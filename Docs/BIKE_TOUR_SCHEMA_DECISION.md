# Decisão de Schema de Bike Tour

<!-- cspell:words alocacao correlacao ciclista pedalista -->

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.8 — Decisão de Schema (`BT-DOC-08`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Decisão de Arquitetura de Dados
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Decisão

A etapa 2.7 deve seguir a regra de **adoção incremental e sem reescrita**. O módulo Bike Tour será modelado como
extensão aditiva e conservadora da estrutura existente, sem alterar pacotes, reservas, contratos, títulos ou objetos
certificados de Turismo, Comercial, Financeiro ou Core.

A proposta em elaboração é manter a nova modelagem no mesmo nível de autoridade do domínio: os objetos próprios do módulo
serão criados de forma aditiva, com chaves explícitas, status, comentários e relacionamento mínimo com entidades
existentes. Nenhuma tabela legada ou migration histórica será modificada para inserir a funcionalidade de Bike Tour.

## 2. Objetivo da modelagem

- preservar a estrutura oficial, sem reescrever ou renomear objetos de baseline;
- manter a identidade da operação de Bike Tour separada da identidade da reserva e do contrato;
- representar capacidades, recursos e blocos temporais de forma explícita;
- preservar integridade de evento, participante, ponto de controle e ocorrência;
- manter correlacao com Comercial e Financeiro apenas por identificadores e evidências de origem.

## 3. Diretrizes de esquema

| Diretriz | Decisão |
| --- | --- |
| schema de execução | manter em `public` ou no schema oficial do módulo, se houver decisão explícita posterior |
| tabela de domínio | nomes em português, minúsculas e `snake_case` |
| chave primária | explicitamente declarada e rastreável |
| chave estrangeira | sempre vinculando ao identificador do domínio pai ou ao objeto de referencia |
| status | enum ou check explícito por domínio |
| capacidade | protegida por validacao de intervalo e recurso |
| histórico | preservar mudanças relevantes com auditoria e correlacao |
| registros legados | opcionais e compatíveis com a baseline existente |
| séries de eventos | sem sobregravar estado anterior |

## 4. Estruturas lógicas previstas

As entidades principais devem seguir a lógica de especialização e não de duplicação:

- `evento_bike_tour`: materializa a operação do evento, a data e a capacidade da rota;
- `recurso_bike_tour`: representa bicicletas, acessórios, veículos e suporte do modelo;
- `alocacao_recurso_bike_tour`: guarda a alocação, o bloqueio e a vigência do recurso;
- `inscricao_bike_tour`: conserva a pessoa, o evento e a sua vinculação operacional;
- `ponto_controle_bike_tour`: materializa a ordem, a data e o status da rota;
- `ocorrencia_bike_tour`: grava falhas, atrasos, incidentes e eventos críticos;
- `equipe_bike_tour`: descreve o papel da tripulação e a atribuição operacional;
- `logistica_bike_tour`: concentra apoio, material e operação de suporte da rota.

Essas estruturas são a base arquitetural para a `migration` aditiva posterior, sem qualquer alteração retroativa na
baseline histórica.

## 5. Compatibilidade e integração

- objetos existentes de Turismo, Comercial, Financeiro e Core não serão reescritos;
- a correlação com `reserva`, `venda` e `titulo` será por identificador externo e evento de origem;
- não haverá duplicação de pessoa, contrato ou título como fato de negócio;
- downgrade e upgrade devem manter a linearidade de head e eliminar somente objetos aditivos da etapa 2.7;
- a proposta depende da aprovação formal do gate documental antes de orientar a implementação.

## 6. Critérios de aceite da decisão

A decisão de schema só será final quando:

1. a arquitetura de domínio for validada pelo gate de `BT-DOC-04`;
2. a política de concorrência e expiração do módulo estiver aprovada em `BT-DOC-05`;
3. a segurança e privacidade de participante estiver aprovada em `BT-DOC-06`;
4. o teste de capacidade, concorrência e idempotência estiver definido em `BT-DOC-07`;
5. o plano da migration aditiva demonstrar linearidade e compatibilidade com a baseline.

A execução de upgrade e downgrade comprovará esse plano na entrega funcional, após implementação autorizada.

## 7. Conclusão

A decisão de schema de Bike Tour define uma implementação aditiva, conservadora e separada da estrutura vigente.
Ela protege a baseline, preserva a autoridade dos outros módulos e prepara a migration sem extrapolar o escopo da
Fase 2.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.8 — Decisão de Schema de Bike Tour |
| Entregável | `BT-DOC-08` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

<!-- cspell:ignore ocorrencia logistica -->
