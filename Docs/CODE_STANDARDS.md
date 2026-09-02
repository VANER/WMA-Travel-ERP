# WMA Travel ERP — Padrões de Código

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Norma de Código
> **Versão:** 1.0
> **Data:** 01/09/2026
> **Status:** VIGENTE

## 1. Objetivo

Consolidar os padrões verificáveis de Python, arquitetura do Backend, API e qualidade. `Backend/pyproject.toml` e
`.github/workflows/backend-ci.yml` são as autoridades executáveis.

## 2. Tooling oficial

| Gate | Ferramenta | Autoridade |
| --- | --- | --- |
| Dependências | `python -m pip check` | Backend CI |
| Lint | Ruff | `Backend/pyproject.toml` |
| Formatação | Ruff Format | Backend CI |
| Tipagem | Mypy strict | `Backend/pyproject.toml` |
| Testes | Pytest | `Backend/pyproject.toml` |
| Cobertura | pytest-cov, mínimo de 100% | `Backend/pyproject.toml` |
| Migrations | Alembic | Backend CI |
| Integração | PostgreSQL 18 descartável | Backend CI |
| Contrato | OpenAPI versionado | `Backend/openapi.json` e Backend CI |

Black e Pylint não são ferramentas obrigatórias enquanto não integrarem o manifesto e o CI.

## 3. Convenções Python

- classes em `PascalCase`;
- funções, métodos, variáveis, módulos e arquivos em `snake_case`;
- constantes em `UPPER_SNAKE_CASE`;
- type hints obrigatórios em interfaces públicas;
- `Any` somente com justificativa técnica;
- comprimento de linha de 100 caracteres, conforme Ruff;
- imports organizados e validados pelo Ruff;
- código novo acompanhado de testes proporcionais ao risco.

## 4. Arquitetura do Backend

```text
API
  → Schema
  → Service
  → Repository
  → Model
  → PostgreSQL
```

- API valida transporte, autenticação, autorização e conversão de respostas;
- Schema representa contratos de entrada e saída;
- Service aplica regras e controla a unidade de trabalho;
- Repository concentra persistência e não confirma transações autonomamente;
- Model representa a persistência certificada ou migrations aditivas;
- imports internos entre domínios são proibidos, salvo contrato compartilhado ou interface explícita;
- módulos pequenos não recebem abstrações ou diretórios vazios sem necessidade comprovada.

## 5. API

- operações funcionais permanecem sob `/api/v1`;
- toda operação declara `operationId` estável, tag, respostas e schemas aplicáveis;
- RBAC e autenticação são aplicados no servidor;
- paginação usa limites validados;
- erros seguem o contrato padronizado com correlation ID;
- breaking changes exigem nova versão e o processo da ADR-016;
- `Backend/openapi.json` deve permanecer sincronizado com a aplicação.

## 6. Banco e migrations

- baseline, dumps, scripts F1-FIN e migrations aplicadas são imutáveis;
- evolução estrutural usa nova migration Alembic versionada;
- novos objetos seguem `Docs/DATABASE_STANDARDS.md`;
- valores monetários usam `NUMERIC(15,2)`;
- migration declara pré-condições, validações, impacto e rollback quando seguro;
- testes de downgrade destrutivo usam somente banco local descartável.

## 7. Comandos oficiais

Executar em `Backend/` com o ambiente de desenvolvimento ativo:

```powershell
python -m pip check
python -m ruff check .
python -m ruff format --check app tests migrations scripts
python -m mypy app tests scripts
python -m pytest -W error --cov=app --cov-report=term-missing
python scripts/export_openapi.py --check
python -m alembic heads
```

A integração PostgreSQL adiciona `--run-postgresql` e exige URL local descartável com nome terminado em `_test`.

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.0 |
| Status | VIGENTE |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

Alterações neste documento devem ser versionadas e manter a rastreabilidade pelo Git.
