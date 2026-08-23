# WMA Travel ERP — Certificação da ETAPA 2.0.10

## GitHub Actions

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.10 — GitHub Actions

**Data:** 22/08/2026

**Status:** APROVADA E CERTIFICADA

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
Validação Linux/GitHub Actions ........... OK
```

## 5. Evidência Linux

O commit final do PR #15 foi aprovado na execução `32578163803`, e o merge na `main` foi revalidado na execução
`32578246572`, em Ubuntu e Python 3.13, com o serviço PostgreSQL 18 saudável e todos os gates obrigatórios
concluídos.

A auditoria corretiva do PR #19 ampliou o gate para formatar `migrations` e executar `alembic upgrade head` no
PostgreSQL descartável. O PR passou na execução `32642028747` e o merge `e3c61ec` foi revalidado na `main` pela
execução `32642096219`.

## 6. Resultado

**ETAPA 2.0.10 — GITHUB ACTIONS: APROVADA E CERTIFICADA**

A automação da fundação do backend foi validada localmente e no GitHub Actions. O PR #15 foi integrado à `main`
no commit `40cb9ac`.
