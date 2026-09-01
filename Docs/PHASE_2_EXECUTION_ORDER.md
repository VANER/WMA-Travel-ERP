# WMA Travel ERP — Ordem de Execução Oficial da Fase 2

> Backend, API, módulos operacionais, integrações e certificação.

**Documento:** Ordem de Execução da Fase 2

**Versão:** 1.0

**Data:** 18/08/2026

**Status:** Oficial para execução

**Fase anterior:** Fase 1 — Concluída e certificada

**Marco da Fase 1:** `phase-1-final-2026-08-18`

**Fase atual:** Fase 2 — Backend, API e Integrações

**Arquitetura:** Monólito Modular

**Banco:** PostgreSQL 18.x

---

## 1. Objetivo

Este documento estabelece a ordem oficial de execução da Fase 2 do
WMA Travel ERP.

A Fase 2 transforma a fundação de dados certificada na Fase 1 em uma
plataforma operacional composta por:

- backend;
- API REST;
- autenticação e autorização;
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
- certificação.

---

## 2. Regra Fundamental

A baseline certificada da Fase 1 é considerada imutável.

Nenhuma alteração estrutural futura deverá modificar retroativamente os
artefatos certificados da Fase 1.

O fluxo obrigatório para evolução do banco será:

```text
Requisito
    ↓
Análise da estrutura existente
    ↓
Alteração necessária?
    ↓
Migration versionada
    ↓
Validação
    ↓
Model
    ↓
Repository
    ↓
Service
    ↓
API
    ↓
Testes
    ↓
Documentação
    ↓
Commit
```

Não utilizar criação automática do schema como mecanismo de implantação.

Alterações estruturais deverão ser realizadas exclusivamente por migrations
controladas e versionadas.

---

## 3. Ordem Macro da Fase 2

```text
FASE 1 — CERTIFICADA
        │
        ▼
2.0 — FUNDAÇÃO BACKEND/API
        │
        ▼
2.1 — CORE CORPORATIVO
        │
        ▼
2.2 — SEGURANÇA E ACESSO
        │
        ▼
2.3 — COMERCIAL
        │
        ▼
2.5 — FINANCEIRO
        │
        ▼
2.6 — TURISMO
        │
        ▼
2.7 — BIKE TOUR
        │
        ▼
2.8 — WMA TRAVEL WEBSITE
        │
        ▼
2.9 — FISCAL
        │
        ▼
2.10 — INTEGRAÇÕES EXTERNAS
        │
        ▼
2.11 — BI / DW
        │
        ▼
2.12 — AUDITORIA E OBSERVABILIDADE
        │
        ▼
2.13 — QUALIDADE E HARDENING
        │
        ▼
2.14 — CERTIFICAÇÃO FINAL
        │
        ▼
FASE 2 — CERTIFICADA
```

---

## 4. ETAPA 2.0 — Fundação Backend/API

**Prioridade:** Crítica

**Dependência:** Fase 1 certificada

A Etapa 2.0 deve ser concluída antes do desenvolvimento funcional dos
módulos.

---

### 2.0.1 — Arquitetura Tecnológica

#### 2.0.1.1 — ADR-001 — Monólito Modular

Formalizar:

- arquitetura Monólito Modular;
- separação por domínio;
- regras de dependência;
- comunicação entre módulos;
- política de componentes compartilhados;
- critérios futuros para microserviços.

**Status inicial:** Decisão aprovada.

#### 2.0.1.2 — ADR-002 — Stack Tecnológica

Definir e certificar:

- Python;
- FastAPI;
- SQLAlchemy;
- Pydantic;
- Alembic;
- psycopg;
- PostgreSQL;
- pytest;
- HTTPX;
- Uvicorn;
- OpenAPI;
- GitHub Actions.

#### 2.0.1.3 — ADR-003 — Persistência

Definir:

- sessões;
- transações;
- repositories;
- ORM;
- SQL explícito quando necessário;
- connection pooling;
- tratamento de falhas;
- política de acesso aos schemas.

#### 2.0.1.4 — ADR-004 — Migrations

Definir:

- Alembic;
- nomenclatura;
- versionamento;
- `upgrade`;
- `downgrade`;
- revisão;
- testes;
- evidências;
- política de produção.

#### 2.0.1.5 — ADR-005 — API

Definir:

- REST;
- JSON;
- `/api/v1`;
- recursos;
- verbos HTTP;
- status HTTP;
- paginação;
- filtros;
- ordenação;
- erros;
- OpenAPI.

#### 2.0.1.6 — ADR-006 — Configuração e Secrets

Definir:

- `.env`;
- `.env.example`;
- variáveis de ambiente;
- secrets;
- ambientes;
- desenvolvimento;
- testes;
- produção.

O arquivo `.env` real nunca deverá ser versionado.

#### 2.0.1.7 — ADR-007 — Testes

Definir:

- testes unitários;
- integração;
- API;
- banco;
- migrations;
- segurança;
- regressão.

#### 2.0.1.8 — ADR-008 — Integrações

Definir arquitetura para:

- `wmatravel.com.br`;
- pagamentos;
- operadoras;
- fiscal;
- serviços externos;
- webhooks.

#### Gate 2.0.1

**ARQUITETURA TECNOLÓGICA: APROVADA**

---

### 2.0.2 — Bootstrap do Backend

Criar:

```text
Backend/
├── app/
├── migrations/
├── tests/
├── scripts/
├── .env.example
├── alembic.ini
├── pyproject.toml
└── README.md
```

Preparar ambiente Python e gerenciamento de dependências.

#### Gate 2.0.2

- ambiente executável;
- dependências controladas;
- aplicação inicia sem erro.

---

### 2.0.3 — Estrutura Modular

Criar progressivamente:

```text
Backend/app/
├── main.py
├── api/
├── core/
├── modules/
├── integrations/
└── shared/
```

Estrutura funcional prevista:

```text
modules/
├── comercial/
├── financeiro/
├── turismo/
├── biketour/
└── fiscal/
```

Não criar implementações vazias desnecessárias.

#### Gate 2.0.3

**ESTRUTURA MODULAR: APROVADA**

---

### 2.0.4 — Configuração

Implementar:

- settings;
- ambientes;
- secrets;
- logging básico;
- configuração central;
- validação das variáveis obrigatórias.

#### Gate 2.0.4

**CONFIGURAÇÃO: APROVADA E CERTIFICADA**

Certificação: `Docs/certification/PHASE_2_0_4_CONFIGURATION_CERTIFICATION.md`.

---

### 2.0.5 — PostgreSQL e SQLAlchemy

Implementar:

- driver PostgreSQL;
- engine;
- session factory;
- transações;
- pool;
- health check do banco;
- tratamento de indisponibilidade.

Proibido usar `create_all()` como mecanismo de implantação da baseline.

#### Gate 2.0.5

**BACKEND ↔ POSTGRESQL: APROVADO E CERTIFICADO**

Certificação: `Docs/certification/PHASE_2_0_5_POSTGRESQL_SQLALCHEMY_CERTIFICATION.md`.

---

### 2.0.6 — Alembic e Migrations

Configurar:

- Alembic;
- diretório de migrations;
- nomenclatura;
- versionamento;
- upgrade;
- downgrade;
- validação da baseline;
- documentação.

#### Gate 2.0.6

**MIGRATIONS: APROVADAS E CERTIFICADAS**

Certificação: `Docs/certification/PHASE_2_0_6_ALEMBIC_MIGRATIONS_CERTIFICATION.md`.

---

### 2.0.7 — API Base

Criar:

```text
GET /health
GET /api/v1/health
```

Implementar:

- aplicação FastAPI;
- router principal;
- versionamento;
- respostas;
- tratamento básico de exceções.

#### Gate 2.0.7

**API BASE: OPERACIONAL E CERTIFICADA**

Certificação: `Docs/certification/PHASE_2_0_7_API_BASE_CERTIFICATION.md`.

---

### 2.0.8 — OpenAPI

Validar:

- `/docs`;
- `/redoc`;
- `/openapi.json`;
- metadata;
- versionamento;
- schemas.

#### Gate 2.0.8

**OPENAPI: APROVADA E CERTIFICADA**

Certificação: `Docs/certification/PHASE_2_0_8_OPENAPI_CERTIFICATION.md`.

---

### 2.0.9 — Testes Iniciais

**Status:** CONCLUÍDA E CERTIFICADA

Implementar testes para:

- aplicação;
- health;
- PostgreSQL;
- configuração;
- API;
- migrations.

#### Gate 2.0.9

**TESTES DA FUNDAÇÃO: APROVADOS E CERTIFICADOS**

Certificação: `Docs/certification/PHASE_2_0_9_INITIAL_TESTS_CERTIFICATION.md`.

---

### 2.0.10 — GitHub Actions

**Status:** CONCLUÍDA E CERTIFICADA

Automatizar:

- lint;
- testes;
- validações;
- migrations;
- qualidade básica.

#### Gate 2.0.10

**CI: OPERACIONAL E CERTIFICADA**

Certificação: `Docs/certification/PHASE_2_0_10_GITHUB_ACTIONS_CERTIFICATION.md`.

---

### 2.0.11 — Certificação da Fundação

**Status:** CONCLUÍDA E CERTIFICADA

Auditar:

```text
Arquitetura ............... OK
Python .................... OK
FastAPI ................... OK
SQLAlchemy ................ OK
PostgreSQL ................ OK
Alembic ................... OK
API v1 .................... OK
Health .................... OK
OpenAPI ................... OK
Testes .................... OK
CI ........................ OK
Documentação .............. OK
```

#### Gate 2.0

**FUNDAÇÃO BACKEND/API: CERTIFICADA**

Certificação: `Docs/certification/PHASE_2_0_11_FOUNDATION_CERTIFICATION.md`.

Reauditoria: `Docs/certification/PHASE_2_0_FOUNDATION_REAUDIT_2026_08_25.md`.

---

## 5. ETAPA 2.1 — Core Corporativo

**Dependência:** 2.0

### 2.1.1 — Inventário

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Mapear estruturas existentes relacionadas a:

- empresa;
- usuários;
- clientes;
- fornecedores;
- documentos;
- configurações;
- entidades transversais.

Inventário: `Docs/CORE_CORPORATE_INVENTORY.md`.

Certificação: `Docs/certification/PHASE_2_1_1_CORE_INVENTORY_CERTIFICATION.md`.

### 2.1.2 — Models

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Mapear modelos existentes sem recriar a baseline.

Mapeamento: `Docs/CORE_MODELS.md`.

Certificação: `Docs/certification/PHASE_2_1_2_CORE_MODELS_CERTIFICATION.md`.

### 2.1.3 — Repositories

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Implementar persistência do Core.

Contrato: `Docs/CORE_REPOSITORIES.md`.

Certificação: `Docs/certification/PHASE_2_1_3_CORE_REPOSITORIES_CERTIFICATION.md`.

### 2.1.4 — Services

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Implementar regras corporativas.

Contrato: `Docs/CORE_SERVICES.md`.

Certificação: `Docs/certification/PHASE_2_1_4_CORE_SERVICES_CERTIFICATION.md`.

### 2.1.5 — Schemas

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Implementar contratos de entrada e saída.

Contrato: `Docs/CORE_SCHEMAS.md`.

Certificação: `Docs/certification/PHASE_2_1_5_CORE_SCHEMAS_CERTIFICATION.md`.

### 2.1.6 — API

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Criar endpoints necessários.

Contrato: `Docs/CORE_API.md`.

Certificação: `Docs/certification/PHASE_2_1_6_CORE_API_CERTIFICATION.md`.

### 2.1.7 — Testes

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Cobrir regras, banco e API.

Plano de testes: `Docs/CORE_TESTS.md`.

Certificação: `Docs/certification/PHASE_2_1_7_CORE_TESTS_CERTIFICATION.md`.

### 2.1.8 — Certificação

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Certificação consolidada: `Docs/certification/PHASE_2_1_CORE_CORPORATE_CERTIFICATION.md`.

#### Gate 2.1

**CORE CORPORATIVO: CERTIFICADO**

---

## 6. ETAPA 2.2 — Segurança e Controle de Acesso

**Dependência:** 2.0 e 2.1

**Status:** CONCLUÍDA E CERTIFICADA

### 2.2.1 — Inventário e Modelo de Identidade

**Status:** CONCLUÍDA E CERTIFICADA

Identificar autoridades humanas e técnicas, relações certificadas, duplicidades e lacunas antes da autenticação.

Inventário: `Docs/SECURITY_IDENTITY_INVENTORY.md`.

Certificação: `Docs/certification/PHASE_2_2_1_IDENTITY_INVENTORY_CERTIFICATION.md`.

### 2.2.2 — Autenticação

**Status:** CONCLUÍDA E CERTIFICADA

Implementar autenticação sem antecipar tokens, sessões ou autorização.

Contrato: `Docs/AUTHENTICATION.md`.

Certificação: `Docs/certification/PHASE_2_2_2_AUTHENTICATION_CERTIFICATION.md`.

Hash de credenciais, adaptador concreto, tokens, sessões e migrations permanecem reservados às decisões explícitas
das etapas seguintes.

### 2.2.3 — Hash de Credenciais

**Status:** CONCLUÍDA E CERTIFICADA

Política e limites: `Docs/CREDENTIAL_HASHING.md`.

Certificação: `Docs/certification/PHASE_2_2_3_CREDENTIAL_HASHING_CERTIFICATION.md`.

### 2.2.5 — Tokens e Sessões

**Status:** CONCLUÍDA E CERTIFICADA

Política e limites: `Docs/TOKENS_AND_SESSIONS.md`.

Certificação: `Docs/certification/PHASE_2_2_4_TOKENS_SESSIONS_CERTIFICATION.md`.

### 2.2.6 a 2.2.13 — Controle de Acesso

**Status:** CONCLUÍDAS E CERTIFICADAS

Perfis, roles, permissions, autorização, proteção de endpoints, recuperação, auditoria e testes foram integrados.

Contrato consolidado: `Docs/SECURITY_ACCESS_CONTROL.md`.

### 2.2.14 — Certificação

**Status:** CONCLUÍDA

Certificação: `Docs/certification/PHASE_2_2_SECURITY_ACCESS_CERTIFICATION.md`.

Recertificação de hardening: `Docs/certification/PHASE_2_2_SECURITY_HARDENING.md`.

Hardening transacional da recuperação:
`Docs/certification/PHASE_2_2_RECOVERY_TRANSACTION_HARDENING.md`.

Integração Titan Email: `Docs/certification/PHASE_2_2_TITAN_RECOVERY_CERTIFICATION.md`.

### Ordem

1. modelo de identidade;
2. autenticação;
3. hash de credenciais;
4. tokens/sessões;
5. perfis;
6. roles;
7. permissions;
8. autorização;
9. proteção de endpoints;
10. recuperação de acesso;
11. auditoria;
12. testes;
13. certificação.

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

**SEGURANÇA E ACESSO: CERTIFICADOS**

---

## 7. ETAPA 2.3 — Governança de API

**Dependência:** 2.0 a 2.2

**Duração estimada:** 5 a 7 dias úteis

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

### 2.3.1 — Inventário e Coerência Documental

**Status:** CONCLUÍDA

Inventariar o contrato publicado, reconciliar o planejamento e eliminar divergências entre documentação e
implementação. Evidência: `API_GOVERNANCE_INVENTORY.md`.

### 2.3.2 — Identificadores de Operação

**Status:** CONCLUÍDA

Definir convenção estável e declarar `operationId` explicitamente sem quebrar o snapshot vigente.

### 2.3.3 — Paginação, Filtros e Ordenação

**Status:** CONCLUÍDA

Formalizar o contrato atual `offset`/`limite` e decidir as extensões compatíveis de filtros e ordenação.

### 2.3.4 — Matriz de Respostas

**Status:** CONCLUÍDA

Definir respostas obrigatórias por classe de endpoint e controles executáveis correspondentes.

### 2.3.5 — Propriedade e Aprovação

**Status:** CONCLUÍDA

Definir responsáveis, aprovadores, evidências de mudança e exceções emergenciais.

### 2.3.6 — Auditoria Integral

**Status:** CONCLUÍDA

Executar lint, tipagem, testes, cobertura, PostgreSQL, migrations, snapshot e classificador de compatibilidade.

### 2.3.7 — Certificação

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Consolidar evidências locais e do CI, integrar por pull request e validar o workflow pós-merge.

Certificação: `certification/PHASE_2_3_API_GOVERNANCE_CERTIFICATION.md`.

#### Gate 2.3 --- Critério de Saída

**GOVERNANÇA DE API: CERTIFICADA**

---

## 8. ETAPA 2.4 — Comercial

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

**Dependência:** 2.1 a 2.3

**Duração planejada:** 5 semanas

**Cronograma oficial:** `Docs/COMMERCIAL_EXECUTION_SCHEDULE.md`.

### 2.4.1 — Inventário Comercial

Auditar banco existente antes de qualquer migration.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Inventário: `Docs/COMMERCIAL_INVENTORY.md`.

Certificação: `Docs/certification/PHASE_2_4_1_COMMERCIAL_INVENTORY_CERTIFICATION.md`.

### 2.4.2 — Clientes

Implementar serviços comerciais sobre cadastro corporativo.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

Contrato: `Docs/COMMERCIAL_CLIENTS.md`.

Certificação: `Docs/certification/PHASE_2_4_2_COMMERCIAL_CLIENTS_CERTIFICATION.md`.

### 2.4.3 — Leads

Implementar captação e acompanhamento.

**Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

### 2.4.4 — CRM

Implementar relacionamento e histórico.

### 2.4.5 — Fornecedores e Operadoras

Implementar regras comerciais.

### 2.4.6 — Oportunidades

Implementar pipeline comercial.

### 2.4.7 — Propostas

Implementar proposta e itens.

### 2.4.8 — Condições Comerciais

Implementar:

- preços;
- descontos;
- condições;
- comissões.

### 2.4.9 — Vendas

Implementar venda e itens.

### 2.4.10 — Contratos

Integrar contratos quando aplicável.

### 2.4.11 — API Comercial

Disponibilizar endpoints versionados.

### 2.4.12 — Testes

Executar testes funcionais e de integração.

### 2.4.13 — Certificação

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

**MÓDULO COMERCIAL: CERTIFICADO**

---

## 9. ETAPA 2.5 — Financeiro

**Dependência:** 2.1 a 2.4

A estrutura F1-FIN certificada será preservada.

### Ordem

1. inventário ORM;
2. plano de contas;
3. classificações;
4. contas a pagar;
5. contas a receber;
6. parcelas;
7. pagamentos;
8. caixa;
9. bancos;
10. cartões;
11. transferências;
12. centros de custo;
13. rateios;
14. movimentações;
15. conciliação;
16. capital social;
17. AFAC;
18. pró-labore;
19. distribuição de lucros;
20. tributos;
21. empréstimos;
22. imobilizado;
23. integração Comercial → Financeiro;
24. API;
25. testes;
26. certificação.

Fluxo:

```text
Venda
  ↓
Lançamento
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

**MÓDULO FINANCEIRO: CERTIFICADO**

---

## 10. ETAPA 2.6 — Turismo

**Dependência:** Comercial e Financeiro

### Ordem

1. inventário;
2. destinos;
3. produtos turísticos;
4. pacotes;
5. roteiros;
6. serviços;
7. fornecedores turísticos;
8. saídas;
9. disponibilidade;
10. vagas;
11. reservas;
12. passageiros;
13. serviços da reserva;
14. operação;
15. integração Comercial;
16. integração Financeiro;
17. API;
18. testes;
19. certificação.

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

**MÓDULO TURISMO: CERTIFICADO**

---

## 11. ETAPA 2.7 — Bike Tour

**Dependência:** Turismo

### Ordem

1. inventário;
2. eventos;
3. roteiros;
4. inscrições;
5. participantes;
6. bicicletas;
7. equipes;
8. apoio;
9. logística;
10. pontos de controle;
11. ocorrências;
12. integração Turismo;
13. integração Comercial;
14. integração Financeiro;
15. API;
16. testes;
17. certificação.

#### Gate 2.7

**MÓDULO BIKE TOUR: CERTIFICADO**

---

## 12. ETAPA 2.8 — Integração wmatravel.com.br

**Dependência:** Comercial, Financeiro e Turismo

O ERP será o núcleo corporativo e o site será um canal digital.

### 2.8.1 — Inventário do Site

Mapear:

- WordPress;
- WooCommerce;
- plugins;
- produtos;
- categorias;
- pedidos;
- clientes;
- pagamentos;
- formulários;
- campos personalizados.

### 2.8.2 — Mapeamento Site ↔ ERP

Definir correspondência entre entidades.

### 2.8.3 — Segurança da Integração

Implementar:

- HTTPS;
- autenticação;
- tokens;
- rate limiting;
- idempotência;
- validação;
- auditoria.

### 2.8.4 — Catálogo

ERP → site:

- produtos;
- pacotes;
- preços;
- datas;
- disponibilidade;
- vagas.

### 2.8.5 — Comercial

Site → ERP:

- lead;
- cliente;
- pedido;
- reserva;
- passageiros.

### 2.8.6 — Financeiro

Integrar:

- cobrança;
- pagamento;
- confirmação;
- cancelamento;
- estorno.

### 2.8.7 — Webhooks

Implementar eventos necessários.

### 2.8.8 — Reconciliação

Garantir que site e ERP permaneçam consistentes.

### 2.8.9 — Testes

Testar fluxos ponta a ponta.

### 2.8.10 — Certificação

Arquitetura obrigatória:

```text
wmatravel.com.br
       ↓
      HTTPS
       ↓
   WMA ERP API
       ↓
    Services
       ↓
   PostgreSQL
```

É proibido acesso direto do WordPress ao PostgreSQL corporativo.

#### Gate 2.8

**WMATRAVEL.COM.BR ↔ ERP: CERTIFICADO**

---

## 13. ETAPA 2.9 — Fiscal

**Dependência:** Comercial e Financeiro

### Ordem

1. inventário fiscal;
2. serviços;
3. documentos fiscais;
4. regras tributárias;
5. impostos;
6. retenções;
7. NFS-e;
8. apuração;
9. integração Comercial;
10. integração Financeiro;
11. integração contábil;
12. API;
13. testes;
14. certificação.

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

**MÓDULO FISCAL: CERTIFICADO**

---

## 14. ETAPA 2.10 — Integrações Externas

**Dependência:** Fundação e módulos correspondentes

Estrutura prevista:

```text
integrations/
├── website/
├── payments/
├── operators/
├── fiscal/
├── email/
└── external/
```

### Ordem

1. framework de integrações;
2. contratos;
3. autenticação externa;
4. timeouts;
5. retries;
6. idempotência;
7. webhooks;
8. logs;
9. tratamento de falhas;
10. testes;
11. certificação.

#### Gate 2.10

**INTEGRAÇÕES EXTERNAS: CERTIFICADAS**

---

## 15. ETAPA 2.11 — BI/DW

**Dependência:** Dados operacionais dos módulos

### Ordem

1. revisar DW existente;
2. mapear fontes;
3. Comercial;
4. Financeiro;
5. Turismo;
6. Bike Tour;
7. Fiscal;
8. Website;
9. ETL/ELT;
10. dimensões;
11. fatos;
12. indicadores;
13. qualidade dos dados;
14. testes;
15. certificação.

Fluxo:

```text
Comercial ────┐
Financeiro ───┤
Turismo ──────┤
Bike Tour ────┼──> ETL/ELT ──> DW ──> BI
Fiscal ───────┤
Website ──────┘
```

#### Gate 2.11

**BI/DW: CERTIFICADO**

---

## 16. ETAPA 2.12 — Auditoria e Observabilidade

Esta etapa é transversal e deverá ser preparada desde a Fundação.

### Ordem

1. logs estruturados;
2. correlation ID;
3. auditoria de operações;
4. métricas;
5. health checks;
6. erros;
7. performance;
8. integrações;
9. alertas;
10. rastreabilidade;
11. testes;
12. certificação.

#### Gate 2.12

**AUDITORIA E OBSERVABILIDADE: CERTIFICADAS**

---

## 17. ETAPA 2.13 — Qualidade e Hardening

**Dependência:** Módulos concluídos

### 2.13.1 — Testes Unitários

Validar regras isoladas.

### 2.13.2 — Testes de Integração

Validar módulos e banco.

### 2.13.3 — Testes de API

Validar contratos REST.

### 2.13.4 — Testes de Banco

Validar integridade e transações.

### 2.13.5 — Testes de Migrations

Validar `upgrade` e `downgrade`.

### 2.13.6 — Testes de Segurança

Validar autenticação e autorização.

### 2.13.7 — Testes de Integrações

Validar sistemas externos.

### 2.13.8 — Testes Website ↔ ERP

Validar fluxos ponta a ponta.

### 2.13.9 — Performance

Avaliar endpoints críticos.

### 2.13.10 — Regressão

Garantir que funcionalidades existentes não foram quebradas.

### 2.13.11 — Documentação

Validar documentação técnica e operacional.

### 2.13.12 — Gate de Qualidade

Nenhuma falha crítica poderá permanecer aberta.

#### Gate 2.13

**QUALIDADE E HARDENING: APROVADOS**

---

## 18. ETAPA 2.14 — Certificação Final da Fase 2

Executar auditoria completa.

### 2.14.1 — Arquitetura

Confirmar aderência às ADRs.

### 2.14.2 — Backend

Validar aplicação e dependências.

### 2.14.3 — Banco

Validar migrations e integridade.

### 2.14.4 — Segurança

Validar autenticação e autorização.

### 2.14.5 — Módulos

Certificar:

- Core;
- Comercial;
- Financeiro;
- Turismo;
- Bike Tour;
- Fiscal.

### 2.14.6 — Website

Certificar integração com `wmatravel.com.br`.

### 2.14.7 — Integrações

Certificar serviços externos.

### 2.14.8 — BI/DW

Certificar camada analítica.

### 2.14.9 — Observabilidade

Certificar logs, métricas e auditoria.

### 2.14.10 — Qualidade

Confirmar testes e gates.

### 2.14.11 — Documentação

Confirmar documentação final.

### 2.14.12 — Git

Validar:

- working tree;
- branch;
- commits;
- push;
- tag;
- ausência de conflitos;
- ausência de arquivos temporários;
- ausência de secrets.

---

## 19. Gate Final

A Fase 2 somente poderá ser encerrada quando:

```text
Arquitetura ................. OK
Backend ..................... OK
API ......................... OK
PostgreSQL .................. OK
Migrations .................. OK
Core ........................ OK
Segurança ................... OK
Comercial ................... OK
Financeiro .................. OK
Turismo ..................... OK
Bike Tour ................... OK
wmatravel.com.br ............ OK
Fiscal ...................... OK
Integrações ................. OK
BI/DW ....................... OK
Auditoria ................... OK
Observabilidade ............. OK
Testes ...................... OK
Segurança final ............. OK
Documentação ................ OK
Git ......................... OK
```

Resultado esperado:

**FASE 2 — CONCLUÍDA, CERTIFICADA E AUTORIZADA PARA PRODUÇÃO**

---

## 20. Regra de Conclusão por Etapa

Nenhuma etapa será considerada concluída apenas porque o código foi escrito.

Cada etapa deverá possuir:

- requisito definido;
- implementação;
- migrations, quando necessárias;
- testes;
- evidências;
- documentação;
- revisão;
- commit;
- gate de certificação.

---

## 21. Política de Commits

Utilizar commits pequenos e rastreáveis.

Exemplos:

```text
docs(phase2): define backend architecture
chore(backend): bootstrap FastAPI project
feat(core): implement company service
feat(auth): implement authentication
feat(comercial): implement sales workflow
feat(financeiro): expose accounts receivable API
feat(turismo): implement reservations
feat(website): integrate booking API
feat(fiscal): implement fiscal document workflow
test(phase2): add integration certification suite
docs(phase2): certify phase 2
```

---

## 22. Marcos Oficiais

| Marco | Resultado |
| --- | --- |
| M2.0 | Fundação Backend/API certificada |
| M2.1 | Core certificado |
| M2.2 | Segurança certificada |
| M2.3 | Governança de API certificada |
| M2.4 | Comercial certificado |
| M2.5 | Financeiro certificado |
| M2.6 | Turismo certificado |
| M2.7 | Bike Tour certificado |
| M2.8 | Website integrado e certificado |
| M2.9 | Fiscal certificado |
| M2.10 | Integrações certificadas |
| M2.11 | BI/DW certificado |
| M2.12 | Observabilidade certificada |
| M2.13 | Qualidade aprovada |
| M2.14 | Fase 2 certificada |

---

## 23. Ordem Imediata de Trabalho

A execução corrente começa obrigatoriamente por:

```text
ADR-017 — Reprogramação Funcional da Fase 2
               ↓
2.4.1 — Inventário Comercial
               ↓
2.4.2 — Clientes
```

Não iniciar a 2.4.2 antes da auditoria, aprovação e certificação do inventário 2.4.1.

---

## 24. Status Atual

| Item | Status |
| --- | --- |
| Fase 1 | **CERTIFICADA** |
| Baseline Fase 1 | **CONGELADA** |
| Fase 2 | **INICIADA** |
| ADR-001 | **APROVADA** |
| ADR-017 | **APROVADA** |
| Etapa 2.0.1 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.2 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.3 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.4 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.5 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.6 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.7 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.8 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.9 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.10 | **CONCLUÍDA E CERTIFICADA** |
| Etapa 2.0.11 | **CONCLUÍDA E CERTIFICADA** |
| Fundação Backend/API | **CERTIFICADA** |
| Etapa 2.1.1 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.2 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.3 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.4 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.5 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.6 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.7 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.1.8 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Core Corporativo 2.1 | **CERTIFICADO** |
| Etapa 2.2 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.3 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Reprogramação funcional | **CONCLUÍDA PELA ADR-017** |
| Etapa 2.4.1 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.4.2 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Etapa 2.4 | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| Próxima execução | **2.5 — FINANCEIRO** |

---

### Declaração de Continuidade

A Fase 2 do WMA Travel ERP está formalmente em execução. As etapas 2.0 a 2.3 foram concluídas, certificadas e
integradas à `main`. A Governança de API 2.3 foi integrada pelo PR #43 no commit `0153b99`.

O desenvolvimento deverá seguir a sequência, dependências, gates e regras
estabelecidos neste documento.

**Próxima ação oficial:**

**ETAPA 2.5 — FINANCEIRO.**
