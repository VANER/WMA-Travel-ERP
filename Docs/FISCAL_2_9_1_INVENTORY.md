# Inventário Fiscal 2.9.1

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.9.1 — Inventário Fiscal
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Documento Técnico
> **Data:** 20/10/2026
> **Versão:** 0.4
> **Status:** EM EXECUÇÃO — NÃO CERTIFICADO
> **Encaminhamento:** Proposta de conclusão documental com ressalvas; aprovação explícita pendente

## Escopo e método

Este levantamento consolida a fonte local [FISCAL_INVENTORY.md](FISCAL_INVENTORY.md), documentos de autoridade
Comercial/Financeiro e inspeção estática de Backend, testes, OpenAPI, migrations e dump. Os objetos citados foram
identificados nas declarações do dump oficial `Database/scripts/WmaTravelERP.sql`; isso não comprova que existam
no banco atual. A revisão 0.2 não executou conexão, migration, teste funcional ou chamada a provedor.
A revisão 0.3 incorpora evidências PostgreSQL fornecidas pelo responsável nesta solicitação e a saída local de
restrições, sem nova conexão ou execução SQL. A data desta revisão não substitui a data de coleta não informada.

A revisão 0.4 delimita a 2.9.1 ao inventário das seis estruturas, metadados disponíveis, dependências referenciais
e lacunas de domínio. Não inclui implementação, homologação, certificação funcional ou liberação para produção.
As dependências inventariadas são as seis FKs identificadas e as fronteiras Comercial/Financeiro descritas abaixo.
Não se declara paridade integral com o dump nem cobertura de funções, triggers, views ou dependências transitivas.

Propõe-se aceitar condicionalmente a rastreabilidade disponível: saída local de restrições e confirmações do
responsável, mantendo explícita a ausência de logs completos de colunas, índices, privilégios e READ ONLY.
O aceite dessa limitação integra a proposta do [gate](FISCAL_2_9_1_GATE.md); não foi registrado em nome do responsável.

## Estruturas efetivamente encontradas no PostgreSQL

Ambiente informado: PostgreSQL 18.4, banco `wma_phase2_b07_20261001_test`, usuário `wma_test`.
O inventário estrutural das seis tabelas está concluído no recorte abaixo; isso não certifica a etapa ou o módulo.

| Tabela no schema public | Colunas | Chave primária | Chaves estrangeiras |
| --- | --- | --- | --- |
| `nota_fiscal` | 19 | `pk_nota_fiscal (id_nota_fiscal)` | `fk_nf_empresa`; `fk_nf_cliente` |
| `integracao_nfse` | 9 | `pk_integracao_nfse (id_integracao)` | `fk_integracao_nf` |
| `imposto` | 12 | `pk_imposto (id_imposto)` | Nenhuma |
| `das` | 16 | `pk_das (id_das)` | `fk_das_empresa` |
| `simples_nacional` | 17 | `pk_simples_nacional (id_simples)` | `fk_simples_empresa` |
| `declaracao_fiscal` | 15 | `pk_declaracao_fiscal (id_declaracao)` | `fk_declaracao_empresa` |
| Total | 88 | 6 PKs | 6 FKs |

As FKs `fk_nf_empresa`, `fk_das_empresa`, `fk_simples_empresa` e `fk_declaracao_empresa` ligam `id_empresa`
a `empresa(id_empresa)`. `fk_nf_cliente` liga `nota_fiscal.id_cliente` a `cliente(id_cliente)`;
`fk_integracao_nf` liga `integracao_nfse.id_nota_fiscal` a `nota_fiscal(id_nota_fiscal)`.

São 31 restrições: seis PKs, seis FKs, uma UNIQUE (`uk_imposto_codigo`, em `imposto.codigo`) e 18 NOT NULL.
Não há CHECK nas seis tabelas. Os sete índices informados correspondem às seis PKs e à UNIQUE de `imposto.codigo`;
não há índices específicos nas FKs. A ausência destes índices não invalida as FKs nem comprova lentidão.

A [saída local de restrições](../fiscal_2_9_1_constraints.txt) confirma nomes, definições e contagem das 31
restrições. O arquivo contém `BEGIN` e `COMMIT`, mas não mostra o modo da transação nem a identidade da conexão.
A confirmação de transações `READ ONLY`, versão, banco, usuário, colunas, índices e privilégios provém do relato
do responsável. Não foi inventado log adicional nem atribuída a esta revisão uma auditoria executada por ela.

## Estruturas apontadas no dump

| Objeto | Estrutura declarada no dump oficial | Chaves/relacionamentos declarados |
| --- | --- | --- |
| `public.nota_fiscal` | Número, datas, serviço, base, ISS, status e chave | PK; FK empresa/cliente |
| `public.integracao_nfse` | Provedor, código/mensagem, XML de envio/retorno, status e data | PK; FK para nota fiscal |
| `public.imposto` | Código, descrição, tipo e alíquota `numeric(5,2)` | PK; código único; sem FK declarada |
| `public.declaracao_fiscal` | Tipo, ano/período, entrega, status e observação | PK; FK empresa |
| `public.das` | Competência, receita, alíquota, valor, vencimento/pagamento e status | PK; FK empresa |
| `public.simples_nacional` | Ano, anexo, alíquota efetiva, faturamento 12 meses, faixa e RBT12 | PK; FK empresa |

As constraints foram conferidas nas declarações `ALTER TABLE` do próprio dump. Não foram encontrados `COMMENT ON`
para estas seis tabelas/colunas. A tabela NFS-e não declara versão de contrato, certificado, assinatura,
idempotência, município ou chave externa de autorização. A tabela `imposto` não declara vigência, regra de
incidência ou relação fiscal com nota/declaração. O default `EMITIDA` em `nota_fiscal` não prova autorização,
transmissão ou resposta fiscal válida. Tudo acima descreve o arquivo dump, não o banco atual.

## Backend e API

| Área | Classificação | Evidência / limite |
| --- | --- | --- |
| Pacote Backend Fiscal | PARCIAL | `app/modules/fiscal/__init__.py` só declara a fronteira |
| Models, repositories, services e schemas fiscais | AUSENTE | Nenhum arquivo fiscal nessas camadas no pacote dedicado |
| Router e registro na API | AUSENTE | `app/api/v1/router.py` inclui seis módulos; Fiscal não está incluído |
| OpenAPI versionado | AUSENTE | Nenhum path com fiscal, NFS-e ou nota fiscal em `Backend/openapi.json` |
| RBAC fiscal | AUSENTE | `authorization.py` define permissões por domínio; não há `FISCAL_*` |
| Testes fiscais | AUSENTE | `Backend/tests/` não contém testes fiscais dedicados |

O teste arquitetural inclui `fiscal` no conjunto de pacotes modulares obrigatórios; isso confirma a fronteira,
não implementação funcional. Os testes financeiros incluem `tributo` como objeto esperado apenas nos scripts
F1-FIN, não como tabela fiscal integrada ao Backend ou ao dump.

## Integrações e responsabilidades

O [desenho financeiro](FINANCIAL_IMPLEMENTATION_DESIGN.md) atribui ao Fiscal a autoridade do cálculo tributário;
Financeiro controla a obrigação recebida. O [inventário financeiro](FINANCIAL_INVENTORY.md) registra diferença
entre dump e scripts F1-FIN: o objeto `financeiro.tributo` citado em scripts históricos não deve ser afirmado como
presente no dump oficial sem evidência específica. A integração de entradas Comercial e saídas Financeiro requer
mapear venda/serviço, cliente, empresa, contas a receber/pagar e referências auditáveis, sem duplicar autoridade.

| Domínio | Integração observada e lacuna fiscal |
| --- | --- |
| Comercial | Venda/Item/Contrato existem; Fiscal não os consome |
| Financeiro | Lançamento da venda usa `app.shared.vendas`; sem integração fiscal |
| Turismo | Reserva correlaciona IDs comerciais; sem vínculo fiscal |
| Bike Tour | Pendência externa não cria título nem documento fiscal |
| Contabilidade | Fora do escopo Financeiro; sem módulo/API identificado |

As fronteiras se apoiam em `Docs/FINANCIAL_IMPLEMENTATION_DESIGN.md`, `Docs/COMMERCIAL_INVENTORY.md`,
`Docs/TOURISM_DOMAIN_BOUNDARIES.md` e `Docs/BIKE_TOUR_DOMAIN_BOUNDARIES.md`. Financeiro não deve absorver
autoridade Fiscal ou Contábil; Comercial é dono da venda; Turismo referencia venda/reserva; Bike Tour apenas
registra pendência de tratamento externo.

## NFS-e, tributos e apuração

Há tabela `public.integracao_nfse` confirmada no banco auditado e no DDL do dump, porém provedor, municípios,
ambiente de homologação, autenticação, certificados, layouts, assinatura, idempotência, cancelamento e contratos
não foram verificados. Tributos, retenções, regimes, regras temporais, cálculo, fechamento e obrigações acessórias
permanecem requisitos a esclarecer com responsável fiscal. Não se conclui cobertura legal ou operacional.

## Migrations e PostgreSQL

A árvore `Backend/migrations/versions/` foi listada estaticamente: o head versionado é
`202609170300_bike_tour_level_vocabulary.py` e não há revision fiscal nomeada. Nenhuma migration foi executada.
Revisão de nomes/escopo das 18 revisions versionadas encontrou revisões de segurança, Comercial, Financeiro,
Turismo e Bike Tour, nenhuma fiscal. O revision ID final conhecido pela documentação é `202609170300`; o comando
Alembic não foi executado. Isso não comprova o estado aplicado de qualquer banco.

### Preparação anterior e acesso confirmado

Na preparação da revisão 0.2, `Backend/.env` existia, mas não foi lido. A variável de processo
`WMA_DATABASE_URL` não estava definida. `Backend/.env.example` continha somente placeholders para
`postgresql+psycopg://<usuario>:<senha>@localhost:5432/<database>`, sem identificar banco real ou usuário.
Naquela preparação, destino e privilégios não foram confirmados; não houve tentativa de conexão.

O registro anterior `DATABASE_AUDIT=NOT_RUN` descreve apenas a preparação. Nesta consolidação,
**DATABASE_AUDIT=EVIDÊNCIA FORNECIDA; NOVA EXECUÇÃO NÃO REALIZADA**. A confirmação física limita-se ao recorte
informado; não comprova inventário de funções, triggers, views, extensões ou paridade integral com o dump.

`wma_test` não possui SELECT nem privilégios de escrita nas 249 tabelas verificadas, conforme evidência fornecida.
Foi possível consultar metadados em transações READ ONLY, sem acesso aos dados de negócio. Isso não comprova
ausência de privilégios em sequências, funções, schemas, outros bancos ou por associação a outras roles.
Consultas a `information_schema` podem omitir objetos por visibilidade; ausência de linhas não prova inexistência.

A autenticação TCP local está configurada como `trust` em `pg_hba.conf`, conforme confirmação do responsável.
É uma pendência de segurança comprovada, não uma evidência de invasão. Nenhuma configuração foi alterada.

## Evidências e pendências

As pendências têm destino e condição de tratamento na
[análise de lacunas](FISCAL_2_9_1_GAP_ANALYSIS.md#encaminhamento-das-pendências). A 2.9.1 registra as lacunas;
sua solução depende de tarefas próprias e dos gates posteriores. Em particular:

- evidências complementares e dependências fora do recorte: antes de decisão estrutural que delas dependa;
- `trust` e privilégios além das tabelas: tarefa independente de segurança, antes de ampliar acesso;
- vínculos, idempotência e estados: desenho e implementação fiscal posteriores, sem autorização implícita;
- contratos, provedor, regras fiscais e homologação: etapas funcionais correspondentes, antes do aceite operacional;
- Markdownlint/CSpell: validação documental posterior ou aceite explícito da limitação; não executados nesta proposta.

## Resultado

O inventário do recorte está preparado para conclusão documental com ressalvas, condicionado à aprovação
explícita do [gate](FISCAL_2_9_1_GATE.md). A proposta não registra aceite formal: o estado continua **EM EXECUÇÃO**,
**NÃO CERTIFICADO** até a decisão do responsável. Lacunas funcionais permanecem encaminhadas às etapas posteriores.
A 2.8 continua em HOLD; não há autorização de implementação da 2.9.2 nem liberação para produção.

## Histórico de atualização

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 18/10/2026 | Inventário inicial baseado na fonte preliminar |
| 0.2 | 19/10/2026 | Auditoria estática Backend, integrações, migrations e configuração; sem conexão DB |
| 0.3 | 19/10/2026 | Consolidação das evidências físicas fornecidas; limites de acesso e pendência trust |
| 0.4 | 20/10/2026 | Proposta de fechamento com ressalvas, escopo delimitado e pendências encaminhadas |

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 0.4 |
| Status | EM EXECUÇÃO; NÃO CERTIFICADO |
| Última atualização | 20/10/2026 |
| Repositório | VANER/WMA-Travel-ERP |
| Documento mestre | [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
