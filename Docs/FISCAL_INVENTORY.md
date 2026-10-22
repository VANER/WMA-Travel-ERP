# WMA Travel ERP — Início do Inventário Fiscal 2.9.1

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.9.1 — Inventário fiscal
> **Tipo de documento:** Levantamento técnico preliminar
> **Versão:** 0.1
> **Data:** 18/10/2026
> **Status:** INICIADO — NÃO CERTIFICADO

## 1. Objetivo e escopo

Iniciar o inventário fiscal solicitado pelo responsável, registrando estruturas existentes e pendências.
Este incremento é documental: não define regras tributárias, não implementa API e não altera schema.
As seções de arquitetura, implementação e testes do modelo técnico foram consolidadas abaixo porque
não há implementação fiscal nova nesta entrega.

## 2. Contexto e ordem de execução

A [ordem oficial](PHASE_2_EXECUTION_ORDER.md) identifica Fiscal como 2.9 e inventário fiscal como seu
primeiro item. As dependências declaradas são Comercial e Financeiro. O início deste levantamento decorre
da solicitação de auditoria 2.7, limpeza e início 2.9.1, em 18/10/2026.

O AGENTS.md e a ordem imediata ainda apontam para 2.8.1. Essa divergência de planejamento permanece explícita:
o levantamento fiscal não encerra, substitui nem certifica o
[inventário externo da 2.8](WEBSITE_INTEGRATION_PREPARATION.md).
A reconciliação do cronograma e da execução corrente permanece pendente.

## 3. Auditoria documental e Git da 2.7

O [fechamento final](certification/PHASE_2_7_BIKE_TOUR_FINAL_CLOSURE.md) registra a certificação e os gates
históricos. Eles não foram executados novamente nesta inspeção.

| Verificação local | Resultado em 18/10/2026 |
| --- | --- |
| HEAD observado | `180beca` |
| Ancestralidade do merge funcional `ffcc09e` em HEAD | Confirmada; comando Git retornou 0 |
| Ancestralidade do fechamento `d1d79de` em HEAD | Confirmada; comando Git retornou 0 |
| Alteração local preexistente | `.vscode/settings.json`; preservada |
| `git diff --check` inicial | Sem erros |
| CI remoto e PostgreSQL | Não reexecutados nem consultados nesta inspeção |

A conclusão desta inspeção é limitada à coerência documental e à ancestralidade local.
Não constitui nova certificação funcional, auditoria integral de segurança ou validação de produção.

## 4. Estruturas candidatas identificadas

Fonte: declarações de tabelas do [dump oficial](../Database/scripts/WmaTravelERP.sql), sem leitura de registros.
O nome de uma coluna não comprova FK; constraints e dependências ainda precisam ser inventariadas.

| Objeto existente | Evidência ou papel candidato | Ponto a esclarecer |
| --- | --- | --- |
| `public.nota_fiscal` | Empresa, cliente, competência, valores e status | Emissão, cancelamento e vínculo à venda |
| `public.integracao_nfse` | Nota, provedor, XML de envio e retorno | Contrato, proteção e idempotência |
| `public.imposto` | Código, tipo e alíquota | Vigência, precisão e regras aplicáveis |
| `public.declaracao_fiscal` | Empresa, período, entrega e status | Obrigações cobertas e ciclo de estados |
| `public.das` | Tabela presente no dump | Colunas, vínculos e autoridade |
| `public.simples_nacional` | Tabela presente no dump | Colunas, vigência e autoridade |

Em `nota_fiscal`, os valores observados usam `numeric(15,2)` e o status tem default `EMITIDA`.
Esse default histórico não comprova autorização de emissão por provedor externo e deve ser avaliado antes
de qualquer serviço de emissão. Em `imposto`, a alíquota observada usa `numeric(5,2)`.
Não há decisão de alterar essas estruturas neste levantamento.

## 5. Fronteiras e implementação existente

O [desenho financeiro](FINANCIAL_IMPLEMENTATION_DESIGN.md) atribui cálculo fiscal ao Fiscal e controle da
obrigação tributária recebida ao Financeiro. O [inventário financeiro](FINANCIAL_INVENTORY.md) distingue
o dump oficial dos scripts históricos F1-FIN; eles não devem ser tratados como estados equivalentes.

O diretório `Backend/app/modules/fiscal/` contém apenas `__init__.py`, com a descrição da fronteira do domínio.
O levantamento completo de models, services, repositories, rotas e testes fiscais ainda está pendente.
A evolução Alembic deve ser confrontada com o dump antes de concluir ausência de objetos no estado atual.

## 6. Limpeza e preservação

Foram encontrados backups `.bak` locais em `Docs/` e `Backend/`. A consulta `git ls-files '*.bak'`
não retornou arquivos versionados. Ausência de versionamento não prova que um backup seja descartável.
Nenhuma exclusão foi executada nesta etapa; a limpeza depende da classificação de conteúdo e utilidade.
Os dez backups examinados em `Docs/` têm hashes diferentes dos respectivos documentos atuais;
portanto, não são cópias idênticas que possam ser removidas por deduplicação simples.
Alterações do usuário, baseline, certificações, logs históricos e migrations aplicadas permanecem preservados.

## 7. Pendências e critérios de conclusão

- Mapear colunas, PKs, FKs, índices, constraints, comentários, funções, triggers e views dos objetos candidatos.
- Confrontar dump, migrations aplicáveis e catálogo de banco local descartável explicitamente identificado.
- Inventariar código e testes existentes, incluindo obrigações tributárias no Financeiro.
- Definir vínculos com venda, serviço, empresa, cliente e obrigação financeira sem duplicar autoridades.
- Obter requisitos do responsável fiscal: operações, município, regime, provedor e homologação aplicáveis.
- Definir proteção e retenção de documentos e payloads, sem versionar dados pessoais ou credenciais.
- Classificar lacunas como reaproveitamento, decisão de domínio ou possível migration aditiva.
- Revisar o inventário e reconciliar o planejamento antes de declarar a 2.9.1 concluída.

## 8. Validação e rastreabilidade

Foram consultados documentos locais, declarações de tabelas e histórico Git.
Não foram executados testes Backend, health check, restauração, migrations ou chamadas a provedor fiscal.
Não há afirmação de conformidade tributária neste inventário técnico preliminar.

| Requisito | Evidência | Estado |
| --- | --- | --- |
| Auditar fechamento da 2.7 | Seção 3 e fechamento final existente | Inspeção documental e Git realizada |
| Limpar sem perder trabalho local | Seção 6 | Classificação iniciada; sem exclusões |
| Iniciar 2.9.1 | Seções 4, 5 e 7 | Levantamento iniciado; conclusão pendente |

## 9. Controle e resultado

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 18/10/2026 | Início documental, inspeção da 2.7 e registro das pendências |

Resultado: inventário fiscal iniciado, sem mudança funcional e sem certificação da 2.9.1.
