# ADR-006 --- Configuração, Ambientes e Secrets

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

A aplicação terá configurações distintas para desenvolvimento, teste e
produção, incluindo credenciais de banco e integrações.

## Problema

Evitar secrets no código/repositório e tornar configuração reproduzível.

## Decisão

Usar configuração baseada em variáveis de ambiente, validada por
Settings/Pydantic. Versionar somente .env.example sem valores sensíveis.
O .env real será ignorado pelo Git.

## Alternativas consideradas

- Configuração hardcoded --- rejeitada.
- Versionar .env real --- proibido.
- Arquivos diferentes com secrets dentro do repositório ---
    rejeitados.

## Consequências positivas

- Separação entre código e ambiente.
- Menor risco de vazamento.
- Deploy reproduzível.
- Validação antecipada de configuração obrigatória.

## Consequências negativas

- Gestão de secrets em produção exige ferramenta/processo externo.
- Erros de ambiente podem impedir inicialização, intencionalmente.

## Regras obrigatórias

- Nunca versionar senhas, tokens, chaves privadas ou connection
    strings reais.
- Manter .env.example atualizado.
- Falhar cedo quando configuração obrigatória estiver ausente.
- Logs não podem imprimir secrets.
- Credenciais devem ter menor privilégio necessário.
- Produção deve usar mecanismo seguro de secrets compatível com a
    infraestrutura escolhida.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Adoção de orquestrador/cloud com secret manager específico.
- Necessidade de rotação automática.
- Mudança significativa no modelo de ambientes.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
