# ADR-005 --- Padrões de API

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

O ERP terá clientes internos, integração com wmatravel.com.br e futuras
integrações externas. O contrato HTTP precisa ser previsível.

## Problema

Definir versionamento, formatos, erros, paginação e documentação da API.

## Decisão

Adotar REST/JSON sobre HTTPS, prefixo funcional /api/v1 e OpenAPI como
contrato documentado. /health permanece endpoint técnico não versionado
e /api/v1/health pode representar saúde da API.

## Alternativas consideradas

- GraphQL como padrão principal --- adiado por não ser necessário no
    início.
- RPC proprietário --- rejeitado para integrações web públicas.
- API sem versionamento --- rejeitada por dificultar evolução
    compatível.

## Consequências positivas

- Contrato simples e amplamente suportado.
- Integração natural com WordPress/WooCommerce.
- Documentação automática.
- Versionamento explícito.
- Testabilidade com HTTPX.

## Consequências negativas

- REST pode exigir múltiplas chamadas em alguns cenários.
- Versionamento demanda política de depreciação.
- OpenAPI precisa ser mantida coerente com implementação.

## Regras obrigatórias

- JSON como formato padrão.
- HTTPS obrigatório fora de desenvolvimento local.
- Status HTTP semânticos.
- Schemas de request/response explícitos.
- Paginação para coleções potencialmente grandes.
- Filtros e ordenação com parâmetros documentados.
- Erros seguem ADR-011.
- Breaking change exige nova versão ou estratégia compatível.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Necessidade comprovada de GraphQL.
- Integração B2B exigir protocolo específico.
- Mudança substancial no padrão de clientes.
- Necessidade de streaming ou comunicação em tempo real como padrão
    dominante.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
