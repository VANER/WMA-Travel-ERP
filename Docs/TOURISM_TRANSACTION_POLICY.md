# Política Transacional de Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6.5 — Política Transacional (`TUR-DOC-05`)
> **Módulo:** Turismo
> **Tipo de documento:** Política Técnica e Funcional
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Objetivo e limite

Esta política define consistência, concorrência, idempotência e compensação para saída, vaga e reserva. Ela aprova
o comportamento transacional requerido, sem escolher tabelas, constraints, payloads ou código. O delta físico
será decidido em `TUR-DOC-08` e implementado somente após o fechamento integral do gate.

As transações são locais ao módulo proprietário. Integrações com Comercial e Financeiro usam correlação,
idempotência e recuperação explícita; não dependem de transação distribuída.

## 2. Termos normativos

| Termo | Definição |
| --- | --- |
| Capacidade | limite efetivo de passageiros aceitos por uma saída |
| Disponibilidade | capacidade menos ocupações e bloqueios válidos |
| Bloqueio | retenção temporária de vagas, com expiração obrigatória |
| Ocupação | vagas comprometidas por reserva confirmada |
| Liberação | reversão única de bloqueio ou ocupação elegível |
| Chave idempotente | identificador estável de uma intenção mutável |
| Correlação | identificador que liga fatos de domínios diferentes |
| Compensação | nova operação que neutraliza efeito confirmado anteriormente |

Disponibilidade é informação temporal. Uma consulta isolada não constitui garantia; somente uma alocação
confirmada dentro da transação de Turismo reserva capacidade.

## 3. Equação e invariantes de capacidade

Para cada saída:

```text
disponibilidade = capacidade_efetiva - vagas_bloqueadas_validas - vagas_confirmadas
```

Devem ser preservadas em todo commit:

- `capacidade_efetiva >= 0`;
- `vagas_bloqueadas_validas >= 0`;
- `vagas_confirmadas >= 0`;
- bloqueios válidos e confirmações não superam a capacidade efetiva;
- uma alocação pertence a uma única saída e a uma única intenção;
- uma vaga não pode estar simultaneamente bloqueada e confirmada pela mesma alocação;
- expiração ou cancelamento libera o efeito no máximo uma vez;
- capacidade não é reduzida abaixo do total já comprometido;
- histórico de ocupação não é apagado após conclusão ou no-show.

A fonte física do saldo e a estratégia de conferência serão aprovadas em `TUR-DOC-08`. Um contador materializado,
se adotado, deve ser reconciliável com as alocações que explicam seu valor.

## 4. Unidades transacionais

| Comando | Escritas atômicas obrigatórias |
| --- | --- |
| Criar bloqueio | validar saída, capacidade, chave e validade; registrar alocação |
| Confirmar reserva | validar bloqueio ou saldo, registrar ocupação e transição da reserva |
| Expirar bloqueio | marcar expiração e liberar efeito uma vez |
| Cancelar reserva | transicionar reserva, liberar ocupação elegível e registrar motivo |
| Reacomodar | reservar destino novo antes de compensar origem, conforme política |
| Alterar capacidade | validar compromissos existentes e registrar justificativa |
| Registrar no-show | preservar ocupação histórica e transicionar a reserva |
| Cancelar saída | congelar novas alocações e registrar plano para reservas afetadas |

Evento de integração decorrente de commit deve ser registrável na mesma unidade local que o fato de origem ou por
mecanismo equivalente que impeça perda silenciosa. O mecanismo físico depende de decisão posterior.

## 5. Concorrência

### 5.1 Regra de ordem transacional por saída

Comandos que alteram capacidade ou alocação da mesma saída devem observar uma ordem única de commit. A futura
implementação deve usar primitiva transacional suportada pelo PostgreSQL, como bloqueio da linha de capacidade ou
controle otimista versionado com nova tentativa limitada.

Não são aceitos:

- leitura do saldo seguida de escrita sem proteção contra concorrência;
- contador atualizado sem vínculo auditável com a alocação;
- bloqueio apenas em memória ou dependente de uma única instância da aplicação;
- tratamento de violação de capacidade como sucesso parcial;
- repetição infinita em contenção.

### 5.2 Última vaga

Se duas intenções concorrentes disputarem a última vaga, somente uma pode confirmar a alocação. A perdedora recebe
conflito estável, sem reserva parcial, contador negativo ou efeito em Comercial e Financeiro.

### 5.3 Ordem de aquisição

Operações com mais de uma saída devem adquirir proteção em ordem determinística de identificador. Essa regra reduz
deadlocks; ocorrências remanescentes devem causar rollback integral e nova tentativa limitada.

## 6. Idempotência

Todo comando mutável exposto a repetição deve exigir chave idempotente no escopo de ator, operação e recurso.

| Repetição | Resultado obrigatório |
| --- | --- |
| mesma chave e mesmo conteúdo | retornar o resultado lógico original |
| mesma chave e conteúdo diferente | rejeitar como conflito de idempotência |
| chave nova para intenção equivalente | aplicar regras de unicidade do negócio |
| repetição após timeout | consultar ou concluir o resultado anterior sem duplicar efeito |

A chave não substitui autorização, versionamento ou correlação. O prazo de retenção será definido com Segurança em
`TUR-DOC-06` e deve cobrir a janela máxima de repetição e reconciliação.

## 7. Ciclo de bloqueio e reserva

```text
DISPONÍVEL -> BLOQUEADA -> RESERVADA
                   |           |
                   v           v
               EXPIRADA    LIBERADA
```

1. bloqueio recebe instante absoluto de expiração definido no servidor;
2. confirmação válida converte o efeito do bloqueio em ocupação, sem consumir vaga adicional;
3. bloqueio vencido não pode ser confirmado;
4. expiração lógica vale mesmo antes do processamento físico do trabalho de limpeza;
5. liberação manual exige motivo, autorização e versão esperada;
6. tarefa de expiração é repetível e não altera alocação já confirmada;
7. confirmação sem bloqueio, se admitida pelo contrato futuro, usa a mesma proteção de capacidade.

Relógio da aplicação e banco deve usar instante com fuso normalizado. Horário informado pelo cliente não decide a
validade do bloqueio.

## 8. Confirmação e dependências comerciais

A reserva é confirmada por Turismo somente quando as precondições operacionais e comerciais aprovadas estiverem
presentes. O vínculo comercial deve conter correlação única, mas Turismo não modifica venda ou contrato.

Sequência normativa:

1. Comercial cria ou identifica a formalização sob sua autoridade;
2. solicita a Turismo usando correlação e chave idempotente;
3. Turismo valida versão, vigência e capacidade sob sua transação local;
4. Turismo confirma a reserva e registra o resultado correlacionado;
5. a consequência financeira é encaminhada após o commit local;
6. falha posterior entra em reconciliação, sem desfazer silenciosamente o commit.

O contrato técnico definirá qual evidência comercial é obrigatória e como situações divergentes são reconciliadas.

## 9. Cancelamento, expiração e no-show

| Situação | Vaga | Reserva | Efeito externo |
| --- | --- | --- | --- |
| Bloqueio expirado | liberada uma vez | permanece ausente ou pendente | correlação encerrada |
| Reserva pendente cancelada | bloqueio liberado | CANCELADA | Comercial notificado se aplicável |
| Reserva confirmada cancelada | liberada conforme política | CANCELADA | avaliação comercial e financeira |
| Cancelamento após início | ocupação histórica preservada | regra excepcional | política contratual aplicada externamente |
| No-show | ocupação histórica preservada | NO_SHOW | política comercial e financeira aplicável |

Cancelamento não apaga reserva, passageiro, correlação ou evento. Consequência monetária é decidida por Comercial e
Financeiro; Turismo registra apenas a transição operacional e a solicitação correlacionada.

## 10. Reacomodação

Reacomodação é uma operação composta, auditável e idempotente:

1. validar elegibilidade e autorização;
2. obter alocação na saída de destino;
3. registrar vínculo entre reserva de origem e destino;
4. confirmar a nova ocupação;
5. compensar a ocupação anterior conforme o ponto operacional;
6. solicitar avaliação de diferenças a Comercial e Financeiro;
7. reconciliar qualquer efeito externo pendente.

Falha antes da nova confirmação preserva a reserva original. Falha após confirmação exige estado intermediário
recuperável; não é permitido liberar a origem primeiro e perder ambas as vagas.

## 11. Cancelamento de saída

Ao iniciar cancelamento de saída, Turismo deve impedir novos bloqueios, identificar todas as reservas afetadas e
registrar uma decisão individual de reacomodação ou cancelamento. A saída somente alcança `CANCELADA` quando o
processo operacional possuir evidência suficiente para reconciliação.

Processamento em lote deve isolar falhas por reserva, admitir retomada e expor totais de pendências. Não deve manter
uma transação de banco aberta durante chamadas a outros módulos.

## 12. Compensação e reconciliação

| Falha | Estado preservado | Recuperação |
| --- | --- | --- |
| timeout antes do commit de Turismo | resultado desconhecido | consultar pela chave idempotente |
| conflito de capacidade | nenhuma escrita parcial | informar indisponibilidade |
| falha após confirmação local | reserva confirmada | reenviar efeito externo com mesma correlação |
| rejeição comercial definitiva | estado correlacionado pendente | compensação autorizada ou intervenção |
| falha financeira | fato operacional preservado | nova tentativa e reconciliação financeira |
| divergência de correlação | ambos os históricos preservados | fila de análise auditável |

Compensação é um novo fato, nunca edição retroativa. Nova tentativa usa política limitada, espaçamento progressivo
e classificação entre erro transitório e definitivo. Após o limite, o item permanece visível para intervenção.

## 13. Resultados de erro normativos

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

Erros não podem revelar existência de recurso fora do escopo do ator nem conter dados pessoais. Códigos HTTP e
payloads definitivos serão aprovados junto aos contratos de API.

## 14. Observabilidade mínima

Métricas e registros devem permitir identificar contenção, conflitos, bloqueios expirados, tentativas, pendências
de compensação e divergências de reconciliação. Não podem usar CPF, documento, e-mail ou nome de passageiro como
rótulo ou conteúdo operacional genérico.

## 15. Critérios de aceite

- invariantes permanecem verdadeiros sob concorrência;
- última vaga nunca é confirmada para duas intenções;
- todo comando repetível possui comportamento idempotente verificável;
- expiração e cancelamento liberam capacidade no máximo uma vez;
- reacomodação não perde a ocupação de origem antes de assegurar o destino;
- falha externa não produz escrita parcial entre autoridades;
- pendências de integração são rastreáveis e reconciliáveis;
- testes de falha e concorrência são derivados em `TUR-DOC-07`.

## 16. Conclusão

O `TUR-DOC-05` aprova os limites transacionais, a estratégia de concorrência e as regras de compensação da Etapa
2.6. A próxima entrega autorizada é `TUR-DOC-06` — Segurança e privacidade. A implementação funcional permanece
bloqueada até a aprovação integral do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6.5 — Política Transacional de Turismo |
| Entregável | `TUR-DOC-05` |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
