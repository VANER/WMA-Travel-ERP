# ADR-020 — Especialização Operacional de Bike Tour

**Status:** ACEITA

**Data:** 10/09/2026

## Contexto

O inventário BT-DOC-01 foi aceito no commit `f94f421`. Turismo mantém produto, saída, reserva e passageiro.
Vaner confirmou um evento por saída e inscrição vinculada a passageiro de reserva. A baseline não oferece
alocação exclusiva de bicicleta/guia/veículo por intervalo nem todos os contratos internos de consulta necessários.
O gate 2.7 exige decisão documental antes de models, migrations e endpoints.

## Decisão proposta

1. Especializar produto e saída com vínculos únicos, mantendo inscrição como vínculo operacional de passageiro.
2. Criar somente o delta `public` descrito em BT-DOC-08; preservar todos os marcos e migrations anteriores.
3. Obter referências por portas públicas dos proprietários; Bike Tour não consulta models/repositories privados.
4. Não chamar serviços existentes que fazem commit dentro da unidade atômica Bike Tour.
5. Proteger mutações por lock transacional consultivo inicial e exclusão temporal PostgreSQL com `btree_gist`.
6. Reconciliar cancelamentos de origem explicitamente; comandos críticos revalidam a elegibilidade turística.
7. Registrar pendências operacionais para tratamento Comercial/Financeiro, sem escrever títulos ou estornos.
8. Manter RBAC e auditoria vigentes; não coletar nome, CPF, documento ou texto clínico em Bike Tour.

## Alternativas

- Reserva/passageiro paralelos: rejeitados na proposta por duplicação de autoridade.
- Acesso direto a tabelas estrangeiras pelo service consumidor: rejeitado por violar fronteiras.
- Reutilizar confirmação turística com commit como subtransação: rejeitado, pois não fornece atomicidade composta.
- Contador sem exclusão temporal: rejeitado, pois não protege o mesmo recurso em eventos distintos.
- Lock somente em memória: rejeitado, pois múltiplas instâncias não compartilham a proteção.
- Outbox e automação financeira nesta entrega: adiadas; pendência operacional recuperável preserva o escopo.
- Locks granulares desde a primeira versão: possível evolução, mas exigem desenho adicional para limpeza entre eventos.

## Consequências

O desenho preserva o catálogo CICLOTURISMO e as autoridades comuns. O delta adiciona tabelas operacionais,
portas de consulta, uma extensão PostgreSQL e testes de integração/concorrência; nenhum deles está implementado.
A execução serial inicial limita a vazão de escrita e deve ser medida. Leitura não garante disponibilidade futura.
Cancelamento na origem não libera recurso instantaneamente: reconciliação explícita ou comando subsequente trata o vínculo.
O consumidor financeiro deve tratar a pendência fora do comando Bike Tour, com referência auditável.

## Critérios de reavaliação

- Volume que torne inadequada a execução serial de comandos.
- Exigência de transferência entre saídas, eventos múltiplos por saída ou inscrição independente.
- Integração automática com pagamento, necessidade de transação distribuída ou scheduler.
- Necessidade de dados sensíveis, autoatendimento ou segregação de acesso por evento/filial.
- Provedor PostgreSQL sem disponibilidade/permissão para a extensão proposta.

## Relações

- [Gate documental](../BIKE_TOUR_DOCUMENTATION_GATE.md).
- [Fronteiras](../BIKE_TOUR_DOMAIN_BOUNDARIES.md).
- [Transações](../BIKE_TOUR_TRANSACTION_POLICY.md).
- [Decisão de dados](../BIKE_TOUR_SCHEMA_DECISION.md).
- ADR-014 — Limites Transacionais entre Módulos.
- ADR-019 — Modelo Transacional de Turismo.

ADR aceita por Vaner em 11/09/2026, em conjunto com A4, A5 e A8, após auditoria semântica do desenho.

<!-- cspell:ignore btree gist -->
