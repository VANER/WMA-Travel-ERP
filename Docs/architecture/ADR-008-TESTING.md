# ADR-008 --- Estratégia de Testes

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A Fase 2 precisa preservar a qualidade da baseline e impedir regressões
enquanto módulos e migrations evoluem.

## Problema

Definir níveis mínimos de teste e como eles entram no gate de entrega.

## Decisão

Adotar pytest como runner principal e HTTPX para API. Manter testes
unitários, integração, API, banco/migrations, segurança e regressão.
Testes críticos deverão rodar em CI.

## Alternativas consideradas

- Testes apenas manuais --- rejeitados.
- Somente testes end-to-end --- rejeitados por custo e diagnóstico
    difícil.
- Meta única de cobertura percentual --- rejeitada como único critério
    de qualidade.

## Consequências positivas

- Feedback rápido.
- Proteção contra regressão.
- Validação de contratos e migrations.
- Facilita refatoração segura.

## Consequências negativas

- Tempo de manutenção da suíte.
- Testes de integração exigem ambiente de banco controlado.
- Suítes extensas podem aumentar duração do CI.

## Regras obrigatórias

- Todo bug relevante corrigido deve ganhar teste de regressão quando
    viável.
- Regra de negócio crítica deve possuir teste.
- Migrations devem ser testadas.
- Testes não podem depender de dados pessoais reais.
- Suíte deve ser determinística.
- Falha em teste obrigatório bloqueia certificação/release.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- CI excessivamente lento.
- Mudança de arquitetura.
- Necessidade de testes de carga/contrato mais especializados.
- Novos requisitos de compliance.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
