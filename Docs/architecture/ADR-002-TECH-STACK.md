# ADR-002 --- Stack Tecnológica

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A aplicação precisa de uma stack coerente com PostgreSQL 18.x, APIs
HTTP, tipagem, validação, migrations e testes automatizados.

## Problema

Definir tecnologias oficiais para impedir escolhas divergentes durante a
implementação.

## Decisão

Adotar Python 3.13+, FastAPI, Uvicorn, Pydantic v2, SQLAlchemy 2.x,
Alembic, psycopg 3, PostgreSQL 18.x, pytest, HTTPX, OpenAPI e GitHub
Actions. Versões exatas serão fixadas no pyproject.toml/lockfile após
validação de compatibilidade.

## Alternativas consideradas

- Django/DRF --- robusto, porém mais opinativo e com componentes além
    do necessário para a API inicial.
- Node.js/NestJS --- viável, mas adicionaria outra stack principal ao
    projeto.
- .NET ASP.NET Core --- tecnicamente forte, mas não escolhido para
    manter produtividade e aderência à stack definida.

## Consequências positivas

- Boa produtividade para APIs.
- Tipagem e validação fortes.
- Documentação OpenAPI automática.
- Ecossistema maduro para PostgreSQL e testes.
- Baixa barreira para automação e BI futuro.

## Consequências negativas

- Dependência do ecossistema Python.
- Atualizações de bibliotecas exigem gestão de compatibilidade.
- Código assíncrono exige disciplina quando adotado.

## Regras obrigatórias

- Dependências devem ser declaradas em pyproject.toml.
- Versões devem ser fixadas/reproduzíveis.
- Atualizações relevantes exigem testes e revisão.
- Bibliotecas novas precisam de justificativa técnica.
- Somente versões suportadas e sem vulnerabilidade crítica conhecida
    podem compor release.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Fim de suporte de componente central.
- Incompatibilidade relevante com PostgreSQL ou Python.
- Vulnerabilidade crítica sem correção adequada.
- Necessidade funcional não atendida pela stack.
- Custo operacional ou desempenho comprovadamente inadequado.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
