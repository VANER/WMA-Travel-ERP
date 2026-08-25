# WMA Travel ERP — Certificação da ETAPA 2.1.4

## Services do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.4 — Services do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar os casos de uso cadastrais do Core Corporativo, com limites transacionais explícitos e sem antecipar
schemas HTTP, endpoints ou regras não autorizadas pela baseline e pelo inventário.

## 2. Escopo auditado

- base genérica de service;
- services concretos para as nove autoridades corporativas;
- consultas sem efeitos transacionais;
- cadastro com commit único em sucesso;
- rollback para falhas do repository ou do commit;
- propagação de erros ao chamador;
- preservação das constraints e decisões adiadas da baseline;
- documentação e limites das etapas seguintes.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (44 arquivos)
mypy app tests ........................... OK (43 arquivos)
pytest -W error .......................... OK (86 testes; 2 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

## 4. Evidência PostgreSQL

O dump oficial foi restaurado em PostgreSQL 18 local e descartável. Um cadastro foi confirmado por commit; uma
tentativa duplicada acionou a constraint histórica, provocou rollback e deixou a mesma sessão novamente utilizável.
O `alembic check` não detectou novas operações. O container foi removido após a auditoria.

## 5. Gate transacional

```text
Leituras sem commit ou rollback .......... OK
Commit único após flush .................. OK
Rollback em falha do repository .......... OK
Rollback em falha do commit .............. OK
Erro original propagado .................. OK
Sessão recuperável após rollback ......... OK
Constraints PostgreSQL preservadas ....... OK
Regras não autorizadas ausentes .......... OK
```

## 6. Evidência Linux

O workflow do PR #26 foi aprovado na execução `32859036102`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados os 88 testes, incluindo integração PostgreSQL, com cobertura de 100%, lint, formatação, tipagem,
verificação e aplicação da árvore Alembic.

## 7. Resultado

**ETAPA 2.1.4 — SERVICES DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #26. A próxima etapa autorizada após sua integração é a 2.1.5 — Schemas.
