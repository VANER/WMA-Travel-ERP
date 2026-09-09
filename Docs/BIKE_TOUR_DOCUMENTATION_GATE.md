# WMA Travel ERP — Gate Documental da Etapa 2.7

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour
> **Tipo:** Gate Documental
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** ABERTO PARA PLANEJAMENTO; IMPLEMENTAÇÃO NÃO AUTORIZADA

## 1. Objetivo e dependências

Abrir o planejamento de Bike Tour no padrão dos gates de Financeiro e Turismo. Este documento organiza
inventário, decisões e critérios de aceite; não aprova antecipadamente os entregáveis nem autoriza código.

A 2.6 e seu hardening foram integrados. O fechamento documental ocorreu pelo PR #60, no commit
`f48b46566b1031dd089e9a14ca7ed0f226339f1a`. A regressão de transição identificou uma falha temporal nos testes
de tokens e uma restrição local na pasta temporária. A correção e as pendências de segurança estão no
[gate de transição](certification/PHASE_2_6_TO_2_7_TRANSITION_GATE.md).

## 2. Fontes de verdade

| Fonte | Uso |
| --- | --- |
| `Docs/PHASE_2_EXECUTION_ORDER.md`, seção 11 | Ordem oficial da 2.7 |
| `Docs/PHASE_2_ROADMAP.md`, seção 11 | Escopo macro de Bike Tour |
| `Docs/architecture/ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md` | Dependência de Turismo |
| `Docs/TOURISM_DOMAIN_BOUNDARIES.md` | Autoridades e especialização de Turismo |
| `Docs/TOURISM_TRANSACTION_POLICY.md` | Invariantes comuns e concorrência |
| `Database/scripts/WmaTravelERP.sql` e migrations posteriores | Estrutura existente, sem recriação histórica |
| `Docs/DATABASE_STANDARDS.md`, `Docs/SECURITY.md`, `Docs/GOVERNANCE.md` | Normas obrigatórias |
| `Backend/openapi.json` | Contratos executáveis disponíveis |

O `AGENTS.md` ainda cita a 2.5 como próxima etapa. Essa divergência está registrada; o escopo documental da 2.7
foi expressamente solicitado e segue a ordem vigente. As regras de preservação histórica continuam válidas.

## 3. Escopo e fronteiras

O inventário deve cobrir eventos, roteiros, inscrições, participantes, bicicletas, equipes, veículos de apoio,
logística, pontos de controle, ocorrências e acompanhamento operacional.

| Autoridade | Limite de Bike Tour |
| --- | --- |
| Core | Referenciar clientes, fornecedores, localidades e identidade; não duplicar cadastros |
| Turismo | Reutilizar contratos comuns de saída, reserva, vaga e passageiro |
| Comercial | Referenciar venda, item e contrato; não escrever fatos comerciais |
| Financeiro | Referenciar obrigações e pagamentos; não duplicar lançamento ou conciliação |
| Bike Tour | Definir somente recursos e regras exclusivos da modalidade |

Frontend, aplicativo móvel, scheduler e integrações do site não fazem parte desta abertura. Nenhuma tabela,
migration, classe de domínio ou rota deve ser criada antes da aprovação do gate.

## 4. Entregáveis obrigatórios

| ID | Entregável | Evidência de aceite | Status |
| --- | --- | --- | --- |
| BT-DOC-01 | Inventário | Objetos, FKs, contratos existentes e lacunas com fontes verificáveis | PENDENTE |
| BT-DOC-02 | Matriz funcional | Fluxos, estados e critérios de aceite por requisito | PENDENTE |
| BT-DOC-03 | Rastreabilidade | Requisito → dado → serviço → API → teste | PENDENTE |
| BT-DOC-04 | Fronteiras | Autoridade de cada entidade e contrato de integração | PENDENTE |
| BT-DOC-05 | Política transacional | Capacidade, recursos exclusivos, idempotência, rollback e compensação | PENDENTE |
| BT-DOC-06 | Segurança e privacidade | RBAC, dados necessários, retenção e trilha de auditoria | PENDENTE |
| BT-DOC-07 | Plano de testes | Casos normais, limites, concorrência, falhas e regressão | PENDENTE |
| BT-DOC-08 | Decisão de schema | ADR para ausência de delta ou migration aditiva justificada | PENDENTE |

Cada aprovação deve registrar responsável, data e evidência. A existência do arquivo não equivale à aprovação.

## 5. Decisões que o planejamento deve resolver

- Identidade e relação entre evento, saída turística e inscrição, sem criar reserva paralela.
- Capacidade de participantes e disponibilidade de bicicletas/equipamentos por intervalo.
- Estados permitidos, cancelamento, expiração, reacomodação e preservação do histórico.
- Correlação com Comercial e Financeiro, incluindo repetição e falha parcial.
- Necessidade e minimização de dados pessoais específicos da modalidade.
- Permissões por ação e consulta, responsáveis operacionais e auditoria.

O plano de testes deve incluir disputa pelo último recurso, reserva simultânea da mesma bicicleta, repetição
de comandos, rollback integral, referências inexistentes, transições inválidas e autorização por endpoint.
Esses cenários são critérios de análise; o modelo e os contratos permanecem por decidir.

## 6. Gate para implementação

- [ ] Correção encontrada na regressão integrada e regressão final da `main` aprovada.
- [ ] Situação SMTP e tratamento do histórico documentados com evidência do responsável.
- [ ] `BT-DOC-01` a `BT-DOC-08` aprovados e rastreáveis.
- [ ] Autoridades preservadas, sem duplicação de reserva, vaga ou fatos financeiros.
- [ ] Contratos de API, erros HTTP, RBAC e critérios de teste aprovados.
- [ ] Delta de banco decidido sem modificar baseline, tags ou migrations históricas.

## 7. Próxima execução

Preparar `BT-DOC-01` — Inventário de Bike Tour e submetê-lo à revisão. A implementação funcional permanece
bloqueada até o atendimento dos critérios acima. Esta abertura documental não certifica a Etapa 2.7.

**WMA Travel ERP — Gate documental anterior à implementação.**
