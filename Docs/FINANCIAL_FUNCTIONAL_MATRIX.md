# Matriz Funcional Financeira

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.5 — Financeiro (`FIN-DOC-02`)

**Data:** 03/09/2026

**Status:** APROVADA

## 2. Objetivo e limites

Esta matriz relaciona as capacidades planejadas da etapa 2.5 às estruturas encontradas no inventário aprovado.
Ela classifica cobertura e decisões necessárias, mas não define regras financeiras ausentes, não escolhe entre
fontes estruturais divergentes e não autoriza implementação.

As evidências estruturais referem-se ao dump oficial `Database/scripts/WmaTravelERP.sql`. Objetos encontrados
somente em `Database/scripts/F1_FIN/` são classificados como históricos até a decisão `FIN-DOC-08`.

## 3. Classificação de cobertura

| Classificação | Significado |
| --- | --- |
| Existente | Estrutura principal comprovada no dump; regras ainda precisam de contrato |
| Parcial | Parte do fluxo existe, mas há lacuna estrutural ou funcional relevante |
| Histórico | Objeto existe apenas nos scripts F1-FIN e não no dump oficial |
| Ausente | Não há estrutura comprovada nas fontes inventariadas |
| Transversal | Autoridade pertence a outro domínio e deve ser consumida por contrato interno |

## 4. Matriz de capacidades

| Capacidade | Dados comprovados | Entrada | Saída esperada | Cobertura | Decisão necessária |
| --- | --- | --- | --- | --- | --- |
| Plano de contas | `grupo`, `categoria`, `subcategoria`, `classificacao`, `conta` | Estrutura hierárquica | Conta classificável | Parcial | Resolver referências ausentes de natureza e DRE |
| Classificações | `classificacao`; natureza e DRE apenas históricas | Conta e finalidade | Classificação aplicável | Parcial | Vigência, hierarquia e uso contábil versus gerencial |
| Contas a pagar | `lancamento`, `tipo_lancamento`, `status_lancamento`, `fornecedor` legado | Obrigação | Lançamento pagável | Parcial | Tipo, competência, aprovação e autoridade do fornecedor |
| Contas a receber | `lancamento`, `tipo_lancamento`, `status_lancamento`, `cliente` legado | Direito | Lançamento recebível | Parcial | Tipo, competência, aprovação e autoridade do cliente |
| Parcelas | `lancamento_parcela` | Lançamento e condição | Cronograma de vencimentos | Existente | Soma, arredondamento, renegociação e vencimento |
| Pagamentos | `pagamento`, `forma_pagamento` | Parcela e valor | Liquidação total ou parcial | Existente | Parcialidade, encargos, desconto, estorno e idempotência |
| Caixa | `caixa` apenas histórico | Movimento em espécie | Saldo e movimento de caixa | Histórico | Restaurar por migration ou representar com conta bancária |
| Bancos | `banco`, `conta_bancaria` | Dados bancários | Conta operacional | Existente | Saldo derivado, titularidade e inativação |
| Cartões | `cartao`, `fatura_cartao`, `fatura_cartao_item` apenas históricos | Compra/fatura | Obrigação por cartão | Histórico | Autoridade, fechamento, parcelamento e vínculo com lançamento |
| Transferências | `transferencia` apenas histórico | Conta origem/destino e valor | Dois movimentos correlacionados | Histórico | Atomicidade, chave idempotente e estorno |
| Centros de custo | `centro_custo` | Estrutura gerencial | Centro aplicável | Existente | Hierarquia, vigência e responsabilidade |
| Rateios | `rateio_centro_custo` | Lançamento e percentuais/valores | Distribuição gerencial | Existente | Fechamento de 100%, arredondamento e alteração posterior |
| Movimentações | `movimentacao_bancaria`, `tipo_movimentacao` | Conta, data e valor | Movimento bancário | Existente | Origem, unicidade, sinal e vínculo com pagamento |
| Conciliação | `conciliacao_bancaria` | Movimento interno e evidência externa | Estado conciliado | Existente | Tolerância, pareamento, desconciliação e reprocessamento |
| Capital social | `capital_social` apenas histórico | Sócio, valor e data | Evento de capital | Histórico | Autoridade societária e reflexo contábil/fiscal |
| AFAC | `afac` apenas histórico | Aportante, valor e data | Adiantamento controlado | Histórico | Conversão, devolução e aprovação societária |
| Pró-labore | `pro_labore` apenas histórico | Beneficiário e competência | Obrigação de pagamento | Histórico | Fiscal, retenções e vínculo com pessoa/colaborador |
| Distribuição de lucros | `distribuicao_lucro` apenas histórico | Beneficiário e período | Distribuição aprovada | Histórico | Apuração, aprovação e fronteira contábil/fiscal |
| Tributos | `tributo` apenas histórico | Competência e obrigação | Tributo controlado | Histórico | Cálculo pertence ao Fiscal ou ao Financeiro |
| Empréstimos | `emprestimo`, `emprestimo_parcela` apenas históricos | Contrato e cronograma | Dívida e parcelas | Histórico | Juros, amortização, encargos e renegociação |
| Imobilizado | `ativo_imobilizado`, `depreciacao_ativo` apenas históricos | Aquisição e vida útil | Ativo e depreciações | Histórico | Autoridade contábil/fiscal e método de depreciação |
| Comercial → Financeiro | `public.venda`; sem FK para `financeiro.lancamento` | Venda confirmada | Lançamento idempotente | Ausente | Evento, chave de origem, atomicidade e cancelamento |

## 5. Fluxo operacional mínimo

O fluxo planejado somente poderá ser implementado após formalização das decisões correspondentes:

```text
Venda confirmada
      ↓
Lançamento financeiro
      ↓
Parcelas consistentes com o total
      ↓
Pagamento ou recebimento
      ↓
Movimentação da conta
      ↓
Conciliação com evidência externa
```

Regras mínimas ainda pendentes:

1. a criação financeira decorrente da venda deve possuir chave idempotente e origem rastreável;
2. lançamento, parcelas e rateios devem fechar no mesmo total segundo regra explícita de arredondamento;
3. liquidação parcial não pode exceder o saldo da parcela;
4. pagamento e movimentação correlata pertencem ao mesmo caso de uso transacional quando internos;
5. estorno deve preservar histórico e produzir reversão rastreável, não apagar fatos;
6. conciliação deve impedir pareamento duplicado e admitir desconciliação auditada;
7. integrações externas devem ocorrer fora de transações longas e admitir reprocessamento idempotente.

Os itens acima são requisitos de decisão e teste, não regras já comprovadas pela baseline.

## 6. Estados e transições a decidir

A existência de `status_lancamento` não comprova o vocabulário nem as transições permitidas. A matriz funcional
requer que `FIN-DOC-05` defina, no mínimo:

- criação, aprovação e cancelamento do lançamento;
- aberto, parcialmente liquidado, liquidado e vencido;
- estorno de pagamento e reversão de movimentação;
- conciliado, desconciliado e divergente;
- fechamento e reabertura de período.

Nenhum desses estados deve ser codificado a partir de texto livre ou inferência sobre dados de exemplo.

## 7. Fronteiras funcionais

| Domínio | Autoridade | Participação no fluxo financeiro |
| --- | --- | --- |
| Core Corporativo | empresa, cliente, fornecedor e pessoas | Fornece identidades estáveis |
| Segurança | usuário, permissões e auditoria de acesso | Autoriza e identifica ações |
| Comercial | venda e itens | Origina obrigação ou direito após evento aprovado |
| Financeiro | lançamento, parcela, pagamento, movimento e conciliação | Executa e registra o ciclo financeiro |
| Fiscal | cálculo e documento fiscal | Fornece ou consome obrigações tributárias conforme decisão futura |
| Contábil | competência, escrituração e demonstrações | Fora do escopo até definição explícita |

## 8. Cenários que devem alimentar a rastreabilidade

- venda à vista e parcelada;
- conta a pagar sem origem comercial;
- pagamento/recebimento total e parcial;
- tentativa de liquidação acima do saldo;
- desconto, multa, juros e abatimento;
- cancelamento antes e depois de pagamento;
- estorno e reprocessamento repetido;
- rateio com diferença de centavos;
- transferência entre contas;
- importação bancária duplicada;
- conciliação com valor/data divergente;
- concorrência entre duas liquidações da mesma parcela;
- fechamento e tentativa de alteração retroativa.

## 9. Critérios de conclusão de `FIN-DOC-02`

- [x] todas as capacidades da ordem oficial classificadas;
- [x] entradas, saídas e estruturas relacionadas registradas;
- [x] estruturas exclusivas dos scripts históricos distinguidas do dump;
- [x] fluxo principal e pontos transacionais identificados;
- [x] fronteiras com Core, Segurança, Comercial, Fiscal e Contábil registradas;
- [x] decisões não comprovadas mantidas como pendências;
- [x] cenários mínimos preparados para a matriz de rastreabilidade;
- [x] matriz funcional aprovada para liberar `FIN-DOC-03`.
