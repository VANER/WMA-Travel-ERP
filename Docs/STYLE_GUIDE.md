# WMA Travel ERP — Guia de Padrões de Desenvolvimento

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Guia Resumido
> **Versão:** 1.2.0
> **Data:** 01/09/2026
> **Status:** VIGENTE

---

## Índice

- [WMA Travel ERP — Guia de Padrões de Desenvolvimento](#wma-travel-erp--guia-de-padrões-de-desenvolvimento)
  - [Índice](#índice)
  - [1. Objetivo](#1-objetivo)
  - [2. Padrões SQL](#2-padrões-sql)
  - [3. Padrões Python](#3-padrões-python)
  - [4. Padrões TypeScript/React](#4-padrões-typescriptreact)
  - [5. Padrões Flutter/Dart](#5-padrões-flutterdart)
  - [6. Convenção de Commits](#6-convenção-de-commits)
  - [7. Padrões de Documentação Markdown](#7-padrões-de-documentação-markdown)
  - [8. Estrutura de Branches](#8-estrutura-de-branches)
  - [9. Glossário](#9-glossário)
  - [10. Documentos Relacionados](#10-documentos-relacionados)

---

## 1. Objetivo

Este documento consolida os padrões de codificação e documentação adotados no **WMA Travel ERP**,
garantindo consistência entre backend, frontend, mobile e banco de dados.

---

## 2. Padrões SQL

Os padrões de nomenclatura de tabelas, campos e objetos de banco estão definidos em
`DATABASE_GUIDE.md`, seção 7, e são referenciados aqui, não duplicados. Resumo:

- Nomes de tabela em português, singular, minúsculo, com underscore;
- Chave primária no padrão `id_nome_tabela`;
- Toda tabela deve possuir colunas de controle (`created_at`, `updated_at`, `deleted_at`).

---

## 3. Padrões Python

| Ferramenta | Finalidade |
| ---------- | -------------------------------------- |
| `ruff check` | Lint e organização de imports |
| `ruff format` | Formatação automática de código |
| `mypy` | Checagem estrita de tipos estáticos |
| `pytest` | Testes automatizados e cobertura |

Convenções gerais:

- Nomes de função e variável em `snake_case`;
- Nomes de classe em `PascalCase`;
- Tipagem explícita em funções públicas da API (FastAPI);
- Um router por domínio de negócio (financeiro, comercial, fiscal, turismo, bike tour).

---

## 4. Padrões TypeScript/React

- Lint via ESLint com regras compartilhadas do projeto;
- Componentes em `PascalCase`, hooks customizados prefixados com `use`;
- Componentes de UI seguindo Material UI como biblioteca base;
- Separação entre componentes de apresentação e componentes conectados a estado/API.

---

## 5. Padrões Flutter/Dart

- Nomes de classe em `PascalCase`, arquivos em `snake_case`;
- Separação entre camada de dados, domínio e apresentação;
- Sincronização offline tratada como caso de uso explícito, não como exceção do fluxo principal.

---

## 6. Convenção de Commits

Adota-se o padrão **Conventional Commits**:

```text
tipo(escopo): descrição curta

feat(financeiro): adiciona endpoint de conciliação bancária
fix(auditoria): corrige cálculo do ICB
docs(readme): atualiza lista de documentos oficiais
```

Tipos permitidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

---

## 7. Padrões de Documentação Markdown

Toda documentação do projeto segue as regras configuradas em `.markdownlint.jsonc`, com destaque
para:

| Regra | Descrição |
| ------ | ---------------------------------------------------------- |
| MD012 | No máximo 1 linha em branco consecutiva |
| MD013 | Linha de texto com até 120 caracteres |
| MD022 | Títulos cercados por linha em branco |
| MD024 | Títulos duplicados permitidos apenas entre seções distintas |
| MD025 | Apenas um título de nível 1 (H1) por documento |
| MD032 | Listas cercadas por linha em branco |
| MD034 | URLs nuas não são permitidas, usar link markdown |
| MD040 | Blocos de código devem declarar a linguagem |
| MD047 | Arquivo deve terminar com uma única linha em branco |

Documentos devem ser compatíveis com VS Code, GitHub, MkDocs e Docusaurus, e escritos em
português do Brasil.

Novas certificações devem partir de `templates/CERTIFICATION_TEMPLATE.md`. Novos documentos de entrega técnica
devem partir de `templates/TECHNICAL_DOCUMENT_TEMPLATE.md`, removendo campos não aplicáveis somente quando a
decisão permanecer explícita no documento final.

---

## 8. Estrutura de Branches

```text
main        → linha estável e integrada
feat/*      → funcionalidades da etapa corrente
feature/*   → funcionalidades históricas ou incrementais
fix/*       → correções técnicas
docs/*      → documentação e certificações
```

Toda branch de trabalho é criada a partir de `main` e retorna diretamente para `main` por pull request revisado,
com os gates obrigatórios aprovados. O projeto não mantém uma branch permanente `develop`.

---

## 9. Glossário

| Termo | Significado |
| ----- | ---------------------------------- |
| PR | Pull Request |
| Lint | Análise estática de estilo/código |

---

## 10. Documentos Relacionados

- DATABASE_GUIDE.md
- CODE_STANDARDS.md
- DOCUMENTATION_STANDARDS.md
- CONTRIBUTING.md
- GOVERNANCE.md

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
