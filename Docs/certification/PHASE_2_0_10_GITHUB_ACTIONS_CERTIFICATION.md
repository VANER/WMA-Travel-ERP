# WMA Travel ERP — Certificação da ETAPA 2.0.10

## GitHub Actions

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.10 — GitHub Actions

**Data:** 22/08/2026

**Status:** APROVADA LOCALMENTE — VALIDAÇÃO CI PENDENTE

## 1. Objetivo

Certificar a automação Linux do backend para dependências bloqueadas, lint, formatação, tipagem, testes,
cobertura, integração PostgreSQL e validação da árvore Alembic.

## 2. Escopo auditado

- execução em Python 3.13 sobre Ubuntu;
- instalação reproduzível pelo lockfile Linux;
- permissões mínimas e cancelamento de execuções obsoletas;
- limite de tempo do job;
- PostgreSQL 18 efêmero e sem volume persistente;
- Ruff, Mypy, Pytest com warnings como erro e cobertura mínima de 95%;
- teste de integração PostgreSQL real com banco explicitamente descartável;
- validação da cabeça Alembic;
- testes de regressão da configuração do workflow.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check app tests ............ OK (34 arquivos)
mypy app tests ........................... OK (34 arquivos)
pytest -W error --run-postgresql ......... OK (47 testes; 100%)
alembic heads ............................ OK
```

A integração foi executada contra a imagem oficial `postgres:18`, em contêiner temporário sem volume, banco
`wma_phase2_test` e porta local exclusiva. O workflow está protegido por testes que verificam seus serviços,
limites e comandos obrigatórios.

## 4. Gate

```text
Dependências bloqueadas .................. OK
Ruff lint e formatação ................... OK
Mypy ..................................... OK
Pytest e cobertura >= 95% ................ OK (100%)
PostgreSQL real descartável .............. OK
Alembic heads ............................ OK
Segurança e limites do job ............... OK
Validação Linux/GitHub Actions ........... PENDENTE
```

## 5. Resultado preliminar

**ETAPA 2.0.10 — GITHUB ACTIONS: APROVADA LOCALMENTE**

A certificação definitiva depende da execução bem-sucedida do workflow no pull request da etapa.
