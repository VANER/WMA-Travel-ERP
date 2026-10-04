"""Comandos operacionais atomicos, sem commit ou escrita em dominios de origem."""

from datetime import UTC, datetime
from decimal import Decimal
from typing import cast

from sqlalchemy import select
from sqlalchemy.orm import Session, class_mapper

from app.modules.biketour import operational_schemas as schemas
from app.modules.biketour.domain import (
    calcular_expiracao,
    validar_rebloqueio,
    validar_transicao_inscricao,
    validar_transicao_ocorrencia,
    validar_versao,
)
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    AvaliacaoBikeTour,
    BikeTourAuditMixin,
    EquipeBikeTour,
    EventoBikeTour,
    InscricaoBikeTour,
    LogisticaBikeTour,
    OcorrenciaBikeTour,
    PassagemBikeTour,
    PendenciaBikeTour,
    PontoControleBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.uow import ContextoComando, ResultadoComando, _tem_permissao
from app.shared.localidades import localidade_disponivel
from app.shared.turismo import (
    ContextoInscricao,
    obter_bloqueio_turistico,
    obter_catalogo_saida,
    obter_contexto_inscricao,
    obter_origem_comercial_reserva,
    obter_situacao_recurso_origem,
)

ATIVAS = ("PENDENTE", "CONFIRMADA", "PRESENTE")
ALOCADAS = ("BLOQUEADA", "CONFIRMADA")


def projecao(item: BikeTourAuditMixin) -> dict[str, object]:
    """Somente atributos operacionais; remove identificadores de auditoria interna."""
    mapper = class_mapper(type(item))
    result: dict[str, object] = {}
    for column in mapper.columns:
        if column.key in {"created_by", "updated_by", "deleted_by", "deleted_at"}:
            continue
        value = getattr(item, column.key)
        if isinstance(value, datetime):
            value = value.isoformat()
        elif isinstance(value, Decimal):
            value = str(value)
        result["id" if column.primary_key else column.key] = value
    return result


def obter[T: BikeTourAuditMixin](session: Session, model: type[T], identifier: int) -> T:
    item = session.get(model, identifier, with_for_update=True, populate_existing=True)
    if item is None or item.deleted_at is not None:
        raise BikeTourError(404, "BT_RECURSO_NAO_ENCONTRADO")
    return item


class OperacoesBikeTour:
    def __init__(self, contexto: ContextoComando) -> None:
        self.ctx = contexto
        self.session = contexto.session
        self.ator = str(contexto.ator.id_usuario)

    def salvar(self, item: BikeTourAuditMixin) -> dict[str, object]:
        item.updated_by = self.ator
        self.session.add(item)
        self.session.flush()
        self.session.refresh(item)
        return projecao(item)

    def alocacoes(self, evento: int, inscricao: int | None = None) -> list[AlocacaoRecursoBikeTour]:
        statement = select(AlocacaoRecursoBikeTour).where(
            AlocacaoRecursoBikeTour.id_evento_bike_tour == evento,
            AlocacaoRecursoBikeTour.status.in_(ALOCADAS),
        )
        if inscricao is not None:
            statement = statement.where(AlocacaoRecursoBikeTour.id_inscricao_bike_tour == inscricao)
        return list(
            self.session.scalars(
                statement.order_by(
                    AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour
                ).with_for_update()
            ).all()
        )

    def liberar(self, alocacoes: list[AlocacaoRecursoBikeTour], status: str = "LIBERADA") -> None:
        for item in alocacoes:
            item.status, item.expira_em, item.updated_by = status, None, self.ator

    def expirar(self) -> list[int]:
        vencidas = list(
            self.session.scalars(
                select(AlocacaoRecursoBikeTour)
                .where(
                    AlocacaoRecursoBikeTour.status == "BLOQUEADA",
                    AlocacaoRecursoBikeTour.expira_em <= self.ctx.agora,
                )
                .order_by(AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour)
                .with_for_update()
            ).all()
        )
        ids = sorted(
            {a.id_inscricao_bike_tour for a in vencidas if a.id_inscricao_bike_tour is not None}
        )
        for identifier in ids:
            inscricao = obter(self.session, InscricaoBikeTour, identifier)
            if inscricao.status == "PENDENTE":
                inscricao.status, inscricao.updated_by = "EXPIRADA", self.ator
                self.liberar(self.alocacoes(inscricao.id_evento_bike_tour, identifier), "EXPIRADA")
        self.liberar(vencidas, "EXPIRADA")
        self.session.flush()
        return ids

    def origem(self, evento: EventoBikeTour, reserva: int, passageiro: int) -> ContextoInscricao:
        origem = obter_contexto_inscricao(
            self.session, evento.id_saida, reserva, passageiro, bloquear=True
        )
        if (
            origem is None
            or origem.saida.deleted_at is not None
            or origem.saida.status not in {"PLANEJADA", "ABERTA"}
            or origem.reserva.deleted_at is not None
            or origem.reserva.status not in {"PENDENTE", "CONFIRMADA"}
            or origem.passageiro.deleted_at is not None
            or origem.passageiro.status != "ATIVO"
        ):
            raise BikeTourError(409, "BT_ORIGEM_INCOMPATIVEL")
        catalogo = obter_catalogo_saida(self.session, origem.saida, bloquear=True)
        comercial = obter_origem_comercial_reserva(self.session, reserva, bloquear=True)
        if (
            catalogo is None
            or not catalogo.elegivel
            or catalogo.produto.tipo != "CICLOTURISMO"
            or not comercial.valida
        ):
            raise BikeTourError(409, "BT_ORIGEM_INCOMPATIVEL")
        return origem

    def recurso(self, identifier: int, tipos: set[str]) -> RecursoBikeTour:
        item = obter(self.session, RecursoBikeTour, identifier)
        if item.tipo not in tipos or item.status != "DISPONIVEL":
            raise BikeTourError(409, "BT_RECURSO_INDISPONIVEL")
        self.validar_referencia(item)
        return item

    def validar_referencia(self, item: RecursoBikeTour) -> None:
        identifier = item.id_ativo or item.id_guia or item.id_transporte
        if identifier is not None:
            origem = obter_situacao_recurso_origem(
                self.session, cast(schemas.TipoRecurso, item.tipo), identifier, bloquear=True
            )
            if not origem.existe:
                raise BikeTourError(404, "BT_ORIGEM_NAO_ENCONTRADA")
            if not origem.permitido:
                raise BikeTourError(409, "BT_ORIGEM_INCOMPATIVEL")

    def alocar(
        self,
        evento: EventoBikeTour,
        recurso: RecursoBikeTour,
        inscricao: InscricaoBikeTour | None = None,
        expira: datetime | None = None,
    ) -> None:
        conflito = self.session.scalar(
            select(AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour)
            .where(
                AlocacaoRecursoBikeTour.id_recurso_bike_tour == recurso.id_recurso_bike_tour,
                AlocacaoRecursoBikeTour.status.in_(ALOCADAS),
                AlocacaoRecursoBikeTour.inicio < evento.fim,
                AlocacaoRecursoBikeTour.fim > evento.inicio,
            )
            .limit(1)
        )
        if conflito is not None:
            raise BikeTourError(409, "BT_RECURSO_OCUPADO")
        self.session.add(
            AlocacaoRecursoBikeTour(
                id_evento_bike_tour=evento.id_evento_bike_tour,
                id_inscricao_bike_tour=inscricao.id_inscricao_bike_tour if inscricao else None,
                id_recurso_bike_tour=recurso.id_recurso_bike_tour,
                inicio=evento.inicio,
                fim=evento.fim,
                expira_em=expira,
                status="BLOQUEADA" if expira else "CONFIRMADA",
                created_by=self.ator,
            )
        )
        self.session.flush()

    def pendencia(self, item: InscricaoBikeTour, tipo: str, motivo: str) -> None:
        self.ctx.pendencias.append(
            PendenciaBikeTour(
                id_evento_bike_tour=item.id_evento_bike_tour,
                id_inscricao_bike_tour=item.id_inscricao_bike_tour,
                tipo=tipo,
                status="ABERTA",
                motivo=motivo,
                created_by=self.ator,
            )
        )

    def inscricao_resultado(
        self, item: InscricaoBikeTour, evento: EventoBikeTour
    ) -> dict[str, object]:
        self.session.flush()
        self.session.refresh(item)
        alocacoes = self.alocacoes(item.id_evento_bike_tour, item.id_inscricao_bike_tour)
        expira = min((a.expira_em for a in alocacoes if a.expira_em is not None), default=None)
        try:
            self.origem(evento, item.id_reserva, item.id_passageiro)
            origem_valida = True
        except BikeTourError as exc:
            if exc.status_code != 409:
                raise
            origem_valida = False
        return {
            **projecao(item),
            "origem_valida": origem_valida,
            "expira_em": expira.isoformat() if expira else None,
            "alocacoes": [a.id_alocacao_recurso_bike_tour for a in alocacoes],
        }

    def criar_recurso(self, payload: schemas.RecursoCreate) -> ResultadoComando:
        item = RecursoBikeTour(
            **payload.model_dump(exclude={"chave_idempotencia"}),
            status="DISPONIVEL",
            created_by=self.ator,
        )
        self.validar_referencia(item)
        return ResultadoComando(201, self.salvar(item))

    def alterar_recurso(self, identifier: int, payload: schemas.RecursoUpdate) -> ResultadoComando:
        self.expirar()
        item = obter(self.session, RecursoBikeTour, identifier)
        validar_versao(item.versao, payload.versao_esperada)
        if (
            self.session.scalar(
                select(AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour)
                .where(
                    AlocacaoRecursoBikeTour.id_recurso_bike_tour == identifier,
                    AlocacaoRecursoBikeTour.status.in_(ALOCADAS),
                )
                .limit(1)
            )
            is not None
        ):
            raise BikeTourError(409, "BT_RECURSO_ALOCADO")
        if payload.status == "DISPONIVEL":
            self.validar_referencia(item)
        item.status = payload.status
        return ResultadoComando(200, self.salvar(item))

    def bloquear(self, identifier: int, payload: schemas.InscricaoCreate) -> ResultadoComando:
        evento = obter(self.session, EventoBikeTour, identifier)
        if evento.status != "ABERTO":
            raise BikeTourError(409, "BT_EVENTO_FECHADO")
        origem = self.origem(evento, payload.id_reserva, payload.id_passageiro)
        self.expirar()
        bloqueio = obter_bloqueio_turistico(self.session, payload.id_reserva, bloquear=True)
        if origem.reserva.status == "PENDENTE" and (
            bloqueio is None or bloqueio.status != "BLOQUEADA" or bloqueio.expira_em is None
        ):
            raise BikeTourError(409, "BT_BLOQUEIO_ORIGEM_INVALIDO")
        expira = calcular_expiracao(
            self.ctx.agora,
            evento.inicio,
            bloqueio.expira_em if bloqueio and origem.reserva.status == "PENDENTE" else None,
        )
        inscricoes = list(
            self.session.scalars(
                select(InscricaoBikeTour).where(
                    InscricaoBikeTour.id_evento_bike_tour == identifier,
                    InscricaoBikeTour.status.in_(ATIVAS),
                )
            ).all()
        )
        if (
            len(inscricoes) >= evento.capacidade
            or evento.capacidade > origem.saida.capacidade
            or sum(i.id_reserva == payload.id_reserva for i in inscricoes)
            >= origem.reserva.quantidade_passageiros
        ):
            raise BikeTourError(409, "BT_CAPACIDADE_ESGOTADA")
        item = self.session.scalar(
            select(InscricaoBikeTour)
            .where(
                InscricaoBikeTour.id_evento_bike_tour == identifier,
                InscricaoBikeTour.id_passageiro == payload.id_passageiro,
            )
            .with_for_update()
        )
        criada = item is None
        if item is not None:
            if item.deleted_at is not None or payload.versao_esperada is None:
                raise BikeTourError(409, "BT_REBLOQUEIO_INELEGIVEL")
            validar_rebloqueio(item.status, evento.status)
            validar_versao(item.versao, payload.versao_esperada)
        else:
            item = InscricaoBikeTour(
                id_evento_bike_tour=identifier,
                id_reserva=payload.id_reserva,
                id_passageiro=payload.id_passageiro,
                created_by=self.ator,
            )
        item.papel = "CICLISTA" if payload.papel == "PARTICIPANTE" else payload.papel
        item.status, item.updated_by = "PENDENTE", self.ator
        self.session.add(item)
        self.session.flush()
        for recurso_id in sorted([payload.id_bicicleta, *payload.ids_equipamentos]):
            recurso = self.recurso(
                recurso_id, {"BICICLETA" if recurso_id == payload.id_bicicleta else "EQUIPAMENTO"}
            )
            self.alocar(evento, recurso, item, expira)
        return ResultadoComando(201 if criada else 200, self.inscricao_resultado(item, evento))

    def acionar_inscricao(
        self, identifier: int, payload: schemas.InscricaoAcao
    ) -> ResultadoComando:
        item = obter(self.session, InscricaoBikeTour, identifier)
        evento = obter(self.session, EventoBikeTour, item.id_evento_bike_tour)
        validar_versao(item.versao, payload.versao_esperada)
        destinos = {
            "CONFIRMAR": "CONFIRMADA",
            "CANCELAR": "CANCELADA",
            "PRESENCA": "PRESENTE",
            "NO_SHOW": "NO_SHOW",
            "CONCLUIR": "CONCLUIDA",
        }
        destino = destinos[payload.acao]
        validar_transicao_inscricao(item.status, destino)
        if payload.acao in {"CANCELAR", "PRESENCA", "NO_SHOW"} and payload.motivo is None:
            raise BikeTourError(422, "BT_MOTIVO_OBRIGATORIO")
        alocacoes = self.alocacoes(item.id_evento_bike_tour, identifier)
        if payload.acao == "CONFIRMAR":
            origem = self.origem(evento, item.id_reserva, item.id_passageiro)
            if (
                evento.status != "ABERTO"
                or origem.reserva.status != "CONFIRMADA"
                or not alocacoes
                or any(a.expira_em is None or a.expira_em <= self.ctx.agora for a in alocacoes)
            ):
                raise BikeTourError(409, "BT_CONFIRMACAO_INELEGIVEL")
            for alocacao in alocacoes:
                self.recurso(alocacao.id_recurso_bike_tour, {"BICICLETA", "EQUIPAMENTO"})
                alocacao.status, alocacao.expira_em, alocacao.updated_by = (
                    "CONFIRMADA",
                    None,
                    self.ator,
                )
        elif payload.acao in {"PRESENCA", "NO_SHOW", "CONCLUIR"}:
            if evento.status != "EM_EXECUCAO":
                raise BikeTourError(409, "BT_EVENTO_NAO_INICIADO")
            if payload.acao == "PRESENCA":
                origem = self.origem(evento, item.id_reserva, item.id_passageiro)
                if origem.reserva.status != "CONFIRMADA":
                    raise BikeTourError(409, "BT_ORIGEM_INCOMPATIVEL")
            if payload.acao == "CONCLUIR":
                ultimo = self.session.scalar(
                    select(PontoControleBikeTour.id_ponto_controle_bike_tour)
                    .where(
                        PontoControleBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
                        PontoControleBikeTour.deleted_at.is_(None),
                    )
                    .order_by(PontoControleBikeTour.ordem.desc())
                    .limit(1)
                )
                passou = self.session.scalar(
                    select(PassagemBikeTour.id_passagem_bike_tour)
                    .where(
                        PassagemBikeTour.id_inscricao_bike_tour == identifier,
                        PassagemBikeTour.id_ponto_controle_bike_tour == ultimo,
                    )
                    .limit(1)
                )
                if passou is None and not (
                    payload.motivo
                    and _tem_permissao(self.ctx.ator.permissoes, "BIKE_TOUR_GERENCIAR")
                ):
                    raise BikeTourError(409, "BT_PERCURSO_INCOMPLETO")
        if destino in {"CANCELADA", "NO_SHOW", "CONCLUIDA"}:
            self.liberar(alocacoes)
            if destino in {"CANCELADA", "NO_SHOW"}:
                self.pendencia(
                    item,
                    "CANCELAMENTO" if destino == "CANCELADA" else "NO_SHOW",
                    payload.motivo or "OPERACIONAL",
                )
        item.status, item.updated_by = destino, self.ator
        return ResultadoComando(200, self.inscricao_resultado(item, evento))

    def definir_pontos(self, identifier: int, payload: schemas.PontosRequest) -> ResultadoComando:
        evento = obter(self.session, EventoBikeTour, identifier)
        validar_versao(evento.versao, payload.versao_esperada)
        if evento.status != "PLANEJADO":
            raise BikeTourError(409, "BT_EVENTO_JA_ABERTO")
        existentes = {
            p.ordem: p
            for p in self.session.scalars(
                select(PontoControleBikeTour).where(
                    PontoControleBikeTour.id_evento_bike_tour == identifier,
                )
            ).all()
        }
        ordens = {p.ordem for p in payload.pontos}
        for anterior in existentes.values():
            if anterior.ordem not in ordens:
                anterior.deleted_at, anterior.deleted_by = self.ctx.agora, self.ator
        resultado = []
        for entrada in payload.pontos:
            if not localidade_disponivel(self.session, entrada.id_localidade):
                raise BikeTourError(404, "BT_LOCALIDADE_NAO_ENCONTRADA")
            ponto = existentes.get(entrada.ordem)
            if ponto is None:
                ponto = PontoControleBikeTour(id_evento_bike_tour=identifier, created_by=self.ator)
            ponto.ordem, ponto.id_localidade = entrada.ordem, entrada.id_localidade
            ponto.distancia_km = entrada.distancia_km
            ponto.deleted_at, ponto.deleted_by = None, None
            resultado.append(self.salvar(ponto))
        evento.updated_at, evento.updated_by = self.ctx.agora, self.ator
        self.session.flush()
        return ResultadoComando(200, resultado)

    def definir_apoio(
        self, identifier: int, payload: schemas.EquipeRequest | schemas.LogisticaRequest
    ) -> ResultadoComando:
        evento = obter(self.session, EventoBikeTour, identifier)
        validar_versao(evento.versao, payload.versao_esperada)
        if evento.status != "PLANEJADO":
            raise BikeTourError(409, "BT_EVENTO_JA_ABERTO")
        self.expirar()
        equipe = isinstance(payload, schemas.EquipeRequest)
        model: type[EquipeBikeTour] | type[LogisticaBikeTour] = (
            EquipeBikeTour if equipe else LogisticaBikeTour
        )
        entradas: list[schemas.GuiaInput | schemas.ApoioInput] = (
            list(payload.equipe)
            if isinstance(payload, schemas.EquipeRequest)
            else list(payload.apoio)
        )
        anteriores = cast(
            list[EquipeBikeTour | LogisticaBikeTour],
            list(
                self.session.scalars(
                    select(model).where(model.id_evento_bike_tour == identifier)
                ).all()
            ),
        )
        # Desativa antes de reatribuir o lider unico. O rollback protege o plano anterior.
        for anterior in anteriores:
            anterior.deleted_at, anterior.deleted_by = self.ctx.agora, self.ator
        ids = {p.id_recurso_bike_tour for p in anteriores}
        self.liberar(
            [
                a
                for a in self.alocacoes(identifier)
                if a.id_inscricao_bike_tour is None and a.id_recurso_bike_tour in ids
            ]
        )
        self.session.flush()
        existentes = {p.id_recurso_bike_tour: p for p in anteriores}
        resultado = []
        for entrada in sorted(entradas, key=lambda e: e.id_recurso):
            recurso = self.recurso(
                entrada.id_recurso, {"GUIA"} if equipe else {"VEICULO", "EQUIPAMENTO"}
            )
            item = existentes.get(entrada.id_recurso)
            if item is None:
                item = model(
                    id_evento_bike_tour=identifier,
                    id_recurso_bike_tour=entrada.id_recurso,
                    created_by=self.ator,
                )
            if isinstance(item, EquipeBikeTour) and isinstance(entrada, schemas.GuiaInput):
                item.papel = entrada.papel
            elif isinstance(item, LogisticaBikeTour) and isinstance(entrada, schemas.ApoioInput):
                item.finalidade = entrada.finalidade
            item.deleted_at, item.deleted_by = None, None
            self.alocar(evento, recurso)
            resultado.append(self.salvar(item))
        evento.updated_at, evento.updated_by = self.ctx.agora, self.ator
        self.session.flush()
        return ResultadoComando(200, resultado)

    def registrar_passagem(
        self, identifier: int, payload: schemas.PassagemCreate
    ) -> ResultadoComando:
        item = obter(self.session, InscricaoBikeTour, identifier)
        validar_versao(item.versao, payload.versao_esperada)
        evento = obter(self.session, EventoBikeTour, item.id_evento_bike_tour)
        ponto = obter(self.session, PontoControleBikeTour, payload.id_ponto)
        instante = payload.instante.astimezone(UTC)
        if (
            item.status != "PRESENTE"
            or evento.status != "EM_EXECUCAO"
            or ponto.id_evento_bike_tour != item.id_evento_bike_tour
            or not evento.inicio <= instante <= min(self.ctx.agora, evento.fim)
        ):
            raise BikeTourError(409, "BT_PASSAGEM_INELEGIVEL")
        pontos = list(
            self.session.scalars(
                select(PontoControleBikeTour)
                .where(
                    PontoControleBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
                    PontoControleBikeTour.deleted_at.is_(None),
                )
                .order_by(PontoControleBikeTour.ordem)
            ).all()
        )
        passagens = list(
            self.session.scalars(
                select(PassagemBikeTour).where(
                    PassagemBikeTour.id_inscricao_bike_tour == identifier,
                )
            ).all()
        )
        visitados = {p.id_ponto_controle_bike_tour for p in passagens}
        proximos = [p for p in pontos if p.id_ponto_controle_bike_tour not in visitados]
        if (
            not proximos
            or proximos[0].id_ponto_controle_bike_tour != payload.id_ponto
            or any(p.instante > instante for p in passagens)
        ):
            raise BikeTourError(409, "BT_PASSAGEM_FORA_DE_ORDEM")
        passagem = PassagemBikeTour(
            id_inscricao_bike_tour=identifier,
            id_ponto_controle_bike_tour=payload.id_ponto,
            instante=instante,
            created_by=self.ator,
        )
        item.updated_at, item.updated_by = self.ctx.agora, self.ator
        return ResultadoComando(201, self.salvar(passagem))

    def registrar_ocorrencia(
        self, identifier: int, payload: schemas.OcorrenciaCreate
    ) -> ResultadoComando:
        obter(self.session, EventoBikeTour, identifier)
        if payload.id_inscricao is not None:
            inscricao = obter(self.session, InscricaoBikeTour, payload.id_inscricao)
            if inscricao.id_evento_bike_tour != identifier:
                raise BikeTourError(409, "BT_INSCRICAO_OUTRO_EVENTO")
        item = OcorrenciaBikeTour(
            id_evento_bike_tour=identifier,
            id_inscricao_bike_tour=payload.id_inscricao,
            tipo=payload.tipo,
            gravidade=payload.gravidade,
            motivo=payload.motivo,
            status="ABERTA",
            created_by=self.ator,
        )
        return ResultadoComando(201, self.salvar(item))

    def alterar_ocorrencia(
        self, identifier: int, payload: schemas.OcorrenciaUpdate
    ) -> ResultadoComando:
        item = obter(self.session, OcorrenciaBikeTour, identifier)
        validar_versao(item.versao, payload.versao_esperada)
        validar_transicao_ocorrencia(item.status, payload.status)
        item.status, item.motivo = payload.status, payload.motivo
        return ResultadoComando(200, self.salvar(item))

    def avaliar(self, identifier: int, payload: schemas.AvaliacaoCreate) -> ResultadoComando:
        item = obter(self.session, InscricaoBikeTour, identifier)
        validar_versao(item.versao, payload.versao_esperada)
        if item.status != "CONCLUIDA":
            raise BikeTourError(409, "BT_INSCRICAO_NAO_CONCLUIDA")
        avaliacao = AvaliacaoBikeTour(
            id_inscricao_bike_tour=identifier, nota=payload.nota, created_by=self.ator
        )
        return ResultadoComando(201, self.salvar(avaliacao))

    def tratar_pendencia(
        self, identifier: int, payload: schemas.TratamentoRequest
    ) -> ResultadoComando:
        item = obter(self.session, PendenciaBikeTour, identifier)
        validar_versao(item.versao, payload.versao_esperada)
        if item.status != "ABERTA":
            raise BikeTourError(409, "BT_PENDENCIA_JA_TRATADA")
        item.status, item.motivo = "TRATADA", payload.motivo
        item.referencia_tratamento = payload.referencia_tratamento
        return ResultadoComando(200, self.salvar(item))

    def expirar_evento(self, identifier: int, payload: schemas.Alteracao) -> ResultadoComando:
        evento = obter(self.session, EventoBikeTour, identifier)
        validar_versao(evento.versao, payload.versao_esperada)
        expiradas = self.expirar()
        ids = list(
            self.session.scalars(
                select(InscricaoBikeTour.id_inscricao_bike_tour).where(
                    InscricaoBikeTour.id_evento_bike_tour == identifier,
                    InscricaoBikeTour.id_inscricao_bike_tour.in_(expiradas),
                )
            ).all()
        )
        return ResultadoComando(200, {"id_evento_bike_tour": identifier, "expiradas": ids})

    def reconciliar(self, identifier: int, payload: schemas.Reconciliacao) -> ResultadoComando:
        evento = obter(self.session, EventoBikeTour, identifier)
        validar_versao(evento.versao, payload.versao_esperada)
        inscricoes = list(
            self.session.scalars(
                select(InscricaoBikeTour)
                .where(
                    InscricaoBikeTour.id_evento_bike_tour == identifier,
                    InscricaoBikeTour.id_inscricao_bike_tour > payload.cursor,
                    InscricaoBikeTour.status.in_(ATIVAS),
                )
                .order_by(InscricaoBikeTour.id_inscricao_bike_tour)
                .limit(payload.limite + 1)
            ).all()
        )
        tratadas = []
        for item in inscricoes[: payload.limite]:
            try:
                self.origem(evento, item.id_reserva, item.id_passageiro)
            except BikeTourError as exc:
                if exc.status_code != 409:
                    raise
                item.status, item.updated_by = "CANCELADA", self.ator
                self.liberar(self.alocacoes(identifier, item.id_inscricao_bike_tour))
                self.pendencia(item, "CANCELAMENTO", "ORIGEM_INVALIDA")
                tratadas.append(item.id_inscricao_bike_tour)
        self.session.flush()
        return ResultadoComando(
            200,
            {
                "id_evento_bike_tour": identifier,
                "tratadas": tratadas,
                "proximo_cursor": inscricoes[payload.limite - 1].id_inscricao_bike_tour
                if len(inscricoes) > payload.limite
                else None,
            },
        )

    def cancelar_evento(self, evento: EventoBikeTour, motivo: str) -> None:
        for item in self.session.scalars(
            select(InscricaoBikeTour)
            .where(
                InscricaoBikeTour.id_evento_bike_tour == evento.id_evento_bike_tour,
                InscricaoBikeTour.status.in_(ATIVAS),
            )
            .order_by(InscricaoBikeTour.id_inscricao_bike_tour)
            .with_for_update()
        ).all():
            item.status, item.updated_by = "CANCELADA", self.ator
            self.pendencia(item, "CANCELAMENTO", motivo)
        self.liberar(self.alocacoes(evento.id_evento_bike_tour))
        self.session.flush()

    def reacomodar(self, identifier: int, payload: schemas.Reacomodacao) -> ResultadoComando:
        item = obter(self.session, InscricaoBikeTour, identifier)
        evento = obter(self.session, EventoBikeTour, item.id_evento_bike_tour)
        validar_versao(item.versao, payload.versao_esperada)
        if (
            item.status not in {"PENDENTE", "CONFIRMADA"}
            or evento.status != "ABERTO"
            or self.ctx.agora >= evento.inicio
        ):
            raise BikeTourError(409, "BT_REACOMODACAO_INELEGIVEL")
        self.origem(evento, item.id_reserva, item.id_passageiro)
        antigas = self.alocacoes(item.id_evento_bike_tour, identifier)
        expira = min((a.expira_em for a in antigas if a.expira_em is not None), default=None)
        if item.status == "PENDENTE" and (expira is None or expira <= self.ctx.agora):
            raise BikeTourError(409, "BT_BLOQUEIO_VENCIDO")
        destinos = sorted([payload.id_bicicleta, *payload.ids_equipamentos])
        atuais = {a.id_recurso_bike_tour for a in antigas}
        self.expirar()
        for recurso_id in destinos:
            recurso = self.recurso(
                recurso_id, {"BICICLETA" if recurso_id == payload.id_bicicleta else "EQUIPAMENTO"}
            )
            if recurso_id not in atuais:
                self.alocar(evento, recurso, item, expira)
        self.liberar([a for a in antigas if a.id_recurso_bike_tour not in destinos])
        # A versao da inscricao representa tambem a composicao de seus recursos.
        item.updated_at, item.updated_by = self.ctx.agora, self.ator
        return ResultadoComando(200, self.inscricao_resultado(item, evento))
