# WMA Travel ERP — Certificação da ETAPA 2.1.5

## Schemas do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.5 — Schemas do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar os contratos Pydantic de entrada e saída das nove autoridades corporativas, alinhados à baseline e sem
antecipar endpoints ou regras de domínio não aprovadas.

## 2. Escopo auditado

- contratos `Create` sem identidades ou auditoria administradas pelo servidor;
- contratos `Response` compatíveis com instâncias ORM;
- correspondência integral entre respostas e colunas dos nove models;
- limites de tamanho e tipos compatíveis com PostgreSQL;
- defaults de novos cadastros;
- nulabilidade histórica nas respostas;
- rejeição de campos extras;
- ausência de relacionamentos ORM nos contratos públicos.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (46 arquivos)
mypy app tests ........................... OK (45 arquivos)
pytest -W error .......................... OK (122 testes; 2 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

## 4. Gate dos contratos

```text
Nove entradas Create ..................... OK
Nove respostas ORM ....................... OK
IDs protegidos na entrada ................ OK
Auditoria protegida na entrada ........... OK
Campos extras rejeitados ................. OK
Decimal monetário preservado ............. OK
Defaults históricos refletidos ........... OK
Nulls históricos aceitos na saída ........ OK
Relacionamentos não expostos ............. OK
```

## 5. Evidência Linux

O workflow do PR #27 foi aprovado na execução `32860770419`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados os 124 testes, incluindo integração PostgreSQL, com cobertura de 100%, lint, formatação, tipagem,
verificação e aplicação da árvore Alembic.

## 6. Resultado

**ETAPA 2.1.5 — SCHEMAS DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #27. A próxima etapa autorizada após sua integração é a 2.1.6 — API.
