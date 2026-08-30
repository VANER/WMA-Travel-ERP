# WMA Travel ERP — Certificação da ETAPA 2.4.2

## Clientes do Módulo Comercial

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.4.2 — Clientes

**Data:** 30/08/2026

**Status:** APROVADA, CERTIFICADA E INTEGRADA

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

## 6. Evidências remotas

| Evidência | Resultado |
| --- | --- |
| pull request | [#49](https://github.com/VANER/WMA-Travel-ERP/pull/49) |
| commit auditado | `66327a59e95b383685fb1cf3d839c60fdaa7433d` |
| Backend CI | [run 33327899335](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33327899335) |
| job Linux/Python 3.13 | `99301191472`, aprovado em 1 min |
| testes e integrações PostgreSQL | Aprovados |
| arquitetura modular | Aprovada |
| baseline e migrations | Restauração e aplicação aprovadas |
| contrato OpenAPI | Snapshot e compatibilidade aprovados |
| commit final do PR | `c66defdc8144a31e94b5ee4579aac7a725e8a927` |
| CI final do PR | [run 33328078331](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33328078331) |
| job final do PR | `99301663471`, aprovado em 1 min 13 s |
| merge do PR #49 | `6e24f64c8e81cbad6fa2678238c670742b19ac6b` |
| CI pós-merge em `main` | [run 33328179748](https://github.com/VANER/WMA-Travel-ERP/actions/runs/33328179748) |
| job pós-merge | `99301934021`, aprovado em 1 min 11 s |

## 7. Critério de encerramento

O CI do commit final, o merge e a execução pós-merge permaneceram aprovados. A etapa está integrada à `main`, e a
próxima execução autorizada é a 2.4.3 — Leads.

## 8. Resultado

**ETAPA 2.4.2 — CLIENTES: APROVADA, CERTIFICADA E INTEGRADA**

As autoridades foram preservadas, todas as evidências locais e remotas foram aprovadas e a 2.4.3 — Leads está
formalmente autorizada para execução.
