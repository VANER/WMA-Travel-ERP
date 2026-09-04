"""Gates de rastreabilidade do inventário Financeiro."""

import re
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = REPOSITORY_ROOT / "Docs" / "FINANCIAL_INVENTORY.md"
FUNCTIONAL_MATRIX_PATH = REPOSITORY_ROOT / "Docs" / "FINANCIAL_FUNCTIONAL_MATRIX.md"
BASELINE_PATH = REPOSITORY_ROOT / "Database" / "scripts" / "WmaTravelERP.sql"
F1_FIN_PATH = REPOSITORY_ROOT / "Database" / "scripts" / "F1_FIN"

BASELINE_FINANCIAL_TABLES = {
    "anexo",
    "banco",
    "categoria",
    "centro_custo",
    "classificacao",
    "cliente",
    "conciliacao_bancaria",
    "configuracao",
    "conta",
    "conta_bancaria",
    "empresa",
    "forma_pagamento",
    "fornecedor",
    "grupo",
    "historico_lancamento",
    "lancamento",
    "lancamento_parcela",
    "movimentacao_bancaria",
    "pagamento",
    "rateio_centro_custo",
    "status_lancamento",
    "subcategoria",
    "tipo_documento",
    "tipo_lancamento",
    "tipo_movimentacao",
    "usuario",
}

F1_FIN_ONLY_TABLES = {
    "afac",
    "ativo_imobilizado",
    "caixa",
    "capital_social",
    "cartao",
    "depreciacao_ativo",
    "distribuicao_lucro",
    "emprestimo",
    "emprestimo_parcela",
    "fatura_cartao",
    "fatura_cartao_item",
    "natureza_financeira",
    "pro_labore",
    "tipo_dre",
    "transferencia",
    "tributo",
}


def _table_names(sql: str) -> set[str]:
    return set(
        re.findall(
            r"^CREATE TABLE (?:IF NOT EXISTS )?financeiro\.([a-z0-9_]+) \(",
            sql,
            flags=re.MULTILINE,
        )
    )


def test_inventory_references_every_financial_table_in_baseline() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    assert _table_names(baseline) == BASELINE_FINANCIAL_TABLES
    for table in BASELINE_FINANCIAL_TABLES:
        assert f"`financeiro.{table}`" in inventory


def test_inventory_records_f1_fin_tables_absent_from_dump() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")
    baseline = BASELINE_PATH.read_text(encoding="utf-8")
    historical_sql = "\n".join(
        path.read_text(encoding="utf-8") for path in sorted(F1_FIN_PATH.glob("*.sql"))
    )

    assert _table_names(historical_sql) == F1_FIN_ONLY_TABLES
    assert _table_names(baseline).isdisjoint(F1_FIN_ONLY_TABLES)
    for table in F1_FIN_ONLY_TABLES:
        assert f"`financeiro.{table}`" in inventory


def test_inventory_records_certified_universe_divergence() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    assert "26 tabelas e 26 sequences" in inventory
    assert "37 tabelas, 37 sequences e 96 índices" in inventory
    assert "explica os 37 objetos certificados" in inventory


def test_inventory_preserves_boundaries_and_blocks_implementation() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    assert "`app/modules/financeiro`" in inventory
    assert "autoridades corporativas" in inventory
    assert "não autorizam migrations ou regras implícitas" in inventory
    assert "reproduzido em PostgreSQL descartável" in inventory


def test_functional_matrix_covers_official_capabilities() -> None:
    matrix = FUNCTIONAL_MATRIX_PATH.read_text(encoding="utf-8")
    capabilities = {
        "Plano de contas",
        "Classificações",
        "Contas a pagar",
        "Contas a receber",
        "Parcelas",
        "Pagamentos",
        "Caixa",
        "Bancos",
        "Cartões",
        "Transferências",
        "Centros de custo",
        "Rateios",
        "Movimentações",
        "Conciliação",
        "Capital social",
        "AFAC",
        "Pró-labore",
        "Distribuição de lucros",
        "Tributos",
        "Empréstimos",
        "Imobilizado",
        "Comercial → Financeiro",
    }

    for capability in capabilities:
        assert f"| {capability} |" in matrix


def test_functional_matrix_does_not_invent_pending_rules() -> None:
    matrix = FUNCTIONAL_MATRIX_PATH.read_text(encoding="utf-8")

    assert "requisitos de decisão e teste" in matrix
    assert "não regras já comprovadas pela baseline" in matrix
    assert "Nenhum desses estados deve ser codificado" in matrix
    assert "Contábil | competência" in matrix
