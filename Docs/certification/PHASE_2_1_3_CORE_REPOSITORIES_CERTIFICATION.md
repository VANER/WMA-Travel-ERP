# WMA Travel ERP — Certificação da ETAPA 2.1.3

## Repositories do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.3 — Repositories do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a camada de persistência dos nove models corporativos, mantendo o controle transacional nos services e
sem antecipar regras de negócio, schemas HTTP ou endpoints.

## 2. Escopo auditado

- base genérica e tipada de repository;
- repositories concretos para as nove autoridades corporativas;
- consulta por chave primária;
- listagem ordenada e paginada;
- inclusão com `flush` e sem `commit` autônomo;
- propagação de falhas sem rollback interno;
- limites arquiteturais das etapas seguintes;
- documentação operacional e rastreabilidade da etapa.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (42 arquivos)
mypy app tests ........................... OK (41 arquivos)
pytest -W error .......................... OK (72 testes; 2 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

## 4. Evidência PostgreSQL

O dump oficial foi restaurado em PostgreSQL 18 local e descartável. Os nove repositories executaram consultas
reais; uma inclusão de localidade foi sincronizada por `flush` e revertida por rollback, sem resíduos. A comparação
por `alembic check` retornou `No new upgrade operations detected.`. O container foi removido após a auditoria.

## 5. Gate transacional

```text
Session recebida por injeção ............. OK
Commit autônomo ausente .................. OK
Rollback interno ausente ................. OK
Flush dentro da transação corrente ....... OK
Falhas propagadas ao proprietário ........ OK
Paginação limitada ....................... OK
Ordenação determinística ................. OK
Exclusão não antecipada .................. OK
```

## 6. Evidência Linux

O workflow do PR #25 foi aprovado na execução `32856671871`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados os 74 testes, incluindo integração PostgreSQL, com cobertura de 100%, lint, formatação, tipagem,
verificação e aplicação da árvore Alembic.

## 7. Resultado

**ETAPA 2.1.3 — REPOSITORIES DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #25. A próxima etapa autorizada após sua integração é a 2.1.4 — Services.
