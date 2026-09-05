# Certificação da Etapa 2.6 — Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6 — Turismo
> **Data:** 05/09/2026
> **Status:** CERTIFICADA

## 1. Escopo certificado

- gate documental `TUR-DOC-01` a `TUR-DOC-08`;
- ADR-019 e migration aditiva `202609050100`;
- models, schemas, repositories, services e rotas de Turismo;
- saída operacional, disponibilidade, alocação de vagas e reserva;
- idempotência, concorrência, confirmação, cancelamento e correlação comercial;
- RBAC, auditoria, OpenAPI e regressão do Backend.

## 2. Ambiente PostgreSQL

| Evidência | Resultado |
| --- | --- |
| PostgreSQL | 18.4 local |
| Banco restaurado | `wma_turismo_26_20260905_test` |
| Restauração | `Database/install.sh --with-validation` aprovada |
| F1-FIN.12 | `F1_FIN_12_APROVADA` |
| F1-FIN.13 | `F1_FIN_13_CERTIFICADA` |
| Upgrade inicial | `202609050100` |
| Downgrade | `202609030100`, sem resíduos da 2.6 |
| Novo upgrade | `202609050100` |
| Constraints não validadas | 0 |

O teste opt-in usou separadamente `wma_turismo_ci_20260905_test`, pois sua fixture cria e remove o metadata para
cada cenário. O banco restaurado permaneceu intacto no head final.

## 3. Qualidade

| Gate | Resultado |
| --- | --- |
| `python -m pip check` | aprovado |
| `ruff check .` | aprovado |
| `ruff format --check app tests migrations scripts` | aprovado |
| `mypy app tests scripts` | 99 arquivos, sem erros |
| `pytest -W error --run-postgresql` | 322 aprovados |
| Integração PostgreSQL | 7 de 7 aprovados |
| Cobertura | 100%, 2.791 instruções |
| OpenAPI | sincronizado |
| Alembic | head único `202609050100` |
| Markdownlint e CSpell de Turismo | sem erros |
| `git diff --check` | aprovado |

## 4. Proteção histórica

Nenhum dump, script, migration ou artefato certificado da Fase 1 foi alterado. A restauração foi executada em
banco local descartável e as evoluções da Fase 2 foram aplicadas somente pelo Alembic.

## 5. Resultado

A Etapa 2.6 está implementada e certificada. A integração remota depende de commit, push, pull request e CI; a
Etapa 2.7 — Bike Tour permanece bloqueada até essa integração.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6 — Turismo |
| Migration | `202609050100` |
| Status | CERTIFICADA |
| Última atualização | 05/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
