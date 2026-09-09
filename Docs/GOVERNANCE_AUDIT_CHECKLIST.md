# Auditoria de Governança — WMA Travel ERP

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Status:** PROTEÇÃO E SMTP AUDITADOS; INTEGRAÇÃO PENDENTE

## 1. Objetivo

Consolidar evidências verificáveis antes da implementação da Etapa 2.7 — Bike Tour.
Esta revisão substitui marcações anteriores sem evidência suficiente; não altera certificações históricas.

## 2. Proteção verificada no GitHub

A API do GitHub confirmou a regra ativa `22152693`, aplicada à branch padrão, sem atores com bypass.
A auditoria encontrou apenas o check documental obrigatório e corrigiu a configuração em 09/09/2026.

| Workflow | Nome exato do check obrigatório | Origem |
| --- | --- | --- |
| Backend CI | `Python 3.13` | GitHub Actions, integração `15368` |
| Documentation CI | `Markdown e ortografia` | GitHub Actions, integração `15368` |
| Secret Scan | `Secret scan` | GitHub Actions, integração `15368` |

- [x] Regra ativa com os três checks obrigatórios.
- [x] Branch atualizada antes do merge: política estrita habilitada.
- [x] Sem bypass; exclusão e atualização não fast-forward bloqueadas.
- [x] Pull request obrigatório; check ausente ou vermelho impede integração.
- [x] Secret scanning e push protection habilitados.
- [ ] Workflows sem filtros de caminhos integrados e CI pós-merge aprovado.

Os filtros de caminhos do Backend CI foram removidos nesta correção para que todos os PRs emitam o check.
O Documentation CI também passa a executar em todo push para `main`, permitindo auditar o mesmo SHA.

Evidência: [regra da branch padrão](https://github.com/VANER/WMA-Travel-ERP/rules/22152693).

## 3. SMTP e histórico

O [registro SMTP](SECURITY_INCIDENT_SMTP_CLOSURE.md) declara revogação, rotação e validação operacional local.
Essa declaração é uma evidência documental existente, não uma nova verificação do provedor nesta auditoria.

- [x] Rotação e revogação declaradas no registro existente.
- [x] Decisão de preservar o histórico Git registrada.
- [x] Vaner confirmou em 09/09/2026: testes locais documentados; ainda não existe produção.
- [x] Auditoria documental SMTP concluída para o ambiente existente, sem divulgar credenciais.

Remover o segredo da versão atual não remove cópias históricas. Preservar o histórico depende da revogação
registrada; não significa que o histórico está livre do segredo antigo. Não serão reescritos marcos certificados.
Testes unitários usam transporte simulado e não comprovam autenticação ou entrega no provedor.

## 4. Pendências e transição

- [ ] Revisar o PR #63, encontrado aberto com Backend CI vermelho; não integrá-lo nesse estado.
- [ ] Concluir validação e integração da correção de governança, vinculadas ao SHA resultante.
- [x] Branches inventariadas; remoção depende da confirmação de ausência de uso.
- [ ] Aprovar entregáveis do [gate Bike Tour](BIKE_TOUR_DOCUMENTATION_GATE.md) antes da implementação.

As etapas 2.0 a 2.6 permanecem integradas. A próxima etapa é 2.7, inicialmente documental.
Não há certificação de ausência absoluta de riscos nem liberação funcional enquanto existirem gates pendentes.

<!-- cspell:ignore fundacao certificacao -->

## 5. Inventário de branches remanescentes

Consulta à API do GitHub em 09/09/2026. PR integrado não comprova ausência de commits posteriores
nem de trabalho ativo; nenhuma branch foi removida nesta auditoria.

| Branch | Referência | Decisão |
| --- | --- | --- |
| `chore/local-remaining-fixes` | PR #63 aberto | Preservar até substituição validada |
| `chore/project-standardization` | #53 | PR integrado; uso atual não confirmado |
| `docs/atualizar-status-fase-2` | #12 | PR integrado; uso atual não confirmado |
| `docs/close-phase-2.5-post-merge` | #56 | PR integrado; uso atual não confirmado |
| `docs/close-phase-2.6-hardening-post-merge` | #60 | PR integrado; uso atual não confirmado |
| `docs/finalizar-etapa-2.0.9` | #14 | PR integrado; uso atual não confirmado |
| `docs/finalizar-etapa-2.0.10` | #16 | PR integrado; uso atual não confirmado |
| `docs/finalizar-etapa-2.0.11` | #18 | PR integrado; uso atual não confirmado |
| `docs/registrar-auditoria-final-fundacao-2.0` | #20 | PR integrado; uso atual não confirmado |
| `feat/financeiro-2.5` | #55 | PR integrado; uso atual não confirmado |
| `feature/2.0.2-backend-bootstrap` | #3 | PR integrado; uso atual não confirmado |
| `feature/2.0.3-modular-structure` | #4 | PR integrado; uso atual não confirmado |
| `feature/2.0.4-backend-configuration` | #5 | PR integrado; uso atual não confirmado |
| `feature/2.0.5-postgresql-sqlalchemy` | #8 | PR integrado; uso atual não confirmado |
| `feature/2.0.6-alembic-migrations` | #9 | PR integrado; uso atual não confirmado |
| `feature/2.0.7-api-base` | #10 | PR integrado; uso atual não confirmado |
| `feature/2.0.8-openapi` | #11 | PR integrado; uso atual não confirmado |
| `feature/2.0.9-testes-iniciais` | #13 | PR integrado; uso atual não confirmado |
| `feature/2.0.10-github-actions` | #15 | PR integrado; uso atual não confirmado |
| `feature/2.0.11-certificacao-fundacao` | #17 | PR integrado; uso atual não confirmado |
| `fix/close-smtp-security-incident` | #62 | PR integrado; uso atual não confirmado |
| `fix/security-smtp-mitigation` | #61 | PR integrado; uso atual não confirmado |
| `fix/2.0-foundation-pending-items` | #24 | PR integrado; uso atual não confirmado |
| `fix/2.0.4-certification` | #6 | PR integrado; uso atual não confirmado |
| `security/remove-exposed-smtp-credentials` | #54 | PR integrado; uso atual não confirmado |

## 6. Evidência da regressão

A [auditoria complementar](certification/GOVERNANCE_SMTP_AUDIT_2026_09_09.md) registra 408 testes aprovados,
cobertura de 100%, PostgreSQL real e ciclo Alembic concluído. Publicação e integração continuam pendentes.
