# WMA Travel ERP — Processo de Implantação

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Planejamento de Implantação
> **Versão:** 1.2.0
> **Data:** 01/09/2026
> **Status:** PLANEJADA

A implantação permanece não iniciada.

---

## Índice

- [WMA Travel ERP — Processo de Implantação](#wma-travel-erp--processo-de-implantação)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Ambientes](#2-ambientes)
  - [3. Pré-requisitos](#3-pré-requisitos)
  - [4. Processo de Instalação Inicial](#4-processo-de-instalação-inicial)
  - [5. Ordem de Execução dos Scripts SQL](#5-ordem-de-execução-dos-scripts-sql)
  - [6. Pipeline de CI/CD](#6-pipeline-de-cicd)
  - [7. Estratégia de Deployment](#7-estratégia-de-deployment)
  - [8. Variáveis de Ambiente](#8-variáveis-de-ambiente)
  - [9. Rollback e Contingência](#9-rollback-e-contingência)
  - [10. Checklist Pré-Deploy](#10-checklist-pré-deploy)
  - [11. Checklist Pós-Deploy](#11-checklist-pós-deploy)
  - [12. Glossário](#12-glossário)
  - [13. Documentos Relacionados](#13-documentos-relacionados)

---

## 1. Objetivo

Este documento descreve o processo de implantação do **WMA Travel ERP**, cobrindo instalação
inicial, execução segura de scripts de banco de dados e o fluxo de entrega contínua.

---

## 2. Ambientes

| Ambiente | Finalidade |
| ------------ | -------------------------------------------------------- |
| Desenvolvimento | Trabalho ativo dos times, dados fictícios |
| Staging (`wma_staging`) | Validação de scripts e releases antes de produção |
| Produção | Ambiente final, dados reais da operação |

---

## 3. Pré-requisitos

- PostgreSQL (versão compatível com os scripts em `WmaTravelERP.sql`);
- Docker e Docker Compose;
- pgAdmin 4 (para backup/restore de staging);
- Acesso ao repositório com permissões adequadas;
- Variáveis de ambiente configuradas (ver seção 8).

---

## 4. Processo de Instalação Inicial

1. Provisionar instância PostgreSQL;
2. Restaurar o schema base a partir de `WmaTravelERP.sql`;
3. Validar criação dos 5 schemas populados (`public`, `financeiro`, `auditoria`, `dw`, `config`) e
   dos 3 schemas reservados (`logs`, `seguranca`, `util`);
4. Executar rotina de health check (`fn_health_check`);
5. Subir os serviços de backend via Docker Compose;
6. Validar conectividade da API com o banco.

---

## 5. Ordem de Execução dos Scripts SQL

Scripts de migração devem ser executados **exclusivamente após validação em `wma_staging`**, na
seguinte ordem:

1. `WmaTravelERP.sql` — schema base completo;
2. `01_normalizar_3fn_enderecos.sql` — normalização 3FN de endereços;
3. `02_consolidar_financeiro_public.sql` — consolidação de tabelas duplicadas
   (**mantido em espera**: só deve ser executado após estabilização do módulo financeiro em
   desenvolvimento ativo, para evitar quebra de FKs de `lancamento`, `pagamento` e
   `movimentacao_bancaria`).

Cada script segue o padrão `BEGIN`/`COMMIT`, registra sua execução em `auditoria.log_correcao` e
inclui bloco de rollback comentado.

---

## 6. Pipeline de CI/CD

Implementado via **GitHub Actions**, cobrindo minimamente:

```text
Lint (markdownlint / cspell) → Testes → Build da Imagem Docker →
Execução em Staging → Auditoria Estrutural (ICB) → Deploy Condicional
```

O deploy para produção é bloqueado automaticamente se o ICB calculado em staging estiver abaixo
do limite mínimo definido em `auditoria.configuracao` (ver `DBA_FRAMEWORK.md`).

---

## 7. Estratégia de Deployment

Recomenda-se **rolling deployment**: substituição gradual das instâncias de backend, mantendo
disponibilidade durante a atualização, com verificação de saúde (`fn_health_check`) entre etapas.

---

## 8. Variáveis de Ambiente

| Variável | Finalidade |
| -------------------- | ----------------------------------------- |
| `WMA_DATABASE_URL` | String de conexão `postgresql+psycopg://` com o PostgreSQL |
| `WMA_DATABASE_POOL_SIZE` | Quantidade de conexões persistentes por processo |
| `WMA_DATABASE_MAX_OVERFLOW` | Limite de conexões temporárias adicionais |
| `WMA_DATABASE_POOL_TIMEOUT` | Tempo máximo de espera por conexão disponível |
| `WMA_DATABASE_POOL_RECYCLE` | Intervalo de renovação preventiva das conexões |
| `WMA_DATABASE_CONNECT_TIMEOUT` | Tempo máximo por tentativa de conexão PostgreSQL |
| `JWT_SECRET` | Chave de assinatura dos tokens JWT |
| `JWT_REFRESH_SECRET` | Chave de assinatura dos refresh tokens |
| `WMA_ENVIRONMENT` | Identifica o ambiente (`development`, `test` ou `production`) |
| `WMA_LOG_LEVEL` | Nível mínimo do logging técnico |

> Nenhum valor real de segredo deve constar neste documento — ver `SECURITY.md`, seção 9.

---

## 9. Rollback e Contingência

- Todo script de migração inclui bloco de rollback comentado, pronto para uso;
- Backups completos de produção devem ser realizados antes de qualquer execução estrutural;
- Em caso de falha pós-deploy, o rollback prioriza restaurar o backup mais recente validado.

---

## 10. Checklist Pré-Deploy

- [ ] Script testado em `wma_staging`
- [ ] Backup de produção realizado
- [ ] ICB de staging dentro do limite mínimo
- [ ] Documentação (`CHANGELOG.md`) atualizada

---

## 11. Checklist Pós-Deploy

- [ ] Health check executado com sucesso
- [ ] Log de execução registrado em `auditoria.log_correcao`
- [ ] Monitoramento ativo por período de observação
- [ ] Comunicação de release enviada às partes interessadas

---

## 12. Glossário

| Termo | Significado |
| ----- | ----------------------------------- |
| CI/CD | Integração e Entrega Contínua |
| ICB | Índice de Conformidade do Banco |
| FK | Chave Estrangeira |

---

## 13. Documentos Relacionados

- GOVERNANCE.md
- SECURITY.md
- DBA_FRAMEWORK.md

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.2.0 |
| Status | PLANEJADA |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
