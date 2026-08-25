# WMA Travel ERP — Certificação da ETAPA 2.1.7

## Testes do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.7 — Testes do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a cobertura automatizada das regras, persistência e API do Core Corporativo, incluindo a cadeia completa
em PostgreSQL real descartável.

## 2. Escopo auditado

- fidelidade dos nove models à baseline;
- contratos e paginação dos repositories;
- commit, rollback e propagação de falhas dos services;
- limites, defaults e conversão ORM dos schemas;
- 27 operações HTTP e respostas padronizadas;
- persistência integrada das nove autoridades no PostgreSQL;
- defaults do servidor, dependências, leitura, paginação e conflito real;
- proteção por host local e sufixo `_test`.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (48 arquivos)
mypy app tests ........................... OK (47 arquivos)
pytest -W error .......................... OK (154 testes; 3 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

A execução PostgreSQL local não foi declarada como aprovada: o usuário configurado não possui permissão para
criar o banco descartável exclusivo. O fluxo real foi validado no ambiente efêmero do CI.

## 4. Evidência Linux/PostgreSQL

O workflow do PR #29 foi aprovado na execução `32864902097`, em Ubuntu, Python 3.13 e PostgreSQL 18. A suíte
executou 157 testes, incluindo os três cenários PostgreSQL opt-in, com cobertura de 100%, lint, formatação,
tipagem, validação e aplicação da árvore Alembic.

## 5. Resultado

**ETAPA 2.1.7 — TESTES DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #29. A próxima etapa autorizada após sua integração é a 2.1.8 — Certificação do
Core Corporativo.
