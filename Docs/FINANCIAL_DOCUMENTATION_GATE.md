# WMA Travel ERP — Gate Documental da Etapa 2.5

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.5 — Financeiro
> **Módulo:** Financeiro
> **Tipo de documento:** Gate Documental
> **Versão:** 1.0
> **Data:** 01/09/2026
> **Status:** PLANEJADA

A etapa permanece planejada. Este documento autoriza apenas o inventário `FIN-DOC-01`, não a implementação.

## 1. Objetivo

Definir as fontes de verdade, os entregáveis documentais e os critérios mínimos que antecedem a implementação da
etapa 2.5, preservando integralmente a baseline e as evidências certificadas da Fase 1.

Este gate não autoriza alterações de schema, migrations, models, API ou regras financeiras. A primeira execução
funcional permanece o inventário verificável do domínio Financeiro.

## 2. Fontes de verdade

| Fonte | Autoridade |
| --- | --- |
| `Docs/PHASE_2_EXECUTION_ORDER.md` | Ordem, dependências e gate oficial da etapa 2.5 |
| `Docs/PHASE_2_ROADMAP.md` | Escopo macro e sequência da Fase 2 |
| `Docs/DATABASE_STANDARDS.md` | Normas vigentes para objetos PostgreSQL |
| `Docs/DATA_DICTIONARY.md` | Catálogo da baseline certificada |
| `Database/scripts/WmaTravelERP.sql` | Dump completo oficial para reconstrução |
| `Database/scripts/F1_FIN/` | Construção histórica certificada do domínio Financeiro |
| `Database/certification/F1_FIN_13_CERTIFICACAO_FINAL.md` | Certificação estrutural histórica |
| `Database/certification/F1_FIN_CERTIFICACAO_REPRODUTIBILIDADE.md` | Evidência histórica de reprodução |
| `Docs/architecture/ADR-014-TRANSACTION-BOUNDARIES.md` | Autoridade dos limites transacionais |
| `Docs/architecture/ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md` | Posicionamento oficial da etapa 2.5 |

Em caso de divergência, a baseline certificada deve ser preservada e a inconsistência deve ser registrada no
inventário. Nenhum artefato histórico pode ser corrigido retroativamente para acomodar a implementação.

## 3. Escopo documental de entrada

O inventário da 2.5 deve identificar, sem alterar o banco:

- tabelas, views, sequences, constraints, índices, funções, procedures e triggers financeiros;
- autoridades de dados entre `public` e `financeiro`;
- relacionamentos com Core Corporativo e Comercial;
- estruturas refletíveis por SQLAlchemy e lacunas de mapeamento;
- regras já impostas pelo banco e regras apenas presumidas por nomes ou comentários;
- campos monetários, datas, status, auditoria, soft delete e versionamento;
- riscos de concorrência, duplicidade, arredondamento e integridade transacional;
- ausências que exigiriam migration aditiva;
- objetos históricos que devem permanecer somente como referência certificada.

## 4. Entregáveis obrigatórios antes da implementação

| ID | Entregável | Resultado esperado | Status |
| --- | --- | --- | --- |
| FIN-DOC-01 | Inventário financeiro | Objetos, autoridades, relações e lacunas identificados | APROVADO |
| FIN-DOC-02 | Matriz funcional | Fluxos e regras ligados às estruturas existentes | APROVADO |
| FIN-DOC-03 | Matriz de rastreabilidade | Requisito → dado → serviço → API → teste | APROVADO |
| FIN-DOC-04 | Fronteiras de domínio | Core, Comercial, Financeiro e Fiscal delimitados | APROVADO |
| FIN-DOC-05 | Política transacional | Commit, rollback, estorno e idempotência definidos | APROVADO |
| FIN-DOC-06 | Segurança e alçadas | Permissões, segregação de funções e auditoria definidas | APROVADO |
| FIN-DOC-07 | Plano de testes | Cenários normais, limites, falhas e regressões definidos | APROVADO |
| FIN-DOC-08 | Decisão de schema | Ausência de delta ou migration aditiva justificada | APROVADO |

## 5. Decisões que não podem ser presumidas

O inventário deve registrar como decisão pendente, até validação funcional expressa:

- regime de caixa, competência e respectivas fronteiras;
- regras de fechamento e reabertura de período;
- cancelamento, estorno, reversão e reprocessamento;
- pagamentos parciais, antecipações, juros, multas, descontos e abatimentos;
- tolerâncias e tratamento de divergências na conciliação;
- alçadas de criação, aprovação, pagamento e baixa;
- integração idempotente entre Comercial e Financeiro;
- moeda, câmbio e precisão além do padrão monetário certificado;
- fronteira entre os domínios Financeiro, Contábil e Fiscal.

Ausência de decisão não autoriza a criação de uma regra implícita no código.

## 6. Critérios para iniciar implementação

- [ ] `FIN-DOC-01` a `FIN-DOC-08` concluídos ou explicitamente classificados como não aplicáveis;
- [ ] inconsistências entre documentação, dump e código registradas;
- [ ] nenhuma alteração retroativa em baseline, scripts F1-FIN ou certificações;
- [ ] autoridades de dados e limites transacionais aprovados;
- [ ] critérios de aceite verificáveis definidos;
- [ ] impacto estrutural avaliado antes de qualquer revision Alembic;
- [ ] plano de validação em PostgreSQL local descartável definido;
- [ ] documentação técnica preparada a partir do template oficial.

## 7. Próxima execução autorizada

Implementar a etapa 2.5 conforme `Docs/FINANCIAL_IMPLEMENTATION_DESIGN.md`. Toda evolução estrutural deve ser
aditiva; a baseline, os scripts F1-FIN e as certificações históricas permanecem imutáveis.

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.0 |
| Status | PLANEJADA |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

Alterações neste documento devem ser versionadas e manter a rastreabilidade pelo Git.
