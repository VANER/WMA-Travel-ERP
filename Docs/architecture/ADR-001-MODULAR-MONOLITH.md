# ADR-001 --- Monólito Modular

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A Fase 2 transforma a baseline de dados certificada em uma aplicação
operacional com Core, Comercial, Financeiro, Turismo, Bike Tour, Fiscal
e integrações. Esses domínios possuem forte relacionamento transacional,
mas precisam manter fronteiras claras.

## Problema

Escolher uma arquitetura que preserve separação de domínios sem
introduzir a complexidade operacional de sistemas distribuídos antes de
existir necessidade comprovada.

## Decisão

Adotar Monólito Modular como arquitetura inicial. Os módulos serão
implantados como uma única aplicação FastAPI, com fronteiras explícitas,
serviços próprios e dependências controladas. Microserviços poderão ser
considerados futuramente por ADR específica.

## Alternativas consideradas

- Monólito tradicional sem fronteiras --- rejeitado por elevar
    acoplamento.
- Microserviços desde o início --- rejeitado pelo custo operacional,
    transações distribuídas e complexidade desnecessária.
- Serverless por função --- rejeitado como arquitetura principal pela
    fragmentação do domínio e maior complexidade transacional.

## Consequências positivas

- Deploy inicial simples.
- Transações ACID entre módulos quando necessárias.
- Menor custo de infraestrutura e observabilidade.
- Facilidade de desenvolvimento, teste e depuração.
- Permite extração futura de módulos bem delimitados.

## Consequências negativas

- Escalabilidade independente por módulo é limitada.
- Disciplina arquitetural é necessária para evitar acoplamento.
- Falha da aplicação pode afetar vários módulos no mesmo processo.

## Regras obrigatórias

- Cada módulo deve possuir fronteira funcional explícita.
- Regra de negócio de um módulo não pode ser implementada diretamente
    por outro.
- Dependências circulares entre módulos são proibidas.
- Integração entre módulos deve ocorrer por serviços/interfaces
    internos definidos.
- Extração para microserviço exige nova ADR.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Necessidade comprovada de escala independente.
- Equipes independentes com ciclos de deploy distintos.
- Requisitos de disponibilidade ou isolamento incompatíveis com
    implantação única.
- Volume ou perfil de carga que justifique separação.
- Fronteiras de domínio maduras e mensuráveis.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
