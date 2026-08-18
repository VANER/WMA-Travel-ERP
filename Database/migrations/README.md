# Histórico de migrations

Este diretório recebe toda alteração estrutural criada após a baseline certificada no commit `d63800e`.

## Situação da Fase 1

As alterações históricas anteriores à certificação estão incorporadas ao dump
`Database/scripts/WmaTravelERP.sql`. Parte dos scripts originais não foi preservada no repositório; essa lacuna
é registrada explicitamente e não deve ser ocultada por migrations reconstruídas com identidade retroativa.

| Identificação histórica | Situação do script | Estado incorporado ao dump |
| --- | --- | --- |
| 01 — normalização 3FN de endereços | Original não preservado neste diretório | Sim |
| 02 — consolidação `financeiro.*` → `public.*` | Formalmente deferida | Não aplicável |
| 03 — colunas de auditoria em `financeiro.*` | Original não preservado neste diretório | Sim |
| 04 — PKs em `auditoria.*` | Original não preservado neste diretório | Sim |
| 05 — triggers de auditoria | Original não preservado neste diretório | Sim |

Os scripts `Database/scripts/F1_FIN/` compõem uma evolução controlada posterior à baseline e permanecem
separados até a emissão da baseline consolidada da Fase 1.

## Regra para novas migrations

Cada arquivo novo deve conter:

- identificador único e ordem de execução;
- objetivo, justificativa e objetos afetados;
- pré-condições e análise de dependências;
- transação quando tecnicamente possível;
- validações pré e pós-aplicação;
- estratégia de rollback ou justificativa para sua impossibilidade;
- referência à evidência de execução e certificação.

Não modifique uma migration já aplicada. Crie uma nova migration corretiva.
