# WMA Travel ERP — Certificação da ETAPA 2.0.8

## OpenAPI

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.8 — OpenAPI

**Data:** 21/08/2026

**Status:** APROVADA EM VALIDAÇÃO LOCAL; CI PENDENTE

## 1. Objetivo

Validar a documentação OpenAPI 3.1 da aplicação FastAPI, seus endpoints de documentação, metadata,
versionamento, schemas e contratos de resposta.

## 2. Escopo auditado

- configuração OpenAPI da app factory em `Backend/app/main.py`;
- schemas públicos em `Backend/app/core/schemas.py`;
- Swagger UI em `/docs`;
- ReDoc em `/redoc`;
- especificação OpenAPI 3.1 em `/openapi.json`;
- rotas sem versão e versionadas sob `/api/v1`;
- testes de contrato em `Backend/tests/test_openapi.py`.

## 3. Contratos validados

```text
GET /docs ........................... 200 HTML
GET /redoc .......................... 200 HTML
GET /openapi.json ................... 200 OpenAPI 3.1
GET /health ......................... HealthResponse
GET /api/v1/health .................. HealthResponse
GET /api/v1/health/database ......... DatabaseHealthResponse
Erros 404, 405, 422 e 500 ........... ErrorResponse
```

A especificação apresenta título, resumo, descrição, versão da aplicação, tags e identificadores de operação
únicos. Os contratos não publicam credenciais nem valores de configuração sensíveis.

## 4. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check (arquivos da etapa) . OK
pytest -W error --cov=app ................. OK (42 testes; 100%)
alembic heads ............................ OK
auditoria de termos sensíveis ............ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
mypy app tests ........................... OK (32 arquivos)
```

O primeiro passe completo do Mypy recompilou 538 módulos de dependências no Windows. Após a correção da tipagem
das respostas OpenAPI, a análise dos 32 arquivos de código e testes foi aprovada. A execução Linux/CI deve ser
confirmada pelo workflow antes da certificação definitiva.

## 5. Gate

```text
Swagger UI /docs .......................... OK
ReDoc /redoc .............................. OK
OpenAPI JSON /openapi.json ................ OK
OpenAPI 3.1 ............................... OK
Metadata e tags ........................... OK
Versionamento /api/v1 ..................... OK
Schemas de sucesso e erro ................. OK
Operation IDs únicos ...................... OK
Ausência de segredos na especificação ..... OK
Cobertura automatizada .................... OK (100%)
Validação Windows completa ................ OK
Validação Linux/CI ........................ PENDENTE
```

## 6. Resultado

**ETAPA 2.0.8 — OPENAPI: APROVADA EM VALIDAÇÃO LOCAL; CERTIFICAÇÃO DEFINITIVA PENDENTE**

A implementação atende ao escopo funcional da etapa. O gate definitivo somente poderá ser encerrado após as
validações obrigatórias restantes e o workflow Linux/CI do futuro pull request.
