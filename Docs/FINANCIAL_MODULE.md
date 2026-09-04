# Módulo Financeiro

## 1. Escopo entregue

A etapa 2.5 implementa o domínio Financeiro sobre o schema `financeiro`, preservando o dump certificado e
introduzindo o delta por migration Alembic aditiva.

Capacidades cobertas:

- plano de contas, classificações, centros de custo e rateios refletidos da baseline;
- lançamentos de contas a pagar e receber com parcelas;
- pagamentos parciais, movimentações e conciliação;
- bancos, contas, caixa, cartões, faturas e transferências;
- capital social, AFAC, pró-labore e distribuição de lucros;
- tributos, empréstimos, parcelas, imobilizado e depreciação;
- integração idempotente entre Venda e Lançamento;
- períodos e fechamento financeiro;
- RBAC e API REST versionada.

## 2. Arquitetura

O módulo está em `Backend/app/modules/financeiro` e segue as camadas model, repository, service, schema e router.
Repositories não fazem commit. Services controlam as unidades transacionais e executam rollback em falhas.

O contrato compartilhado `app/shared/vendas.py` impede dependência direta da implementação Financeira sobre o
módulo Comercial.

## 3. API

Todas as rotas usam o prefixo `/api/v1/financeiro`.

| Método e rota | Finalidade | Permissão adicional |
| --- | --- | --- |
| `GET /lancamentos` | Lista lançamentos | `FINANCEIRO_VISUALIZAR` |
| `POST /lancamentos` | Cria lançamento e parcelas | `FINANCEIRO_OPERAR` |
| `POST /parcelas/{id}/pagamentos` | Liquida parcela e movimenta conta | `FINANCEIRO_OPERAR` |
| `POST /transferencias` | Transfere entre contas atomicamente | `FINANCEIRO_OPERAR` |
| `POST /movimentacoes/{id}/conciliacao` | Concilia movimento | `FINANCEIRO_OPERAR` |
| `POST /vendas/{id}/lancamento` | Gera financeiro idempotente | `FINANCEIRO_OPERAR` |
| `POST /periodos` | Abre período mensal | `FINANCEIRO_APROVAR` |
| `POST /periodos/{id}/fechamento` | Fecha período | `FINANCEIRO_APROVAR` |
| Estruturas especializadas | Contratos futuros por capacidade | não publicadas |

As estruturas especializadas da baseline — caixa, cartões, capital, tributos, empréstimos e imobilizado — foram
preservadas, mas não receberam endpoints genéricos. Cada capacidade exige contrato próprio em evolução futura;
publicar um payload único seria incompatível com suas colunas e regras distintas.

## 4. Regras implementadas

- valores monetários usam `Decimal` e precisão de centavos;
- a soma das parcelas deve corresponder ao valor líquido do lançamento;
- competência e vencimento não antecedem a emissão;
- chaves idempotentes impedem duplicar lançamento de venda, pagamento e transferência;
- a parcela é bloqueada para atualização durante liquidação;
- liquidação não pode exceder o saldo;
- pagamento, saldos e movimento são confirmados na mesma transação;
- transferência gera movimentos correlatos de saída e entrada;
- uma movimentação possui no máximo uma conciliação;
- período fechado rejeita novos lançamentos daquela competência;
- Venda precisa estar confirmada e possuir valor líquido para originar lançamento.

## 5. Migration

A revision `202609030100` depende de `202608310100`. Ela:

- valida as baselines Comercial e Financeira;
- interrompe se detectar o universo F1-FIN divergente;
- adiciona as capacidades ausentes sem editar o dump histórico;
- adiciona rastreabilidade e idempotência aos fatos existentes;
- cria permissões e as concede ao perfil `ADMIN`;
- possui downgrade restrito ao delta da Fase 2.

## 6. Execução e validação

No diretório `Backend/`:

```powershell
python -m pip check
python -m ruff check .
python -m mypy app tests
python -m pytest -W error --cov=app --cov-report=term-missing
python -m alembic heads
```

O teste real de upgrade/downgrade requer PostgreSQL local descartável com a baseline restaurada. Nunca execute a
migration experimentalmente em banco compartilhado, homologação ou produção.
