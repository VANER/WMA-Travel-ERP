# Certificação complementar — Hardening de Turismo 2.6

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.6 — Hardening
> **Data:** 08/09/2026
> **Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

## 1. Objetivo e escopo

Complemento à certificação original da 2.6, que permanece imutável. Abrange HTTP `404/409`, idempotência de
confirmação/cancelamento, concorrência, rollback integral, correlação Comercial, RBAC, constraints, expiração
e OpenAPI. Não inicia a 2.7 nem acrescenta scheduler.

Documento derivado do modelo de certificação, com seções de evidências e qualidade consolidadas para este
ajuste. A referência desatualizada à 2.5 no `AGENTS.md` foi identificada; prevalece o escopo de hardening
expressamente solicitado, consistente com a certificação integrada da 2.6.

## 2. Critérios e evidências locais

| Critério | Evidência | Resultado |
| --- | --- | --- |
| Recursos inexistentes e conflitos distintos | testes HTTP de Turismo | APROVADO |
| Idempotência persistida, com ator/recurso/operação | replay, concorrência e isolamento de ator | APROVADO |
| Ausência de overselling | duas conexões e espera comprovada por `pg_blocking_pids` | APROVADO |
| Rollback completo | falhas após Reserva e antes de alocação/correlação/snapshot | APROVADO |
| Correlação Comercial e unicidade | inexistência, incompatibilidade, ausência e duplicidade | APROVADO |
| RBAC por endpoint | sem acesso, visualizar, operar e administrador | APROVADO |
| Constraints e ciclo de expiração | PostgreSQL real | APROVADO |
| Dependências, Ruff, formato, mypy e cobertura | 408 testes; cobertura 100%; Ruff; format; mypy; pip check | APROVADO |
| OpenAPI sincronizado e compatível | exportador e comparação com `HEAD` | APROVADO |
| Auditoria material de snapshots e expiração | PostgreSQL real, triggers e rollback integral | APROVADO |
| Markdown e diff | markdownlint e git diff --check | APROVADO |

## 3. Banco e migration

A revisão aditiva `202609080100` sucede `202609050100`, sem modificar revisões históricas.
O SQL versionado fica em `Database/migrations/202609080100_turismo_hardening.sql`; Alembic controla a transação.
Dados anteriores incompatíveis interrompem a aplicação. O downgrade perde somente os snapshots novos e
remove constraints, índice e triggers desta revisão; exige aplicação parada.

| Ambiente PostgreSQL local descartável | Uso | Resultado |
| --- | --- | --- |
| `wma_turismo_hardening_20260908_test` | integração e concorrência | APROVADO |
| `wma_turismo_hardening_migration_20260908_test` | dump oficial + F1-FIN.04–11 + Alembic | upgrade aprovado |
| Mesmo banco de migration | downgrade 202609080100 → 202609050100 → 202609080100 | APROVADO |

O dump foi restaurado com `psql -X -v ON_ERROR_STOP=1`. A evolução financeira seguiu a sequência de
`Database/install.sh`, por comandos equivalentes no PowerShell. Não houve alteração dos scripts históricos.

## 4. Operação, riscos e evidências remotas

A expiração lógica é imediata; consultas não gravam. A rotina interna `expirar_bloqueios` materializa
`BLOQUEADA → EXPIRADA` sob lock, mantém o prazo e a reserva pendente, com auditoria pelos triggers existentes.
A execução cabe à manutenção operacional; scheduler e expurgo automático de snapshots ficam fora do escopo.
Detalhes operacionais estão em `Docs/TOURISM_MODULE.md`.

PR, CI Linux, revisão e integração em `main`: **PENDENTES**. Nenhuma aprovação remota é inferida de testes locais.
A execução da 2.7 permanece condicionada ao hardening verde e integrado, conforme solicitado.

## 5. Resultado e rastreabilidade

**Hardening aprovado em todos os gates locais e em certificação.**

A conclusão permanece condicionada ao PR, CI remoto e integração em `main`.
A certificação original e a tag `phase-1-certified` foram preservadas.

**WMA Travel ERP — Documento complementar de certificação.**
