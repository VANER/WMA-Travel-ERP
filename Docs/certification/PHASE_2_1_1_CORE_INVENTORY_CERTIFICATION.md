# WMA Travel ERP — Certificação da ETAPA 2.1.1

## Inventário do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.1 — Inventário do Core Corporativo

**Data:** 23/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar que as estruturas corporativas existentes foram identificadas a partir da baseline oficial antes do
mapeamento SQLAlchemy, sem criar ou alterar objetos de banco.

## 2. Escopo auditado

- autoridades cadastrais de pessoa, empresa, cliente e fornecedor;
- documentos, tipos, arquivos, históricos e sequências;
- configurações por empresa e parâmetros globais;
- usuários como identidade transversal, com segurança reservada à etapa 2.2;
- localidade, colaboradores e demais entidades consumidoras;
- duplicatas financeiras e projeções analíticas;
- decisões adiadas de schema e inconsistências históricas;
- fronteira física do futuro módulo funcional.

## 3. Decisão de fronteira

O domínio funcional será implementado em `app/modules/corporativo`. `app/core` continuará contendo somente a
infraestrutura técnica transversal. A etapa 2.1.1 não cria o novo pacote nem antecipa models da etapa 2.1.2.

## 4. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check app tests migrations . OK (36 arquivos)
mypy app tests ........................... OK (35 arquivos)
pytest -W error --run-postgresql ......... OK (53 testes; 100%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

Os testes de inventário verificam a presença das nove tabelas autoritativas, das principais foreign keys e das
fronteiras adiadas diretamente no dump certificado.

## 5. Gate

```text
Baseline preservada ...................... OK
Autoridades identificadas ............... OK
Relações estruturais verificadas ......... OK
Duplicatas e projeções classificadas ..... OK
Segurança não antecipada ................. OK
Fronteira funcional definida ............. OK
Validação Linux/CI ....................... OK
```

## 6. Evidência Linux

O workflow do PR #21 foi aprovado na execução `32644026107`, em Ubuntu, Python 3.13 e PostgreSQL 18, incluindo os
53 testes, cobertura, lint, tipagem e aplicação da árvore Alembic.

## 7. Resultado

**ETAPA 2.1.1 — INVENTÁRIO DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

O inventário está apto para integração após a auditoria final do PR #21. A próxima etapa autorizada após o merge
é a 2.1.2 — Models.
