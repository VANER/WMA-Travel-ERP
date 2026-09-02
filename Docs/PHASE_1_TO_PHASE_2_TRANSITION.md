# WMA Travel ERP — Transição da Fase 1 para a Fase 2

## Marco Formal de Governança

**Data:** 17/08/2026
**Fase encerrada:** Fase 1 — Fundação e Banco de Dados
**Próxima fase:** Fase 2 — Backend, API e Integrações
**PostgreSQL:** 18.4
**Baseline estrutural 10.12.2:** `d63800e`
**Implementação financeira F1-FIN:** `33fe492`
**Consolidação anterior ao gate final:** `980af60`
**Marco definitivo da Fase 1:** tag `phase-1-final-2026-08-18`

---

## 1. Objetivo

Este documento estabelece o marco formal de transição entre a Fase 1 e a
Fase 2 do WMA Travel ERP.

A partir deste ponto, a fundação do banco de dados deixa de ser tratada como
estrutura em construção e passa a ser tratada como baseline certificada.

## 2. Situação da Fase 1

A Fase 1 foi submetida aos processos de:

- modelagem;
- padronização;
- auditoria;
- inventário;
- reconstrução;
- comparação estrutural;
- validação de reprodutibilidade;
- certificação.

**Status da Fase 1: CONCLUÍDA E CERTIFICADA**

## 3. Marcos certificados

A baseline certificada encontra-se associada ao seguinte marco Git:

`d63800e`

As certificações posteriores ao commit documentam formalmente o encerramento
da fase sem redefinir silenciosamente a baseline técnica já validada.

Após a baseline 10.12.2, o domínio Financeiro passou pela sequência controlada
F1-FIN.01 a F1-FIN.13. A execução final da F1-FIN.13 confirmou zero critérios
bloqueantes e zero resíduos de teste, conforme
`Database/certification/F1_FIN_13_CERTIFICACAO_FINAL.md`.

O encerramento completo da fase é identificado pela tag
`phase-1-final-2026-08-18`. A tag distingue o marco final do projeto da baseline
histórica `d63800e`, que permanece válida como referência da ETAPA 10.12.2.

## 4. Regra de governança

A partir da Fase 2, alterações estruturais persistentes no banco de dados não
devem ser realizadas diretamente sobre a baseline histórica.

As alterações deverão ser introduzidas através de migrations versionadas e
rastreáveis.

## 5. Fluxo de alteração estrutural

O fluxo padrão passa a ser:

```text
Necessidade de alteração
        |
        v
Migration SQL versionada
        |
        v
Validação em desenvolvimento
        |
        v
Análise de impacto
        |
        v
Auditoria
        |
        v
Commit Git
        |
        v
Aplicação controlada
        |
        v
Validação pós-aplicação
```

## 6. Requisitos mínimos de migration

Cada migration deverá possuir, quando aplicável:

- identificação única;
- descrição da alteração;
- justificativa;
- objetos afetados;
- SQL versionado;
- validação prévia;
- análise de dependências;
- estratégia de rollback quando tecnicamente aplicável;
- evidência de execução;
- validação pós-aplicação.

## 7. Proteção da baseline

A baseline certificada deverá permanecer disponível para:

- auditoria;
- reconstrução;
- comparação;
- investigação de regressões;
- recuperação histórica;
- validação de migrations;
- rastreabilidade.

Não deverá haver alteração silenciosa de arquivos utilizados como referência
histórica da certificação.

## 8. Fase 2

A Fase 2 poderá utilizar a baseline certificada como fundação para o
desenvolvimento das camadas superiores do sistema.

O escopo inicial poderá compreender:

- arquitetura do backend;
- configuração da aplicação;
- conexão com PostgreSQL;
- camada de persistência;
- models;
- schemas de aplicação;
- services;
- API;
- autenticação;
- autorização;
- validações;
- testes;
- documentação técnica da API.

## 9. Gate de transição

Os seguintes critérios encontram-se estabelecidos para autorização da Fase 2:

- baseline certificada;
- estrutura auditada;
- reconstrução validada;
- reprodutibilidade aprovada;
- divergências estruturais críticas iguais a zero;
- certificações finais formalizadas;
- governança de migrations definida.

**GATE FASE 1 -> FASE 2: APROVADO**

## 10. Decisão

A Fase 1 encontra-se formalmente encerrada.

O projeto está autorizado a prosseguir para a Fase 2, mantendo a baseline
certificada como referência histórica e utilizando migrations versionadas
para futuras alterações estruturais.

---

**WMA Travel ERP**
**Transição Fase 1 → Fase 2**
**17/08/2026**
