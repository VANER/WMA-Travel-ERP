# WMA Travel ERP — Certificação da ETAPA 2.4.2

## Clientes do Módulo Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.4.2 — Clientes

**Data:** 30/08/2026

**Status:** APROVADA LOCALMENTE; CERTIFICAÇÃO REMOTA E INTEGRAÇÃO PENDENTES

## 1. Objetivo

Registrar a aprovação local dos serviços comerciais de Cliente sobre a autoridade cadastral do Core Corporativo,
sem duplicar model, tabela, migration ou endpoint.

## 2. Escopo certificado localmente

- contrato interno entre Core e Comercial;
- projeções imutáveis de Pessoa e Cliente;
- adaptador SQLAlchemy sem commit autônomo;
- habilitação de Pessoa elegível como Cliente;
- prevenção sequencial de papel duplicado;
- validações e erros de domínio;
- commit único e rollback integral;
- consulta interna por Pessoa;
- integração em PostgreSQL descartável;
- documentação da lacuna de concorrência da baseline.

## 3. Evidências locais

| Gate | Resultado |
| --- | --- |
| `python -m pip check` | Aprovado |
| `python -m ruff check .` | Aprovado |
| `python -m ruff format --check app tests migrations scripts` | Aprovado em 82 arquivos |
| `python -m mypy app tests` | Aprovado em 74 arquivos |
| `python -m pytest -W error --cov=app --cov-report=term-missing` | 273 aprovados; 5 opt-in ignorados |
| cobertura total | 100% de 1.440 statements |
| testes específicos | 17 aprovados |
| cobertura das novas camadas | 100% de 93 statements |
| integração PostgreSQL | 5 testes aprovados; 1 fluxo específico da 2.4.2 |
| banco descartável | Removido após a validação |
| `python -m alembic heads` | `202608262200 (head)` |
| Markdownlint | Aprovado nos documentos da etapa |
| `git diff --check` | Aprovado |
| migration criada | Não aplicável |
| alteração OpenAPI | Nenhuma |

## 4. Gate local

```text
Autoridade do Core preservada ............ OK
Contrato interno explícito ............... OK
Pessoa inexistente rejeitada ............. OK
Pessoa excluída rejeitada ................ OK
Papel duplicado rejeitado ................ OK
Commit e rollback cobertos ............... OK
Integração PostgreSQL .................... OK
Migration criada ........................ NÃO APLICÁVEL
Endpoint criado ......................... NÃO APLICÁVEL
```

## 5. Risco aceito para continuidade

`public.cliente.id_pessoa` não possui unicidade na baseline. A proteção implementada evita duplicidade sequencial,
mas não substitui uma constraint em concorrência real. A etapa não altera silenciosamente o schema; a decisão
estrutural permanece pendente de migration aditiva autorizada.

## 6. Pendências de encerramento

- validar em CI Linux/PostgreSQL;
- registrar PR, commits, merge e CI pós-merge;
- liberar a 2.4.3 — Leads somente após integração.

## 7. Resultado

**ETAPA 2.4.2 — CLIENTES: APROVADA LOCALMENTE**

A etapa não está declarada integrada e não libera a 2.4.3 enquanto as evidências remotas e pós-merge não forem
registradas.
