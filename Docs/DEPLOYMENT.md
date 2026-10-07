# WMA Travel ERP — Processo de Implantação

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Planejamento de Implantação
> **Versão:** 1.2.0
> **Data:** 07/10/2026
> **Status:** PLANEJADA

Não há implantação produtiva certificada neste documento. O Backend/API até a 2.7 está integrado à `main`;
a 2.8 está em preparação, com homologação do site e contratos externos pendentes. CI aprovado não comprova deploy.
Consulte o [estado corrente](PROJECT_DOCUMENTATION.md) e o [plano da 2.8](WEBSITE_INTEGRATION_PREPARATION.md).

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
- Python 3.13+ e dependências do Backend conforme seu README;
- Bash e `psql` para o instalador certificado; Docker é usado no CI, mas não há Compose de deploy versionado;
- pgAdmin 4 (para backup/restore de staging);
- Acesso ao repositório com permissões adequadas;
- Variáveis de ambiente configuradas (ver seção 8).

---

## 4. Processo de Instalação Inicial

Para reconstrução e testes, usar banco local descartável explicitamente identificado:

1. Preparar PostgreSQL e confirmar o banco de destino antes de qualquer restauração;
2. Reconstruir a Fase 1 pelo [instalador certificado](../Database/README.md), incluindo F1-FIN;
3. Configurar o Backend e aplicar as revisions Alembic conforme [Migrations](MIGRATIONS.md);
4. Verificar o head aplicado, a estrutura esperada e as validações do escopo;
5. Iniciar a API conforme o [README do Backend](../Backend/README.md);
6. Validar os health checks da API e a conectividade com o banco.

Este fluxo local não autoriza restauração em produção. A implantação produtiva exige plano próprio de
infraestrutura, secrets, backup, recuperação e aceite operacional; não existe comando Compose certificado.

---

## 5. Ordem de Execução dos Scripts SQL

O instalador `Database/install.sh` coordena o dump histórico e os scripts F1-FIN.04 a F1-FIN.11;
`--with-validation` executa as validações certificadas. Não reaplicar manualmente scripts históricos
incorporados à baseline nem reconstruir scripts ausentes para simular uma migration antiga.

Depois da fundação, as evoluções da Fase 2 seguem a cadeia Alembic em `Backend/migrations/versions/`.
O head da entrega 2.7 é `202609170300`. O estado de cada banco deve ser consultado separadamente.
A consolidação de schemas não faz parte deste procedimento e exige decisão explícita de arquitetura.

---

## 6. Pipeline de CI/CD

Implementado via GitHub Actions:

- Backend CI: dependências, lint, formatação, tipos, testes, OpenAPI, Alembic e PostgreSQL descartável;
- Documentation CI: Markdownlint, CSpell e whitespace;
- Secret Scan: verificação de segredos.

Os três checks são exigidos antes da integração e executados após o merge em `main`.
Build de imagem, deploy em staging/produção e bloqueio de deploy por ICB não estão implementados nos
workflows versionados; permanecem decisões futuras do plano de implantação.

---

## 7. Estratégia de Deployment

A estratégia produtiva ainda precisa ser definida e validada no ambiente escolhido. Atualização gradual,
rollback e verificações de saúde são requisitos a avaliar; não há execução produtiva certificada neste guia.

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
| `WMA_TOKEN_SIGNING_KEY` | Segredo de assinatura de access tokens, com no mínimo 32 caracteres |
| `WMA_TOKEN_ISSUER` | Emissor esperado dos tokens |
| `WMA_TOKEN_AUDIENCE` | Audiência esperada da API |
| `WMA_ACCESS_TOKEN_TTL_MINUTES` | Validade dos access tokens |
| `WMA_REFRESH_TOKEN_TTL_DAYS` | Validade das sessões de renovação |
| `WMA_ENVIRONMENT` | Identifica o ambiente (`development`, `test` ou `production`) |
| `WMA_LOG_LEVEL` | Nível mínimo do logging técnico |

> Nenhum valor real de segredo deve constar neste documento — ver `SECURITY.md`, seção 9.

---

## 9. Rollback e Contingência

- Avaliar o `downgrade()` de cada revision; reversão não é presumida segura e exige teste em banco descartável;
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
| Última atualização | 07/10/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
