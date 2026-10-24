# WMA Travel ERP — Proposta de Gate da Etapa 2.9.2 — Serviços

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.9.2 — Serviços (Fiscal)
> **Tipo de documento:** Planejamento e proposta de gate
> **Versão:** 0.1
> **Data:** 24/10/2026
> **Status:** PREPARAÇÃO DOCUMENTAL — PROPOSTA NÃO APROVADA

## 1. Objetivo e justificativa

A ordem oficial denomina a 2.9.2 como etapa de serviços, mas não especifica casos de uso, contratos ou regras
aprovados. Esta proposta descreve as decisões e evidências necessárias antes de autorizar qualquer implementação.
Preparar este gate não inicia a etapa nem autoriza código, migrations, conexão a banco, homologação ou produção.

## 2. Escopo proposto

Após aprovação do gate, o trabalho poderá implementar somente serviços fiscais associados a casos de uso aprovados,
com contratos, validação, erros, limites de domínio, autorização, auditoria, transações e testes definidos antes da
implementação. Cada serviço deverá apontar para requisitos, fonte de dados, resultados e critérios de teste.

O escopo funcional exato permanece pendente. As fontes consultadas não especificam operações fiscais completas,
atores, regras tributárias, estados de emissão ou integrações externas para esta etapa.

## 3. Itens fora do escopo desta proposta

- Implementação antes da aprovação formal do gate e do escopo funcional.
- Autorização para produção, certificação funcional ou aceite de segurança.
- Emissão ou cancelamento de NFS-e e integração com provedor, salvo inclusão expressa e aprovação de contrato próprio.
- Regras legais de tributos, retenções, apuração e obrigações acessórias sem fonte normativa e responsável fiscal
  identificados e aprovados.
- Contabilidade, interface React, aplicativo Flutter e alterações nas etapas 2.8 ou 2.10–2.14.
- Migration ou alteração de schema sem decisão documentada e gate próprio.
- Conexão a PostgreSQL enquanto a configuração de segurança do ambiente não tiver sido verificada e tratada ou
  formalmente aceita pela autoridade de segurança competente.

## 4. Dependências da Etapa 2.9.1

Antes da aprovação de entrada da 2.9.2, deve existir decisão formal sobre a 2.9.1, incluindo o resultado da
rastreabilidade: aceitação explícita dos limites registrados ou complementação das evidências seguida de revisão.
A 2.9.1 permanece com gate aberto até essa decisão.

A pendência PostgreSQL `trust` é P0 e independente do fechamento documental. Seu estado atual não está verificado.
Antes de qualquer conexão, o ambiente alvo precisa de verificação autorizada e tratamento ou aceite de segurança
específico; este documento não concede esse aceite.

A 2.8 permanece em HOLD conforme a ADR-021. A sequência oficial 2.8, 2.9 e 2.10–2.14 não é alterada. A preparação
da 2.9.2 não antecipa, substitui ou certifica qualquer etapa.

## 5. Requisitos identificados e propostas

| Tema | Requisito documentado | Proposta para aprovação |
| --- | --- | --- |
| Ordem | A ordem executiva chama 2.9.2 de serviços | Aprovar casos de uso e atores antes de desenhar serviços |
| Fronteiras | Fiscal é autoridade do cálculo fiscal; Financeiro controla a obrigação recebida | Mapear contratos sem duplicar autoridades |
| Comercial | Comercial é autoridade da venda | Definir origem, referência e reconciliação se o caso usar venda |
| API | API versionada, autorização e respostas padronizadas são requisitos do projeto | Definir rotas apenas se a API fizer parte do escopo aprovado |
| Dados | Há estruturas fiscais no inventário e no dump oficial | Associar cada campo usado a um caso de uso e autoridade |
| Regras fiscais | As fontes consultadas não definem regras completas para esta etapa | Exigir fonte normativa e aprovação do responsável fiscal |
| Segurança | Mínimo privilégio, SCRAM-SHA-256, RBAC e auditoria são diretrizes vigentes | Especificar matriz de permissões, eventos auditáveis e proteção por operação |
| Transações | O desenho Financeiro define atomicidade local e reexecução idempotente para aquele domínio | Definir política fiscal própria sem copiar regras financeiras automaticamente |
| Banco | Baseline certificada e migrations Alembic aditivas são normativas | Decidir formalmente se cada caso exige mudança de schema |

Os itens da coluna “Proposta” não são requisitos aprovados nem autorização de implementação.

## 6. Fontes de verdade

- Ordem e status das etapas: [PHASE_2_EXECUTION_ORDER.md](PHASE_2_EXECUTION_ORDER.md) e
  [PHASE_2_ROADMAP.md](PHASE_2_ROADMAP.md).
- Reprogramação e HOLD da 2.8: [ADR-021](architecture/ADR-021-PHASE-2-EXECUTION-REPROGRAMMING.md).
- Inventário, evidências e lacunas: [FISCAL_2_9_1_INVENTORY.md](FISCAL_2_9_1_INVENTORY.md) e
  [FISCAL_2_9_1_GAP_ANALYSIS.md](FISCAL_2_9_1_GAP_ANALYSIS.md).
- DDL de referência: `Database/scripts/WmaTravelERP.sql`; a baseline não demonstra o estado atual de outro banco.
- Autoridades Fiscal/Financeiro: [FINANCIAL_IMPLEMENTATION_DESIGN.md](FINANCIAL_IMPLEMENTATION_DESIGN.md).
- Contratos e aprovação de API, quando aplicáveis: [API_CHANGE_GOVERNANCE.md](API_CHANGE_GOVERNANCE.md) e
  [API_RESPONSE_MATRIX.md](API_RESPONSE_MATRIX.md).
- Acesso, segurança e migrações: [SECURITY.md](SECURITY.md), [GOVERNANCE.md](GOVERNANCE.md),
  [DATABASE_STANDARDS.md](DATABASE_STANDARDS.md) e [MIGRATIONS.md](MIGRATIONS.md).

Não foi localizada nas fontes consultadas uma especificação fiscal aprovada de regras legais, regimes, retenções,
apuração ou provedores para os serviços da 2.9.2. Essa fonte e seu responsável devem ser identificados antes de
aprovar operações que dependam dela.

## 7. Inventário estrutural candidato

O inventário abaixo é informativo para desenho futuro. Não define quais objetos ou colunas serão usados, porque os
casos de uso ainda não foram aprovados.

### 7.1 Colunas no dump oficial

As listas a seguir foram lidas estaticamente do dump oficial e não representam verificação do PostgreSQL atual.

- `public.nota_fiscal` — 20 colunas: `id_nota_fiscal`, `id_empresa`, `id_cliente`, `numero_nf`, `serie`,
  `tipo_documento`, `data_emissao`, `competencia`, `valor_servico`, `base_calculo`, `valor_iss`, `status`,
  `chave_acesso`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`, `deleted_by`, `versao`.
- `public.integracao_nfse` — 9 colunas: `id_integracao`, `id_nota_fiscal`, `provedor`, `codigo_retorno`,
  `mensagem`, `xml_envio`, `xml_retorno`, `status`, `created_at`.
- `public.imposto` — 12 colunas: `id_imposto`, `codigo`, `descricao`, `tipo`, `aliquota`, `created_at`,
  `updated_at`, `deleted_at`, `created_by`, `updated_by`, `deleted_by`, `versao`.
- `public.declaracao_fiscal` — 15 colunas: `id_declaracao`, `id_empresa`, `tipo_declaracao`, `ano`, `periodo`,
  `data_entrega`, `status`, `observacao`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`,
  `deleted_by`, `versao`.
- `public.das` — 16 colunas: `id_das`, `id_empresa`, `competencia`, `receita_bruta`, `aliquota`, `valor_das`,
  `data_vencimento`, `data_pagamento`, `status`, `created_at`, `updated_at`, `deleted_at`, `created_by`,
  `updated_by`, `deleted_by`, `versao`.
- `public.simples_nacional` — 15 colunas: `id_simples`, `id_empresa`, `ano`, `anexo`, `aliquota_efetiva`,
  `faturamento_12_meses`, `faixa`, `rbt12`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`,
  `deleted_by`, `versao`.

### 7.2 Constraints, índices e relações reportados

O snapshot de teste reportado na 2.9.1 contém seis PKs, seis FKs, uma UNIQUE e 18 NOT NULL, totalizando 31
constraints; não registra CHECK. Os sete índices reportados correspondem a seis PKs e ao índice da UNIQUE de
`imposto.codigo`. Não foram reportados índices específicos nas FKs. Essas contagens não provam paridade com o dump
nem com o estado atual de qualquer banco.

As relações reportadas são: `nota_fiscal` → `empresa` e `cliente`; `integracao_nfse` → `nota_fiscal`; e cada uma de
`das`, `simples_nacional` e `declaracao_fiscal` → `empresa`. As fontes e limitações estão descritas no inventário
2.9.1 e no arquivo de evidência de constraints.

### 7.3 Divergência de contagem a reconciliar

O inventário fornecido do banco de teste informa 19 colunas em `nota_fiscal` e 17 em `simples_nacional`. A leitura
estática do dump oficial encontrou, respectivamente, 20 e 15. As outras quatro tabelas têm contagens iguais nas
duas fontes. O total informado para o banco de teste é 88; o total contado no dump é 87.

Não há log completo das colunas do banco de teste que permita identificar quais campos divergem. Essa diferença
não permite concluir qual fonte corresponde ao banco alvo nem deve ser corrigida por suposição. Reconciliar as
definições por procedimento autorizado antes de qualquer serviço ou migration que dependa desses objetos.

## 8. Segurança, autorização, auditoria e dados

Antes de aprovar cada caso de uso, documentar:

- ator, identidade autenticada, permissões necessárias e matriz de autorização;
- dados pessoais e fiscais tratados, finalidade, minimização, retenção e acesso;
- eventos de auditoria, correlação e política para dados sensíveis em logs;
- comportamento de falhas, repetição, concorrência e separação de transações entre domínios;
- ambiente permitido, credenciais e mecanismo de autenticação aprovado.

Nenhum acesso a banco é autorizado por esta proposta. O risco `trust` permanece não verificado e não é aceito por
este documento.

## 9. Estratégia de testes e CI proposta

Após autorização de implementação, propor e aprovar uma matriz que cubra:

- testes unitários de validação, regras e transições especificadas;
- testes de integração de repositories e transações em banco descartável identificado;
- testes de API e contrato, inclusive autenticação, autorização, erros e compatibilidade quando aplicável;
- repetição idempotente, concorrência, rollback e falhas externas para casos que os envolvam;
- regressão dos domínios Comercial, Financeiro e Core sem alterar suas autoridades;
- validadores locais documentados e checks de CI realmente executados no PR.

Os workflows versionados incluem Backend CI, Documentation CI e Secret Scan. A existência dos workflows não é
resultado de execução; nenhuma aprovação de CI é declarada aqui.

## 10. Critérios objetivos de entrada

Todos os itens abaixo devem ser demonstrados e registrados antes da autorização de implementação:

1. Decisão formal da 2.9.1 registrada, com resultado explícito sobre os limites de rastreabilidade ou evidência
   complementar aprovada.
2. Casos de uso da 2.9.2, atores, entradas, saídas, erros e limites de domínio aprovados pelo responsável.
3. Responsável de negócio por regras fiscais identificado; fontes normativas aplicáveis referenciadas.
4. Campos, tabelas e relações pertinentes vinculados aos casos de uso; divergência de contagem entre snapshot e
   dump reconciliada por evidência autorizada.
5. Invariantes, estados, idempotência, transações e recuperação de falhas definidos para as operações aplicáveis.
6. Matriz de permissões, auditoria e tratamento de dados aprovada.
7. Decisão de schema registrada; migration, se necessária, aprovada em gate próprio conforme ADR-004 e
   `MIGRATIONS.md`.
8. Ambiente de testes descartável, plano de teste e checks de CI aplicáveis identificados.
9. Para qualquer conexão a banco, configuração de segurança do ambiente confirmada e `trust` tratado ou aceito
   explicitamente pela autoridade de segurança competente.
10. Gate e escopo da 2.9.2 aprovados formalmente pelo responsável do projeto. Aprovação não significa produção.

## 11. Critérios objetivos de saída

Para encerrar a etapa após futura implementação autorizada:

- cada requisito aprovado rastreia caso de uso, serviço, contrato, dados, autorização e teste;
- implementação corresponde somente ao escopo aprovado e não duplica autoridade entre domínios;
- testes requeridos passam em ambiente permitido; falhas e riscos residuais são registrados;
- migrations, se houver, passam pelo processo próprio e preservam baseline e histórico;
- documentação e evidências refletem o resultado real; CI só é declarado aprovado com execução observável;
- o responsável registra decisão de saída, escopo e data; não se infere certificação integral nem produção.

## 12. Riscos e decisões pendentes

| Item | Estado | Decisão ou evidência necessária |
| --- | --- | --- |
| Fechamento da 2.9.1 | Gate aberto | Decisão formal e resultado de rastreabilidade |
| `trust` P0 | Não verificado | Ambiente e procedimento autorizado de segurança |
| Divergência de colunas | Não reconciliada | Inventário reproduzível do ambiente alvo ou decisão de fonte |
| Casos de uso e regras | Não especificados | Aprovação de negócio e fonte normativa |
| Responsável fiscal | Não confirmado nesta proposta | Identificar papel e responsável sem presunção |
| Schema e migrations | Necessidade desconhecida | Decisão por caso de uso e gate próprio |
| NFS-e e provedor | Contratos não demonstrados | Excluir ou aprovar escopo, ambiente e contratos específicos |

## 13. Incrementos de implementação propostos

Após aprovação, executar em incrementos pequenos; cada incremento depende do escopo autorizado:

1. Baseline de requisitos, atores, fronteiras e contratos internos.
2. Schemas e validações de entrada/saída para os casos aprovados.
3. Regras puras de domínio e testes unitários.
4. Persistência e transações; migration apenas se necessária e autorizada.
5. Endpoints, RBAC, auditoria e testes de contrato, se API estiver no escopo.
6. Integrações externas e idempotência apenas se explicitamente incluídas e homologadas.
7. Regressão, evidências de CI e decisão formal do gate de saída.

Esta sequência é proposta e não autoriza iniciar qualquer incremento.

## 14. Condições para solicitar autorização de implementação

Submeter ao responsável um pacote revisável com: decisão da 2.9.1; casos de uso e fontes aprovados; matriz de
requisitos e dados; limites de domínio; controles de segurança; decisão de schema; ambiente de testes; incrementos,
critérios de aceite e riscos residuais. A autorização deve indicar explicitamente escopo e etapa. Até então, a
2.9.2 permanece **NÃO AUTORIZADA PARA IMPLEMENTAÇÃO**.

## 15. Decisão e estado

Esta proposta não foi aprovada. Ela não registra aceite de rastreabilidade, segurança ou regras fiscais. A 2.9.1
permanece **EM EXECUÇÃO**, com gate **ABERTO**; a 2.8 permanece em **HOLD**; a 2.9.2 está em **PREPARAÇÃO
DOCUMENTAL**, sem autorização de implementação. Não há certificação funcional nem liberação para produção.

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 0.1 |
| Status | PREPARAÇÃO DOCUMENTAL — PROPOSTA NÃO APROVADA |
| Última atualização | 24/10/2026 |
| Repositório | VANER/WMA-Travel-ERP |
| Documento mestre | [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
