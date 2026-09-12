# Plano de Testes e Certificação de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-07`)
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

Este documento é uma proposta revisável, não aprovação de A7 ou autorização de código.
O aceite de A1 permanece restrito ao inventário do commit `f94f421`.

## 1. Gates de entrada e entrega

Entrada: aceitar A2–A8 e ADR-020; não exigir código ou testes executáveis antes da autorização de implementação.
Entrega: implementar casos abaixo e anexar evidências reais, sem reutilizar aprovação da 2.6 como teste da 2.7.

| Gate de qualidade da entrega | Evidência exigida |
| --- | --- |
| Dependências | pip check aprovado |
| Ruff / Ruff Format | Todos os arquivos do backend verificados |
| Mypy strict | app, tests e scripts sem erros |
| Pytest e cobertura | Suíte completa com PostgreSQL; 100% de app, sem reduzir limite ou excluir linhas |
| PostgreSQL real | Testes de integridade, concorrência e rollback aprovados |
| Alembic | Head único, baseline restaurada, upgrade/downgrade/upgrade da nova revisão |
| OpenAPI | Snapshot sincronizado, operationIds únicos, códigos HTTP e compatibilidade verificados |
| Documentação | Markdownlint, CSpell dos documentos vivos e git diff --check |
| GitHub | Backend CI, Documentation CI e Secret Scan no PR e no SHA pós-merge |
| Certificação | Registro final com SHA, ambiente, comandos, resultados e pendências reais |

## 2. Casos rastreáveis e resultados esperados

| Caso | BT-REQ | Cenário e resultado verificável |
| --- | --- | --- |
| T01 | 001 | Produto sem origem/rota válida rejeitado; duplicação 409; origem CICLOTURISMO reutilizada |
| T02 | 002 | Um evento por saída; período incompatível 409; capacidade inválida 422; abrir sem líder/apoio 409 |
| T03 | 003 | Manutenção impede alocação; sobreposição entre eventos rejeitada; intervalos consecutivos permitidos |
| T04 | 004 | Primeiro bloqueio cria inscrição; rebloqueio elegível reutiliza a mesma inscrição e incrementa versão; validade limitada à origem e ao evento |
| T05 | 005 | Confirmar sem reserva CONFIRMADA ou com bloqueio vencido 409; confirmar não consome nova vaga turística |
| T06 | 006 | Sem correlação permitido; venda/contrato inexistente ou item incompatível rejeitado pela porta; sem segunda autoridade |
| T07 | 007 | Ponto de outro evento, passagem fora de ordem ou no futuro rejeitados; replay sem duplicação |
| T08 | 008 | Ocorrência sem evento 404; enum inválido 422; resolução sem motivo rejeitada |
| T09 | 009 | Apoio exige tipo e recurso compatíveis; substituição com falha preserva plano anterior |
| T10 | 010 | Guia alocado simultaneamente em dois eventos rejeitado; líder único; reatribuição mantém histórico |
| T11 | 011 | Passageiro de outra reserva/saída 409; cliente não é criado; acompanhante também exige passageiro |
| T12 | 012 | Presença distinta de confirmação; no-show auditado; fechamento sem resultados finais 409; avaliação única |
| T13 | 013 | Matriz de token, V/O/G e ADMIN; nenhuma resposta ou log expõe dado pessoal de origem |
| T14 | 014 | Transição tem ator/versão/correlação; falha no registro de auditoria reverte tudo |
| T15 | 003,004 | Duas conexões disputam última bicicleta: uma confirma e outra recebe 409, sem sobreposição |
| T16 | 004 | Expiração concorrente com confirmação: um resultado válido; sem recurso liberado e confirmado simultaneamente |
| T17 | 004,005 | Mesma chave simultânea retorna mesma resposta; payload divergente 409; nova chave respeita unicidade |
| T18 | 003,005 | Reacomodação falha após reservar destino: rollback mantém origem e remove destino parcial |
| T19 | 006,012 | Cancelamento turístico posterior impede operação; reconciliação libera recursos; indisponibilidade não cancela |
| T20 | 004,014 | Falha após inscrição, após alocação, após pendência e antes de resposta: zero registros parciais |
| T21 | 003,005 | SQL direto viola FK/check/exclusão temporal: banco rejeita; invariantes não dependem só do HTTP |
| T22 | 013 | Replay após revogação retorna 401/403; texto livre de ocorrência rejeitado com 422; chave nunca vira token ou PII |
| T23 | 013,014 | Limpeza respeita prazo e preservação expressa; não altera auditoria/objetos de outro domínio |
| T24 | Todos | Novo schema instala sobre baseline e reverte somente delta; extensão compartilhada preservada |
| T25 | Todos | Compatibilidade das rotas existentes, coleção OpenAPI, paginação, 401/403/404/409/422/503/500 por contrato |

## 3. Concorrência reproduzível

Usar duas sessões/conexões PostgreSQL independentes, sem SQLite e sem compartilhar Session entre threads.
Fixture cria evento com uma bicicleta restante; sincronização ocorre antes da aquisição dos locks do service.
Não colocar barreira depois do lock global, pois isso impediria a segunda transação de chegar à barreira.
Controlar primeira transação antes do commit para comprovar que a segunda aguarda; depois liberar e coletar resultados.
Assertar uma inscrição elegível/alocação ativa, segunda rejeitada e ocupação final dentro da capacidade.
Repetir entre eventos sobrepostos para verificar exclusividade global do recurso, não só contador por evento.

Variante de rollback: provocar falha na primeira transação após alocação e deixar a segunda concluir.
Assertar ausência de inscrição/alocação/pendência/operação órfã da primeira, e recurso alocado uma única vez à segunda.
Tentar confirmação e cancelamento simultâneos; resultado final e resposta idempotente devem corresponder ao vencedor.

## 4. Ambiente e isolamento

Banco local descartável explicitamente nomeado, sufixo `_test`, com WMA_TEST_DATABASE_URL e opt-in PostgreSQL.
Não utilizar banco compartilhado nem dados reais. Fixture cria e limpa somente seu banco; secrets são sintéticos.
Separar banco de testes ORM do banco restaurado usado para migrations e funções/triggers reais.
Desabilitar leitura de .env em configurações de teste quando necessário, preservando validação real dos Settings.

Testes de HTTP com portas simuladas comprovam contrato; testes de integração com adaptadores reais comprovam
pertencimento, locks e tradução de erros. Um não substitui o outro. Não chamar serviços turísticos que fazem commit
para simular uma unidade transacional compartilhada inexistente.

## 5. Evidência para certificação

Registrar comandos, versões, SHA, número de testes, cobertura, duração e banco descartável por execução.
Para concorrência, registrar assertivas de ambas as transações e consulta final; não expor payloads ou dados pessoais.
Falha ou ferramenta indisponível permanece pendente. PR verde não aprova automaticamente regras de negócio.
Esta proposta de plano aguarda aceite de A7; nenhum caso foi executado como funcionalidade Bike Tour nesta revisão.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-07, versão 1.1 |
| Última atualização | 10/09/2026 |
| Aceite | Vaner, 11/09/2026; plano aprovado para execução durante a implementação |
| Implementação | Plano aceito; execução dos testes pertence à implementação autorizada pelo gate |

<!-- cspell:ignore inscricao inscricoes ocorrencia ocorrencias logistica alocacao alocacoes correlacao -->
<!-- cspell:ignore reacomodacao reconciliacao idempotencia versao btree gist payloads fixtures operationId -->
<!-- cspell:ignore rebloqueio -->
