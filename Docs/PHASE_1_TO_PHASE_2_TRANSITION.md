# WMA Travel ERP â€” TransiÃ§Ã£o da Fase 1 para a Fase 2

## Marco Formal de GovernanÃ§a

**Data:** 17/08/2026  
**Fase encerrada:** Fase 1 â€” FundaÃ§Ã£o e Banco de Dados  
**PrÃ³xima fase:** Fase 2 â€” Backend e API  
**PostgreSQL:** 18.4  
**Baseline certificada:** `d63800e`

---

## 1. Objetivo

Este documento estabelece o marco formal de transiÃ§Ã£o entre a Fase 1 e a
Fase 2 do WMA Travel ERP.

A partir deste ponto, a fundaÃ§Ã£o do banco de dados deixa de ser tratada como
estrutura em construÃ§Ã£o e passa a ser tratada como baseline certificada.

## 2. SituaÃ§Ã£o da Fase 1

A Fase 1 foi submetida aos processos de:

- modelagem;
- padronizaÃ§Ã£o;
- auditoria;
- inventÃ¡rio;
- reconstruÃ§Ã£o;
- comparaÃ§Ã£o estrutural;
- validaÃ§Ã£o de reprodutibilidade;
- certificaÃ§Ã£o.

**Status da Fase 1: CONCLUÃDA E CERTIFICADA**

## 3. Baseline

A baseline certificada encontra-se associada ao seguinte marco Git:

`d63800e`

As certificaÃ§Ãµes posteriores ao commit documentam formalmente o encerramento
da fase sem redefinir silenciosamente a baseline tÃ©cnica jÃ¡ validada.

## 4. Regra de governanÃ§a

A partir da Fase 2, alteraÃ§Ãµes estruturais persistentes no banco de dados nÃ£o
devem ser realizadas diretamente sobre a baseline histÃ³rica.

As alteraÃ§Ãµes deverÃ£o ser introduzidas atravÃ©s de migrations versionadas e
rastreÃ¡veis.

## 5. Fluxo de alteraÃ§Ã£o estrutural

O fluxo padrÃ£o passa a ser:

``text
Necessidade de alteraÃ§Ã£o
        |
        v
Migration SQL versionada
        |
        v
ValidaÃ§Ã£o em desenvolvimento
        |
        v
AnÃ¡lise de impacto
        |
        v
Auditoria
        |
        v
Commit Git
        |
        v
AplicaÃ§Ã£o controlada
        |
        v
ValidaÃ§Ã£o pÃ³s-aplicaÃ§Ã£o
``

## 6. Requisitos mÃ­nimos de migration

Cada migration deverÃ¡ possuir, quando aplicÃ¡vel:

- identificaÃ§Ã£o Ãºnica;
- descriÃ§Ã£o da alteraÃ§Ã£o;
- justificativa;
- objetos afetados;
- SQL versionado;
- validaÃ§Ã£o prÃ©via;
- anÃ¡lise de dependÃªncias;
- estratÃ©gia de rollback quando tecnicamente aplicÃ¡vel;
- evidÃªncia de execuÃ§Ã£o;
- validaÃ§Ã£o pÃ³s-aplicaÃ§Ã£o.

## 7. ProteÃ§Ã£o da baseline

A baseline certificada deverÃ¡ permanecer disponÃ­vel para:

- auditoria;
- reconstruÃ§Ã£o;
- comparaÃ§Ã£o;
- investigaÃ§Ã£o de regressÃµes;
- recuperaÃ§Ã£o histÃ³rica;
- validaÃ§Ã£o de migrations;
- rastreabilidade.

NÃ£o deverÃ¡ haver alteraÃ§Ã£o silenciosa de arquivos utilizados como referÃªncia
histÃ³rica da certificaÃ§Ã£o.

## 8. Fase 2

A Fase 2 poderÃ¡ utilizar a baseline certificada como fundaÃ§Ã£o para o
desenvolvimento das camadas superiores do sistema.

O escopo inicial poderÃ¡ compreender:

- arquitetura do backend;
- configuraÃ§Ã£o da aplicaÃ§Ã£o;
- conexÃ£o com PostgreSQL;
- camada de persistÃªncia;
- models;
- schemas de aplicaÃ§Ã£o;
- services;
- API;
- autenticaÃ§Ã£o;
- autorizaÃ§Ã£o;
- validaÃ§Ãµes;
- testes;
- documentaÃ§Ã£o tÃ©cnica da API.

## 9. Gate de transiÃ§Ã£o

Os seguintes critÃ©rios encontram-se estabelecidos para autorizaÃ§Ã£o da Fase 2:

- baseline certificada;
- estrutura auditada;
- reconstruÃ§Ã£o validada;
- reprodutibilidade aprovada;
- divergÃªncias estruturais crÃ­ticas iguais a zero;
- certificaÃ§Ãµes finais formalizadas;
- governanÃ§a de migrations definida.

**GATE FASE 1 -> FASE 2: APROVADO**

## 10. DecisÃ£o

A Fase 1 encontra-se formalmente encerrada.

O projeto estÃ¡ autorizado a prosseguir para a Fase 2, mantendo a baseline
certificada como referÃªncia histÃ³rica e utilizando migrations versionadas
para futuras alteraÃ§Ãµes estruturais.

---

**WMA Travel ERP**  
**TransiÃ§Ã£o Fase 1 â†’ Fase 2**  
**17/08/2026**
