# WMA Travel ERP — Certificação Final F1-FIN.13

## Identificação

| Item | Valor |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | F1-FIN.13 — Certificação Estrutural do Módulo Financeiro |
| Banco | `wma_travel` |
| Usuário executor | `postgres` |
| PostgreSQL | 18.4 |
| Server encoding | UTF8 |
| Client encoding | UTF8 |
| Executado em | 18/08/2026 14:07:16 -03:00 |
| Commit da implementação financeira | `33fe492` |
| Commit de consolidação anterior ao gate final | `980af60` |
| Marco definitivo | tag `phase-1-final-2026-08-18` |
| Modo | Somente leitura, transação encerrada com `ROLLBACK` |
| Status | APROVADA |

## Objetivo

Formalizar a execução final do script `F1_FIN_13_CERTIFICACAO_ESTRUTURAL_FINANCEIRO.sql` após a correção do
gate bloqueante de resíduos de teste. A correção garante que `residuos_teste` participe tanto do status calculado
quanto do bloco `DO $$` que lança a exceção de reprovação.

## Artefatos certificados

| Artefato | SHA-256 |
| --- | --- |
| `Database/scripts/F1_FIN/F1_FIN_13_CERTIFICACAO_ESTRUTURAL_FINANCEIRO.sql` | `8FFD0719990A4E1FCC032623C0B8FF50C252ADB97A25DBC98FC5CF8BF0955A36` |
| `Database/certification/evidence/F1_FIN_13_EXECUCAO_FINAL_20260818.txt` | `2210FA6A5DFA86F07F0A441289F9C1B3DEBF383494E0F3F2C9BE3306724A760D` |

## Universo financeiro

| Objeto | Quantidade |
| --- | ---: |
| Tabelas | 37 |
| Sequences | 37 |
| Índices | 96 |
| Tabelas documentadas | 37 |
| Tabelas sem comentário | 0 |

## Resultado dos critérios bloqueantes

| Critério | Resultado |
| --- | ---: |
| Tabelas sem PK | 0 |
| Constraints não validadas | 0 |
| FKs `financeiro` → `public` não transversais | 0 |
| Parcelas órfãs | 0 |
| Pagamentos órfãos | 0 |
| Movimentações órfãs | 0 |
| Conciliações órfãs | 0 |
| Rateios órfãos | 0 |
| Classificações sem natureza financeira | 0 |
| Registros DRE sem tipo | 0 |
| Resíduos de teste | 0 |

## Plano de contas

| Objeto | Quantidade |
| --- | ---: |
| Grupos | 5 |
| Categorias | 13 |
| Subcategorias | 23 |
| Classificações | 23 |
| Contas | 23 |

## Resíduos de teste

Foram verificados os seguintes núcleos, todos com resultado zero:

- `lancamento`;
- `movimentacao_bancaria`;
- `transferencia`;
- `tributo`;
- `emprestimo`;
- `ativo_imobilizado`;
- `capital_social`;
- `afac`;
- `distribuicao_lucro`.

O total `residuos_teste = 0` foi avaliado pelo resumo de certificação e pelo gate bloqueante executado no bloco
`DO $$`.

## Resultado da execução

```text
tabelas_sem_pk                  = 0
constraints_nao_validadas       = 0
fks_public_nao_transversais     = 0
parcelas_orfas                  = 0
pagamentos_orfaos               = 0
movimentos_orfaos               = 0
conciliacoes_orfas              = 0
rateios_orfaos                  = 0
classificacoes_sem_natureza     = 0
dre_sem_tipo                    = 0
residuos_teste                  = 0
status                          = F1_FIN_13_CERTIFICADA
validacao_bloqueante            = APROVADA
transacao                       = ROLLBACK
```

## Decisão

**STATUS: APROVADA**

O módulo Financeiro atende integralmente aos critérios bloqueantes definidos pela F1-FIN.13. A execução não
alterou dados nem estrutura e foi encerrada com `ROLLBACK`.

Esta certificação integra o marco definitivo da Fase 1 identificado pela tag
`phase-1-final-2026-08-18`.
