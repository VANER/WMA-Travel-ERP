# ADR-018 — Modelo de Dados Comercial Integrado

**Status:** APROVADA PARA IMPLEMENTAÇÃO NA ETAPA 2.4

**Data:** 31/08/2026

## Contexto

O inventário 2.4.1 comprovou estruturas legadas para Lead, funil, Venda, Comissão e Contrato, mas não encontrou
identidades próprias para Oportunidade, Proposta, seus itens, Operadora ou Condição Comercial. Também não existe
rastreabilidade estrutural completa entre Lead, Cliente, Proposta, Venda, Reserva e Contrato.

## Decisão

- preservar e mapear as tabelas legadas sem recriá-las;
- criar `operadora` como papel único de `fornecedor`;
- criar `oportunidade` como agregado único originado de `lead`;
- criar `proposta`, `item_proposta` e `condicao_comercial` como estruturas transacionais normalizadas;
- relacionar Lead convertido a Cliente, Venda a Proposta e Contrato a Venda/Reserva por FKs opcionais;
- garantir uma única linha de Cliente por Pessoa após pré-validação de duplicidades;
- introduzir permissões `COMERCIAL_VISUALIZAR` e `COMERCIAL_GERENCIAR`;
- aplicar todas as evoluções por migration Alembic aditiva e reversível.

## Limites

Produto Turístico e Reserva continuam autoridades do módulo Turismo. Cliente e Fornecedor continuam autoridades
do Core Corporativo. O Comercial armazena apenas suas próprias identidades e referências por foreign key.

## Consequências

- o fluxo Comercial passa a possuir rastreabilidade referencial;
- dados duplicados de Cliente impedem a migration, em vez de serem resolvidos silenciosamente;
- vínculos opcionais preservam registros legados anteriores à aplicação;
- downgrade remove somente objetos e vínculos da Fase 2;
- API e regras de transição continuam responsáveis por validar estados de negócio.
