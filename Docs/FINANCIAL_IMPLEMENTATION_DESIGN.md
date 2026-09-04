# Desenho de Implementação Financeira

## 1. Identificação

**Etapa:** 2.5 — Financeiro

**Entregáveis:** `FIN-DOC-03` a `FIN-DOC-08`

**Data:** 03/09/2026

**Status:** APROVADO PARA IMPLEMENTAÇÃO

## 2. Matriz de rastreabilidade (`FIN-DOC-03`)

| Requisito | Dados | Serviço/API | Teste obrigatório |
| --- | --- | --- | --- |
| Consultar plano | grupo até conta | consultas `/financeiro/plano-contas` | ordenação e exclusão lógica |
| Criar obrigação/direito | lançamento e parcelas | `criar_lancamento` | totais, datas e rollback |
| Gerar financeiro da venda | venda, origem financeira e lançamento | `gerar_da_venda` | idempotência e valor |
| Liquidar parcela | pagamento, parcela e lançamento | `liquidar_parcela` | parcialidade, excesso e concorrência |
| Movimentar conta | movimentação bancária | incluído na liquidação | entrada/saída e atomicidade |
| Transferir | transferência e dois movimentos | `transferir` | soma zero e rollback |
| Ratear | rateio e lançamento | `ratear_lancamento` | total de 100% e centavos |
| Conciliar | conciliação e movimento | `conciliar_movimento` | duplicidade e reversão |
| Administrar capacidades especiais | tabelas específicas | contratos futuros por capacidade | baseline preservada |

## 3. Fronteiras (`FIN-DOC-04`)

- Core é autoridade de empresa, cliente, fornecedor e pessoa.
- Segurança é autoridade de usuário e das permissões `FINANCEIRO_VISUALIZAR`, `FINANCEIRO_OPERAR` e
  `FINANCEIRO_APROVAR`.
- Comercial é autoridade da venda; Financeiro guarda apenas `id_venda_origem` e uma chave idempotente.
- Financeiro é autoridade de lançamentos, parcelas, liquidações, movimentos, conciliações e saldos derivados.
- Fiscal é autoridade do cálculo fiscal; Financeiro controla apenas a obrigação tributária recebida.
- Contabilidade permanece fora do escopo. Classificação DRE é gerencial até decisão futura.

## 4. Política transacional (`FIN-DOC-05`)

O service define a unidade de trabalho e repositories nunca fazem commit. Criação de lançamento e parcelas,
liquidação e movimento, transferência e movimentos, além de conciliação, são operações atômicas. Falhas provocam
rollback integral.

Cada origem externa usa chave idempotente única. Pagamentos não podem exceder o saldo. Valores são quantizados em
centavos; parcelas usam ajuste determinístico na última parcela. Estorno cria registros de reversão relacionados
ao fato original. Fechamento de período bloqueia mutações com competência anterior ou igual ao período fechado.

## 5. Segurança e alçadas (`FIN-DOC-06`)

| Permissão | Poder |
| --- | --- |
| `FINANCEIRO_VISUALIZAR` | Consultar cadastros, lançamentos e movimentos |
| `FINANCEIRO_OPERAR` | Criar lançamentos, parcelas, pagamentos, transferências e conciliações |
| `FINANCEIRO_APROVAR` | Aprovar, cancelar, estornar, fechar ou reabrir período |

O perfil `ADMIN` recebe as três permissões na migration. Segregação adicional de função depende da configuração
de perfis, sem concessão implícita. Toda mutação exige identidade autenticada e mantém auditoria estrutural.

## 6. Plano de testes (`FIN-DOC-07`)

- unitários: schemas, cálculos, transições, rateios, parcelas e idempotência;
- repositories: busca bloqueante e paginação determinística;
- API: autenticação, autorização, respostas 201/404/409/422 e contratos;
- migration: head único, upgrade/downgrade e presença de constraints, índices, comentários e triggers;
- PostgreSQL: atomicidade, locks, generated columns, FKs e rollback em banco local descartável;
- regressão: lint, tipagem, cobertura, OpenAPI e compatibilidade.

## 7. Decisão de schema (`FIN-DOC-08`)

O dump oficial permanece imutável e os scripts F1-FIN completam a baseline executável certificada. As 16 tabelas
introduzidas por esses scripts não são recriadas pelo Alembic. O delta da Fase 2 adiciona somente a
rastreabilidade Venda → Lançamento, chaves idempotentes, reversões e períodos financeiros.

A migration tem pré-validação da baseline, transação, constraints explícitas, comentários, triggers e
rollback apenas dos objetos da Fase 2. Ela não reaplicará nem editará scripts F1-FIN.

## 8. Critérios de saída documental

- [x] requisito → dado → serviço → API → teste rastreado;
- [x] fronteiras de domínio delimitadas;
- [x] commit, rollback, estorno, concorrência e idempotência definidos;
- [x] permissões e alçadas definidas;
- [x] cenários normais, limites, falhas e regressões definidos;
- [x] migration aditiva escolhida e baseline preservada;
- [x] implementação autorizada pelo escopo integral solicitado.
