# ADR-003 --- Persistência e SQLAlchemy

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A baseline possui múltiplos schemas e integridade já certificada. A
camada de aplicação deve mapear esse banco sem recriá-lo ou enfraquecer
suas constraints.

## Problema

Definir como endpoints, regras de negócio, transações e acesso SQL serão
separados.

## Decisão

Adotar SQLAlchemy 2.x como camada principal de persistência, com sessões
de ciclo de vida controlado. O fluxo padrão será Endpoint → Service →
Repository/Persistence → PostgreSQL. SQL explícito será permitido quando
houver justificativa técnica.

## Alternativas consideradas

- SQL direto em toda aplicação --- rejeitado pela duplicação e
    manutenção.
- Active Record acoplado ao domínio --- rejeitado por misturar
    persistência e regra de negócio.
- ORM com criação automática de schema --- rejeitado por ameaçar a
    baseline certificada.

## Consequências positivas

- Separação entre regra e persistência.
- Testabilidade.
- Controle transacional.
- Mapeamento gradual do banco existente.
- Permite SQL especializado quando necessário.

## Consequências negativas

- Camada adicional de abstração.
- Risco de consultas ineficientes se o ORM for mal utilizado.
- Mapeamento de estruturas legadas pode exigir configuração explícita.

## Regras obrigatórias

- Não usar create_all() como implantação.
- Sessões não podem ficar globais e mutáveis.
- Commit/rollback devem ocorrer em limites transacionais definidos.
- Repositories não devem conter regras de negócio.
- Consultas críticas devem ser observáveis e testadas.
- Constraints do PostgreSQL permanecem autoridade de integridade.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Problemas de desempenho recorrentes causados pela abstração.
- Mudança relevante no modelo de persistência.
- Adoção de CQRS/event sourcing por necessidade comprovada.
- Separação de um módulo para serviço independente.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
