# WMA Travel ERP

<!-- WMA_PHASE_1_CERTIFICATION -->

## Marco de Certificação da Fase 1

**Status:** CONCLUÍDA E CERTIFICADA
**Data da certificação:** 17/08/2026
**PostgreSQL:** 18.4
**Baseline certificada:** `d63800e`
**Fase atual:** Fase 2 — Backend e API

**Progresso da Fase 2:** fundação 2.0, Core Corporativo 2.1 e etapas 2.2.1 e 2.2.2 certificados

**Próxima etapa:** 2.2.3 — Hash de Credenciais

A Fase 1 do WMA Travel ERP foi formalmente concluída após a validação da
fundação do banco de dados, incluindo auditoria estrutural, reconstrução
independente, validação de reprodutibilidade e comparação da baseline com o
ambiente reconstruído.

A baseline PostgreSQL certificada passa a constituir a referência histórica
para a evolução do projeto.

Alterações estruturais posteriores deverão ser introduzidas através de
migrations versionadas, documentadas e validadas.

Documentos de referência:

- `Database/certification/FASE_1_CERTIFICACAO_FINAL.md`
- `Database/certification/F1_FIN_CERTIFICACAO_REPRODUTIBILIDADE.md`
- `Docs/PHASE_1_TO_PHASE_2_TRANSITION.md`
- `Docs/RELATORIO_FASE_1.md`
- `Docs/PHASE_2_ROADMAP.md`
- `Docs/PHASE_2_EXECUTION_ORDER.md`

## Progresso das fases

| Fase | Escopo | Status |
| --- | --- | --- |
| Fase 1 | Fundação e Banco de Dados | **CONCLUÍDA E CERTIFICADA** |
| Fase 2 | Backend, API e Integrações | **EM EXECUÇÃO** |

### Etapas concluídas da Fase 2

| Etapa | Entrega | Status |
| --- | --- | --- |
| 2.0.1 | Definição da Arquitetura Tecnológica | **CONCLUÍDA E CERTIFICADA** |
| 2.0.2 | Estrutura do Backend | **CONCLUÍDA E CERTIFICADA** |
| 2.0.3 | Estrutura Modular do Backend | **CONCLUÍDA E CERTIFICADA** |
| 2.0.4 | Configuração do Backend | **CONCLUÍDA E CERTIFICADA** |
| 2.0.5 | PostgreSQL e SQLAlchemy | **CONCLUÍDA E CERTIFICADA** |
| 2.0.6 | Alembic e Migrations | **CONCLUÍDA E CERTIFICADA** |
| 2.0.7 | API Base | **CONCLUÍDA E CERTIFICADA** |
| 2.0.8 | OpenAPI | **CONCLUÍDA E CERTIFICADA** |
| 2.0.9 | Testes Iniciais | **CONCLUÍDA E CERTIFICADA** |
| 2.0.10 | GitHub Actions | **CONCLUÍDA E CERTIFICADA** |
| 2.0.11 | Certificação da Fundação | **CONCLUÍDA E CERTIFICADA** |
| 2.1.1 | Inventário do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.2 | Models do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.3 | Repositories do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.4 | Services do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.5 | Schemas do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.6 | API do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.7 | Testes do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.1.8 | Certificação do Core Corporativo | **CONCLUÍDA, CERTIFICADA E INTEGRADA** |
| 2.2.1 | Inventário e Modelo de Identidade | **CONCLUÍDA E CERTIFICADA** |

> Plataforma Corporativa Integrada de Gestão Empresarial para Turismo, Serviços e Inteligência de Negócios.

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![Database](https://img.shields.io/badge/database-PostgreSQL%2018-blue)
![Backend](https://img.shields.io/badge/backend-FastAPI-orange)
![Frontend](https://img.shields.io/badge/frontend-React-blue)
![BI](https://img.shields.io/badge/BI-Power%20BI-yellow)
![License](https://img.shields.io/badge/license-Propriet%C3%A1ria-red)

---

## 📚 Índice

- [WMA Travel ERP](#wma-travel-erp)
  - [Marco de Certificação da Fase 1](#marco-de-certificação-da-fase-1)
  - [📚 Índice](#-índice)
  - [📌 Visão Geral](#-visão-geral)
  - [🎯 Objetivos](#-objetivos)
  - [🚀 Principais Características](#-principais-características)
  - [Plataforma Corporativa](#plataforma-corporativa)
  - [Gestão Empresarial](#gestão-empresarial)
  - [Inteligência de Negócios](#inteligência-de-negócios)
  - [🏗 Arquitetura](#-arquitetura)
  - [💻 Tecnologias](#-tecnologias)
  - [Banco de Dados](#banco-de-dados)
  - [Backend](#backend)
  - [Frontend](#frontend)
  - [Mobile](#mobile)
  - [Business Intelligence](#business-intelligence)
  - [Controle de Versão](#controle-de-versão)
  - [📂 Estrutura do Projeto](#-estrutura-do-projeto)
  - [🗄 Banco de Dados](#-banco-de-dados)
  - [Características](#características)
  - [🔎 Framework de Auditoria](#-framework-de-auditoria)
  - [Recursos](#recursos)
  - [🛡 Framework de Governança de Dados](#-framework-de-governança-de-dados)
  - [Controles Implementados](#controles-implementados)
  - [✅ Certificação da Base de Dados](#-certificação-da-base-de-dados)
  - [Itens Avaliados](#itens-avaliados)
  - [Indicador](#indicador)
  - [Objetivo](#objetivo)
  - [📦 Módulos do ERP](#-módulos-do-erp)
  - [💰 Financeiro](#-financeiro)
  - [Funcionalidades](#funcionalidades)
  - [🤝 Comercial e CRM](#-comercial-e-crm)
    - [Funcionalidades](#funcionalidades-1)
  - [🧾 Fiscal](#-fiscal)
    - [Funcionalidades](#funcionalidades-2)
  - [✈️ Turismo](#️-turismo)
    - [Funcionalidades](#funcionalidades-3)
  - [🚴 WMA Bike Tour](#-wma-bike-tour)
    - [Funcionalidades](#funcionalidades-4)
  - [🏢 Administrativo](#-administrativo)
    - [Funcionalidades](#funcionalidades-5)
  - [⚙️ Instalação](#️-instalação)
  - [Pré-requisitos](#pré-requisitos)
  - [📥 Configuração do Projeto](#-configuração-do-projeto)
  - [Acessar o diretório do projeto](#acessar-o-diretório-do-projeto)
  - [🗄 Configuração do Banco de Dados](#-configuração-do-banco-de-dados)
  - [Criar Banco PostgreSQL](#criar-banco-postgresql)
  - [Estrutura dos Scripts de Banco](#estrutura-dos-scripts-de-banco)
  - [Processos Executados](#processos-executados)
  - [🐍 Configuração do Backend](#-configuração-do-backend)
  - [Acessar diretório](#acessar-diretório)
  - [Criar ambiente virtual Python](#criar-ambiente-virtual-python)
  - [Ativar ambiente virtual](#ativar-ambiente-virtual)
    - [Windows](#windows)
    - [Linux / Mac](#linux--mac)
  - [Instalar dependências](#instalar-dependências)
  - [Executar API](#executar-api)
  - [⚛️ Configuração do Frontend](#️-configuração-do-frontend)
    - [Acessar diretório](#acessar-diretório-1)
    - [Instalar dependências](#instalar-dependências-1)
    - [Executar aplicação](#executar-aplicação)
  - [📱 Configuração Mobile](#-configuração-mobile)
  - [Tecnologia](#tecnologia)
    - [Instalar dependências](#instalar-dependências-2)
    - [Executar aplicação](#executar-aplicação-1)
    - [Aplicações previstas](#aplicações-previstas)
  - [🔢 Versionamento](#-versionamento)
  - [Semantic Versioning (SemVer)](#semantic-versioning-semver)
  - [Definição das versões](#definição-das-versões)
  - [📚 Documentação](#-documentação)
  - [Documentos Principais](#documentos-principais)
  - [📖 Documentação Técnica](#-documentação-técnica)
  - [🛣 Roadmap](#-roadmap)
  - [🚀 Próximas Evoluções](#-próximas-evoluções)
    - [Business Intelligence](#business-intelligence-1)
  - [Inteligência Artificial](#inteligência-artificial)
  - [Integrações](#integrações)
  - [Aplicativo Mobile](#aplicativo-mobile)
  - [🤝 Contribuição](#-contribuição)
  - [🔄 Processo de Desenvolvimento](#-processo-de-desenvolvimento)
  - [📜 Licenciamento](#-licenciamento)
  - [WMA Travel Ltda.](#wma-travel-ltda)
  - [👨‍💻 Autor](#-autor)
  - [Vâner de Menezes Lázaro](#vâner-de-menezes-lázaro)
  - [🌐 Contato](#-contato)
  - [Website](#website)
  - [📊 Status do Projeto](#-status-do-projeto)
  - [🏆 Visão do Projeto](#-visão-do-projeto)

---

## 📌 Visão Geral

O **WMA Travel ERP** é uma plataforma corporativa integrada de gestão empresarial desenvolvida pela **WMA Travel Ltda.**

O sistema foi criado para centralizar, automatizar e integrar os processos:

- Administrativos;
- Financeiros;
- Fiscais;
- Comerciais;
- Operacionais;
- Gerenciais.

A solução foi projetada utilizando princípios de:

- Arquitetura corporativa;
- Governança de dados;
- Segurança da informação;
- Modularização;
- Escalabilidade;
- Boas práticas de engenharia de software.

O ERP atende empresas dos segmentos:

- Turismo;
- Agências de viagens;
- Operadoras turísticas;
- Receptivos;
- Eventos;
- Cicloturismo;
- Serviços especializados.

O projeto possui módulos específicos para gerenciamento de experiências turísticas e operações do **WMA Bike Tour**.

---

## 🎯 Objetivos

Os principais objetivos do projeto são:

- Centralizar operações empresariais em uma única plataforma;
- Automatizar processos administrativos e operacionais;
- Garantir integridade, segurança e rastreabilidade das informações;
- Disponibilizar indicadores estratégicos para tomada de decisão;
- Melhorar produtividade e eficiência operacional;
- Padronizar processos internos;
- Criar uma base tecnológica escalável;
- Permitir evolução contínua através de arquitetura modular.

---

## 🚀 Principais Características

## Plataforma Corporativa

O WMA Travel ERP possui:

- Arquitetura modular;
- Banco de dados PostgreSQL corporativo;
- API REST;
- Controle de usuários;
- Controle de permissões;
- Auditoria completa;
- Governança de dados;
- Certificação da base;
- Dashboard executivo;
- Integração com Business Intelligence.

---

## Gestão Empresarial

Principais recursos:

- Gestão administrativa;
- Gestão financeira;
- Gestão fiscal;
- Gestão comercial;
- Gestão de clientes;
- Gestão de fornecedores;
- Gestão de contratos;
- Gestão de projetos;
- Gestão turística.

---

## Inteligência de Negócios

Recursos analíticos:

- Indicadores financeiros;
- Dashboards gerenciais;
- Relatórios estratégicos;
- Análise de desempenho;
- Integração Microsoft Power BI.

---

## 🏗 Arquitetura

O WMA Travel ERP utiliza arquitetura moderna baseada em camadas.

```text
WMA Travel ERP
│
├── PostgreSQL Database
│
├── FastAPI REST API
│
├── Backend Python + FastAPI
│
├── Frontend React + TypeScript
│
├── Mobile Flutter
│
├── Dashboard Microsoft Power BI
│
└── Framework DBA
```

---

## 💻 Tecnologias

## Banco de Dados

Tecnologias utilizadas:

- PostgreSQL 18
- PL/pgSQL
- SQL
- Modelagem Relacional
- Índices otimizados
- Triggers
- Functions
- Procedures

---

## Backend

Tecnologias utilizadas:

- Python 3.13+
- FastAPI
- SQLAlchemy
- Alembic
- API REST

Responsabilidades:

- Regras de negócio;
- Processamento empresarial;
- Integrações;
- Serviços internos.

---

## Frontend

Tecnologias utilizadas:

- React
- TypeScript
- Material UI

Responsável por:

- Interface administrativa;
- Dashboards;
- Experiência do usuário.

---

## Mobile

Tecnologia:

- Flutter

Aplicações:

- Operações em campo;
- Eventos;
- Cicloturismo;
- Atendimento operacional.

---

## Business Intelligence

Tecnologia:

- Microsoft Power BI

Aplicações:

- Indicadores estratégicos;
- Dashboards executivos;
- Relatórios gerenciais;
- Análises de desempenho.

---

## Controle de Versão

Ferramentas:

- Git;
- GitHub.

Práticas:

- Versionamento semântico;
- Controle de alterações;
- Organização por branches.

---

## 📂 Estrutura do Projeto

A organização do projeto segue uma arquitetura modular preparada para evolução contínua.

```text
WMATRAVEL_ERP/
│
├── backend/
│   ├── api/
│   ├── core/
│   ├── modules/
│   ├── services/
│   └── tests/
│
├── frontend/
│   ├── src/
│   ├── components/
│   ├── pages/
│   └── services/
│
├── mobile/
│
├── database/
│   ├── migrations/
│   ├── scripts/
│   ├── audit/
│   └── certification/
│
├── docs/
│   ├── architecture/
│   ├── database/
│   ├── api/
│   └── guides/
│
├── scripts/
│
├── tests/
│
├── tools/
│
├── ci/
│
├── README.md
├── CHANGELOG.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
└── VERSION
```

---

## 🗄 Banco de Dados

A camada de dados do **WMA Travel ERP** foi projetada seguindo padrões corporativos de modelagem,
governança, segurança e auditoria.

## Características

- Modelagem relacional;
- Integridade referencial;
- Controle transacional;
- Versionamento de scripts;
- Auditoria de dados;
- Governança de informações;
- Certificação automática da base.

---

## 🔎 Framework de Auditoria

O **WMA Travel ERP** possui framework próprio de auditoria desenvolvido para garantir rastreabilidade,
segurança e controle das operações realizadas no sistema.

## Recursos

- Histórico de alterações;
- Registro de usuários responsáveis;
- Controle de operações realizadas;
- Registro de data e hora dos eventos;
- Rastreamento de modificações;
- Auditoria de tabelas críticas.

---

## 🛡 Framework de Governança de Dados

O framework de governança garante padronização, qualidade e confiabilidade das informações armazenadas.

## Controles Implementados

- Padronização de tabelas;
- Padronização de nomenclaturas;
- Validação de relacionamentos;
- Controle de integridade dos dados;
- Documentação técnica;
- Comentários de objetos do banco;
- Monitoramento da estrutura.

---

## ✅ Certificação da Base de Dados

O processo de certificação valida a qualidade estrutural e operacional do banco de dados.

## Itens Avaliados

- Estrutura das tabelas;
- Chaves primárias;
- Chaves estrangeiras;
- Índices;
- Constraints;
- Campos obrigatórios;
- Integridade referencial;
- Qualidade dos dados.

## Indicador

**ICB - Índice de Certificação do Banco**

## Objetivo

Garantir que a base de dados esteja preparada para operação corporativa,
mantendo confiabilidade, desempenho e segurança.

---

## 📦 Módulos do ERP

O **WMA Travel ERP** é composto por módulos integrados responsáveis pela gestão completa dos processos empresariais.

---

## 💰 Financeiro

Responsável pela gestão financeira empresarial.

## Funcionalidades

- Plano de Contas;
- Contas a pagar;
- Contas a receber;
- Fluxo de Caixa;
- DRE Gerencial;
- Balancete;
- Conciliação bancária;
- Movimentações financeiras;
- Centros de custos;
- Controle de aportes;
- Pró-labore;
- Distribuição de lucros.

---

## 🤝 Comercial e CRM

Responsável pelo relacionamento comercial e gestão de clientes.

### Funcionalidades

- Cadastro de clientes;
- Leads;
- Oportunidades comerciais;
- Histórico de atendimento;
- Propostas comerciais;
- Contratos;
- Vendas;
- Follow-up.

---

## 🧾 Fiscal

Responsável pelo controle das obrigações fiscais e tributárias.

### Funcionalidades

- NFSe;
- NFe;
- Simples Nacional;
- Obrigações acessórias;
- Documentos fiscais;
- Controle tributário.

---

## ✈️ Turismo

Módulo especializado para operações turísticas.

### Funcionalidades

- Cadastro de produtos turísticos;
- Pacotes;
- Roteiros;
- Reservas;
- Hospedagens;
- Transportes;
- Voos;
- Passeios;
- Guias;
- Fornecedores turísticos.

---

## 🚴 WMA Bike Tour

Módulo exclusivo para gerenciamento de operações de cicloturismo.

### Funcionalidades

- Eventos;
- Trilhas;
- Rotas;
- Inscrições;
- Participantes;
- Equipes de apoio;
- Pontos de controle;
- Bicicletas;
- Equipamentos;
- Logística operacional.

---

## 🏢 Administrativo

Responsável pela administração geral do sistema.

### Funcionalidades

- Empresas;
- Filiais;
- Usuários;
- Perfis de acesso;
- Permissões;
- Configurações;
- Parâmetros do sistema;
- Auditoria administrativa.

---

## ⚙️ Instalação

## Pré-requisitos

Antes de iniciar a instalação do **WMA Travel ERP**, certifique-se de possuir:

- PostgreSQL 18;
- Python 3.13 ou superior;
- Node.js;
- Flutter SDK;
- Git;
- Visual Studio Code.

---

## 📥 Configuração do Projeto

## Acessar o diretório do projeto

```bash
cd WMATRAVEL_ERP
```

---

## 🗄 Configuração do Banco de Dados

## Criar Banco PostgreSQL

Execute:

```sql
CREATE DATABASE wma_travel_erp;
```

## Estrutura dos Scripts de Banco

```text
database/
├── migrations/
├── scripts/
├── audit/
└── certification/
```

## Processos Executados

- Criação das tabelas;
- Criação das constraints;
- Criação dos índices;
- Criação das funções;
- Criação das triggers;
- Configuração da auditoria;
- Certificação da base de dados.

---

## 🐍 Configuração do Backend

## Acessar diretório

```bash
cd backend
```

## Criar ambiente virtual Python

```bash
python -m venv venv
```

## Ativar ambiente virtual

### Windows

```bash
venv\Scripts\activate
```

### Linux / Mac

```bash
source venv/bin/activate
```

## Instalar dependências

```bash
pip install -r requirements.txt
```

## Executar API

```bash
uvicorn main:app --reload
```

API disponível em:

```text
http://localhost:8000
```

---

## ⚛️ Configuração do Frontend

### Acessar diretório

```bash
cd frontend
```

### Instalar dependências

```bash
npm install
```

### Executar aplicação

```bash
npm run dev
```

Frontend disponível em:

```text
http://localhost:3000
```

---

## 📱 Configuração Mobile

## Tecnologia

- Flutter

### Instalar dependências

```bash
flutter pub get
```

### Executar aplicação

```bash
flutter run
```

### Aplicações previstas

- Operações em campo;
- Eventos;
- Cicloturismo;
- Atendimento operacional.

---

## 🔢 Versionamento

O projeto utiliza o padrão:

## Semantic Versioning (SemVer)

Formato:

```text
MAJOR.MINOR.PATCH
```

Exemplo:

```text
1.0.0
```

## Definição das versões

| Versão | Descrição |
| --- | --- |
| MAJOR | Alterações estruturais importantes |
| MINOR | Inclusão de novas funcionalidades |
| PATCH | Correções e melhorias |

Versão atual:

```text
1.0.0
```

---

## 📚 Documentação

A documentação oficial do projeto é organizada para facilitar:

- Manutenção;
- Evolução;
- Governança;
- Padronização técnica.

## Documentos Principais

| Documento | Descrição |
| --- | --- |
| README.md | Visão geral do projeto |
| CHANGELOG.md | Histórico de alterações |
| ROADMAP.md | Planejamento de evolução |
| CONTRIBUTING.md | Guia de contribuição |
| CODE_OF_CONDUCT.md | Código de conduta |
| LICENSE | Licenciamento |
| VERSION | Controle de versão |

---

## 📖 Documentação Técnica

Documentos complementares:

| Documento | Descrição |
| --- | --- |
| ARCHITECTURE.md | Arquitetura geral do sistema |
| DATABASE_GUIDE.md | Guia do banco de dados |
| DATA_DICTIONARY.md | Dicionário de dados |
| API.md | Documentação das APIs |
| DEPLOYMENT.md | Processo de implantação |
| SECURITY.md | Segurança da aplicação |
| STYLE_GUIDE.md | Padrões de desenvolvimento |
| GOVERNANCE.md | Governança do projeto |
| DBA_FRAMEWORK.md | Framework DBA |

---

## 🛣 Roadmap

O planejamento completo da evolução do projeto está disponível em:

```text
ROADMAP.md
```

---

## 🚀 Próximas Evoluções

### Business Intelligence

Planejamento:

- Dashboards executivos;
- Indicadores financeiros;
- Indicadores comerciais;
- Análises operacionais;
- Relatórios estratégicos.

---

## Inteligência Artificial

Possíveis aplicações:

- Assistente inteligente;
- Análise preditiva;
- Automação de processos;
- Recomendações estratégicas.

---

## Integrações

Planejamento:

- APIs externas;
- Gateways de pagamento;
- Sistemas turísticos;
- Plataformas de reservas;
- Serviços governamentais.

---

## Aplicativo Mobile

Evolução prevista:

- Operações em campo;
- Gestão de eventos;
- Cicloturismo;
- Atendimento ao cliente;
- Comunicação operacional.

---

## 🤝 Contribuição

As regras para contribuição estão disponíveis no arquivo:

```text
CONTRIBUTING.md
```

Antes de realizar alterações:

- Consulte a documentação;
- Respeite os padrões do projeto;
- Utilize boas práticas de desenvolvimento;
- Atualize documentos relacionados;
- Execute testes.

---

## 🔄 Processo de Desenvolvimento

O projeto segue práticas de engenharia de software:

- Controle de versão Git;
- Organização modular;
- Revisão de código;
- Documentação contínua;
- Testes automatizados;
- Padronização técnica.

---

## 📜 Licenciamento

Este software é propriedade exclusiva da:

## WMA Travel Ltda.

Todos os direitos reservados.

Este projeto possui licença proprietária.

Não é permitido:

- Copiar;
- Distribuir;
- Modificar;
- Comercializar;
- Utilizar partes do código;

sem autorização formal da **WMA Travel Ltda.**

Arquivo:

```text
LICENSE
```

---

## 👨‍💻 Autor

## Vâner de Menezes Lázaro

Fundador da:

**WMA Travel Ltda.**

Responsável pela arquitetura, desenvolvimento e evolução da plataforma.

---

## 🌐 Contato

## Website

[Website](https://wmatravel.com.br)

---

## 📊 Status do Projeto

| Item | Situação |
| --- | --- |
| Projeto | Em desenvolvimento |
| Versão | 1.0.0 |
| Arquitetura | Estável |
| Banco de Dados | Fase 1 certificada — 220 tabelas após F1-FIN |
| Auditoria | Implementada |
| Governança | Implementada |
| Documentação | Evolução contínua |

---

## 🏆 Visão do Projeto

O **WMA Travel ERP** representa uma plataforma tecnológica criada
para transformar a gestão empresarial através da integração entre:

- Tecnologia;
- Dados;
- Automação;
- Inteligência de Negócios;
- Processos empresariais.

O objetivo é construir uma solução moderna, escalável e preparada para o crescimento sustentável da **WMA Travel Ltda.**

---

**Copyright © 2026 WMA Travel Ltda.**

**Todos os direitos reservados.**
