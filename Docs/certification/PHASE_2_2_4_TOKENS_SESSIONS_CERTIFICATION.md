# WMA Travel ERP — Certificação da ETAPA 2.2.4

## Tokens e Sessões

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.2.4 — Tokens e Sessões

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar o ciclo de vida de tokens e sessões humanas após autenticação, sem antecipar perfis, roles,
permissions, autorização, proteção de endpoints ou recuperação de acesso.

## 2. Escopo auditado

- access token JWT HS256 curto, com algoritmo e claims obrigatórios fixos;
- chave de assinatura obrigatória, validada e protegida contra exposição;
- refresh token opaco de alta entropia persistido somente como SHA-256;
- rotação de uso único com bloqueio pessimista;
- detecção de reutilização e revogação da família;
- separação entre sessões humanas e tokens técnicos de aplicações;
- model, repository e serviço sem controle transacional indevido;
- migration aditiva, reversível, comentada e vinculada à baseline;
- workflow capaz de restaurar o dump certificado antes das migrations.

## 3. Evidências locais

```text
pip check ................................ OK
ruff format --check app tests migrations . OK (59 arquivos)
ruff check . ............................. OK
mypy app tests ........................... OK (57 arquivos)
pytest -W error --run-postgresql ......... OK (194 testes; sem skips)
cobertura ................................ OK (100%; mínimo 95%)
restauração da baseline PostgreSQL 18 .... OK
alembic upgrade/downgrade/upgrade ........ OK
alembic check ............................ OK (sem drift)
comentários de colunas e triggers ........ OK
auditoria real de INSERT e UPDATE ........ OK
pip-audit ................................ OK (nenhuma vulnerabilidade conhecida)
markdownlint dos documentos alterados .... OK
git diff --check ......................... OK
```

## 4. Evidência Linux/PostgreSQL

O workflow do PR #35 foi aprovado na execução `32906887241`, job `97992835915`, em Ubuntu, Python 3.13 e
PostgreSQL 18. O commit validado foi `71f754b0a68a3cd43291617c31e1a297c0572821`.

Foram aprovados instalação reproduzível, dependências, lint, formatação, tipagem, 194 testes com integração
PostgreSQL, cobertura de 100%, restauração do dump certificado, árvore Alembic e aplicação da migration no banco
descartável.

## 5. Gate de tokens e sessões

```text
JWT com algoritmo fixo .................... OK
Claims obrigatórias e TTL curto ........... OK
Refresh token opaco e não persistido ...... OK
Rotação de uso único ...................... OK
Reutilização detectada .................... OK
Revogação por família ..................... OK
Sessão humana separada de token técnico ... OK
Migration reversível e sem drift .......... OK
Baseline preservada ....................... OK
Autorização e endpoints não antecipados ... OK
```

## 6. Resultado

**ETAPA 2.2.4 — TOKENS E SESSÕES: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #35. A próxima etapa autorizada após sua integração é a 2.2.5 — Perfis.
