# ADR-014 --- Limites Transacionais entre Módulos

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

Fluxos como Venda → Reserva → Financeiro podem alterar múltiplos
módulos. Limites mal definidos geram commits parciais e inconsistência.

## Problema

Definir quem inicia, confirma e desfaz transações que atravessam
serviços internos.

## Decisão

A camada de caso de uso/service orquestrador define o limite
transacional. Repositories participam da sessão/transação fornecida e
não realizam commits autônomos por padrão. Fluxos síncronos internos que
exigem atomicidade usam uma transação PostgreSQL.

## Alternativas consideradas

- Commit dentro de cada repository --- rejeitado.
- Transação por endpoint sem considerar caso de uso --- insuficiente.
- Consistência eventual para todos os módulos --- desnecessária no
    monólito inicial.

## Consequências positivas

- Atomicidade clara.
- Rollback integral em falha.
- Integração simples entre módulos no mesmo banco.
- Facilita testes de consistência.

## Consequências negativas

- Transações longas podem gerar locks.
- Chamadas externas não devem permanecer dentro de transações longas.
- Orquestração exige desenho explícito.

## Regras obrigatórias

- Repository não faz commit autônomo salvo exceção documentada.
- Chamadas HTTP externas não devem ficar dentro de transação de banco
    aberta quando evitável.
- Falha deve provocar rollback do caso de uso atômico.
- Operações pós-commit externas devem usar estratégia de
    reconciliação/idempotência.
- Limites transacionais críticos devem possuir testes.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Adoção de microserviços.
- Introdução de filas/eventos.
- Necessidade de saga/outbox.
- Problemas de lock ou throughput comprovados.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
