# Gate do Inventário Fiscal 2.9.1

> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Documento Técnico
> **Data:** 20/10/2026
> **Versão:** 0.11
> **Resultado:** EM EXECUÇÃO — GATE ABERTO
> **Certificação:** NÃO CONCEDIDA
> **Encaminhamento:** APTO COM RESSALVAS; proposta de fechamento documental aguardando aprovação

## Escopo avaliado

Consolidação documental das evidências físicas fornecidas pelo responsável, sem nova conexão ou execução SQL.
A fonte preliminar é
[FISCAL_INVENTORY.md](FISCAL_INVENTORY.md); a consolidação e lacunas estão em
[FISCAL_2_9_1_INVENTORY.md](FISCAL_2_9_1_INVENTORY.md) e
[FISCAL_2_9_1_GAP_ANALYSIS.md](FISCAL_2_9_1_GAP_ANALYSIS.md).

O escopo de fechamento é o inventário das seis tabelas, metadados disponíveis, seis dependências referenciais
e lacunas entre domínios. Não inclui paridade integral com o dump, dependências transitivas ou implementação.
A leitura estática desta revisão identificou divergência na contagem de colunas entre o snapshot informado e o dump;
ela está registrada no inventário e encaminhada para resolução antes de serviços ou migrations dependentes. A matriz
de auditoria foi aprovada para encaminhamento; isso não constitui aceite formal de encerramento.

## Resultado por critério

| Critério | Resultado | Observação |
| --- | --- | --- |
| Estruturas fiscais físicas | CONCLUÍDO NO RECORTE | Seis tabelas; 88 colunas; 31 restrições; sete índices; seis FKs |
| Banco auditado | EVIDÊNCIA FORNECIDA | PostgreSQL 18.4; wma_phase2_b07_20261001_test; wma_test |
| Integridade estrutural | PARCIAL | Seis PKs; UNIQUE em imposto.codigo; sem CHECK e sem índices específicos nas FKs |
| Acesso e segurança | PENDENTE | Privilégios relatados; `trust` informado em 20/10, não verificado agora |
| Rastreabilidade da coleta | PARCIAL | Saída local de restrições; demais resultados confirmados pelo responsável |
| Backend, API, RBAC e testes | AUSENTE | Camadas, rotas, permissões e testes fiscais não encontrados |
| Integração Comercial | AUSENTE | Venda disponível; consumo pelo Fiscal não implementado |
| Integração Financeiro | PARCIAL | Fronteira definida; integração fiscal não implementada |
| Turismo/Bike Tour | AUSENTE | Correlações/pendências não geram efeito fiscal |
| Contabilidade | AUSENTE | Sem domínio/API; fora do escopo Financeiro documentado |
| Migrations | AUSENTE | Nenhuma revision fiscal entre as 18 versionadas |
| NFS-e e provedor | PARCIAL | Tabela confirmada; contrato, idempotência, estados e operação não demonstrados |
| Tributos, retenções e apuração | PARCIAL | Estruturas candidatas; regras/fluxos não demonstrados |

## Configuração e decisão PostgreSQL

O registro da versão 0.2 não identificava destino ou privilégios e declarava `DATABASE_AUDIT=NOT_RUN`.
As evidências posteriores fornecidas pelo responsável confirmam banco `wma_phase2_b07_20261001_test`,
PostgreSQL 18.4, usuário `wma_test` e consultas de catálogo em transações READ ONLY.
O usuário não possui SELECT nem privilégios de escrita nas 249 tabelas verificadas. Isso não atesta permissões
globais em funções, sequências, schemas ou outros bancos. Dados de negócio e comportamento fiscal não foram validados.

**DATABASE_AUDIT=EVIDÊNCIA FORNECIDA; NOVA EXECUÇÃO NÃO REALIZADA.** O `.env` não foi lido nesta consolidação.
A [saída de restrições](../fiscal_2_9_1_constraints.txt) contém 35 linhas físicas, das quais 31 são entradas de
restrições: seis PKs, seis FKs, uma UNIQUE e 18 NOT NULL, sem CHECK. Ela termina em COMMIT, não em ROLLBACK, e
não registra modo READ ONLY nem destino;
essas informações são atribuídas ao responsável, sem alterar a evidência ou presumir execução do roteiro abaixo.

O uso de `trust` no TCP local de `pg_hba.conf` foi informado pelo responsável em 20/10/2026 e permanece
classificado como pendência P0, conforme a [análise de riscos](FISCAL_2_9_1_GAP_ANALYSIS.md). Esta revisão não
verificou o estado atual nem alterou configuração. A restrição de privilégios do usuário não substitui a
verificação de autenticação. Não há evidência de incidente ou acesso indevido nesta coleta.

### Roteiro preliminar preservado da versão 0.2

O bloco abaixo é histórico de preparação, não prova da coleta nem roteiro aprovado para reutilização integral.
Contém quatro SELECTs e comandos de controle de transação/sessão, sem DDL ou DML de escrita. O timeout de 5s
limita cada instrução; não controla estabelecimento de conexão. É compatível com transação READ ONLY.
`information_schema` filtra visibilidade por privilégios; com `wma_test`, resultados vazios não provam ausência.
A consulta de constraints e seus joins por nome não garantem cobertura nem pareamento de FKs compostas.
Uma futura coleta deve revisar consultas por identidade de objetos em `pg_catalog`, sem ampliar permissões
de negócio para contornar essas limitações. Nenhum SQL foi executado nesta revisão.

<!-- cspell:ignore inet -->

```sql
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '5s';

SELECT current_database() AS database_name,
       inet_server_addr() AS server_address,
       inet_server_port() AS server_port,
       current_user AS database_user,
       current_setting('transaction_read_only') AS read_only;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'nota_fiscal', 'integracao_nfse', 'imposto',
      'declaracao_fiscal', 'das', 'simples_nacional'
  )
ORDER BY table_name;

SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'nota_fiscal', 'integracao_nfse', 'imposto',
      'declaracao_fiscal', 'das', 'simples_nacional'
  )
ORDER BY table_name, ordinal_position;

SELECT tc.table_name, tc.constraint_name, tc.constraint_type,
       kcu.column_name, ccu.table_name AS foreign_table,
       ccu.column_name AS foreign_column
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_catalog = kcu.constraint_catalog
 AND tc.constraint_schema = kcu.constraint_schema
 AND tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON tc.constraint_catalog = ccu.constraint_catalog
 AND tc.constraint_schema = ccu.constraint_schema
 AND tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
      'nota_fiscal', 'integracao_nfse', 'imposto',
      'declaracao_fiscal', 'das', 'simples_nacional'
  )
ORDER BY tc.table_name, tc.constraint_name;

ROLLBACK;
```

Em eventual coleta futura autorizada, interromper se `read_only` não retornar `on`, se o destino divergir do
autorizado ou se os privilégios excederem o escopo. O bloco preservado consulta metadados, sem dados de negócio.

## Proposta de aceitação condicionada da rastreabilidade

Propõe-se aceitar a saída local de restrições e as confirmações do responsável para concluir somente o recorte
inventariado. O aceite deve reconhecer que não há logs completos de colunas, índices, privilégios, identidade
da conexão e READ ONLY, nem data de coleta comprovada neste conjunto. Não se exige nova conexão para esta proposta.
Contagens não comprovam paridade integral; dependências não inventariadas devem ser verificadas antes de qualquer
decisão estrutural que delas dependa. Aprovar a proposta não certifica o banco inteiro nem os dados de negócio.

Na revisão anterior desta minuta, Markdownlint e CSpell foram executados nos quatro documentos então alterados em
24/10/2026; ambos reportaram zero ocorrências. Isso não representa aprovação de CI nem valida esta revisão posterior.
A decisão formal sobre o fechamento e as limitações da rastreabilidade continua pendente.

## Pendências encaminhadas para tarefas posteriores

O destino e a condição de tratamento de cada lacuna estão na
[análise de lacunas](FISCAL_2_9_1_GAP_ANALYSIS.md#encaminhamento-das-pendências).

- Segurança: tratar `trust` e revisar privilégios globais antes de ampliar acesso, em tarefa independente.
- Arquitetura de dados: completar evidências e dependências fora do recorte antes de decisão estrutural dependente.
- Serviços e desenho fiscal: definir invariantes, idempotência e estados antes da implementação correspondente.
- Integrações: definir contratos Comercial/Financeiro, provedor e regras fiscais antes dos fluxos e homologação.
- Qualidade funcional: implementar e testar API, RBAC e emissão nas etapas previstas, antes de certificar o módulo.

A correção de `trust` não bloqueia por si só a conclusão documental condicionada deste inventário; permanece
risco P0 informado em 20/10/2026, com estado atual não verificado e sem aceite de segurança operacional.
Homologação NFS-e e solução dos contratos não são critérios de conclusão da 2.9.1. Nenhuma dessas tarefas está
autorizada por este documento; a 2.9.2 e as demais etapas exigem gates próprios.

## Proposta de gate de entrada e saída da 2.9.2

A ordem oficial identifica a 2.9.2 como serviços, sem decompor seus casos de uso. Os critérios abaixo são uma
proposta documental para aprovação do responsável; não constituem autorização de implementação. A proposta
detalhada está em [FISCAL_2_9_2_GATE_PROPOSAL.md](FISCAL_2_9_2_GATE_PROPOSAL.md).

### Entrada proposta

- decisão formal do gate 2.9.1, incluindo aceite ou rejeição explícita das ressalvas de rastreabilidade;
- autorização expressa para iniciar a 2.9.2 e escopo de serviços aprovado pelo responsável fiscal;
- casos de uso, atores, entradas, saídas, erros e fronteiras Fiscal/Comercial/Financeiro documentados;
- invariantes, estados, idempotência e responsabilidade transacional definidos para cada operação aprovada;
- controles de acesso, auditoria e tratamento de dados especificados;
- decisão registrada sobre mudança de schema; se necessária, migration e gate próprios conforme ADR-004 e
  `Docs/MIGRATIONS.md`;
- plano de testes e ambiente de teste descartável identificados;
- antes de qualquer conexão a banco, verificação de segurança do ambiente e resolução ou aceite explícito de
  segurança para a pendência P0 `trust`.

### Saída proposta

- implementação restrita ao escopo e aos casos de uso autorizados;
- testes automatizados aprovados para regras, estados, idempotência, autorização e falhas pertinentes;
- integridade transacional demonstrada; migration aprovada e validada se o escopo exigir mudança estrutural;
- documentação, riscos residuais e evidências de validação revisados;
- aceite específico do gate da 2.9.2, sem declarar certificação integral do módulo Fiscal ou autorização para
  produção.

Documentos fiscais, regras tributárias, impostos, retenções, NFS-e, apuração, integrações Comercial/Financeiro/
contábil, API, testes de integração e certificação permanecem nos itens próprios da sequência 2.9. Atribuí-los à
2.9.2 requer decisão explícita de mudança de escopo. A proposta não muda a sequência 2.8, 2.9 e 2.10–2.14.

## Consistência com planejamento e critérios de fechamento

A [ADR-021](architecture/ADR-021-PHASE-2-EXECUTION-REPROGRAMMING.md) mantém a 2.8 em HOLD e permite priorizar
o inventário 2.9.1 sem renumerar etapas, certificar dependências ou liberar implementação. O
[roadmap da Fase 2](PHASE_2_ROADMAP.md) e a [ordem executiva](PHASE_2_EXECUTION_ORDER.md) mantêm Fiscal em execução.
A incorporação documental da coleta autorizada pelo responsável não atribui autorização de banco à ADR-021.

Roadmap da Fase 2 e ordem executiva passam a apontar a revisão desta proposta como ação corrente, com a 2.8 em
HOLD e 2.10–2.14 planejadas. Numeração e sequência oficial são preservadas. A ADR-021 permanece inalterada.
O [roadmap geral](ROADMAP.md) e o [manual mestre](PROJECT_DOCUMENTATION.md) receberam atualização aditiva em
23/10/2026 para registrar a 2.9.1 em execução, a 2.8 em HOLD e a 2.9.2 sem autorização. Textos anteriores
permanecem identificados como históricos; nenhum deles registra o aceite formal.

### Matriz final proposta

PASS significa critério documental verificado; não representa aprovação formal nem certificação funcional.

| Critério | Evidência verificável | Estado | Bloqueio / efeito | Ação necessária |
| --- | --- | --- | --- | --- |
| Seis tabelas e metadados registrados | 88 colunas; 6 PKs; 6 FKs | CONCLUÍDO NO RECORTE | Nenhum para o fechamento documental | Manter o recorte inventariado |
| Restrições e índices registrados | 31 restrições; 7 índices | CONCLUÍDO NO RECORTE | Nenhum para o fechamento documental | Manter a atribuição às evidências disponíveis |
| Dependências referenciais | Seis FKs com origem e destino | CONCLUÍDO NO RECORTE | Nenhum para o fechamento documental | Não inferir paridade ou dependências transitivas |
| Limitações de evidência | Coleta parcial; relatos; logs incompletos | REGISTRADAS | Nenhum, se aceitas formalmente | Registrar os limites no aceite |
| Lacunas com encaminhamento | Destino definido na análise | CONCLUÍDO | Nenhum para o fechamento documental | Transferir às tarefas e gates próprios |
| Escopo e sequência | Separados; 2.8 HOLD; 2.10–2.14 preservadas | CONCLUÍDO | Nenhum | Preservar os gates posteriores |
| Markdownlint e CSpell | Execução anterior: zero ocorrências; esta revisão não revalidada | RESSALVA | Não representa aprovação de CI nem aceite formal | Reexecutar em ambiente com os validadores disponíveis |
| Aceite condicionado da rastreabilidade | Limitado às evidências declaradas | PENDENTE | Impede o fechamento formal da 2.9.1 | Decisão explícita do proprietário do projeto |
| Encerramento formal da 2.9.1 | Proposta; sem aceite atribuído | PENDENTE | Impede declarar a etapa encerrada | Registrar decisão explícita, aprovador e data |
| Pendência de segurança `trust` | P0 informado; estado atual não verificado | ABERTA, INDEPENDENTE | Não impede o inventário documental; impede conexão ou ampliação de acesso sem tratamento ou aceite de segurança específico | Encaminhar à segurança; não declarar configuração segura |
| Gate da 2.9.2 | Escopo e critérios em proposta | PENDENTE, ETAPA POSTERIOR | Não impede fechar a 2.9.1; impede iniciar a 2.9.2 | Aprovar escopo e gate após a decisão da 2.9.1 |

## Validação da proposta 0.4 — 20/10/2026

- Branch preservada: `docs/project-state-alignment`; HEAD `180beca586cda86a1006afae0b24ea399e768d57`.
- `git diff --check` sem erros; os três arquivos ainda não rastreados receberam também verificação de whitespace
  com `git diff --no-index --check`, sem inclusão no índice do Git.
- Links Markdown locais dos seis documentos submetidos à conferência de destinos e âncoras.
- Conferidos estrutura e whitespace das alterações, preservando conteúdo histórico fora do ajuste.
- Markdownlint e CSpell não foram localizados no PATH nem nos locais de instalação/cache examinados;
  não foram executados ou instalados. A conferência básica não substitui esses validadores nem o CI.
- As alterações locais fora dos seis documentos e a evidência de restrições devem permanecer idênticas.
- Nenhuma conexão, migration, alteração de banco, código, API ou teste; nenhum comando de publicação Git.

## Revisão documental 0.5 — 23/10/2026

- Checkout preservado em `docs/project-state-alignment`, HEAD `3faf9c5f930329a8fc6311d90f275f4335492cf6`;
  alterações locais preexistentes preservadas.
- `git diff --check` e destinos dos links locais foram conferidos após as atualizações desta revisão.
- Markdownlint e CSpell não foram executados; nenhum validador foi instalado.
- Nenhuma conexão PostgreSQL, SQL, migration, teste ou operação de publicação Git foi realizada.

## Decisão

**APTO COM RESSALVAS — PROPOSTA PARA APROVAÇÃO EXPLÍCITA.** Recomenda-se concluir documentalmente a 2.9.1 no
recorte inventariado, mediante decisão explícita sobre os limites de rastreabilidade descritos acima. As validações
editoriais foram executadas conforme registrado neste gate; isso não equivale a aprovação de CI.
O gate permanece **ABERTO**, e o estado **EM EXECUÇÃO**, até essa aprovação. Nenhum aceite é registrado em nome
do responsável pelo projeto. A conclusão proposta não certifica funcionalmente o Fiscal, não libera produção,
migrations, emissão ou implementação da 2.9.2. A 2.8 permanece em HOLD conforme ADR-021.

## Minuta de decisão formal — pendente

Esta minuta prepara a decisão e não registra aceite. Todos os campos de decisão permanecem sem preenchimento.

**Autorização de trabalho registrada:** em 24/10/2026, o responsável pelo projeto autorizou prosseguir com a
preparação do fechamento condicionado após corrigir erros e pendências. Esta autorização de trabalho não aprova o
fechamento, não aceita automaticamente as limitações de rastreabilidade e não concede aceite de segurança.

**Responsável pela decisão:** Vâner de Menezes Lázaro, proprietário do projeto, conforme declaração explícita do
responsável nesta conversa. Este registro da autoridade decisória é atual e não atribui retroativamente uma regra
formal à documentação anterior. Não se atribui a ele outro cargo organizacional.

- **Aprovador:** Vâner de Menezes Lázaro, proprietário do projeto.
- **Data da decisão:** a preencher pelo aprovador.

**Decisão sobre a proposta de fechamento condicionado:**

- [ ] Aprovar o fechamento documental limitado ao inventário e às evidências descritas neste gate.
- [ ] Rejeitar ou solicitar complementação; registrar os itens requeridos antes de nova decisão.

**Aceitação das ressalvas de rastreabilidade:**

- [ ] Aceitar explicitamente os limites descritos na seção “Proposta de aceitação condicionada da rastreabilidade”.
- [ ] Não aceitar; solicitar as evidências complementares identificadas pelo aprovador.

**Markdownlint:**

Na revisão anterior: markdownlint-cli2 0.24.0 (markdownlint 0.42.0), nos quatro documentos então alterados; zero
ocorrências. Esta versão do gate não foi revalidada por Markdownlint.

**CSpell:**

Na revisão anterior: CSpell 10.4.0, nos quatro documentos então alterados; zero ocorrências. Esta versão do gate
não foi revalidada por CSpell.

**Pendências que permanecem abertas:** `trust` P0 com estado atual não verificado; verificações fora do recorte;
requisitos funcionais e integrações encaminhados às etapas posteriores. A decisão documental não aceita risco de
segurança.

**Limites do aceite:** não representa certificação funcional, aceite de segurança, autorização para conexão ou produção,
nem autorização para iniciar a 2.9.2. O gate da 2.9.2 precisa de aprovação própria após a decisão da 2.9.1.

Até o registro de uma decisão válida, o gate permanece **ABERTO**, a 2.9.1 permanece **EM EXECUÇÃO** e não há
fechamento formal.

## Validação editorial da revisão anterior — 24/10/2026

- `git diff --check`: aprovado, sem erros de whitespace.
- Destinos locais dos links Markdown nos quatro documentos alterados: verificados; nenhum destino inexistente.
- Markdownlint-cli2 0.24.0 (markdownlint 0.42.0): zero ocorrências nos quatro documentos alterados.
- CSpell 10.4.0: zero ocorrências nos quatro documentos alterados.
- Nenhum teste funcional, SQL, migration ou acesso ao PostgreSQL foi realizado.

## Revisão da minuta — 24/10/2026

O nome e a função de proprietário do projeto foram registrados conforme declaração atual do responsável. A decisão
de fechamento e o aceite das limitações de rastreabilidade permanecem sem preenchimento. Após esta revisão,
`git diff --check` passou. Markdownlint e CSpell não foram localizados como comandos executáveis nesta sessão e não
foram repetidos; a validação anterior não deve ser atribuída a esta versão 0.11.

## Histórico de atualização

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 19/10/2026 | Gate preliminar aberto, sem certificação |
| 0.2 | 19/10/2026 | Atualizado após auditoria estática; banco permanece não verificado |
| 0.3 | 19/10/2026 | Evidências físicas fornecidas consolidadas; inventário estrutural separado do aceite do gate |
| 0.4 | 20/10/2026 | Proposta de fechamento com ressalvas; critérios objetivos e pendências transferidas |
| 0.5 | 23/10/2026 | Trust qualificado; gate 2.9.2 proposto, sem autorização |
| 0.6 | 24/10/2026 | Minuta pendente; validações e efeitos de bloqueio registrados |
| 0.7 | 24/10/2026 | Markdownlint e CSpell executados; zero ocorrências nos quatro documentos alterados |
| 0.8 | 24/10/2026 | Autoridade decisória informada; decisão e aceite pendentes; validação editorial desta revisão delimitada |
| 0.9 | 24/10/2026 | Matriz corrigida para distinguir a execução anterior da revisão atual não revalidada |
| 0.10 | 24/10/2026 | Corrigida a distinção entre linhas físicas e entradas de restrições; validação atual continua pendente |
| 0.11 | 24/10/2026 | Divergência de colunas registrada; autorização de trabalho separada do aceite formal |

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 0.11 |
| Status | EM EXECUÇÃO; NÃO CERTIFICADO |
| Última atualização | 24/10/2026 |
| Repositório | VANER/WMA-Travel-ERP |
| Documento mestre | [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
