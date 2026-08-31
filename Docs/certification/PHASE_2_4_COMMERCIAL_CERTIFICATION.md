# WMA Travel ERP — Candidata à Certificação da Etapa 2.4

## Módulo Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend e API

**Etapa:** 2.4 — Comercial

**Data:** 31/08/2026

**Status:** IMPLEMENTAÇÃO COMPLETA E APROVADA LOCALMENTE; INTEGRAÇÃO REMOTA PENDENTE

## 1. Escopo auditado

As subetapas 2.4.1 e 2.4.2 permanecem certificadas e integradas. Este incremento implementa e audita localmente
as subetapas 2.4.3 a 2.4.12: Leads, CRM, Fornecedores e Operadoras, Oportunidades, Propostas, Condições Comerciais,
Vendas, Contratos, API Comercial e testes.

## 2. Evidências locais

| Gate | Resultado |
| --- | --- |
| `python -m pip check` | Aprovado |
| `python -m ruff check .` | Aprovado |
| `python -m mypy app tests` | Aprovado em 80 arquivos |
| suíte completa com cobertura | 288 aprovados, 6 opt-in ignorados; 100% de 1.944 statements |
| integração PostgreSQL opt-in | 6 aprovados, incluindo conversão comercial integral |
| restauração do dump oficial | Aprovada em `wma_phase_24_full_test` |
| Alembic upgrade | `202608310100` aprovado |
| Alembic downgrade/upgrade | Aprovado até `202608262200` e novamente até a head |
| tabelas novas | 5 encontradas |
| FKs de integração | 4 encontradas |
| permissões RBAC | 2 encontradas |
| OpenAPI | Snapshot sincronizado e verificação aprovada |

## 3. Auditoria funcional

```text
Autoridades Corporativo/Turismo preservadas ........ OK
Unicidade Cliente/Pessoa no banco ................... OK
Transições de estado explícitas ..................... OK
Cálculos quantizados em centavos .................... OK
Conversão Proposta → Venda única .................... OK
Rastreabilidade até Contrato/Reserva ................ OK
RBAC de leitura e gestão ............................ OK
Rollback da migration ............................... OK
Cobertura integral do código novo ................... OK
```

## 4. Evidências remotas pendentes

| Evidência | Estado |
| --- | --- |
| commit auditado | Pendente de autorização explícita |
| CI Linux/Python 3.13/PostgreSQL | Pendente |
| pull request | Pendente |
| merge em `main` | Pendente |
| CI pós-merge | Pendente |

## 5. Resultado local

**ETAPA 2.4 — IMPLEMENTAÇÃO COMPLETA E CANDIDATA À CERTIFICAÇÃO FINAL**

A etapa não deve ser declarada integrada nem liberar a 2.5 antes do preenchimento das evidências remotas e da
validação pós-merge exigidas pelo cronograma oficial.
