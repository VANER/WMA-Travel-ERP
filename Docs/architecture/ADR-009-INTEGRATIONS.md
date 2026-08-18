# ADR-009 --- Integrações e Webhooks

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

O ERP integrará website, pagamentos, operadoras, fiscal e outros
serviços. Falhas externas não podem corromper o domínio.

## Problema

Padronizar comunicação externa, retries, idempotência, webhooks e
rastreabilidade.

## Decisão

Centralizar adaptadores externos em integrations/, mantendo domínio
desacoplado de fornecedores. Usar HTTPS, timeouts explícitos,
idempotência quando aplicável, retries apenas para falhas transitórias
seguras e registro auditável de eventos relevantes.

## Alternativas consideradas

- Chamadas externas espalhadas pelos módulos --- rejeitadas.
- Acesso externo direto ao PostgreSQL --- proibido.
- Retry ilimitado --- proibido.

## Consequências positivas

- Troca de fornecedor mais simples.
- Tratamento uniforme de falhas.
- Maior observabilidade.
- Proteção contra duplicidades.

## Consequências negativas

- Camada adicional de adaptação.
- Algumas integrações exigirão particularidades específicas.
- Webhooks exigem segurança e reconciliação.

## Regras obrigatórias

- Toda chamada externa deve ter timeout.
- Retries devem ser limitados e seguros.
- Operações não idempotentes exigem chave/estratégia contra
    duplicidade.
- Webhooks devem ser autenticados/verificados quando o provedor
    permitir.
- Payload externo deve ser validado.
- Falha externa não deve deixar transação interna inconsistente.
- Credenciais seguem ADR-006.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Adoção de broker de mensagens.
- Volume assíncrono significativo.
- Necessidade de event-driven architecture.
- SLA externo exigir circuit breaker/filas dedicadas.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
