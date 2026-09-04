"""Testes unitários do domínio Financeiro integrado."""

from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.modules.financeiro import router
from app.modules.financeiro.models import (
    Lancamento,
    Pagamento,
    Parcela,
    PeriodoFinanceiro,
    Transferencia,
)
from app.modules.financeiro.repositories import (
    LancamentoRepository,
    PagamentoRepository,
    ParcelaRepository,
    Repository,
)
from app.modules.financeiro.schemas import (
    ConciliacaoCreate,
    LancamentoCreate,
    PagamentoCreate,
    PeriodoCreate,
    TransferenciaCreate,
    VendaFinanceiroCreate,
)
from app.modules.financeiro.services import (
    RegraFinanceiraError,
    conciliar,
    criar_lancamento,
    fechar_periodo,
    gerar_da_venda,
    liquidar_parcela,
    transferir,
)
from app.shared.vendas import obter_venda_financeira

HOJE = date(2026, 9, 3)


def _lancamento_payload() -> LancamentoCreate:
    return LancamentoCreate(
        numero="L-1",
        id_empresa=1,
        id_tipo_lancamento=1,
        id_status=1,
        id_conta=1,
        competencia=HOJE,
        emissao=HOJE,
        vencimento=HOJE,
        valor_bruto=Decimal("100"),
        chave_idempotencia="origem:1",
        parcelas=[{"vencimento": HOJE, "valor": Decimal("100")}],
    )


def _pagamento_payload() -> PagamentoCreate:
    return PagamentoCreate(
        id_conta_bancaria=1,
        id_forma_pagamento=1,
        id_tipo_movimentacao=1,
        data_pagamento=HOJE,
        valor=Decimal("40"),
        chave_idempotencia="pag:1",
    )


def _transferencia_payload() -> TransferenciaCreate:
    return TransferenciaCreate(
        id_conta_origem=1,
        id_conta_destino=2,
        id_tipo_saida=1,
        id_tipo_entrada=2,
        data_transferencia=HOJE,
        valor=Decimal("10"),
        chave_idempotencia="transf:1",
    )


def test_schemas_validate_financial_invariants() -> None:
    assert _lancamento_payload().valor_bruto == Decimal("100")
    with pytest.raises(ValidationError, match="soma das parcelas"):
        _lancamento_payload().model_copy(update={"parcelas": []}).model_validate(
            {
                **_lancamento_payload().model_dump(),
                "parcelas": [{"vencimento": HOJE, "valor": "99"}],
            }
        )
    data = _lancamento_payload().model_dump()
    data["competencia"] = date(2026, 9, 2)
    data["emissao"] = HOJE
    with pytest.raises(ValidationError, match="não podem anteceder"):
        LancamentoCreate.model_validate(data)
    with pytest.raises(ValidationError, match="diferentes"):
        TransferenciaCreate(
            id_conta_origem=1,
            id_conta_destino=1,
            id_tipo_saida=1,
            id_tipo_entrada=2,
            data_transferencia=HOJE,
            valor=Decimal("1"),
            chave_idempotencia="x",
        )


def test_repository_get_list_add_and_validation() -> None:
    session = MagicMock()
    entity = PeriodoFinanceiro(competencia=HOJE, fechado=False)
    session.get.return_value = entity
    session.scalars.return_value.all.return_value = [entity]
    repository = Repository(session, PeriodoFinanceiro)
    assert repository.obter(1) is entity
    assert repository.listar(offset=1, limite=2) == [entity]
    assert repository.adicionar(entity) is entity
    with pytest.raises(ValueError, match="paginação"):
        repository.listar(offset=-1)
    with pytest.raises(ValueError, match="paginação"):
        repository.listar(limite=0)
    session.scalar.return_value = entity
    assert repository.obter(1, bloquear=True) is entity


def test_specialized_repositories_and_idempotent_queries() -> None:
    session = MagicMock()
    session.scalar.return_value = object()
    assert LancamentoRepository(session).por_chave("x") is session.scalar.return_value
    assert PagamentoRepository(session).por_chave("x") is session.scalar.return_value
    assert ParcelaRepository(session).model_type is Parcela
    session.get.return_value = object()
    assert obter_venda_financeira(session, 1) is session.get.return_value


def test_create_lancamento_is_atomic_and_idempotent() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    persisted = Lancamento(
        id_lancamento=1, **_lancamento_payload().model_dump(exclude={"parcelas"})
    )
    repository = MagicMock()
    repository.por_chave.return_value = persisted
    with patch("app.modules.financeiro.services.LancamentoRepository", return_value=repository):
        assert criar_lancamento(session, _lancamento_payload()) is persisted
    repository.por_chave.return_value = None
    repository.adicionar.return_value = persisted
    session.scalar.return_value = None
    with patch("app.modules.financeiro.services.LancamentoRepository", return_value=repository):
        assert criar_lancamento(session, _lancamento_payload()) is persisted
    session.add.assert_called_once()
    session.commit.assert_called_once()
    session.refresh.assert_called_once_with(persisted)


def test_create_lancamento_rejects_closed_period_and_rolls_back_commit() -> None:
    session = MagicMock()
    session.scalar.return_value = PeriodoFinanceiro(competencia=HOJE, fechado=True)
    with pytest.raises(RegraFinanceiraError, match="fechado"):
        criar_lancamento(session, _lancamento_payload())
    session.scalar.return_value = None
    session.commit.side_effect = RuntimeError("commit")
    repository = MagicMock()
    repository.por_chave.return_value = None
    repository.adicionar.return_value = Lancamento(
        id_lancamento=1, **_lancamento_payload().model_dump(exclude={"parcelas"})
    )
    with (
        patch("app.modules.financeiro.services.LancamentoRepository", return_value=repository),
        pytest.raises(RuntimeError, match="commit"),
    ):
        criar_lancamento(session, _lancamento_payload())
    session.rollback.assert_called_once()


def test_liquidation_idempotency_missing_and_invalid_balance() -> None:
    session = MagicMock()
    payment = Pagamento(
        id_pagamento=1,
        id_parcela=1,
        **_pagamento_payload().model_dump(exclude={"id_tipo_movimentacao"}),
    )
    payment_repository = MagicMock()
    payment_repository.por_chave.return_value = payment
    with patch(
        "app.modules.financeiro.services.PagamentoRepository", return_value=payment_repository
    ):
        assert liquidar_parcela(session, 1, _pagamento_payload()) is payment
    payment_repository.por_chave.return_value = None
    parcela_repository = MagicMock()
    parcela_repository.obter.return_value = None
    with (
        patch(
            "app.modules.financeiro.services.PagamentoRepository", return_value=payment_repository
        ),
        patch("app.modules.financeiro.services.ParcelaRepository", return_value=parcela_repository),
        pytest.raises(RegraFinanceiraError, match="não encontrada"),
    ):
        liquidar_parcela(session, 1, _pagamento_payload())
    parcela_repository.obter.return_value = Parcela(
        id_parcela=1,
        id_lancamento=1,
        numero_parcela=1,
        vencimento=HOJE,
        valor=Decimal("20"),
        valor_pago=Decimal("0"),
        saldo=Decimal("20"),
    )
    with (
        patch(
            "app.modules.financeiro.services.PagamentoRepository", return_value=payment_repository
        ),
        patch("app.modules.financeiro.services.ParcelaRepository", return_value=parcela_repository),
        pytest.raises(RegraFinanceiraError, match="saldo"),
    ):
        liquidar_parcela(session, 1, _pagamento_payload())


def test_liquidation_updates_parcela_lancamento_and_movement() -> None:
    session = MagicMock()
    parcela = Parcela(
        id_parcela=1,
        id_lancamento=2,
        numero_parcela=1,
        vencimento=HOJE,
        valor=Decimal("100"),
        valor_pago=Decimal("0"),
        saldo=Decimal("100"),
    )
    lancamento = Lancamento(
        id_lancamento=2,
        valor_pago=Decimal("0"),
        **_lancamento_payload().model_dump(exclude={"parcelas"}),
    )
    pagamento = Pagamento(
        id_pagamento=3,
        id_parcela=1,
        **_pagamento_payload().model_dump(exclude={"id_tipo_movimentacao"}),
    )
    pagamentos = MagicMock()
    pagamentos.por_chave.return_value = None
    pagamentos.adicionar.return_value = pagamento
    parcelas = MagicMock()
    parcelas.obter.return_value = parcela
    lancamentos = MagicMock()
    lancamentos.obter.return_value = lancamento
    with (
        patch("app.modules.financeiro.services.PagamentoRepository", return_value=pagamentos),
        patch("app.modules.financeiro.services.ParcelaRepository", return_value=parcelas),
        patch("app.modules.financeiro.services.LancamentoRepository", return_value=lancamentos),
    ):
        assert liquidar_parcela(session, 1, _pagamento_payload()) is pagamento
    assert parcela.saldo == Decimal("60.00")
    assert lancamento.valor_pago == Decimal("40.00")
    session.commit.assert_called_once()
    lancamentos.obter.return_value = None
    with (
        patch("app.modules.financeiro.services.PagamentoRepository", return_value=pagamentos),
        patch("app.modules.financeiro.services.ParcelaRepository", return_value=parcelas),
        patch("app.modules.financeiro.services.LancamentoRepository", return_value=lancamentos),
        pytest.raises(RegraFinanceiraError, match="lançamento"),
    ):
        liquidar_parcela(session, 1, _pagamento_payload())


def test_transfer_and_conciliation_flows() -> None:
    session = MagicMock()
    existing = Transferencia(
        codigo="transf:1",
        id_conta_origem=1,
        id_conta_destino=2,
        data_transferencia=HOJE,
        valor=Decimal("10"),
        status="EFETIVADA",
    )
    session.scalar.return_value = existing
    assert transferir(session, _transferencia_payload()) is existing
    session.scalar.return_value = None
    result = transferir(session, _transferencia_payload())
    assert isinstance(result, Transferencia)
    assert session.add.call_count == 3
    movement = MagicMock()
    session.get.return_value = movement
    result_conciliacao = conciliar(session, 1, ConciliacaoCreate(data_conciliacao=HOJE))
    assert result_conciliacao.conciliado
    session.scalar.return_value = result_conciliacao
    assert conciliar(session, 1, ConciliacaoCreate(data_conciliacao=HOJE)) is result_conciliacao
    session.scalar.return_value = None
    session.get.return_value = None
    with pytest.raises(RegraFinanceiraError, match="movimentação"):
        conciliar(session, 2, ConciliacaoCreate(data_conciliacao=HOJE))


def test_sale_integration_and_period_closing() -> None:
    session = MagicMock()
    payload = VendaFinanceiroCreate(
        id_conta=1,
        id_tipo_lancamento=1,
        id_status=1,
        emissao=HOJE,
        vencimentos=[HOJE, date(2026, 10, 3), date(2026, 11, 3)],
    )
    venda = SimpleNamespace(
        id_venda=1,
        id_cliente=2,
        numero_venda="V-1",
        valor_liquido=Decimal("100"),
        status="CONFIRMADA",
    )
    lancamento = Lancamento(id_lancamento=1, id_venda_origem=None)
    with patch(
        "app.modules.financeiro.services.criar_lancamento", return_value=lancamento
    ) as criar:
        assert gerar_da_venda(session, venda, payload) is lancamento
    valores = [item.valor for item in criar.call_args.args[1].parcelas]
    assert valores == [Decimal("33.33"), Decimal("33.33"), Decimal("33.34")]
    assert lancamento.id_venda_origem == 1
    lancamento.id_venda_origem = 1
    with patch("app.modules.financeiro.services.criar_lancamento", return_value=lancamento):
        gerar_da_venda(session, venda, payload)
    venda.status = "RASCUNHO"
    with pytest.raises(RegraFinanceiraError, match="confirmada"):
        gerar_da_venda(session, venda, payload)
    periodo = PeriodoFinanceiro(competencia=HOJE, fechado=False)
    assert fechar_periodo(session, periodo).fechado
    assert periodo.fechado_em is not None


def test_router_helpers_and_main_operations() -> None:
    session = MagicMock()
    payload = _lancamento_payload()
    lancamento = Lancamento(id_lancamento=1)
    with patch(
        "app.modules.financeiro.router.LancamentoRepository.listar",
        return_value=[lancamento],
    ):
        assert router.listar_lancamentos(session) == [lancamento]
    with patch.object(router, "criar_lancamento", return_value=lancamento):
        assert router.cadastrar_lancamento(payload, session) is lancamento
    with patch.object(router, "criar_lancamento", side_effect=RegraFinanceiraError("regra")):
        with pytest.raises(HTTPException) as exc:
            router.cadastrar_lancamento(payload, session)
        assert exc.value.status_code == 409
    with (
        patch.object(router, "liquidar_parcela", side_effect=RegraFinanceiraError("regra")),
        pytest.raises(HTTPException),
    ):
        router.cadastrar_pagamento(1, _pagamento_payload(), session)
    with (
        patch.object(router, "conciliar", side_effect=RegraFinanceiraError("regra")),
        pytest.raises(HTTPException),
    ):
        router.cadastrar_conciliacao(1, ConciliacaoCreate(data_conciliacao=HOJE), session)


def test_router_sale_period_and_generic_resources() -> None:
    session = MagicMock()
    sale_payload = VendaFinanceiroCreate(
        id_conta=1,
        id_tipo_lancamento=1,
        id_status=1,
        emissao=HOJE,
        vencimentos=[HOJE],
    )
    with patch.object(router, "obter_venda_financeira", return_value=None):
        with pytest.raises(HTTPException) as exc:
            router.cadastrar_financeiro_venda(1, sale_payload, session)
        assert exc.value.status_code == 404
    venda = MagicMock()
    with (
        patch.object(router, "obter_venda_financeira", return_value=venda),
        patch.object(router, "gerar_da_venda", side_effect=RegraFinanceiraError("regra")),
        pytest.raises(HTTPException),
    ):
        router.cadastrar_financeiro_venda(1, sale_payload, session)
    periodo = router.cadastrar_periodo(PeriodoCreate(competencia=HOJE), session)
    assert periodo.competencia.day == 1
    session.get.return_value = None
    with (
        patch("app.modules.financeiro.router.Repository.obter", return_value=None),
        pytest.raises(HTTPException),
    ):
        router.fechar(1, session)
    with (
        patch("app.modules.financeiro.router.Repository.obter", return_value=periodo),
        patch.object(router, "fechar_periodo", return_value=periodo),
    ):
        assert router.fechar(1, session) is periodo
    transferencia = Transferencia(
        id_transferencia=1,
        codigo="transf:1",
        id_conta_origem=1,
        id_conta_destino=2,
        data_transferencia=HOJE,
        valor=Decimal("10"),
        status="EFETIVADA",
    )
    with patch.object(router, "transferir", return_value=transferencia):
        assert (
            router.cadastrar_transferencia(_transferencia_payload(), session).id_transferencia == 1
        )
