# WMA Travel ERP — Certificação de Reprodutibilidade F1-FIN

**Data:** 18/08/2026  
**PostgreSQL:** 18.4  
**Banco de referência:** `wma_travel`  
**Banco descartável:** `wma_phase1_verify_20260818`  
**Status:** APROVADA

## Objetivo

Certificar que a evolução financeira F1-FIN pode ser aplicada sobre o dump histórico
`Database/scripts/WmaTravelERP.sql` em um banco limpo e produzir o mesmo universo estrutural do banco de
referência.

Esta certificação complementa a baseline histórica do commit `d63800e`; ela não altera retroativamente as
evidências emitidas em 17/08/2026.

## Procedimento executado

1. Criação do banco descartável `wma_phase1_verify_20260818`.
2. Restauração integral de `Database/scripts/WmaTravelERP.sql` com `ON_ERROR_STOP=1`.
3. Execução de F1-FIN.01 a F1-FIN.04.
4. Detecção e correção do acoplamento dos scripts F1-FIN.05 a F1-FIN.11 ao nome `wma_travel`.
5. Reexecução de F1-FIN.05 a F1-FIN.11 com
   `expected_database=wma_phase1_verify_20260818`.
6. Execução somente leitura de F1-FIN.12 e F1-FIN.13.
7. Execução de `Database/audit/06_validar_log_auditoria.sql`.
8. Comparação quantitativa entre o banco de referência e o banco reconstruído.
9. Execução ponta a ponta de `Database/install.sh --with-validation` no banco descartável
   `wma_install_verify_20260818`, concluída com código de saída zero.

## Proteção do banco-alvo

Os scripts persistentes F1-FIN.05 a F1-FIN.11 usam `wma_travel` como banco esperado por padrão. Para execução
em rebuild, o operador deve informar explicitamente `-v expected_database=<banco>`. O script compara o valor
com `current_database()` e aborta em caso de divergência.

## Resultado estrutural

Schemas temporários `pg_temp_*` e schemas de sistema foram excluídos da contagem.

| Objeto | Referência | Rebuild | Resultado |
| --- | ---: | ---: | --- |
| Schemas da aplicação | 8 | 8 | OK |
| Tabelas | 220 | 220 | OK |
| Views | 38 | 38 | OK |
| Sequences | 217 | 217 | OK |
| Constraints | 1.433 | 1.433 | OK |
| Índices | 391 | 391 | OK |
| Functions | 64 | 64 | OK |
| Procedures | 11 | 11 | OK |
| Triggers de usuário | 138 | 138 | OK |
| Tabelas em `financeiro` | 37 | 37 | OK |

## Resultado da certificação financeira

F1-FIN.13 apresentou no banco de referência e no rebuild:

- tabelas financeiras sem PK: 0;
- constraints não validadas: 0;
- FKs para objetos `public` não transversais: 0;
- registros órfãos nos núcleos críticos: 0;
- classificações sem natureza: 0;
- itens DRE sem tipo: 0;
- resíduos de teste: 0;
- status: `F1_FIN_13_CERTIFICADA`.

A validação geral também confirmou:

- funções obrigatórias de auditoria: 2 de 2;
- triggers de usuário desabilitados: 0;
- tabelas sem PK: 0, desconsiderada a exceção certificada `public.v_total`;
- resultado: `VALIDAÇÃO ESTRUTURAL DA AUDITORIA: APROVADA`.

## Hashes dos scripts executados

| Script | SHA-256 |
| --- | --- |
| `F1_FIN_01_INVENTARIO_FINANCEIRO.sql` | `69BC22BA0814A34C936D9C28E9679B1EDCDCF184AC501C6E6531ADA33F0E06BF` |
| `F1_FIN_02_MAPA_FUNCIONAL.sql` | `1494AA06A5CD31C0D45B522B27A95AA6F5F809EB56622E82AF8220932E6EADD9` |
| `F1_FIN_03_ANALISE_LACUNAS_ESTRUTURAIS.sql` | `77E570651BC2860A01D3F6EE1507C42927F05FBB344BC2EF22F16433D7316DC6` |
| `F1_FIN_04_CORRECOES_MINIMAS.sql` | `9090D47B5F4DE8F23B6868A1622DE0A6C426753BBA440C000B52A6E0FEBAB4AF` |
| `F1_FIN_05_PLANO_CONTAS_CLASSIFICACOES.sql` | `073229EF809A122E4C41706591A0C10714CC3B26A9F15ABA7B894B29F497E985` |
| `F1_FIN_06_AP_AR_PARCELAMENTOS.sql` | `54CEBA001B68F5657AD64402912A9F858D96C6E94F7483CCAC4162C8E25117E3` |
| `F1_FIN_07_CAIXA_BANCOS_CARTOES_TRANSFERENCIAS.sql` | `38589CD0123EA1559ADBC531292B882E231393EB5895C77486DDBCB098777B99` |
| `F1_FIN_08_RATEIOS_CENTROS_CUSTO.sql` | `53BF5F5D867A56F33CAE9F7930952051C763052B6496C83F20ADF413FB3B6861` |
| `F1_FIN_09_CONCILIACAO_MOVIMENTACAO.sql` | `D6685EE3B5E29C3378C4D3003872EB8D69B7ED3870E2F2697B50C6EB9E2FAC21` |
| `F1_FIN_10_CAPITAL_AFAC_PRO_LABORE_LUCROS.sql` | `95A0154CF4D416FE14559D2E22F453B130A9D4E6717862DED5DAE64A5A090593` |
| `F1_FIN_11_TRIBUTOS_EMPRESTIMOS_IMOBILIZADO.sql` | `F67D3D0970AE5EE211C1C9D08B098B10024E120B0CB8F5D17E543E813969BB17` |
| `F1_FIN_12_AUDITORIA_INTEGRIDADE_FINANCEIRA.sql` | `3B8C8174330636AC67A01D030932E4ED131751C426AEE22F1AB40C0E93AADF44` |
| `F1_FIN_13_CERTIFICACAO_ESTRUTURAL_FINANCEIRO.sql` | `8FFD0719990A4E1FCC032623C0B8FF50C252ADB97A25DBC98FC5CF8BF0955A36` |

## Decisão

**F1-FIN: CERTIFICADA E REPRODUZÍVEL**

O dump histórico somado à sequência persistente F1-FIN reproduz o universo estrutural financeiro vigente. O
`install.sh` passa a aplicar essa sequência por padrão e a executar F1-FIN.12/F1-FIN.13 quando solicitado com
`--with-validation`.

Os bancos descartáveis utilizados nesta certificação foram removidos após a coleta das evidências.
