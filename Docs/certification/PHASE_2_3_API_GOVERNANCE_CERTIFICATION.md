# Certificação da Etapa 2.3 --- Governança de API

**Projeto:** WMA Travel ERP

**Etapa:** 2.3 --- Governança de API

**Data da auditoria local:** 29/08/2026

**Status:** AUDITORIA APROVADA --- MERGE E CI PÓS-MERGE PENDENTES

## 1. Objetivo

Consolidar as decisões, controles e evidências da governança do contrato HTTP antes de autorizar os próximos
módulos operacionais da Fase 2.

## 2. Escopo auditado

- contrato OpenAPI 3.1 versionado;
- ciclo de vida, compatibilidade e depreciação;
- `operationId` explícito e estável;
- paginação, filtros e ordenação;
- matriz de respostas HTTP;
- propriedade, aprovação e exceções;
- snapshot e classificador de breaking changes;
- testes, cobertura, tipagem, lint e migrations;
- coerência dos roteiros da Fase 2.

## 3. Decisões e controles

| Controle | Evidência | Resultado |
| --- | --- | --- |
| padrões e ciclo de vida | `architecture/ADR-016-API-GOVERNANCE.md` | Aprovado |
| inventário | `API_GOVERNANCE_INVENTORY.md` | Concluído |
| paginação vigente | `API.md` e testes OpenAPI | `offset`/`limite` |
| identificadores | 35 decorators e teste AST | Explícitos e estáveis |
| respostas HTTP | `API_RESPONSE_MATRIX.md` | Aprovada |
| propriedade | `.github/CODEOWNERS` | `@VANER` |
| evidências de PR | `.github/pull_request_template.md` | Controladas |
| aprovação e exceções | `API_CHANGE_GOVERNANCE.md` | Aprovadas |
| snapshot | `Backend/openapi.json` | Sincronizado |
| compatibilidade | `check_openapi_compatibility.py` | Sem quebra detectada |

## 4. Correções da auditoria

1. a paginação documental `page`/`page_size` foi alinhada ao contrato `offset`/`limite`;
2. o planejamento ativo da 2.3 foi separado dos identificadores do Comercial legado;
3. os 35 `operationId` gerados automaticamente foram declarados explicitamente sem alterar o snapshot;
4. respostas específicas ausentes foram adicionadas de forma compatível;
5. o classificador foi corrigido para carregar a baseline Git a partir da raiz do repositório;
6. propriedade, aprovação e exceções receberam controles versionados.

## 5. Evidências locais

| Gate | Resultado |
| --- | --- |
| `python -m pip check` | Aprovado |
| `python -m ruff check .` | Aprovado |
| `python -m ruff format --check app tests migrations scripts` | Aprovado |
| `python -m mypy app tests scripts` | Aprovado em 72 arquivos |
| `python -m pytest -W error --cov=app --cov-report=term-missing` | 250 aprovados; 4 opt-in |
| cobertura | 100% de 1.347 statements |
| `python -m alembic heads` | `202608262200 (head)` |
| snapshot OpenAPI | Sincronizado |
| classificador contra `HEAD` | Nenhuma mudança incompatível |
| Markdownlint | 13 documentos aprovados |
| `git diff --check` | Aprovado |

## 6. Evidências remotas

| Evidência | Resultado |
| --- | --- |
| pull request | [#43](https://github.com/VANER/WMA-Travel-ERP/pull/43) |
| commit auditado | `fa8c066527c918f9dae2ab04d19827f623d7fe52` |
| Backend CI | [run 33249820518](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33249820518) |
| job Linux/Python 3.13 | `99093459926`, aprovado em 1 min 3 s |
| testes e integrações PostgreSQL | Aprovados |
| baseline e migrations | Restauração e aplicação aprovadas |
| contrato OpenAPI | Snapshot e compatibilidade contra a branch-base aprovados |

Permanecem pendentes antes da certificação final:

- merge commit e CI pós-merge.

## 7. Critério de encerramento

O status somente poderá mudar para **CONCLUÍDA, CERTIFICADA E INTEGRADA** depois que todas as evidências da
seção 6 forem registradas e os checks permanecerem aprovados. Este documento, no estado atual, não autoriza o
início do módulo Comercial nem a renumeração das etapas subsequentes.
