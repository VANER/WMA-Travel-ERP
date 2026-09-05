# Decisão de Schema de Turismo

<!-- cspell:words alocacao correlacao -->

> **Etapa:** 2.6.8 — Decisão de Schema (`TUR-DOC-08`)
> **Data:** 05/09/2026
> **Status:** APROVADO

## 1. Decisão

Conforme a ADR-019, as 13 tabelas legadas permanecem em `public`. A migration `202609050100` é aditiva e cria:

- `saida_turistica`, para execução datada e capacidade versionada;
- `alocacao_vaga`, para razão transacional de bloqueio e ocupação;
- `reserva_correlacao`, para referências idempotentes de Comercial;
- `produto_turistico.id_destino`, vínculo opcional com o destino estruturado;
- `reserva.id_saida`, vínculo opcional com a saída operacional;
- permissões `TURISMO_VISUALIZAR`, `TURISMO_OPERAR` e `TURISMO_GERENCIAR`.

## 2. Compatibilidade

As colunas são opcionais para preservar registros legados. Nenhum objeto certificado é removido, renomeado ou
reescrito. O downgrade remove somente objetos da 2.6. O head anterior permanece `202609030100` e o novo head linear
é `202609050100`.

## 3. Integridade

PKs, FKs, unicidades, checks de status, período, capacidade e quantidade são explícitos. As novas tabelas recebem
colunas comuns, comentários e triggers de atualização e auditoria. A capacidade é protegida por bloqueio da saída
na unidade transacional de reserva.

## 4. Conclusão

O `TUR-DOC-08` está aprovado. O gate documental está completo e autoriza a implementação e certificação da Etapa
2.6 conforme a ADR-019.
