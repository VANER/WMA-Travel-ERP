# WMA Travel ERP — Certificação da ETAPA 2.1.6

## API do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.6 — API do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a exposição HTTP versionada dos casos de uso cadastrais das nove autoridades corporativas, preservando
os contratos, limites transacionais e a baseline aprovados nas etapas anteriores.

## 2. Escopo auditado

- 27 operações de listagem, consulta e cadastro sob `/api/v1`;
- paginação limitada e identificadores inteiros positivos;
- schemas Pydantic específicos para entrada e saída;
- respostas padronizadas para validação, ausência e conflito;
- proteção contra vazamento de detalhes de integridade do banco;
- publicação integral dos contratos no OpenAPI;
- ausência de alteração na baseline ou de migration desnecessária.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (48 arquivos)
mypy app tests ........................... OK (47 arquivos)
pytest -W error .......................... OK (154 testes; 2 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

## 4. Gate da API

```text
Nove recursos publicados ................ OK
Listagem paginada ........................ OK
Consulta por identificador ............... OK
Cadastro com HTTP 201 .................... OK
Validação antes da persistência .......... OK
Ausência padronizada ..................... OK
Conflito de integridade seguro ........... OK
OpenAPI versionado ....................... OK
```

## 5. Evidência Linux

O workflow do PR #28 foi aprovado na execução `32863062195`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados todos os gates, incluindo os testes de integração PostgreSQL, cobertura de 100%, lint, formatação,
tipagem e validação da árvore Alembic.

## 6. Resultado

**ETAPA 2.1.6 — API DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #28. A próxima etapa autorizada após sua integração é a 2.1.7 — Testes.
