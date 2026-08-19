# ADR-010 --- Observabilidade e Auditoria Técnica

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

Com múltiplos módulos e integrações, problemas precisam ser
diagnosticáveis sem depender de acesso manual ao banco.

## Problema

Definir sinais mínimos de saúde, métricas, logs e rastreabilidade.

## Decisão

Adotar observabilidade progressiva com health checks, logs estruturados,
correlation ID, métricas e auditoria técnica. Ferramentas específicas de
coleta/visualização serão escolhidas quando a infraestrutura de deploy
for definida.

## Alternativas consideradas

- Somente arquivos de log locais --- insuficiente como estratégia
    final.
- APM completo desde o primeiro commit --- adiado até existir
    infraestrutura e carga reais.

## Consequências positivas

- Diagnóstico mais rápido.
- Rastreabilidade entre API e integrações.
- Base para alertas e capacidade.
- Melhor suporte operacional.

## Consequências negativas

- Custo de armazenamento e ferramentas.
- Instrumentação exige disciplina.
- Dados de logs precisam de proteção.

## Regras obrigatórias

- Health check não deve expor secrets.
- Logs estruturados devem incluir contexto mínimo.
- Correlation ID deve atravessar chamadas relevantes.
- Dados pessoais/sensíveis devem ser minimizados ou mascarados.
- Falhas críticas devem ser detectáveis.
- Auditoria de negócio e log técnico não devem ser confundidos.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Definição da infraestrutura de produção.
- SLA formal.
- Necessidade de tracing distribuído.
- Migração para microserviços.
- Exigências de retenção/compliance.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
