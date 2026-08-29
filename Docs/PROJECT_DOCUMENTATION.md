# WMA Travel ERP — Manual Mestre da Documentação

> Documento oficial de navegação da documentação do projeto **WMA Travel ERP**.

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
certificada; a Fase 2 está em execução, com a fundação 2.0, o Core Corporativo 2.1, a etapa 2.2 e a Governança de
API 2.3 concluídos, certificados e integrados. As etapas funcionais posteriores aguardam reprogramação formal.

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
WMA_TRAVEL_ERP/

├── README.md
├── CHANGELOG.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── VERSION
│
├── docs/
│   ├── PROJECT_DOCUMENTATION.md
│   ├── ARCHITECTURE.md
│   ├── DATABASE_GUIDE.md
│   ├── DATABASE_STANDARDS.md
│   ├── DATA_DICTIONARY.md
│   ├── API.md
│   ├── DEPLOYMENT.md
│   ├── GOVERNANCE.md
│   ├── SECURITY.md
│   ├── STYLE_GUIDE.md
│   └── DBA_FRAMEWORK.md
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
| VERSION | Versão oficial |

---

## 6. Documentação Técnica

| Documento | Finalidade |
| ---------------------- | -------------------------- |
| ARCHITECTURE.md | Arquitetura corporativa |
| DATABASE_GUIDE.md | Guia do banco de dados |
| DATABASE_STANDARDS.md | Padrões técnicos do banco |
| DATA_DICTIONARY.md | Dicionário de dados |
| API.md | APIs REST |
| API_GOVERNANCE_INVENTORY.md | Inventário e pendências da governança da API 2.3 |
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
| certification/PHASE_2_3_API_GOVERNANCE_CERTIFICATION.md | Certificação controlada da governança de API |

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
| Tipo | Manual Mestre da Documentação |
| Versão | 1.0.0 |
| Status | Oficial |
| Responsável | WMA Travel Ltda. |
| Compatibilidade | Markdownlint |
| Última atualização | 2026 |

---

## Observações

Este documento deverá permanecer atualizado sempre que novos documentos oficiais forem adicionados ao projeto.

Alterações estruturais na documentação deverão ser registradas no **CHANGELOG.md** e refletidas neste manual.

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
