# WMA Travel ERP — Cronograma Oficial da Fase 2

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Planejamento
> **Versão:** 1.1
> **Data:** 04/09/2026
> **Status:** EM EXECUÇÃO

**Fase anterior:** Fase 1 — Fundação e Banco de Dados
**Status da Fase 1:** CONCLUÍDA E CERTIFICADA
**Status atual:** etapas 2.0 a 2.5 concluídas, certificadas e integradas
**Marco inicial:** `phase-1-final-2026-08-18`

**Branch inicial:** `feature/fase-2-backend-api`

---

## 1. Objetivo

A Fase 2 tem como objetivo transformar a fundação de dados certificada na
Fase 1 em uma plataforma operacional completa.

O desenvolvimento compreenderá:

- backend;
- API;
- autenticação;
- autorização;
- regras de negócio;
- módulo Comercial;
- módulo Financeiro;
- módulo Turismo;
- módulo Bike Tour;
- integração com `wmatravel.com.br`;
- módulo Fiscal;
- integrações externas;
- BI/DW;
- auditoria;
- observabilidade;
- testes;
- segurança;
- documentação;
- certificação final.

---

## 2. Princípios da Fase 2

A Fase 2 seguirá os seguintes princípios:

1. preservar a baseline certificada da Fase 1;
2. utilizar migrations versionadas para alterações estruturais;
3. desenvolver por domínio funcional;
4. separar API, regras de negócio e persistência;
5. utilizar PostgreSQL como fonte corporativa de dados;
6. tratar o ERP como sistema central da operação;
7. tratar `wmatravel.com.br` como canal digital integrado;
8. evitar acesso direto de sistemas externos ao banco;
9. implementar segurança desde a fundação;
10. automatizar testes e gates de qualidade;
11. documentar decisões arquiteturais;
12. manter rastreabilidade entre requisito, código, banco e commit.

---

## 3. Cronograma Macro

| Etapa | Módulo | Duração estimada | Dependência |
| --- | --- | ---: | --- |
| 2.0 | Arquitetura e Fundação Backend | 3 semanas | Fase 1 |
| 2.1 | Core Corporativo | 3 semanas | 2.0 |
| 2.2 | Segurança e Controle de Acesso | 3 semanas | 2.0–2.1 |
| 2.3 | Governança de API | 5 a 7 dias úteis | 2.0–2.2 |
| 2.4 | Comercial | 5 semanas | 2.1–2.3 |
| 2.5 | Financeiro | 5 semanas | 2.1–2.4 |
| 2.6 | Turismo | 6 semanas | 2.4–2.5 |
| 2.7 | Bike Tour | 4 semanas | 2.6 |
| 2.8 | Integração wmatravel.com.br | 5 semanas | 2.3–2.6 |
| 2.9 | Fiscal | 5 semanas | 2.3–2.5 |
| 2.10 | Integrações Externas | 4 semanas | módulos operacionais |
| 2.11 | BI/DW | 4 semanas | módulos operacionais |
| 2.12 | Auditoria e Observabilidade | 3 semanas | transversal |
| 2.13 | Qualidade e Hardening | 4 semanas | todas |
| 2.14 | Certificação da Fase 2 | 2 semanas | 2.13 |

A sequência 2.4 a 2.14 foi reprogramada pela ADR-017 para reinserir o módulo Comercial sem sobrepor a etapa 2.3.

**Estimativa sequencial total:** aproximadamente 61 semanas.

A duração poderá ser reduzida com execução paralela de atividades que não
possuam dependência técnica direta.

---

## 4. ETAPA 2.0 — Arquitetura e Fundação Backend

**Duração estimada:** 3 semanas
**Prioridade:** Crítica

### 2.0.1 — Arquitetura tecnológica

Definir:

- linguagem;
- framework;
- ORM;
- migrations;
- padrão arquitetural;
- API REST;
- OpenAPI;
- testes;
- configuração;
- logging;
- tratamento de erros.

Stack inicialmente recomendada:

- Python 3.13+;
- FastAPI;
- SQLAlchemy 2;
- Alembic;
- Pydantic;
- PostgreSQL 18.x;
- pytest;
- HTTPX;
- Uvicorn.

### 2.0.2 — Estrutura do backend

Criar a estrutura oficial:

```text
Backend/
├── app/
├── migrations/
├── tests/
├── scripts/
└── pyproject.toml
```

### 2.0.3 — Estrutura modular

Criar progressivamente:

- módulos Comercial, Financeiro, Turismo, Bike Tour e Fiscal;
- área de integrações externas;
- área de recursos genuinamente compartilhados;
- gate automatizado para proteger as fronteiras entre domínios.

### 2.0.4 — Configuração

Implementar:

- ambientes;
- variáveis de ambiente;
- configuração do PostgreSQL;
- secrets;
- connection pooling;
- configuração de logging.

### 2.0.5 — PostgreSQL e SQLAlchemy

Implementar:

- SQLAlchemy;
- conexão com a baseline;
- session factory;
- transações e pool;
- health check do banco;
- tratamento de indisponibilidade.

### 2.0.6 — Alembic e migrations

Configurar:

- diretório e nomenclatura de migrations;
- upgrade e downgrade;
- validação da baseline;
- documentação da política de migrations.

### 2.0.7 — API inicial

Criar:

```text
GET /health
GET /api/v1/health
```

### 2.0.8 — OpenAPI

Validar:

- `/docs`;
- `/redoc`;
- `/openapi.json`;
- metadata, versionamento e schemas.

### 2.0.9 — Testes iniciais

**Status:** CONCLUÍDA E CERTIFICADA

Implementar testes para aplicação, configuração, API, PostgreSQL e migrations.

### 2.0.10 — GitHub Actions

**Status:** CONCLUÍDA E CERTIFICADA

Configurar:

- lint;
- type checking;
- testes;
- validação de migrations.

Validação local e Linux aprovadas. Certificação:
`Docs/certification/PHASE_2_0_10_GITHUB_ACTIONS_CERTIFICATION.md`.

### 2.0.11 — Certificação da fundação

**Status:** CONCLUÍDA E CERTIFICADA

Auditar a arquitetura e todos os gates técnicos da etapa 2.0.

Certificação: `Docs/certification/PHASE_2_0_11_FOUNDATION_CERTIFICATION.md`.

#### Gate 2.0

- backend inicializa;
- PostgreSQL conecta;
- migrations funcionam;
- `/health` responde;
- testes passam;
- CI funciona;
- documentação arquitetural aprovada.

---

## 5. ETAPA 2.1 — Core Corporativo

**Duração:** 3 semanas.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Implementar serviços corporativos compartilhados.

Inventário aprovado: `Docs/CORE_CORPORATE_INVENTORY.md`.

Certificação: `Docs/certification/PHASE_2_1_1_CORE_INVENTORY_CERTIFICATION.md`.

Models certificados: `Docs/CORE_MODELS.md`.

Certificação: `Docs/certification/PHASE_2_1_2_CORE_MODELS_CERTIFICATION.md`.

Repositories certificados: `Docs/CORE_REPOSITORIES.md`.

Certificação: `Docs/certification/PHASE_2_1_3_CORE_REPOSITORIES_CERTIFICATION.md`.

Services certificados: `Docs/CORE_SERVICES.md`.

Certificação: `Docs/certification/PHASE_2_1_4_CORE_SERVICES_CERTIFICATION.md`.

Schemas certificados: `Docs/CORE_SCHEMAS.md`.

Certificação: `Docs/certification/PHASE_2_1_5_CORE_SCHEMAS_CERTIFICATION.md`.

### Escopo

- empresa;
- usuários;
- clientes;
- fornecedores;
- documentos;
- configurações;
- tipos corporativos;
- serviços compartilhados.

### Entregas

- models;
- repositories;
- services;
- schemas;
- endpoints;
- validações;
- testes.

#### Gate 2.1

**CORE CORPORATIVO: APROVADO**

---

## 6. ETAPA 2.2 — Segurança e Controle de Acesso

**Duração:** 3 semanas.

**Status:** CONCLUÍDA E CERTIFICADA

### 2.2.1 — Inventário e Modelo de Identidade

Identificar autoridades humanas, identidades técnicas, duplicidades e lacunas anteriores à autenticação.

Inventário: `Docs/SECURITY_IDENTITY_INVENTORY.md`.

Certificação: `Docs/certification/PHASE_2_2_1_IDENTITY_INVENTORY_CERTIFICATION.md`.

### 2.2.2 — Autenticação

Implementar autenticação sem antecipar tokens, sessões ou autorização.

Contrato: `Docs/AUTHENTICATION.md`.

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_2_2_AUTHENTICATION_CERTIFICATION.md`.

### 2.2.3 — Hash de Credenciais

Política e limites: `Docs/CREDENTIAL_HASHING.md`.

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_2_3_CREDENTIAL_HASHING_CERTIFICATION.md`.

### 2.2.4 — Tokens e Sessões

Política e limites: `Docs/TOKENS_AND_SESSIONS.md`.

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_2_4_TOKENS_SESSIONS_CERTIFICATION.md`.

### Escopo

- autenticação;
- autorização;
- usuários;
- perfis;
- roles;
- permissions;
- tokens;
- recuperação de acesso;
- auditoria de acesso;
- políticas de API.

Fluxo:

```text
Usuário
   ↓
Autenticação
   ↓
Identidade
   ↓
Perfil
   ↓
Permissão
   ↓
Endpoint
   ↓
Auditoria
```

#### Gate 2.2

- autenticação validada;
- autorização validada;
- endpoints protegidos;
- credenciais protegidas;
- auditoria ativa;
- testes de segurança aprovados.

---

## 7. ETAPA 2.3 — Governança de API

**Duração estimada:** 5 a 7 dias úteis.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA.

### Ordem

1. inventário e coerência documental;
2. identificadores de operação estáveis;
3. paginação, filtros e ordenação;
4. matriz de respostas;
5. propriedade e aprovação;
6. auditoria integral;
7. certificação.

#### Gate 2.3

- contrato OpenAPI versionado e compatível;
- documentação coerente com a implementação;
- mudanças incompatíveis bloqueadas no CI;
- processo de aprovação definido;
- testes e integrações aprovados;
- certificação publicada.

---

## 8. ETAPA 2.4 — Comercial

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA.

**Dependência:** 2.1 a 2.3.

**Duração:** 5 semanas.

**Cronograma oficial:** `Docs/COMMERCIAL_EXECUTION_SCHEDULE.md`.

O cronograma distribuiu as subetapas 2.4.1 a 2.4.13 em cinco ciclos semanais. Todas foram concluídas, certificadas
e integradas pelo PR #51 e pelo CI pós-merge da `main`.

### Escopo

- leads;
- CRM;
- clientes;
- fornecedores;
- operadoras;
- oportunidades;
- propostas;
- vendas;
- itens;
- contratos;
- descontos;
- condições comerciais;
- comissões.

Fluxo principal:

```text
Lead
 ↓
Oportunidade
 ↓
Cliente
 ↓
Proposta
 ↓
Venda
 ↓
Reserva/Contrato
```

#### Gate 2.4

**MÓDULO COMERCIAL: OPERACIONAL**

---

## 9. ETAPA 2.5 — Financeiro

**Duração:** 5 semanas.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA.

A estrutura F1-FIN certificada será utilizada como fundação.

### Escopo

- plano de contas;
- classificações;
- contas a pagar;
- contas a receber;
- parcelas;
- pagamentos;
- caixa;
- bancos;
- cartões;
- transferências;
- centros de custo;
- rateios;
- conciliação;
- capital social;
- AFAC;
- pró-labore;
- distribuição de lucros;
- tributos;
- empréstimos;
- imobilizado.

Integração principal:

```text
Venda
  ↓
Financeiro
  ↓
Parcelas
  ↓
Pagamento
  ↓
Movimentação
  ↓
Conciliação
```

#### Gate 2.5

**MÓDULO FINANCEIRO: CONCLUÍDO, CERTIFICADO E INTEGRADO**

---

## 10. ETAPA 2.6 — Turismo

**Duração:** 6 semanas.

**Status:** EM EXECUÇÃO — GATE DOCUMENTAL.

Branch sugerida após o merge do PR `#56`: `feature/2.6-turismo`.

Os entregáveis `TUR-DOC-01` a `TUR-DOC-08` foram aprovados. A implementação está certificada e aguarda integração;
a Etapa 2.7 permanece bloqueada até a integração da 2.6.

### Escopo

- produtos turísticos;
- destinos;
- pacotes;
- roteiros;
- serviços;
- saídas;
- disponibilidade;
- reservas;
- passageiros;
- fornecedores turísticos;
- operação;
- acompanhamento de viagem.

Fluxo:

```text
Produto
 ↓
Pacote
 ↓
Saída
 ↓
Reserva
 ↓
Passageiros
 ↓
Serviços
 ↓
Operação
```

#### Gate 2.6

**MÓDULO TURISMO: OPERACIONAL**

---

## 11. ETAPA 2.7 — Bike Tour

**Duração:** 4 semanas.

### Escopo

- eventos;
- roteiros;
- inscrições;
- participantes;
- bicicletas;
- equipes;
- veículos de apoio;
- pontos de controle;
- logística;
- ocorrências;
- acompanhamento operacional.

Fluxo:

```text
Evento
 ↓
Roteiro
 ↓
Inscrição
 ↓
Participante
 ↓
Operação
 ↓
Pontos de controle
```

#### Gate 2.7

**MÓDULO BIKE TOUR: OPERACIONAL**

---

## 12. ETAPA 2.8 — Integração wmatravel.com.br

**Duração:** 5 semanas.

O ERP será tratado como sistema corporativo central e o site como canal
digital integrado.

### 2.8.1 — Inventário

Mapear:

- WordPress;
- WooCommerce;
- produtos;
- categorias;
- clientes;
- pedidos;
- formulários;
- pagamentos;
- plugins;
- campos personalizados.

### 2.8.2 — Mapeamento

Definir:

```text
Site                  ERP
----------------------------------------
Cliente          <-> Cliente
Produto          <-> Produto turístico
Pedido           <-> Venda/Reserva
Pagamento        <-> Financeiro
Data de viagem   <-> Saída
Passageiro       <-> Passageiro
```

### 2.8.3 — API

Implementar endpoints específicos para o canal digital.

### 2.8.4 — Sincronização

ERP → site:

- produtos;
- pacotes;
- preços;
- datas;
- disponibilidade;
- vagas;
- regras comerciais.

Site → ERP:

- leads;
- clientes;
- reservas;
- pedidos;
- passageiros;
- pagamentos.

### 2.8.5 — Webhooks

Eventos previstos:

```text
pedido.criado
pedido.confirmado
pedido.pago
pedido.cancelado
reserva.criada
pagamento.aprovado
pagamento.estornado
```

### 2.8.6 — Segurança

Obrigatório:

- HTTPS;
- autenticação;
- tokens;
- rate limiting;
- idempotência;
- validação de payload;
- logs;
- auditoria;
- LGPD.

É proibido acesso direto do WordPress ao PostgreSQL do ERP.

#### Gate 2.8

**SITE ↔ ERP: INTEGRAÇÃO CERTIFICADA**

---

## 13. ETAPA 2.9 — Fiscal

**Duração:** 5 semanas.

### Escopo

- documentos fiscais;
- serviços;
- impostos;
- regras tributárias;
- NFS-e;
- retenções;
- apuração;
- integração financeira;
- integração contábil;
- histórico fiscal.

Fluxo:

```text
Venda/Serviço
     ↓
Financeiro
     ↓
Fiscal
     ↓
Documento fiscal
     ↓
Tributos
```

#### Gate 2.9

**MÓDULO FISCAL: OPERACIONAL**

---

## 14. ETAPA 2.10 — Integrações Externas

**Duração:** 4 semanas.

Preparar arquitetura:

```text
integrations/
├── website/
├── payments/
├── operators/
├── fiscal/
├── email/
└── future/
```

Possíveis integrações:

- gateways de pagamento;
- operadoras turísticas;
- APIs fiscais;
- e-mail;
- serviços de comunicação;
- serviços turísticos;
- sistemas futuros.

### Gate 2.10

**CAMADA DE INTEGRAÇÕES: APROVADA**

---

## 15. ETAPA 2.11 — BI/DW

**Duração:** 4 semanas.

### Escopo

- Comercial;
- Financeiro;
- Turismo;
- Bike Tour;
- Fiscal;
- Site;
- indicadores corporativos.

Fluxo:

```text
Comercial ────┐
Financeiro ───┤
Turismo ──────┤
Bike Tour ────┼──> ETL/ELT ──> DW ──> BI
Fiscal ───────┤
Site ─────────┘
```

#### Gate 2.11

**CAMADA ANALÍTICA: OPERACIONAL**

---

## 16. ETAPA 2.12 — Auditoria e Observabilidade

**Duração:** 3 semanas.

### Escopo

- logs estruturados;
- auditoria;
- métricas;
- rastreabilidade;
- erros;
- performance;
- health checks;
- alertas;
- histórico de integrações.

#### Gate 2.12

**OBSERVABILIDADE: APROVADA**

---

## 17. ETAPA 2.13 — Qualidade e Hardening

**Duração:** 4 semanas.

Executar:

- testes unitários;
- testes de integração;
- testes de API;
- testes PostgreSQL;
- testes de migrations;
- testes de autenticação;
- testes de autorização;
- testes do site;
- testes de integrações;
- segurança;
- performance;
- regressão;
- revisão de documentação.

Nenhuma falha crítica poderá permanecer aberta.

### Gate 2.13

**QUALIDADE: APROVADA**

---

## 18. ETAPA 2.14 — Certificação Final

**Duração:** 2 semanas.

Auditoria completa:

```text
Arquitetura .............. OK
Backend .................. OK
PostgreSQL ............... OK
Migrations ............... OK
Core ..................... OK
Segurança ................ OK
Comercial ................ OK
Financeiro ............... OK
Turismo .................. OK
Bike Tour ................ OK
wmatravel.com.br ......... OK
Fiscal ................... OK
Integrações .............. OK
BI/DW .................... OK
Auditoria ................ OK
Testes ................... OK
Documentação ............. OK
```

Resultado esperado:

**FASE 2: CONCLUÍDA E CERTIFICADA**

---

## 19. Marcos Oficiais

| Marco | Resultado esperado |
| --- | --- |
| M2.0 | Backend operacional |
| M2.1 | Core operacional |
| M2.2 | Segurança certificada |
| M2.3 | Governança de API certificada |
| M2.4 | Comercial operacional |
| M2.5 | Financeiro operacional |
| M2.6 | Turismo operacional |
| M2.7 | Bike Tour operacional |
| M2.8 | Site integrado |
| M2.9 | Fiscal operacional |
| M2.10 | Integrações operacionais |
| M2.11 | BI/DW operacional |
| M2.12 | Observabilidade ativa |
| M2.13 | Qualidade aprovada |
| M2.14 | Fase 2 certificada |

---

## 20. Estratégia de Execução

A execução deverá seguir ciclos pequenos:

```text
Requisito
   ↓
Análise
   ↓
Banco existente
   ↓
Migration, se necessária
   ↓
Model
   ↓
Repository
   ↓
Service
   ↓
API
   ↓
Teste
   ↓
Documentação
   ↓
Commit
```

Cada etapa deverá possuir seu próprio gate.

Uma etapa somente será considerada concluída quando código, banco, testes e
documentação estiverem consistentes.

---

## 21. Política para Alterações no Banco

A baseline da Fase 1 não deverá ser modificada retroativamente.

Toda nova alteração estrutural deverá ser realizada através de migration
versionada.

Cada migration deverá registrar, quando aplicável:

- identificação;
- requisito;
- justificativa;
- objetos afetados;
- SQL;
- dependências;
- rollback;
- testes;
- evidência;
- commit.

Toda alteração persistente posterior à Fase 1 deve:

1. ser criada como migration nova em `Database/migrations/` ou pelo Alembic;
2. possuir identificador e ordem inequívocos;
3. declarar objetivo, dependências e objetos afetados;
4. incluir validações pré e pós-aplicação;
5. incluir rollback ou justificar sua impossibilidade;
6. ser testada sobre uma reconstrução da Fase 1;
7. preservar a tag `phase-1-final-2026-08-18` e todos os seus artefatos.

É proibido editar retroativamente:

- `Database/scripts/WmaTravelERP.sql`;
- `Database/scripts/WMA_Travel_Schema.sql`;
- `Database/scripts/F1_FIN/`;
- `Database/baseline/`;
- documentos e evidências de certificação da Fase 1.

---

## 22. Prioridade de Execução

A sequência oficial será:

```text
FASE 1 CERTIFICADA
        ↓
2.0 Arquitetura/Fundação
        ↓
2.1 Core
        ↓
2.2 Segurança
        ↓
2.3 Governança de API
        ↓
2.4 Comercial
        ↓
2.5 Financeiro
        ↓
2.6 Turismo
        ↓
2.7 Bike Tour
        ↓
2.8 wmatravel.com.br
        ↓
2.9 Fiscal
        ↓
2.10 Integrações
        ↓
2.11 BI/DW
        ↓
2.12 Observabilidade
        ↓
2.13 Qualidade
        ↓
2.14 Certificação
        ↓
FASE 2 CERTIFICADA
```

---

## 23. Gate Inicial

- [x] Fase 1 certificada.
- [x] Tag final publicada e conferida.
- [x] Repositório sem arquivos temporários versionados conhecidos.
- [x] Diretório de migrations preparado.
- [x] Branch da Fase 2 criada a partir do marco final.
- [x] Backend inicial criado.
- [x] Pipeline de testes do backend configurado.
- [x] Migrations da Fase 2 validadas em árvore linear.

---

## 24. Próxima Ação Oficial

A próxima atividade do WMA Travel ERP será:

**ETAPA 2.6 — TURISMO**

As etapas 2.0 a 2.5 estão concluídas, certificadas e integradas à `main`. A ADR-017 reprogramou as etapas
funcionais, e a execução deve continuar pelo módulo Turismo na 2.6.

---

### Status

**FASE 1:** CONCLUÍDA E CERTIFICADA
**FASE 2:** EM EXECUÇÃO

**ETAPAS 2.0.1 E 2.0.2:** CONCLUÍDAS E CERTIFICADAS

**ETAPA 2.0.3:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.4:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.5:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.6:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.7:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.8:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.9:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.10:** CONCLUÍDA E CERTIFICADA

**ETAPA 2.0.11:** CONCLUÍDA E CERTIFICADA

**FUNDAÇÃO BACKEND/API:** CERTIFICADA

**ETAPA 2.1.1:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.2:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.3:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.4:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.5:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.6:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.7:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.1.8:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**CORE CORPORATIVO 2.1:** CERTIFICADO

**ETAPA 2.4.1:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.4.2:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.4:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA 2.5:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**ETAPA ATUAL:** 2.6 — Turismo, certificada e aguardando integração

**PRÓXIMA ENTREGA:** integração da Etapa 2.6 por pull request e CI

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.1 |
| Status | EM EXECUÇÃO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
