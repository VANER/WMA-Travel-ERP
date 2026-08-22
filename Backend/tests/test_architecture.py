"""Gates automatizados para a estrutura do monólito modular."""

import ast
from importlib.util import resolve_name
from pathlib import Path

APP_ROOT = Path(__file__).parents[1] / "app"
MODULES_ROOT = APP_ROOT / "modules"
DOMAIN_NAMES = {"biketour", "comercial", "financeiro", "fiscal", "turismo"}


def _imported_modules(node: ast.Import | ast.ImportFrom, package: str) -> set[str]:
    """Normaliza módulos importados por sintaxes absolutas e relativas."""
    if isinstance(node, ast.Import):
        return {alias.name for alias in node.names}

    relative_name = f"{'.' * node.level}{node.module or ''}"
    base_module = resolve_name(relative_name, package) if node.level else node.module or ""
    imported_modules = {base_module} if base_module else set()
    imported_modules.update(f"{base_module}.{alias.name}" for alias in node.names if base_module)
    return imported_modules


def _has_forbidden_domain_import(source: str, package: str, domain: str) -> bool:
    """Informa se o código importa diretamente a implementação de outro domínio."""
    forbidden_prefixes = {
        f"app.modules.{other_domain}" for other_domain in DOMAIN_NAMES if other_domain != domain
    }

    for node in ast.walk(ast.parse(source)):
        if not isinstance(node, ast.Import | ast.ImportFrom):
            continue
        if any(
            imported == prefix or imported.startswith(f"{prefix}.")
            for imported in _imported_modules(node, package)
            for prefix in forbidden_prefixes
        ):
            return True

    return False


def test_required_modular_packages_exist() -> None:
    """Confirma as fronteiras estruturais aprovadas para a etapa 2.0.3."""
    expected_packages = {
        APP_ROOT / "integrations",
        APP_ROOT / "modules",
        APP_ROOT / "shared",
        *(MODULES_ROOT / domain for domain in DOMAIN_NAMES),
    }

    assert all((package / "__init__.py").is_file() for package in expected_packages)


def test_domains_do_not_import_other_domain_implementations() -> None:
    """Impede acoplamento direto entre implementações internas de domínios."""
    violations: list[str] = []

    for domain in DOMAIN_NAMES:
        for python_file in (MODULES_ROOT / domain).rglob("*.py"):
            relative_parent = python_file.parent.relative_to(APP_ROOT)
            package = ".".join(("app", *relative_parent.parts))
            if _has_forbidden_domain_import(
                python_file.read_text(encoding="utf-8"), package, domain
            ):
                violations.append(str(python_file.relative_to(APP_ROOT)))

    assert violations == []


def test_cross_domain_import_detector_covers_supported_syntaxes() -> None:
    """Evita regressões que permitam sintaxes alternativas entre domínios."""
    forbidden_imports = {
        "import app.modules.financeiro.service",
        "from app.modules.financeiro import service",
        "from app.modules import financeiro",
        "from ..financeiro import service",
    }

    assert all(
        _has_forbidden_domain_import(source, "app.modules.comercial", "comercial")
        for source in forbidden_imports
    )
    assert not _has_forbidden_domain_import(
        "from app.modules.comercial import service", "app.modules.comercial", "comercial"
    )
