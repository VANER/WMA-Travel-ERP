# WMA Travel ERP — Certificação da ETAPA 2.4.1

## Inventário Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.4.1 — Inventário Comercial

**Data:** 30/08/2026

**Status:** APROVADA, CERTIFICADA E INTEGRADA

## 1. Objetivo

Registrar a aprovação local do inventário das estruturas comerciais existentes antes de qualquer migration,
modelagem funcional ou API das etapas 2.4.2 a 2.4.13.

## 2. Escopo auditado

- autoridade transacional do schema `public` e projeções não autoritativas;
- clientes, contatos, fornecedores e especialização turística;
- origens, leads, interações e movimentos do funil;
- campanha e parceiro comercial como estruturas isoladas de autoridade ainda pendente;
- vendas, itens, comissões e contratos;
- projeções analíticas, incluindo `public.vw_dashboard_comercial_bi`;
- foreign keys internas e dependências com Core, Turismo, documentos e colaboradores;
- lacunas entre a baseline e o fluxo Comercial planejado;
- ausências de oportunidade, proposta, operadora e condição comercial como estruturas explícitas;
- fronteira do futuro módulo `app/modules/comercial`.

## 3. Decisões do inventário

1. `public` permanece como autoridade dos dados comerciais;
2. Cliente e Fornecedor permanecem sob autoridade cadastral do Core Corporativo;
3. o funil existente não será reinterpretado silenciosamente como agregado Oportunidade;
4. estruturas ausentes exigirão decisões rastreáveis e migrations aditivas nas subetapas proprietárias;
5. dependências com Produto Turístico e Reserva não autorizam antecipar o módulo Turismo;
6. nenhuma inconsistência da baseline será corrigida retroativamente.

## 4. Evidências locais

| Gate | Resultado |
| --- | --- |
| `python -m pip check` | Aprovado |
| `python -m ruff check .` | Aprovado |
| `python -m ruff format --check app tests migrations scripts` | Aprovado em 78 arquivos |
| `python -m mypy app tests` | Aprovado em 70 arquivos |
| `python -m pytest -W error --cov=app --cov-report=term-missing` | 256 aprovados; 4 opt-in ignorados |
| cobertura | 100% de 1.347 statements |
| integração PostgreSQL com `--run-postgresql` | 4 aprovadas em banco local descartável |
| `python -m alembic heads` | `202608262200 (head)` |
| Markdownlint | Aprovado nos documentos da etapa |
| `git diff --check` | Aprovado |

Os seis testes específicos verificam no dump oficial as 13 tabelas do fluxo principal, duas estruturas comerciais
isoladas, uma view analítica, 15 foreign keys, as ausências estruturais registradas e a preservação das fronteiras
de domínio.

## 5. Gate local

```text
Baseline preservada ...................... OK
Autoridades identificadas ............... OK
Relações estruturais verificadas ......... OK
Projeções não autoritativas separadas ..... OK
Lacunas do fluxo registradas ............. OK
Domínios posteriores não antecipados ..... OK
Migration criada ......................... NÃO APLICÁVEL
```

## 6. Evidências remotas

| Evidência | Resultado |
| --- | --- |
| pull request | [#47](https://github.com/VANER/WMA-Travel-ERP/pull/47) |
| commit auditado | `2d927a84017936f79df7824a259667604fd54faa` |
| Backend CI | [run 33326105232](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33326105232) |
| job Linux/Python 3.13 | `99296392804`, aprovado em 1 min 16 s |
| testes e integrações PostgreSQL | Aprovados |
| baseline e migrations | Restauração e aplicação aprovadas |
| contrato OpenAPI | Snapshot e compatibilidade aprovados |
| commit final do PR | `a46550c` |
| CI final do PR | [run 33326258814](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33326258814) |
| job final do PR | `99296799846`, aprovado em 1 min 11 s |
| merge do PR #47 | `28db82a5ba97aa1484c2c8e9dbc6a3ff642499dd` |
| CI pós-merge em `main` | [run 33326342384](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33326342384) |
| job pós-merge | `99297032415`, aprovado em 1 min 12 s |

## 7. Critério de encerramento

O CI do commit final, o merge e a execução pós-merge permaneceram aprovados. A etapa está integrada à `main`, e a
próxima execução autorizada é a 2.4.2 — Clientes.

## 8. Resultado

**ETAPA 2.4.1 — INVENTÁRIO COMERCIAL: APROVADA, CERTIFICADA E INTEGRADA**

A baseline foi preservada, todas as evidências locais e remotas foram aprovadas e a 2.4.2 — Clientes está
formalmente autorizada para execução.
