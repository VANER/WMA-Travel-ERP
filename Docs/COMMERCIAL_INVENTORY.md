# Inventário Comercial

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.4.1 — Inventário Comercial

**Data do levantamento:** 30/08/2026

**Status:** APROVADO E CERTIFICADO; INTEGRAÇÃO PENDENTE

## 2. Objetivo e limites

Este inventário identifica as estruturas comerciais da baseline antes de qualquer migration ou implementação
funcional das etapas 2.4.2 a 2.4.13. Ele não cria models, tabelas, endpoints ou novas regras de negócio.

Fontes consultadas:

- `Database/scripts/WmaTravelERP.sql`, dump oficial e autoridade estrutural;
- `Docs/DATA_DICTIONARY.md`, catálogo da baseline;
- `Docs/DATABASE_STANDARDS.md`, regras normativas de banco;
- `Docs/ARCHITECTURE.md`, fronteiras modulares;
- `Docs/PHASE_2_ROADMAP.md` e `Docs/PHASE_2_EXECUTION_ORDER.md`, escopo e sequência autorizados;
- ADR-001, ADR-003, ADR-004 e ADR-017.

## 3. Autoridade e fronteira do domínio

O schema `public` é a autoridade dos dados comerciais. O futuro código funcional permanece reservado a
`app/modules/comercial`; o pacote existente contém apenas sua marcação de fronteira. As entidades `Cliente` e
`Fornecedor` já refletidas em `app/modules/corporativo` continuam sendo autoridades cadastrais compartilhadas.
O Comercial deve consumir essas identidades sem duplicar models ou transferir sua propriedade.

`financeiro.cliente`, `financeiro.fornecedor`, `public.dim_cliente`, `public.fato_vendas`, `dw.dim_cliente`,
`dw.dim_fornecedor` e `dw.fato_vendas` não são autoridades transacionais do Comercial. As tabelas financeiras são
representações legadas do módulo Financeiro; dimensões e fatos são projeções analíticas.

`public.vw_dashboard_comercial_bi` também é uma projeção analítica: agrega `public.fato_vendas` por canal e não
deve ser usada como fonte transacional para vendas, receita ou margem.

## 4. Objetos comerciais existentes

### 4.1 Cadastro e relacionamento

| Objeto | Identidade | Papel | Dependências diretas |
| --- | --- | --- | --- |
| `public.cliente` | `id_cliente` | Papel comercial de uma pessoa | `public.pessoa` |
| `public.contato_cliente` | `id_contato` | Histórico de contato com cliente | `public.cliente` |
| `public.fornecedor` | `id_fornecedor` | Papel fornecedor de uma pessoa | `public.pessoa` |
| `public.fornecedor_turistico` | `id_fornecedor_turistico` | Especialização turística | `public.fornecedor` |

`public.fornecedor_turistico` pertence funcionalmente ao Turismo. O Comercial pode referenciar a identidade do
fornecedor, mas não deve absorver categoria, registro ou regras turísticas.

### 4.2 Leads e funil

| Objeto | Identidade | Papel | Dependências diretas |
| --- | --- | --- | --- |
| `public.origem_lead` | `id_origem` | Catálogo de origens | Nenhuma |
| `public.lead` | `id_lead` | Prospect comercial | `public.origem_lead` opcional |
| `public.interacao_lead` | `id_interacao` | Histórico de interação | `public.lead` |
| `public.funil_vendas` | `id_funil` | Movimento do lead no funil | `public.lead` |

`public.funil_vendas` registra movimentos com etapa, probabilidade, valor e data. Não existe uma tabela
`public.oportunidade`; portanto, o funil não deve ser reinterpretado silenciosamente como agregado Oportunidade.

### 4.3 Estruturas comerciais isoladas

| Objeto | Identidade | Papel aparente | Relações estruturais |
| --- | --- | --- | --- |
| `public.campanha` | `id_campanha` | Campanha, canal e investimento | Nenhuma |
| `public.parceiro_comercial` | `id_parceiro` | Parceiro e percentual de comissão | Nenhuma |

As duas tabelas possuem nomes e atributos comerciais, mas não são referenciadas pelo fluxo inventariado e não
possuem `COMMENT ON TABLE` que defina sua responsabilidade. A baseline não relaciona Campanha a Origem ou Lead,
nem Parceiro Comercial a Fornecedor, Venda, Reserva ou Comissão. Sua propriedade funcional permanece pendente e
não autoriza incorporação automática ao módulo Comercial.

### 4.4 Vendas e itens

| Objeto | Identidade | Papel | Dependências diretas |
| --- | --- | --- | --- |
| `public.venda` | `id_venda` | Cabeçalho da venda | `public.cliente` |
| `public.item_venda` | `id_item` | Item comercializado | `public.venda` e `public.produto_turistico` |

O vínculo de `public.item_venda` com `public.produto_turistico` cruza a fronteira do futuro módulo Turismo. A
etapa de Vendas deverá preservar essa dependência sem antecipar a implementação funcional de Turismo. A baseline
não declara unicidade para `public.venda.numero_venda` nem checks para quantidade, valores, desconto ou status.

### 4.5 Comissões e contratos

| Objeto | Identidade | Papel | Dependências diretas |
| --- | --- | --- | --- |
| `public.comissao` | `id_comissao` | Comissão por reserva e fornecedor | `public.reserva` e `public.fornecedor` |
| `public.comissao_colaborador` | `id_comissao` | Comissão interna por venda | `public.colaborador` e `public.venda` |
| `public.contrato` | `id_contrato` | Metadados contratuais | `public.documento` |

As duas tabelas de comissão representam fatos diferentes e reutilizam o nome `id_comissao` sem relação entre si.
`public.comissao` depende de Reserva, pertencente ao futuro módulo Turismo. `public.contrato` não possui foreign
key direta para cliente, venda ou reserva; as partes são texto livre e o único vínculo estrutural é Documento.

## 5. Cobertura do roteiro funcional

| Capacidade planejada | Evidência na baseline | Classificação para implementação |
| --- | --- | --- |
| clientes | `public.cliente`, `public.contato_cliente` | Reutilizar autoridade do Core |
| leads | `public.origem_lead`, `public.lead`, `public.interacao_lead` | Existente |
| CRM | contatos e interações separados | Cobertura parcial, sem agregado próprio |
| fornecedores | `public.fornecedor` | Reutilizar autoridade do Core |
| operadoras | nenhuma tabela explícita | Modelo pendente de decisão |
| oportunidades | `public.funil_vendas` apenas | Cobertura parcial, sem identidade própria |
| propostas e itens | nenhuma tabela explícita | Modelo pendente de migration aditiva |
| condições comerciais | desconto em `public.venda` | Cobertura parcial, sem catálogo ou vigência |
| comissões | duas tabelas com dependências distintas | Existente, exige separar responsabilidades |
| vendas e itens | `public.venda`, `public.item_venda` | Existente |
| contratos | `public.contrato` | Existente, sem vínculo comercial direto |

Não há tabelas explícitas chamadas `operadora`, `oportunidade`, `proposta`, `item_proposta` ou
`condicao_comercial` no dump oficial. Essas ausências não autorizam criar estruturas antes das respectivas
subetapas e de uma decisão de modelagem rastreável.

## 6. Fluxos comprovados e lacunas

Relações comprovadas pela baseline:

```text
origem_lead → lead → funil_vendas

pessoa → cliente → venda → item_venda → produto_turistico

pessoa → fornecedor → comissao → reserva

colaborador → comissao_colaborador → venda

documento → contrato
```

O fluxo planejado `Lead → Oportunidade → Cliente → Proposta → Venda → Reserva/Contrato` não é íntegro na
baseline: não há conversão estrutural de lead para cliente, identidades de oportunidade e proposta, vínculo de
proposta com venda, vínculo de venda com reserva ou vínculo comercial direto do contrato.

## 7. Inconsistências e decisões pendentes

- contatos e interações registram responsáveis em texto, sem identidade de usuário ou colaborador;
- Campanha e Parceiro Comercial estão isolados, sem foreign keys para o fluxo comercial;
- status, etapas e tipos são textos livres, sem catálogo ou checks de domínio;
- `public.funil_vendas` registra movimentos, mas não identifica uma oportunidade independente;
- `public.venda.numero_venda` não possui constraint única;
- `public.item_venda` não possui checks de quantidade e valores;
- valores derivados de venda e item não são colunas geradas nem possuem validação de consistência;
- comissões não possuem checks de percentual ou valor e têm fronteiras distintas;
- `public.contrato` não contém as colunas completas de autoria e versão exigidas pelo padrão atual;
- `public.interacao_lead` possui apenas `created_at` e não contém o conjunto de auditoria exigido pelo padrão atual;
- `public.contrato` e `public.interacao_lead` não possuem trigger de atualização da baseline;
- tabelas comerciais alternam nulabilidade nas colunas de auditoria e não devem ser corrigidas retroativamente;
- nomes históricos como `funil_vendas`, `id_item`, `id_origem` e `id_contato` divergem do padrão normativo atual;
- as tabelas comerciais inventariadas não possuem `COMMENT ON TABLE` ou `COMMENT ON COLUMN` no dump oficial;
- não existe regra estrutural de conversão ou rastreabilidade entre as etapas do fluxo comercial.

Esses pontos pertencem à baseline e devem ser preservados até que a subetapa proprietária autorize uma migration
nova. Models futuros devem refletir o banco existente e não inventar relacionamentos ausentes.

## 8. Sequência recomendada para 2.4.2 a 2.4.10

1. reutilizar `Cliente` e `Fornecedor` do Core por contratos internos;
2. mapear leads, origem, interações e funil sem reinterpretar lacunas;
3. decidir se Oportunidade será agregado próprio ou evolução explícita do funil;
4. criar Proposta e seus itens por migration aditiva antes de implementar o fluxo;
5. formalizar condições comerciais e regras de cálculo monetário;
6. mapear Venda e Item de Venda preservando a dependência com Produto Turístico;
7. separar comissão de fornecedor/reserva da comissão de colaborador/venda;
8. definir a rastreabilidade de Contrato com Venda e Reserva sem alterar a baseline retroativamente.

Operadora exige decisão explícita: especialização de fornecedor, papel comercial ou entidade autônoma. A etapa
2.4.5 deve resolver a autoridade antes de criar tabela ou API.

## 9. Critérios de conclusão da etapa 2.4.1

- [x] autoridades comerciais e projeções não autoritativas classificadas;
- [x] tabelas, identidades e foreign keys existentes inventariadas;
- [x] fronteiras com Core, Financeiro, Turismo, documentos e colaboradores registradas;
- [x] cobertura do roteiro funcional confrontada com a baseline;
- [x] ausências e inconsistências documentadas sem alteração estrutural;
- [x] fronteira física do módulo Comercial preservada;
- [x] gates automatizados adicionados contra o dump oficial;
- [x] validações locais consolidadas na certificação;
- [x] integrações validadas em PostgreSQL local descartável;
- [x] validação em CI Linux/PostgreSQL registrada;
- [ ] merge e validação pós-merge registrados.
