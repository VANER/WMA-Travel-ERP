# Gate do Inventário Fiscal 2.9.1

> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Documento Técnico
> **Data:** 20/10/2026
> **Versão:** 0.4
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
A matriz de auditoria foi aprovada para encaminhamento; isso não constitui aceite formal de encerramento.

## Resultado por critério

| Critério | Resultado | Observação |
| --- | --- | --- |
| Estruturas fiscais físicas | CONCLUÍDO NO RECORTE | Seis tabelas; 88 colunas; 31 restrições; sete índices; seis FKs |
| Banco auditado | EVIDÊNCIA FORNECIDA | PostgreSQL 18.4; wma_phase2_b07_20261001_test; wma_test |
| Integridade estrutural | PARCIAL | Seis PKs; UNIQUE em imposto.codigo; sem CHECK e sem índices específicos nas FKs |
| Acesso e segurança | PENDENTE | Sem SELECT/escrita nas 249 tabelas; autenticação TCP local trust |
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
A [saída de restrições](../fiscal_2_9_1_constraints.txt) contém 31 linhas: seis PKs, seis FKs, uma UNIQUE e
18 NOT NULL, sem CHECK. Ela termina em COMMIT, não em ROLLBACK, e não registra modo READ ONLY nem destino;
essas informações são atribuídas ao responsável, sem alterar a evidência ou presumir execução do roteiro abaixo.

O `trust` no TCP local de `pg_hba.conf` é pendência P0, conforme a
[análise de riscos](FISCAL_2_9_1_GAP_ANALYSIS.md). Não foi alterado. A restrição de privilégios do usuário não
resolve a falha de autenticação. Não há evidência de incidente ou acesso indevido nesta coleta.

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

Markdownlint e CSpell não foram executados. A aprovação deve aceitar explicitamente essa limitação ou exigir
sua execução antes do registro de encerramento. Não se declara CI aprovado.

## Pendências encaminhadas para tarefas posteriores

O destino e a condição de tratamento de cada lacuna estão na
[análise de lacunas](FISCAL_2_9_1_GAP_ANALYSIS.md#encaminhamento-das-pendências).

- Segurança: tratar `trust` e revisar privilégios globais antes de ampliar acesso, em tarefa independente.
- Arquitetura de dados: completar evidências e dependências fora do recorte antes de decisão estrutural dependente.
- Serviços e desenho fiscal: definir invariantes, idempotência e estados antes da implementação correspondente.
- Integrações: definir contratos Comercial/Financeiro, provedor e regras fiscais antes dos fluxos e homologação.
- Qualidade funcional: implementar e testar API, RBAC e emissão nas etapas previstas, antes de certificar o módulo.

A correção de `trust` não bloqueia por si só o fechamento deste inventário; permanece risco P0 sem aceite de
segurança operacional. Homologação NFS-e e solução dos contratos não são critérios de conclusão da 2.9.1.
Nenhuma dessas tarefas está autorizada por este documento; a 2.9.2 e as demais etapas exigem gates próprios.

## Consistência com planejamento e critérios de fechamento

A [ADR-021](architecture/ADR-021-PHASE-2-EXECUTION-REPROGRAMMING.md) mantém a 2.8 em HOLD e permite priorizar
o inventário 2.9.1 sem renumerar etapas, certificar dependências ou liberar implementação. O
[roadmap da Fase 2](PHASE_2_ROADMAP.md) e a [ordem executiva](PHASE_2_EXECUTION_ORDER.md) mantêm Fiscal em execução.
A incorporação documental da coleta autorizada pelo responsável não atribui autorização de banco à ADR-021.

Roadmap da Fase 2 e ordem executiva passam a apontar a revisão desta proposta como ação corrente, com a 2.8 em
HOLD e 2.10–2.14 planejadas. Numeração e sequência oficial são preservadas. A ADR-021 permanece inalterada.
O [roadmap geral](ROADMAP.md), fora do escopo de edição, conserva Fiscal como Planejado na seção temática e
inventário em execução no bloco corrente. Essa ressalva editorial não invalida o inventário nem libera operação.

### Matriz final proposta

PASS significa critério documental verificado; não representa aprovação formal nem certificação funcional.

| Critério | Evidência verificável | Status | Bloqueante | Ação necessária |
| --- | --- | --- | --- | --- |
| Seis tabelas e metadados registrados | 19 + 9 + 12 + 16 + 17 + 15 = 88 colunas; 6 PKs; 6 FKs | CONCLUÍDO | Não | Manter o recorte declarado |
| Restrições e índices registrados | 31 restrições (6 PKs, 6 FKs, 1 UNIQUE, 18 NOT NULL); 7 índices | CONCLUÍDO | Não | Manter a atribuição das fontes |
| Dependências referenciais | Seis FKs identificadas com origem e destino | CONCLUÍDO | Não | Não inferir paridade ou dependências transitivas |
| Limitações de evidência | Coleta parcial; fatos relatados atribuídos; sem logs completos | CONCLUÍDO | Não | Submeter a ressalva ao responsável |
| Lacunas com encaminhamento | Destino e condição registrados na análise de lacunas | CONCLUÍDO | Não | Transferir para gates próprios |
| Escopo e sequência | Inventário separado de implementação; 2.8 HOLD; 2.10–2.14 preservadas | CONCLUÍDO | Não | Manter gates posteriores |
| Markdownlint e CSpell | Não executados | RESSALVA | Não para conclusão documental condicionada | Executar quando disponíveis ou aceitar a limitação |
| Aceite condicionado da rastreabilidade | Restrito às evidências enumeradas e limitações declaradas | PENDENTE DE APROVAÇÃO | Sim para encerramento formal | Decisão explícita do responsável |
| Encerramento formal da 2.9.1 | Esta peça é proposta; nenhum aceite em nome do responsável | PENDENTE DE APROVAÇÃO | Sim para encerramento formal | Aprovação explícita do responsável |

## Validação desta revisão documental

- Branch preservada: `docs/project-state-alignment`; HEAD `180beca586cda86a1006afae0b24ea399e768d57`.
- `git diff --check` sem erros; os três arquivos ainda não rastreados receberam também verificação de whitespace
  com `git diff --no-index --check`, sem inclusão no índice do Git.
- Links Markdown locais dos seis documentos submetidos à conferência de destinos e âncoras.
- Conferidos estrutura e whitespace das alterações, preservando conteúdo histórico fora do ajuste.
- Markdownlint e CSpell não foram localizados no PATH nem nos locais de instalação/cache examinados;
  não foram executados ou instalados. A conferência básica não substitui esses validadores nem o CI.
- As alterações locais fora dos seis documentos e a evidência de restrições devem permanecer idênticas.
- Nenhuma conexão, migration, alteração de banco, código, API ou teste; nenhum comando de publicação Git.

## Decisão

**APTO COM RESSALVAS — PROPOSTA PARA APROVAÇÃO EXPLÍCITA.** Recomenda-se concluir documentalmente a 2.9.1 no
recorte inventariado, mediante aceite dos limites de rastreabilidade e de validação descritos acima.
O gate permanece **ABERTO**, e o estado **EM EXECUÇÃO**, até essa aprovação. Nenhum aceite é registrado em nome
do responsável pelo projeto. A conclusão proposta não certifica funcionalmente o Fiscal, não libera produção,
migrations, emissão ou implementação da 2.9.2. A 2.8 permanece em HOLD conforme ADR-021.

## Histórico de atualização

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 19/10/2026 | Gate preliminar aberto, sem certificação |
| 0.2 | 19/10/2026 | Atualizado após auditoria estática; banco permanece não verificado |
| 0.3 | 19/10/2026 | Evidências físicas fornecidas consolidadas; inventário estrutural separado do aceite do gate |
| 0.4 | 20/10/2026 | Proposta de fechamento com ressalvas; critérios objetivos e pendências transferidas |

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
