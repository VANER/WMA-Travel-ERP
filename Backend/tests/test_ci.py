"""Gates de regressão da configuração de integração contínua."""

from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
WORKFLOW_PATH = REPOSITORY_ROOT / ".github" / "workflows" / "backend-ci.yml"


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
        "pytest -W error --run-postgresql --cov=app --cov-report=term-missing",
        "python scripts/export_openapi.py --check",
        'python scripts/check_openapi_compatibility.py --base-ref "$WMA_OPENAPI_BASE_REF"',
        "alembic heads",
        "alembic upgrade head",
    }

    for command in required_commands:
        assert f"run: {command}" in workflow

    assert "fetch-depth: 0" in workflow
    assert "if: github.event_name == 'pull_request'" in workflow


def test_backend_workflow_installs_linux_lock_without_resolving_dependencies() -> None:
    workflow = _workflow()

    assert "python -m pip install -r pylock.linux.toml" in workflow
    assert "python -m pip install --no-deps -e ." in workflow
