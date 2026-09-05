# WMA Travel ERP — Manual Mestre da Documentação

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Manual Mestre
> **Versão:** 1.1.0
> **Data:** 01/09/2026
> **Status:** VIGENTE

---

## Índice

- [WMA Travel ERP — Manual Mestre da Documentação](#wma-travel-erp--manual-mestre-da-documentação)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Escopo](#2-escopo)
  - [3. Organização da Documentação](#3-organização-da-documentação)
  - [4. Estrutura do Projeto](#4-estrutura-do-projeto)
  - [5. Documentação Institucional](#5-documentação-institucional)
  - [6. Documentação Técnica](#6-documentação-técnica)
  - [7. Banco de Dados](#7-banco-de-dados)
  - [8. Framework DBA](#8-framework-dba)
  - [9. Desenvolvimento](#9-desenvolvimento)
  - [10. Implantação](#10-implantação)
  - [11. Governança](#11-governança)
  - [12. Segurança](#12-segurança)
  - [13. Fluxo da Documentação](#13-fluxo-da-documentação)
  - [14. Ordem Recomendada de Leitura](#14-ordem-recomendada-de-leitura)
  - [15. Controle do Documento](#15-controle-do-documento)
  - [Observações](#observações)

---

## 1. Objetivo

Este documento centraliza toda a documentação oficial do
**WMA Travel ERP**, servindo como ponto único de navegação para:

- desenvolvedores;
- arquitetos de software;
- administradores de banco de dados (DBA);
- analistas;
- gestores;
- auditores.

Todos os documentos oficiais do projeto deverão estar referenciados neste manual.

---

## 2. Escopo

Este manual contempla:

- documentação institucional;
- documentação técnica;
- documentação do banco de dados;
- documentação do Framework DBA;
- documentação de implantação;
- documentação de segurança;
- documentação de governança;
- documentação de APIs;
- documentação de padronização.

O estado oficial de execução está consolidado em `PHASE_2_EXECUTION_ORDER.md`. A Fase 1 está concluída e
certificada; a Fase 2 está em execução, com as etapas 2.0 a 2.5 concluídas, certificadas e integradas. A ADR-017
reprogramou as etapas funcionais, e a etapa 2.6 — Turismo está certificada e aguardando integração remota. A
implementação funcional da etapa 2.7 ainda não está autorizada.

---

## 3. Organização da Documentação

A documentação está organizada nas seguintes categorias:

- Institucional
- Arquitetura
- Banco de Dados
- Desenvolvimento
- APIs
- Implantação
- Segurança
- Governança
- Framework DBA

---

## 4. Estrutura do Projeto

```text
WMA Travel ERP/
├── Backend/
│   ├── README.md
│   ├── app/
│   ├── migrations/
│   └── tests/
├── Database/
│   ├── README.md
│   ├── audit/
│   ├── certification/
│   ├── migrations/
│   └── scripts/
└── Docs/
    ├── architecture/
    ├── certification/
    ├── templates/
    ├── PROJECT_DOCUMENTATION.md
    ├── PHASE_2_EXECUTION_ORDER.md
    └── README.md
```

---

## 5. Documentação Institucional

| Documento | Finalidade |
| ------------------ | ------------------------ |
| README.md | Visão geral do projeto |
| CHANGELOG.md | Histórico de versões |
| ROADMAP.md | Planejamento de evolução |
| CONTRIBUTING.md | Processo de contribuição |
| CODE_OF_CONDUCT.md | Código de conduta |
| LICENSE | Licenciamento |

---

## 6. Documentação Técnica

| Documento | Finalidade |
| ---------------------- | -------------------------- |
| ARCHITECTURE.md | Arquitetura corporativa |
| CODE_STANDARDS.md | Norma oficial de Python, API, arquitetura e qualidade |
| DOCUMENTATION_STANDARDS.md | Norma oficial de famílias, metadados, status e templates |
| DOCUMENTATION_INVENTORY.md | Inventário e classificação das famílias documentais |
| DATABASE_GUIDE.md | Guia do banco de dados |
| DATABASE_STANDARDS.md | Padrões técnicos do banco |
| DATA_DICTIONARY.md | Dicionário de dados |
| API.md | APIs REST |
| API_GOVERNANCE_INVENTORY.md | Inventário e encerramento da governança da API 2.3 |
| COMMERCIAL_INVENTORY.md | Inventário das autoridades, relações e lacunas comerciais da etapa 2.4.1 |
| COMMERCIAL_EXECUTION_SCHEDULE.md | Cronograma oficial, entregas e gates da etapa Comercial 2.4 |
| COMMERCIAL_CLIENTS.md | Contrato interno e casos de uso comerciais de Cliente da etapa 2.4.2 |
| COMMERCIAL_MODULE.md | Modelo, regras, API e validação local das etapas 2.4.3 a 2.4.12 |
| FINANCIAL_DOCUMENTATION_GATE.md | Fontes, entregáveis e critérios de entrada da etapa Financeiro 2.5 |
| API_RESPONSE_MATRIX.md | Matriz normativa de respostas HTTP da API v1 |
| API_CHANGE_GOVERNANCE.md | Propriedade, aprovação e exceções de mudança da API |
| DEPLOYMENT.md | Processo de implantação |
| GOVERNANCE.md | Governança do projeto |
| SECURITY.md | Política de segurança |
| AUTHENTICATION.md | Contrato e limites da autenticação humana 2.2.2 |
| CREDENTIAL_HASHING.md | Política e limites do hash de credenciais 2.2.3 |
| TOKENS_AND_SESSIONS.md | Política e limites de tokens e sessões humanas 2.2.4 |
| STYLE_GUIDE.md | Padrões de desenvolvimento |
| DBA_FRAMEWORK.md | Framework DBA |
| PHASE_2_ROADMAP.md | Planejamento oficial da Fase 2 |
| PHASE_2_EXECUTION_ORDER.md | Ordem, gates e status das etapas da Fase 2 |
| certification/ | Evidências das etapas certificadas da Fase 2 |
| templates/CERTIFICATION_TEMPLATE.md | Template obrigatório para novas certificações |
| templates/TECHNICAL_DOCUMENT_TEMPLATE.md | Template para novas entregas técnicas |
| templates/EXECUTION_SCHEDULE_TEMPLATE.md | Template para cronogramas de execução |
| templates/ADR_TEMPLATE.md | Template para novas decisões arquiteturais |
| certification/PHASE_2_3_API_GOVERNANCE_CERTIFICATION.md | Certificação final da governança de API |
| certification/PHASE_2_4_1_COMMERCIAL_INVENTORY_CERTIFICATION.md | Aprovação local do inventário Comercial |
| certification/PHASE_2_4_2_COMMERCIAL_CLIENTS_CERTIFICATION.md | Aprovação local dos serviços de Cliente |
| certification/PHASE_2_4_COMMERCIAL_CERTIFICATION.md | Certificação consolidada do módulo Comercial |

---

## 7. Banco de Dados

A documentação oficial do banco está organizada na seguinte sequência:

1. DATABASE_GUIDE.md
2. DATABASE_STANDARDS.md
3. DATA_DICTIONARY.md
4. DBA_FRAMEWORK.md

Essa organização permite compreender:

- a arquitetura do banco;
- o dicionário de dados;
- os processos de auditoria;
- a governança;
- a certificação técnica.

---

## 8. Framework DBA

O Framework DBA contempla os seguintes componentes:

- Core
- Auditoria Estrutural
- Auditoria Documental
- Auditoria de Segurança
- Auditoria de Performance
- Backup
- Monitoramento
- Governança
- Dashboard Técnico
- Dashboard Executivo
- Certificação Técnica

---

## 9. Desenvolvimento

O projeto segue os seguintes padrões técnicos:

- Clean Architecture
- Clean Code
- SOLID
- Domain-Driven Design (DDD)
- Semantic Versioning (SemVer)
- Conventional Commits
- Markdownlint
- PostgreSQL Best Practices

---

## 10. Implantação

Fluxo recomendado de implantação:

```text
Clone do Repositório

↓

Configuração do Ambiente

↓

Instalação do PostgreSQL

↓

Execução dos Scripts SQL

↓

Migrações

↓

Inicialização da API

↓

Inicialização do Front-end

↓

Execução dos Testes

↓

Deploy
```

---

## 11. Governança

A governança do projeto contempla:

- Versionamento
- Auditorias
- Controle de Mudanças
- Indicadores
- Framework DBA
- Documentação
- Certificação Técnica

---

## 12. Segurança

Os principais pilares de segurança do projeto são:

- LGPD
- ISO 27001
- Controle de Acesso
- Auditoria
- Backup
- SSL/TLS
- Privilégios mínimos
- Monitoramento contínuo

---

## 13. Fluxo da Documentação

```text
README

↓

ARCHITECTURE

↓

DATABASE GUIDE

↓

DATABASE STANDARDS

↓

DATA DICTIONARY

↓

DBA FRAMEWORK

↓

API

↓

DEPLOYMENT

↓

GOVERNANCE

↓

SECURITY

↓

ROADMAP
```

---

## 14. Ordem Recomendada de Leitura

Para novos colaboradores recomenda-se a seguinte sequência:

1. README.md
2. ARCHITECTURE.md
3. DATABASE_GUIDE.md
4. DATABASE_STANDARDS.md
5. DATA_DICTIONARY.md
6. DBA_FRAMEWORK.md
7. API.md
8. DEPLOYMENT.md
9. GOVERNANCE.md
10. SECURITY.md
11. ROADMAP.md

---

## 15. Controle do Documento

| Campo | Valor |
| ------------------ | ----------------------------- |
| Documento | PROJECT_DOCUMENTATION.md |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Tipo | Manual Mestre da Documentação |
| Versão | 1.1.0 |
| Status | VIGENTE — EVOLUÇÃO CONTROLADA |
| Responsável | WMA Travel Ltda. |
| Compatibilidade | Markdownlint |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

---

## Observações

Este documento deverá permanecer atualizado sempre que novos documentos oficiais forem adicionados ao projeto.

Alterações estruturais na documentação deverão ser registradas no **CHANGELOG.md** e refletidas neste manual.

---

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
