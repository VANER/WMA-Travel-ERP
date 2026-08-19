# ADR-004 --- Banco de Dados e Migrations

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A Fase 1 produziu uma baseline certificada e imutável. A Fase 2
precisará evoluir o banco sem alterar retroativamente esse marco.

## Problema

Estabelecer processo único, rastreável e reversível para mudanças
estruturais.

## Decisão

Usar Alembic para migrations versionadas. Toda mudança estrutural da
Fase 2 deverá ser representada por revision, revisada e testada. A
baseline da Fase 1 não será reescrita.

## Alternativas consideradas

- Alterar scripts da baseline --- rejeitado por destruir
    rastreabilidade.
- DDL manual em produção --- rejeitado por falta de reprodutibilidade.
- create_all() --- rejeitado como mecanismo de implantação.

## Consequências positivas

- Histórico auditável.
- Reprodução entre ambientes.
- Revisão de alterações.
- Possibilidade de rollback quando tecnicamente seguro.
- Proteção do marco da Fase 1.

## Consequências negativas

- Migrations exigem disciplina de ordem e dependência.
- Downgrade nem sempre é seguro para mudanças destrutivas.
- Conflitos de branches podem exigir reconciliação.

## Regras obrigatórias

- Uma cabeça Alembic por linha principal salvo ADR em contrário.
- Migration deve possuir descrição objetiva.
- Upgrade deve ser testado em banco de teste.
- Downgrade deve existir quando seguro; exceções precisam ser
    documentadas.
- Mudanças destrutivas exigem plano de dados/rollback.
- Nenhum secret ou dado sensível em migration.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Necessidade de múltiplas linhas de migration por serviços
    independentes.
- Mudança de ferramenta.
- Requisitos de zero-downtime que exijam estratégia expand/contract
    formal.
- Nova política de deploy de banco.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
