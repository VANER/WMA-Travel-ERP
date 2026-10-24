# Análise de Lacunas Fiscal 2.9.1

> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Documento Técnico
> **Data:** 20/10/2026
> **Versão:** 0.4
> **Status:** EM EXECUÇÃO — NÃO CERTIFICADO
> **Encaminhamento:** Proposta de conclusão documental com ressalvas; aprovação explícita pendente

Esta análise usa como fonte o [inventário fiscal preliminar](FISCAL_INVENTORY.md), o inventário consolidado
([FISCAL_2_9_1_INVENTORY.md](FISCAL_2_9_1_INVENTORY.md)), o desenho financeiro e inspeção estática limitada.
Incorpora também as evidências PostgreSQL 18.4 fornecidas pelo responsável e a saída local de restrições citada
no inventário. “Ausente” nas camadas funcionais significa capacidade não demonstrada pela inspeção estática.
Não houve nova consulta ao banco nesta revisão.

| Capacidade | Classificação | Evidência e lacuna | Risco / próximo passo |
| --- | --- | --- | --- |
| DDL no dump | IMPLEMENTADO | Estruturas identificadas | Comparar dependências |
| PostgreSQL auditado | CONFIRMADO | 6 tabelas; 88 colunas; 31 restrições; 7 índices; 6 FKs | Escopo limitado |
| Backend Fiscal funcional | AUSENTE | Pacote dedicado só possui inicializador | Planejar implementação após gate |
| API/RBAC/testes fiscais | AUSENTE | Rotas, permissões e testes não encontrados | Definir contratos e autorização |
| Comercial → Fiscal | AUSENTE | Nenhum contrato de consumo da venda | Definir origem, cancelamento e correlação |
| Financeiro ↔ Fiscal | PARCIAL | Fronteira definida; integração fiscal ausente | Definir obrigação e reconciliação |
| Turismo/Bike Tour | AUSENTE | Referências sem documento fiscal | Definir eventual necessidade fiscal |
| Contabilidade | AUSENTE | Fora do Financeiro; sem domínio/API | Deliberar escopo e contrato |
| Migrations fiscais | AUSENTE | Nenhuma das 18 revisions é fiscal | Criar somente após decisão e autorização próprias |
| NFS-e | PARCIAL | Tabela física confirmada; emissão funcional não demonstrada | Obter contrato e homologação |
| Tributos/retenções | PARCIAL | Tabela de alíquota; sem cálculo demonstrado | Definir regras e vigência |
| Apuração | PARCIAL | Tabelas no dump; fluxo não provado | Validar regime e entrega |

## Riscos principais

- Confundir DDL do dump com estado atual do PostgreSQL.
- Marcar documento como emitido sem autorização do provedor e resposta fiscal válida.
- Duplicar a autoridade fiscal entre Comercial, Financeiro e Fiscal.
- Tratar scripts históricos F1-FIN como equivalentes ao dump oficial.
- Definir retenções ou apuração sem validar regime e regras com responsável fiscal.

Na linha de estruturas do dump, **IMPLEMENTADO** descreve exclusivamente a presença de DDL no arquivo oficial.
Não classifica implementação funcional nem presença no PostgreSQL atual.

## Riscos priorizados e natureza da evidência

P0 exige contenção prioritária de segurança antes de ampliar acesso. P1 exige decisão antes da implementação
ou do aceite funcional. P2 exige avaliação de desempenho ou melhoria da rastreabilidade documental.
Prioridade não representa incidente ocorrido. Ausências estruturais não são, isoladamente, defeitos funcionais.

| Prioridade | Achado e natureza | Consequência potencial / encaminhamento |
| --- | --- | --- |
| P0 | `trust` TCP local: falha confirmada | Tratar autenticação em tarefa própria |
| P1 | Sem CHECK: ausência comprovada | Risco de valores inválidos; definir invariantes |
| P1 | Rastreabilidade Comercial/Financeiro: contrato não demonstrado | Modelar origem e reconciliação |
| P1 | Idempotência/estados: desenho não demonstrado | Risco de duplicação; definir transições |
| P1 | Emissão NFS-e: capacidade não comprovada | Não liberar operação pelo default EMITIDA |
| P1 | Sem SELECT/escrita nas 249 tabelas: limitação comprovada | Catálogo não valida dados/fluxos |
| P2 | Sem índices específicos nas FKs: ausência comprovada | Risco de custo em joins; medir antes de criar |
| P2 | Evidência local parcial; demais resultados relatados | Propor aceite limitado e complemento antes do uso estrutural |

O `trust` dispensa senha para conexões que correspondam à regra, portanto exige tratamento antes de ampliar
acesso. A tarefa não corrige essa configuração nem aumenta privilégios de `wma_test`. A rastreabilidade deve
cobrir venda, item, contrato, obrigação financeira, cancelamento e reconciliação. Idempotência deve definir
escopo de unicidade e repetição segura. Os riscos de índices incluem joins e verificações referenciais.

Não há evidência de exploração do `trust`, duplicação de emissão, dados inválidos ou lentidão observada.
As seis PKs, seis FKs e a UNIQUE de `imposto.codigo` estão presentes. As 31 restrições incluem 18 NOT NULL;
não são 31 regras de negócio. A falta de CHECK não comprova ausência de validação em todas as outras camadas.
O inventário estrutural concluído neste recorte não equivale à certificação funcional do módulo Fiscal.

## Encaminhamento das pendências

O fechamento proposto exige identificar e encaminhar lacunas, não implementar suas soluções. As áreas abaixo
são destinos propostos; responsáveis nominais, prazos e execução dependem de aprovação própria.

| Pendência | Destino proposto | Condição para tratamento |
| --- | --- | --- |
| `trust` TCP e privilégios globais | Administração PostgreSQL / segurança | Antes de ampliar acesso |
| Logs completos e dependências fora do recorte | Auditoria / arquitetura de dados | Antes de decisão estrutural dependente |
| CHECK, idempotência e estados | Desenho fiscal e serviços posteriores | Antes de implementar regras afetadas |
| Índices nas FKs | Modelagem / desempenho | Medir necessidade antes de propor migration |
| Vínculos Comercial/Financeiro | Contratos e integrações fiscais | Antes de implementar os fluxos integrados |
| Provedor, regras e emissão NFS-e | Responsável fiscal / integração NFS-e | Antes de homologação e aceite operacional |
| Backend, API, RBAC e testes | Etapas funcionais correspondentes | Antes de certificar o módulo Fiscal |
| Markdownlint/CSpell não executados | Revisão documental | Executar quando disponíveis ou aceitar ressalva |

A solução de `trust` permanece independente: não bloqueia por si só o registro documental do inventário,
não perde prioridade P0 e não é aceita como configuração segura por este fechamento. Sem SELECT nas tabelas,
`wma_test` permite o recorte de catálogo relatado, mas não comprova conteúdo nem comportamento de negócio.

Propõe-se aceitar a rastreabilidade disponível apenas para o recorte da 2.9.1, mediante aprovação explícita.
Comparações integrais com dump/migrations e dependências transitivas ficam fora da conclusão proposta;
devem ser verificadas antes de mudanças que delas dependam. Não se exige homologação NFS-e para concluir inventário.
A ordem oficial continua preservada; estas pendências não são todas atribuídas à 2.9.2, cujo item é serviços.

## Evidências por camada

- `Backend/app/api/v1/router.py` registra Comercial, Corporativo, Financeiro, Segurança, Turismo e Bike Tour;
  não registra Fiscal.
- `Backend/openapi.json` não contém paths fiscais, NFS-e ou nota fiscal.
- `Backend/app/modules/seguranca/authorization.py` possui permissões desses domínios, sem código `FISCAL_*`.
- `Backend/tests/` não possui testes fiscais; `test_architecture.py` exige apenas o pacote de fronteira.
- `Backend/migrations/versions/` contém 18 arquivos até `202609170300`, sem revisão Fiscal.
- A preparação 0.2 usou apenas placeholders, sem ler `.env`. A confirmação posterior identifica
  `wma_phase2_b07_20261001_test`, PostgreSQL 18.4 e `wma_test`; não houve conexão nesta revisão documental.
- O acesso informado restringe-se a catálogo em READ ONLY. A ausência de privilégios nas 249 tabelas não
  comprova restrição global da role em todos os objetos. A autenticação `trust` permanece pendente.

## Histórico de atualização

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 19/10/2026 | Lacunas preliminares a partir da fonte fiscal |
| 0.2 | 19/10/2026 | Evidências estáticas de Backend, integrações, migrations e ambiente |
| 0.3 | 19/10/2026 | Achados físicos recebidos e riscos P0/P1/P2, separados de falhas funcionais não comprovadas |
| 0.4 | 20/10/2026 | Encaminhamento das lacunas e proposta de aceite condicionado da rastreabilidade |

## Saída requerida

Submeter o fechamento documental com ressalvas à aprovação explícita, conforme o [gate](FISCAL_2_9_1_GATE.md).
Não há aceite formal nesta proposta. Qualquer implementação ou alteração estrutural exige escopo próprio,
ADR-004, `Docs/MIGRATIONS.md` quando aplicáveis e gate específico. Não há liberação para produção.

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
