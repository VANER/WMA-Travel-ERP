"""Gates de rastreabilidade do inventário do Core Corporativo."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = REPOSITORY_ROOT / "Docs" / "CORE_CORPORATE_INVENTORY.md"
BASELINE_PATH = REPOSITORY_ROOT / "Database" / "scripts" / "WmaTravelERP.sql"

AUTHORITATIVE_TABLES = {
    "localidade",
    "pessoa",
    "empresa",
    "cliente",
    "fornecedor",
    "tipo_documento",
    "documento",
    "configuracao_empresa",
    "parametro_sistema",
}

AUTHORITATIVE_RELATIONSHIPS = {
    "fk_cliente_pessoa": ("id_pessoa", "public.pessoa", "id_pessoa"),
    "fk_config_empresa": ("id_empresa", "public.empresa", "id_empresa"),
    "fk_documento_tipo": (
        "id_tipo_documento",
        "public.tipo_documento",
        "id_tipo_documento",
    ),
    "fk_empresa_localidade": ("id_localidade", "public.localidade", "id_localidade"),
    "fk_fornecedor_pessoa": ("id_pessoa", "public.pessoa", "id_pessoa"),
    "fk_pessoa_localidade": ("id_localidade", "public.localidade", "id_localidade"),
}


def test_inventory_references_every_authoritative_core_table() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    for table in AUTHORITATIVE_TABLES:
        assert f"`public.{table}`" in inventory


def test_inventory_tables_exist_in_the_certified_baseline() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for table in AUTHORITATIVE_TABLES:
        assert f"CREATE TABLE public.{table} (" in baseline


def test_inventory_relationships_exist_in_the_certified_baseline() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for constraint, (
        column,
        referenced_table,
        referenced_column,
    ) in AUTHORITATIVE_RELATIONSHIPS.items():
        definition = (
            f"ADD CONSTRAINT {constraint} FOREIGN KEY ({column}) "
            f"REFERENCES {referenced_table}({referenced_column})"
        )
        assert definition in baseline


def test_inventory_preserves_deferred_domain_boundaries() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    assert "não devem ser antecipados" in inventory
    assert "Não tratar como autoridade cadastral" in inventory
    assert "não autoriza" in inventory
    assert "`app/modules/corporativo`" in inventory
    assert "`app/core` permanece reservado" in inventory
