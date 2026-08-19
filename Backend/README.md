# Backend — WMA Travel ERP

Bootstrap da etapa 2.0.2 com Python 3.13+, FastAPI, SQLAlchemy 2, Alembic e pytest.

## Preparação no Windows

```powershell
cd Backend
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
Copy-Item .env.example .env
```

Edite o `WMA_DATABASE_URL` local sem versionar credenciais. A aplicação não cria tabelas por
`Base.metadata.create_all()`; toda evolução estrutural deve usar uma nova revision Alembic.

## Execução

```powershell
uvicorn app.main:app --reload
```

A API expõe `GET /health`, `GET /api/v1/health`, `/docs`, `/redoc` e `/openapi.json`.

## Validação

```powershell
ruff check .
mypy app
pytest --cov=app --cov-report=term-missing
alembic heads
```

O health check inicial confirma somente o processo da API e não abre conexão com o banco. Testes de integração
com PostgreSQL serão adicionados junto ao primeiro mapeamento de domínio, sempre em banco descartável.

## Migrations

Antes de executar qualquer migration, confirme que `WMA_DATABASE_URL` aponta para o ambiente correto.

```powershell
alembic revision -m "descrição objetiva"
alembic upgrade head
```

A pasta `migrations/versions/` começa sem revisions porque o dump certificado da Fase 1 já contém a baseline.
