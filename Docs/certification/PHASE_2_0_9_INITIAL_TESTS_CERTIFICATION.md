# WMA Travel ERP — Certificação da ETAPA 2.0.9

## Testes Iniciais

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.9 — Testes Iniciais

**Data:** 22/08/2026

**Status:** APROVADA EM WINDOWS E POSTGRESQL REAL; CI PENDENTE

## 1. Objetivo

Certificar os testes iniciais da fundação do backend para aplicação, health checks, PostgreSQL, configuração,
API e migrations.

## 2. Escopo auditado

- criação e inicialização da aplicação FastAPI;
- health checks de processo e persistência;
- configuração por ambiente e proteção de valores sensíveis;
- contratos HTTP, erros e OpenAPI;
- engine, sessões e limites transacionais SQLAlchemy;
- convenções e árvore Alembic;
- fronteiras da arquitetura modular;
- conexão real com PostgreSQL 18 local descartável.

## 3. Estratégia certificada

A suíte rápida permanece determinística e não depende de serviços externos. O teste PostgreSQL real exige opt-in
com `--run-postgresql` e `WMA_TEST_DATABASE_URL`, aceita somente hosts locais e exige banco terminado em `_test`.
O teste de integração executa apenas `SELECT 1` e `SELECT current_database()`, sem alterar schema ou dados.

## 4. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check ...................... OK
mypy app tests ........................... OK
pytest -W error --cov=app ................. OK (42 testes; 1 skip; 100%)
pytest --run-postgresql ................... OK (1 teste PostgreSQL real)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

A integração foi executada contra a imagem oficial `postgres:18`, em contêiner temporário sem volume, banco
`wma_phase2_test` e porta local exclusiva. O contêiner foi removido após a validação.

## 5. Gate

```text
Aplicação FastAPI ........................ OK
Health de processo ....................... OK
PostgreSQL com mocks ..................... OK
PostgreSQL real descartável .............. OK
Configuração e secrets ................... OK
API, erros e OpenAPI ..................... OK
SQLAlchemy e transações .................. OK
Alembic e migrations ..................... OK
Arquitetura modular ...................... OK
Cobertura automatizada ................... OK (100%)
Validação Windows ........................ OK
Validação Linux/CI ....................... PENDENTE
```

## 6. Resultado

**ETAPA 2.0.9 — TESTES INICIAIS: APROVADA LOCALMENTE; CERTIFICAÇÃO DEFINITIVA PENDENTE**

Todos os contratos da etapa foram aprovados no ambiente Windows e a integração PostgreSQL real foi confirmada.
O gate definitivo depende apenas do workflow Linux/CI do futuro pull request.
