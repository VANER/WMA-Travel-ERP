# Recomendação de Ruleset do GitHub

## 1. Objetivo

Registrar a configuração recomendada para proteção da branch `main`. Este documento é uma recomendação de
governança; nenhuma automação deste repositório cria, altera, aprova ou ignora rulesets no GitHub.

## 2. Configuração recomendada

| Regra | Valor recomendado |
| --- | --- |
| Pull request obrigatório | `true` |
| Aprovações obrigatórias | `0` |
| Aprovação de Code Owner | `false` |
| Aprovação após o último push | `false` |
| Proteção contra exclusão | `true` |
| Bloqueio de non-fast-forward | `true` |
| Aprovação extra para alterações sem atribuição | `false` |

Checks obrigatórios:

- `Markdown e ortografia`;
- `Python 3.13`.

## 3. Aplicação

A configuração deve ser aplicada manualmente por mantenedor autorizado nas configurações do repositório. Não se
deve criar bypass, autoaprovação ou workflow destinado a contornar a proteção.

## 4. Saneamento de branches

Branches remotas somente devem ser removidas após prova de que estão integralmente mergeadas em `main`, não são a
branch principal e não correspondem à branch ativa de um pull request. A lista auditada deve ser tratada como
recomendação de limpeza, sem exclusão automática neste fechamento.

Na auditoria de 04/09/2026, `git branch -r --merged origin/main` confirmou as seguintes candidatas:

<!-- cspell:disable -->

- `chore/project-standardization`;
- `docs/atualizar-status-fase-2`;
- `docs/finalizar-etapa-2.0.9`;
- `docs/finalizar-etapa-2.0.10`;
- `docs/finalizar-etapa-2.0.11`;
- `docs/registrar-auditoria-final-fundacao-2.0`;
- `feat/financeiro-2.5`;
- `feature/2.0.2-backend-bootstrap`;
- `feature/2.0.3-modular-structure`;
- `feature/2.0.4-backend-configuration`;
- `feature/2.0.5-postgresql-sqlalchemy`;
- `feature/2.0.6-alembic-migrations`;
- `feature/2.0.7-api-base`;
- `feature/2.0.8-openapi`;
- `feature/2.0.9-testes-iniciais`;
- `feature/2.0.10-github-actions`;
- `feature/2.0.11-certificacao-fundacao`;
- `fix/2.0-foundation-pending-items`;
- `fix/2.0.4-certification`;
- `security/remove-exposed-smtp-credentials`.

<!-- cspell:enable -->

A branch `docs/close-phase-2.5-post-merge` foi excluída da lista por ser a branch ativa do PR `#56`. Nenhuma
branch foi removida automaticamente.

## 5. Risco externo de credencial

A credencial SMTP previamente exposta deve estar revogada ou rotacionada no provedor. A auditoria do repositório
não comprova a execução dessa ação externa; um mantenedor deve confirmá-la diretamente no provedor, sem registrar
o novo segredo no Git ou na documentação.
