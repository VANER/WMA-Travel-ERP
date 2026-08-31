"""Testes unitários do domínio Comercial integrado."""

from datetime import date
from decimal import Decimal
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.modules.comercial import router
from app.modules.comercial.models import (
    CondicaoComercial,
    Contrato,
    InteracaoLead,
    ItemProposta,
    Lead,
    Operadora,
    Oportunidade,
    Proposta,
    Venda,
)
from app.modules.comercial.repositories import (
    CondicaoComercialRepository,
    ContratoRepository,
    InteracaoLeadRepository,
    ItemPropostaRepository,
    LeadRepository,
    OperadoraRepository,
    OportunidadeRepository,
    PropostaRepository,
    VendaRepository,
)
from app.modules.comercial.schemas import (
    CondicaoComercialCreate,
    ContratoCreate,
    InteracaoLeadCreate,
    ItemPropostaCreate,
    LeadCreate,
    OperadoraCreate,
    OportunidadeCreate,
    PropostaCreate,
    TransicaoStatus,
    VendaCreate,
)
from app.modules.comercial.services import (
    CadastroService,
    RegraComercialError,
    adicionar_item,
    converter_em_venda,
    transicionar,
)


def test_repositories_cover_persistence_and_pagination() -> None:
    session = MagicMock()
    lead = Lead(nome="Lead")
    session.get.return_value = lead
    session.scalars.return_value.all.return_value = [lead]
    repository = LeadRepository(session)

    assert repository.obter(1) is lead
    assert repository.listar(offset=1, limite=2) == [lead]
    assert repository.adicionar(lead) is lead
    session.add.assert_called_once_with(lead)
    session.flush.assert_called_once()

    with pytest.raises(ValueError, match="offset"):
        repository.listar(offset=-1)
    with pytest.raises(ValueError, match="limite"):
        repository.listar(limite=0)
    with pytest.raises(ValueError, match="limite"):
        repository.listar(limite=1001)


def test_all_specialized_repositories_bind_the_expected_model() -> None:
    session = MagicMock()
    assert InteracaoLeadRepository(session).model_type is InteracaoLead
    assert OperadoraRepository(session).model_type is Operadora
    assert OportunidadeRepository(session).model_type is Oportunidade
    assert PropostaRepository(session).model_type is Proposta
    assert ItemPropostaRepository(session).model_type is ItemProposta
    assert CondicaoComercialRepository(session).model_type is CondicaoComercial
    assert VendaRepository(session).model_type is Venda
    assert ContratoRepository(session).model_type is Contrato


def test_cadastro_service_commits_and_rolls_back() -> None:
    session = MagicMock()
    repository = MagicMock()
    lead = Lead(nome="Lead")
    repository.obter.return_value = lead
    repository.listar.return_value = [lead]
    repository.adicionar.return_value = lead
    service: CadastroService[Lead] = CadastroService(session, repository)

    assert service.obter(1) is lead
    assert service.listar(offset=2, limite=3) == [lead]
    assert service.cadastrar(lead) is lead
    session.commit.assert_called_once()

    repository.adicionar.side_effect = RuntimeError("falha")
    with pytest.raises(RuntimeError, match="falha"):
        service.cadastrar(lead)
    session.rollback.assert_called_once()


@pytest.mark.parametrize(
    ("entity", "next_status"),
    [
        (Lead(nome="L", status="NOVO"), "CONTATADO"),
        (Oportunidade(id_lead=1, titulo="O", status="ABERTA"), "GANHA"),
        (
            Proposta(
                id_oportunidade=1,
                id_cliente=1,
                numero="P",
                data_emissao=date(2026, 8, 31),
                data_validade=date(2026, 9, 1),
                status="RASCUNHO",
            ),
            "ENVIADA",
        ),
    ],
)
def test_valid_status_transitions(entity: Lead | Oportunidade | Proposta, next_status: str) -> None:
    session = MagicMock()
    assert transicionar(session, entity, next_status).status == next_status
    session.commit.assert_called_once()


def test_invalid_status_transition_is_rejected() -> None:
    with pytest.raises(RegraComercialError, match="transição inválida"):
        transicionar(MagicMock(), Lead(nome="L", status="NOVO"), "CONVERTIDO")


def test_transactional_operations_roll_back_commit_failures() -> None:
    session = MagicMock()
    session.commit.side_effect = RuntimeError("commit")
    with pytest.raises(RuntimeError, match="commit"):
        transicionar(session, Lead(nome="L", status="NOVO"), "CONTATADO")
    assert session.rollback.call_count == 1

    item = ItemProposta(
        id_proposta=10,
        descricao="Hotel",
        quantidade=Decimal("1"),
        valor_unitario=Decimal("10"),
        desconto=Decimal("0"),
        valor_total=Decimal("0"),
    )
    with pytest.raises(RuntimeError, match="commit"):
        adicionar_item(session, _proposal(), item)
    assert session.rollback.call_count == 2

    with pytest.raises(RuntimeError, match="commit"):
        converter_em_venda(
            session,
            _proposal("ACEITA"),
            numero_venda="V-ROLLBACK",
            data_venda=date(2026, 8, 31),
        )
    assert session.rollback.call_count == 3


def _proposal(status_value: str = "RASCUNHO") -> Proposta:
    return Proposta(
        id_proposta=10,
        id_oportunidade=1,
        id_cliente=2,
        numero="P-1",
        data_emissao=date(2026, 8, 31),
        data_validade=date(2026, 9, 30),
        status=status_value,
        valor_bruto=Decimal("0"),
        desconto=Decimal("0"),
        valor_liquido=Decimal("0"),
    )


def test_add_item_recalculates_proposal() -> None:
    session = MagicMock()
    proposal = _proposal()
    item = ItemProposta(
        id_proposta=10,
        descricao="Hotel",
        quantidade=Decimal("2"),
        valor_unitario=Decimal("100"),
        desconto=Decimal("10"),
        valor_total=Decimal("0"),
    )
    assert adicionar_item(session, proposal, item) is item
    assert item.valor_total == Decimal("190")
    assert proposal.valor_liquido == Decimal("190")
    session.commit.assert_called_once()


def test_add_item_rejects_state_and_excessive_discount() -> None:
    item = ItemProposta(
        id_proposta=10,
        descricao="Hotel",
        quantidade=Decimal("1"),
        valor_unitario=Decimal("1"),
        desconto=Decimal("2"),
        valor_total=Decimal("0"),
    )
    with pytest.raises(RegraComercialError, match="rascunho"):
        adicionar_item(MagicMock(), _proposal("ENVIADA"), item)
    with pytest.raises(RegraComercialError, match="desconto"):
        adicionar_item(MagicMock(), _proposal(), item)


def test_convert_accepted_proposal_to_sale() -> None:
    session = MagicMock()
    proposal = _proposal("ACEITA")
    sale = converter_em_venda(session, proposal, numero_venda="V-1", data_venda=date(2026, 8, 31))
    assert sale.id_proposta == 10
    assert sale.status == "CONFIRMADA"
    session.add.assert_called_once_with(sale)
    session.commit.assert_called_once()

    with pytest.raises(RegraComercialError, match="aceita"):
        converter_em_venda(
            MagicMock(), _proposal(), numero_venda="V-2", data_venda=date(2026, 8, 31)
        )


def test_commercial_schemas_validate_dates_and_extra_fields() -> None:
    valid = PropostaCreate(
        id_oportunidade=1,
        id_cliente=1,
        numero="P",
        data_emissao=date(2026, 8, 31),
        data_validade=date(2026, 8, 31),
    )
    assert valid.numero == "P"
    with pytest.raises(ValidationError, match="data_validade"):
        PropostaCreate(
            id_oportunidade=1,
            id_cliente=1,
            numero="P",
            data_emissao=date(2026, 9, 1),
            data_validade=date(2026, 8, 31),
        )
    assert CondicaoComercialCreate(
        id_proposta=1,
        tipo="DESCONTO",
        descricao="Campanha",
        data_inicio=date(2026, 8, 31),
        data_fim=date(2026, 8, 31),
    ).ativo
    with pytest.raises(ValidationError, match="data_fim"):
        CondicaoComercialCreate(
            id_proposta=1,
            tipo="DESCONTO",
            descricao="Campanha",
            data_inicio=date(2026, 9, 1),
            data_fim=date(2026, 8, 31),
        )
    with pytest.raises(ValidationError, match="extra"):
        LeadCreate(nome="Lead", extra="proibido")  # type: ignore[call-arg]
    with pytest.raises(ValidationError, match="data_fim"):
        ContratoCreate(
            id_documento=1,
            data_inicio=date(2026, 9, 1),
            data_fim=date(2026, 8, 31),
        )


def test_router_helpers() -> None:
    lead = Lead(nome="Lead")
    assert router._required(lead) is lead
    assert isinstance(router._service(MagicMock(), LeadRepository(MagicMock())), CadastroService)
    with pytest.raises(HTTPException) as exc_info:
        router._required(None)
    assert exc_info.value.status_code == 404
    conflict = router._conflict(RegraComercialError("regra"))
    assert conflict.status_code == 409


def test_router_crud_functions(monkeypatch: pytest.MonkeyPatch) -> None:
    session = MagicMock()
    service = MagicMock()
    service.listar.return_value = []
    monkeypatch.setattr(router, "_service", lambda *_: service)

    assert router.listar_leads(session, 0, 10) == []
    router.cadastrar_lead(LeadCreate(nome="Lead"), session)
    router.registrar_interacao(InteracaoLeadCreate(id_lead=1), session)
    assert router.listar_operadoras(session, 0, 10) == []
    router.cadastrar_operadora(OperadoraCreate(id_fornecedor=1, codigo="OP"), session)
    assert router.listar_oportunidades(session, 0, 10) == []
    router.cadastrar_oportunidade(OportunidadeCreate(id_lead=1, titulo="O"), session)
    assert router.listar_propostas(session, 0, 10) == []
    router.cadastrar_proposta(
        PropostaCreate(
            id_oportunidade=1,
            id_cliente=1,
            numero="P",
            data_emissao=date(2026, 8, 31),
            data_validade=date(2026, 9, 1),
        ),
        session,
    )
    router.cadastrar_condicao(
        CondicaoComercialCreate(
            id_proposta=1,
            tipo="DESCONTO",
            descricao="D",
            data_inicio=date(2026, 8, 31),
        ),
        session,
    )
    assert router.listar_vendas(session, 0, 10) == []
    assert router.listar_contratos(session, 0, 10) == []
    router.cadastrar_contrato(ContratoCreate(id_documento=1), session)
    assert service.cadastrar.call_count == 7


def test_router_business_functions_and_conflicts(monkeypatch: pytest.MonkeyPatch) -> None:
    session = MagicMock()
    lead = Lead(id_lead=1, nome="L", status="NOVO")
    opportunity = Oportunidade(id_oportunidade=1, id_lead=1, titulo="O", status="ABERTA")
    proposal = _proposal()
    monkeypatch.setattr(LeadRepository, "obter", lambda *_: lead)
    monkeypatch.setattr(OportunidadeRepository, "obter", lambda *_: opportunity)
    monkeypatch.setattr(PropostaRepository, "obter", lambda *_: proposal)

    assert router.transicionar_lead(1, TransicaoStatus(status="CONTATADO"), session) is lead
    assert (
        router.transicionar_oportunidade(1, TransicaoStatus(status="GANHA"), session) is opportunity
    )
    assert router.transicionar_proposta(1, TransicaoStatus(status="ENVIADA"), session) is proposal

    proposal.status = "RASCUNHO"
    item = router.cadastrar_item_proposta(
        ItemPropostaCreate(
            id_proposta=10,
            descricao="I",
            quantidade=Decimal("1"),
            valor_unitario=Decimal("10"),
        ),
        session,
    )
    assert item.valor_total == Decimal("10")

    proposal.status = "ACEITA"
    assert (
        router.cadastrar_venda(
            VendaCreate(
                id_proposta=10,
                numero_venda="V",
                data_venda=date(2026, 8, 31),
            ),
            session,
        ).id_proposta
        == 10
    )

    lead.status = "PERDIDO"
    with pytest.raises(HTTPException) as exc_info:
        router.transicionar_lead(1, TransicaoStatus(status="NOVO"), session)
    assert exc_info.value.status_code == 409
    opportunity.status = "PERDIDA"
    with pytest.raises(HTTPException):
        router.transicionar_oportunidade(1, TransicaoStatus(status="ABERTA"), session)
    proposal.status = "CANCELADA"
    with pytest.raises(HTTPException):
        router.transicionar_proposta(1, TransicaoStatus(status="ENVIADA"), session)
    proposal.status = "ENVIADA"
    with pytest.raises(HTTPException):
        router.cadastrar_item_proposta(
            ItemPropostaCreate(
                id_proposta=10,
                descricao="I",
                quantidade=Decimal("1"),
                valor_unitario=Decimal("10"),
            ),
            session,
        )
    with pytest.raises(HTTPException):
        router.cadastrar_venda(
            VendaCreate(
                id_proposta=10,
                numero_venda="V",
                data_venda=date(2026, 8, 31),
            ),
            session,
        )
