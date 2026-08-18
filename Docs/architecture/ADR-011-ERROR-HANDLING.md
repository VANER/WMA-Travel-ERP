# ADR-011 --- Tratamento de Erros e Exceções

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

APIs e serviços precisam apresentar comportamento consistente diante de
validação, conflito, indisponibilidade e erros internos.

## Problema

Evitar respostas ad hoc, vazamento de stack traces e tratamento
inconsistente entre módulos.

## Decisão

Adotar hierarquia de exceções da aplicação e handlers centrais FastAPI.
Respostas de erro terão código estável, mensagem segura, detalhes
permitidos e correlation ID quando disponível.

## Alternativas consideradas

- try/except em cada endpoint --- rejeitado como padrão.
- Retornar HTTP 200 com erro no corpo --- rejeitado.
- Expor exceção interna/SQL ao cliente --- proibido.

## Consequências positivas

- Contrato consistente.
- Melhor suporte e observabilidade.
- Menor vazamento de detalhes internos.
- Mapeamento previsível para status HTTP.

## Consequências negativas

- Exige catálogo e disciplina de códigos.
- Erros de integrações precisam ser traduzidos adequadamente.

## Regras obrigatórias

- Nunca retornar stack trace em produção.
- Erro de validação deve ser distinguível de erro interno.
- Conflitos de domínio devem ter status apropriado.
- Exceções inesperadas devem ser logadas com correlation ID.
- Mensagens não podem revelar secrets ou SQL sensível.
- Códigos públicos de erro devem permanecer estáveis dentro da versão
    da API.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Novo protocolo de API.
- Necessidade de internacionalização de mensagens.
- Adoção de padrão externo obrigatório como Problem Details em toda
    API.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
