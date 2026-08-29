# Governança do Projeto — WMA Travel ERP

**Versão do Documento:** 1.1.0
**Última Atualização:** 29/08/2026
**Status:** VIGENTE — EVOLUÇÃO CONTROLADA

---

## Índice

- [Governança do Projeto — WMA Travel ERP](#governança-do-projeto--wma-travel-erp)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Escopo](#2-escopo)
  - [3. Papéis e Responsabilidades](#3-papéis-e-responsabilidades)
  - [4. Governança dos Schemas](#4-governança-dos-schemas)
  - [5. Processo de Mudança](#5-processo-de-mudança)
  - [6. Política de Versionamento](#6-política-de-versionamento)
  - [7. Ciclo de Vida de Scripts de Migração](#7-ciclo-de-vida-de-scripts-de-migração)
  - [8. Fluxo de Aprovação para Alterações Estruturais](#8-fluxo-de-aprovação-para-alterações-estruturais)
  - [9. Indicadores de Governança](#9-indicadores-de-governança)
  - [10. Auditoria e Rastreabilidade](#10-auditoria-e-rastreabilidade)
  - [11. Gestão de Não Conformidades](#11-gestão-de-não-conformidades)
  - [12. Glossário](#12-glossário)
  - [13. Documentos Relacionados](#13-documentos-relacionados)

---

## 1. Objetivo

Este documento define as regras de governança aplicadas ao desenvolvimento, manutenção e evolução
do **WMA Travel ERP**, garantindo que decisões técnicas e estruturais sejam tomadas de forma
rastreável, consistente e auditável.

---

## 2. Escopo

Esta governança se aplica a:

- Alterações de schema no banco de dados;
- Consolidação ou depreciação de tabelas;
- Criação de novos módulos;
- Alterações em documentação oficial;
- Execução de scripts de migração em qualquer ambiente.

---

## 3. Papéis e Responsabilidades

| Papel | Responsabilidade |
| -------------------- | -------------------------------------------------------------- |
| Data Owner | Decide sobre o significado e uso dos dados de seu domínio |
| DBA | Responsável técnico pela estrutura, integridade e performance |
| Data Steward | Garante qualidade e conformidade dos dados no dia a dia |
| Squad/Time de Módulo | Implementa funcionalidades respeitando os padrões definidos |
| Revisor de Governança | Aprova mudanças estruturais antes da execução em produção |

---

## 4. Governança dos Schemas

O schema `public` é a **fonte de verdade cadastral** do sistema: é referenciado por chaves
estrangeiras de módulos fiscais, corporativos e de integração. O schema `financeiro` contém, hoje,
tabelas majoritariamente autorreferenciadas, sem colunas de auditoria completas.

Regra de governança vigente:

- Toda consolidação entre `public` e `financeiro` deve preservar `public` como schema de origem;
- Nenhuma tabela pode ser removida enquanto houver FK ativa apontando para ela;
- Views não substituem tabelas como alvo de FK — scripts de consolidação devem considerar essa
  limitação do PostgreSQL antes de propor a troca de uma tabela por uma view.

---

## 5. Processo de Mudança

1. Abertura de uma solicitação de mudança (RFC interna), descrevendo motivo e impacto;
2. Análise de impacto em FKs, triggers, views e documentação dependente;
3. Validação em banco de staging (`wma_staging`);
4. Aprovação pelo Revisor de Governança;
5. Execução controlada, com log em `auditoria.log_correcao`;
6. Atualização obrigatória da documentação afetada (`CHANGELOG.md` no mínimo).

---

## 6. Política de Versionamento

O projeto segue **Versionamento Semântico** (`MAJOR.MINOR.PATCH`):

- `MAJOR`: mudança incompatível de schema ou API;
- `MINOR`: nova funcionalidade compatível com versões anteriores;
- `PATCH`: correção que não altera comportamento externo.

A versão vigente do projeto é mantida no arquivo `VERSION`, na raiz do repositório, como string
simples (exemplo: `0.1.0-dev`), e todo incremento deve ser refletido em `CHANGELOG.md`.

---

## 7. Ciclo de Vida de Scripts de Migração

Todo script de migração segue obrigatoriamente:

```text
Elaboração → Revisão → Teste em wma_staging → Aprovação → Execução em Produção → Registro
```

Nenhum script é executado diretamente em produção sem passar por `wma_staging` (criado via
backup/restore no pgAdmin 4) e sem revisão de impacto em FKs ativas.

---

## 8. Fluxo de Aprovação para Alterações Estruturais

| Etapa | Responsável | Critério de Aprovação |
| ----------------- | ---------------------- | ----------------------------------------- |
| Proposta | Squad/DBA | Script segue padrão `BEGIN`/`COMMIT` |
| Validação técnica | DBA | Testado em `wma_staging` sem erros |
| Validação de impacto | Revisor de Governança | Sem quebra de FK ativa |
| Aprovação final | Data Owner do domínio | Impacto de negócio compreendido e aceito |

---

## 9. Indicadores de Governança

A governança é monitorada em conjunto com o Framework DBA (`DBA_FRAMEWORK.md`), utilizando o
Índice de Conformidade do Banco (ICB) como indicador quantitativo de aderência às regras
estruturais definidas neste documento.

---

## 10. Auditoria e Rastreabilidade

Toda alteração estrutural aplicada ao banco deve gerar um registro em `auditoria.log_correcao`,
contendo, no mínimo: schema, tabela, objeto alterado, tipo de correção, descrição e resultado.
Esse log é a base de rastreabilidade usada em auditorias posteriores.

---

## 11. Gestão de Não Conformidades

Não conformidades identificadas pelo Framework DBA (ex.: ausência de PK, trigger não instanciado,
tabela duplicada) devem ser:

1. Registradas com prioridade (crítica, alta, média, baixa);
2. Vinculadas a um script de correção, quando aplicável;
3. Acompanhadas até o fechamento, com evidência em `auditoria.log_correcao`.

---

## 12. Glossário

| Termo | Significado |
| ----- | -------------------------------- |
| RFC | Request for Change (Solicitação de Mudança) |
| ICB | Índice de Conformidade do Banco |
| FK | Chave Estrangeira |

---

## 13. Documentos Relacionados

- DBA_FRAMEWORK.md
- DATABASE_GUIDE.md
- SECURITY.md
- CHANGELOG.md

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
