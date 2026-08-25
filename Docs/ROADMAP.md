# Roadmap do WMA Travel ERP

<!-- WMA_PHASE_1_ROADMAP_CLOSE -->

## Fase 1 — Fundação e Banco de Dados

**Status:** CONCLUÍDA E CERTIFICADA  
**Conclusão:** 17/08/2026  
**PostgreSQL:** 18.4  
**Baseline:** `d63800e`

### Entregas certificadas

- modelagem corporativa do banco;
- padronização SQL;
- schemas e tabelas;
- constraints;
- índices;
- sequences e identity;
- triggers;
- views;
- functions e procedures;
- auditoria estrutural;
- catálogo técnico;
- dicionário de dados;
- baseline SQL;
- reconstrução independente;
- validação de banco limpo;
- validação de reprodutibilidade;
- comparação baseline × rebuild;
- hashes normalizados;
- certificação final.
- evolução financeira F1-FIN reproduzida em banco limpo;
- validação estrutural bloqueante integrada ao instalador.
- certificação final F1-FIN.13 com gate de resíduos e evidência versionada.

### Gate de saída

- Baseline certificada: APROVADA
- Estrutura auditada: APROVADA
- Rebuild: APROVADO
- Reprodutibilidade: APROVADA
- Divergências estruturais críticas: 0
- Certificação financeira F1-FIN: APROVADA
- Marco definitivo: tag `phase-1-final-2026-08-18`
- Transição para Fase 2: AUTORIZADA

## Fase 2 — Backend e API

**Status:** INICIADA EM 18/08/2026

**Progresso:** fundação 2.0 e etapas 2.1.1 a 2.1.6 concluídas e certificadas

**Próxima etapa:** 2.1.7 — Testes do Core Corporativo

**Branch inicial:** `feature/fase-2-backend-api`

**Fundação imutável:** tag `phase-1-final-2026-08-18`

A Fase 2 utilizará a baseline certificada como fundação para o desenvolvimento
das camadas de aplicação e integração.

**Versão do Documento:** 1.0.0
**Última Atualização:** 25/08/2026
**Status:** Fase 1 encerrada; Fase 2 em execução

---

## Visão Geral

O **WMA Travel ERP** é uma plataforma completa de gestão empresarial voltada para:

- Agências de turismo;
- Operadoras de turismo;
- Receptivos turísticos;
- Empresas de serviços;
- Operações de cicloturismo.

O projeto tem como objetivo desenvolver um **ERP moderno, modular, escalável e baseado em tecnologias Open Source**,
seguindo padrões profissionais de desenvolvimento de software, governança de dados, segurança da informação e
qualidade empresarial.

A plataforma foi projetada para integrar processos:

- Administrativos;
- Financeiros;
- Comerciais;
- Operacionais;
- Gerenciais.

O sistema proporciona maior controle, rastreabilidade das informações e suporte à tomada de decisões estratégicas.

---

## Objetivos do Projeto

### Objetivo Geral

Desenvolver um ERP corporativo integrado contemplando:

- Gestão Financeira.
- Gestão Fiscal.
- Gestão Comercial.
- CRM.
- Turismo.
- WMA Bike Tour.
- Dashboard Executivo.
- Business Intelligence.
- Governança de Dados.
- Auditoria.
- Certificação do Banco de Dados.

---

## Arquitetura da Plataforma

```text
WMA Travel ERP

├── Banco de Dados
├── API
├── Back-end
├── Front-end
├── Aplicativo Mobile
├── Business Intelligence
└── Infraestrutura
```

---

## Cronograma de Desenvolvimento

### Fase 1 - Fundação

**Status:** Em Desenvolvimento

#### Banco de Dados

**Entregas:**

- Modelagem relacional.
- Padronização estrutural.
- Governança de banco de dados.
- Framework DBA.
- Auditoria técnica.
- Certificação da base.
- Scripts SQL.
- Catálogo técnico.

---

### Fase 2 - API

**Status:** Planejado

#### Entregas da API

- API REST.
- Autenticação JWT.
- OAuth2.
- Swagger.
- OpenAPI.
- Versionamento de API.

---

### Fase 3 - Back-end

**Status:** Planejado

#### Tecnologias do Back-end

- Python.
- FastAPI.
- SQLAlchemy.
- Alembic.

---

### Fase 4 - Front-end

**Status:** Planejado

#### Tecnologias do Front-end

- React.
- TypeScript.
- Material UI.

---

### Fase 5 - Aplicativo Mobile

**Status:** Planejado

#### Tecnologia Mobile

- Flutter.

---

## Módulos do Sistema

---

## Módulo Financeiro

**Status:** Em Desenvolvimento

### Recursos do Módulo Financeiro

- Plano de Contas.
- Fluxo de Caixa.
- DRE.
- Balancete.
- Centro de Custos.
- Contas Bancárias.
- Conciliação Bancária.
- Contas a Pagar.
- Contas a Receber.
- Indicadores Financeiros.

---

## Módulo Fiscal

**Status:** Planejado

### Recursos do Módulo Fiscal

- Nota Fiscal de Serviço (NFS-e).
- Nota Fiscal Eletrônica (NF-e).
- Simples Nacional.
- SPED.
- Obrigações fiscais.

---

## Módulo Comercial

**Status:** Planejado

### Recursos do Módulo Comercial

- CRM.
- Clientes.
- Fornecedores.
- Contratos.
- Propostas comerciais.
- Gestão de vendas.

---

## Módulo Turismo

**Status:** Planejado

### Recursos do Módulo Turismo

- Pacotes turísticos.
- Hotéis.
- Voos.
- Passeios.
- Reservas.
- Operações turísticas.

---

## Módulo WMA Bike Tour

**Status:** Planejado

### Recursos do WMA Bike Tour

- Eventos.
- Inscrições.
- Trilhas.
- Participantes.
- Gestão operacional.

---

## Módulo Administrativo

**Status:** Planejado

### Recursos Administrativos

- Usuários.
- Perfis.
- Permissões.
- Configurações.
- Parâmetros do sistema.

---

## Dashboard Executivo

**Status:** Planejado

### Recursos Executivos

- Indicadores.
- KPIs.
- Financeiro.
- Comercial.
- Turismo.
- Gestão estratégica.

---

## Banco de Dados Corporativo

**Status:** Em Desenvolvimento

### Meta do Banco de Dados

Criar um banco de dados corporativo certificado, seguro, escalável e preparado para auditoria.

### Componentes do Banco de Dados

- Framework DBA.
- Auditoria técnica.
- Score de qualidade.
- Health Check.
- Governança.
- Plano de correção.
- Certificação da base.

---

## Business Intelligence

**Status:** Planejado

### Recursos de Business Intelligence

- Power BI.
- Dashboards executivos.
- Indicadores estratégicos.
- Data Warehouse.
- Análise de dados.

---

## Segurança

**Status:** Em Desenvolvimento

### Recursos de Segurança

- JWT.
- Controle de acesso.
- Auditoria.
- Logs.
- Gestão de permissões.
- LGPD.

---

## Qualidade de Software

### Meta

Alcançar cobertura superior a 95% nos testes automatizados.

### Componentes de Qualidade

- Testes unitários.
- Testes de integração.
- Testes SQL.
- Testes de performance.
- Validação contínua.

---

## DevOps

**Status:** Planejado

### Recursos de DevOps

- Docker.
- Docker Compose.
- GitHub Actions.
- CI/CD.
- Automação de deploy.

---

## Documentação Corporativa

**Status:** Em Desenvolvimento

### Documentos do Projeto

- README.md.
- CHANGELOG.md.
- ROADMAP.md.
- CONTRIBUTING.md.
- CODE_OF_CONDUCT.md.
- ARCHITECTURE.md.
- DATABASE_GUIDE.md.
- DATA_DICTIONARY.md.
- API.md.
- DEPLOYMENT.md.
- GOVERNANCE.md.

---

## Meta Final

Construir um ERP corporativo completo para a **WMA Travel Ltda.**, com:

- Arquitetura modular.
- Banco de dados certificado.
- Código de alta qualidade.
- Segurança empresarial.
- Documentação completa.
- Governança de dados.
- Capacidade de evolução contínua.
- Preparação para ambiente de produção.

---

**Copyright © 2026 WMA Travel Ltda.**

**Todos os direitos reservados.**
