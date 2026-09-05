# Inventário de Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6.1 — Inventário de Turismo (`TUR-DOC-01`)
> **Módulo:** Turismo
> **Tipo de documento:** Documento Técnico
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Limite deste inventário

Este documento identifica o estado existente e as decisões necessárias antes da implementação. Ele não cria
models, migrations, endpoints, serviços nem regras funcionais e não altera a baseline certificada da Fase 1.

Fontes inspecionadas:

- `Database/scripts/WmaTravelERP.sql`;
- `Docs/DATA_DICTIONARY.md`;
- `Docs/PHASE_2_EXECUTION_ORDER.md` e `Docs/PHASE_2_ROADMAP.md`;
- models registrados em `Backend/app` e contrato `Backend/openapi.json`;
- catálogo PostgreSQL de uma reconstrução local da baseline.

## 2. Autoridade e fronteiras

Não existe schema `turismo` na baseline. As estruturas operacionais estão em `public`, que deve ser preservado
como autoridade até decisão arquitetural e migration aditiva aprovadas. A ausência de schema dedicado não autoriza
mover ou duplicar tabelas.

| Domínio | Autoridade consumida por Turismo |
| --- | --- |
| Core Corporativo | `localidade`, `cliente` e `fornecedor` |
| Comercial | `produto_turistico` em item de venda; venda e contrato |
| Financeiro | obrigações e recebimentos originados pela operação comercial |
| Turismo | produto, pacote, roteiro, reserva, passageiro e operação da viagem |
| Bike Tour | especialização futura; não integra o escopo desta etapa |

## 3. Objetos operacionais encontrados

Foram identificadas 13 tabelas diretamente relacionadas ao domínio:

| Tabela | Papel observado | Relações declaradas |
| --- | --- | --- |
| `public.destino` | Destino comercial e operacional | `localidade` |
| `public.produto_turistico` | Catálogo de produto turístico | nenhuma FK própria |
| `public.pacote_viagem` | Oferta datada, preço e capacidade | `produto_turistico` |
| `public.roteiro_viagem` | Trecho ou período do roteiro | `pacote_viagem`, `destino` |
| `public.reserva` | Reserva de cliente em pacote | `cliente`, `pacote_viagem` |
| `public.passageiro` | Viajante associado à reserva | `reserva` |
| `public.fornecedor_turistico` | Especialização de fornecedor | `fornecedor` |
| `public.guia_turistico` | Cadastro operacional de guia | nenhuma FK própria |
| `public.hospedagem` | Oferta de hospedagem | `fornecedor_turistico` |
| `public.transporte` | Recurso de transporte | `fornecedor_turistico` opcional |
| `public.custo_pacote` | Composição estimada de custo | `pacote_viagem` |
| `public.checklist_viagem` | Item operacional do pacote | `pacote_viagem` |
| `public.avaliacao_pos_viagem` | Avaliação posterior | `reserva` |

Todos os objetos possuem chave primária. Destino, produto, pacote e reserva possuem unicidade declarada em seus
identificadores de negócio. As relações acima existem como foreign keys na baseline.

## 4. Estruturas relacionadas, mas fora da autoridade direta

- `public.item_venda` referencia `produto_turistico`, mas não existe FK de venda ou item de venda para reserva;
- `public.comissao` referencia reserva, fornecedor e pertence à fronteira Comercial/Financeiro;
- `public.dim_destino`, `public.dim_produto_turistico` e `public.kpi_turismo` são estruturas analíticas, não fontes
  transacionais;
- `produto_estoque` representa estoque administrativo e não deve ser confundido com vaga de saída turística.

## 5. Cobertura do roteiro oficial

| Capacidade da 2.6 | Evidência atual | Classificação |
| --- | --- | --- |
| Destinos | `destino` e `localidade` | Parcialmente coberta |
| Produtos turísticos | `produto_turistico` | Coberta estruturalmente |
| Pacotes | `pacote_viagem` | Parcialmente coberta |
| Roteiros | `roteiro_viagem` | Parcialmente coberta |
| Serviços | hospedagem e transporte isolados | Lacuna de catálogo e composição |
| Saídas | datas e vagas estão em `pacote_viagem` | Conceito não separado |
| Disponibilidade e vagas | `quantidade_vagas`, sem alocação | Lacuna transacional |
| Reservas | `reserva` | Parcialmente coberta |
| Passageiros | `passageiro` | Parcialmente coberta |
| Fornecedores turísticos | `fornecedor_turistico` | Coberta estruturalmente |
| Operação | `checklist_viagem` | Cobertura mínima |
| Acompanhamento | avaliação posterior apenas | Lacuna operacional |

## 6. Lacunas e riscos comprovados

1. `produto_turistico.destino` armazena texto enquanto `destino` é uma autoridade estruturada; não há FK entre
   esses conceitos.
2. Pacote acumula catálogo, período de saída, preço e capacidade, sem entidade própria de saída.
3. Não há controle de vaga reservada, bloqueada, liberada ou expirada, nem versão para concorrência de capacidade.
4. Reserva não referencia venda, item de venda ou contrato, impedindo rastreabilidade transacional ponta a ponta.
5. Hospedagem e transporte não possuem composição com pacote, roteiro ou reserva.
6. Não há catálogo genérico de serviço, serviço da reserva, alocação de guia ou recurso operacional.
7. Guia duplica nome, telefone e e-mail sem vínculo declarado com pessoa ou fornecedor.
8. Passageiro armazena nome, CPF e documento diretamente, sem política registrada de minimização, acesso ou
   retenção.
9. A maioria das tabelas possui trigger de `updated_at`, mas nenhuma das 13 apresenta trigger de log de auditoria.
10. `avaliacao_pos_viagem` possui apenas `created_at`; faltam o conjunto comum de auditoria e trigger de atualização.
11. Status de pacote, reserva e checklist são texto livre ou defaults sem catálogos e transições documentadas.
12. Não existem contratos de API de Turismo no OpenAPI atual nem models funcionais em `app/modules/turismo`.

As lacunas são insumos documentais. Qualquer correção estrutural futura deve usar migration nova, preservar nomes e
dados certificados e ser precedida por decisão explícita em `TUR-DOC-08`.

## 7. Decisões exigidas antes da implementação

- distinguir produto, pacote comercial e saída operacional;
- definir capacidade, disponibilidade, bloqueio, confirmação e liberação de vaga;
- decidir a raiz transacional entre venda, contrato e reserva;
- modelar serviços, composição do pacote e serviços efetivamente reservados;
- definir atribuição de fornecedor, guia, hospedagem e transporte;
- aprovar estados e transições de pacote, saída, reserva e operação;
- definir cancelamento, reacomodação, no-show e compensações com Comercial e Financeiro;
- aprovar política de privacidade e autorização para passageiros;
- avaliar o delta de auditoria e schema sem alteração retroativa da baseline.

## 8. Conclusão

O inventário `TUR-DOC-01` está aprovado. A baseline oferece um núcleo aproveitável, mas não comprova o fluxo
operacional completo previsto para a 2.6. Os entregáveis sucessores `TUR-DOC-02` a `TUR-DOC-05` também foram
aprovados, e a próxima entrega autorizada é `TUR-DOC-06` — Segurança e privacidade. A implementação continua
bloqueada até a aprovação integral do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6.1 — Inventário de Turismo |
| Entregável | `TUR-DOC-01` |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
