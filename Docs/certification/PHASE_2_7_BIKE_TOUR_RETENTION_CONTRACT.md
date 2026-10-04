# Certificação do Contrato de Retenção — Bike Tour

> **Projeto:** WMA Travel ERP
> **Fase:** 2.7 — Bike Tour
> **Gate:** B06-F4
> **Status:** CONTRATO FECHADO; CONTROLE FÍSICO AINDA ABERTO
> **Data:** 27/09/2026

## 1. Objetivo

Consolidar o contrato administrativo de retenção exigido pelo T23 antes da
definição e implementação do mecanismo físico.

Este gate é exclusivamente documental. Não certifica migration, endpoint,
execução PostgreSQL ou mecanismo administrativo implementado.

## 2. Fontes normativas

A decisão consolida:

- `BIKE_TOUR_SECURITY_PRIVACY.md`;
- `BIKE_TOUR_TRANSACTION_POLICY.md`;
- `BIKE_TOUR_TEST_PLAN.md`;
- `BIKE_TOUR_SCHEMA_DECISION.md`;
- `BIKE_TOUR_FUNCTIONAL_MATRIX.md`;
- `BIKE_TOUR_TRACEABILITY_MATRIX.md`;
- `BIKE_TOUR_DOCUMENTATION_GATE.md`.

## 3. Decisão

`RETENTION_MODEL=REVIEW_AND_COMPACTION`

`AUTOMATIC_PURGE=NO`

A retenção da Etapa 2.7 é uma revisão administrativa controlada. O vencimento
do prazo não representa autorização automática para exclusão física.

## 4. Idempotência — 90 dias

O resultado idempotente permanece reproduzível por pelo menos 90 dias após a
operação.

Após esse período, informação elegível pode ser compactada, preservando
tombstone suficiente para impedir que uma chave conhecida seja reinterpretada
como comando novo.

`PHYSICAL_DELETE_OPERACAO_BIKE_TOUR=NO`

A linha de operação também pode participar da integridade referencial de
pendências Bike Tour.

## 5. Revisão — 365 dias

Chave/hash e vínculos operacionais ligados a evento são revisados 365 dias após
encerramento ou cancelamento terminal.

Operação técnica ou administrativa sem evento terminal identificável usa
`created_at` da própria operação como marco.

A trilha técnica nova do módulo também é submetida a revisão após 365 dias.

## 6. Hold e extensão

Pendência Bike Tour `ABERTA` constitui hold para os registros necessários ao
tratamento.

Preservação expressa também constitui hold.

Retenção adicional exige motivo e nova data.

## 7. Fronteiras

Auditoria corporativa compartilhada é preservada.

Dados sob autoridade de Turismo, Comercial e Financeiro são preservados e não
têm sua política de retenção alterada pelo Bike Tour.

## 8. Autorização

A futura execução administrativa exige:

`BIKE_TOUR_GERENCIAR`

Essa permissão não implica `BIKE_TOUR_OPERAR`.

Não é criada nova permissão neste contrato.

## 9. Execução administrativa futura

A ação futura deve ser:

- explícita;
- manual;
- transacional;
- auditada;
- limitada ao Bike Tour;
- repetível com segurança;
- sem sucesso parcial silencioso.

A evidência administrativa deve registrar ator, `correlation_id`, instante UTC,
período avaliado, motivo, quantidade elegível, processada, preservada e
impedimentos.

Não existe scheduler ou purge automático na Etapa 2.7.

## 10. T23

O T23 permanece aberto até existir implementação e prova física de que:

- prazos são respeitados;
- holds são respeitados;
- tombstones permanecem seguros;
- auditoria compartilhada permanece intacta;
- outros domínios permanecem intactos;
- rollback e autorização funcionam.

## 11. B07

A certificação física final B07 permanece adiada até a decisão física do B06.

Se B06-F5 exigir migration, a evidência física deverá considerar o novo delta
antes do fechamento final.

## 12. Itens reservados ao B06-F5

Este documento não define:

- nome de nova tabela;
- nome de nova coluna;
- migration;
- endpoint;
- payload;
- armazenamento físico de hold;
- armazenamento físico de extensão;
- SQL de compactação.

Esses elementos dependem do desenho físico mínimo do próximo gate.

## 13. Resultado

`B06_CONTRACT_DECISION=APPROVED`

`B06_RETENTION_CONTRACT=CLOSED`

`B06_RETENTION_CONTROL=OPEN`

`T23=PASS`

`B07=DEFERRED_UNTIL_B06_PHYSICAL_DECISION`

Nenhuma implementação física é certificada por este gate.
