# Política Transacional de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.5 — Política Transacional (`BT-DOC-05`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Política Técnica e Funcional
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Objetivo e limite

Esta política define consistência, concorrência, idempotência, expiração e compensação para o domínio de Bike Tour.
Ela descreve as regras transacionais esperadas para eventos, recursos, inscrições, blocos e ocorrências, sem
aprovar tabelas, payloads ou código. A decisão física do
delta será submetida em `BT-DOC-08` como requisito para a aprovação documental do gate.

As transações são locais ao domínio de Bike Tour. Integrações com Turismo, Comercial e Financeiro usam correlação,
idempotência e recuperação explícita; não dependem de transação distribuída.

## 2. Termos normativos

| Termo | Definição |
| --- | --- |
| Capacidade | limite efetivo de participantes e recursos por evento |
| Disponibilidade | capacidade menos bloqueios válidos e alocações confirmadas |
| Bloqueio | retenção temporária de recurso, com expiração obrigatória |
| Alocação | vínculo de recurso a inscrição ou evento |
| Liberação | reversão de bloqueio ou alocação elegível |
| Chave idempotente | identificador estável da intenção mutável |
| Correlação | identificador de ligação entre domínios distintos |
| Compensação | operação nova que neutraliza efeito anterior de forma rastreável |

Disponibilidade é informação temporal. Uma leitura isolada não constitui garantia. Somente a confirmação dentro da
mesma transação de Bike Tour produz capacidade operacional válida.

## 3. Equação e invariantes de capacidade

Para cada evento de Bike Tour e recurso específico:

```text
disponibilidade = capacidade_efetiva - bloqueios_validos - alocacoes_confirmadas
```

Devem ser preservados em todo commit:

- `capacidade_efetiva >= 0`;
- `bloqueios_validos >= 0`;
- `alocacoes_confirmadas >= 0`;
- bloqueios válidos e confirmações não superam a capacidade efetiva;
- cada alocação pertence a um único evento e a um único recurso;
- um recurso não pode estar simultaneamente bloqueado e confirmado para a mesma intenção;
- expiração ou cancelamento libera o efeito no máximo uma vez;
- mudança do estado do evento não remove histórico de alocação confirmada;
- capacidade não pode ser reduzida abaixo do total já comprometido;
- histórico operacional não é apagado após cancelamento, conclusão ou no-show.

A fonte física do saldo e da conferência será aprovada em `BT-DOC-08`.

## 4. Unidades transacionais

| Comando | Escritas atômicas obrigatórias |
| --- | --- |
| criar bloqueio | validar evento, recurso, capacidade e validade; registrar alocação |
| confirmar inscrição | validar bloqueio ou saldo, registrar ocupação e transição |
| expirar bloqueio | marcar expiração e liberar efeito uma vez |
| cancelar inscrição | transicionar estado, liberar ocupação elegível e registrar motivo |
| reacomodar recurso | reservar destino antes de compensar origem |
| alterar evento | validar compromissos existentes e registrar justificativa |
| registrar ocorrência | preservar contexto, gravidade e trilha de status |
| encerrar evento | bloquear nova alocação e registrar fechamento |

Evento de integração decorrente de commit deve ser registrável na mesma unidade local da operação ou por mecanismo
equivalente que impeça perda silenciosa.

## 5. Concorrência

### 5.1 Regra de ordem transacional por evento

Comandos que alteram capacidade ou alocação do mesmo evento devem observar ordem única de commit. A futura
implementação deve usar primitiva transacional compatível com PostgreSQL, como bloqueio de linha ou controle
otimista com nova tentativa limitada.

Não são aceitos:

- leitura do saldo seguida de escrita sem proteção contra concorrência;
- contador atualizado sem vínculo auditável com a alocação;
- bloqueio apenas em memória ou dependente de uma única instância;
- tratamento de indisponibilidade como sucesso parcial;
- repetição infinita em contenção.

### 5.2 Último recurso

Se duas intenções concorrentes disputarem o último recurso, somente uma pode confirmar a alocação. A perdedora
recebe conflito estável, sem alocação parcial, contador negativo ou efeito inconsistente em Turismo ou Comercial.

### 5.3 Ordem de aquisição

Operações com mais de um recurso devem adquirir proteção em ordem determinística de identificador. Isso reduz
deadlocks e preserva integridade do evento.

## 6. Idempotência

Todo comando mutável exposto a repetição deve exigir chave idempotente no escopo de ator, operação e recurso.

| Repetição | Resultado obrigatório |
| --- | --- |
| mesma chave e mesmo conteúdo | retornar o resultado lógico original |
| mesma chave e conteúdo diferente | rejeitar como conflito de idempotência |
| chave nova para intenção equivalente | aplicar regras de unicidade do negócio |
| repetição após timeout | consultar ou concluir resultado anterior sem duplicar efeito |

A chave não substitui autorização, versionamento ou correlação. O prazo de retenção será definido com Segurança em
`BT-DOC-06` e deve cobrir a janela de repetição e reconciliação.

## 7. Ciclo de bloqueio e confirmação

```text
DISPONÍVEL -> BLOQUEADO -> CONFIRMADO
                 |           |
                 v           v
             EXPIRADO    LIBERADO
```

1. bloqueio recebe instante de expiração definido no servidor;
2. confirmação válida converte o efeito do bloqueio em alocação, sem consumir recurso extra;
3. bloqueio vencido não pode ser confirmado;
4. expiração lógica vale mesmo antes da limpeza física;
5. liberação manual exige motivo, autorização e versão esperada;
6. tarefa de expiração é repetível e não altera alocação confirmada;
7. confirmação sem bloqueio, se admitida, usa a mesma proteção de capacidade.

Relógio da aplicação e do banco devem usar instante com fuso normalizado. O cliente não decide validade do bloco.

## 8. Confirmação e dependências comerciais e turísticas

A inscrição de Bike Tour deve ser confirmada com as precondições operacionais e de origem aprovadas. O vínculo
comercial ou turístico permanece externo ao domínio funcional do módulo, sem duplicação de venda, contrato ou
reserva principal.

Sequência normativa:

1. Turismo ou Comercial registra a origem da intenção sob sua autoridade;
2. Bike Tour recebe correlação e chave idempotente;
3. Bike Tour valida evento, recurso e capacidade dentro da transação local;
4. Bike Tour confirma a inscrição e registra o resultado correlacionado;
5. consequência financeira ou comercial é encaminhada após o commit local;
6. falha posterior entra em reconciliação, sem desfazer silenciosamente o commit.

## 9. Cancelamento, expiração e no-show

| Situação | Recurso | Inscrição | Efeito externo |
| --- | --- | --- | --- |
| bloqueio expirado | liberado uma vez | permanece sem confirmação | correlação encerrada |
| inscrição pendente cancelada | liberado | CANCELADA | operação e origem notificadas |
| inscrição confirmada cancelada | liberado conforme regra | CANCELADA | avaliação comercial e financeira |
| cancelamento após início | recurso histórico preservado | transição documentada | política contratual aplicada |
| no-show | recurso preservado em histórico | NO_SHOW | regra contratual aplicada por origem |

Cancelamento não apaga evento, correlação, recurso ou histórico. Consequência monetária é decidida por Comercial e
Financeiro; Bike Tour apenas registra a transição operacional e a correlação.

## 10. Reacomodação e encerramento

Reacomodação é operação composta, auditável e idempotente:

1. validar elegibilidade e autorização;
2. obter recurso no destino;
3. registrar vínculo entre inscrição de origem e destino;
4. confirmar novo estado;
5. compensar alocação anterior conforme regra operacional;
6. solicitar avaliação de diferenças a Comercial e Financeiro;
7. reconciliar qualquer efeito externo pendente.

Falha antes da nova confirmação preserva a inscrição original. Falha após confirmação exige estado intermediário
recuperável; não é permitido liberar a origem primeiro e perder ambos os recursos.

Ao encerrar um evento, Bike Tour deve bloquear novas alocações, identificar inscrições afetadas e registrar uma
decisão individual de reacomodação, cancelamento ou fechamento. O evento só alcança `CONCLUIDO` com evidência
suficiente para reconciliação.

## 11. Compensação e reconciliação

| Falha | Estado preservado | Recuperação |
| --- | --- | --- |
| timeout antes do commit | resultado desconhecido | consultar pela chave idempotente |
| conflito de capacidade | nenhuma escrita parcial | informar indisponibilidade |
| falha após confirmação local | inscrição confirmada | reenviar efeito externo com mesma correlação |
| rejeição comercial definitiva | estado correlacionado pendente | compensação autorizada ou intervenção |
| divergência de correlação | ambos os históricos preservados | fila de análise auditável |

Compensação é um novo fato, nunca edição retroativa. Nova tentativa usa política limitada, espaçamento
progressivo e classificação entre erro transitório e definitivo.

## 12. Resultados de erro normativos

O contrato de API futuro deve distinguir ao menos:

- entrada inválida;
- recurso ausente;
- estado ou versão incompatível;
- capacidade indisponível;
- chave idempotente reutilizada com conteúdo divergente;
- bloqueio expirado;
- conflito de concorrência;
- ação não autorizada;
- dependência externa pendente ou indisponível.

Erros não podem revelar existência de recurso fora do escopo do ator nem conter dados pessoais.

## 13. Observabilidade mínima

Métricas e registros devem permitir identificar contenção, conflitos, bloqueios expirados, tentativas, pendências
de compensação e divergências de reconciliação. Não devem usar CPF, documento, e-mail ou nome do participante como
rótulo operacional genérico.

## 14. Critérios de aceite

- invariantes permanecem verdadeiros sob concorrência;
- o último recurso nunca é confirmado para duas intenções;
- todo comando repetível possui comportamento idempotente verificável;
- expiração e cancelamento liberam capacidade no máximo uma vez;
- reacomodação não perde a origem antes de garantir o destino;
- falha externa não produz escrita parcial entre autoridades;
- as pendências de integração são rastreáveis e reconciliáveis;
- testes de falha e concorrência são derivados em `BT-DOC-07`.

## 15. Conclusão

O `BT-DOC-05` define os limites transacionais e a estratégia de concorrência esperados para o módulo de Bike Tour.
Ele permanece em elaboração e deve ser aprovado antes da implementação funcional da etapa 2.7.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.5 — Política Transacional de Bike Tour |
| Entregável | `BT-DOC-05` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

<!-- cspell:ignore CONCLUIDO -->
