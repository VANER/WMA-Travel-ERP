# Backend — WMA Travel ERP

Bootstrap da etapa 2.0.2 com Python 3.13+, FastAPI, SQLAlchemy 2, Alembic e pytest.

## Preparação no Windows

```powershell
cd Backend
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r pylock.windows.toml
python -m pip install --no-deps -e .
Copy-Item .env.example .env
```

O lockfile Linux é usado pelo CI e o lockfile Windows é usado no desenvolvimento local. Ambos foram gerados
com `pip 26.2.1` a partir do grupo `dev` definido no `pyproject.toml`.

Edite o `WMA_DATABASE_URL` local sem versionar credenciais. A aplicação não cria tabelas por
`Base.metadata.create_all()`; toda evolução estrutural deve usar uma nova revision Alembic.

## Configuração

As configurações usam o prefixo `WMA_` e são validadas na inicialização:

| Variável | Valores | Regra |
| --- | --- | --- |
| `WMA_DATABASE_URL` | URL `postgresql+psycopg://` | Obrigatória e nunca exibida no `repr` ou em erros de validação. |
| `WMA_ENVIRONMENT` | `development`, `test`, `production` | Padrão: `development`. |
| `WMA_LOG_LEVEL` | `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` | `DEBUG` é proibido em produção. |
| `WMA_DATABASE_POOL_SIZE` | 1 a 50 | Conexões persistentes por processo. Padrão: 5. |
| `WMA_DATABASE_MAX_OVERFLOW` | 0 a 100 | Conexões temporárias adicionais. Padrão: 10. |
| `WMA_DATABASE_POOL_TIMEOUT` | 1 a 120 segundos | Espera por uma conexão. Padrão: 30. |
| `WMA_DATABASE_POOL_RECYCLE` | 60 a 86400 segundos | Renovação preventiva. Padrão: 1800. |
| `WMA_DATABASE_CONNECT_TIMEOUT` | 1 a 30 segundos | Limite por tentativa de conexão. Padrão: 5. |

O `.env` é destinado somente ao ambiente local e permanece ignorado pelo Git. Produção deve injetar variáveis
por um mecanismo seguro de secrets compatível com a infraestrutura escolhida.

Os logs técnicos são emitidos em JSON para `stderr`, com timestamp UTC, nível, logger, mensagem e correlation ID
quando disponível. Requisições incluem método, caminho, status e duração, sem query string ou payload.
O access log padrão do servidor é desativado para evitar duplicidade e exposição acidental de parâmetros.

## Execução

```powershell
uvicorn app.main:app --reload
```

A API expõe `GET /health`, `GET /api/v1/health`, `GET /api/v1/health/database`, `/docs`, `/redoc` e
`/openapi.json`.

O router principal usa o prefixo `/api` e agrega routers versionados, começando por `/v1`. Rotas inexistentes,
métodos não permitidos, validações, indisponibilidade do banco e falhas internas retornam o contrato de erro
padronizado com correlation ID.

O contrato OpenAPI 3.1 está disponível em `/openapi.json`, com interfaces Swagger UI em `/docs` e ReDoc em
`/redoc`. Metadata, tags, schemas de sucesso e erro e respostas HTTP comuns são definidos explicitamente.

## Estrutura modular

O código funcional é organizado por domínio em `app/modules/`: `comercial`, `financeiro`, `turismo`, `biketour`,
`fiscal` e `corporativo`. Adaptadores externos pertencem a `app/integrations/`; somente recursos comprovadamente
transversais pertencem a `app/shared/`.

Os models do Core Corporativo refletem a baseline em `app/modules/corporativo/models.py` e são registrados para o
Alembic por `app/db/models.py`. Consulte `Docs/CORE_MODELS.md` antes de ampliar esse mapeamento.

Os repositories corporativos ficam em `app/modules/corporativo/repositories.py`, recebem uma sessão explícita e
nunca confirmam a transação autonomamente. Consulte `Docs/CORE_REPOSITORIES.md` para o contrato da etapa 2.1.3.

Os services cadastrais ficam em `app/modules/corporativo/services.py` e controlam commit e rollback de cada caso
de uso atômico. Consulte `Docs/CORE_SERVICES.md` antes de adicionar regras ou orquestrações.

Um teste arquitetural impede imports diretos entre implementações internas dos domínios. A comunicação deverá
usar interfaces, serviços ou contratos internos explícitos quando os casos de uso forem implementados.

## Validação

```powershell
ruff check .
mypy app tests
pytest --cov=app --cov-report=term-missing
alembic heads
```

As conexões online do Alembic respeitam `WMA_DATABASE_CONNECT_TIMEOUT`, evitando espera indefinida em falhas de
rede ou resolução de host.

Os testes rápidos não acessam um banco real. A integração PostgreSQL é opt-in e aceita somente uma URL local cujo
nome do banco termine em `_test`:

```powershell
$env:WMA_TEST_DATABASE_URL = "postgresql+psycopg://usuario:senha@localhost:5432/wma_phase2_test"
python -m pytest -W error --run-postgresql tests/integration/test_postgresql.py
```

O teste executa apenas consultas de leitura e não cria, remove ou altera objetos. O banco descartável deve ser
preparado previamente pelo operador.

No GitHub Actions, a suíte completa usa um serviço efêmero `postgres:18`, sem volume persistente. O workflow
executa verificação de dependências, lint, formato, tipagem, testes rápidos e de integração, cobertura mínima e
validação e aplicação da árvore Alembic no banco descartável.

Para atualizar os locks após uma mudança intencional de dependências:

```powershell
python -m pip install --upgrade pip==26.2.1
python -m pip lock --only-deps ".[dev]" --output pylock.windows.toml
docker run --rm --mount "type=bind,source=${PWD},target=/workspace" `
  -w /workspace python:3.13-slim `
  sh -c "python -m pip install --upgrade pip==26.2.1 && `
  python -m pip lock --only-deps '.[dev]' --output pylock.linux.toml"
```

Os endpoints `/health` e `/api/v1/health` confirmam somente o processo da API. O endpoint
`/api/v1/health/database` executa `SELECT 1` e retorna `503 DATABASE_UNAVAILABLE` sem detalhes internos quando o
PostgreSQL não responde.

Services orquestradores devem usar `transactional_session()` para confirmar a unidade de trabalho somente após
sucesso integral. Falhas provocam rollback; repositories não devem realizar commits autônomos.

## Migrations

Antes de executar qualquer migration, confirme que `WMA_DATABASE_URL` aponta para o ambiente correto.

```powershell
alembic revision --rev-id YYYYMMDDHHMM_descricao_curta -m "descrição objetiva"
alembic upgrade head
alembic current
```

A pasta `migrations/versions/` começa sem revisions porque o dump certificado da Fase 1 já contém a baseline.
Não execute `stamp head` para ocultar migrations pendentes. O downgrade deve ser testado somente em banco local
descartável. Consulte `Docs/MIGRATIONS.md` antes de criar ou aplicar uma revision.
