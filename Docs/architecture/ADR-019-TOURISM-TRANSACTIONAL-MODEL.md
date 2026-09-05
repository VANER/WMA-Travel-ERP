# ADR-019 — Modelo Transacional de Turismo

<!-- cspell:words alocacao correlacao -->

**Status:** APROVADA PARA IMPLEMENTAÇÃO NA ETAPA 2.6

**Data:** 05/09/2026

## Contexto

A baseline certificada contém catálogo, pacote, roteiro, reserva, passageiro e estruturas operacionais, mas
concentra período e capacidade em `pacote_viagem`. Não existe identidade de saída, razão de vagas nem correlação
idempotente entre Comercial e Turismo.

## Decisão

- preservar e mapear as 13 tabelas legadas sem recriá-las;
- criar `saida_turistica` como execução datada e versionada de um pacote;
- criar `alocacao_vaga` como razão de bloqueios, confirmações, liberações e expirações;
- criar `reserva_correlacao` para referências idempotentes de venda, item e contrato;
- adicionar `id_destino` opcional ao produto e `id_saida` opcional à reserva para preservar dados legados;
- controlar concorrência sob bloqueio transacional da saída;
- introduzir permissões separadas de visualização, operação e gestão;
- aplicar todas as mudanças por migration Alembic aditiva e reversível.

## Limites

Cliente, fornecedor e localidade continuam no Core. Venda e contrato continuam no Comercial. Fatos monetários
continuam no Financeiro. Bike Tour permanece fora da Etapa 2.6. A migration não altera dumps, migrations ou
certificações anteriores.

## Consequências

- pacote e saída passam a representar conceitos distintos;
- toda ocupação é explicável por uma alocação;
- conflitos pela última vaga são resolvidos dentro da transação de Turismo;
- registros legados continuam válidos com vínculos novos opcionais;
- downgrade remove somente objetos e colunas introduzidos na Etapa 2.6.
