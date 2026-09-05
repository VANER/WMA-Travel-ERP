# Matriz de Rastreabilidade de Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6.3 — Matriz de Rastreabilidade (`TUR-DOC-03`)
> **Módulo:** Turismo
> **Tipo de documento:** Documento de Rastreabilidade
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Objetivo e limite

Esta matriz liga os requisitos aprovados em `TUR-DOC-02` aos dados, serviços de aplicação, superfícies de API
planejadas e evidências de teste. Os nomes de serviços e operações são identificadores de rastreabilidade, não
contratos implementados.

Rotas, payloads, códigos de resposta, permissões, transações e representação física continuam sujeitos a
`TUR-DOC-04` até `TUR-DOC-08`. Nenhum item desta matriz autoriza implementação funcional ou alteração da baseline.

## 2. Convenções

- `RF-TUR`: requisito funcional de Turismo;
- **atual**: estrutura existente na baseline certificada;
- **delta**: conceito sem representação suficiente, dependente de decisão em `TUR-DOC-08`;
- nomes iniciados por `/v1/turismo` representam superfícies candidatas da API;
- cada requisito deve possuir teste de autorização, validação e erro, além da evidência específica indicada.

## 3. Requisito e autoridade de dados

| ID | Requisito | Autoridade e dados relacionados |
| --- | --- | --- |
| RF-TUR-001 | Manter destinos válidos | Core: `localidade`; Turismo: `destino` atual |
| RF-TUR-002 | Manter produtos turísticos | Turismo: `produto_turistico` atual; destino requer decisão |
| RF-TUR-003 | Compor pacote e roteiro | Turismo: `pacote_viagem`, `roteiro_viagem` atuais |
| RF-TUR-004 | Programar saída operacional | Turismo: saída como delta; pacote atual como origem |
| RF-TUR-005 | Consultar disponibilidade | Turismo: capacidade e razão de vagas como delta |
| RF-TUR-006 | Bloquear e expirar vaga | Turismo: alocação, validade e idempotência como delta |
| RF-TUR-007 | Criar e confirmar reserva | Turismo: `reserva` atual; versão e correlação como delta |
| RF-TUR-008 | Correlacionar venda e contrato | Comercial: venda, item e contrato; Turismo: reserva |
| RF-TUR-009 | Manter passageiros mínimos | Turismo: `passageiro` atual; política depende do `TUR-DOC-06` |
| RF-TUR-010 | Compor serviços e fornecedores | Core: fornecedor; Turismo: serviços e composição como delta |
| RF-TUR-011 | Planejar recursos e checklist | Turismo: `checklist_viagem`; alocações como delta |
| RF-TUR-012 | Cancelar, expirar ou reacomodar | Turismo: reserva e vaga; efeitos externos correlacionados |
| RF-TUR-013 | Iniciar e encerrar saída | Turismo: saída, ocorrências e checklist |
| RF-TUR-014 | Registrar no-show | Turismo: reserva, ocupação histórica e ocorrência |
| RF-TUR-015 | Registrar avaliação elegível | Turismo: `avaliacao_pos_viagem` e reserva atual |
| RF-TUR-016 | Auditar transições sensíveis | Auditoria: evento; Turismo: referência e correlação |

## 4. Serviço e operação de API planejados

| ID | Serviço de aplicação candidato | Superfície de API candidata |
| --- | --- | --- |
| RF-TUR-001 | `DestinoService` | `/v1/turismo/destinos` |
| RF-TUR-002 | `ProdutoTuristicoService` | `/v1/turismo/produtos` |
| RF-TUR-003 | `PacoteService` | `/v1/turismo/pacotes` e sub-recurso `roteiro` |
| RF-TUR-004 | `SaidaService` | `/v1/turismo/saidas` |
| RF-TUR-005 | `DisponibilidadeService` | `/v1/turismo/saidas/{id}/disponibilidade` |
| RF-TUR-006 | `VagaService` | `/v1/turismo/saidas/{id}/bloqueios` |
| RF-TUR-007 | `ReservaService` | `/v1/turismo/reservas` e ação `confirmar` |
| RF-TUR-008 | `ComercialService` | operação interna versionada; rota pública a decidir |
| RF-TUR-009 | `PassageiroService` | `/v1/turismo/reservas/{id}/passageiros` |
| RF-TUR-010 | `ServicoTuristicoService` | `/v1/turismo/pacotes/{id}/servicos` |
| RF-TUR-011 | `OperacaoViagemService` | `/v1/turismo/saidas/{id}/operacao` |
| RF-TUR-012 | `GestaoReservaService` | ações `cancelar`, `expirar` e `reacomodar` |
| RF-TUR-013 | `OperacaoViagemService` | ações `iniciar` e `concluir` na saída |
| RF-TUR-014 | `GestaoReservaService` | ação `registrar-no-show` na reserva |
| RF-TUR-015 | `AvaliacaoViagemService` | `/v1/turismo/reservas/{id}/avaliacao` |
| RF-TUR-016 | `AuditoriaTurismoService` | consulta administrativa restrita; rota a decidir |

Os verbos de ação indicam intenção funcional. O padrão definitivo deve seguir a governança vigente da API e será
avaliado antes da implementação, inclusive quanto a idempotência, concorrência e respostas de conflito.

## 5. Evidências de teste requeridas

| ID | Evidência mínima de teste |
| --- | --- |
| RF-TUR-001 | localidade inválida rejeitada; destino duplicado tratado |
| RF-TUR-002 | ativação exige destino e dados válidos |
| RF-TUR-003 | roteiro fora do período ou fora de ordem rejeitado |
| RF-TUR-004 | capacidade negativa e período inválido rejeitados |
| RF-TUR-005 | saldo calculado explica capacidade, bloqueios e reservas |
| RF-TUR-006 | concorrência pela última vaga tem um vencedor; expiração é idempotente |
| RF-TUR-007 | confirmação sem vaga falha; repetição não duplica ocupação |
| RF-TUR-008 | correlação duplicada ou inexistente é rejeitada sem escrita parcial |
| RF-TUR-009 | quantidade de passageiros respeita vagas; dados sensíveis não vazam |
| RF-TUR-010 | fornecedor e serviço incompatíveis são rejeitados |
| RF-TUR-011 | recurso conflitante e transição inválida são rejeitados |
| RF-TUR-012 | cancelamento libera vaga uma vez; falha externa permanece recuperável |
| RF-TUR-013 | saída não inicia incompleta; conclusão registra ator e instante |
| RF-TUR-014 | no-show preserva ocupação histórica e impede duplicidade |
| RF-TUR-015 | avaliação antes da conclusão ou duplicada é rejeitada |
| RF-TUR-016 | mutações sensíveis geram evento; acesso não autorizado é negado |

## 6. Rastreabilidade transversal

| Controle | Requisitos alcançados | Documento responsável pela decisão |
| --- | --- | --- |
| Fronteiras e contratos internos | 001, 008, 010, 012 e 016 | `TUR-DOC-04` |
| Transação, concorrência e compensação | 004 a 008 e 012 a 014 | `TUR-DOC-05` |
| Autorização, privacidade e auditoria | 001 a 016, com foco em 009 e 016 | `TUR-DOC-06` |
| Estratégia e níveis de teste | 001 a 016 | `TUR-DOC-07` |
| Persistência e migrations aditivas | 002 e 004 a 016 | `TUR-DOC-08` |

## 7. Critério de cobertura

Um requisito somente poderá ser considerado implementado quando possuir:

1. regra e autoridade aprovadas no documento responsável;
2. representação de dados compatível com a decisão de schema;
3. serviço de aplicação sem acesso indevido à persistência de outro domínio;
4. contrato OpenAPI versionado, quando houver superfície HTTP;
5. testes unitários, de integração e de autorização aplicáveis;
6. evidência de regressão da baseline e migrations lineares;
7. vínculo entre requisito, alteração, teste e resultado de CI.

A classificação **delta** não significa aprovação automática de nova tabela ou coluna. Ela apenas evidencia que a
baseline atual não satisfaz integralmente o requisito.

## 8. Conclusão

A matriz `TUR-DOC-03` cobre os 16 requisitos funcionais identificados e mantém explícitas as decisões ainda
pendentes. Os entregáveis sucessores `TUR-DOC-04` e `TUR-DOC-05` também foram aprovados, e a próxima entrega
autorizada é `TUR-DOC-06` — Segurança e privacidade. A implementação funcional segue bloqueada até a aprovação
integral do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6.3 — Matriz de Rastreabilidade de Turismo |
| Entregável | `TUR-DOC-03` |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
