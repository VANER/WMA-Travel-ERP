# WMA Travel ERP — Certificação da ETAPA 2.2.2

## Autenticação

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.2.2 — Autenticação

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a autenticação da identidade humana de `public.usuario` sem antecipar algoritmo de hash, tokens,
sessões, autorização ou migrations reservadas às etapas seguintes.

## 2. Escopo auditado

- reflexo fiel da autoridade humana existente na baseline;
- consulta somente leitura por e-mail sem espaços externos;
- validação dos estados ativo, excluído e credencial ausente;
- recusa uniforme contra enumeração de contas;
- porta abstrata para a futura política de hash;
- identidade autenticada sem perfil, permissão, token ou sessão;
- ausência deliberada de endpoint enquanto não houver artefato de sessão aprovado.

## 3. Evidências locais

```text
pip check ................................ OK
ruff format --check app tests migrations . OK (54 arquivos)
ruff check . ............................. OK
mypy app tests ........................... OK (53 arquivos)
pytest -W error --run-postgresql ......... OK (171 testes)
cobertura ................................ OK (100%; mínimo 95%)
alembic check contra baseline ............ OK (nenhuma operação nova)
markdownlint dos documentos alterados .... OK
git diff --check ......................... OK
```

A baseline foi restaurada em PostgreSQL 18 descartável. A primeira comparação identificou diferença no comentário
de `public.usuario`; o model foi corrigido para o texto certificado e a repetição não detectou operações novas.

## 4. Evidência Linux/PostgreSQL

O workflow do PR #33 foi aprovado na execução `32894861102`, job `97955042413`, em Ubuntu, Python 3.13 e
PostgreSQL 18. O commit validado foi `b3fce73ab01e9facd897b0ffbcd5e1b7803abbe2`.

Foram aprovados instalação reproduzível, dependências, lint, formatação, tipagem, 171 testes com integração
PostgreSQL, cobertura de 100%, árvore Alembic e aplicação das migrations no banco descartável.

## 5. Gate da autenticação

```text
Autoridade humana refletida .............. OK
Consulta somente leitura ................. OK
Estados inválidos negados ................ OK
Falha uniforme ........................... OK
Política de hash não antecipada .......... OK
Tokens e sessões não antecipados ......... OK
Autorização não antecipada ............... OK
Baseline preservada ...................... OK
```

## 6. Resultado

**ETAPA 2.2.2 — AUTENTICAÇÃO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #33. A próxima etapa autorizada após sua integração é a 2.2.3 — Hash de
Credenciais.
