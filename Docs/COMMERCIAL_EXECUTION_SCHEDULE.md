# Cronograma Oficial de Execução da Etapa 2.4 — Comercial

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.4 — Comercial

**Duração planejada:** 5 semanas

**Dependências de entrada:** etapas 2.1, 2.2 e 2.3 concluídas, certificadas e integradas

**Estado:** EM EXECUÇÃO; 2.4.2 CERTIFICADA E AGUARDANDO INTEGRAÇÃO

## 2. Objetivo

Definir a sequência executiva, as entregas mínimas, as dependências e os gates da etapa 2.4. Este cronograma
detalha, sem renumerar ou ampliar, as subetapas aprovadas pela ADR-017 e por
`PHASE_2_EXECUTION_ORDER.md`.

As semanas representam janelas de planejamento, não autorização para trabalho paralelo. A passagem entre
subetapas depende da aprovação do incremento anterior. Datas civis serão registradas nas certificações e não são
fixadas antecipadamente, para que atrasos de auditoria ou CI não produzam um cronograma documental fictício.

## 3. Regras de execução

1. executar as subetapas na ordem 2.4.1 a 2.4.13;
2. não iniciar 2.4.2 antes da certificação e integração de 2.4.1;
3. iniciar cada subetapa seguinte somente após aprovação local da anterior;
4. não antecipar modelos, migrations, endpoints ou domínios pertencentes a uma subetapa futura;
5. usar migrations exclusivamente aditivas para evoluções estruturais da Fase 2;
6. preservar Cliente e Fornecedor como autoridades cadastrais do Core Corporativo;
7. atualizar documentação, testes e evidências no mesmo incremento que alterar comportamento observável;
8. concluir a etapa somente após certificação remota e validação pós-merge da 2.4.13.

## 4. Cronograma executivo

| Ciclo | Subetapas | Entrega principal | Gate acumulado |
| --- | --- | --- | --- |
| Semana 1 | 2.4.1 e 2.4.2 | Inventário certificado e serviços de Cliente | Autoridades preservadas e Clientes aprovados |
| Semana 2 | 2.4.3 a 2.4.5 | Leads, CRM, Fornecedores e Operadoras | Captação e relacionamento aprovados |
| Semana 3 | 2.4.6 e 2.4.7 | Oportunidades, Propostas e itens | Pipeline e proposta aprovados |
| Semana 4 | 2.4.8 a 2.4.10 | Condições, Vendas, itens e Contratos | Fluxo comercial transacional aprovado |
| Semana 5 | 2.4.11 a 2.4.13 | API, testes integrais e certificação | Módulo Comercial certificado e integrado |

O agrupamento semanal expressa capacidade planejada. Se um gate não for aprovado, as subetapas posteriores são
deslocadas; não são executadas em paralelo para compensar o atraso.

## 5. Plano por subetapa

### 2.4.1 — Inventário Comercial

**Estado:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**Entregas:**

- inventário das autoridades, relações, projeções e lacunas da baseline;
- fronteiras com Core, Financeiro, Turismo, documentos e colaboradores;
- testes de rastreabilidade contra o dump oficial;
- certificação local e evidências de validação.

**Gate:** inventário auditado em CI Linux/PostgreSQL, integrado e confirmado após o merge.

### 2.4.2 — Clientes

**Estado:** APROVADA E CERTIFICADA; INTEGRAÇÃO PENDENTE

**Entregas:**

- serviços comerciais sobre `Cliente`, sem duplicar a autoridade cadastral do Core;
- casos de uso, validações e erros do papel comercial;
- testes unitários e de integração;
- contrato interno entre Comercial e Core documentado.

**Gate:** operações comerciais de Cliente aprovadas, sem nova autoridade cadastral.

Contrato: `Docs/COMMERCIAL_CLIENTS.md`.

Certificação: `Docs/certification/PHASE_2_4_2_COMMERCIAL_CLIENTS_CERTIFICATION.md`.

### 2.4.3 — Leads

**Estado:** PLANEJADA

**Entregas:**

- models para Origem, Lead e Interação refletindo a baseline;
- repositories e services de captação e acompanhamento;
- transições de status explicitamente validadas;
- testes de persistência e regras de negócio.

**Gate:** ciclo de Lead aprovado e rastreável.

### 2.4.4 — CRM

**Estado:** PLANEJADA

**Entregas:**

- histórico de contatos e interações;
- visão de relacionamento sem duplicar dados pessoais;
- regras de autoria e ordenação cronológica;
- testes de isolamento e histórico.

**Gate:** relacionamento de Lead e Cliente aprovado.

### 2.4.5 — Fornecedores e Operadoras

**Estado:** PLANEJADA

**Entregas:**

- serviços comerciais sobre a autoridade `Fornecedor` do Core;
- decisão rastreável sobre Operadora como papel, especialização ou entidade;
- fronteira explícita com `FornecedorTuristico`;
- migration aditiva somente se a decisão exigir nova estrutura.

**Gate:** autoridades de Fornecedor e Operadora aprovadas sem colisão com Core ou Turismo.

### 2.4.6 — Oportunidades

**Estado:** PLANEJADA

**Entregas:**

- decisão sobre identidade própria de Oportunidade e relação com `funil_vendas`;
- pipeline, etapas, probabilidade, valor e responsáveis;
- conversão rastreável a partir de Lead;
- migration, persistência, serviços e testes quando necessários.

**Gate:** pipeline de Oportunidades aprovado e íntegro.

### 2.4.7 — Propostas

**Estado:** PLANEJADA

**Entregas:**

- proposta e itens vinculados à Oportunidade e ao Cliente aplicável;
- numeração, validade, versionamento e estados;
- cálculos monetários com `NUMERIC(15,2)`;
- migration, persistência, serviços e testes.

**Gate:** proposta versionada, calculada e rastreável até a Oportunidade.

### 2.4.8 — Condições Comerciais

**Estado:** PLANEJADA

**Entregas:**

- preços, descontos, condições, vigência e comissões;
- regras de precedência e arredondamento;
- separação entre comissão de fornecedor/reserva e colaborador/venda;
- testes de limites, conflitos e cálculos.

**Gate:** cálculos e condições comerciais determinísticos e aprovados.

### 2.4.9 — Vendas

**Estado:** PLANEJADA

**Entregas:**

- venda e itens, com conversão rastreável da proposta;
- numeração, totais, descontos e estados;
- integração transacional com Cliente e Produto Turístico;
- persistência, serviços e testes de concorrência e consistência.

**Gate:** Venda íntegra, transacional e rastreável até Cliente e Proposta.

### 2.4.10 — Contratos

**Estado:** PLANEJADA

**Entregas:**

- integração entre Contrato, Documento, Venda e Reserva quando aplicável;
- partes, vigência, valor e estados validados;
- preservação da autoridade documental do Core;
- migration aditiva, serviços e testes quando necessários.

**Gate:** vínculo contratual aprovado sem associação polimórfica implícita.

### 2.4.11 — API Comercial

**Estado:** PLANEJADA

**Entregas:**

- endpoints versionados sob `/api/v1`;
- autenticação, autorização, paginação, filtros e ordenação;
- respostas de erro e `operationId` conforme a governança 2.3;
- snapshot OpenAPI atualizado e classificado.

**Gate:** contrato da API compatível, documentado e aprovado.

### 2.4.12 — Testes

**Estado:** PLANEJADA

**Entregas:**

- testes unitários, de serviço, API e integração PostgreSQL;
- fluxos positivos, negativos, concorrência e transações;
- cobertura integral do código novo;
- validação de migrations e compatibilidade OpenAPI no CI.

**Gate:** suíte Comercial aprovada localmente e no CI Linux/PostgreSQL.

### 2.4.13 — Certificação

**Estado:** PLANEJADA

**Entregas:**

- auditoria integral das subetapas 2.4.1 a 2.4.12;
- consolidação das evidências locais e remotas;
- registro do PR, merge e CI pós-merge;
- atualização do estado oficial e liberação da etapa 2.5.

**Gate:** **MÓDULO COMERCIAL CERTIFICADO E INTEGRADO**.

## 6. Caminho crítico

```text
2.4.1 Inventário
  → 2.4.2 Clientes
  → 2.4.3 Leads
  → 2.4.4 CRM
  → 2.4.5 Fornecedores e Operadoras
  → 2.4.6 Oportunidades
  → 2.4.7 Propostas
  → 2.4.8 Condições Comerciais
  → 2.4.9 Vendas
  → 2.4.10 Contratos
  → 2.4.11 API Comercial
  → 2.4.12 Testes
  → 2.4.13 Certificação
```

## 7. Critério de encerramento

A etapa 2.4 somente poderá ser declarada concluída quando:

- todas as subetapas estiverem aprovadas e rastreáveis;
- migrations novas tiverem upgrade e downgrade validados quando aplicável;
- a suíte local e o CI Linux/PostgreSQL estiverem aprovados;
- o contrato OpenAPI estiver sincronizado e sem quebra incompatível não autorizada;
- a documentação e a certificação final estiverem publicadas;
- o merge e a execução pós-merge tiverem sido registrados.

Até esse gate, a etapa 2.5 — Financeiro permanece bloqueada.
