# Certificação da Etapa 2.3 --- Governança de API

**Projeto:** WMA Travel ERP

**Etapa:** 2.3 --- Governança de API

**Data da auditoria local:** 29/08/2026

**Status:** EM VALIDAÇÃO --- NÃO CERTIFICADA

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

## 6. Evidências remotas pendentes

Antes da certificação final, registrar:

- número e URL do pull request;
- commit auditado;
- execução do Backend CI em Linux/Python 3.13;
- quatro integrações PostgreSQL aprovadas;
- restauração da baseline e aplicação das migrations;
- classificador executado contra a branch-base real;
- merge commit e CI pós-merge.

## 7. Critério de encerramento

O status somente poderá mudar para **CONCLUÍDA, CERTIFICADA E INTEGRADA** depois que todas as evidências da
seção 6 forem registradas e os checks permanecerem aprovados. Este documento, no estado atual, não autoriza o
início do módulo Comercial nem a renumeração das etapas subsequentes.
