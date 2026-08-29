# Inventário de Governança da API

**Etapa:** preparação da 2.3 - Governança de API  
**Data do inventário:** 28/08/2026  
**Estado:** inventário concluído; escopo executivo reconciliado pela ADR-016

## 1. Objetivo

Registrar o estado verificável da API antes de novas decisões de governança. Este documento não altera contratos,
rotas, schema de banco ou artefatos históricos.

## 2. Fronteiras atuais

- aplicação FastAPI publicada sob `/api`;
- contrato funcional atual sob `/api/v1`;
- saúde global em `/health` e saúde versionada em `/api/v1/health`;
- OpenAPI 3.1 em `/openapi.json`;
- interfaces interativas em `/docs` e `/redoc`;
- domínios publicados: Core Corporativo e Segurança;
- autenticação por bearer token nos recursos protegidos;
- rastreabilidade por `X-Correlation-Id`;
- erros de aplicação representados pelo schema `ErrorResponse`.

## 3. Controles já verificáveis

| Controle | Evidência executável | Estado |
| --- | --- | --- |
| prefixo de versão | `Backend/app/api/router.py` | Implementado |
| metadata OpenAPI | `Backend/tests/test_openapi.py` | Coberto |
| documentação interativa | `Backend/tests/test_openapi.py` | Coberto |
| identificadores de operação únicos | `Backend/tests/test_openapi.py` | Coberto |
| `operationId` explícito e estável | decorators FastAPI e `Backend/tests/test_openapi.py` | Coberto |
| tags em todas as operações | `Backend/tests/test_openapi.py` | Coberto |
| presença de resposta de sucesso | `Backend/tests/test_openapi.py` | Coberto |
| schemas de erro cobertos | `Backend/tests/test_openapi.py` e `Backend/tests/test_errors.py` | Coberto |
| correlation ID | `Backend/tests/test_errors.py` e testes de middleware | Coberto |
| snapshot canônico do contrato | `Backend/openapi.json` e CI | Coberto |

## 4. Decisões consolidadas

As decisões de compatibilidade, ciclo de vida, depreciação e retirada de versões foram aprovadas pela ADR-016.
O contrato de paginação vigente foi formalizado como `offset`/`limite` em `API.md`.

## 5. Pendências para o gate

1. validar integrações PostgreSQL no CI Linux;
2. consolidar a auditoria e a certificação da etapa.

O classificador deverá ser ampliado quando novos formatos de schema forem adotados.

## 6. Não conformidade documental resolvida

**GOV-API-001:** `AGENTS.md`, `Docs/README.md`, `Docs/PROJECT_DOCUMENTATION.md` e
`Docs/architecture/README.md` declaram a próxima etapa como **2.3 - Governança de API**. Entretanto,
`Docs/PHASE_2_ROADMAP.md` e `Docs/PHASE_2_EXECUTION_ORDER.md` definiam **2.3 - Comercial** e seus respectivos
subitens.

A ADR-016 resolveu a divergência de forma aditiva: a etapa oficial 2.3 é Governança de API. O bloco Comercial foi
marcado como planejamento legado suspenso, preservando seu conteúdo até a reprogramação das etapas subsequentes.

## 7. Critério para prosseguir

A próxima entrega da governança da API exige:

- concluir os itens da seção 5;
- manter os controles automatizados coerentes com a ADR-016;
- validação integral do backend e certificação própria da etapa.
