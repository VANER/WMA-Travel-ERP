# WMA Travel ERP — Certificação da ETAPA 2.0.7

## API Base

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.7 — API Base

**Data:** 21/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a aplicação FastAPI, o router principal, o versionamento inicial, os contratos de resposta e o
tratamento básico de exceções da API.

## 2. Escopo auditado

- app factory em `Backend/app/main.py`;
- router principal em `Backend/app/api/router.py`;
- router versionado em `Backend/app/api/v1/router.py`;
- contratos em `Backend/app/core/schemas.py`;
- handlers globais em `Backend/app/core/errors.py`;
- testes HTTP e de criação da aplicação em `Backend/tests/test_health.py`.

## 3. Contratos certificados

```text
GET /health ......................... 200 HealthResponse
GET /api/v1/health .................. 200 HealthResponse
GET /api/v1/health/database ......... 200 ou 503 padronizado
Rota inexistente .................... 404 NOT_FOUND
Método não permitido ................ 405 METHOD_NOT_ALLOWED
Entrada inválida .................... 422 VALIDATION_ERROR
Falha inesperada .................... 500 INTERNAL_ERROR
```

Todas as respostas de erro incluem `correlation_id` e não expõem detalhes internos. O router principal usa o
prefixo `/api` e agrega a versão inicial em `/v1`.

## 4. Evidências

```text
pip check ................................ OK
ruff check . ............................. OK
pytest -W error --cov=app ................. OK (38 testes; 100%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

O workflow Linux do PR #10 foi aprovado na execução `32535360753`, confirmando dependências, lint, tipagem,
testes e árvore Alembic em Python 3.13.

## 5. Gate

```text
Aplicação FastAPI ......................... OK
App factory ............................... OK
Router principal ......................... OK
Versionamento /api/v1 ..................... OK
Contratos de resposta ..................... OK
Tratamento 404 e 405 ...................... OK
Validação, 500 e indisponibilidade DB ..... OK
Correlation ID ............................ OK
Testes automatizados ...................... OK (100%)
Validação Windows ......................... OK
Validação Linux/CI ........................ OK
```

## 6. Resultado

**ETAPA 2.0.7 — API BASE: APROVADA E CERTIFICADA**

A API base está validada em Windows e Linux/CI e pronta para a validação de metadata e schemas OpenAPI da etapa
2.0.8.
