"""Regras operacionais: estados, origem, recursos, rollback delegado e projecoes minimas."""

from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from types import SimpleNamespace
from typing import cast
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from sqlalchemy.orm import class_mapper

from app.modules.biketour import operational_schemas as s
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    BikeTourAuditMixin,
    EquipeBikeTour,
    EventoBikeTour,
    InscricaoBikeTour,
    LogisticaBikeTour,
    OcorrenciaBikeTour,
    PendenciaBikeTour,
    PontoControleBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.operations import OperacoesBikeTour, obter, projecao
from app.modules.biketour.uow import ContextoComando
from app.modules.seguranca.rbac import ContextoRbac

NOW = datetime(2026, 9, 23, 12, tzinfo=UTC)
ATOR = ContextoRbac(
    1, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR", "BIKE_TOUR_GERENCIAR"})
)


def entidade[T: BikeTourAuditMixin](model: type[T], **values: object) -> T:
    return model(
        **{
            str(class_mapper(model).primary_key[0].key): 1,
            "versao": 1,
            "created_at": NOW,
            "updated_at": None,
            "deleted_at": None,
            **values,
        }
    )


def evento(**values: object) -> EventoBikeTour:
    return entidade(
        EventoBikeTour,
        **{
            "id_saida": 1,
            "inicio": NOW + timedelta(hours=1),
            "fim": NOW + timedelta(hours=4),
            "status": "ABERTO",
            "capacidade": 10,
            **values,
        },
    )


def inscricao(**values: object) -> InscricaoBikeTour:
    return entidade(
        InscricaoBikeTour,
        **{
            "id_evento_bike_tour": 1,
            "id_reserva": 1,
            "id_passageiro": 1,
            "status": "PENDENTE",
            "papel": "CICLISTA",
            **values,
        },
    )


def alocacao(**values: object) -> AlocacaoRecursoBikeTour:
    return entidade(
        AlocacaoRecursoBikeTour,
        **{
            "id_evento_bike_tour": 1,
            "id_inscricao_bike_tour": 1,
            "id_recurso_bike_tour": 1,
            "status": "BLOQUEADA",
            "expira_em": NOW + timedelta(minutes=10),
            **values,
        },
    )


def origem(**values: object) -> SimpleNamespace:
    return SimpleNamespace(
        **{
            "saida": SimpleNamespace(deleted_at=None, status="ABERTA", capacidade=10),
            "reserva": SimpleNamespace(
                deleted_at=None, status="CONFIRMADA", quantidade_passageiros=2
            ),
            "passageiro": SimpleNamespace(deleted_at=None, status="ATIVO"),
            **values,
        }
    )


@pytest.fixture
def op() -> Iterator[OperacoesBikeTour]:
    session = MagicMock()
    session.scalar.return_value = None
    session.scalars.return_value.all.return_value = []

    def add(item: BikeTourAuditMixin) -> None:
        pk = str(class_mapper(type(item)).primary_key[0].key)
        if getattr(item, pk) is None:
            setattr(item, pk, 10)
        if item.created_at is None:
            item.created_at = NOW
            item.versao = 1

    session.add.side_effect = add
    yield OperacoesBikeTour(ContextoComando(session, ATOR, uuid4(), NOW))


def test_obter_nao_retorna_ausente_ou_excluido(op: OperacoesBikeTour) -> None:
    session = cast(MagicMock, op.session)
    with patch.object(session, "get", side_effect=[None, evento(deleted_at=NOW)]):
        for _ in range(2):
            with pytest.raises(BikeTourError, match="BT_RECURSO_NAO_ENCONTRADO"):
                obter(session, EventoBikeTour, 1)


def test_projecao_nao_expoe_auditoria_interna() -> None:
    ponto = entidade(PontoControleBikeTour, distancia_km=Decimal("5.00"), created_by="1")
    result = projecao(ponto)
    assert result["distancia_km"] == "5.00"
    assert result["created_at"] == NOW.isoformat()
    assert "created_by" not in result and "deleted_at" not in result


@pytest.mark.parametrize(
    "existe,permitido,code", [(False, False, 404), (True, False, 409), (True, True, 201)]
)
def test_criar_recurso_valida_origem(
    op: OperacoesBikeTour, existe: bool, permitido: bool, code: int
) -> None:
    payload = s.RecursoCreate(codigo="G1", tipo="GUIA", id_guia=1, chave_idempotencia="k")
    with patch(
        "app.modules.biketour.operations.obter_situacao_recurso_origem",
        return_value=SimpleNamespace(existe=existe, permitido=permitido),
    ):
        if code == 201:
            assert op.criar_recurso(payload).status == 201
        else:
            with pytest.raises(BikeTourError) as erro:
                op.criar_recurso(payload)
            assert erro.value.status_code == code


def test_bicicleta_propria_sem_patrimonio(op: OperacoesBikeTour) -> None:
    assert (
        op.criar_recurso(
            s.RecursoCreate(codigo="B1", tipo="BICICLETA", chave_idempotencia="k")
        ).status
        == 201
    )


@pytest.mark.parametrize("status", ["MANUTENCAO", "DISPONIVEL"])
def test_alterar_recurso_e_rejeitar_alocacao(op: OperacoesBikeTour, status: str) -> None:
    item = entidade(RecursoBikeTour, tipo="BICICLETA", status="DISPONIVEL")
    payload = s.RecursoUpdate(status=status, versao_esperada=1, chave_idempotencia="k")
    with patch.object(cast(MagicMock, op.session), "get", return_value=item):
        assert op.alterar_recurso(1, payload).status == 200
        with (
            patch.object(cast(MagicMock, op.session), "scalar", return_value=1),
            pytest.raises(BikeTourError, match="BT_RECURSO_ALOCADO"),
        ):
            op.alterar_recurso(1, payload)
        item.status = "MANUTENCAO"
        with pytest.raises(BikeTourError, match="BT_RECURSO_INDISPONIVEL"):
            op.recurso(1, {"BICICLETA"})


def test_expirar_libera_recursos_e_nao_reabre_terminal(op: OperacoesBikeTour) -> None:
    pendente, terminal = inscricao(), inscricao(id_inscricao_bike_tour=2, status="CANCELADA")
    vencidas = [
        alocacao(expira_em=NOW),
        alocacao(id_inscricao_bike_tour=2, expira_em=NOW),
        alocacao(id_inscricao_bike_tour=None),
    ]
    with (
        patch.object(cast(MagicMock, op.session), "get", side_effect=[pendente, terminal]),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value,
            "all",
            side_effect=[vencidas, [vencidas[0]]],
        ),
    ):
        assert op.expirar() == [1, 2]
    assert pendente.status == "EXPIRADA" and terminal.status == "CANCELADA"
    assert all(a.status == "EXPIRADA" and a.expira_em is None for a in vencidas)


@pytest.mark.parametrize(
    "contexto,catalogo,comercial",
    [
        (None, None, True),
        (origem(reserva=SimpleNamespace(deleted_at=None, status="CANCELADA")), None, True),
        (origem(), None, True),
        (origem(), SimpleNamespace(elegivel=False), True),
        (origem(), SimpleNamespace(elegivel=True, produto=SimpleNamespace(tipo="HOTEL")), True),
        (
            origem(),
            SimpleNamespace(elegivel=True, produto=SimpleNamespace(tipo="CICLOTURISMO")),
            False,
        ),
    ],
)
def test_origem_invalida_impede_operacao(
    op: OperacoesBikeTour, contexto: object, catalogo: object, comercial: bool
) -> None:
    with (
        patch("app.modules.biketour.operations.obter_contexto_inscricao", return_value=contexto),
        patch("app.modules.biketour.operations.obter_catalogo_saida", return_value=catalogo),
        patch(
            "app.modules.biketour.operations.obter_origem_comercial_reserva",
            return_value=SimpleNamespace(valida=comercial),
        ),
        pytest.raises(BikeTourError, match="BT_ORIGEM_INCOMPATIVEL"),
    ):
        op.origem(evento(), 1, 1)


def test_origem_valida_sem_escrita(op: OperacoesBikeTour) -> None:
    with (
        patch("app.modules.biketour.operations.obter_contexto_inscricao", return_value=origem()),
        patch(
            "app.modules.biketour.operations.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(tipo="CICLOTURISMO")
            ),
        ),
        patch(
            "app.modules.biketour.operations.obter_origem_comercial_reserva",
            return_value=SimpleNamespace(valida=True),
        ),
    ):
        assert op.origem(evento(), 1, 1).reserva.status == "CONFIRMADA"
    cast(MagicMock, op.session).add.assert_not_called()


def test_alocacao_rejeita_sobreposicao(op: OperacoesBikeTour) -> None:
    with (
        patch.object(cast(MagicMock, op.session), "scalar", return_value=2),
        pytest.raises(BikeTourError, match="BT_RECURSO_OCUPADO"),
    ):
        op.alocar(evento(), entidade(RecursoBikeTour))


@pytest.mark.parametrize("existente", [False, True])
def test_bloqueio_novo_e_rebloqueio_reutilizam_inscricao(
    op: OperacoesBikeTour, existente: bool
) -> None:
    item = inscricao(status="EXPIRADA") if existente else None
    recurso = entidade(RecursoBikeTour, tipo="BICICLETA", status="DISPONIVEL")
    payload = s.InscricaoCreate(
        id_reserva=1,
        id_passageiro=1,
        papel="PARTICIPANTE",
        id_bicicleta=1,
        versao_esperada=1 if existente else None,
        chave_idempotencia="k",
    )
    with (
        patch.object(cast(MagicMock, op.session), "get", side_effect=[evento(), recurso]),
        patch.object(cast(MagicMock, op.session), "scalar", side_effect=[item, None]),
        patch.object(op, "origem", return_value=origem()),
        patch("app.modules.biketour.operations.obter_bloqueio_turistico", return_value=None),
    ):
        result = op.bloquear(1, payload)
    assert result.status == (200 if existente else 201)
    assert isinstance(result.corpo, dict)
    assert result.corpo["status"] == "PENDENTE"


@pytest.mark.parametrize(
    "estado,contexto,ocupadas,anterior,code",
    [
        ("PLANEJADO", origem(), [], None, "BT_EVENTO_FECHADO"),
        (
            "ABERTO",
            origem(reserva=SimpleNamespace(status="PENDENTE")),
            [],
            None,
            "BT_BLOQUEIO_ORIGEM_INVALIDO",
        ),
        ("ABERTO", origem(), [inscricao()] * 10, None, "BT_CAPACIDADE_ESGOTADA"),
        ("ABERTO", origem(), [], inscricao(status="EXPIRADA"), "BT_REBLOQUEIO_INELEGIVEL"),
    ],
)
def test_bloqueio_rejeita_precondicoes(
    op: OperacoesBikeTour,
    estado: str,
    contexto: object,
    ocupadas: list[InscricaoBikeTour],
    anterior: object,
    code: str,
) -> None:
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento(status=estado)),
        patch.object(op, "origem", return_value=contexto),
        patch.object(op, "expirar"),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value, "all", return_value=ocupadas
        ),
        patch.object(cast(MagicMock, op.session), "scalar", return_value=anterior),
        patch("app.modules.biketour.operations.obter_bloqueio_turistico", return_value=None),
        pytest.raises(BikeTourError, match=code),
    ):
        op.bloquear(
            1,
            s.InscricaoCreate(
                id_reserva=1,
                id_passageiro=1,
                papel="CICLISTA",
                id_bicicleta=1,
                chave_idempotencia="k",
            ),
        )


@pytest.mark.parametrize(
    "acao,atual,destino",
    [
        ("CONFIRMAR", "PENDENTE", "CONFIRMADA"),
        ("PRESENCA", "CONFIRMADA", "PRESENTE"),
        ("NO_SHOW", "CONFIRMADA", "NO_SHOW"),
        ("CANCELAR", "PENDENTE", "CANCELADA"),
        ("CONCLUIR", "PRESENTE", "CONCLUIDA"),
    ],
)
def test_acoes_preservam_maquina_de_estados(
    op: OperacoesBikeTour, acao: str, atual: str, destino: str
) -> None:
    item = inscricao(status=atual)
    aloc = alocacao()
    with (
        patch.object(
            cast(MagicMock, op.session),
            "get",
            side_effect=[item, evento(status="ABERTO" if acao == "CONFIRMAR" else "EM_EXECUCAO")],
        ),
        patch.object(op, "origem", return_value=origem()),
        patch.object(op, "recurso"),
        patch.object(op, "alocacoes", return_value=[aloc]),
    ):
        result = op.acionar_inscricao(
            1,
            s.InscricaoAcao(
                acao=acao, motivo="OPERACIONAL", versao_esperada=1, chave_idempotencia="k"
            ),
        )
    assert isinstance(result.corpo, dict)
    assert result.corpo["status"] == destino
    if acao in {"CANCELAR", "NO_SHOW"}:
        assert len(op.ctx.pendencias) == 1 and aloc.status == "LIBERADA"


@pytest.mark.parametrize(
    "acao,estado,evento_status,motivo,code",
    [
        ("CANCELAR", "PENDENTE", "ABERTO", None, "BT_MOTIVO_OBRIGATORIO"),
        ("CONFIRMAR", "PENDENTE", "PLANEJADO", None, "BT_CONFIRMACAO_INELEGIVEL"),
        ("PRESENCA", "CONFIRMADA", "ABERTO", "OPERACIONAL", "BT_EVENTO_NAO_INICIADO"),
        ("CONCLUIR", "PRESENTE", "EM_EXECUCAO", None, "BT_PERCURSO_INCOMPLETO"),
    ],
)
def test_acoes_rejeitam_precondicoes(
    op: OperacoesBikeTour, acao: str, estado: str, evento_status: str, motivo: str | None, code: str
) -> None:
    with (
        patch.object(
            cast(MagicMock, op.session),
            "get",
            side_effect=[inscricao(status=estado), evento(status=evento_status)],
        ),
        patch.object(op, "origem", return_value=origem()),
        pytest.raises(BikeTourError, match=code),
    ):
        op.acionar_inscricao(
            1, s.InscricaoAcao(acao=acao, motivo=motivo, versao_esperada=1, chave_idempotencia="k")
        )


def test_presenca_exige_reserva_confirmada(op: OperacoesBikeTour) -> None:
    with (
        patch.object(
            cast(MagicMock, op.session),
            "get",
            side_effect=[inscricao(status="CONFIRMADA"), evento(status="EM_EXECUCAO")],
        ),
        patch.object(op, "origem", return_value=origem(reserva=SimpleNamespace(status="PENDENTE"))),
        pytest.raises(BikeTourError, match="BT_ORIGEM_INCOMPATIVEL"),
    ):
        op.acionar_inscricao(
            1,
            s.InscricaoAcao(
                acao="PRESENCA", motivo="OPERACIONAL", versao_esperada=1, chave_idempotencia="k"
            ),
        )


def test_definir_pontos_preserva_historico_e_reutiliza_ordem(op: OperacoesBikeTour) -> None:
    antigo = entidade(PontoControleBikeTour, ordem=3, distancia_km=Decimal(20))
    reutilizado = entidade(PontoControleBikeTour, ordem=1, distancia_km=Decimal(0))
    payload = s.PontosRequest(
        pontos=[
            s.PontoInput(ordem=1, id_localidade=1, distancia_km=0),
            s.PontoInput(ordem=2, id_localidade=1, distancia_km=5),
        ],
        versao_esperada=1,
        chave_idempotencia="k",
    )
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento(status="PLANEJADO")),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value,
            "all",
            return_value=[antigo, reutilizado],
        ),
        patch("app.modules.biketour.operations.localidade_disponivel", return_value=True),
    ):
        assert op.definir_pontos(1, payload).status == 200
    assert antigo.deleted_at == NOW and reutilizado.deleted_at is None
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento()),
        pytest.raises(BikeTourError, match="BT_EVENTO_JA_ABERTO"),
    ):
        op.definir_pontos(1, payload)
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento(status="PLANEJADO")),
        patch("app.modules.biketour.operations.localidade_disponivel", return_value=False),
        pytest.raises(BikeTourError, match="BT_LOCALIDADE_NAO_ENCONTRADA"),
    ):
        op.definir_pontos(1, payload)


@pytest.mark.parametrize("equipe", [False, True])
@pytest.mark.parametrize("existente", [False, True])
def test_substituir_apoio_libera_alocacao_anterior(
    op: OperacoesBikeTour, equipe: bool, existente: bool
) -> None:
    payload = (
        s.EquipeRequest(
            equipe=[s.GuiaInput(id_recurso=1, papel="LIDER")],
            versao_esperada=1,
            chave_idempotencia="k",
        )
        if equipe
        else s.LogisticaRequest(
            apoio=[s.ApoioInput(id_recurso=1, finalidade="APOIO")],
            versao_esperada=1,
            chave_idempotencia="k",
        )
    )
    anterior = entidade(
        EquipeBikeTour if equipe else LogisticaBikeTour,
        id_recurso_bike_tour=1,
        id_evento_bike_tour=1,
    )
    aloc = alocacao(id_inscricao_bike_tour=None)
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento(status="PLANEJADO")),
        patch.object(op, "expirar"),
        patch.object(op, "recurso", return_value=entidade(RecursoBikeTour)),
        patch.object(op, "alocacoes", return_value=[aloc]),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value,
            "all",
            return_value=[anterior] if existente else [],
        ),
    ):
        assert op.definir_apoio(1, payload).status == 200
    if existente:
        assert aloc.status == "LIBERADA" and anterior.deleted_at is None
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento()),
        pytest.raises(BikeTourError, match="BT_EVENTO_JA_ABERTO"),
    ):
        op.definir_apoio(1, payload)


def test_passagem_exige_evento_presenca_ordem_e_horario(op: OperacoesBikeTour) -> None:
    item = inscricao(status="PRESENTE")
    ev = evento(status="EM_EXECUCAO", inicio=NOW - timedelta(hours=1))
    ponto = entidade(PontoControleBikeTour, id_evento_bike_tour=1, ordem=1)
    payload = s.PassagemCreate(id_ponto=1, instante=NOW, versao_esperada=1, chave_idempotencia="k")
    with (
        patch.object(cast(MagicMock, op.session), "get", side_effect=[item, ev, ponto]),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value, "all", side_effect=[[ponto], []]
        ),
    ):
        assert op.registrar_passagem(1, payload).status == 201
    for presenca, pontos in [(False, [ponto]), (True, [])]:
        item.status = "PRESENTE" if presenca else "CONFIRMADA"
        with (
            patch.object(cast(MagicMock, op.session), "get", side_effect=[item, ev, ponto]),
            patch.object(
                cast(MagicMock, op.session).scalars.return_value, "all", side_effect=[pontos, []]
            ),
            pytest.raises(BikeTourError, match="BT_PASSAGEM_"),
        ):
            op.registrar_passagem(1, payload)


def test_ocorrencia_valida_evento_e_transicao(op: OperacoesBikeTour) -> None:
    payload = s.OcorrenciaCreate(
        id_inscricao=1,
        tipo="MECANICA",
        gravidade="ALTA",
        motivo="OPERACIONAL",
        chave_idempotencia="k",
    )
    with patch.object(cast(MagicMock, op.session), "get", side_effect=[evento(), inscricao()]):
        assert op.registrar_ocorrencia(1, payload).status == 201
    with (
        patch.object(
            cast(MagicMock, op.session),
            "get",
            side_effect=[evento(), inscricao(id_evento_bike_tour=2)],
        ),
        pytest.raises(BikeTourError, match="BT_INSCRICAO_OUTRO_EVENTO"),
    ):
        op.registrar_ocorrencia(1, payload)
    with patch.object(
        cast(MagicMock, op.session),
        "get",
        return_value=entidade(OcorrenciaBikeTour, status="ABERTA"),
    ):
        assert (
            op.alterar_ocorrencia(
                1,
                s.OcorrenciaUpdate(
                    status="EM_ANALISE",
                    motivo="OPERACIONAL",
                    versao_esperada=1,
                    chave_idempotencia="k",
                ),
            ).status
            == 200
        )


def test_avaliacao_apenas_apos_conclusao(op: OperacoesBikeTour) -> None:
    payload = s.AvaliacaoCreate(nota=5, versao_esperada=1, chave_idempotencia="k")
    with patch.object(
        cast(MagicMock, op.session), "get", return_value=inscricao(status="CONCLUIDA")
    ):
        assert op.avaliar(1, payload).status == 201
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=inscricao()),
        pytest.raises(BikeTourError, match="BT_INSCRICAO_NAO_CONCLUIDA"),
    ):
        op.avaliar(1, payload)


def test_tratamento_pendencia_nao_reabre_concluida(op: OperacoesBikeTour) -> None:
    item = entidade(PendenciaBikeTour, status="ABERTA")
    payload = s.TratamentoRequest(
        referencia_tratamento="FIN-123",
        motivo="TRATAMENTO_CONCLUIDO",
        versao_esperada=1,
        chave_idempotencia="k",
    )
    with patch.object(cast(MagicMock, op.session), "get", return_value=item):
        assert op.tratar_pendencia(1, payload).status == 200
        assert item.referencia_tratamento == "FIN-123"
        with pytest.raises(BikeTourError, match="BT_PENDENCIA_JA_TRATADA"):
            op.tratar_pendencia(1, payload)


def test_expiracao_reporta_ids_do_evento(op: OperacoesBikeTour) -> None:
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento()),
        patch.object(op, "expirar", return_value=[1, 2]),
        patch.object(cast(MagicMock, op.session).scalars.return_value, "all", return_value=[1]),
    ):
        result = op.expirar_evento(1, s.Alteracao(versao_esperada=1, chave_idempotencia="k"))
    assert result.corpo == {"id_evento_bike_tour": 1, "expiradas": [1]}


@pytest.mark.parametrize("falha", [None, 409, 503])
def test_reconciliacao_distingue_cancelamento_de_indisponibilidade(
    op: OperacoesBikeTour, falha: int | None
) -> None:
    item = inscricao()
    payload = s.Reconciliacao(limite=1, versao_esperada=1, chave_idempotencia="k")
    with (
        patch.object(cast(MagicMock, op.session), "get", return_value=evento()),
        patch.object(
            cast(MagicMock, op.session).scalars.return_value,
            "all",
            return_value=[item, inscricao(id_inscricao_bike_tour=2)],
        ),
        patch.object(op, "alocacoes", return_value=[]),
        patch.object(op, "origem", side_effect=BikeTourError(falha, "ORIGEM") if falha else None),
    ):
        if falha == 503:
            with pytest.raises(BikeTourError):
                op.reconciliar(1, payload)
            assert item.status == "PENDENTE" and not op.ctx.pendencias
        else:
            result = op.reconciliar(1, payload)
            assert isinstance(result.corpo, dict) and result.corpo["proximo_cursor"] == 1
            assert item.status == ("CANCELADA" if falha else "PENDENTE")


def test_cancelamento_evento_registra_intencao_para_cada_inscricao(op: OperacoesBikeTour) -> None:
    itens = [inscricao(), inscricao(id_inscricao_bike_tour=2)]
    aloc = alocacao()
    with (
        patch.object(cast(MagicMock, op.session).scalars.return_value, "all", return_value=itens),
        patch.object(op, "alocacoes", return_value=[aloc]),
    ):
        op.cancelar_evento(evento(), "CLIMA")
    assert all(i.status == "CANCELADA" for i in itens)
    assert len(op.ctx.pendencias) == 2 and aloc.status == "LIBERADA"


@pytest.mark.parametrize("estado", ["PENDENTE", "CONFIRMADA"])
def test_reacomodacao_reserva_destino_e_libera_origem(op: OperacoesBikeTour, estado: str) -> None:
    item = inscricao(status=estado)
    antiga = alocacao(expira_em=NOW + timedelta(minutes=5) if estado == "PENDENTE" else None)
    payload = s.Reacomodacao(id_bicicleta=2, versao_esperada=1, chave_idempotencia="k")
    with (
        patch.object(cast(MagicMock, op.session), "get", side_effect=[item, evento()]),
        patch.object(op, "origem"),
        patch.object(op, "expirar"),
        patch.object(op, "alocacoes", return_value=[antiga]),
        patch.object(op, "recurso", return_value=entidade(RecursoBikeTour, id_recurso_bike_tour=2)),
    ):
        assert op.reacomodar(1, payload).status == 200
    assert antiga.status == "LIBERADA"


@pytest.mark.parametrize(
    "estado,expira,code",
    [("CONCLUIDA", None, "BT_REACOMODACAO_INELEGIVEL"), ("PENDENTE", NOW, "BT_BLOQUEIO_VENCIDO")],
)
def test_reacomodacao_rejeita_terminal_ou_vencimento(
    op: OperacoesBikeTour, estado: str, expira: datetime | None, code: str
) -> None:
    with (
        patch.object(
            cast(MagicMock, op.session), "get", side_effect=[inscricao(status=estado), evento()]
        ),
        patch.object(op, "origem"),
        patch.object(op, "alocacoes", return_value=[alocacao(expira_em=expira)]),
        pytest.raises(BikeTourError, match=code),
    ):
        op.reacomodar(1, s.Reacomodacao(id_bicicleta=2, versao_esperada=1, chave_idempotencia="k"))
