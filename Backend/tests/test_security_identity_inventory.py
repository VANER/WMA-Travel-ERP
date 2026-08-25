"""Gates de rastreabilidade do inventário de identidade e acesso."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = REPOSITORY_ROOT / "Docs" / "SECURITY_IDENTITY_INVENTORY.md"
BASELINE_PATH = REPOSITORY_ROOT / "Database" / "scripts" / "WmaTravelERP.sql"

HUMAN_IDENTITY_TABLES = {
    "usuario",
    "perfil_acesso",
    "usuario_perfil",
    "permissao",
    "politica_acesso",
}

APPLICATION_IDENTITY_TABLES = {
    "aplicacao_api",
    "chave_api",
    "token_acesso",
}


def test_inventory_references_every_identity_authority() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")

    for table in HUMAN_IDENTITY_TABLES | APPLICATION_IDENTITY_TABLES:
        assert f"`public.{table}`" in inventory
    assert "`financeiro.usuario`" in inventory


def test_identity_authorities_exist_in_the_certified_baseline() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    for table in HUMAN_IDENTITY_TABLES | APPLICATION_IDENTITY_TABLES:
        assert f"CREATE TABLE public.{table} (" in baseline
    assert "CREATE TABLE financeiro.usuario (" in baseline


def test_certified_relationships_are_not_reinterpreted() -> None:
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    assert (
        "ADD CONSTRAINT fk_usuario_perfil_usuario FOREIGN KEY (id_usuario) "
        "REFERENCES public.usuario(id_usuario)"
    ) in baseline
    assert (
        "ADD CONSTRAINT fk_usuario_perfil_perfil FOREIGN KEY (id_perfil) "
        "REFERENCES public.perfil_acesso(id_perfil)"
    ) in baseline
    assert (
        "ADD CONSTRAINT fk_token_aplicacao FOREIGN KEY (id_aplicacao) "
        "REFERENCES public.aplicacao_api(id_aplicacao)"
    ) in baseline


def test_inventory_records_the_rbac_gap_and_safe_boundaries() -> None:
    inventory = INVENTORY_PATH.read_text(encoding="utf-8")
    baseline = BASELINE_PATH.read_text(encoding="utf-8")

    assert "não existe associação" in inventory
    assert "não pode ser reutilizado como access token" in inventory
    assert "negar acesso por padrão" in inventory
    assert "não devem ser corrigidas retroativamente" in inventory
    assert "perfil_permissao" not in baseline
