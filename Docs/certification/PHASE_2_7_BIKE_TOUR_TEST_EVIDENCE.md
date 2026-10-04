# Fase 2.7 Bike Tour — Evidências dos Critérios de Teste

**Projeto:** WMA Travel ERP
**Fase:** 2.7 — Bike Tour
**Gate:** B05 — Test Criteria Evidence
**Status:** READY TO CLOSE — T23 CONTROLADO PELO B06
**Branch:** `feature/2.7-bike-tour`
**Baseline HEAD:** `ba45b3c1c544a05a6ed317445f31ba737c497919`

---

## 1. Objetivo

Este documento consolida as evidências atuais dos critérios T01–T25
definidos em `BIKE_TOUR_TEST_PLAN.md`.

A consolidação não reescreve a evidência histórica registrada em
`BIKE_TOUR_IMPLEMENTATION_REVIEW.md`. Os estados históricos daquele
documento permanecem preservados e são reconciliados aqui com testes,
correções e certificações posteriores.

---

## 2. Resultado do gate B05

- Critérios canônicos identificados: **25/25**.
- Gaps funcionais de teste identificados: **0**.
- Novos testes funcionais necessários: **não**.
- Evidências físicas PostgreSQL posteriores reconciliadas: **sim**.
- Contratos corrigidos posteriormente reconciliados: **sim**.
- T23: política definida, execução administrativa ainda não certificada.
- Responsável pelo fechamento de T23: **B06 — Retention Control**.
- T24: evidência física de reconstrução e migration já certificada.

O B05 não considera a pendência administrativa de T23 como ausência de
teste funcional. O controle permanece explicitamente aberto até o B06.

---

## 3. Matriz consolidada T01–T25

| Critério | Evidência consolidada | Situação B05 |
| --- | --- | --- |
| T01 | Vocabulário canônico `INICIANTE`, `INTERMEDIARIO`, `AVANCADO` validado após correções | EVIDÊNCIA ATUAL |
| T02 | Testes de produto/evento, saída, período, capacidade e transições | EVIDÊNCIA PRESENTE |
| T03 | PostgreSQL: intervalos consecutivos permitidos e sobreposição real rejeitada | EVIDÊNCIA FÍSICA |
| T04 | Bloqueio, expiração, cancelamento e reutilização de recurso | EVIDÊNCIA PRESENTE |
| T05 | Confirmação, reserva, origem e alocação | EVIDÊNCIA PRESENTE |
| T06 | Correlação e origem Turismo/Comercial sem criação indevida | EVIDÊNCIA PRESENTE |
| T07 | Pontos, passagens, ordem e replay | EVIDÊNCIA PRESENTE |
| T08 | Ocorrências, estados e resolução | EVIDÊNCIA PRESENTE |
| T09 | PostgreSQL: falha na substituição do apoio restaura plano anterior | EVIDÊNCIA FÍSICA |
| T10 | PostgreSQL: mesmo guia não ocupa eventos sobrepostos | EVIDÊNCIA FÍSICA |
| T11 | Passageiro, reserva, saída e elegibilidade | EVIDÊNCIA PRESENTE |
| T12 | Presença, no-show, conclusão e avaliação | EVIDÊNCIA PRESENTE |
| T13 | RBAC canônico e respostas 401/403 reconciliados após correções | EVIDÊNCIA ATUAL |
| T14 | Auditoria, ator, operação, `correlation_id`, versão e rollback | EVIDÊNCIA ATUAL |
| T15 | PostgreSQL: duas conexões disputam a última bicicleta | EVIDÊNCIA FÍSICA |
| T16 | PostgreSQL: expiração concorrente com confirmação mantém consistência | EVIDÊNCIA FÍSICA |
| T17 | Idempotência, replay, payload divergente e revogação | EVIDÊNCIA PRESENTE |
| T18 | PostgreSQL: falha na reacomodação restaura alocação de origem | EVIDÊNCIA FÍSICA |
| T19 | Reconciliação e tratamento de origem indisponível/inválida | EVIDÊNCIA PRESENTE |
| T20 | UoW, rollback, falha após flush e ausência de estado parcial | EVIDÊNCIA PRESENTE |
| T21 | Constraints e integridade PostgreSQL | EVIDÊNCIA PRESENTE |
| T22 | Revogação, replay, validação e rejeição 422 | EVIDÊNCIA PRESENTE |
| T23 | Política de retenção definida; execução administrativa ainda não certificada | CONTROLADO ABERTO — B06 |
| T24 | Rebuild descartável, paridade física e downgrade/reupgrade Alembic | EVIDÊNCIA FÍSICA |
| T25 | OpenAPI, IDs únicos, erros HTTP e contratos tipados | EVIDÊNCIA ATUAL |

---

## 4. Pendências históricas superadas

Os seguintes critérios apareciam como pendentes em evidência histórica,
mas possuem testes físicos posteriores:

- **T03** — intervalos consecutivos e sobreposição real;
- **T09** — rollback de substituição de apoio;
- **T10** — conflito temporal de guia;
- **T15** — concorrência pela última bicicleta;
- **T16** — expiração concorrente com confirmação;
- **T18** — rollback da reacomodação.

Esses estados históricos são considerados superados pela evidência atual,
sem alteração retroativa do documento histórico.

---

## 5. Falhas históricas reconciliadas

### T01

O vocabulário atual utiliza os níveis canônicos:

- `INICIANTE`;
- `INTERMEDIARIO`;
- `AVANCADO`.

### T13

O contrato RBAC atual utiliza:

- `BIKE_TOUR_VISUALIZAR`;
- `BIKE_TOUR_OPERAR`;
- `BIKE_TOUR_GERENCIAR`.

Aliases históricos `BIKETOUR_*` permanecem apenas como compatibilidade
interna controlada.

### T14

A projeção de auditoria atual contém evidência de ator, operação e
`correlation_id`, além dos controles transacionais/versionados do módulo.

### T25

Os contratos HTTP Bike Tour possuem respostas tipadas. A certificação B03
eliminou o uso de `ResultadoJSON` nos contratos Bike Tour e preservou a
compatibilidade semântica externa.

---

## 6. T23 — retenção administrativa

A política Bike Tour define retenção operacional, incluindo prazo de
**365 dias** para categorias documentadas em
`BIKE_TOUR_SECURITY_PRIVACY.md`.

O B05 confirma a existência da política, mas não declara execução
administrativa certificada.

Portanto:

- política definida: **PASS**;
- gap funcional de teste: **não**;
- evidência administrativa de execução: **aberta**;
- owner do fechamento: **B06 — Retention Control**.

T23 somente poderá ser fechado quando B06 demonstrar o mecanismo
administrativo correspondente sem apagar auditoria compartilhada nem
alterar retenção pertencente a Turismo, Comercial ou Financeiro.

---

## 7. T24 — certificação física

A evidência física já executada utilizou banco descartável:

`wma_phase2_t24_20260926_184756_test`

Resultados certificados:

- rebuild limpo: **PASS**;
- objetos comparados: **1016**;
- somente no target: **0**;
- somente na referência: **0**;
- Alembic head: `202609170300`;
- downgrade: `202609170300 -> 202609170200`;
- reupgrade: `202609170200 -> 202609170300`;
- inventário preservado: **sim**;
- bancos protegidos preservados: **sim**.

Hash certificado de `Database/install.sh`:

`40D7AA9E6C102A93082750B6CB807FC9904301BAA6DDA033BC401C7CB4D73055`

Nova execução física não é necessária enquanto migration ou mecanismo de
instalação relevante não for alterado.

---

## 8. Artefatos preservados

Artefatos certificados mantidos durante B05:

- `Backend/openapi.json`
  - SHA-256:
    `5154DDD7D5C717A49D7756D7F31127344D26A02A9FEE93A9A89063667BBB00AE`
- `Backend/tests/test_biketour_operational_api.py`
  - SHA-256:
    `6525D9359272AD5038B0D4C7CB97C5F58FE64AA5B3ABED9BF6ADC4BB4622F1FF`
- `Backend/tests/integration/test_biketour_uow_postgresql.py`
  - SHA-256:
    `B07914C69F5CFFC372F2BFF6BB57B5582A444B48142F7E4450E5D591BB2D5DA7`
- `Database/install.sh`
  - SHA-256:
    `40D7AA9E6C102A93082750B6CB807FC9904301BAA6DDA033BC401C7CB4D73055`

---

## 9. Decisão

O B05 conclui que não existe gap funcional de teste que exija criação de
novo teste para fechamento desta etapa.

A única evidência ainda controlada aberta é T23, de natureza
administrativa e de retenção, explicitamente transferida para B06.

**B05_TEST_CRITERIA_EVIDENCE = READY_TO_CLOSE**

Próximo controle:

**B06_RETENTION_CONTROL**

---

WMA Travel ERP — Fase 2.7 Bike Tour
Certificação de evidências de teste — B05

<!-- cspell:ignore AVANCADO -->
