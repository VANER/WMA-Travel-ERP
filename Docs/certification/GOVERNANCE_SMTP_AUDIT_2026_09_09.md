# WMA Travel ERP — Auditoria Complementar de Governança e SMTP

> **Projeto:** WMA Travel ERP
> **Fase:** Fase 2 — Backend e API
> **Tipo de documento:** Certificação Técnica Complementar
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** VALIDAÇÃO LOCAL CONCLUÍDA; PUBLICAÇÃO E INTEGRAÇÃO PENDENTES

## 1. Objetivo e escopo

Corrigir o enforcement dos gates, a inconsistência documental e a interferência do ambiente nos testes SMTP.
Base auditada: `243cc90126c22d27d1796c4469d1a3c3cc5d65ed`, integrada pelo PR #64.
Correção técnica local: `b291e5d`; os complementos documentais registram as evidências finais.
Nenhuma implementação de Bike Tour, migration nova ou alteração retroativa da baseline integra este escopo.

## 2. Achados e correções

- A regra da branch exigia apenas `Markdown e ortografia`; foram incluídos `Python 3.13` e `Secret scan`.
- Mantidos política estrita de atualização, ausência de bypass, bloqueio de exclusão e de force push.
- Removidos filtros de caminhos para emitir todos os checks em PRs e em pushes para `main`.
- Acrescentada reversão e reaplicação da última migration no workflow Backend CI.
- Testes SMTP carregavam configuração local quando executados dentro de `Backend/`.
  A configuração agora desabilita o arquivo de ambiente e isola as variáveis externas durante sua construção.
- Preservados os ajustes locais de nomes dos testes; reconciliados AGENTS e o status integrado da etapa 2.2.
- O checklist anterior misturava conclusão e pendências; agora diferencia evidência local, GitHub e operação SMTP.

## 3. Evidências locais

| Validação | Resultado |
| --- | --- |
| `python -m pip check` | PASS |
| `ruff check .` | PASS |
| `ruff format --check app tests migrations scripts` | PASS; 110 arquivos |
| `mypy app tests scripts` | PASS; 101 arquivos |
| `pytest -W error --run-postgresql --cov=app --cov-report=term-missing` | PASS; 408 testes em 212,06 s |
| Cobertura de `app` | 100%; 2878 instruções, nenhuma sem cobertura |
| SMTP e CI com variável SMTP externa sintética | PASS; 9 testes |
| `python scripts/export_openapi.py --check` | PASS; contrato sincronizado |
| `alembic heads` | PASS; `202609080100` |
| Markdownlint de arquivos versionados | PASS; 145 arquivos antes desta certificação |
| CSpell dos documentos vivos | PASS; complementos conferidos separadamente |
| `git diff --check` | PASS |

A primeira regressão identificou duas falhas SMTP e uma asserção do formato de comando do workflow.
Após isolamento da configuração e separação dos passos Alembic, a suíte completa passou.
O teste de ambiente utiliza valor sintético e não realiza envio real de e-mail.

## 4. PostgreSQL e migrations

A suíte usou exclusivamente `wma_governance_20260909_test`, criado localmente para esta auditoria.
Incluiu testes reais de concorrência, capacidade, idempotência, consistência e rollback.

O ciclo Alembic usou `wma_governance_migration_20260909_test`, cópia descartável do banco local
`wma_turismo_hardening_migration_20260908_test`, que já estava na revisão `202609080100`.
Foram executados `upgrade head`, `downgrade -1`, `upgrade head` e `current`, todos com sucesso.
A revisão final voltou a `202609080100`. Isso valida o ciclo da última migration; não é nova restauração da baseline.

## 5. Evidência remota e integração

A regra [22152693](https://github.com/VANER/WMA-Travel-ERP/rules/22152693) foi alterada e relida pela API.
Os três checks pertencem à integração GitHub Actions `15368`. Secret scanning e push protection estão habilitados.

| Gate | Estado |
| --- | --- |
| Configuração dos checks obrigatórios | Verificada no GitHub |
| Publicação da correção | Pendente de aprovação específica após bloqueio automático |
| CI do novo PR | Pendente; não executado sem publicação |
| Merge e CI pós-merge no mesmo SHA | Pendentes |
| PR #63 | Aberto; Backend CI vermelho; não integrado nesta auditoria |

O PR #63 contém proposta anterior de ajustes SMTP, tokens e AGENTS. A correção de tokens já está na base;
a atualização de AGENTS e o isolamento SMTP estão tratados nesta correção. O PR antigo deve ser encerrado
como substituído somente após validação e publicação do novo PR, preservando rastreabilidade.

## 6. SMTP e riscos residuais

Vaner atestou em 09/09/2026 que os testes operacionais foram realizados e documentados localmente, no VS Code,
e confirmou que ainda não existe produção. A referência é o
[registro de encerramento SMTP](../SECURITY_INCIDENT_SMTP_CLOSURE.md), seções 2, 4 e 6.
Esta auditoria não repetiu autenticação ou envio no provedor e não publicou valores de credenciais.

A validação em produção é requisito da futura implantação. O histórico Git permanece preservado;
a remoção na versão atual não elimina o segredo antigo do histórico. O tratamento depende da revogação atestada.
As branches remanescentes foram inventariadas sem remoção por ausência de confirmação de uso ativo.

## 7. Resultado e limites

Validação técnica local concluída, com cobertura de 100%. Esse percentual mede cobertura de testes,
não ausência absoluta de defeitos ou riscos. A integração não está certificada enquanto faltarem publicação,
CI do PR e CI pós-merge. O gate documental de Bike Tour continua aplicável antes de implementar a etapa 2.7.

## 8. Documentos relacionados

- [Auditoria de governança](../GOVERNANCE_AUDIT_CHECKLIST.md).
- [Registro SMTP](../SECURITY_INCIDENT_SMTP_CLOSURE.md).
- [Gate documental de Bike Tour](../BIKE_TOUR_DOCUMENTATION_GATE.md).

## 9. Controle de alterações

| Versão | Data | Alteração |
| --- | --- | --- |
| 1.0 | 09/09/2026 | Auditoria local e registro explícito dos gates remotos pendentes |
