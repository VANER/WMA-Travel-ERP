# WMA Travel ERP — Certificação da ETAPA 2.0.5

## PostgreSQL e SQLAlchemy

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.5 — PostgreSQL e SQLAlchemy

**Data:** 20/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a conexão do backend com PostgreSQL, o ciclo de vida das sessões, os limites transacionais, o pool
explícito e o tratamento seguro de indisponibilidade, sem recriar ou alterar a baseline da Fase 1.

## 2. Escopo auditado

- `Backend/app/core/config.py`: URL oficial `postgresql+psycopg://` e parâmetros validados;
- `Backend/app/db/session.py`: engine, pool, pre-ping, session factory e transações;
- `Backend/app/api/v1/router.py`: `GET /api/v1/health/database`;
- `Backend/app/core/errors.py`: resposta `503 DATABASE_UNAVAILABLE` sem detalhes internos;
- testes unitários e HTTP da configuração, sessão, transação e health check;
- ausência de `create_all()` na implementação;
- preservação dos artefatos certificados da Fase 1.

## 3. Evidências de validação

As verificações foram executadas em Windows, na branch `feature/2.0.5-postgresql-sqlalchemy`, com Python 3.13.15,
PostgreSQL 18 local em execução e ambiente virtual do backend:

```text
pip check ................................ OK
ruff check . ............................. OK
mypy app tests ........................... OK (29 arquivos)
pytest -W error --cov=app ................. OK (30 testes; 100%)
alembic heads ............................ OK
health check PostgreSQL real ............. OK (SELECT 1; True)
```

O health check real conectou ao PostgreSQL local e executou `SELECT 1`. A suíte também cobre o cenário de falha,
confirmando o retorno HTTP 503 padronizado.

O workflow Linux do PR #7 foi aprovado na execução `32427637178`, confirmando dependências, lint, tipagem e testes
da etapa em Python 3.13.

## 4. Segurança e governança

- a URL de banco é obrigatória e injetada por ambiente;
- valores de conexão não são expostos em erros de validação nem no `repr` de `Settings`;
- `DEBUG` permanece bloqueado em produção;
- o pool usa `pool_pre_ping`, limites explícitos e `connect_timeout`;
- falhas transacionais realizam rollback e sucesso realiza commit;
- o health check não altera dados nem schema;
- não há `create_all()` na implementação;
- nenhuma migration ou baseline histórica foi alterada;
- nenhum segredo, `.env` ou log sensível foi versionado.

## 5. Gate

```text
Driver psycopg 3 oficial ................ OK
URL PostgreSQL validada ................. OK
Engine SQLAlchemy 2 ..................... OK
Pool explícito e pre-ping ................ OK
Session factory .......................... OK
Commit e rollback transacionais .......... OK
Health check real ........................ OK
Tratamento seguro de indisponibilidade ... OK
Testes automatizados ..................... OK (100%)
Lint e tipagem ........................... OK
Alembic sem alteração da baseline ........ OK
Validação Windows ....................... OK
Validação Linux/CI ....................... OK
```

## 6. Resultado

**ETAPA 2.0.5 — POSTGRESQL E SQLALCHEMY: APROVADA E CERTIFICADA**

A etapa está tecnicamente validada em Windows e Linux/CI e autorizada a avançar para a etapa 2.0.6.
