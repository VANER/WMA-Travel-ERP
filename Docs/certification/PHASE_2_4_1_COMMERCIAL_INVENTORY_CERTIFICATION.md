# WMA Travel ERP — Certificação da ETAPA 2.4.1

## Inventário Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.4.1 — Inventário Comercial

**Data:** 30/08/2026

**Status:** APROVADA LOCALMENTE; CERTIFICAÇÃO REMOTA E INTEGRAÇÃO PENDENTES

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

## 6. Pendências de encerramento

- validar em CI Linux com PostgreSQL descartável;
- registrar pull request, commit auditado e execução remota;
- registrar merge e CI pós-merge antes de declarar a etapa integrada;
- somente então atualizar a próxima execução oficial para 2.4.2 — Clientes.

## 7. Resultado

**ETAPA 2.4.1 — INVENTÁRIO COMERCIAL: APROVADA LOCALMENTE**

A etapa não está declarada integrada nem libera a 2.4.2 enquanto as evidências remotas e pós-merge da seção 6 não
forem registradas.
