# WMA Travel ERP — Certificação da ETAPA 2.0.2

## Bootstrap do Backend

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.2 — Bootstrap do Backend

**Data:** 19/08/2026

**Status:** APROVADA

## 1. Objetivo

Certificar a configuração inicial do backend e o atendimento do gate da etapa 2.0.2, preservando a baseline
imutável da Fase 1.

## 2. Escopo certificado

- Python 3.13, FastAPI, SQLAlchemy 2, Alembic e psycopg 3;
- configuração tipada por ambiente, sem credencial ou URL de banco embutida no código;
- aplicação ASGI executável com OpenAPI e health checks versionado e não versionado;
- correlation ID e formato inicial padronizado de erro;
- testes automatizados, lint, análise estática e cobertura mínima de 95%;
- pipeline GitHub Actions em Linux;
- lockfiles PEP 751 separados para Linux e Windows, incluindo hashes dos artefatos.

## 3. Evidências de validação

As verificações abaixo foram executadas no ambiente local da etapa:

```text
pip check ................................ OK
ruff check . ............................. OK
mypy app tests ........................... OK (18 arquivos)
pytest -W error --cov=app ................. OK (10 testes; 100%)
alembic heads ............................ OK
Uvicorn e GET /health .................... OK
OpenAPI 3.1 .............................. OK
SQLAlchemy/psycopg com PostgreSQL local .. OK
```

O lock Linux foi gerado e validado em `python:3.13-slim`. O lock Windows foi gerado e validado com Python 3.13.
O CI instala diretamente `pylock.linux.toml`, evitando nova resolução de dependências durante o gate.

## 4. Segurança e governança

- `.env` e caches locais permanecem ignorados pelo Git;
- nenhuma credencial foi adicionada aos lockfiles ou à documentação;
- nenhuma migration foi criada, pois o bootstrap não altera o schema;
- nenhum artefato histórico da Fase 1 foi modificado;
- a tag `phase-1-final-2026-08-18` permanece protegida.

## 5. Gate

```text
Estrutura Backend/ ....................... OK
Manifesto de dependências ................ OK
Lockfiles Linux e Windows ................ OK
FastAPI e OpenAPI ........................ OK
SQLAlchemy e psycopg ..................... OK
Alembic .................................. OK
Testes automatizados ..................... OK
Cobertura mínima de 95% .................. OK (100%)
Lint e tipagem ........................... OK
CI ....................................... OK
Configuração sem secrets ................. OK
Baseline da Fase 1 protegida ............. OK
```

## 6. Resultado

**ETAPA 2.0.2 — BOOTSTRAP DO BACKEND: APROVADA**

O projeto está autorizado a avançar para a etapa 2.0.3 — Estrutura Modular do Backend.

## 7. Publicação

Esta certificação, os lockfiles e as correções documentais compõem o fechamento publicado no PR #3. O merge
somente deve ocorrer após a aprovação de todos os checks obrigatórios.
