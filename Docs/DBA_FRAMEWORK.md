# Framework DBA — WMA Travel ERP

**Versão do Documento:** 1.0.0
**Última Atualização:** 18/08/2026
**Status:** Estrutura Certificada; Automação Operacional Planejada para a Fase 2
**Schema de Referência:** `auditoria`

---

## Índice

- [Framework DBA — WMA Travel ERP](#framework-dba--wma-travel-erp)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Visão Geral do Framework](#2-visão-geral-do-framework)
  - [3. Modelo de Dados](#3-modelo-de-dados)
  - [4. Ciclo de Execução de Auditoria](#4-ciclo-de-execução-de-auditoria)
  - [5. Índice de Conformidade do Banco (ICB)](#5-índice-de-conformidade-do-banco-icb)
  - [6. Categorias de Regras](#6-categorias-de-regras)
  - [7. Níveis de Maturidade](#7-níveis-de-maturidade)
  - [8. Correção Automática vs. Manual](#8-correção-automática-vs-manual)
  - [9. Health Check](#9-health-check)
  - [10. Catálogo Técnico](#10-catálogo-técnico)
  - [11. Integração com CI/CD](#11-integração-com-cicd)
  - [12. Estado Atual da Auditoria (Achados Confirmados)](#12-estado-atual-da-auditoria-achados-confirmados)
  - [13. Procedures e Functions do Framework](#13-procedures-e-functions-do-framework)
  - [14. Glossário](#14-glossário)
  - [15. Documentos Relacionados](#15-documentos-relacionados)

---

## 1. Objetivo

Este documento descreve o **Framework DBA** do WMA Travel ERP: a estrutura responsável por auditar,
pontuar e acompanhar a conformidade técnica do banco de dados de forma contínua e rastreável.

O framework existe fisicamente no banco como o schema `auditoria`, com 16 tabelas dedicadas ao
registro de regras, execuções, resultados, pontuação e recomendações de correção.

---

## 2. Visão Geral do Framework

O Framework DBA segue um ciclo fechado:

```text
Regra → Execução → Resultado → Score → Recomendação → Correção → Nova Execução
```

Cada rodada de auditoria avalia o banco contra um conjunto de regras cadastradas, produz resultados
por item avaliado, calcula uma pontuação agregada (o ICB) e gera recomendações acionáveis quando a
regra não é atendida.

---

## 3. Modelo de Dados

O schema `auditoria` possui 34 tabelas no estado certificado. As tabelas centrais do framework incluem:

| Tabela | Finalidade |
| ------------------------- | ------------------------------------------------------------------ |
| `core` | Registro central/âncora do framework |
| `configuracao` | Parâmetros globais de execução da auditoria |
| `categoria` | Agrupamento temático das regras (estrutura, segurança, performance) |
| `regra` | Definição de cada regra de conformidade e seu peso |
| `executor` | Identifica quem/o que disparou uma execução |
| `execucao` | Registro de cada rodada de auditoria disparada |
| `item` | Itens avaliados dentro de uma execução |
| `resultado` | Resultado individual de cada item avaliado |
| `score` | Pontuação agregada calculada por execução |
| `recomendacao` | Sugestões de correção geradas a partir de resultados não conformes |
| `log` | Log operacional do framework |
| `log_correcao` | Log específico de execuções de scripts de correção |
| `catalogo_schema` | Catálogo técnico dos schemas do banco |
| `catalogo_tabela` | Catálogo técnico das tabelas do banco |
| `catalogo_coluna` | Catálogo técnico das colunas do banco |
| `script` | Registro de scripts de correção/migração vinculados ao framework |

> **Status certificado:** as 34 tabelas do schema `auditoria` possuem chave primária. As tabelas de regras,
> execuções, resultados e score estão estruturalmente disponíveis, mas ainda não possuem carga operacional.

---

## 4. Ciclo de Execução de Auditoria

1. Uma `execucao` é aberta via `sp_iniciar_execucao`, associada a um `executor`.
2. As `regra` ativas (por `categoria`) são avaliadas contra o banco real.
3. Cada avaliação gera um `item` e um `resultado` (conforme / não conforme).
4. Resultados não conformes podem gerar uma `recomendacao`.
5. O `score` da execução é calculado a partir dos resultados ponderados pelo peso da regra.
6. A execução é fechada via `sp_finalizar_execucao`.
7. Correções aplicadas (manuais ou automatizadas) são registradas em `log_correcao`.

---

## 5. Índice de Conformidade do Banco (ICB)

O ICB é a métrica agregada de saúde estrutural do banco, calculada por `sp_recalcular_score` e
classificada por `fn_classificacao_score`.

Fórmula conceitual:

```text
ICB = Σ (resultado_regra × peso_regra) / Σ (peso_regra)
```

O resultado é expresso em uma escala de 0 a 100 e associado a uma faixa de classificação (ver
seção 7).

---

## 6. Categorias de Regras

| Categoria | Exemplos de Regra |
| -------------- | -------------------------------------------------------------- |
| Estrutura | Toda tabela possui chave primária |
| Auditoria | Colunas de controle (`created_at`, `updated_at`) presentes |
| Integridade | Toda FK possui índice correspondente |
| Automação | Triggers de auditoria/atualização instanciados |
| Documentação | Tabela possui comentário (`COMMENT ON TABLE`) |
| Segurança | Privilégios mínimos aplicados por schema |
| Performance | Índices em colunas de busca frequente |

---

## 7. Níveis de Maturidade

| Nível | Faixa ICB | Descrição |
| -------------- | --------- | -------------------------------------------- |
| 1 — Crítico | 0–39 | Estrutura básica ausente ou inconsistente |
| 2 — Inicial | 40–59 | Estrutura presente, controles incompletos |
| 3 — Gerenciado | 60–74 | Controles presentes, automação parcial |
| 4 — Avançado | 75–89 | Automação e auditoria consistentes |
| 5 — Otimizado | 90–100 | Conformidade plena e monitorada continuamente |

---

## 8. Correção Automática vs. Manual

Nem toda não conformidade é corrigida automaticamente. O framework distingue:

- **Correção automática**: aplicável via script padronizado, registrado em `auditoria.script` e
  executado com log em `auditoria.log_correcao`, sempre dentro de uma transação `BEGIN`/`COMMIT`
  com bloco de rollback comentado.
- **Correção manual**: exige revisão humana antes da aplicação — típico de tabelas transacionais
  sensíveis (ex.: `lancamento_parcela`, `conciliacao_bancaria`).

---

## 9. Health Check

O health check (`fn_health_check`) é uma verificação rápida e não destrutiva do estado geral do
banco, usada para monitoramento contínuo entre execuções completas de auditoria. Deve cobrir, no
mínimo:

- Conectividade e disponibilidade dos schemas;
- Presença de triggers esperados;
- Presença de chaves primárias em todas as tabelas;
- Schemas vazios não previstos.

---

## 10. Catálogo Técnico

As tabelas `catalogo_schema`, `catalogo_tabela` e `catalogo_coluna` mantêm um espelho estruturado
dos metadados do banco (equivalente a uma versão curada de `information_schema`), usado como fonte
para geração automatizada de partes do `DATA_DICTIONARY.md`.

---

## 11. Integração com CI/CD

O pipeline de CI/CD (ver `DEPLOYMENT.md`) deve, no mínimo:

1. Rodar `sp_auditoria_estrutura` contra o banco de staging a cada alteração de schema;
2. Bloquear o merge se o ICB cair abaixo do limite mínimo configurado em `auditoria.configuracao`;
3. Publicar o `score` resultante como artefato do pipeline.

---

## 12. Estado Atual da Auditoria (Achados Confirmados)

Levantamento revalidado diretamente no banco `wma_travel` em 18/08/2026:

| Achado | Situação |
| ---------------------------------------------------- | ------------------------------- |
| Tabelas totais no banco | 220 |
| Triggers de usuário instanciados | 138 |
| Triggers de usuário desabilitados | 0 |
| Funções obrigatórias de trigger | 2 de 2 presentes |
| Chaves primárias no schema `auditoria` | 34 de 34 tabelas |
| Constraints não validadas | 0 |
| Schemas reservados vazios (`logs`, `seguranca`, `util`) | 3, por decisão arquitetural documentada |
| Regras/execuções/resultados/scores ICB | 0, ativação operacional planejada para a Fase 2 |

Os antigos bloqueantes estruturais foram corrigidos. A carga de regras e a execução contínua do ICB pertencem à
automação operacional da Fase 2 e não devem ser apresentadas como certificação já executada.

---

## 13. Procedures e Functions do Framework

| Objeto | Tipo | Finalidade |
| -------------------------- | --------- | ----------------------------------------- |
| `sp_iniciar_execucao` | Procedure | Abre uma nova execução de auditoria |
| `sp_auditoria_estrutura` | Procedure | Executa a auditoria estrutural completa |
| `sp_executar_governanca` | Procedure | Executa validações de governança |
| `fn_health_check` | Function | Verificação rápida de saúde do banco |
| `fn_calcular_score` | Function | Calcula o score de uma execução |
| `fn_classificacao_score` | Function | Classifica o score em nível de maturidade |
| `sp_recalcular_score` | Procedure | Recalcula o ICB agregado |
| `sp_finalizar_execucao` | Procedure | Encerra uma execução de auditoria |

---

## 14. Glossário

| Termo | Significado |
| ----- | ----------------------------------- |
| DBA | Administrador de Banco de Dados |
| ICB | Índice de Conformidade do Banco |
| PK | Chave Primária |
| FK | Chave Estrangeira |
| CI/CD | Integração e Entrega Contínua |

---

## 15. Documentos Relacionados

- DATABASE_GUIDE.md
- DATA_DICTIONARY.md
- GOVERNANCE.md
- SECURITY.md

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
