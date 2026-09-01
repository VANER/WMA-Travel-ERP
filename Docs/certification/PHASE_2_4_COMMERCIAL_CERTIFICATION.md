# WMA Travel ERP — Certificação da Etapa 2.4

## Módulo Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend e API

**Etapa:** 2.4 — Comercial

**Data:** 31/08/2026

**Status:** APROVADA, CERTIFICADA E INTEGRADA

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

## 4. Evidências remotas

| Evidência | Estado |
| --- | --- |
| commit auditado | `698925e2de27d139a3ba3928c56e8cb6510f7475` |
| pull request | [#51](https://github.com/VANER/WMA-Travel-ERP/pull/51) |
| CI final do PR | [run 33344724386](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33344724386) |
| job Linux/Python 3.13/PostgreSQL | `99346572371`, aprovado em 1 min 8 s |
| merge em `main` | `7d103d801a44ebe35fc4a806399076bf2f6361d9` |
| CI pós-merge | [run 33344829611](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33344829611) |
| job pós-merge | `99346859697`, aprovado em 1 min 18 s |

## 5. Resultado

**ETAPA 2.4 — COMERCIAL: APROVADA, CERTIFICADA E INTEGRADA**

As evidências locais, o CI do PR, o merge e a validação pós-merge foram aprovados. A etapa 2.5 — Financeiro está
formalmente autorizada para execução.
