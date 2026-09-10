# Autorização de Implementação — Etapa 2.7 Bike Tour

> Projeto: WMA Travel ERP
> Data: 10/09/2026
> Responsável: Vaner
> Status: APROVADO PARA IMPLEMENTAÇÃO

## Decisão

Fica aprovado o gate documental da Etapa 2.7 — Bike Tour e autorizada a implementação funcional completa do módulo, preservando as fronteiras já definidas entre Core, Turismo, Comercial, Financeiro e Auditoria.

A aprovação atende à solicitação explícita do responsável pelo projeto para verificar e resolver as pendências necessárias ao início da implementação completa da Etapa 2.7.

## Entregáveis aprovados

| ID | Documento | Versão | Resultado |
| --- | --- | --- | --- |
| BT-DOC-01 | `Docs/BIKE_TOUR_INVENTORY.md` | 1.0 | APROVADO |
| BT-DOC-02 | `Docs/BIKE_TOUR_FUNCTIONAL_MATRIX.md` | 1.0 | APROVADO |
| BT-DOC-03 | `Docs/BIKE_TOUR_TRACEABILITY_MATRIX.md` | 1.0 | APROVADO |
| BT-DOC-04 | `Docs/BIKE_TOUR_DOMAIN_BOUNDARIES.md` | 1.0 | APROVADO |
| BT-DOC-05 | `Docs/BIKE_TOUR_TRANSACTION_POLICY.md` | 1.0 | APROVADO |
| BT-DOC-06 | `Docs/BIKE_TOUR_SECURITY_PRIVACY.md` | 1.0 | APROVADO |
| BT-DOC-07 | `Docs/BIKE_TOUR_TEST_PLAN.md` | 1.0 | APROVADO |
| BT-DOC-08 | `Docs/BIKE_TOUR_SCHEMA_DECISION.md` | 1.0 | APROVADO |

Os metadados `EM ELABORAÇÃO` nas versões 1.0 registram o estado anterior. Este registro constitui o aceite rastreável posterior dessas versões para o gate de entrada.

## Decisões consolidadas

1. Bike Tour especializa Turismo e não duplica produto, reserva, vaga, passageiro, venda, contrato ou fatos financeiros.
2. Evento, recurso, alocação, inscrição operacional, ponto de controle, ocorrência, equipe e logística específicos pertencem a Bike Tour.
3. A inscrição referencia a reserva de Turismo; não cria uma segunda reserva.
4. O participante referencia os cadastros existentes e mantém somente atributos operacionais próprios da modalidade.
5. Recursos exclusivos são controlados por intervalo, com proteção transacional e idempotência.
6. A evolução de banco é somente aditiva; baseline, tags e migrations históricas permanecem imutáveis.
7. Os novos objetos permanecem no schema `public`, seguindo a baseline atual, salvo ADR posterior antes do merge funcional.
8. A API é versionada sob `/api/v1/biketour`, com autenticação e permissões do domínio.
9. Operações repetíveis são idempotentes; concorrência pelo último recurso deve produzir um único vencedor.
10. Integrações usam interfaces públicas e correlação, sem escrita direta em domínio alheio.

## Condições para o merge funcional

- migration aditiva com head único e ciclo de upgrade, downgrade e novo upgrade aprovado;
- models, schemas, repositories, services e API coerentes com BT-DOC-01 a BT-DOC-08;
- OpenAPI sincronizado;
- testes unitários, integração PostgreSQL, API, permissões, idempotência, concorrência, rollback e regressão;
- disputa simultânea pelo último recurso com um único vencedor;
- repetição de confirmação e cancelamento sem efeito duplicado;
- Ruff, Ruff Format, mypy strict, pytest e cobertura, Markdownlint, CSpell, secret scan e `git diff --check` aprovados;
- nenhuma alteração retroativa em artefatos certificados ou migrations integradas;
- documentação e certificação da Etapa 2.7 atualizadas no fechamento.

## Resultado

**GATE 2.6 -> 2.7: PASS.**

**ETAPA 2.7: AUTORIZADA PARA IMPLEMENTAÇÃO FUNCIONAL COMPLETA.**

A próxima execução autorizada é integrar este registro à `main` e então criar a branch funcional da Etapa 2.7.
