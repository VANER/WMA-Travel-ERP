# WMA Travel ERP — ETAPA 2.0.1 — Arquitetura Tecnológica

## Definição e Certificação da Arquitetura Tecnológica da Fase 2

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.1 — Arquitetura Tecnológica

**Status:** Em execução

**Data de início:** 18/08/2026

**Fase anterior:** Fase 1 — Concluída e certificada

**Marco anterior:** `phase-1-final-2026-08-18`

---

## 1. Objetivo

Definir, documentar e certificar a arquitetura tecnológica que será utilizada
durante toda a Fase 2 do WMA Travel ERP.

Esta etapa deve estabelecer decisões técnicas suficientemente claras para que
a implementação do backend seja iniciada sem decisões arquiteturais críticas
pendentes.

Nenhum módulo funcional deverá ser iniciado antes da aprovação desta etapa.

---

## 2. Princípios Arquiteturais

A Fase 2 seguirá os seguintes princípios:

- Monólito Modular;
- separação explícita entre domínios;
- baixo acoplamento;
- alta coesão;
- API versionada;
- contratos explícitos;
- segurança por padrão;
- migrations versionadas;
- baseline da Fase 1 imutável;
- testes automatizados;
- observabilidade;
- rastreabilidade;
- integração externa exclusivamente por API;
- documentação arquitetural através de ADRs.

---

## 3. Arquitetura Oficial

A arquitetura inicial será um **Monólito Modular**.

Estrutura conceitual:

```text
WMA Travel ERP Backend
│
├── Core
├── Auth
├── Comercial
├── Financeiro
├── Turismo
├── Bike Tour
├── Fiscal
│
├── Integrations
│   ├── Website
│   ├── Payments
│   ├── Operators
│   └── External Services
│
└── Shared Infrastructure
```

Os módulos deverão possuir fronteiras claras.

Um módulo não deverá implementar regras internas pertencentes a outro domínio.

---

## 4. ADR-001 — Monólito Modular

**Status:** Aprovada.

### Decisão

Adotar Monólito Modular como arquitetura inicial da Fase 2.

### Motivos

- menor complexidade operacional;
- transações simples entre domínios;
- deploy centralizado;
- menor custo;
- desenvolvimento incremental;
- boa aderência ao PostgreSQL existente;
- possibilidade de extração futura de serviços.

### Regra

Microserviços não serão adotados nesta fase.

A decisão poderá ser reavaliada futuramente mediante requisito técnico real.

---

## 5. ADR-002 — Stack Tecnológica

### Stack proposta

| Componente | Tecnologia |
| --- | --- |
| Linguagem | Python 3.13+ |
| Framework | FastAPI |
| Servidor ASGI | Uvicorn |
| ORM | SQLAlchemy 2.x |
| Validação | Pydantic v2 |
| Migrations | Alembic |
| Driver PostgreSQL | psycopg 3 |
| Banco | PostgreSQL 18.x |
| Testes | pytest |
| Testes HTTP | HTTPX |
| API | REST/JSON |
| Contrato | OpenAPI |
| CI | GitHub Actions |
| Versionamento | Git/GitHub |

### Critério de aprovação

A stack deverá possuir compatibilidade entre seus componentes e documentação
oficial suficiente para suporte do ciclo de desenvolvimento.

---

## 6. ADR-003 — Persistência

### Princípios

A aplicação deverá utilizar uma camada de persistência explícita.

Fluxo recomendado:

```text
Endpoint
   ↓
Service
   ↓
Repository
   ↓
SQLAlchemy
   ↓
PostgreSQL
```

### Regras

- regras de negócio não devem ficar no endpoint;
- repositories não devem concentrar regras funcionais;
- sessões devem possuir ciclo de vida controlado;
- transações devem ser explícitas;
- falhas devem realizar rollback;
- SQL direto poderá ser utilizado quando tecnicamente justificável;
- consultas complexas deverão ser documentadas.

---

## 7. ADR-004 — Banco e Migrations

A baseline certificada da Fase 1 deverá permanecer protegida.

Não utilizar:

```text
Base.metadata.create_all()
```

como processo oficial de implantação.

### Fluxo obrigatório

```text
Requisito
   ↓
Análise do banco
   ↓
Migration necessária?
   ↓
Alembic Revision
   ↓
Revisão
   ↓
Teste
   ↓
Upgrade
   ↓
Validação
```

### Toda migration deverá possuir

- identificação;
- descrição;
- justificativa;
- objetos afetados;
- `upgrade`;
- `downgrade`, quando aplicável;
- testes;
- evidência;
- commit.

---

## 8. ADR-005 — API

A API será REST e versionada.

Prefixo oficial:

```text
/api/v1
```

Endpoints técnicos:

```text
GET /health
GET /api/v1/health
```

### Padrões obrigatórios

- JSON;
- status HTTP adequados;
- schemas de entrada;
- schemas de saída;
- paginação;
- filtros;
- ordenação;
- tratamento padronizado de erros;
- OpenAPI.

---

## 9. ADR-006 — Configuração e Secrets

A aplicação utilizará configuração baseada em ambiente.

Arquivos previstos:

```text
.env
.env.example
```

### Regra crítica

`.env` não deverá ser versionado.

`.env.example` deverá conter apenas nomes e exemplos seguros.

### Ambientes mínimos

- development;
- test;
- production.

---

## 10. ADR-007 — Segurança

A segurança será transversal.

A arquitetura deverá prever:

- autenticação;
- autorização;
- hash de senha;
- tokens;
- permissões;
- proteção de endpoints;
- secrets;
- auditoria;
- validação de entrada;
- rate limiting para integrações;
- LGPD.

---

## 11. ADR-008 — Testes

A estratégia de testes deverá contemplar:

### Testes unitários

Validar regras isoladas.

### Testes de integração

Validar banco e services.

### Testes de API

Validar endpoints e contratos.

### Testes de migrations

Validar `upgrade` e `downgrade`.

### Testes de segurança

Validar autenticação e autorização.

### Testes de regressão

Impedir quebra de funcionalidades existentes.

---

## 12. ADR-009 — Integrações

Sistemas externos não poderão acessar diretamente o PostgreSQL.

Fluxo obrigatório:

```text
Sistema externo
      ↓
    HTTPS
      ↓
    API ERP
      ↓
   Service
      ↓
Repository
      ↓
PostgreSQL
```

A regra se aplica também ao:

```text
wmatravel.com.br
```

A arquitetura deverá suportar:

- REST;
- webhooks;
- retries;
- timeouts;
- idempotência;
- logs;
- auditoria.

---

## 13. ADR-010 — Observabilidade

A aplicação deverá nascer preparada para observabilidade.

Implementar progressivamente:

- logs estruturados;
- correlation ID;
- health checks;
- métricas;
- monitoramento de erros;
- auditoria;
- performance;
- rastreamento de integrações.

---

## 14. Estrutura Alvo do Backend

Estrutura inicial:

```text
Backend/
├── app/
│   ├── main.py
│   ├── api/
│   │   └── v1/
│   ├── core/
│   ├── modules/
│   │   ├── comercial/
│   │   ├── financeiro/
│   │   ├── turismo/
│   │   ├── biketour/
│   │   └── fiscal/
│   ├── integrations/
│   │   ├── website/
│   │   ├── payments/
│   │   └── operators/
│   └── shared/
│
├── migrations/
├── tests/
├── scripts/
├── .env.example
├── alembic.ini
├── pyproject.toml
└── README.md
```

A estrutura deverá ser criada progressivamente.

Não criar arquivos ou módulos vazios sem necessidade funcional.

---

## 15. Fronteiras entre Módulos

Os módulos deverão respeitar fronteiras de domínio.

Exemplo correto:

```text
Comercial
   ↓
FinanceiroService
   ↓
Financeiro
```

Exemplo incorreto:

```text
Comercial
   ↓
UPDATE direto em tabela financeira
```

A comunicação deverá ocorrer por interfaces, services ou contratos internos.

---

## 16. Dependências

Dependências entre módulos deverão ser controladas.

Não permitir dependências circulares.

Exemplo aceitável:

```text
Comercial → Financeiro
Turismo → Comercial
Turismo → Financeiro
Fiscal → Comercial
Fiscal → Financeiro
```

A direção final deverá ser refinada durante o desenho de domínio.

---

## 17. Política de Banco

O PostgreSQL será a fonte corporativa de persistência.

### Regras

- baseline Fase 1 protegida;
- migrations obrigatórias;
- constraints mantidas no banco;
- integridade não depender exclusivamente da aplicação;
- transações controladas;
- acesso externo ao banco proibido;
- auditoria preservada.

---

## 18. OpenAPI

O FastAPI deverá disponibilizar documentação automática.

Endpoints previstos:

```text
/docs
/redoc
/openapi.json
```

A especificação OpenAPI deverá ser tratada como parte do contrato oficial da
API.

---

## 19. CI

A arquitetura deverá prever GitHub Actions desde a fundação.

Validações iniciais:

- lint;
- testes;
- imports;
- configuração;
- migrations;
- segurança básica.

A expansão do pipeline ocorrerá conforme os módulos evoluírem.

---

## 20. Critérios de Certificação

A ETAPA 2.0.1 somente será considerada aprovada quando todos os critérios
abaixo estiverem definidos.

```text
Arquitetura ...................... OK
Monólito Modular ................. OK
Stack tecnológica ................ OK
Persistência ..................... OK
Migrations ....................... OK
API .............................. OK
Versionamento .................... OK
Configuração ..................... OK
Secrets .......................... OK
Segurança ........................ OK
Testes ........................... OK
Integrações ...................... OK
Observabilidade .................. OK
OpenAPI .......................... OK
CI ............................... OK
Proteção da baseline ............. OK
```

---

## 21. Entregáveis

A etapa deverá gerar os seguintes artefatos:

```text
Docs/architecture/
├── ADR-001-MODULAR-MONOLITH.md
├── ADR-002-TECH-STACK.md
├── ADR-003-PERSISTENCE.md
├── ADR-004-DATABASE-MIGRATIONS.md
├── ADR-005-API-STANDARDS.md
├── ADR-006-CONFIGURATION-SECRETS.md
├── ADR-007-SECURITY.md
├── ADR-008-TESTING.md
├── ADR-009-INTEGRATIONS.md
└── ADR-010-OBSERVABILITY.md
```

Também deverá existir um documento de certificação:

```text
Docs/certification/
PHASE_2_0_1_ARCHITECTURE_CERTIFICATION.md
```

---

## 22. Gate Final da Etapa

Resultado esperado:

```text
WMA TRAVEL ERP
FASE 2
ETAPA 2.0.1

ARQUITETURA TECNOLÓGICA .......... APROVADA
ADRs ............................. APROVADAS
STACK ............................ APROVADA
BASELINE FASE 1 .................. PROTEGIDA
BACKEND .......................... AUTORIZADO PARA BOOTSTRAP
```

---

## 23. Próxima Etapa

Após a certificação:

**ETAPA 2.0.2 — Bootstrap do Backend**

Nessa etapa serão criados:

- `Backend/`;
- ambiente Python;
- `pyproject.toml`;
- FastAPI;
- SQLAlchemy;
- Alembic;
- psycopg;
- pytest;
- HTTPX;
- `.env.example`;
- aplicação mínima.

---

## 24. Status

**ETAPA 2.0.1: EM EXECUÇÃO**

**Próxima atividade:** ADR-002 — Stack Tecnológica.

---

**WMA Travel ERP**

**Fase 2 — Backend, API e Integrações**

**ETAPA 2.0.1 — Arquitetura Tecnológica**
