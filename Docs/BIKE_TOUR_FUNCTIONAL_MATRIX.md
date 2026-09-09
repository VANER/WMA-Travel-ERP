<!-- cspell:words alocacao correlacao ciclismo pedalista ponto controle -->

# Matriz Funcional de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.2 — Matriz Funcional de Bike Tour (`BT-DOC-02`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento funcional
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Objetivo e limite

Este documento define as capacidades funcionais e os invariantes do domínio de Bike Tour antes da implementação.
Ele relaciona requisitos ao inventário da etapa 2.7 sem autorizar schema, migration, endpoint ou código de
produção.

A etapa reutiliza a autoridade de Core, Comercial, Financeiro e Turismo. O domínio próprio refere-se a recursos e
regras da modalidade: bicicletas, equipes, pontos de controle e logística específica.

## 2. Atores e responsabilidades

| Ator | Responsabilidade | Limite de autoridade |
| --- | --- | --- |
| Administrador de Bike Tour | configurar produto, rota e parâmetros operacionais | não altera fatos monetários |
| Operação | preparar evento, pontos de controle e checklist específico | não altera contrato comercial |
| Equipe de apoio | atender rota, suporte e manutenção | não confirma venda nem pagamento |
| Participante | confirmar presença, acompanhar percurso e registrar ocorrências | acesso restrito ao próprio contexto |
| Comercial | formalizar venda, item e contrato | não controla capacidade da rota |
| Financeiro | tratar pagamento, cobrança e estorno | não altera disponibilidade do evento |
| Turismo | manter pacote e saída base | não redefine modalidade de Bike Tour |
| Auditor | consultar eventos e trilhas | sem mutação operacional |

## 3. Fluxo funcional de referência

1. Um produto ou pacote de Bike Tour é definido a partir de um pacote turístico base e de uma rota específica.
2. Um evento materializa data, capacidade, nível, apoio e pontos de controle.
3. O participante se inscreve ou é vinculado a uma reserva existente do pacote e a um recurso de bicicleta.
4. A operação valida disponibilidade de recurso, equipe e ponto de controle por intervalo.
5. A confirmação de inscrição aloca o recurso e registra a presença do participante.
6. O percurso e os pontos de controle registram avanço, atraso, interrupção ou ocorrência.
7. A logística de apoio registra suporte, manutenção e recursos complementares.
8. O encerramento da rota gera relatórios de execução, ocorrências e evento final.
9. O cancelamento ou a expiração de bloqueio libera o recurso e preserva histórico.
10. O pós-evento grava avaliação e conclusões sem duplicar fato financeiro ou comercial.

## 4. Matriz de capacidades

| Capacidade | Entrada principal | Resultado funcional | Situação |
| --- | --- | --- | --- |
| definir produto de Bike Tour | rota, nível, duração e apoio | produto específico da modalidade | lacuna |
| definir evento de Bike Tour | pacote base, data, capacidade e equipe | evento operacional identificável | lacuna |
| gerir recurso de bicicleta | tipo, capacidade e disponibilidade | alocação por recurso | lacuna |
| gerir equipe e guia | perfil, papel e escala | alocação operacional | lacuna |
| gerir ponto de controle | ordem, localização e critério | acompanhamento do percurso | lacuna |
| controlar presença e inscrição | participante, evento e recurso | inscrição rastreável | lacuna |
| registrar ocorrência | evento, tipo e gravidade | histórico operacional | lacuna |
| gerir logística de apoio | material, transporte e apoio | plano operacional coerente | lacuna |
| consultar disponibilidade | evento e recurso | saldo e bloqueios explícitos | lacuna |
| bloquear recurso | evento, recurso e validade | alocação temporária idempotente | lacuna |
| confirmar inscrição | evento, participante e recurso | participação confirmada | lacuna |
| concluir evento | status final, ocorrências e fechamento | evento encerrado e auditável | lacuna |
| avaliar pós-evento | evento e consentimento | avaliação validada | lacuna |

## 5. Conceitos e estados funcionais

| Conceito | Estados funcionais candidatos | Regra central |
| --- | --- | --- |
| Produto de Bike Tour | RASCUNHO, ATIVO, INATIVO | apenas produto ativo pode ser ofertado |
| Evento | PLANEJADO, ABERTO, EM_EXECUCAO, CONCLUIDO, CANCELADO | mudança de período exige autorização |
| Recurso | DISPONIVEL, BLOQUEADO, RESERVADO, EM_USO, MANUTENCAO | o recurso não pode exceder a capacidade |
| Inscrição | PENDENTE, CONFIRMADA, EXPIRADA, CANCELADA, NO_SHOW | confirmação exige recurso válido |
| Ponto de controle | AGENDADO, ATIVO, CONCLUIDO, CANCELADO | progresso deve seguir ordem esperada |
| Ocorrência | ABERTA, EM_ANALISE, RESOLVIDA, IGNORADA | registro preserva trilha e contexto |

## 6. Invariantes de negócio

- uma rota de Bike Tour não pode duplicar venda, vaga ou reserva já pertencentes a Turismo;
- um recurso só pode ser alocado a uma inscrição ativa por evento;
- presença e deslocamento não podem ser registrados sem evento e recurso válidos;
- a capacidade do recurso deve ser preservada por intervalo e por ordem de alocação;
- confirmação, expiração e cancelamento devem ser idempotentes;
- expiração de bloqueio libera o recurso uma única vez;
- ocorrência severa deve preservar auditoria e rastreabilidade do evento;
- Comercial e Financeiro permanecem autoridades de venda e cobrança;
- dados pessoais do participante devem ser mínimos e controlados por RBAC;
- qualquer transição relevante deve registrar ator, instante e correlação.

## 7. Cenários funcionais obrigatórios

| Cenário | Resultado esperado |
| --- | --- |
| duas inscrições para o mesmo recurso no mesmo intervalo | apenas uma permanece confirmada |
| repetição da mesma inscrição | a operação não duplica alocação |
| recurso bloqueado vencido | liberado uma vez e registrado |
| grupo sem guia válido | operação rejeitada |
| ponto de controle fora de ordem | transição rejeitada |
| ocorrência sem evento | rejeição ou registro invalidado |
| cancelamento de evento | participantes e recursos afetados rastreados |
| no-show sem justificativa | evento permanece auditável e reprocessável |
| reavaliação de evento concluído | rejeitada por política |

## 8. Segurança, privacidade e auditoria

Os dados pessoais do participante devem permanecer mínimos, restritos ao contexto do evento e protegidos por
permissão específica. Logs, erros e métricas não podem expor CPF, documento, telefone ou e-mail de forma
necessária.

Toda alteração de recurso, disponibilidade, inscrição e ocorrência deve gerar evento de auditoria. O estado
funcional permanece independente da persistência física.

## 9. Decisões encaminhadas

- `BT-DOC-03`: rastrear cada requisito a dado, serviço, API e teste;
- `BT-DOC-04`: formalizar fronteiras e autoridade entre Core, Comercial, Financeiro, Turismo e Bike Tour;
- `BT-DOC-05`: decidir transações, concorrência, expiração e compensação;
- `BT-DOC-06`: definir autorização, minimização, retenção e auditoria;
- `BT-DOC-07`: derivar o plano de testes a partir destes invariantes;
- `BT-DOC-08`: definir schema e migrations aditivas do módulo.

## 10. Conclusão

A matriz funcional identifica o domínio próprio, as lacunas e os critérios mínimos para a próxima etapa documental.
O escopo funcional continua bloqueado até a aprovação do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.2 — Matriz Funcional de Bike Tour |
| Entregável | `BT-DOC-02` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

<!-- cspell:ignore CONCLUIDO -->
