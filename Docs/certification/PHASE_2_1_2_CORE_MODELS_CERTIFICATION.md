# WMA Travel ERP — Certificação da ETAPA 2.1.2

## Models do Core Corporativo

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.1.2 — Models do Core Corporativo

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar o mapeamento SQLAlchemy das nove autoridades aprovadas no inventário 2.1.1, preservando integralmente
a baseline oficial e sem criar migrations retroativas.

## 2. Escopo auditado

- models `Localidade`, `Pessoa`, `Empresa`, `Cliente`, `Fornecedor`, `TipoDocumento`, `Documento`,
  `ConfiguracaoEmpresa` e `ParametroSistema`;
- tipos, tamanhos, nulabilidade, defaults, identities, constraints e foreign keys;
- relacionamentos internos com carregamento explícito;
- vínculo polimórfico histórico de documentos;
- registro central dos models e carregamento do metadata pelo Alembic;
- proteção dos objetos da baseline ainda não mapeados;
- fronteiras arquiteturais e documentação da etapa.

## 3. Evidências locais

```text
pip check ................................ OK
ruff check . ............................. OK
ruff format --check . .................... OK (40 arquivos)
mypy app tests ........................... OK (39 arquivos)
pytest -W error .......................... OK (56 testes; 2 opcionais ignorados)
cobertura ................................ OK (100%; mínimo 95%)
alembic heads ............................ OK
markdownlint-cli2 ........................ OK
git diff --check ......................... OK
```

Uma restauração descartável do dump oficial em PostgreSQL 18 também foi comparada com o metadata por
`alembic check`, que retornou `No new upgrade operations detected.`. Consultas reais com os nove models foram
executadas com sucesso. O banco descartável foi removido após a auditoria.

## 4. Gate de fidelidade

```text
Baseline histórica preservada ........... OK
Nove autoridades mapeadas ............... OK
Tipos e nulabilidade equivalentes ........ OK
Constraints e FKs históricas ............. OK
Identity de localidade preservada ........ OK
Vínculo documental sem FK inventada ...... OK
Autogenerate sem diferenças .............. OK
Migration retroativa ausente ............. OK
```

## 5. Evidência Linux

O workflow do PR #23 foi aprovado na execução `32851298710`, em Ubuntu, Python 3.13 e PostgreSQL 18. Foram
aprovados os 58 testes, incluindo integração PostgreSQL, com cobertura de 100%, lint, formatação, tipagem,
verificação e aplicação da árvore Alembic.

## 6. Resultado

**ETAPA 2.1.2 — MODELS DO CORE CORPORATIVO: APROVADA E CERTIFICADA**

A entrega está vinculada ao PR #23. A próxima etapa autorizada após sua integração é a 2.1.3 — Repositories.
