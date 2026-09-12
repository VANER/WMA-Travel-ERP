# WMA Travel ERP — Gate Documental da Etapa 2.7

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7 — Bike Tour
> **Módulo:** Bike Tour
> **Tipo de documento:** Gate documental
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** GATE FECHADO; IMPLEMENTAÇÃO AUTORIZADA

## 1. Objetivo

Definir os documentos e critérios que devem preceder a implementação funcional de Bike Tour. Este gate autoriza
apenas inventário, análise e decisões documentais; não autoriza models, migrations, endpoints ou regras de negócio.

## 2. Dependências satisfeitas

- etapas 2.0 a 2.6 concluídas, certificadas e integradas;
- Core Corporativo como autoridade cadastral;
- Turismo como autoridade funcional de saída, reserva e passageiro;
- Comercial como autoridade de venda e contrato;
- Financeiro como autoridade de lançamento, pagamento e conciliação;
- sequência funcional definida pela ADR-017.

## 3. Fontes de verdade

| Fonte | Autoridade |
| --- | --- |
| `Docs/PHASE_2_EXECUTION_ORDER.md`, seção 11 | Ordem e dependências oficiais da etapa 2.7 |
| `Docs/PHASE_2_ROADMAP.md`, seção 11 | Escopo macro e sequência da Fase 2 |
| `Docs/architecture/ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md` | Posicionamento funcional de Bike Tour |
| `Docs/TOURISM_DOMAIN_BOUNDARIES.md` | Autoridades e especialização de Turismo |
| `Docs/TOURISM_TRANSACTION_POLICY.md` | Invariantes comuns e concorrência |
| `Docs/DATABASE_STANDARDS.md`, `Docs/SECURITY.md`, `Docs/GOVERNANCE.md` | Regras normativas de banco, segurança e governança |
| `Database/scripts/WmaTravelERP.sql` e migrations posteriores | Baseline executável certificada |
| `Backend/openapi.json` | Contrato executável atual da API |

O `AGENTS.md` fornecido na conversa cita a 2.5 como próximo passo; o arquivo local no commit `74685c6`
cita o gate documental da 2.7. A divergência fica registrada, sem presumir autorização funcional.

## 4. Escopo e fronteiras

O inventário e os demais entregáveis devem cobrir eventos, roteiros, inscrições, participantes, bicicletas, equipes,
veículos de apoio, logística, pontos de controle, ocorrências e acompanhamento operacional.

| Autoridade | Limite de Bike Tour |
| --- | --- |
| Core | Referenciar clientes, fornecedores, localidades e identidade; não duplicar cadastros |
| Turismo | Reutilizar contratos comuns de saída, reserva, vaga e passageiro |
| Comercial | Referenciar venda, item e contrato; não escrever fatos comerciais |
| Financeiro | Referenciar obrigações e pagamentos; não duplicar lançamento ou conciliação |
| Bike Tour | Definir somente recursos e regras exclusivos da modalidade |

Frontend, aplicativo móvel, scheduler e integrações do site não fazem parte desta abertura. Nenhuma tabela,
migration, classe de domínio ou rota deve ser criada antes da aprovação do gate.

## 5. Entregáveis obrigatórios

| ID | Entregável | Evidência de aceite | Status |
| --- | --- | --- | --- |
| BT-DOC-01 | Inventário | [Aceite formal, seção 9](BIKE_TOUR_INVENTORY.md#9-aceite-formal) | APROVADO E ACEITO |
| BT-DOC-02 | Matriz funcional | Fluxos, estados e critérios de aceite por requisito | APROVADO E ACEITO |
| BT-DOC-03 | Rastreabilidade | Requisito → dado → serviço → API → teste | APROVADO E ACEITO |
| BT-DOC-04 | Fronteiras | Autoridade de cada entidade e contrato de integração | APROVADO E ACEITO |
| BT-DOC-05 | Política transacional | Capacidade, recursos exclusivos, idempotência, rollback e compensação | APROVADO E ACEITO |
| BT-DOC-06 | Segurança e privacidade | RBAC, dados necessários, retenção e trilha de auditoria | APROVADO E ACEITO |
| BT-DOC-07 | Plano de testes | Casos normais, limites, concorrência, falhas e regressão | APROVADO E ACEITO |
| BT-DOC-08 | Decisão de schema | ADR para ausência de delta ou migration aditiva justificada | APROVADO E ACEITO |

Cada aprovação deve registrar responsável, data e evidência. A existência do arquivo não equivale à aprovação.

## 6. Critérios para iniciar implementação

- [x] correção encontrada na regressão integrada e regressão final da `main` aprovada;
- [x] situação SMTP e tratamento do histórico documentados com evidência do responsável;
- [x] `BT-DOC-01` a `BT-DOC-08` aprovados e rastreáveis;
- [x] autoridades preservadas, sem duplicação de reserva, vaga ou fatos financeiros;
- [x] contratos de API, erros HTTP, RBAC e critérios de teste aprovados;
- [x] delta de banco decidido sem modificar baseline, tags ou migrations históricas.

A evidência de regressão consultada refere-se à `main` remota do PR #65, não a uma igualdade entre branches locais.
O [adendo do gate de transição](certification/PHASE_2_6_TO_2_7_TRANSITION_GATE.md#5-adendo-de-auditoria-do-gate)
registra os três CIs pós-merge e o alcance da evidência SMTP.
A [matriz de auditoria](BIKE_TOUR_GATE_AUDIT.md) detalha os bloqueadores e a evidência necessária para cada aceite.
BT-DOC-01 foi aceito por Vaner em 10/09/2026, no commit `f94f421`; A1 está fechado.
BT-DOC-02 a BT-DOC-08 foram aprovados e aceitos por Vaner em 11/09/2026 após auditoria semântica e validação documental.
Os dois pré-requisitos acima foram conciliados com autorização explícita de Vaner nesta revisão.
A regressão está vinculada ao SHA `5856477`; a atestação SMTP cobre o ambiente local, sem produção existente.
Todos os critérios documentais de abertura da implementação foram atendidos; A1–A8 estão fechados e rastreáveis.

## 7. Resultado e próxima execução autorizada

Os critérios documentais foram integralmente atendidos. A implementação funcional de Bike Tour está autorizada.
A autorização não certifica a Etapa 2.7 como concluída; a próxima execução é a implementação funcional
conforme A2–A8 e ADR-020.

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Etapa | 2.7 — Bike Tour |
| Versão | 1.0 |
| Status | GATE FECHADO; IMPLEMENTAÇÃO AUTORIZADA |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
