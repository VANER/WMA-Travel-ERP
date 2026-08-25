# WMA Travel ERP — Certificação da ETAPA 2.2.1

## Inventário e Modelo de Identidade

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.2.1 — Inventário e Modelo de Identidade

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a identificação das autoridades humanas, técnicas e legadas de acesso antes de implementar
autenticação, credenciais, sessões ou autorização.

## 2. Escopo auditado

- autoridade humana em `public.usuario`;
- perfis e atribuições temporais em `public.perfil_acesso` e `public.usuario_perfil`;
- catálogos independentes `public.permissao` e `public.politica_acesso`;
- identidades técnicas em `public.aplicacao_api`, `public.chave_api` e `public.token_acesso`;
- fronteira legada de `financeiro.usuario`;
- relações, constraints e lacunas comprovadas na baseline;
- negação por padrão e reserva de mudanças para migrations aditivas.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (49 arquivos)
mypy app tests ........................... OK (48 arquivos)
pytest -W error .......................... OK (158 testes; 3 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

## 4. Gate do inventário

```text
Identidade humana definida ............... OK
Identidades técnicas separadas ........... OK
Usuário financeiro classificado .......... OK
Relações da baseline verificadas ......... OK
Lacuna perfil–permissão registrada ....... OK
Token técnico não reinterpretado ......... OK
Negação por padrão registrada ............ OK
Baseline preservada ...................... OK
```

## 5. Evidência Linux/PostgreSQL

O workflow do PR #32 foi aprovado na execução `32868906699`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados os 161 testes, incluindo as três integrações PostgreSQL, com cobertura de 100%, lint, formatação,
tipagem, validação e aplicação da árvore Alembic.

## 6. Resultado

**ETAPA 2.2.1 — INVENTÁRIO E MODELO DE IDENTIDADE: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #32. A próxima etapa autorizada após sua integração é a 2.2.2 — Autenticação.
