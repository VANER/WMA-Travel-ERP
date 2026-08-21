# WMA Travel ERP — Certificação da ETAPA 2.0.7

## API Base

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.7 — API Base

**Data:** 21/08/2026

**Status:** APROVADA EM WINDOWS — LINUX/CI PENDENTE

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
Validação Linux/CI ........................ PENDENTE
```

## 6. Resultado

**ETAPA 2.0.7 — API BASE: APROVADA EM WINDOWS**

A API base está operacional e pronta para a validação de metadata e schemas OpenAPI da etapa 2.0.8. A
certificação final depende do CI Linux do pull request da etapa 2.0.7.
