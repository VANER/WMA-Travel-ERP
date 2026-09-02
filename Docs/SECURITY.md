# WMA Travel ERP — Política de Segurança

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Norma de Segurança
> **Versão:** 1.2.0
> **Data:** 01/09/2026
> **Status:** VIGENTE

---

## Índice

- [WMA Travel ERP — Política de Segurança](#wma-travel-erp--política-de-segurança)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Escopo](#2-escopo)
  - [3. Princípios de Segurança](#3-princípios-de-segurança)
  - [4. Criptografia](#4-criptografia)
  - [5. Autenticação de Banco de Dados](#5-autenticação-de-banco-de-dados)
  - [6. Autenticação de Aplicação](#6-autenticação-de-aplicação)
  - [7. Autorização (RBAC)](#7-autorização-rbac)
  - [8. LGPD e Proteção de Dados Pessoais](#8-lgpd-e-proteção-de-dados-pessoais)
  - [9. Gestão de Segredos e Credenciais](#9-gestão-de-segredos-e-credenciais)
  - [10. Logs de Auditoria e Retenção](#10-logs-de-auditoria-e-retenção)
  - [11. Resposta a Incidentes](#11-resposta-a-incidentes)
  - [12. Checklist de Segurança](#12-checklist-de-segurança)
  - [13. Glossário](#13-glossário)
  - [14. Documentos Relacionados](#14-documentos-relacionados)

---

## 1. Objetivo

Este documento define as diretrizes de segurança da informação aplicadas ao **WMA Travel ERP**,
cobrindo banco de dados, backend, autenticação e conformidade com a legislação brasileira de
proteção de dados.

---

## 2. Escopo

Aplica-se a todos os componentes da plataforma: banco de dados PostgreSQL, API FastAPI, frontend
React, aplicativo Flutter e pipelines de CI/CD.

---

## 3. Princípios de Segurança

- Privilégio mínimo em todos os níveis de acesso;
- Defesa em profundidade (múltiplas camadas de controle);
- Segregação de ambientes (desenvolvimento, staging, produção);
- Nenhuma credencial em texto plano em repositório de código;
- Auditoria contínua de acessos e alterações estruturais.

---

## 4. Criptografia

| Camada | Padrão |
| ------------------- | ------------------------------------- |
| Dados em repouso | AES-256 |
| Dados em trânsito | TLS 1.3 |
| Autenticação de banco | SCRAM-SHA-256 |
| Senhas de usuário | Argon2id com salt aleatório |

---

## 5. Autenticação de Banco de Dados

O PostgreSQL deve ser configurado para exigir `SCRAM-SHA-256` como método de autenticação
(`pg_hba.conf`), substituindo métodos legados como `md5`. Conexões externas devem ocorrer
exclusivamente via TLS.

---

## 6. Autenticação de Aplicação

A API utiliza **JWT** (JSON Web Token) para autenticação de sessão, com:

- Token de acesso de curta duração;
- Refresh Token de longa duração, armazenado de forma segura;
- Revogação de sessão em caso de comprometimento suspeito.

A política de hash das credenciais humanas é definida em `CREDENTIAL_HASHING.md`. Implementação de tokens e
sessões humanas, incluindo rotação e revogação, é definida em `TOKENS_AND_SESSIONS.md`.

---

## 7. Autorização (RBAC)

O controle de acesso segue o modelo **RBAC** (Role-Based Access Control):

```text
Usuário → Papel(is) → Permissões → Recurso
```

Cada módulo (Financeiro, Comercial, Fiscal, Turismo, Bike Tour, Administrativo) define seus
próprios papéis, com permissões granulares de leitura, escrita e exclusão.

---

## 8. LGPD e Proteção de Dados Pessoais

O WMA Travel ERP trata dados pessoais de clientes, fornecedores e participantes de eventos
(ex.: Bike Tour), exigindo aderência à Lei Geral de Proteção de Dados (LGPD):

- Identificação clara da base legal para cada tratamento de dado pessoal;
- Direito de acesso, correção e exclusão pelo titular dos dados;
- Minimização de dados coletados ao estritamente necessário;
- Registro de consentimento quando aplicável;
- Anonimização ou pseudonimização em bases de BI/Data Warehouse (`schema dw`) sempre que possível.

---

## 9. Gestão de Segredos e Credenciais

- Nenhuma credencial de banco, API key ou secret deve ser versionada em Git;
- Variáveis sensíveis devem ser injetadas via variáveis de ambiente ou cofre de segredos;
- Rotação periódica de credenciais de serviço.

---

## 10. Logs de Auditoria e Retenção

O schema `auditoria` (ver `DBA_FRAMEWORK.md`) registra alterações estruturais. Para dados de
aplicação, o schema `logs` — atualmente vazio e reservado — deve concentrar logs de acesso e
operação, com política de retenção mínima definida antes de sua efetiva utilização.

---

## 11. Resposta a Incidentes

1. Identificação e contenção do incidente;
2. Avaliação de impacto (dados afetados, usuários afetados);
3. Comunicação às partes interessadas, respeitando prazos legais da LGPD quando aplicável;
4. Correção da causa raiz;
5. Registro do incidente e lições aprendidas.

---

## 12. Checklist de Segurança

- [ ] TLS habilitado em todas as conexões externas
- [ ] Autenticação de banco em SCRAM-SHA-256
- [ ] Nenhuma credencial versionada em código
- [ ] RBAC aplicado em todos os módulos
- [ ] Base legal LGPD documentada por tipo de dado pessoal
- [ ] Logs de auditoria ativos e monitorados

---

## 13. Glossário

| Termo | Significado |
| ----- | -------------------------------------- |
| RBAC | Role-Based Access Control |
| JWT | JSON Web Token |
| LGPD | Lei Geral de Proteção de Dados |
| TLS | Transport Layer Security |

---

## 14. Documentos Relacionados

- GOVERNANCE.md
- DBA_FRAMEWORK.md
- ARCHITECTURE.md

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.2.0 |
| Status | VIGENTE |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
