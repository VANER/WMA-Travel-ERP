# WMA Travel ERP — Certificação da ETAPA 2.0.6

## Alembic e Migrations

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.6 — Alembic e Migrations

**Data:** 20/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a infraestrutura de migrations posteriores à baseline da Fase 1, incluindo configuração Alembic,
nomenclatura, versionamento linear, transações, upgrade, downgrade, proteção da baseline, testes e documentação.

## 2. Escopo auditado

- `Backend/alembic.ini` e `Backend/migrations/env.py`;
- metadata e convenções em `Backend/app/db/base.py`;
- template e diretório `Backend/migrations/versions/`;
- testes automatizados em `Backend/tests/test_migrations.py`;
- processo operacional em `Docs/MIGRATIONS.md`;
- preservação do dump e das evidências certificadas da Fase 1.

## 3. Decisão sobre a baseline

O dump oficial já contém a baseline integral. Recriá-la como revision Alembic produziria uma identidade histórica
falsa e risco de reaplicação. A árvore começa sem revisions e receberá somente deltas estruturais novos da Fase 2.

O autogenerate ignora tabelas refletidas que ainda não estejam sob gestão de `Base.metadata`, evitando propostas
de remoção dos objetos históricos. Nenhuma saída autogerada pode ser aplicada sem revisão manual.

## 4. Evidências

```text
pip check ................................ OK
ruff check . ............................. OK
pytest -W error --cov=app ................. OK (34 testes; 100%)
alembic heads ............................ OK (árvore vazia, sem heads)
alembic history --verbose ................ OK (sem revisions artificiais)
alembic current .......................... OK (PostgreSQL acessível)
alembic check ............................ OK (nenhuma operação inesperada)
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

O workflow Linux do PR #9 foi aprovado na execução `32430685826`, confirmando dependências, lint, tipagem,
testes e a árvore Alembic em Python 3.13.

Upgrade e downgrade de uma revision estão classificados como **NÃO APLICÁVEIS** neste gate porque não existe
delta estrutural aprovado. Criar uma migration vazia apenas para executar esses comandos violaria a proteção da
baseline. O primeiro delta futuro deverá comprovar upgrade, downgrade quando seguro e retorno ao head.

## 5. Gate

```text
Alembic configurado ...................... OK
Diretório e template ..................... OK
Nomenclatura documentada ................. OK
Versionamento linear ..................... OK
Comparação de schemas e defaults ......... OK
DDL transacional por migration ........... OK
Proteção do autogenerate ................. OK
Baseline preservada ...................... OK
Upgrade de revision ...................... N/A (nenhum delta aprovado)
Downgrade de revision .................... N/A (nenhum delta aprovado)
Testes e cobertura ....................... OK (100%)
Validação Windows ........................ OK
Validação Linux/CI ....................... OK
```

## 6. Resultado

**ETAPA 2.0.6 — ALEMBIC E MIGRATIONS: APROVADA E CERTIFICADA**

A infraestrutura está validada em Windows e Linux/CI e pronta para receber a primeira evolução estrutural real da
Fase 2.
