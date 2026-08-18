# ADR-012 --- Logging e Correlation ID

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

Uma operação pode atravessar endpoint, serviços, banco e integrações.
Logs sem correlação dificultam investigação.

## Problema

Definir padrão de logging útil, seguro e pesquisável.

## Decisão

Usar logs estruturados e correlation ID por requisição/operação.
Reutilizar ID recebido apenas quando válido segundo política; caso
contrário gerar novo. Propagar o identificador para integrações quando
seguro e suportado.

## Alternativas consideradas

- Logs livres apenas em texto --- rejeitados como padrão de produção.
- Registrar payload completo indiscriminadamente --- proibido.
- Sem correlation ID --- rejeitado.

## Consequências positivas

- Busca e diagnóstico eficientes.
- Relação entre eventos de uma mesma operação.
- Integração futura com plataformas de observabilidade.

## Consequências negativas

- Maior volume de logs.
- Necessidade de mascaramento e política de retenção.

## Regras obrigatórias

- Não registrar senhas, tokens ou chaves.
- Minimizar PII.
- Definir níveis DEBUG/INFO/WARNING/ERROR/CRITICAL.
- Produção não deve operar permanentemente em DEBUG.
- Correlation ID deve aparecer nos erros e logs relevantes.
- Logs de auditoria de negócio seguem regras próprias e não podem
    depender somente do log técnico.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Adoção de OpenTelemetry/tracing distribuído.
- Nova plataforma central de logs.
- Requisitos legais de retenção.
- Microserviços.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
