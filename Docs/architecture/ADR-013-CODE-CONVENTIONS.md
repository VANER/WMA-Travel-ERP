# ADR-013 --- Convenções de Código e Estrutura Modular

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

O monólito modular só preserva seus benefícios se nomes, imports,
responsabilidades e dependências forem consistentes.

## Problema

Evitar crescimento desorganizado e fronteiras de domínio frágeis.

## Decisão

Adotar estrutura modular por domínio, type hints, formatação/lint
automatizados e imports/dependências controlados. Código compartilhado
só entra em shared/core quando for genuinamente transversal.

## Alternativas consideradas

- Organização apenas por camada global (models/services/controllers)
    --- rejeitada por espalhar cada domínio.
- Pasta shared como destino genérico --- rejeitada.
- Convenções informais sem CI --- rejeitadas.

## Consequências positivas

- Navegação simples.
- Fronteiras mais claras.
- Revisões consistentes.
- Menor dívida técnica.

## Consequências negativas

- Exige disciplina de revisão.
- Alguma duplicação local pode ser preferível a abstração
    compartilhada prematura.

## Regras obrigatórias

- Organizar funcionalidades primariamente por domínio.
- Type hints obrigatórios no código novo relevante.
- Evitar dependência circular.
- Não criar abstrações compartilhadas sem uso real em múltiplos
    domínios.
- Ferramentas de lint/format/type-check serão configuradas na
    fundação.
- Nomes de módulos e APIs devem seguir convenção única documentada.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Crescimento significativo da equipe.
- Mudança de framework.
- Extração de módulos.
- Ferramentas de análise estática exigirem nova organização.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
