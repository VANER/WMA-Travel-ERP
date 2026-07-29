# WMA Travel ERP

> Plataforma Corporativa Integrada de Gestão Empresarial para Turismo, Serviços e Inteligência de Negócios.

---

## Índice

  [Visão Geral](#visão-geral)
  [Objetivos](#objetivos)
  [Principais Características](#principais-características)
  [Arquitetura](#arquitetura)
  [Tecnologias](#tecnologias)
  [Estrutura do Projeto](#estrutura-do-projeto)
  [Banco de Dados](#banco-de-dados)
  [Módulos do ERP](#módulos-do-erp)
  [Instalação](#instalação)
  [Versionamento](#versionamento)
  [Documentação](#documentação)
  [Roadmap](#roadmap)
  [Contribuição](#contribuição)
  [Licenciamento](#licenciamento)
  [Autor](#autor)
  [Contato](#contato)
  [Status do Projeto](#status-do-projeto)

---

## Visão Geral

O **WMA Travel ERP** é uma plataforma corporativa desenvolvida para integrar os processos administrativos, financeiros, fiscais, comerciais e operacionais da **WMA Travel Ltda.**

O sistema foi concebido utilizando princípios de arquitetura corporativa, governança de dados, modularização e boas práticas de engenharia de software, permitindo crescimento contínuo, escalabilidade e alta confiabilidade.

Além da gestão empresarial, o ERP possui módulos especializados para o segmento de turismo, incluindo agências de viagens, receptivos turísticos, eventos, cicloturismo e gestão de experiências.

---

## Objetivos

Os principais objetivos do projeto são:

  Centralizar as operações da empresa.
  Automatizar processos administrativos.
  Garantir integridade das informações.
  Disponibilizar indicadores estratégicos em tempo real.
  Melhorar a produtividade operacional.
  Padronizar processos internos.
  Possibilitar crescimento modular do sistema.
  Servir como plataforma tecnológica para expansão da WMA Travel.

---

## Principais Características

  Arquitetura modular.
  Banco de dados corporativo PostgreSQL.
  Framework próprio de Auditoria.
  Framework de Governança.
  Certificação automática da base de dados.
  API REST.
  Dashboard Executivo.
  Integração com Microsoft Power BI.
  Controle Financeiro completo.
  CRM integrado.
  Gestão Comercial.
  Gestão Fiscal.
  Gestão Administrativa.
  Gestão de Turismo.
  Bike Tour.
  Business Intelligence.

---

## Arquitetura

```text
WMA Travel ERP
│
├── PostgreSQL Database
├── FastAPI REST API
├── Backend Python
├── Frontend React
├── Mobile Flutter
├── Dashboard Power BI
└── Framework DBA
```

O projeto utiliza arquitetura em camadas, separando responsabilidades entre banco de dados, API, serviços, interface e documentação.

---

## Tecnologias

### Banco de Dados

  PostgreSQL 15+
  PL/pgSQL

### Backend

  Python 3.12+
  FastAPI
  SQLAlchemy
  Alembic

### Frontend

  React
  TypeScript
  Material UI

### Mobile

  Flutter

### Business Intelligence

  Microsoft Power BI

### Controle de Versão

  Git
  GitHub

---

## Estrutura do Projeto

```text
WMATRAVEL_ERP/
│
├── backend/
├── frontend/
├── mobile/
├── database/
├── docs/
├── scripts/
├── tests/
├── ci/
├── tools/
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

## Arquitetura Banco de Dados

A camada de banco de dados foi projetada para atender padrões corporativos de governança e auditoria.

Características:

  Modelagem relacional.
  Integridade referencial.
  Versionamento de scripts.
  Framework de auditoria.
  Framework de certificação.
  Controle de qualidade da base.
  Comentários técnicos.
  Health Check.
  Índice de Certificação do Banco (ICB).

---

## Módulos do ERP

### Financeiro

  Plano de Contas
  Fluxo de Caixa
  DRE
  Balancete
  Contas a Pagar
  Contas a Receber
  Conciliação Bancária
  Centros de Custos

### Comercial

  CRM
  Clientes
  Fornecedores
  Contratos
  Propostas
  Vendas

### Fiscal

  NFSe
  NFe
  Simples Nacional
  Obrigações Acessórias

### Turismo

  Pacotes
  Reservas
  Hotéis
  Voos
  Passeios
  Guias

### Bike Tour

  Eventos
  Cicloturismo
  Trilhas
  Inscrições
  Participantes

### Administrativo

  Usuários
  Perfis
  Permissões
  Configurações
  Auditoria

---

## Instalação

1. Clonar o repositório.
2. Configurar o PostgreSQL.
3. Executar os scripts do banco de dados.
4. Configurar as variáveis de ambiente.
5. Instalar as dependências do backend.
6. Instalar as dependências do frontend.
7. Executar as migrações.
8. Iniciar a API.
9. Iniciar a interface web.

---

## Versionamento

O projeto utiliza **Semantic Versioning (SemVer)**.

Formato:

```text
MAJOR.MINOR.PATCH
```

Exemplo:

```text
1.0.0
```

---

## Documentação

A documentação oficial está organizada nos seguintes arquivos:

| Documento          | Descrição               |
| ------------------ | ----------------------- |
| README.md          | Visão geral do projeto  |
| CHANGELOG.md       | Histórico de versões    |
| ROADMAP.md         | Planejamento do projeto |
| CONTRIBUTING.md    | Guia de contribuição    |
| CODE_OF_CONDUCT.md | Código de conduta       |
| LICENSE            | Licença proprietária    |
| VERSION            | Versão atual            |

Documentação técnica complementar:

  ARCHITECTURE.md
  DATABASE_GUIDE.md
  DATA_DICTIONARY.md
  API.md
  DEPLOYMENT.md
  SECURITY.md
  STYLE_GUIDE.md
  GOVERNANCE.md
  DBA_FRAMEWORK.md

---

## Roadmap

O planejamento completo do projeto encontra-se em:

***ROADMAP.md**

---

## Contribuição

As diretrizes para contribuição estão disponíveis em:

***CONTRIBUTING.md**

---

## Licenciamento

Este projeto é proprietário da **WMA Travel Ltda.**

Todos os direitos são reservados.

Consulte o arquivo **LICENSE** para mais informações.

---

## Autor

***Vâner de Menezes Lázaro**

Fundador da WMA Travel Ltda.

---

## Contato

***Website**

<https://wmatravel.com.br>

---

## Status do Projeto

| Item           | Situação             |
| -------------- | -------------------- |
| Projeto        | Em desenvolvimento   |
| Versão         | 1.0.0                |
| Banco de Dados | Em certificação      |
| Arquitetura    | Estável              |
| Documentação   | Em evolução contínua |

---

**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
