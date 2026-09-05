# Módulo Turismo

> **Etapa:** 2.6 — Turismo
> **Data:** 05/09/2026
> **Status:** CERTIFICADA

## Escopo implementado

O módulo integra as estruturas legadas de Turismo e adiciona saída operacional, controle transacional de vagas e
correlação Comercial. A API sob `/api/v1/turismo` permite listar e criar saídas, consultar disponibilidade e criar,
confirmar ou cancelar reservas com RBAC.

## Arquitetura

```text
Router -> Schema -> Service -> Repository -> Model -> PostgreSQL
```

Turismo não grava fatos de Core, Comercial ou Financeiro. A migration aditiva `202609050100` preserva a baseline e
mantém um único head Alembic.

## Validação

Os gates obrigatórios são Ruff, Ruff Format, mypy strict, pytest com warnings como erro e cobertura de 100%,
OpenAPI sincronizado e integração PostgreSQL opt-in.
