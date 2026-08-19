# ADR-007 --- Segurança, Autenticação e Autorização

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

O ERP manipulará dados corporativos, clientes, reservas, finanças e
informações fiscais. Segurança precisa ser transversal.

## Problema

Definir princípios mínimos antes de implementar autenticação e
integrações.

## Decisão

Adotar autenticação central, autorização por papéis/permissões, hash de
senha com algoritmo moderno suportado, princípio do menor privilégio,
validação de entrada, HTTPS e auditoria de ações sensíveis. O mecanismo
exato de token/sessão será detalhado na etapa 2.2 sem contrariar esta
ADR.

## Alternativas consideradas

- Autorização apenas no frontend --- proibida.
- Credenciais compartilhadas --- rejeitadas.
- Acesso direto de integrações ao banco --- proibido.

## Consequências positivas

- Controles consistentes.
- Menor superfície de ataque.
- Rastreabilidade.
- Base adequada para LGPD e segregação de funções.

## Consequências negativas

- Maior esforço de implementação e testes.
- Gestão de permissões requer governança contínua.

## Regras obrigatórias

- Nunca armazenar senha em texto claro.
- Autorização deve ocorrer no backend.
- Endpoints privados negam acesso por padrão.
- Privilégios devem ser mínimos.
- Ações sensíveis devem ser auditáveis.
- Tokens/secrets não devem aparecer em logs.
- Dependências críticas de segurança devem ser monitoradas.
- Integrações usam credenciais próprias.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Mudança de requisitos regulatórios.
- SSO/OIDC corporativo.
- MFA obrigatório.
- Novos canais públicos com risco elevado.
- Mudança significativa de modelo de identidade.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
