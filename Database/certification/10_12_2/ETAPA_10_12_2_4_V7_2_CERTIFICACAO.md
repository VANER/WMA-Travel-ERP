# WMA Travel ERP
# ETAPA 10.12.2.4 — V7.2
# CERTIFICAÇÃO DA RECONCILIAÇÃO QUANTITATIVA E ESTRUTURAL

**Data:** 16/08/2026  
**Banco:** `wma_travel_rebuild_test`  
**Usuário:** `postgres`  
**SGBD:** PostgreSQL 18.4  
**Modo de execução:** SOMENTE LEITURA  
**Status:** APROVADA

---

## 1. Objetivo

A V7.2 teve como objetivo realizar a reconciliação quantitativa e estrutural
do banco reconstruído `wma_travel_rebuild_test` contra o baseline estrutural
estabelecido para a ETAPA 10.12.2.

A execução foi realizada diretamente através do PostgreSQL 18.4 utilizando
`psql` e o script:

`Database/database/scripts/10_12_2/ETAPA_10_12_2_4_V7_2_Reconciliacao.sql`

A execução foi somente leitura e não realizou alterações no banco.

---

## 2. Contexto da execução

Banco:

`wma_travel_rebuild_test`

Usuário:

`postgres`

Versão:

`PostgreSQL 18.4 on x86_64-windows, compiled by msvc-19.44.35227, 64-bit`

---

## 3. Reconciliação quantitativa

| Objeto | Baseline | Reconstruído | Status |
|---|---:|---:|---|
| Schemas | 8 | 8 | OK |
| Tabelas | 209 | 209 | OK |
| Views | 38 | 38 | OK |
| Sequences | 206 | 206 | OK |
| Índices | 357 | 357 | OK |
| Constraints | 1.176 | 1.176 | OK |
| Functions | 64 | 64 | OK |
| Procedures | 11 | 11 | OK |
| Triggers | 138 | 138 | OK |

### Resultado

**9/9 métricas estruturais reconciliadas.**

Não foram identificadas divergências quantitativas.

---

## 4. Distribuição das constraints

| Tipo | Quantidade |
|---|---:|
| CHECK | 37 |
| FOREIGN KEY | 187 |
| NOT NULL | 665 |
| PRIMARY KEY | 208 |
| UNIQUE | 79 |
| **TOTAL** | **1.176** |

A soma dos tipos totaliza exatamente 1.176 constraints.

---

## 5. Integridade das Foreign Keys

Resultado da consulta de FKs não validadas:

**0 registros**

Conclusão:

**Todas as Foreign Keys encontram-se validadas.**

---

## 6. Duplicidade de nomes de constraints

Resultado da consulta de duplicidades de nomes:

**0 registros**

Conclusão:

**Não foram identificados nomes de constraints duplicados dentro do mesmo schema.**

---

## 7. Distribuição dos triggers

| Schema | Triggers |
|---|---:|
| auditoria | 15 |
| financeiro | 30 |
| public | 93 |
| **TOTAL** | **138** |

---

## 8. Distribuição das views

| Schema | Views |
|---|---:|
| auditoria | 12 |
| dw | 1 |
| public | 25 |
| **TOTAL** | **38** |

---

## 9. Distribuição das sequences

| Schema | Sequences |
|---|---:|
| auditoria | 34 |
| config | 2 |
| dw | 10 |
| financeiro | 26 |
| public | 134 |
| **TOTAL** | **206** |

---

## 10. Integridade da reconstrução

A V7.2 confirmou que o banco reconstruído apresenta correspondência
quantitativa integral com o baseline utilizado na reconciliação.

Foram confirmados:

- 8 schemas;
- 209 tabelas;
- 38 views;
- 206 sequences;
- 357 índices;
- 1.176 constraints;
- 64 functions;
- 11 procedures;
- 138 triggers.

Também foram confirmados:

- 0 Foreign Keys não validadas;
- 0 nomes duplicados de constraints.

---

## 11. Segurança da execução

A V7.2 foi executada em:

**MODO: SOMENTE LEITURA**

O script não contém comandos destinados à criação, alteração ou exclusão
de objetos do banco.

A finalidade da V7.2 é exclusivamente de inspeção e reconciliação.

---

## 12. Ocorrência de encoding

Durante a primeira tentativa de execução ocorreu erro relacionado à
codificação do arquivo SQL no ambiente Windows/psql:

`caractere com sequência de bytes 0x8d na codificação "WIN1252" não tem equivalente na codificação "UTF8"`

O problema foi identificado como incompatibilidade de encoding do arquivo
SQL no ambiente de execução, não como problema do PostgreSQL ou do banco.

O arquivo foi normalizado para ASCII e executado novamente com sucesso.

A execução posterior foi concluída sem erros.

---

## 13. Resultado final

### STATUS: APROVADA

A ETAPA 10.12.2.4 — V7.2 — Reconciliação Quantitativa e Estrutural está
**tecnicamente concluída e aprovada**.

O banco:

`wma_travel_rebuild_test`

fica registrado como:

**BANCO DE RECONSTRUÇÃO VALIDADO — V7.2**

A partir deste ponto, novas etapas de validação devem preservar este banco
como referência de reconstrução e não devem modificar sua estrutura sem
registro formal da respectiva etapa.

---

## 14. Critério de encerramento

| Critério | Resultado |
|---|---|
| Reconciliação de schemas | APROVADO |
| Reconciliação de tabelas | APROVADO |
| Reconciliação de views | APROVADO |
| Reconciliação de sequences | APROVADO |
| Reconciliação de índices | APROVADO |
| Reconciliação de constraints | APROVADO |
| Reconciliação de functions | APROVADO |
| Reconciliação de procedures | APROVADO |
| Reconciliação de triggers | APROVADO |
| FKs não validadas | 0 |
| Constraints duplicadas | 0 |
| Execução somente leitura | APROVADO |
| Resultado geral | **APROVADO** |

---

## 15. Encerramento formal

**ETAPA 10.12.2.4 — V7.2**

**STATUS: CONCLUÍDA / APROVADA**

`wma_travel_rebuild_test` permanece registrado como banco de reconstrução
estruturalmente reconciliado.

Próxima ação:

**CONTINUIDADE DA ETAPA 10.12.2**, mediante identificação e execução da
próxima validação prevista no roteiro, sem presumir aprovação de etapas
ainda não executadas.
