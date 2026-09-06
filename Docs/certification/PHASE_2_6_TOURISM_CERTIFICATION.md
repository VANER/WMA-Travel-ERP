# Certificação da Etapa 2.6 — Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6 — Turismo
> **Data:** 05/09/2026
> **Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

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

A Etapa 2.6 está concluída, certificada e integrada à `main` pelo PR #57. O commit funcional `935d2c1` foi
integrado pelo merge commit `679ecdc99f8b28ae97e767c156731c9c176c6cb1`.

Os checks do PR e os workflows pós-merge foram aprovados:

| Evidência remota | Resultado |
| --- | --- |
| PR #57 | integrado |
| Documentation CI do PR | aprovado |
| Backend CI do PR | aprovado |
| Documentation CI pós-merge | execução `33989883222`, aprovada |
| Backend CI pós-merge | execução `33989883235`, aprovada |

A próxima etapa oficial é a 2.7 — Bike Tour.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6 — Turismo |
| Migration | `202609050100` |
| Status | CONCLUÍDA, CERTIFICADA E INTEGRADA |
| Última atualização | 05/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
