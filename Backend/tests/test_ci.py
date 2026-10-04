"""Gates de regressão da configuração de integração contínua."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
WORKFLOW_PATH = REPOSITORY_ROOT / ".github" / "workflows" / "backend-ci.yml"
CODEOWNERS_PATH = REPOSITORY_ROOT / ".github" / "CODEOWNERS"
PULL_REQUEST_TEMPLATE_PATH = REPOSITORY_ROOT / ".github" / "pull_request_template.md"


def _workflow() -> str:
    return WORKFLOW_PATH.read_text(encoding="utf-8")


def test_backend_workflow_has_bounded_read_only_job() -> None:
    workflow = _workflow()

    assert "permissions:\n  contents: read" in workflow
    assert "timeout-minutes: 10" in workflow
    assert "cancel-in-progress: true" in workflow


def test_backend_workflow_provisions_disposable_postgresql() -> None:
    workflow = _workflow()

    assert "image: postgres:18" in workflow
    assert "POSTGRES_DB: wma_phase2_test" in workflow
    assert "WMA_TEST_DATABASE_URL:" in workflow
    assert "--health-cmd" in workflow


def test_backend_workflow_runs_all_quality_gates() -> None:
    workflow = _workflow()

    required_commands = {
        "python -m pip check",
        "ruff check .",
        "ruff format --check app tests migrations scripts",
        "mypy app tests scripts",
        "pytest -W error --ignore=tests/integration --cov=app --cov-report=term-missing",
        "python scripts/export_openapi.py --check",
        'python scripts/check_openapi_compatibility.py --base-ref "$WMA_OPENAPI_BASE_REF"',
        "alembic heads",
        "alembic upgrade head",
    }

    for command in required_commands:
        assert f"run: {command}" in workflow

    assert "fetch-depth: 0" in workflow
    assert "if: github.event_name == 'pull_request'" in workflow


def test_backend_workflow_isolates_orm_from_migrated_baseline() -> None:
    workflow = _workflow()
    orm_start = workflow.index("- name: Executar integração PostgreSQL dos recortes ORM")
    orm_end = workflow.index("- name:", orm_start + 1)
    orm_step = workflow[orm_start:orm_end]
    assert "WMA_TEST_DATABASE_URL:" in orm_step
    assert "localhost:5432/wma_orm_test" in orm_step
    assert "createdb --host localhost --username wma_test wma_orm_test" in orm_step
    assert "wma_phase2_test" not in orm_step
    assert "--run-postgresql --no-cov" in orm_step

    baseline = workflow.index("- name: Restaurar baseline certificada")
    upgrade = workflow.index("run: alembic upgrade head", baseline)
    downgrade = workflow.index("run: alembic downgrade -1", upgrade)
    reupgrade = workflow.index("run: alembic upgrade head", downgrade)
    bike_start = workflow.index("- name: Validar Bike Tour sobre a baseline migrada")
    assert orm_end < baseline < upgrade < downgrade < reupgrade < bike_start
    bike_step = workflow[bike_start:]
    assert "--run-postgresql --no-cov" in bike_step

    integration = REPOSITORY_ROOT / "Backend" / "tests" / "integration"
    for test_file in integration.glob("test_*.py"):
        step = bike_step if test_file.name.startswith("test_biketour_") else orm_step
        assert f"tests/integration/{test_file.name}" in step


def test_backend_workflow_installs_linux_lock_without_resolving_dependencies() -> None:
    workflow = _workflow()

    assert "python -m pip install -r pylock.linux.toml" in workflow
    assert "python -m pip install --no-deps -e ." in workflow


def test_api_contract_has_owner_and_pull_request_evidence() -> None:
    codeowners = CODEOWNERS_PATH.read_text(encoding="utf-8")
    template = PULL_REQUEST_TEMPLATE_PATH.read_text(encoding="utf-8")

    for governed_path in (
        "/Backend/app/api/",
        "/Backend/app/main.py",
        "/Backend/app/modules/**/router.py",
        "/Backend/openapi.json",
        "/Backend/scripts/*openapi*",
        "/Backend/tests/test_openapi*.py",
        "/Docs/API*.md",
        "/Docs/architecture/ADR-005-API-STANDARDS.md",
        "/Docs/architecture/ADR-016-API-GOVERNANCE.md",
        "/.github/workflows/backend-ci.yml",
    ):
        assert f"{governed_path} @VANER" in codeowners

    for evidence in (
        "compatibilidade",
        "Backend/openapi.json",
        "Testes de contrato",
        "Proprietário do contrato",
        "Exceção emergencial",
    ):
        assert evidence in template
