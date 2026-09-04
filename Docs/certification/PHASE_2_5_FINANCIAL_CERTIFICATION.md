# Certificação da Etapa 2.5 — Financeiro

## 1. Identificação

**Data:** 04/09/2026

**Status:** CERTIFICADA LOCALMENTE, PENDENTE DE CI E INTEGRAÇÃO REMOTA

## 2. Escopo certificado localmente

- gates documentais `FIN-DOC-01` a `FIN-DOC-08`;
- models e registro central do domínio Financeiro;
- migration aditiva e árvore Alembic linear;
- repositories sem commit autônomo;
- serviços transacionais e integração idempotente com Venda;
- schemas de entrada e saída;
- API v1 protegida por três níveis de permissão;
- contrato OpenAPI atualizado;
- testes unitários, arquiteturais, de migration e regressão.

## 3. Evidências

| Gate | Resultado |
| --- | --- |
| Ruff focado | Aprovado |
| mypy focado | Aprovado |
| import de models e geração OpenAPI | Aprovado |
| suíte Python sem integração | 307 aprovados, 6 ignorados |
| integração PostgreSQL | 6 aprovados |
| cobertura | 100% |
| Alembic heads | `202609030100 (head)` |
| PostgreSQL real | Dump + F1-FIN (37 tabelas), upgrade, downgrade e novo upgrade aprovados |
| CI Linux | Pendente após integração |

## 4. Riscos residuais

- a migration exige as baselines Financeira e Comercial certificadas e bloqueia estruturas incompletas;
- integrações bancárias externas não fazem parte desta etapa e exigirão adaptadores próprios;
- regras contábeis e fiscais permanecem nas fronteiras definidas, sem cálculo implícito.

## 5. Decisão

A implementação está certificada localmente quanto a arquitetura, contratos, PostgreSQL e testes. A etapa somente
poderá ser declarada integrada remotamente após CI, merge e verificação pós-merge.
