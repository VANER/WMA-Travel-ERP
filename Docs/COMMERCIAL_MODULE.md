# Módulo Comercial Integrado

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapas:** 2.4.3 a 2.4.12

**Status:** CONCLUÍDAS, CERTIFICADAS E INTEGRADAS

## 2. Escopo entregue

O incremento completa o fluxo Comercial iniciado pelo inventário 2.4.1 e pelos serviços de Cliente 2.4.2.
Foram implementados:

- Leads, origens, interações e transições explícitas de estado;
- CRM cronológico sem duplicação dos dados pessoais do Core;
- Operadora como papel único de Fornecedor;
- Oportunidade qualificada e vinculada ao Lead;
- Proposta, itens e condições comerciais com valores em `NUMERIC(15,2)`;
- conversão exclusiva de proposta aceita em Venda;
- vínculo de Contrato com Documento, Venda e Reserva;
- API versionada em `/api/v1/comercial` com RBAC e paginação;
- testes unitários e fluxo integral em PostgreSQL descartável.

## 3. Modelo e fronteiras

A decisão estrutural está registrada na ADR-018. Cliente, Fornecedor e Documento permanecem autoridades do Core
Corporativo. Produto Turístico e Reserva permanecem autoridades do Turismo. O Comercial mantém somente seus
agregados e referências, sem importar implementações internas desses módulos.

A migration `202608310100` cria `operadora`, `oportunidade`, `proposta`, `item_proposta` e
`condicao_comercial`; adiciona os vínculos de conversão; garante unicidade de Cliente por Pessoa; e registra as
permissões `COMERCIAL_VISUALIZAR` e `COMERCIAL_GERENCIAR`.

## 4. Regras de estado

```text
Lead: NOVO → CONTATADO → QUALIFICADO → CONVERTIDO
                       ↘ PERDIDO

Oportunidade: ABERTA → GANHA | PERDIDA

Proposta: RASCUNHO → ENVIADA → ACEITA | RECUSADA | EXPIRADA
                  ↘ CANCELADA
```

Estados terminais não admitem reabertura implícita. Itens somente podem ser modificados em proposta `RASCUNHO`,
e Venda somente pode ser criada a partir de proposta `ACEITA`.

## 5. API

| Recurso | Operações implementadas |
| --- | --- |
| `/comercial/leads` | listar e cadastrar |
| `/comercial/leads/{id}/status` | transicionar |
| `/comercial/interacoes` | registrar contato |
| `/comercial/operadoras` | listar e cadastrar |
| `/comercial/oportunidades` | listar e cadastrar |
| `/comercial/oportunidades/{id}/status` | transicionar |
| `/comercial/propostas` | listar e cadastrar |
| `/comercial/propostas/{id}/status` | transicionar |
| `/comercial/itens-proposta` | adicionar e recalcular |
| `/comercial/condicoes` | cadastrar |
| `/comercial/vendas` | listar e converter proposta |
| `/comercial/contratos` | listar e cadastrar |

Todas as rotas exigem `COMERCIAL_VISUALIZAR`; operações mutáveis também exigem `COMERCIAL_GERENCIAR`.

## 6. Validação local

- suíte completa: 288 testes aprovados e 6 opt-in ignorados;
- cobertura: 100% de 1.944 statements;
- integração PostgreSQL: 6 testes aprovados, incluindo o fluxo Comercial integral;
- migration: restauração da baseline, upgrade, downgrade e novo upgrade aprovados;
- OpenAPI, Ruff, Mypy, dependências e head Alembic aprovados.

Os números finais devem ser atualizados na certificação 2.4.13 após a última execução da suíte.

## 7. Encerramento

O PR #51, o CI Linux/PostgreSQL, o merge e a validação pós-merge foram aprovados. A etapa 2.4 está concluída,
certificada e integrada, e a etapa 2.5 — Financeiro está formalmente autorizada.
