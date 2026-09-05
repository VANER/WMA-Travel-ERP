# Plano de Testes de Turismo

> **Etapa:** 2.6.7 — Plano de Testes (`TUR-DOC-07`)
> **Data:** 05/09/2026
> **Status:** APROVADO

## 1. Estratégia

A certificação exige testes unitários de schemas, repositories, services e routers; snapshot OpenAPI; gates
estáticos da migration; regressão integral; e integração PostgreSQL com upgrade, downgrade e concorrência real.

## 2. Matriz mínima

| Área | Evidência |
| --- | --- |
| validação | período, capacidade, quantidade e chaves inválidas rejeitados |
| disponibilidade | saldo explica bloqueios válidos e reservas confirmadas |
| concorrência | duas transações disputando a última vaga produzem um vencedor |
| idempotência | repetição retorna o mesmo resultado sem nova ocupação |
| expiração | bloqueio vencido não confirma e é liberado uma vez |
| cancelamento | transição libera alocação elegível uma única vez |
| autorização | leitura, operação e gestão exigem permissões distintas |
| migration | head linear e ciclo upgrade/downgrade/upgrade aprovado |
| regressão | Ruff, mypy strict, pytest com 100% e OpenAPI sincronizado |

## 3. Ambientes

Testes destrutivos usam exclusivamente PostgreSQL local descartável com banco terminado em `_test`. Ausência da
URL opt-in deve ser relatada como pendência, nunca convertida em sucesso.

## 4. Critério de aceite

Nenhuma falha, warning tratado como erro, regressão de contrato ou head paralelo. A cobertura exigida permanece
100%. Os seis testes de integração preexistentes devem continuar aprovados, acrescidos da evidência de Turismo.

## 5. Conclusão

O `TUR-DOC-07` está aprovado. A próxima entrega é `TUR-DOC-08` — Decisão de schema.
