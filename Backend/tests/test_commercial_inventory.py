"""Gates de rastreabilidade do inventário Comercial."""

import re
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = REPOSITORY_ROOT / "Docs" / "COMMERCIAL_INVENTORY.md"
BASELINE_PATH = REPOSITORY_ROOT / "Database" / "scripts" / "WmaTravelERP.sql"

COMMERCIAL_TABLES = {
    "cliente",
    "comissao",
    "comissao_colaborador",
    "contato_cliente",
    "contrato",
    "fornecedor",
    "fornecedor_turistico",
    "funil_vendas",
    "interacao_lead",
    "item_venda",
    "lead",
    "origem_lead",
    "venda",
}

RELATED_COMMERCIAL_TABLES = {"campanha", "parceiro_comercial"}

COMMERCIAL_RELATIONSHIPS = {
    "fk_cliente_pessoa": ("cliente", "id_pessoa", "public.pessoa", "id_pessoa"),
    "fk_comissao_colaborador": (
        "comissao_colaborador",
        "id_colaborador",
        "public.colaborador",
        "id_colaborador",
    ),
    "fk_comissao_fornecedor": (
        "comissao",
        "id_fornecedor",
        "public.fornecedor",
        "id_fornecedor",
    ),
    "fk_comissao_reserva": (
        "comissao",
        "id_reserva",
        "public.reserva",
        "id_reserva",
    ),
    "fk_comissao_venda": (
        "comissao_colaborador",
        "id_venda",
        "public.venda",
        "id_venda",
    ),
    "fk_contato_cliente": (
        "contato_cliente",
        "id_cliente",
        "public.cliente",
        "id_cliente",
    ),
    "fk_contrato_documento": (
        "contrato",
        "id_documento",
        "public.documento",
        "id_documento",
    ),
    "fk_fornecedor_pessoa": (
        "fornecedor",
        "id_pessoa",
        "public.pessoa",
        "id_pessoa",
    ),
    "fk_ft_fornecedor": (
        "fornecedor_turistico",
        "id_fornecedor",
        "public.fornecedor",
        "id_fornecedor",
    ),
    "fk_funil_lead": ("funil_vendas", "id_lead", "public.lead", "id_lead"),
    "fk_item_produto": (
        "item_venda",
        "id_produto",
        "public.produto_turistico",
        "id_produto",
    ),
    "fk_item_venda": ("item_venda", "id_venda", "public.venda", "id_venda"),
    "fk_interacao_lead": (
        "interacao_lead",
        "id_lead",
        "public.lead",
        "id_lead",
    ),
    "fk_lead_origem": (
        "lead",
        "id_origem",
        "public.origem_lead",
        "id_origem",
    ),
    "fk_venda_cliente": (
        "venda",
        "id_cliente",
        "public.cliente",
        "id_cliente",
    ),
}

ABSENT_PLANNED_TABLES = {
    "condicao_comercial",
    "item_proposta",
    "operadora",
    "oportunidade",
    "proposta",
}


def test_inventory_references_every_commercial_table() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    for table in COMMERCIAL_TABLES:
        assert f"`public.{table}`" in inventory


def test_inventory_tables_exist_in_the_certified_baseline() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for table in COMMERCIAL_TABLES:
        assert f"CREATE TABLE public.{table} (" in baseline


def test_inventory_relationships_exist_in_the_certified_baseline() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for constraint, relationship in COMMERCIAL_RELATIONSHIPS.items():
        source_table, column, referenced_table, referenced_column = relationship
        definition = (
            f"ALTER TABLE ONLY public.{source_table}\n"
            f"    ADD CONSTRAINT {constraint} FOREIGN KEY ({column}) "
            f"REFERENCES {referenced_table}({referenced_column})"
        )
        assert definition in baseline


def test_inventory_classifies_isolated_and_analytical_structures() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for table in RELATED_COMMERCIAL_TABLES:
        assert f"CREATE TABLE public.{table} (" in baseline
        assert f"`public.{table}`" in inventory

    assert "CREATE VIEW public.vw_dashboard_comercial_bi AS" in baseline
    assert "`public.vw_dashboard_comercial_bi`" in inventory


def test_inventory_records_absent_planned_aggregates() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for table in ABSENT_PLANNED_TABLES:
        pattern = rf"^CREATE TABLE [a-z_]+\.{table} \("
        assert re.search(pattern, baseline, flags=re.MULTILINE) is None
        assert f"`{table}`" in inventory


def test_inventory_preserves_domain_boundaries_and_baseline() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    assert "`app/modules/comercial`" in inventory
    assert "continuam sendo autoridades cadastrais compartilhadas" in inventory
    assert "não autorizam criar estruturas" in inventory
    assert "não devem ser corrigidas retroativamente" in inventory
