# Dicionário de Dados - WMA Travel ERP

**Versão do documento:** 0.3.0
**Base de referência:** dump histórico `WmaTravelERP.sql` mais evolução F1-FIN certificada em 18/08/2026
**Gerado a partir de:** extração automática das definições reais do schema (`CREATE TABLE`, `COMMENT ON`, chaves
primárias e estrangeiras)
**Cobertura detalhada:** 209 tabelas da baseline histórica

**Cobertura consolidada:** 220 tabelas, incluindo 11 tabelas adicionadas pela evolução F1-FIN

> **Nota de integridade:** a versão anterior deste documento continha objetos que não existem
> fisicamente no banco (funções, triggers, views e extensões do PostgreSQL documentadas como se
> fossem tabelas). Esta versão foi reconstruída inteiramente a partir do dump real do banco de
> dados e contém apenas tabelas que existem de fato na baseline histórica. A evolução financeira posterior está
> registrada no complemento da seção 3.1 e em `Database/certification/F1_FIN_CERTIFICACAO_REPRODUTIBILIDADE.md`.

---

## 1. Visão Geral

Este documento descreve, de forma estrutural e 100% verificada contra o banco de dados real,
todas as tabelas do WMA Travel ERP. Para cada tabela são listados: descrição (quando disponível
via `COMMENT ON`), colunas com tipo/obrigatoriedade/valor padrão, chave primária e chaves
estrangeiras.

Tabelas que ainda não possuem `COMMENT ON TABLE` no banco estão marcadas como
**"Pendente de descrição funcional"** — a estrutura está correta e completa, mas o significado
de negócio precisa ser escrito e aplicado via `COMMENT ON` na próxima rodada de documentação
(ver backlog de documentação incremental registrado para a Fase 2).

## 2. Convenções

- Nomenclatura de tabelas e colunas em `snake_case`.
- Chaves primárias seguem majoritariamente o padrão `id_<entidade>`.
- Tabelas corporativas possuem colunas de auditoria: `created_at`, `updated_at`, `deleted_at`,
  `created_by`, `updated_by`, `deleted_by`, `versao`.
- `financeiro.*` usa `created_by`/`updated_by`/`deleted_by` como FK `integer` para
  `financeiro.usuario(id_usuario)`; os demais schemas usam `varchar(100)`.

## 3. Índice de Schemas

- [public](#4-schema-public) — 136 tabelas
- [financeiro](#5-schema-financeiro) — 37 tabelas, sendo 26 detalhadas na baseline e 11 no complemento F1-FIN
- [auditoria](#6-schema-auditoria) — 34 tabelas
- [config](#7-schema-config) — 3 tabelas
- [dw](#8-schema-dw) — 10 tabelas

### 3.1 Complemento F1-FIN

As seguintes tabelas foram adicionadas após o dump histórico e validadas no banco de referência e em rebuild
limpo. Todas possuem chave primária e `COMMENT ON TABLE`.

| Tabela | Finalidade |
| --- | --- |
| `financeiro.afac` | Adiantamentos para futuro aumento de capital. |
| `financeiro.ativo_imobilizado` | Ativos imobilizados sob controle financeiro. |
| `financeiro.capital_social` | Eventos de integralização e ajuste do capital social. |
| `financeiro.depreciacao_ativo` | Depreciações periódicas dos ativos. |
| `financeiro.distribuicao_lucro` | Distribuições de lucros aos sócios ou titular. |
| `financeiro.emprestimo` | Contratos de empréstimos e financiamentos. |
| `financeiro.emprestimo_parcela` | Parcelas vinculadas aos empréstimos. |
| `financeiro.natureza_financeira` | Domínio das naturezas do plano de contas. |
| `financeiro.pro_labore` | Controle mensal de pró-labore. |
| `financeiro.tipo_dre` | Domínio dos agrupamentos da DRE. |
| `financeiro.tributo` | Obrigações tributárias do módulo financeiro. |

O detalhamento de colunas permanece extraível diretamente do catálogo PostgreSQL. Sua incorporação integral a
este documento fica registrada como melhoria documental da Fase 2 e não altera a certificação estrutural.

---

## 4. Schema `public`

Schema padrão. Concentra os módulos de negócio (administrativo, comercial, fiscal, turismo, cicloturismo) ainda não
segregados em schemas próprios.

**Total de tabelas:** 136

### public.agenda

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_agenda`

**Chaves estrangeiras:**

- `id_colaborador` → `public.colaborador(id_colaborador)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_agenda** (PK) | integer | Sim | | |
| id_colaborador | integer | Não | | |
| titulo | character varying(150) | Não | | |
| descricao | text | Não | | |
| tipo_evento | character varying(50) | Não | | |
| data_inicio | timestamp without time zone | Não | | |
| data_fim | timestamp without time zone | Não | | |
| status | character varying(30) | Não | 'AGENDADO'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.agendamento_rotina

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_rotina`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_rotina** (PK) | integer | Sim | | |
| codigo | character varying(50) | Não | | |
| descricao | character varying(150) | Não | | |
| expressao_cron | character varying(100) | Não | | |
| ultima_execucao | timestamp without time zone | Não | | |
| proxima_execucao | timestamp without time zone | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.anexo_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_anexo`

**Chaves estrangeiras:**

- `id_projeto` → `public.projeto(id_projeto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_anexo** (PK) | integer | Sim | | |
| id_projeto | integer | Sim | | |
| nome_arquivo | character varying(255) | Não | | |
| caminho | text | Não | | |
| tipo | character varying(50) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.aplicacao_api

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_aplicacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_aplicacao** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| descricao | text | Não | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.aporte_capital

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_aporte`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_aporte** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| data_aporte | date | Não | | |
| valor | numeric(15,2) | Não | | |
| tipo | character varying(30) | Não | | |
| descricao | character varying(200) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.aprovacao_processo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_aprovacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_aprovacao** (PK) | integer | Sim | | |
| tipo_processo | character varying(100) | Não | | |
| registro_id | integer | Não | | |
| solicitante | character varying(100) | Não | | |
| aprovador | character varying(100) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| data_solicitacao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_aprovacao | timestamp without time zone | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.arquivo_digital

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_arquivo`

**Chaves estrangeiras:**

- `id_documento` → `public.documento(id_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_arquivo** (PK) | integer | Sim | | |
| id_documento | integer | Sim | | |
| nome_arquivo | character varying(255) | Não | | |
| extensao | character varying(10) | Não | | |
| caminho_arquivo | text | Não | | |
| tamanho_bytes | bigint | Não | | |
| hash_arquivo | character varying(255) | Não | | |
| versao_arquivo | integer | Não | 1 | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.assinatura_digital

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_assinatura`

**Chaves estrangeiras:**

- `id_documento` → `public.documento(id_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_assinatura** (PK) | integer | Sim | | |
| id_documento | integer | Sim | | |
| assinante | character varying(150) | Não | | |
| email | character varying(150) | Não | | |
| data_solicitacao | timestamp without time zone | Não | | |
| data_assinatura | timestamp without time zone | Não | | |
| status | character varying(30) | Não | | |
| codigo_externo | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.ativo_imobilizado

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_ativo`

**Chaves estrangeiras:**

- `id_categoria_ativo` → `public.categoria_ativo(id_categoria_ativo)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_ativo** (PK) | integer | Sim | | |
| codigo_patrimonio | character varying(30) | Sim | | |
| id_categoria_ativo | integer | Sim | | |
| descricao | character varying(200) | Sim | | |
| marca | character varying(100) | Não | | |
| modelo | character varying(100) | Não | | |
| numero_serie | character varying(100) | Não | | |
| data_aquisicao | date | Não | | |
| valor_aquisicao | numeric(15,2) | Não | | |
| valor_residual | numeric(15,2) | Não | 0 | |
| status | character varying(30) | Não | 'ATIVO'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.avaliacao_pos_viagem

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_avaliacao`

**Chaves estrangeiras:**

- `id_reserva` → `public.reserva(id_reserva)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_avaliacao** (PK) | integer | Sim | | |
| id_reserva | integer | Sim | | |
| nota | integer | Não | | |
| comentario | text | Não | | |
| recomendaria | boolean | Não | | |
| data_avaliacao | date | Não | CURRENT_DATE | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.banco

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_banco`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_banco** (PK) | integer | Sim | | |
| codigo_banco | character varying(10) | Não | | |
| nome_banco | character varying(100) | Sim | | |
| agencia | character varying(20) | Não | | |
| conta | character varying(30) | Não | | |
| tipo_conta | character varying(30) | Não | | |
| saldo_inicial | numeric(15,2) | Não | 0 | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.campanha

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_campanha`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_campanha** (PK) | integer | Sim | | |
| codigo | character varying(30) | Não | | |
| nome | character varying(150) | Não | | |
| canal | character varying(50) | Não | | |
| data_inicio | date | Não | | |
| data_fim | date | Não | | |
| orcamento | numeric(15,2) | Não | | |
| investimento_real | numeric(15,2) | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.cargo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_cargo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_cargo** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(100) | Sim | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.categoria_ativo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_categoria_ativo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_categoria_ativo** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(100) | Sim | | |
| vida_util_anos | integer | Não | | |
| taxa_depreciacao | numeric(5,2) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.categoria_conta

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_categoria`

**Chaves estrangeiras:**

- `id_grupo` → `public.grupo_conta(id_grupo)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_categoria** (PK) | integer | Sim | | |
| id_grupo | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(150) | Sim | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.centro_custo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_centro_custo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_centro_custo** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(100) | Sim | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.chave_api

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_chave`

**Chaves estrangeiras:**

- `id_aplicacao` → `public.aplicacao_api(id_aplicacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_chave** (PK) | integer | Sim | | |
| id_aplicacao | integer | Sim | | |
| nome_chave | character varying(100) | Não | | |
| api_key_hash | text | Sim | | |
| permissoes | jsonb | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.checklist_viagem

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_checklist`

**Chaves estrangeiras:**

- `id_pacote` → `public.pacote_viagem(id_pacote)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_checklist** (PK) | integer | Sim | | |
| id_pacote | integer | Sim | | |
| item | character varying(200) | Não | | |
| responsavel | character varying(100) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| data_execucao | date | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.classificacao_dre

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_classificacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_classificacao** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(150) | Sim | | |
| grupo_dre | character varying(50) | Sim | | |
| ordem_exibicao | integer | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.cliente

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_cliente`

**Chaves estrangeiras:**

- `id_pessoa` → `public.pessoa(id_pessoa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_cliente** (PK) | integer | Sim | | |
| id_pessoa | integer | Sim | | |
| codigo_cliente | character varying(20) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.colaborador

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_colaborador`

**Chaves estrangeiras:**

- `id_cargo` → `public.cargo(id_cargo)`
- `id_pessoa` → `public.pessoa(id_pessoa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_colaborador** (PK) | integer | Sim | | |
| id_pessoa | integer | Sim | | |
| id_cargo | integer | Não | | |
| data_admissao | date | Não | | |
| tipo_vinculo | character varying(50) | Não | | |
| valor_base | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'ATIVO'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.comissao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_comissao`

**Chaves estrangeiras:**

- `id_fornecedor` → `public.fornecedor(id_fornecedor)`
- `id_reserva` → `public.reserva(id_reserva)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_comissao** (PK) | integer | Sim | | |
| id_reserva | integer | Sim | | |
| id_fornecedor | integer | Não | | |
| percentual | numeric(5,2) | Não | | |
| valor_comissao | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.comissao_colaborador

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_comissao`

**Chaves estrangeiras:**

- `id_colaborador` → `public.colaborador(id_colaborador)`
- `id_venda` → `public.venda(id_venda)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_comissao** (PK) | integer | Sim | | |
| id_colaborador | integer | Não | | |
| id_venda | integer | Sim | | |
| percentual | numeric(5,2) | Não | | |
| valor | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| data_pagamento | date | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.conciliacao_bancaria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conciliacao`

**Chaves estrangeiras:**

- `id_conta_bancaria` → `public.conta_bancaria(id_conta_bancaria)`
- `id_lancamento` → `public.lancamento_financeiro(id_lancamento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conciliacao** (PK) | integer | Sim | | |
| id_conta_bancaria | integer | Sim | | |
| data_movimento | date | Sim | | |
| descricao_banco | character varying(200) | Não | | |
| valor | numeric(15,2) | Não | | |
| conciliado | boolean | Não | false | |
| id_lancamento | integer | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.conector_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conector`

**Chaves estrangeiras:**

- `id_sistema_externo` → `public.sistema_externo(id_sistema_externo)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conector** (PK) | integer | Sim | | |
| id_sistema_externo | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| tipo_integracao | character varying(50) | Sim | | |
| protocolo | character varying(30) | Não | | |
| metodo_http | character varying(20) | Não | | |
| endpoint | text | Não | | |
| timeout_segundos | integer | Não | 30 | |
| limite_tentativas | integer | Não | 3 | |
| autenticacao | character varying(50) | Não | | |
| configuracao | jsonb | Não | | |
| ativo | boolean | Não | true | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.configuracao_empresa

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_configuracao`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_configuracao** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| nome_sistema | character varying(100) | Não | | |
| logo | text | Não | | |
| email_padrao | character varying(150) | Não | | |
| telefone_padrao | character varying(30) | Não | | |
| site | character varying(150) | Não | | |
| timezone | character varying(50) | Não | 'America/Sao_Paulo'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |

### public.conformidade_lgpd

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_lgpd`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_lgpd** (PK) | integer | Sim | | |
| tipo_dado | character varying(100) | Não | | |
| finalidade | character varying(200) | Não | | |
| base_legal | character varying(100) | Não | | |
| retencao_dias | integer | Não | | |
| responsavel | character varying(100) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.conta_bancaria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conta_bancaria`

**Chaves estrangeiras:**

- `id_banco` → `public.banco(id_banco)`
- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conta_bancaria** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| banco | character varying(100) | Sim | | |
| codigo_banco | character varying(10) | Não | | |
| agencia | character varying(20) | Não | | |
| numero_conta | character varying(30) | Não | | |
| tipo_conta | character varying(30) | Não | | |
| saldo_inicial | numeric(15,2) | Não | 0 | |
| saldo_atual | numeric(15,2) | Não | 0 | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |
| id_banco | integer | Não | | |

### public.contato_cliente

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_contato`

**Chaves estrangeiras:**

- `id_cliente` → `public.cliente(id_cliente)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_contato** (PK) | integer | Sim | | |
| id_cliente | integer | Não | | |
| tipo_contato | character varying(50) | Não | | |
| descricao | text | Não | | |
| data_contato | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| usuario | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.contrato

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_contrato`

**Chaves estrangeiras:**

- `id_documento` → `public.documento(id_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_contrato** (PK) | integer | Sim | | |
| id_documento | integer | Sim | | |
| parte_contratante | character varying(150) | Não | | |
| parte_contratada | character varying(150) | Não | | |
| data_inicio | date | Não | | |
| data_fim | date | Não | | |
| valor_contrato | numeric(15,2) | Não | | |
| tipo_contrato | character varying(50) | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |

### public.controle_vencimento_documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_controle`

**Chaves estrangeiras:**

- `id_documento` → `public.documento(id_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_controle** (PK) | integer | Sim | | |
| id_documento | integer | Sim | | |
| dias_alerta | integer | Não | 30 | |
| alerta_enviado | boolean | Não | false | |
| data_alerta | date | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.custo_pacote

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_custo`

**Chaves estrangeiras:**

- `id_pacote` → `public.pacote_viagem(id_pacote)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_custo** (PK) | integer | Sim | | |
| id_pacote | integer | Sim | | |
| tipo_custo | character varying(50) | Não | | |
| descricao | character varying(200) | Não | | |
| quantidade | numeric(10,2) | Não | | |
| valor_unitario | numeric(15,2) | Não | | |
| valor_total | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.custo_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_custo_projeto`

**Chaves estrangeiras:**

- `id_projeto` → `public.projeto(id_projeto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_custo_projeto** (PK) | integer | Sim | | |
| id_projeto | integer | Sim | | |
| descricao | character varying(200) | Não | | |
| categoria | character varying(100) | Não | | |
| valor_previsto | numeric(15,2) | Não | | |
| valor_real | numeric(15,2) | Não | | |
| data_lancamento | date | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.das

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_das`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_das** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| competencia | date | Sim | | |
| receita_bruta | numeric(15,2) | Não | | |
| aliquota | numeric(5,2) | Não | | |
| valor_das | numeric(15,2) | Não | | |
| data_vencimento | date | Não | | |
| data_pagamento | date | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.data_mart_execucao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_execucao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_execucao** (PK) | integer | Sim | | |
| processo | character varying(100) | Sim | | |
| data_inicio | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_fim | timestamp without time zone | Não | | |
| registros_processados | integer | Não | 0 | |
| status | character varying(30) | Não | 'PROCESSANDO'::character varying | |
| mensagem | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.declaracao_fiscal

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_declaracao`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_declaracao** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| tipo_declaracao | character varying(50) | Sim | | |
| ano | integer | Não | | |
| periodo | character varying(20) | Não | | |
| data_entrega | date | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Sim | 1 | |

### public.depreciacao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_depreciacao`

**Chaves estrangeiras:**

- `id_ativo` → `public.ativo_imobilizado(id_ativo)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_depreciacao** (PK) | integer | Sim | | |
| id_ativo | integer | Sim | | |
| competencia | date | Sim | | |
| valor_depreciacao | numeric(15,2) | Não | | |
| valor_contabil | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.destino

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_destino`

**Chaves estrangeiras:**

- `id_localidade` → `public.localidade(id_localidade)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_destino** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| nome | character varying(150) | Sim | | |
| descricao | text | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |
| id_localidade | integer | Sim | | |

### public.dim_cliente

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_dim_cliente`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_dim_cliente** (PK) | integer | Sim | | |
| id_cliente_origem | integer | Não | | |
| nome_cliente | character varying(150) | Não | | |
| cidade | character varying(100) | Não | | |
| estado | character varying(50) | Não | | |
| segmento | character varying(50) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.dim_data

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_data`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_data** (PK) | integer | Sim | | |
| data | date | Sim | | |
| ano | integer | Não | | |
| mes | integer | Não | | |
| nome_mes | character varying(20) | Não | | |
| trimestre | integer | Não | | |
| semana | integer | Não | | |
| dia | integer | Não | | |
| dia_semana | character varying(20) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.dim_destino

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_dim_destino`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_dim_destino** (PK) | integer | Sim | | |
| id_destino_origem | integer | Não | | |
| nome_destino | character varying(150) | Não | | |
| cidade | character varying(100) | Não | | |
| estado | character varying(50) | Não | | |
| pais | character varying(50) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.dim_plano_contas

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_dim_plano`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_dim_plano** (PK) | integer | Sim | | |
| id_plano_origem | integer | Não | | |
| codigo | character varying(50) | Não | | |
| descricao | character varying(150) | Não | | |
| grupo | character varying(100) | Não | | |
| categoria | character varying(100) | Não | | |
| natureza | character varying(20) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.dim_produto_turistico

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_dim_produto`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_dim_produto** (PK) | integer | Sim | | |
| id_produto_origem | integer | Não | | |
| nome_produto | character varying(150) | Não | | |
| categoria | character varying(100) | Não | | |
| tipo_produto | character varying(50) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.distribuicao_lucros

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_distribuicao`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_distribuicao** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| data_distribuicao | date | Não | | |
| periodo | character varying(20) | Não | | |
| valor | numeric(15,2) | Não | | |
| socio | character varying(150) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_documento`

**Chaves estrangeiras:**

- `id_tipo_documento` → `public.tipo_documento(id_tipo_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_documento** (PK) | integer | Sim | | |
| id_tipo_documento | integer | Sim | | |
| descricao | character varying(200) | Não | | |
| entidade_tipo | character varying(50) | Não | | |
| entidade_id | integer | Não | | |
| data_documento | date | Não | | |
| data_validade | date | Não | | |
| status | character varying(30) | Não | 'ATIVO'::character varying | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.email_sistema

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_email`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_email** (PK) | integer | Sim | | |
| servidor_smtp | character varying(150) | Não | | |
| porta | integer | Não | | |
| usuario | character varying(150) | Não | | |
| senha_criptografada | text | Não | | |
| email_remetente | character varying(150) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.empresa

Cadastro das empresas pertencentes ao sistema WMA Travel

**Chave primária:** `id_empresa`

**Chaves estrangeiras:**

- `id_localidade` → `public.localidade(id_localidade)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_empresa** (PK) | integer | Sim | | |
| razao_social | character varying(150) | Sim | | |
| nome_fantasia | character varying(100) | Sim | | |
| cnpj | character varying(18) | Não | | |
| inscricao_municipal | character varying(30) | Não | | |
| regime_tributario | character varying(50) | Não | | |
| data_abertura | date | Não | | |
| capital_social | numeric(15,2) | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(150) | Não | | |
| site | character varying(150) | Não | | |
| logradouro | character varying(150) | Não | | |
| numero | character varying(20) | Não | | |
| complemento | character varying(100) | Não | | |
| bairro | character varying(100) | Não | | |
| cep | character varying(10) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Sim | 1 | |
| id_localidade | integer | Sim | | |

### public.estoque

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_estoque`

**Chaves estrangeiras:**

- `id_produto_estoque` → `public.produto_estoque(id_produto_estoque)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_estoque** (PK) | integer | Sim | | |
| id_produto_estoque | integer | Sim | | |
| quantidade_atual | numeric(10,2) | Não | 0 | |
| localizacao | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |

### public.etapa_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_etapa`

**Chaves estrangeiras:**

- `id_projeto` → `public.projeto(id_projeto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_etapa** (PK) | integer | Sim | | |
| id_projeto | integer | Sim | | |
| ordem | integer | Não | | |
| nome | character varying(150) | Não | | |
| descricao | text | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |

### public.fato_financeiro

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fato_financeiro`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fato_financeiro** (PK) | integer | Sim | | |
| data_movimento | date | Sim | | |
| id_lancamento_origem | integer | Não | | |
| id_plano_contas | integer | Não | | |
| id_centro_custo | integer | Não | | |
| tipo_movimento | character varying(30) | Não | | |
| natureza | character varying(20) | Não | | |
| grupo_financeiro | character varying(100) | Não | | |
| categoria_financeira | character varying(100) | Não | | |
| valor | numeric(14,2) | Não | 0 | |
| competencia | date | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.fato_vendas

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fato_venda`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fato_venda** (PK) | integer | Sim | | |
| data_venda | date | Sim | | |
| id_venda_origem | integer | Não | | |
| id_cliente | integer | Não | | |
| id_produto_turistico | integer | Não | | |
| id_destino | integer | Não | | |
| canal_venda | character varying(50) | Não | | |
| quantidade | integer | Não | 1 | |
| valor_bruto | numeric(12,2) | Não | 0 | |
| valor_desconto | numeric(12,2) | Não | 0 | |
| valor_liquido | numeric(12,2) | Não | 0 | |
| custo | numeric(12,2) | Não | 0 | |
| comissao | numeric(12,2) | Não | 0 | |
| margem | numeric(12,2) | Não | 0 | |
| status_venda | character varying(30) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.fila_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fila_integracao`

**Chaves estrangeiras:**

- `id_conector` → `public.conector_integracao(id_conector)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fila_integracao** (PK) | integer | Sim | | |
| id_conector | integer | Sim | | |
| tipo_evento | character varying(100) | Sim | | |
| entidade | character varying(100) | Não | | |
| chave_registro | character varying(100) | Não | | |
| payload | jsonb | Sim | | |
| prioridade | integer | Não | 5 | |
| tentativas | integer | Não | 0 | |
| limite_tentativas | integer | Não | 3 | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| mensagem_erro | text | Não | | |
| data_processamento | timestamp without time zone | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.fila_processamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fila`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fila** (PK) | integer | Sim | | |
| tipo_processo | character varying(100) | Não | | |
| dados | jsonb | Não | | |
| prioridade | integer | Não | 5 | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| tentativas | integer | Não | 0 | |
| data_criacao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_processamento | timestamp without time zone | Não | | |

### public.forma_pagamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_forma_pagamento`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_forma_pagamento** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(100) | Sim | | |
| tipo | character varying(50) | Não | | |
| prazo_dias | integer | Não | 0 | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.fornecedor

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fornecedor`

**Chaves estrangeiras:**

- `id_pessoa` → `public.pessoa(id_pessoa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fornecedor** (PK) | integer | Sim | | |
| id_pessoa | integer | Sim | | |
| codigo_fornecedor | character varying(20) | Não | | |
| tipo_fornecedor | character varying(50) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.fornecedor_turistico

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fornecedor_turistico`

**Chaves estrangeiras:**

- `id_fornecedor` → `public.fornecedor(id_fornecedor)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fornecedor_turistico** (PK) | integer | Sim | | |
| id_fornecedor | integer | Sim | | |
| tipo_fornecedor | character varying(50) | Não | | |
| categoria | character varying(100) | Não | | |
| registro_turismo | character varying(50) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.funil_vendas

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_funil`

**Chaves estrangeiras:**

- `id_lead` → `public.lead(id_lead)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_funil** (PK) | integer | Sim | | |
| id_lead | integer | Sim | | |
| etapa | character varying(50) | Não | | |
| probabilidade | numeric(5,2) | Não | | |
| valor_negociacao | numeric(15,2) | Não | | |
| data_movimento | date | Não | CURRENT_DATE | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.gateway_pagamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_gateway`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_gateway** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(100) | Não | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.grupo_conta

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_grupo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_grupo** (PK) | integer | Sim | | |
| codigo | character varying(10) | Sim | | |
| descricao | character varying(100) | Sim | | |
| natureza | character varying(20) | Sim | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.guia_turistico

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_guia`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_guia** (PK) | integer | Sim | | |
| nome | character varying(150) | Sim | | |
| cadastur | character varying(50) | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(150) | Não | | |
| valor_diaria | numeric(15,2) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.historico_alteracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_historico`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_historico** (PK) | integer | Sim | | |
| tabela_nome | character varying(100) | Não | | |
| registro_id | integer | Não | | |
| campo_alterado | character varying(100) | Não | | |
| valor_anterior | text | Não | | |
| valor_novo | text | Não | | |
| usuario | character varying(100) | Não | | |
| data_alteracao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.historico_documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_historico`

**Chaves estrangeiras:**

- `id_documento` → `public.documento(id_documento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_historico** (PK) | integer | Sim | | |
| id_documento | integer | Sim | | |
| acao | character varying(50) | Não | | |
| descricao | text | Não | | |
| usuario | character varying(100) | Não | | |
| data_evento | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.horas_atividade

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_hora`

**Chaves estrangeiras:**

- `id_colaborador` → `public.colaborador(id_colaborador)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_hora** (PK) | integer | Sim | | |
| id_colaborador | integer | Sim | | |
| data_atividade | date | Não | | |
| atividade | character varying(150) | Não | | |
| quantidade_horas | numeric(5,2) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.hospedagem

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_hospedagem`

**Chaves estrangeiras:**

- `id_fornecedor_turistico` → `public.fornecedor_turistico(id_fornecedor_turistico)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_hospedagem** (PK) | integer | Sim | | |
| id_fornecedor_turistico | integer | Sim | | |
| nome | character varying(150) | Não | | |
| categoria | character varying(50) | Não | | |
| tipo_acomodacao | character varying(100) | Não | | |
| quantidade_quartos | integer | Não | | |
| valor_diaria | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.importacao_dados

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_importacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_importacao** (PK) | integer | Sim | | |
| tipo_importacao | character varying(50) | Não | | |
| nome_arquivo | character varying(255) | Não | | |
| quantidade_registros | integer | Não | | |
| registros_processados | integer | Não | | |
| registros_erro | integer | Não | | |
| status | character varying(30) | Não | | |
| mensagem | text | Não | | |
| data_importacao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.imposto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_imposto`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_imposto** (PK) | integer | Sim | | |
| codigo | character varying(20) | Não | | |
| descricao | character varying(100) | Não | | |
| tipo | character varying(50) | Não | | |
| aliquota | numeric(5,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.integracao_nfse

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_integracao`

**Chaves estrangeiras:**

- `id_nota_fiscal` → `public.nota_fiscal(id_nota_fiscal)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_integracao** (PK) | integer | Sim | | |
| id_nota_fiscal | integer | Sim | | |
| provedor | character varying(100) | Não | | |
| codigo_retorno | character varying(50) | Não | | |
| mensagem | text | Não | | |
| xml_envio | text | Não | | |
| xml_retorno | text | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.integracao_woocommerce

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_integracao`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_integracao** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| id_pedido_externo | character varying(50) | Não | | |
| tipo_evento | character varying(50) | Não | | |
| data_evento | timestamp without time zone | Não | | |
| status | character varying(30) | Não | | |
| json_dados | jsonb | Não | | |
| sincronizado | boolean | Não | false | |
| data_sincronizacao | timestamp without time zone | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.interacao_lead

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_interacao`

**Chaves estrangeiras:**

- `id_lead` → `public.lead(id_lead)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_interacao** (PK) | integer | Sim | | |
| id_lead | integer | Sim | | |
| tipo | character varying(50) | Não | | |
| descricao | text | Não | | |
| data_interacao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| responsavel | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.inventario

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_inventario`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_inventario** (PK) | integer | Sim | | |
| data_inventario | date | Não | CURRENT_DATE | |
| responsavel | character varying(100) | Não | | |
| status | character varying(30) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.item_inventario

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_item`

**Chaves estrangeiras:**

- `id_produto_estoque` → `public.produto_estoque(id_produto_estoque)`
- `id_inventario` → `public.inventario(id_inventario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_item** (PK) | integer | Sim | | |
| id_inventario | integer | Sim | | |
| id_produto_estoque | integer | Sim | | |
| quantidade_sistema | numeric(10,2) | Não | | |
| quantidade_contada | numeric(10,2) | Não | | |
| diferenca | numeric(10,2) | Não | | |

### public.item_pedido_compra

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_item_pedido`

**Chaves estrangeiras:**

- `id_pedido` → `public.pedido_compra(id_pedido)`
- `id_produto_estoque` → `public.produto_estoque(id_produto_estoque)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_item_pedido** (PK) | integer | Sim | | |
| id_pedido | integer | Sim | | |
| id_produto_estoque | integer | Sim | | |
| quantidade | numeric(10,2) | Não | | |
| valor_unitario | numeric(15,2) | Não | | |
| valor_total | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.item_requisicao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_item`

**Chaves estrangeiras:**

- `id_produto_estoque` → `public.produto_estoque(id_produto_estoque)`
- `id_requisicao` → `public.requisicao_compra(id_requisicao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_item** (PK) | integer | Sim | | |
| id_requisicao | integer | Sim | | |
| id_produto_estoque | integer | Sim | | |
| quantidade | numeric(10,2) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.item_venda

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_item`

**Chaves estrangeiras:**

- `id_produto` → `public.produto_turistico(id_produto)`
- `id_venda` → `public.venda(id_venda)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_item** (PK) | integer | Sim | | |
| id_venda | integer | Sim | | |
| id_produto | integer | Sim | | |
| quantidade | integer | Não | 1 | |
| valor_unitario | numeric(15,2) | Não | | |
| valor_total | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.kpi_turismo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_kpi`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_kpi** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| descricao | text | Não | | |
| unidade | character varying(30) | Não | | |
| categoria | character varying(50) | Não | | |
| valor | numeric(14,2) | Não | 0 | |
| periodo | date | Não | | |
| origem | character varying(50) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.lancamento_financeiro

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_lancamento`

**Chaves estrangeiras:**

- `id_conta_bancaria` → `public.conta_bancaria(id_conta_bancaria)`
- `id_categoria` → `public.categoria_conta(id_categoria)`
- `id_centro_custo` → `public.centro_custo(id_centro_custo)`
- `id_empresa` → `public.empresa(id_empresa)`
- `id_grupo` → `public.grupo_conta(id_grupo)`
- `id_forma_pagamento` → `public.forma_pagamento(id_forma_pagamento)`
- `id_pessoa` → `public.pessoa(id_pessoa)`
- `id_conta_plano` → `public.plano_contas(id_conta)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_lancamento** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| tipo_lancamento | character varying(20) | Sim | | |
| descricao | character varying(200) | Sim | | |
| data_lancamento | date | Sim | | |
| data_competencia | date | Sim | | |
| data_pagamento | date | Não | | |
| valor | numeric(15,2) | Sim | | |
| status | character varying(30) | Não | 'ABERTO'::character varying | |
| id_pessoa | integer | Não | | |
| id_conta_bancaria | integer | Não | | |
| id_forma_pagamento | integer | Não | | |
| id_centro_custo | integer | Não | | |
| id_subcategoria | integer | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |
| id_conta_plano | integer | Não | | |
| id_grupo | integer | Não | | |
| id_categoria | integer | Não | | |

### public.lancamento_parcela

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_parcela`

**Chaves estrangeiras:**

- `id_lancamento` → `public.lancamento_financeiro(id_lancamento)`
- `id_status_parcela` → `public.status_parcela(id_status_parcela)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_parcela** (PK) | integer | Sim | | |
| id_lancamento | integer | Sim | | |
| numero_parcela | integer | Sim | | |
| total_parcelas | integer | Sim | | |
| data_vencimento | date | Sim | | |
| data_pagamento | date | Não | | |
| valor_parcela | numeric(15,2) | Sim | | |
| status | character varying(20) | Não | 'ABERTO'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |
| id_status_parcela | integer | Não | | |

### public.lead

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_lead`

**Chaves estrangeiras:**

- `id_origem` → `public.origem_lead(id_origem)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_lead** (PK) | integer | Sim | | |
| id_origem | integer | Não | | |
| nome | character varying(150) | Sim | | |
| email | character varying(150) | Não | | |
| telefone | character varying(30) | Não | | |
| cidade | character varying(100) | Não | | |
| interesse | character varying(150) | Não | | |
| valor_estimado | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'NOVO'::character varying | |
| data_cadastro | date | Não | CURRENT_DATE | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.localidade

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_localidade`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_localidade** (PK) | integer | Sim | | |
| cidade | character varying(100) | Sim | | |
| uf | character(2) | Não | | |
| pais | character varying(100) | Sim | 'Brasil'::character varying | |

### public.localizacao_ativo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_localizacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_localizacao** (PK) | integer | Sim | | |
| codigo | character varying(30) | Não | | |
| descricao | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.log_api

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log`

**Chaves estrangeiras:**

- `id_aplicacao` → `public.aplicacao_api(id_aplicacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | integer | Sim | | |
| id_aplicacao | integer | Não | | |
| endpoint | character varying(255) | Não | | |
| metodo | character varying(20) | Não | | |
| request | jsonb | Não | | |
| response | jsonb | Não | | |
| status_http | integer | Não | | |
| tempo_execucao_ms | integer | Não | | |
| data_execucao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.log_auditoria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | integer | Sim | | |
| tabela_nome | character varying(100) | Sim | | |
| registro_id | integer | Não | | |
| acao | character varying(20) | Sim | | |
| usuario | character varying(100) | Não | | |
| data_evento | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| dados_antigos | jsonb | Não | | |
| dados_novos | jsonb | Não | | |

### public.log_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | integer | Sim | | |
| sistema | character varying(100) | Não | | |
| endpoint | character varying(255) | Não | | |
| metodo | character varying(20) | Não | | |
| request | jsonb | Não | | |
| response | jsonb | Não | | |
| status_http | integer | Não | | |
| data_execucao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.log_integracao_detalhado

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log_integracao`

**Chaves estrangeiras:**

- `id_conector` → `public.conector_integracao(id_conector)`
- `id_sincronizacao` → `public.sincronizacao_integracao(id_sincronizacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log_integracao** (PK) | integer | Sim | | |
| id_conector | integer | Sim | | |
| id_sincronizacao | integer | Não | | |
| tipo_operacao | character varying(50) | Sim | | |
| endpoint | text | Não | | |
| metodo_http | character varying(20) | Não | | |
| requisicao | jsonb | Não | | |
| resposta | jsonb | Não | | |
| codigo_http | integer | Não | | |
| tempo_resposta_ms | integer | Não | | |
| status | character varying(30) | Não | 'PROCESSANDO'::character varying | |
| mensagem_erro | text | Não | | |
| data_execucao | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.log_sistema

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | integer | Sim | | |
| nivel | character varying(20) | Não | | |
| modulo | character varying(100) | Não | | |
| mensagem | text | Não | | |
| stack_trace | text | Não | | |
| usuario | character varying(100) | Não | | |
| data_evento | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.manutencao_ativo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_manutencao`

**Chaves estrangeiras:**

- `id_ativo` → `public.ativo_imobilizado(id_ativo)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_manutencao** (PK) | integer | Sim | | |
| id_ativo | integer | Sim | | |
| data_manutencao | date | Não | | |
| tipo | character varying(50) | Não | | |
| descricao | text | Não | | |
| valor | numeric(15,2) | Não | | |
| fornecedor | character varying(150) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.mapeamento_campo_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_mapeamento`

**Chaves estrangeiras:**

- `id_conector` → `public.conector_integracao(id_conector)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_mapeamento** (PK) | integer | Sim | | |
| id_conector | integer | Sim | | |
| entidade_interna | character varying(100) | Sim | | |
| campo_interno | character varying(100) | Sim | | |
| entidade_externa | character varying(100) | Não | | |
| campo_externo | character varying(150) | Sim | | |
| tipo_dado | character varying(50) | Não | | |
| regra_transformacao | text | Não | | |
| obrigatorio | boolean | Não | false | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.modelo_ml

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_modelo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_modelo** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| tipo_modelo | character varying(50) | Não | | |
| algoritmo | character varying(100) | Não | | |
| versao_modelo | character varying(30) | Não | | |
| status | character varying(30) | Não | 'DESENVOLVIMENTO'::character varying | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.movimentacao_ativo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_movimentacao`

**Chaves estrangeiras:**

- `id_ativo` → `public.ativo_imobilizado(id_ativo)`
- `id_localizacao` → `public.localizacao_ativo(id_localizacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_movimentacao** (PK) | integer | Sim | | |
| id_ativo | integer | Sim | | |
| id_localizacao | integer | Não | | |
| tipo_movimento | character varying(50) | Não | | |
| data_movimento | date | Não | | |
| responsavel | character varying(100) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.movimento_estoque

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_movimento`

**Chaves estrangeiras:**

- `id_produto_estoque` → `public.produto_estoque(id_produto_estoque)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_movimento** (PK) | integer | Sim | | |
| id_produto_estoque | integer | Sim | | |
| tipo_movimento | character varying(20) | Não | | |
| quantidade | numeric(10,2) | Não | | |
| origem | character varying(100) | Não | | |
| data_movimento | date | Não | CURRENT_DATE | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.nota_fiscal

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_nota_fiscal`

**Chaves estrangeiras:**

- `id_cliente` → `public.cliente(id_cliente)`
- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_nota_fiscal** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| id_cliente | integer | Não | | |
| numero_nf | character varying(30) | Não | | |
| serie | character varying(10) | Não | | |
| tipo_documento | character varying(30) | Não | | |
| data_emissao | date | Sim | | |
| competencia | date | Sim | | |
| valor_servico | numeric(15,2) | Não | | |
| base_calculo | numeric(15,2) | Não | | |
| valor_iss | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'EMITIDA'::character varying | |
| chave_acesso | character varying(100) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.notificacao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_notificacao`

**Chaves estrangeiras:**

- `id_usuario` → `public.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_notificacao** (PK) | integer | Sim | | |
| id_usuario | integer | Não | | |
| titulo | character varying(150) | Não | | |
| mensagem | text | Não | | |
| tipo | character varying(30) | Não | | |
| lida | boolean | Não | false | |
| data_envio | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.openfinance_conexao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conexao`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conexao** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| instituicao | character varying(100) | Não | | |
| token_api | text | Não | | |
| data_expiracao | timestamp without time zone | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.openfinance_movimento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_movimento`

**Chaves estrangeiras:**

- `id_conexao` → `public.openfinance_conexao(id_conexao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_movimento** (PK) | integer | Sim | | |
| id_conexao | integer | Não | | |
| data_movimento | date | Não | | |
| descricao | character varying(200) | Não | | |
| valor | numeric(15,2) | Não | | |
| tipo | character varying(20) | Não | | |
| conciliado | boolean | Não | false | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.origem_lead

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_origem`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_origem** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(100) | Sim | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.pacote_viagem

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_pacote`

**Chaves estrangeiras:**

- `id_produto` → `public.produto_turistico(id_produto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_pacote** (PK) | integer | Sim | | |
| id_produto | integer | Sim | | |
| codigo_pacote | character varying(30) | Não | | |
| data_inicio | date | Não | | |
| data_fim | date | Não | | |
| quantidade_vagas | integer | Não | | |
| valor_venda | numeric(15,2) | Não | | |
| custo_estimado | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'ATIVO'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.pagamento_transacao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_transacao`

**Chaves estrangeiras:**

- `id_gateway` → `public.gateway_pagamento(id_gateway)`
- `id_venda` → `public.venda(id_venda)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_transacao** (PK) | integer | Sim | | |
| id_venda | integer | Sim | | |
| id_gateway | integer | Não | | |
| codigo_transacao | character varying(100) | Não | | |
| valor | numeric(15,2) | Não | | |
| status | character varying(30) | Não | | |
| data_pagamento | timestamp without time zone | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.parametro_sistema

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_parametro`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_parametro** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| descricao | character varying(150) | Não | | |
| valor | character varying(255) | Não | | |
| tipo | character varying(30) | Não | | |
| grupo | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.parceiro_comercial

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_parceiro`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_parceiro** (PK) | integer | Sim | | |
| nome | character varying(150) | Sim | | |
| documento | character varying(30) | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(150) | Não | | |
| percentual_comissao | numeric(5,2) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.passageiro

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_passageiro`

**Chaves estrangeiras:**

- `id_reserva` → `public.reserva(id_reserva)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_passageiro** (PK) | integer | Sim | | |
| id_reserva | integer | Sim | | |
| nome | character varying(150) | Sim | | |
| cpf | character varying(14) | Não | | |
| data_nascimento | date | Não | | |
| documento | character varying(30) | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.pedido_compra

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_pedido`

**Chaves estrangeiras:**

- `id_fornecedor` → `public.fornecedor(id_fornecedor)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_pedido** (PK) | integer | Sim | | |
| numero_pedido | character varying(30) | Não | | |
| id_fornecedor | integer | Sim | | |
| data_pedido | date | Não | CURRENT_DATE | |
| valor_total | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.perfil_acesso

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_perfil`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_perfil** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(100) | Sim | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.permissao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_permissao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_permissao** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| descricao | character varying(150) | Sim | | |
| modulo | character varying(50) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.pessoa

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_pessoa`

**Chaves estrangeiras:**

- `id_localidade` → `public.localidade(id_localidade)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_pessoa** (PK) | integer | Sim | | |
| tipo_pessoa | character varying(20) | Sim | | |
| nome_razao_social | character varying(150) | Sim | | |
| nome_fantasia | character varying(100) | Não | | |
| cpf_cnpj | character varying(18) | Não | | |
| rg_ie | character varying(30) | Não | | |
| data_nascimento | date | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(150) | Não | | |
| logradouro | character varying(150) | Não | | |
| numero | character varying(20) | Não | | |
| bairro | character varying(100) | Não | | |
| cep | character varying(10) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |
| id_localidade | integer | Sim | | |

### public.plano_contas

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conta`

**Chaves estrangeiras:**

- `id_conta_pai` → `public.plano_contas(id_conta)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conta** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| nivel | integer | Sim | | |
| descricao | character varying(150) | Sim | | |
| id_conta_pai | integer | Não | | |
| natureza | character varying(20) | Não | | |
| tipo_conta | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.politica_acesso

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_politica`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_politica** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| descricao | character varying(150) | Não | | |
| modulo | character varying(100) | Não | | |
| acao | character varying(50) | Não | | |
| nivel | character varying(30) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.pro_labore

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_pro_labore`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_pro_labore** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| competencia | date | Não | | |
| socio | character varying(150) | Não | | |
| valor_bruto | numeric(15,2) | Não | | |
| inss | numeric(15,2) | Não | | |
| irrf | numeric(15,2) | Não | | |
| valor_liquido | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.produto_estoque

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_produto_estoque`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_produto_estoque** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(150) | Sim | | |
| categoria | character varying(50) | Não | | |
| unidade_medida | character varying(20) | Não | | |
| estoque_minimo | numeric(10,2) | Não | 0 | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.produto_turistico

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_produto`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_produto** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| nome | character varying(150) | Sim | | |
| tipo_produto | character varying(50) | Sim | | |
| descricao | text | Não | | |
| duracao_dias | integer | Não | | |
| destino | character varying(150) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_projeto`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_projeto** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| nome | character varying(200) | Sim | | |
| descricao | text | Não | | |
| tipo_projeto | character varying(50) | Não | | |
| data_inicio | date | Não | | |
| data_fim_prevista | date | Não | | |
| data_fim_real | date | Não | | |
| status | character varying(30) | Não | 'PLANEJAMENTO'::character varying | |
| orcamento | numeric(15,2) | Não | | |
| responsavel | character varying(100) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.rastreabilidade

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_rastreabilidade`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_rastreabilidade** (PK) | integer | Sim | | |
| origem | character varying(100) | Não | | |
| evento | character varying(100) | Não | | |
| referencia | character varying(100) | Não | | |
| descricao | text | Não | | |
| usuario | character varying(100) | Não | | |
| data_evento | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| versao | integer | Não | 1 | |

### public.rate_limit_api

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_rate`

**Chaves estrangeiras:**

- `id_aplicacao` → `public.aplicacao_api(id_aplicacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_rate** (PK) | integer | Sim | | |
| id_aplicacao | integer | Sim | | |
| limite_requisicoes | integer | Não | | |
| periodo_segundos | integer | Não | | |
| ativo | boolean | Não | true | |

### public.rentabilidade_produto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_rentabilidade`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_rentabilidade** (PK) | integer | Sim | | |
| periodo | date | Sim | | |
| id_produto_origem | integer | Não | | |
| id_destino_origem | integer | Não | | |
| receita_total | numeric(14,2) | Não | 0 | |
| custo_total | numeric(14,2) | Não | 0 | |
| comissao_total | numeric(14,2) | Não | 0 | |
| lucro_bruto | numeric(14,2) | Não | 0 | |
| margem_percentual | numeric(6,2) | Não | 0 | |
| quantidade_vendida | integer | Não | 0 | |
| roi_percentual | numeric(6,2) | Não | 0 | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.requisicao_compra

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_requisicao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_requisicao** (PK) | integer | Sim | | |
| numero_requisicao | character varying(30) | Não | | |
| data_solicitacao | date | Não | CURRENT_DATE | |
| solicitante | character varying(100) | Não | | |
| status | character varying(30) | Não | 'ABERTA'::character varying | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.reserva

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_reserva`

**Chaves estrangeiras:**

- `id_cliente` → `public.cliente(id_cliente)`
- `id_pacote` → `public.pacote_viagem(id_pacote)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_reserva** (PK) | integer | Sim | | |
| codigo_reserva | character varying(30) | Sim | | |
| id_cliente | integer | Sim | | |
| id_pacote | integer | Sim | | |
| data_reserva | date | Sim | | |
| quantidade_passageiros | integer | Não | 1 | |
| valor_total | numeric(15,2) | Não | | |
| status | character varying(30) | Não | 'PENDENTE'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.responsavel_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_responsavel`

**Chaves estrangeiras:**

- `id_colaborador` → `public.colaborador(id_colaborador)`
- `id_projeto` → `public.projeto(id_projeto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_responsavel** (PK) | integer | Sim | | |
| id_projeto | integer | Sim | | |
| id_colaborador | integer | Não | | |
| papel | character varying(50) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.risco_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_risco`

**Chaves estrangeiras:**

- `id_projeto` → `public.projeto(id_projeto)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_risco** (PK) | integer | Sim | | |
| id_projeto | integer | Sim | | |
| descricao | text | Não | | |
| probabilidade | character varying(20) | Não | | |
| impacto | character varying(20) | Não | | |
| acao_mitigacao | text | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.roteiro_viagem

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_roteiro`

**Chaves estrangeiras:**

- `id_destino` → `public.destino(id_destino)`
- `id_pacote` → `public.pacote_viagem(id_pacote)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_roteiro** (PK) | integer | Sim | | |
| id_pacote | integer | Sim | | |
| id_destino | integer | Sim | | |
| titulo | character varying(150) | Não | | |
| descricao | text | Não | | |
| dia_inicio | date | Não | | |
| dia_fim | date | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.sequencia_documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_sequencia`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_sequencia** (PK) | integer | Sim | | |
| tipo_documento | character varying(50) | Não | | |
| ano | integer | Não | | |
| proximo_numero | integer | Não | 1 | |
| prefixo | character varying(20) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |

### public.simples_nacional

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_simples`

**Chaves estrangeiras:**

- `id_empresa` → `public.empresa(id_empresa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_simples** (PK) | integer | Sim | | |
| id_empresa | integer | Sim | | |
| ano | integer | Sim | | |
| anexo | character varying(10) | Não | | |
| aliquota_efetiva | numeric(5,2) | Não | | |
| faturamento_12_meses | numeric(15,2) | Não | | |
| faixa | integer | Não | | |
| rbt12 | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.sincronizacao_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_sincronizacao`

**Chaves estrangeiras:**

- `id_conector` → `public.conector_integracao(id_conector)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_sincronizacao** (PK) | integer | Sim | | |
| id_conector | integer | Sim | | |
| tipo_operacao | character varying(30) | Sim | | |
| entidade | character varying(100) | Não | | |
| data_inicio | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| data_fim | timestamp without time zone | Não | | |
| quantidade_processada | integer | Não | 0 | |
| quantidade_sucesso | integer | Não | 0 | |
| quantidade_erro | integer | Não | 0 | |
| status | character varying(30) | Não | 'PROCESSANDO'::character varying | |
| mensagem_retorno | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.sistema_externo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_sistema_externo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_sistema_externo** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| tipo_sistema | character varying(50) | Sim | | |
| fornecedor | character varying(150) | Não | | |
| url_api | text | Não | | |
| ambiente | character varying(30) | Não | 'PRODUCAO'::character varying | |
| autenticacao | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.status_integracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_status_integracao`

**Chaves estrangeiras:**

- `id_conector` → `public.conector_integracao(id_conector)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_status_integracao** (PK) | integer | Sim | | |
| id_conector | integer | Sim | | |
| ultima_execucao | timestamp without time zone | Não | | |
| ultima_situacao | character varying(30) | Não | | |
| total_execucoes | integer | Não | 0 | |
| total_sucesso | integer | Não | 0 | |
| total_erro | integer | Não | 0 | |
| percentual_sucesso | numeric(5,2) | Não | 0 | |
| tempo_medio_resposta_ms | integer | Não | 0 | |
| disponivel | boolean | Não | true | |
| mensagem_status | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.status_parcela

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_status_parcela`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_status_parcela** (PK) | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(60) | Sim | | |

### public.subcategoria_conta

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_subcategoria`

**Chaves estrangeiras:**

- `id_categoria` → `public.categoria_conta(id_categoria)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_subcategoria** (PK) | integer | Sim | | |
| id_categoria | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(150) | Sim | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.tarefa

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tarefa`

**Chaves estrangeiras:**

- `responsavel` → `public.colaborador(id_colaborador)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tarefa** (PK) | integer | Sim | | |
| titulo | character varying(200) | Sim | | |
| descricao | text | Não | | |
| responsavel | integer | Não | | |
| prioridade | character varying(20) | Não | | |
| status | character varying(30) | Não | 'ABERTA'::character varying | |
| data_limite | date | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.tarefa_projeto

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tarefa_projeto`

**Chaves estrangeiras:**

- `id_etapa` → `public.etapa_projeto(id_etapa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tarefa_projeto** (PK) | integer | Sim | | |
| id_etapa | integer | Sim | | |
| titulo | character varying(200) | Não | | |
| descricao | text | Não | | |
| prioridade | character varying(20) | Não | | |
| responsavel | character varying(100) | Não | | |
| data_inicio | date | Não | | |
| data_limite | date | Não | | |
| percentual_conclusao | integer | Não | 0 | |
| status | character varying(30) | Não | 'ABERTA'::character varying | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |

### public.tipo_documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tipo_documento`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tipo_documento** (PK) | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(150) | Sim | | |
| categoria | character varying(50) | Não | | |
| prazo_validade_dias | integer | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.token_acesso

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_token`

**Chaves estrangeiras:**

- `id_aplicacao` → `public.aplicacao_api(id_aplicacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_token** (PK) | integer | Sim | | |
| id_aplicacao | integer | Sim | | |
| token_hash | text | Sim | | |
| data_criacao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_expiracao | timestamp without time zone | Não | | |
| revogado | boolean | Não | false | |

### public.transporte

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_transporte`

**Chaves estrangeiras:**

- `id_fornecedor_turistico` → `public.fornecedor_turistico(id_fornecedor_turistico)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_transporte** (PK) | integer | Sim | | |
| id_fornecedor_turistico | integer | Não | | |
| tipo_transporte | character varying(50) | Não | | |
| empresa | character varying(150) | Não | | |
| placa | character varying(20) | Não | | |
| capacidade | integer | Não | | |
| valor_contratado | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.usuario

Usuários autorizados do sistema

**Chave primária:** `id_usuario`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_usuario** (PK) | integer | Sim | | |
| nome | character varying(100) | Sim | | |
| email | character varying(150) | Sim | | |
| senha_hash | character varying(255) | Não | | |
| perfil | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.usuario_perfil

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_usuario, id_perfil`

**Chaves estrangeiras:**

- `id_perfil` → `public.perfil_acesso(id_perfil)`
- `id_usuario` → `public.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_usuario** (PK) | integer | Sim | | |
| **id_perfil** (PK) | integer | Sim | | |
| data_inicio | date | Não | CURRENT_DATE | |
| data_fim | date | Não | | |

### public.v_total

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| count | bigint | Não | | |

### public.venda

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_venda`

**Chaves estrangeiras:**

- `id_cliente` → `public.cliente(id_cliente)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_venda** (PK) | integer | Sim | | |
| numero_venda | character varying(30) | Sim | | |
| id_cliente | integer | Sim | | |
| data_venda | date | Sim | | |
| valor_bruto | numeric(15,2) | Não | | |
| desconto | numeric(15,2) | Não | 0 | |
| valor_liquido | numeric(15,2) | Não | | |
| status | character varying(30) | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Não | 1 | |

### public.webhook

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_webhook`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_webhook** (PK) | integer | Sim | | |
| sistema_origem | character varying(100) | Não | | |
| evento | character varying(100) | Não | | |
| url_destino | text | Não | | |
| ativo | boolean | Não | true | |
| ultimo_evento | timestamp without time zone | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |

### public.workflow

Cadastro dos fluxos de trabalho do ERP

**Chave primária:** `id_workflow`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_workflow** (PK) | integer | Sim | | |
| codigo | character varying(50) | Sim | | Código único do workflow |
| nome | character varying(150) | Sim | | |
| descricao | text | Não | | |
| modulo | character varying(100) | Sim | | Módulo do ERP responsável pelo workflow |
| ativo | boolean | Sim | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | character varying(100) | Não | | |
| updated_by | character varying(100) | Não | | |
| deleted_by | character varying(100) | Não | | |
| versao | integer | Sim | 1 | |

---

## 5. Schema `financeiro`

Módulo financeiro: lançamentos, pagamentos, contas, centros de custo, conciliação bancária e rateio.

**Total de tabelas:** 26

### financeiro.anexo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_anexo`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `id_lancamento` → `financeiro.lancamento(id_lancamento)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_anexo** (PK) | bigint | Sim | | |
| id_lancamento | bigint | Sim | | |
| nome_original | character varying(255) | Não | | |
| nome_servidor | character varying(255) | Não | | |
| extensao | character varying(20) | Não | | |
| tamanho | bigint | Não | | |
| mime_type | character varying(100) | Não | | |
| caminho | text | Não | | |
| data_upload | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.banco

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_banco`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_banco** (PK) | integer | Sim | | |
| codigo_banco | character varying(10) | Não | | |
| nome | character varying(120) | Sim | | |
| ativo | boolean | Não | true | |

### financeiro.categoria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_categoria`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `id_grupo` → `financeiro.grupo(id_grupo)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_categoria** (PK) | integer | Sim | | |
| id_grupo | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(120) | Sim | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.centro_custo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_centro_custo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_centro_custo** (PK) | integer | Sim | | |
| codigo | character varying(20) | Não | | |
| descricao | character varying(150) | Sim | | |
| ativo | boolean | Não | true | |

### financeiro.classificacao

Tabela de Classificações Financeiras do Plano de Contas

**Chave primária:** `id_classificacao`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `id_subcategoria` → `financeiro.subcategoria(id_subcategoria)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_classificacao** (PK) | integer | Sim | | |
| id_subcategoria | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(180) | Sim | | |
| ativo | boolean | Não | true | |
| id_natureza_financeira | integer | Não | | FK para Natureza Financeira |
| id_tipo_dre | integer | Não | | FK para Tipo DRE |
| ordem_dre | smallint | Não | 0 | Ordem de exibição na DRE |
| gera_fluxo_caixa | boolean | Não | true | Indica se participa do Fluxo de Caixa |
| gera_dre | boolean | Não | true | Indica se participa da DRE |
| aceita_cliente | boolean | Não | false | Permite vínculo com Cliente |
| aceita_fornecedor | boolean | Não | false | Permite vínculo com Fornecedor |
| aceita_centro_custo | boolean | Não | true | Permite Centro de Custo |
| aceita_conta_bancaria | boolean | Não | true | Permite Conta Bancária |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp without time zone | Não | | Data da última alteração |
| created_by | integer | Não | | Usuário criador |
| updated_by | integer | Não | | Usuário que alterou |
| deleted_at | timestamp without time zone | Não | | Soft Delete |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.cliente

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_cliente`

**Chaves estrangeiras:**

- `id_pessoa` → `public.pessoa(id_pessoa)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_cliente** (PK) | integer | Sim | | |
| nome | character varying(150) | Sim | | |
| cpf_cnpj | character varying(20) | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(120) | Não | | |
| cidade | character varying(80) | Não | | |
| uf | character(2) | Não | | |
| ativo | boolean | Não | true | |
| id_pessoa | integer | Sim | | |

### financeiro.conciliacao_bancaria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conciliacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conciliacao** (PK) | bigint | Sim | | |
| id_movimento | bigint | Sim | | |
| data_conciliacao | date | Não | | |
| conciliado | boolean | Não | false | |
| observacao | text | Não | | |

### financeiro.configuracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_configuracao`

**Chaves estrangeiras:**

- `empresa_padrao` → `financeiro.empresa(id_empresa)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_configuracao** (PK) | integer | Sim | | |
| empresa_padrao | integer | Não | | |
| moeda | character varying(10) | Não | 'BRL'::character varying | |
| idioma | character varying(10) | Não | 'pt-BR'::character varying | |
| tema | character varying(20) | Não | 'Claro'::character varying | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.conta

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conta`

**Chaves estrangeiras:**

- `id_classificacao` → `financeiro.classificacao(id_classificacao)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conta** (PK) | integer | Sim | | |
| id_classificacao | integer | Sim | | |
| codigo | character varying(20) | Sim | | |
| descricao | character varying(180) | Sim | | |
| aceita_lancamento | boolean | Não | true | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.conta_bancaria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conta_bancaria`

**Chaves estrangeiras:**

- `id_banco` → `financeiro.banco(id_banco)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conta_bancaria** (PK) | integer | Sim | | |
| id_banco | integer | Sim | | |
| agencia | character varying(20) | Não | | |
| conta | character varying(30) | Não | | |
| digito | character varying(5) | Não | | |
| tipo | character varying(20) | Não | | |
| pix | character varying(150) | Não | | |
| saldo_inicial | numeric(15,2) | Não | 0 | |
| ativo | boolean | Não | true | |

### financeiro.empresa

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_empresa`

**Chaves estrangeiras:**

- `id_localidade` → `public.localidade(id_localidade)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_empresa** (PK) | integer | Sim | | |
| razao_social | character varying(150) | Sim | | |
| nome_fantasia | character varying(150) | Não | | |
| cnpj | character(14) | Não | | |
| inscricao_estadual | character varying(30) | Não | | |
| inscricao_municipal | character varying(30) | Não | | |
| telefone | character varying(20) | Não | | |
| email | character varying(150) | Não | | |
| site | character varying(150) | Não | | |
| cep | character varying(10) | Não | | |
| endereco | character varying(150) | Não | | |
| numero | character varying(20) | Não | | |
| complemento | character varying(100) | Não | | |
| bairro | character varying(80) | Não | | |
| cidade | character varying(80) | Não | | |
| uf | character(2) | Não | | |
| ativo | boolean | Não | true | |
| data_cadastro | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_alteracao | timestamp without time zone | Não | | |
| id_localidade | integer | Não | | |

### financeiro.forma_pagamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_forma_pagamento`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_forma_pagamento** (PK) | integer | Sim | | |
| descricao | character varying(80) | Sim | | |
| ativo | boolean | Não | true | |

### financeiro.fornecedor

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fornecedor`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fornecedor** (PK) | integer | Sim | | |
| nome | character varying(150) | Sim | | |
| cpf_cnpj | character varying(20) | Não | | |
| telefone | character varying(30) | Não | | |
| email | character varying(120) | Não | | |
| cidade | character varying(80) | Não | | |
| uf | character(2) | Não | | |
| ativo | boolean | Não | true | |

### financeiro.grupo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_grupo`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_grupo** (PK) | integer | Sim | | |
| codigo | character varying(10) | Sim | | |
| descricao | character varying(120) | Sim | | |
| natureza | character(1) | Sim | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.historico_lancamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_historico`

**Chaves estrangeiras:**

- `id_lancamento` → `financeiro.lancamento(id_lancamento)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`
- `id_usuario` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_historico** (PK) | bigint | Sim | | |
| id_lancamento | bigint | Sim | | |
| id_usuario | integer | Não | | |
| operacao | character varying(40) | Não | | |
| antes | jsonb | Não | | |
| depois | jsonb | Não | | |
| data_hora | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.lancamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_lancamento`

**Chaves estrangeiras:**

- `id_cliente` → `financeiro.cliente(id_cliente)`
- `id_conta` → `financeiro.conta(id_conta)`
- `id_conta_bancaria` → `financeiro.conta_bancaria(id_conta_bancaria)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `id_empresa` → `financeiro.empresa(id_empresa)`
- `id_forma_pagamento` → `financeiro.forma_pagamento(id_forma_pagamento)`
- `id_fornecedor` → `financeiro.fornecedor(id_fornecedor)`
- `id_status` → `financeiro.status_lancamento(id_status)`
- `id_tipo_lancamento` → `financeiro.tipo_lancamento(id_tipo_lancamento)`
- `id_tipo_documento` → `financeiro.tipo_documento(id_tipo_documento)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_lancamento** (PK) | bigint | Sim | | |
| numero | character varying(30) | Sim | | |
| id_empresa | integer | Sim | | |
| id_tipo_lancamento | smallint | Sim | | |
| id_status | smallint | Sim | | |
| id_conta | integer | Sim | | |
| id_cliente | integer | Não | | |
| id_fornecedor | integer | Não | | |
| id_conta_bancaria | integer | Não | | |
| id_forma_pagamento | integer | Não | | |
| id_tipo_documento | smallint | Não | | |
| competencia | date | Sim | | |
| emissao | date | Sim | | |
| vencimento | date | Sim | | |
| pagamento | date | Não | | |
| documento | character varying(100) | Não | | |
| descricao | character varying(300) | Não | | |
| observacao | text | Não | | |
| valor_bruto | numeric(15,2) | Sim | | |
| desconto | numeric(15,2) | Não | 0 | |
| acrescimo | numeric(15,2) | Não | 0 | |
| juros | numeric(15,2) | Não | 0 | |
| multa | numeric(15,2) | Não | 0 | |
| valor_liquido | numeric(15,2) GENERATED ALWAYS AS (((((valor_bruto - desconto) + acrescimo) + juros) + multa)) STORED | Não | | |
| valor_pago | numeric(15,2) | Não | 0 | |
| saldo | numeric(15,2) GENERATED ALWAYS AS ((((((valor_bruto - desconto) + acrescimo) + juros) + multa) - valor_pago)) STORED | Não | | |
| ativo | boolean | Não | true | |
| data_cadastro | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| data_alteracao | timestamp without time zone | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.lancamento_parcela

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_parcela`

**Chaves estrangeiras:**

- `id_lancamento` → `financeiro.lancamento(id_lancamento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_parcela** (PK) | bigint | Sim | | |
| id_lancamento | bigint | Sim | | |
| numero_parcela | integer | Sim | | |
| vencimento | date | Sim | | |
| valor | numeric(15,2) | Sim | | |
| valor_pago | numeric(15,2) | Não | 0 | |
| saldo | numeric(15,2) | Não | | |
| id_status | smallint | Não | | |
| observacao | text | Não | | |

### financeiro.movimentacao_bancaria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_movimento`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`
- `id_conta_bancaria` → `financeiro.conta_bancaria(id_conta_bancaria)`
- `id_pagamento` → `financeiro.pagamento(id_pagamento)`
- `id_tipo_movimentacao` → `financeiro.tipo_movimentacao(id_tipo_movimentacao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_movimento** (PK) | bigint | Sim | | |
| id_conta_bancaria | integer | Sim | | |
| id_pagamento | bigint | Não | | |
| id_tipo_movimentacao | smallint | Sim | | |
| data_movimento | date | Não | | |
| valor | numeric(15,2) | Não | | |
| saldo_anterior | numeric(15,2) | Não | | |
| saldo_atual | numeric(15,2) | Não | | |
| historico | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.pagamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_pagamento`

**Chaves estrangeiras:**

- `id_conta_bancaria` → `financeiro.conta_bancaria(id_conta_bancaria)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `id_forma_pagamento` → `financeiro.forma_pagamento(id_forma_pagamento)`
- `id_parcela` → `financeiro.lancamento_parcela(id_parcela)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_pagamento** (PK) | bigint | Sim | | |
| id_parcela | bigint | Sim | | |
| id_conta_bancaria | integer | Sim | | |
| id_forma_pagamento | integer | Sim | | |
| data_pagamento | date | Sim | | |
| valor | numeric(15,2) | Sim | | |
| juros | numeric(15,2) | Não | 0 | |
| desconto | numeric(15,2) | Não | 0 | |
| multa | numeric(15,2) | Não | 0 | |
| documento | character varying(100) | Não | | |
| observacao | text | Não | | |
| data_cadastro | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.rateio_centro_custo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_rateio`

**Chaves estrangeiras:**

- `id_centro_custo` → `financeiro.centro_custo(id_centro_custo)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`
- `id_lancamento` → `financeiro.lancamento(id_lancamento)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_rateio** (PK) | bigint | Sim | | |
| id_lancamento | bigint | Sim | | |
| id_centro_custo | integer | Sim | | |
| percentual | numeric(6,2) | Não | | |
| valor | numeric(15,2) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.status_lancamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_status`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_status** (PK) | smallint | Sim | | |
| codigo | character varying(20) | Não | | |
| descricao | character varying(80) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.subcategoria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_subcategoria`

**Chaves estrangeiras:**

- `id_categoria` → `financeiro.categoria(id_categoria)`
- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_subcategoria** (PK) | integer | Sim | | |
| id_categoria | integer | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(150) | Sim | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.tipo_documento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tipo_documento`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tipo_documento** (PK) | smallint | Sim | | |
| codigo | character varying(20) | Não | | |
| descricao | character varying(80) | Não | | |
| ativo | boolean | Não | true | |

### financeiro.tipo_lancamento

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tipo_lancamento`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tipo_lancamento** (PK) | smallint | Sim | | |
| codigo | character varying(10) | Sim | | |
| descricao | character varying(80) | Sim | | |
| natureza | character(1) | Sim | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.tipo_movimentacao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tipo_movimentacao`

**Chaves estrangeiras:**

- `created_by` → `financeiro.usuario(id_usuario)`
- `deleted_by` → `financeiro.usuario(id_usuario)`
- `updated_by` → `financeiro.usuario(id_usuario)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tipo_movimentacao** (PK) | smallint | Sim | | |
| codigo | character varying(20) | Não | | |
| descricao | character varying(80) | Não | | |
| entrada_saida | character(1) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### financeiro.usuario

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_usuario`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_usuario** (PK) | integer | Sim | | |
| nome | character varying(120) | Sim | | |
| email | character varying(120) | Sim | | |
| senha_hash | text | Sim | | |
| administrador | boolean | Não | false | |
| ativo | boolean | Não | true | |
| data_cadastro | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| ultimo_login | timestamp without time zone | Não | | |

---

## 6. Schema `auditoria`

Governança, auditoria técnica, health check e conformidade estrutural do banco (change-log, framework de score ICB
e certificação estrutural "Etapa 10.4.x").

**Total de tabelas:** 34

### auditoria.auditoria_pos_padronizacao_10_4_5

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_auditoria`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_auditoria** (PK) | bigint | Sim | | |
| id_mapa | bigint | Não | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |
| schema_name | character varying(63) | Sim | | |
| table_name | character varying(63) | Sim | | |
| constraint_name_sugerido | character varying(255) | Não | | |
| constraint_name_fisico | character varying(63) | Não | | |
| constraint_type | character varying(30) | Sim | | |
| colunas | text | Não | | |
| tabela_referenciada | character varying(63) | Não | | |
| colunas_referenciadas | text | Não | | |
| definicao_constraint | text | Não | | |
| encontrada | boolean | Sim | false | |
| nome_exato | boolean | Sim | false | |
| nome_truncado | boolean | Sim | false | |
| nome_divergente | boolean | Sim | false | |
| constraint_validada | boolean | Não | | |
| integridade_ok | boolean | Não | | |
| duplicada | boolean | Sim | false | |
| colisao | boolean | Sim | false | |
| resultado | character varying(30) | Sim | | |
| observacao | text | Não | | |

### auditoria.catalogo_coluna

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_coluna`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_coluna** (PK) | bigint | Sim | | |
| id_tabela | bigint | Não | | |
| nome | character varying(120) | Não | | |
| tipo | character varying(80) | Não | | |
| tamanho | integer | Não | | |
| nullable | boolean | Não | | |
| default_value | text | Não | | |
| pk | boolean | Não | | |
| fk | boolean | Não | | |
| unique_key | boolean | Não | | |
| indice | boolean | Não | | |
| comentario | text | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.catalogo_schema

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_schema`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_schema** (PK) | bigint | Sim | | |
| schema_nome | character varying(100) | Não | | |
| owner_name | character varying(100) | Não | | |
| comentario | text | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.catalogo_tabela

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tabela`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tabela** (PK) | bigint | Sim | | |
| id_schema | bigint | Não | | |
| nome | character varying(120) | Não | | |
| tipo | character varying(30) | Não | | |
| owner_name | character varying(100) | Não | | |
| comentario | text | Não | | |
| possui_pk | boolean | Não | | |
| possui_fk | boolean | Não | | |
| possui_indice | boolean | Não | | |
| possui_trigger | boolean | Não | | |
| possui_auditoria | boolean | Não | | |
| quantidade_colunas | integer | Não | | |
| quantidade_registros | bigint | Não | | |
| tamanho_mb | numeric(12,2) | Não | | |
| ultimo_vacuum | timestamp without time zone | Não | | |
| ultimo_analyze | timestamp without time zone | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.categoria

Categorias utilizadas no cálculo do ICB.

**Chave primária:** `id_categoria`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_categoria** (PK) | smallint | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(200) | Sim | | |
| peso | numeric(5,2) | Sim | | |
| ativo | boolean | Sim | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.colunas_identificadoras

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| column_name | character varying(255) | Sim | | |
| data_type | character varying(255) | Sim | | |
| is_nullable | character varying(3) | Sim | | |
| column_default | text | Não | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.colunas_not_null_sem_default

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| column_name | character varying(255) | Sim | | |
| data_type | character varying(255) | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.colunas_sem_comentario

Colunas que ainda não possuem documentação estrutural.

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| column_name | character varying(255) | Sim | | |
| data_type | character varying(255) | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.configuracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_configuracao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_configuracao** (PK) | smallint | Sim | | |
| chave | character varying(100) | Sim | | |
| valor | character varying(500) | Não | | |
| descricao | text | Não | | |
| ativo | boolean | Sim | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.core

Cadastro do núcleo do Framework Enterprise

**Chave primária:** `id_core`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_core** (PK) | bigint | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(200) | Sim | | |
| descricao | text | Não | | |
| versao | character varying(20) | Não | | |
| status | character varying(30) | Não | | |
| ambiente | character varying(20) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| revisao | integer | Não | 1 | |

### auditoria.etapa_10_4_4_snapshot

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `snapshot_id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **snapshot_id** (PK) | bigint | Sim | | |
| snapshot_em | timestamp with time zone | Sim | clock_timestamp() | |
| schema_name | text | Sim | | |
| table_name | text | Sim | | |
| constraint_type | text | Sim | | |
| constraint_name_atual | text | Sim | | |
| nome_padrao_sugerido | text | Sim | | |
| constraint_definition | text | Não | | |
| constraint_oid | oid | Não | | |
| aplicado | boolean | Sim | false | |
| aplicado_em | timestamp with time zone | Não | | |

### auditoria.execucao

Cabeçalho das execuções de auditoria do banco.

**Chave primária:** `id_execucao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_execucao** (PK) | bigint | Sim | | |
| versao_banco | character varying(30) | Sim | | |
| versao_script | character varying(30) | Sim | | |
| schema_auditado | character varying(100) | Sim | | |
| usuario_execucao | character varying(100) | Sim | | |
| host_execucao | character varying(200) | Não | | |
| banco | character varying(100) | Não | | |
| data_inicio | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| data_fim | timestamp without time zone | Não | | |
| tempo_execucao_ms | bigint | Não | | |
| score_final | numeric(5,2) | Não | | Índice Geral de Conformidade do Banco (ICB). |
| classificacao | character varying(30) | Não | | Excelente, Muito Bom, Bom, Regular ou Crítico. |
| status_execucao | character varying(30) | Não | | EXECUTANDO, FINALIZADO ou ERRO. |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.execucao_auditoria

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_execucao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_execucao** (PK) | bigint | Sim | | |
| etapa | character varying(20) | Sim | | |
| iniciado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |
| finalizado_em | timestamp with time zone | Não | | |
| status | character varying(30) | Sim | | |
| descricao | text | Não | | |

### auditoria.execucao_correcao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_execucao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_execucao** (PK) | bigint | Sim | | |
| script | character varying(200) | Sim | | |
| etapa | character varying(200) | Sim | | |
| iniciado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |
| finalizado_em | timestamp with time zone | Não | | |
| status | character varying(30) | Sim | 'EM_EXECUCAO'::character varying | |
| observacao | text | Não | | |

### auditoria.executor

Cadastro dos executores do Framework Enterprise

**Chave primária:** `id_executor`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_executor** (PK) | bigint | Sim | | |
| codigo | character varying(50) | Sim | | |
| nome | character varying(150) | Sim | | |
| descricao | text | Não | | |
| tipo_objeto | character varying(50) | Não | | |
| procedure_execucao | character varying(200) | Sim | | |
| aceita_parametros | boolean | Não | true | |
| permite_correcao | boolean | Não | false | |
| ordem_execucao | integer | Não | 0 | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.fks_sem_indice

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| constraint_name | character varying(255) | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.indices_potencialmente_duplicados

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| index_1 | character varying(255) | Sim | | |
| index_2 | character varying(255) | Sim | | |
| definicao | text | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.inventario_constraints

Inventário das constraints existentes no banco.

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| constraint_name | character varying(255) | Sim | | |
| constraint_type | character varying(50) | Sim | | |
| definition | text | Sim | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.inventario_identity

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| column_name | character varying(255) | Sim | | |
| identity_generation | character varying(30) | Não | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.inventario_indices

Inventário dos índices existentes no banco.

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| index_name | character varying(255) | Sim | | |
| index_definition | text | Sim | | |
| tamanho_bytes | bigint | Não | | |
| tamanho_formatado | text | Não | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.inventario_sequences

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| sequence_schema | character varying(255) | Sim | | |
| sequence_name | character varying(255) | Sim | | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.inventario_tabelas

Inventário estrutural das tabelas existentes no WMA Travel ERP.

**Chave primária:** `id_inventario`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_inventario** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| row_estimate | bigint | Não | | |
| tamanho_bytes | bigint | Não | | |
| tamanho_formatado | text | Não | | |
| possui_pk | boolean | Sim | false | |
| possui_fk | boolean | Sim | false | |
| possui_indices | boolean | Sim | false | |
| possui_comentario | boolean | Sim | false | |
| auditado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.item

Catálogo das regras de auditoria.

**Chave primária:** `id_item`

**Chaves estrangeiras:**

- `id_categoria` → `auditoria.categoria(id_categoria)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_item** (PK) | bigint | Sim | | |
| id_categoria | smallint | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(500) | Sim | | |
| criticidade | character varying(20) | Sim | | |
| peso | numeric(5,2) | Sim | 1 | |
| ativo | boolean | Sim | true | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |
| tipo_verificacao | character varying(30) | Não | | |
| objeto_alvo | character varying(30) | Não | | |
| script_origem | character varying(100) | Não | | |
| procedure_execucao | character varying(100) | Não | | |
| habilitado | boolean | Sim | true | |
| ordem_execucao | integer | Não | | |
| versao_minima | character varying(20) | Não | | |
| versao_maxima | character varying(20) | Não | | |
| categoria_tecnica | character varying(50) | Não | | |
| tempo_estimado_ms | integer | Não | | |
| observacao_tecnica | text | Não | | |

### auditoria.log

Registro de erros, avisos e mensagens produzidos durante a execução da auditoria.

**Chave primária:** `id_log`

**Chaves estrangeiras:**

- `id_execucao` → `auditoria.execucao(id_execucao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | bigint | Sim | | |
| id_execucao | bigint | Não | | |
| script | character varying(200) | Não | | |
| etapa | character varying(100) | Não | | |
| sqlstate | character varying(10) | Não | | |
| mensagem | text | Não | | |
| detalhe | text | Não | | |
| hint | text | Não | | |
| contexto | text | Não | | |
| severidade | character varying(20) | Não | | |
| data_log | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.log_correcao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_log`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_log** (PK) | bigint | Sim | | |
| data_execucao | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| schema_nome | character varying(100) | Não | | |
| tabela_nome | character varying(100) | Não | | |
| objeto | character varying(100) | Não | | |
| tipo_correcao | character varying(100) | Não | | |
| descricao | text | Não | | |
| sql_executado | text | Não | | |
| resultado | character varying(20) | Não | | |
| erro | text | Não | | |

### auditoria.mapa_padronizacao_constraints

ETAPA 10.4.2 - Mapa permanente de padronizacao das constraints do WMA Travel ERP. Esta tabela registra o nome
atual, tipo, definicao e nome profissional sugerido sem alterar as constraints reais.

**Chave primária:** `id_mapa`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_mapa** (PK) | bigint | Sim | | |
| criado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |
| schema_name | character varying(128) | Sim | | |
| table_name | character varying(128) | Sim | | |
| constraint_name_atual | character varying(255) | Sim | | Nome atualmente utilizado pela constraint no banco. |
| constraint_type | character varying(30) | Sim | | |
| colunas | text | Não | | |
| tabela_referenciada | character varying(255) | Não | | |
| colunas_referenciadas | text | Não | | |
| definicao_constraint | text | Não | | |
| prefixo_padrao | character varying(20) | Não | | |
| nome_padrao_sugerido | character varying(255) | Não | | Nome profissional recomendado para futura aplicação da padronização. |
| fora_do_padrao | boolean | Sim | false | Indica se o nome atual não utiliza o prefixo padronizado definido para o tipo da constraint. |
| status_mapa | character varying(30) | Sim | 'PENDENTE'::character varying | |
| observacao | text | Não | | |

### auditoria.recomendacao

Recomendações automáticas geradas durante a auditoria.

**Chave primária:** `id_recomendacao`

**Chaves estrangeiras:**

- `id_execucao` → `auditoria.execucao(id_execucao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_recomendacao** (PK) | bigint | Sim | | |
| id_execucao | bigint | Sim | | |
| prioridade | character varying(20) | Sim | | |
| categoria | character varying(50) | Não | | |
| tabela_nome | character varying(100) | Não | | |
| coluna_nome | character varying(100) | Não | | |
| descricao | text | Sim | | |
| script_sugerido | character varying(255) | Não | | |
| corrigido | boolean | Sim | false | |
| data_correcao | timestamp without time zone | Não | | |
| observacao | text | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.regra

Cadastro central de todas as regras de diagnóstico do Framework.

**Chave primária:** `id_regra`

**Chaves estrangeiras:**

- `id_executor` → `auditoria.executor(id_executor)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_regra** (PK) | bigint | Sim | | |
| codigo | character varying(30) | Não | | |
| descricao | character varying(300) | Não | | |
| categoria | character varying(50) | Não | | |
| objeto | character varying(50) | Não | | |
| consulta_sql | text | Não | | |
| script_recomendado | text | Não | | |
| peso | numeric(5,2) | Não | | |
| criticidade | character varying(20) | Não | | |
| habilitado | boolean | Não | true | |
| ordem | integer | Não | | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |
| tipo_objeto | character varying(30) | Não | | |
| objeto_alvo | character varying(100) | Não | | |
| sql_diagnostico | text | Não | | SQL responsável por localizar inconsistências. |
| sql_correcao | text | Não | | SQL utilizado para corrigir automaticamente o problema. |
| correcao_automatica | boolean | Não | false | Indica se a regra pode ser corrigida automaticamente. |
| ativo | boolean | Não | true | |
| prioridade | smallint | Não | 3 | |
| ordem_execucao | integer | Não | 0 | |
| tempo_estimado_ms | integer | Não | | |
| versao_minima | character varying(20) | Não | | |
| versao_maxima | character varying(20) | Não | | |
| observacao | text | Não | | |
| id_executor | bigint | Não | | |

### auditoria.resultado

Resultado individual de cada verificação executada.

**Chave primária:** `id_resultado`

**Chaves estrangeiras:**

- `id_execucao` → `auditoria.execucao(id_execucao)`
- `id_item` → `auditoria.item(id_item)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_resultado** (PK) | bigint | Sim | | |
| id_execucao | bigint | Sim | | |
| id_item | bigint | Sim | | |
| schema_nome | character varying(100) | Não | | |
| tabela_nome | character varying(100) | Não | | |
| coluna_nome | character varying(100) | Não | | |
| objeto_nome | character varying(200) | Não | | |
| status | character varying(20) | Sim | | |
| severidade | character varying(20) | Não | | |
| valor_encontrado | text | Não | | |
| valor_esperado | text | Não | | |
| observacao | text | Não | | |
| sqlstate | character varying(10) | Não | | |
| data_execucao | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Sim | 1 | |

### auditoria.score

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_score`

**Chaves estrangeiras:**

- `id_execucao` → `auditoria.execucao(id_execucao)`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_score** (PK) | bigint | Sim | | |
| id_execucao | bigint | Sim | | |
| estrutura | numeric(5,2) | Não | | |
| integridade | numeric(5,2) | Não | | |
| auditoria | numeric(5,2) | Não | | |
| performance | numeric(5,2) | Não | | |
| seguranca | numeric(5,2) | Não | | |
| normalizacao | numeric(5,2) | Não | | |
| padronizacao | numeric(5,2) | Não | | |
| documentacao | numeric(5,2) | Não | | |
| score_final | numeric(5,2) | Não | | |
| classificacao | character varying(30) | Não | | |
| created_at | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.script

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_script`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_script** (PK) | bigint | Sim | | |
| codigo | character varying(30) | Sim | | |
| descricao | character varying(200) | Sim | | |
| procedure_name | character varying(150) | Sim | | |
| ordem_execucao | integer | Sim | | |
| categoria | character varying(50) | Não | | |
| ativo | boolean | Não | true | |
| created_at | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| updated_at | timestamp without time zone | Não | | |
| deleted_at | timestamp without time zone | Não | | |
| created_by | integer | Não | | |
| updated_by | integer | Não | | |
| deleted_by | integer | Não | | |
| versao | integer | Não | 1 | |

### auditoria.tabelas_sem_indices

Tabelas detectadas sem índices.

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.tabelas_sem_pk

Tabelas detectadas sem chave primária.

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| schema_name | character varying(255) | Sim | | |
| table_name | character varying(255) | Sim | | |
| detectado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |

### auditoria.validacao_padronizacao_constraints

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_validacao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_validacao** (PK) | bigint | Sim | | |
| criado_em | timestamp with time zone | Sim | CURRENT_TIMESTAMP | |
| id_mapa | bigint | Não | | |
| schema_name | character varying(128) | Sim | | |
| table_name | character varying(128) | Sim | | |
| constraint_name_atual | character varying(255) CONSTRAINT validacao_padronizacao_constrain_constraint_name_atual_not_null | Sim | | |
| constraint_type | character varying(50) | Sim | | |
| colunas | text | Não | | |
| tabela_referenciada | character varying(255) | Não | | |
| colunas_referenciadas | text | Não | | |
| nome_padrao_sugerido | character varying(255) | Não | | |
| prefixo_padrao | character varying(20) | Não | | |
| fora_do_padrao | boolean | Sim | false | |
| possui_colisao | boolean | Sim | false | |
| possui_conflito | boolean | Sim | false | |
| tipo_validacao | character varying(50) | Não | | |
| status_validacao | character varying(50) | Sim | 'PENDENTE'::character varying | |
| observacao | text | Não | | |

---

## 7. Schema `config`

Parâmetros e versionamento de configuração do banco.

**Total de tabelas:** 3

### config.migracao

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| script | character varying(200) | Não | | |
| descricao | character varying(500) | Não | | |
| executado_em | timestamp without time zone | Não | CURRENT_TIMESTAMP | |
| executado_por | character varying(100) | Não | | |
| sucesso | boolean | Não | true | |

### config.parametro

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `chave`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **chave** (PK) | character varying(100) | Sim | | |
| valor | character varying(500) | Não | | |
| descricao | character varying(500) | Não | | |

### config.versao_banco

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id** (PK) | bigint | Sim | | |
| versao | character varying(30) | Sim | | |
| descricao | character varying(500) | Não | | |
| script | character varying(200) | Não | | |
| data_execucao | timestamp without time zone | Sim | CURRENT_TIMESTAMP | |
| usuario_execucao | character varying(100) | Não | CURRENT_USER | |

---

## 8. Schema `dw`

Data Warehouse: dimensões e fatos para Business Intelligence.

**Total de tabelas:** 10

### dw.dim_cliente

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_cliente_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_cliente_dw** (PK) | integer | Sim | | |
| id_cliente_origem | integer | Não | | |
| nome | character varying(150) | Não | | |
| cidade | character varying(100) | Não | | |
| estado | character varying(50) | Não | | |
| data_cadastro | date | Não | | |
| ativo | boolean | Não | | |

### dw.dim_destino

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_destino_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_destino_dw** (PK) | integer | Sim | | |
| id_destino_origem | integer | Não | | |
| nome | character varying(150) | Não | | |
| cidade | character varying(100) | Não | | |
| estado | character varying(50) | Não | | |
| pais | character varying(100) | Não | | |

### dw.dim_fornecedor

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_fornecedor_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_fornecedor_dw** (PK) | integer | Sim | | |
| id_fornecedor_origem | integer | Não | | |
| nome | character varying(150) | Não | | |
| categoria | character varying(100) | Não | | |

### dw.dim_plano_conta

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_conta_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_conta_dw** (PK) | integer | Sim | | |
| id_conta_origem | integer | Não | | |
| grupo | character varying(100) | Não | | |
| categoria | character varying(100) | Não | | |
| subcategoria | character varying(100) | Não | | |

### dw.dim_produto_turistico

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_produto_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_produto_dw** (PK) | integer | Sim | | |
| id_produto_origem | integer | Não | | |
| nome | character varying(200) | Não | | |
| categoria | character varying(100) | Não | | |
| tipo | character varying(50) | Não | | |
| ativo | boolean | Não | | |

### dw.dim_tempo

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_tempo`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_tempo** (PK) | integer | Sim | | |
| data | date | Sim | | |
| ano | integer | Não | | |
| mes | integer | Não | | |
| nome_mes | character varying(20) | Não | | |
| trimestre | integer | Não | | |
| semestre | integer | Não | | |
| dia | integer | Não | | |
| dia_semana | integer | Não | | |
| nome_dia | character varying(20) | Não | | |

### dw.fato_financeiro

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_financeiro_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_financeiro_dw** (PK) | integer | Sim | | |
| id_tempo | integer | Não | | |
| id_conta | integer | Não | | |
| tipo_movimento | character varying(30) | Não | | |
| valor | numeric(15,2) | Não | | |

### dw.fato_marketing

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_marketing_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_marketing_dw** (PK) | integer | Sim | | |
| id_tempo | integer | Não | | |
| canal | character varying(100) | Não | | |
| investimento | numeric(15,2) | Não | | |
| leads | integer | Não | | |
| vendas | integer | Não | | |
| receita | numeric(15,2) | Não | | |

### dw.fato_vendas

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_venda_dw`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_venda_dw** (PK) | integer | Sim | | |
| id_tempo | integer | Não | | |
| id_cliente | integer | Não | | |
| id_produto | integer | Não | | |
| id_destino | integer | Não | | |
| quantidade | integer | Não | | |
| valor_venda | numeric(15,2) | Não | | |
| valor_custo | numeric(15,2) | Não | | |
| margem | numeric(15,2) | Não | | |

### dw.log_etl

_Pendente de descrição funcional (sem `COMMENT ON TABLE` no banco)._

**Chave primária:** `id_execucao`

| Coluna | Tipo | Obrigatória | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| **id_execucao** (PK) | integer | Sim | | |
| processo | character varying(100) | Não | | |
| inicio | timestamp without time zone | Não | | |
| fim | timestamp without time zone | Não | | |
| registros_processados | integer | Não | | |
| status | character varying(30) | Não | | |
| mensagem | text | Não | | |

---

## 9. Histórico de Revisões

| Versão | Data | Descrição |
| --- | --- | --- |
| 0.2.0-dev | 2026-08-15 | Reconstrução completa a partir do schema real (remoção de entradas fictícias, cobertura 209/209 tabelas). |

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
