# Inventário Financeiro

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.5.1 — Inventário ORM/Financeiro (`FIN-DOC-01`)

**Data do levantamento:** 03/09/2026

**Status:** APROVADO

## 2. Objetivo e limites

Este inventário identifica a estrutura financeira disponível para reflexão futura pelo SQLAlchemy. Ele não cria
models, tabelas, migrations, endpoints ou regras de negócio e não altera a baseline nem os artefatos F1-FIN.

Fontes consultadas:

- `Database/scripts/WmaTravelERP.sql`, dump completo oficial;
- `Database/scripts/F1_FIN/`, construção histórica do domínio Financeiro;
- `Database/certification/F1_FIN_13_CERTIFICACAO_FINAL.md`, certificação histórica;
- `Docs/DATA_DICTIONARY.md` e `Docs/DATABASE_STANDARDS.md`;
- `Docs/FINANCIAL_DOCUMENTATION_GATE.md`;
- ADR-003, ADR-004, ADR-014 e ADR-017.

## 3. Autoridade e fronteiras

O schema `financeiro` é a autoridade das operações financeiras. O futuro código funcional pertence a
`app/modules/financeiro`, atualmente apenas uma marcação de fronteira.

`public.empresa`, `public.cliente`, `public.fornecedor` e a identidade de usuário do Core/Segurança permanecem
autoridades corporativas. As tabelas homônimas `financeiro.empresa`, `financeiro.cliente`,
`financeiro.fornecedor` e `financeiro.usuario` são representações legadas e não devem originar novos cadastros.
A consolidação indicada pelos padrões históricos não aparece concluída no dump oficial e exige decisão explícita.

O Comercial é autoridade sobre Venda. O Financeiro pode receber uma obrigação ou um direito decorrente da venda,
mas o dump não declara foreign key entre `public.venda` e `financeiro.lancamento`. Fiscal e Contábil também não
devem ser absorvidos pelo módulo Financeiro sem decisão própria.

## 4. Universo comprovado no dump oficial

O dump contém 26 tabelas e 26 sequences no schema `financeiro`. Não contém views, functions ou procedures próprias
do schema. Há 30 triggers explícitos em 15 tabelas: um de atualização e um de auditoria por tabela, ambos chamando
funções compartilhadas de `public`.

### 4.1 Cadastros legados e configuração

| Objeto | Papel estrutural | Autoridade funcional |
| --- | --- | --- |
| `financeiro.empresa` | Cópia cadastral usada por lançamentos | `public.empresa` |
| `financeiro.cliente` | Cópia cadastral financeira | `public.cliente` |
| `financeiro.fornecedor` | Cópia cadastral financeira | `public.fornecedor` |
| `financeiro.usuario` | Cópia de identidade | Core/Segurança |
| `financeiro.configuracao` | Parâmetros financeiros | Financeiro |
| `financeiro.anexo` | Metadados de anexo de lançamento | Financeiro, com arquivo fora do banco |

### 4.2 Plano de contas e classificações

| Objeto | Papel | Dependências diretas no schema |
| --- | --- | --- |
| `financeiro.grupo` | Primeiro nível do plano | Nenhuma |
| `financeiro.categoria` | Segundo nível | `grupo` |
| `financeiro.subcategoria` | Terceiro nível | `categoria` |
| `financeiro.classificacao` | Classificação financeira/DRE | `subcategoria`; referências esperadas fora do dump |
| `financeiro.conta` | Conta do plano | `classificacao` |
| `financeiro.centro_custo` | Dimensão gerencial | Nenhuma |
| `financeiro.rateio_centro_custo` | Rateio de lançamento | `lancamento`, `centro_custo` |

### 4.3 Lançamentos, parcelas e pagamentos

| Objeto | Papel | Dependências diretas no schema |
| --- | --- | --- |
| `financeiro.tipo_lancamento` | Catálogo de tipos | Nenhuma |
| `financeiro.status_lancamento` | Catálogo de estados | Nenhuma |
| `financeiro.tipo_documento` | Catálogo documental financeiro | Nenhuma |
| `financeiro.forma_pagamento` | Catálogo de formas de pagamento | Nenhuma |
| `financeiro.lancamento` | Cabeçalho de obrigação/direito | Cadastros e catálogos financeiros |
| `financeiro.lancamento_parcela` | Parcelamento do lançamento | `lancamento` |
| `financeiro.pagamento` | Liquidação de parcela | `lancamento_parcela`, `forma_pagamento` |
| `financeiro.historico_lancamento` | Histórico de alterações | `lancamento` e usuário legado |

O mesmo agregado representa contas a pagar e a receber por tipo/natureza; não existem tabelas distintas
`conta_pagar` e `conta_receber` no dump.

### 4.4 Bancos, movimentação e conciliação

| Objeto | Papel | Dependências diretas no schema |
| --- | --- | --- |
| `financeiro.banco` | Catálogo bancário | Nenhuma |
| `financeiro.conta_bancaria` | Conta bancária operacional | `banco`, `empresa` |
| `financeiro.tipo_movimentacao` | Catálogo de movimentos | Nenhuma |
| `financeiro.movimentacao_bancaria` | Movimento em conta | `conta_bancaria`, `tipo_movimentacao` |
| `financeiro.conciliacao_bancaria` | Conciliação de movimento | `movimentacao_bancaria` |

## 5. Divergência entre as fontes certificadas

As três fontes históricas não descrevem o mesmo universo:

| Fonte | Universo observado |
| --- | --- |
| dump `WmaTravelERP.sql` | 26 tabelas e 26 sequences em `financeiro` |
| certificação final F1-FIN.13 | 37 tabelas, 37 sequences e 96 índices |
| scripts F1-FIN versionados | 16 tabelas adicionadas e cinco cópias legadas removidas |

As tabelas declaradas pelos scripts, mas ausentes do dump, são:

- plano/classificação: `financeiro.natureza_financeira`, `financeiro.tipo_dre`;
- caixa e cartões: `financeiro.caixa`, `financeiro.transferencia`, `financeiro.cartao`,
  `financeiro.fatura_cartao`, `financeiro.fatura_cartao_item`;
- capital: `financeiro.capital_social`, `financeiro.afac`, `financeiro.pro_labore`,
  `financeiro.distribuicao_lucro`;
- obrigações e ativos: `financeiro.tributo`, `financeiro.emprestimo`,
  `financeiro.emprestimo_parcela`, `financeiro.ativo_imobilizado`, `financeiro.depreciacao_ativo`.

O fluxo oficial explica os 37 objetos certificados: parte das 26 tabelas do dump, adiciona 16 objetos e remove as
cinco cópias cadastrais legadas. Esse estado foi reproduzido em PostgreSQL descartável e é a autoridade do ORM.

## 6. Condições para reflexão ORM

As 26 tabelas do dump são tecnicamente refletíveis com schema explícito. O mapeamento futuro deve:

- declarar `schema="financeiro"` e respeitar nomes e tipos existentes;
- não usar `create_all()` nem alterar a baseline a partir de metadata;
- mapear valores monetários como `Decimal`, preservando `NUMERIC(15,2)`;
- tratar soft delete e `versao` conforme a nulabilidade real de cada tabela;
- não inventar relacionamentos ausentes nem cascatas não declaradas;
- reutilizar contratos internos do Core para autoridades corporativas;
- manter repositories sem commit autônomo, conforme a ADR-014.

`financeiro.classificacao` é um bloqueio específico: os scripts F1-FIN adicionam relações com
`natureza_financeira` e `tipo_dre`, mas essas tabelas não constam no dump. O model não pode pressupor que essas
referências estejam disponíveis até a decisão sobre o universo estrutural correto.

## 7. Riscos e lacunas

- não há vínculo estrutural e idempotente entre Venda e Lançamento;
- não há regra aprovada para caixa versus competência;
- status e transições válidas ainda não foram confrontados com o fluxo funcional;
- pagamentos parciais, estornos, juros, multas, descontos e abatimentos não têm contrato funcional aprovado;
- conciliação não tem tolerância, chave de importação ou estratégia de reprocessamento aprovadas;
- não há período financeiro, fechamento ou reabertura comprovados no dump;
- duplicidades cadastrais entre `public` e `financeiro` permanecem materializadas;
- auditoria e versionamento não são uniformes nas 26 tabelas;
- a ausência das 16 tabelas adicionais impede afirmar cobertura de cartões, transferências, capital, tributos,
  empréstimos e imobilizado a partir do dump oficial;
- chamadas externas de pagamento e banco não podem ocorrer dentro de transações longas.

Essas lacunas não autorizam migrations ou regras implícitas. Elas devem alimentar `FIN-DOC-02` a `FIN-DOC-08`.

## 8. Cobertura do roteiro da etapa 2.5

| Capacidade planejada | Evidência no dump | Classificação |
| --- | --- | --- |
| plano de contas | grupo, categoria, subcategoria, classificação e conta | Parcial; dependências ausentes |
| contas a pagar/receber | lançamento, parcela e pagamento | Existente, regra funcional pendente |
| caixa e bancos | banco, conta bancária e movimentação | Parcial; caixa próprio ausente |
| cartões | nenhuma tabela | Presente apenas nos scripts F1-FIN |
| transferências | nenhuma tabela | Presente apenas nos scripts F1-FIN |
| rateios | centro de custo e rateio | Existente |
| conciliação | conciliação bancária | Existente, contrato funcional pendente |
| capital, AFAC, pró-labore e lucros | nenhuma tabela | Presentes apenas nos scripts F1-FIN |
| tributos, empréstimos e imobilizado | nenhuma tabela | Presentes apenas nos scripts F1-FIN |
| integração Comercial | nenhuma FK Venda → Lançamento | Ausente |

## 9. Critérios de conclusão de `FIN-DOC-01`

- [x] objetos do schema `financeiro` no dump oficial inventariados;
- [x] autoridades cadastrais e fronteiras de domínio classificadas;
- [x] cobertura funcional confrontada com o dump e os scripts F1-FIN;
- [x] condições e bloqueios para reflexão ORM registrados;
- [x] divergência quantitativa entre dump, scripts e certificação registrada;
- [x] riscos monetários, transacionais, de concorrência e idempotência identificados;
- [x] baseline e artefatos históricos preservados;
- [x] gates automatizados de rastreabilidade adicionados;
- [x] evolução F1-FIN reproduzida em PostgreSQL local descartável;
- [x] inventário aprovado para liberar o próximo entregável documental.
