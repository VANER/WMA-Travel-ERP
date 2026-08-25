# WMA Travel ERP — Certificação consolidada da ETAPA 2.1

## Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.8 — Certificação consolidada do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Encerrar formalmente a etapa 2.1 mediante auditoria conjunta do inventário, models, repositories, services,
schemas, API e testes das nove autoridades do Core Corporativo.

## 2. Matriz de rastreabilidade

| Etapa | Entrega | Evidência | Integração |
| --- | --- | --- | --- |
| 2.1.1 | Inventário | `PHASE_2_1_1_CORE_INVENTORY_CERTIFICATION.md` | PR #21, `819f651` |
| 2.1.2 | Models | `PHASE_2_1_2_CORE_MODELS_CERTIFICATION.md` | PR #23, `ae4b313` |
| 2.1.3 | Repositories | `PHASE_2_1_3_CORE_REPOSITORIES_CERTIFICATION.md` | PR #25, `e314d62` |
| 2.1.4 | Services | `PHASE_2_1_4_CORE_SERVICES_CERTIFICATION.md` | PR #26, `a73fc76` |
| 2.1.5 | Schemas | `PHASE_2_1_5_CORE_SCHEMAS_CERTIFICATION.md` | PR #27, `515ce30` |
| 2.1.6 | API | `PHASE_2_1_6_CORE_API_CERTIFICATION.md` | PR #28, `0e55305` |
| 2.1.7 | Testes | `PHASE_2_1_7_CORE_TESTS_CERTIFICATION.md` | PR #29, `3e18cdb` |

## 3. Gate funcional e arquitetural

```text
Nove autoridades inventariadas .......... OK
Models fiéis à baseline ................. OK
Repositories tipados e paginados ........ OK
Limites transacionais explícitos ........ OK
Schemas de entrada e saída .............. OK
API v1 com 27 operações ................. OK
Erros HTTP padronizados ................. OK
OpenAPI publicado ....................... OK
Fluxo PostgreSQL ponta a ponta ........... OK
Cobertura mínima de 95% ................. OK (100%)
```

## 4. Evidências locais consolidadas

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (48 arquivos)
mypy app tests ........................... OK (47 arquivos)
pytest -W error .......................... OK (154 testes; 3 opcionais ignorados)
cobertura ................................ OK (100%)
alembic heads ............................ OK
```

## 5. Evidência Linux/PostgreSQL

A execução pós-merge `32865356662`, associada ao commit `3e18cdb` da `main`, foi aprovada em Ubuntu, Python 3.13
e PostgreSQL 18. O pipeline confirmou dependências, lint, formatação, tipagem, 157 testes com integração real,
cobertura de 100%, árvore Alembic e aplicação das migrations no banco descartável.

## 6. Governança e baseline

- a tag `phase-1-final-2026-08-18` permanece em `10ae1e4`;
- `Database/scripts/WmaTravelERP.sql` e `Database/baseline/` não foram alterados pela etapa 2.1;
- nenhuma migration estrutural foi necessária para refletir as nove autoridades já existentes;
- credenciais e bancos locais não foram versionados;
- a integração destrutiva aceita apenas host local e banco com sufixo `_test`.

Foram identificadas três alterações antigas exclusivamente de formatação em certificações da Fase 1, realizadas
no commit rastreável `f26c5bc`. Elas não pertencem à etapa 2.1, não alteram a baseline técnica e não foram
reescritas nesta certificação.

## 7. Resultado

**ETAPA 2.1 — CORE CORPORATIVO: APROVADA, CERTIFICADA E ENCERRADA**

Não existem pendências funcionais, técnicas ou documentais conhecidas dentro do escopo aprovado da etapa 2.1.
A próxima etapa oficial é a 2.2 — Segurança e Controle de Acesso, iniciando pelo modelo de identidade.
