# Guia de Padrões de Desenvolvimento — WMA Travel ERP

**Versão do Documento:** 1.0.0
**Última Atualização:** 09/08/2026
**Status:** Rascunho Inicial

---

## Índice

- [Guia de Padrões de Desenvolvimento — WMA Travel ERP](#guia-de-padrões-de-desenvolvimento--wma-travel-erp)
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
| `black` | Formatação automática de código |
| `ruff` | Lint rápido e correção de estilo |
| `pylint` | Análise estática adicional |
| `mypy` | Checagem de tipos estáticos |

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

Toda documentação do projeto segue as regras configuradas em `_markdownlint.jsonc`, com destaque
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

---

## 8. Estrutura de Branches

```text
main        → produção
develop     → integração contínua
feature/*   → novas funcionalidades
fix/*       → correções pontuais
release/*   → preparação de versão
```

Toda `feature/*` e `fix/*` é integrada a `develop` via pull request revisado.

---

## 9. Glossário

| Termo | Significado |
| ----- | ---------------------------------- |
| PR | Pull Request |
| Lint | Análise estática de estilo/código |

---

## 10. Documentos Relacionados

- DATABASE_GUIDE.md
- CONTRIBUTING.md
- GOVERNANCE.md

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
