# WMA Travel ERP — Certificação da ETAPA 2.2.3

## Hash de Credenciais

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.2.3 — Hash de Credenciais

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a política Argon2id para credenciais humanas consumida pela autenticação, sem antecipar migrations,
tokens, sessões, autorização ou persistência automática de rehash.

## 2. Escopo auditado

- Argon2id com parâmetros explícitos e versionados no formato PHC;
- salt aleatório de 16 bytes para cada hash;
- geração e verificação de credenciais com limite de entrada;
- hash fictício para identidade ausente ou hash inválido;
- detecção de hashes que precisam de atualização;
- dependência direta fixada e lockfiles distintos para Linux e Windows;
- compatibilidade estrutural com `public.usuario.senha_hash`, sem migration;
- ausência deliberada de tokens, sessões, autorização e persistência de rehash.

## 3. Evidências locais

```text
pip check ................................ OK
ruff format --check app tests migrations . OK (56 arquivos)
ruff check . ............................. OK
mypy app tests ........................... OK (55 arquivos)
pytest -W error --run-postgresql ......... OK (180 testes; sem skips)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
alembic upgrade head ..................... OK (PostgreSQL 18 descartável)
pip-audit ................................ OK (nenhuma vulnerabilidade conhecida)
testes Argon2id Linux/Python 3.13 ........ OK (9 testes)
markdownlint dos documentos alterados .... OK
git diff --check ......................... OK
```

## 4. Evidência Linux/PostgreSQL

O workflow do PR #34 foi aprovado na execução `32899990439`, job `97971306436`, em Ubuntu, Python 3.13 e
PostgreSQL 18. O commit validado foi `c37fb776d48596a017051c938af8ca69cafff47c`.

Foram aprovados instalação reproduzível, dependências, lint, formatação, tipagem, 180 testes com integração
PostgreSQL, cobertura de 100%, árvore Alembic e aplicação das migrations no banco descartável.

## 5. Gate do hash de credenciais

```text
Argon2id e parâmetros explícitos ......... OK
Salt aleatório por hash .................. OK
Geração e verificação .................... OK
Falha uniforme com hash fictício ......... OK
Limite contra entrada abusiva ............ OK
Detecção de rehash ....................... OK
Lockfiles Linux e Windows ................ OK
Vulnerabilidades conhecidas .............. NENHUMA
Migration não antecipada ................. OK
Tokens, sessões e autorização adiados .... OK
```

## 6. Resultado

**ETAPA 2.2.3 — HASH DE CREDENCIAIS: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #34. A próxima etapa autorizada após sua integração é a 2.2.4 — Tokens e
Sessões.
