# Auditoria do Gate da Etapa 2.7

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Tipo:** Auditoria documental
> **Status:** GATE DOCUMENTAL APROVADO; IMPLEMENTAÇÃO AUTORIZADA

## 1. Fontes primárias e escopo

- [Gate de transição](certification/PHASE_2_6_TO_2_7_TRANSITION_GATE.md).
- [Gate documental](BIKE_TOUR_DOCUMENTATION_GATE.md).

BT-DOC-01 foi aceito por Vaner em 10/09/2026, no commit `f94f421`; A1 está fechado.
Os sete entregáveis BT-DOC-02 a BT-DOC-08 foram aprovados e aceitos por Vaner em 11/09/2026.
A revisão posterior corrigiu inconsistências de redação, preservando as decisões ainda pendentes.
A existência dos arquivos não equivale a aceite.
A auditoria registra achados; não aprova regras, contratos, modelagem ou implementação.

## 2. Matriz de requisitos

| REQUISITO | STATUS ATUAL | EVIDÊNCIA | BLOQUEADOR? | AÇÃO NECESSÁRIA |
| --- | --- | --- | --- | --- |
| Etapas 2.0 a 2.6 e fechamento PR #60 | Integração registrada | Gate de transição, §1 | HISTÓRICO | Preservar marcos |
| Regressão integrada da main | PASS em `5856477` | Gate de transição, §5 | ATUALIZAÇÃO DOCUMENTAL | Checkbox conciliado com evidência do PR #65 |
| Proteção da main | Três checks obrigatórios observados | Seção 3 abaixo | ATUALIZAÇÃO DOCUMENTAL | Manter rastreabilidade da consulta |
| SMTP e tratamento do histórico | PASS no ambiente local | Registro SMTP, §4 e §6 | ATUALIZAÇÃO DOCUMENTAL | Checkbox conciliado com atestação existente |
| SMTP em produção | Produção inexistente | Registro SMTP, §6.2 | NÃO APLICÁVEL | Validar antes da futura implantação |
| Falhas antigas de regressão | Resultados históricos | Gate de transição, §2 | HISTÓRICO | Não confundir com CI posterior |
| Próxima etapa no AGENTS | Instruções alinhadas em 11/09/2026 | AGENTS.md; gate documental, §3 | ATUALIZAÇÃO DOCUMENTAL | Divergência anterior resolvida |
| BT-DOC-01: inventário | PASS; A1 fechado | [Aceite formal](BIKE_TOUR_INVENTORY.md#9-aceite-formal) | HISTÓRICO | Preservar versão aceita em f94f421 |
| BT-DOC-02: mapa funcional | APROVADO E ACEITO | [Matriz funcional](BIKE_TOUR_FUNCTIONAL_MATRIX.md) | ENCERRADO | A2 |
| BT-DOC-03: rastreabilidade | APROVADO E ACEITO | [Rastreabilidade](BIKE_TOUR_TRACEABILITY_MATRIX.md) | ENCERRADO | A3 |
| BT-DOC-04: fronteiras e integrações | APROVADO E ACEITO | [Fronteiras](BIKE_TOUR_DOMAIN_BOUNDARIES.md) | ENCERRADO | A4 |
| BT-DOC-05: regras transacionais | APROVADO E ACEITO | [Transações](BIKE_TOUR_TRANSACTION_POLICY.md) | ENCERRADO | A5 |
| BT-DOC-06: segurança e privacidade | APROVADO E ACEITO | [Segurança](BIKE_TOUR_SECURITY_PRIVACY.md) | ENCERRADO | A6 |
| BT-DOC-07: testes e aceite | APROVADO E ACEITO | [Testes](BIKE_TOUR_TEST_PLAN.md) | ENCERRADO | A7 |
| BT-DOC-08: delta de banco | APROVADO E ACEITO | [Schema](BIKE_TOUR_SCHEMA_DECISION.md) | ENCERRADO | A8 |
| Autoridades sem duplicação | APROVADO | Gate documental, §6; BT-DOC-04/08 | ENCERRADO | A4 e A8 |
| API, erros HTTP e RBAC | APROVADO | Gate documental, §6; BT-DOC-03/06/07 | ENCERRADO | A3, A6 e A7 |
| Aceites rastreáveis dos oito documentos | 8 de 8 registrados | Gate documental, §5 e §6 | ENCERRADO | Vaner, 11/09/2026 |
| Código, endpoints e migrations Bike Tour | Ainda não implementados | Gate documental, §1 e §4 | NÃO APLICÁVEL | Somente após aprovação do gate |
| Frontend, aplicativo, scheduler e site | Fora da abertura | Gate documental, §4 | NÃO APLICÁVEL | Manter fora do escopo |

## 3. Evidência consultada

O adendo do gate de transição referencia o PR #65 e os três CIs pós-merge, consultados em 09/09/2026,
no SHA `5856477a13d1919627197c775fdcfe3b693d5605`. O HEAD local é `74685c6`; os históricos divergem,
mas o conteúdo versionado dos commits é igual segundo `git diff HEAD origin/main`.
Os documentos locais de Bike Tour não estão cobertos por esses CIs.

A consulta à [regra 22152693](https://github.com/VANER/WMA-Travel-ERP/rules/22152693) mostrou estado ativo,
sem bypass, com política estrita e checks `Python 3.13`, `Markdown e ortografia` e `Secret scan`.
Não houve mutação da regra nesta auditoria.

O [registro SMTP](SECURITY_INCIDENT_SMTP_CLOSURE.md) identifica Vaner, data e alcance local da atestação.
A auditoria não repetiu login ou envio. A ausência de produção impede atribuir validação a esse ambiente futuro.
A publicação pendente na auditoria anterior é um registro histórico, distinto da integração observada do PR #65.

## 4. Evidência necessária para transformar bloqueadores em PASS

### A1 — Inventário

**PASS — fechado em 10/09/2026.** Vaner aceitou explicitamente o inventário do commit `f94f421`.
A evidência está na [seção 9 do inventário](BIKE_TOUR_INVENTORY.md#9-aceite-formal).
O aceite do levantamento não aprova as decisões de domínio, contratos ou modelagem atribuídas a A2–A8.

### A2 — Mapa funcional

Aprovar regras por requisito, precondições, resultados, transições, exceções e critérios de aceite.
A versão 1.1 especifica estados e transições. A identidade foi confirmada por Vaner: um evento por saída,
inscrição vinculada ao passageiro da reserva. O aceite do restante de A2 permanece pendente.

### A3 — Rastreabilidade e API

Completar requisito → dado → serviço → contrato → teste para cada requisito aprovado.
A versão 1.1 especifica métodos, entradas, saídas, erros HTTP e permissões por operação, com cenários T01–T25.
Revisar e aceitar esses contratos documentais; não há endpoints implementados nesta auditoria.

### A4 — Fronteiras e integrações

Decidir e aprovar identidades e cardinalidades de evento, saída, inscrição, reserva e participante.
Concluir contratos com Core, Turismo, Comercial e Financeiro: proprietário, referências, precondições,
resultado e falhas. Separar contratos existentes dos ainda necessários. Resolver a correlação com A8
sem duplicar cadastro, reserva, vaga ou fatos comerciais e financeiros.

### A5 — Transações

Aprovar capacidade por intervalo, exclusividade entre eventos, ordem de bloqueio, atomicidade, rollback,
idempotência, retenção de chaves, expiração, cancelamento, reacomodação e compensação de falhas parciais.
Definir responsável pela expiração e sua auditoria; resolver remissões a segurança e decisão de banco.
A redação foi corrigida para situar a decisão documental antes do gate; seu aceite continua pendente.

### A6 — Segurança e privacidade

Concluir e aprovar permissões por operação e escopo, dados mínimos, finalidade e retenção por categoria,
incluindo idempotência, auditoria e anonimização. Princípios gerais e nomes de permissões não comprovam aceite.

### A7 — Testes e critérios de aceite

Aprovar plano rastreável com resultados esperados: último recurso, mesma bicicleta simultânea, repetição,
rollback completo, referência ausente, estado inválido, RBAC por endpoint e falha de integração.
Identificar ambientes, gates de qualidade e evidências de certificação.
A sequência documental foi corrigida: aprovação do plano na entrada; testes executáveis na entrega futura.
Esta auditoria registra o fechamento documental; os gates executáveis permanecem vinculados à implementação.

### A8 — Decisão de schema

Concluir decisão rastreável de ausência de delta ou proposta aditiva justificada, com ADR aplicável.
Definir objetos, relações, constraints, índices, dependências, impactos, validação e estratégia de reversão.
A versão 1.1 propõe schema public, cardinalidades e restrições concretas. Aprovar a decisão com a fronteira de domínio,
sem criar migrations. Prova executável da migration pertence à implementação posteriormente autorizada.

Todos os aceites exigem responsável, data e evidência da versão revisada, conforme o gate primário.

## 5. Correções e limites da auditoria

Foi acrescentado adendo de evidências ao gate de transição, sem reescrever resultados históricos.
No gate documental, foi registrada a divergência entre AGENTS fornecido e local e incluída rastreabilidade.
Foram conciliados apenas os checkboxes de regressão integrada e registro SMTP.
O aceite posterior de BT-DOC-01 fecha somente A1. A2–A8 permanecem pendentes.

A revisão automática rejeitou uma tentativa de conciliação de status por considerar a comprovação insuficiente.
Após apresentação das evidências, Vaner autorizou explicitamente a conciliação desses dois checkboxes.
A atualização é documental e não representa aprovação funcional da etapa 2.7.

A revisão para integração inclui somente documentação. Aprovações funcionais continuam pendentes.

## 6. Revisão consolidada de 11/09/2026

A2–A8 foram detalhados em versão 1.1: regras, contratos HTTP, portas de integração, transações, retenção,
cenários T01–T25 e plano aditivo de dados. A ADR-020 explicita alternativas e impactos. Nenhum aceite foi inferido.
A relação um evento por saída e inscrição por passageiro da reserva foi confirmada por Vaner em 10/09/2026.

Decisões propostas que precisam de revisão do responsável:

- bloqueio de 15 minutos, capacidade máxima de 1000 e apoio obrigatório para abrir evento;
- alocação individual e execução serial inicial das mutações, com exclusão temporal PostgreSQL;
- contratos públicos novos para dados de origem, sem reutilizar services que fazem commit como subtransação;
- reconciliação explícita e pendência operacional, sem cancelamento financeiro automático;
- prazos operacionais de retenção e ausência de texto livre/dados clínicos em ocorrência;
- delta de tabelas em public e dependência de btree_gist, ainda não executados.

As pendências de A2–A8 agora incluem revisão e aceite das soluções propostas. Testes funcionais e prova da migration
são gates da implementação posterior; não foram declarados executados nem usados para aprovar estes documentos.

## 7. Conclusão

**ETAPA 2.7 = BLOQUEADA.**

Os sete entregáveis restantes e os critérios transversais de autoridade, contratos e delta de banco carecem de aceite.
