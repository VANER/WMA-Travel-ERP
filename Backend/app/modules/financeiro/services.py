"""Casos de uso transacionais do domínio Financeiro."""

from datetime import UTC, datetime
from decimal import ROUND_HALF_UP, Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.financeiro.models import (
    Conciliacao,
    Lancamento,
    Movimentacao,
    Pagamento,
    Parcela,
    PeriodoFinanceiro,
    Transferencia,
)
from app.modules.financeiro.repositories import (
    LancamentoRepository,
    PagamentoRepository,
    ParcelaRepository,
)
from app.modules.financeiro.schemas import (
    ConciliacaoCreate,
    LancamentoCreate,
    PagamentoCreate,
    TransferenciaCreate,
    VendaFinanceiroCreate,
)
from app.shared.vendas import VendaFinanceira

CENTAVO = Decimal("0.01")


class RegraFinanceiraError(Exception):
    """Violação esperada de regra financeira."""


def _money(value: Decimal) -> Decimal:
    return value.quantize(CENTAVO, rounding=ROUND_HALF_UP)


def _commit(session: Session) -> None:
    try:
        session.commit()
    except Exception:
        session.rollback()
        raise


def _garantir_periodo_aberto(session: Session, competencia: object) -> None:
    fechado = session.scalar(
        select(PeriodoFinanceiro).where(
            PeriodoFinanceiro.competencia == competencia,
            PeriodoFinanceiro.fechado.is_(True),
        )
    )
    if fechado is not None:
        raise RegraFinanceiraError("período financeiro fechado")


def criar_lancamento(session: Session, payload: LancamentoCreate) -> Lancamento:
    """Cria lançamento e parcelas na mesma transação."""
    _garantir_periodo_aberto(session, payload.competencia.replace(day=1))
    repository = LancamentoRepository(session)
    if payload.chave_idempotencia:
        existente = repository.por_chave(payload.chave_idempotencia)
        if existente is not None:
            return existente
    data = payload.model_dump(exclude={"parcelas"})
    lancamento = repository.adicionar(Lancamento(**data))
    for numero, item in enumerate(payload.parcelas, start=1):
        session.add(
            Parcela(
                id_lancamento=lancamento.id_lancamento,
                numero_parcela=numero,
                vencimento=item.vencimento,
                valor=_money(item.valor),
                valor_pago=Decimal("0"),
                saldo=_money(item.valor),
            )
        )
    _commit(session)
    session.refresh(lancamento)
    return lancamento


def liquidar_parcela(session: Session, id_parcela: int, payload: PagamentoCreate) -> Pagamento:
    """Registra pagamento e movimento sob lock da parcela."""
    pagamentos = PagamentoRepository(session)
    existente = pagamentos.por_chave(payload.chave_idempotencia)
    if existente is not None:
        return existente
    parcela = ParcelaRepository(session).obter(id_parcela, bloquear=True)
    if parcela is None:
        raise RegraFinanceiraError("parcela não encontrada")
    valor_baixa = _money(payload.valor + payload.juros + payload.multa - payload.desconto)
    if valor_baixa <= 0 or valor_baixa > parcela.saldo:
        raise RegraFinanceiraError("valor de liquidação inválido para o saldo da parcela")
    pagamento_data = payload.model_dump(exclude={"id_tipo_movimentacao"})
    pagamento = pagamentos.adicionar(Pagamento(id_parcela=id_parcela, **pagamento_data))
    parcela.valor_pago = _money(parcela.valor_pago + valor_baixa)
    parcela.saldo = _money(parcela.valor - parcela.valor_pago)
    session.add(
        Movimentacao(
            id_conta_bancaria=payload.id_conta_bancaria,
            id_pagamento=pagamento.id_pagamento,
            id_tipo_movimentacao=payload.id_tipo_movimentacao,
            data_movimento=payload.data_pagamento,
            valor=valor_baixa,
            historico=f"Liquidação da parcela {id_parcela}",
        )
    )
    lancamento = LancamentoRepository(session).obter(parcela.id_lancamento, bloquear=True)
    if lancamento is None:
        raise RegraFinanceiraError("lançamento da parcela não encontrado")
    lancamento.valor_pago = _money(lancamento.valor_pago + valor_baixa)
    _commit(session)
    return pagamento


def transferir(session: Session, payload: TransferenciaCreate) -> Transferencia:
    """Cria transferência e seus movimentos opostos atomicamente."""
    existente = session.scalar(
        select(Transferencia).where(Transferencia.codigo == payload.chave_idempotencia)
    )
    if existente is not None:
        return existente
    transferencia = Transferencia(
        codigo=payload.chave_idempotencia,
        id_conta_origem=payload.id_conta_origem,
        id_conta_destino=payload.id_conta_destino,
        data_transferencia=payload.data_transferencia,
        valor=payload.valor,
        historico=payload.observacao,
        status="EFETIVADA",
    )
    session.add(transferencia)
    for conta, tipo, historico in (
        (payload.id_conta_origem, payload.id_tipo_saida, "Saída por transferência"),
        (payload.id_conta_destino, payload.id_tipo_entrada, "Entrada por transferência"),
    ):
        session.add(
            Movimentacao(
                id_conta_bancaria=conta,
                id_tipo_movimentacao=tipo,
                data_movimento=payload.data_transferencia,
                valor=_money(payload.valor),
                historico=f"{historico}: {payload.chave_idempotencia}",
            )
        )
    _commit(session)
    return transferencia


def conciliar(session: Session, id_movimento: int, payload: ConciliacaoCreate) -> Conciliacao:
    """Concilia uma movimentação uma única vez."""
    existente = session.scalar(select(Conciliacao).where(Conciliacao.id_movimento == id_movimento))
    if existente is not None and existente.conciliado:
        return existente
    if session.get(Movimentacao, id_movimento) is None:
        raise RegraFinanceiraError("movimentação não encontrada")
    conciliacao = existente or Conciliacao(id_movimento=id_movimento)
    conciliacao.data_conciliacao = payload.data_conciliacao
    conciliacao.observacao = payload.observacao
    conciliacao.conciliado = True
    session.add(conciliacao)
    _commit(session)
    return conciliacao


def gerar_da_venda(
    session: Session, venda: VendaFinanceira, payload: VendaFinanceiroCreate
) -> Lancamento:
    """Gera um lançamento idempotente para uma venda confirmada."""
    if venda.status != "CONFIRMADA" or venda.valor_liquido is None:
        raise RegraFinanceiraError("somente venda confirmada com valor pode gerar financeiro")
    quantidade = len(payload.vencimentos)
    total = _money(venda.valor_liquido)
    base = _money(total / quantidade)
    valores = [base] * quantidade
    valores[-1] = _money(total - sum(valores[:-1], Decimal("0")))
    lancamento_payload = LancamentoCreate(
        numero=f"VENDA-{venda.id_venda}",
        id_empresa=1,
        id_tipo_lancamento=payload.id_tipo_lancamento,
        id_status=payload.id_status,
        id_conta=payload.id_conta,
        id_cliente=venda.id_cliente,
        competencia=payload.emissao,
        emissao=payload.emissao,
        vencimento=max(payload.vencimentos),
        valor_bruto=total,
        descricao=f"Venda {venda.numero_venda}",
        chave_idempotencia=f"VENDA:{venda.id_venda}",
        parcelas=[
            {"vencimento": vencimento, "valor": valor}
            for vencimento, valor in zip(payload.vencimentos, valores, strict=True)
        ],
    )
    lancamento = criar_lancamento(session, lancamento_payload)
    if lancamento.id_venda_origem is None:
        lancamento.id_venda_origem = venda.id_venda
        _commit(session)
    return lancamento


def fechar_periodo(session: Session, periodo: PeriodoFinanceiro) -> PeriodoFinanceiro:
    periodo.fechado = True
    periodo.fechado_em = datetime.now(UTC).replace(tzinfo=None)
    _commit(session)
    return periodo
