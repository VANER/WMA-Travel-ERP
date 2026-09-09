<!-- cspell:words correlacao alocacao observabilidade -->

# Segurança e Privacidade de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.6 — Segurança e Privacidade (`BT-DOC-06`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento de segurança e privacidade
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Objetivo

Definir autorização, minimização, retenção e auditoria aplicáveis ao domínio de Bike Tour. Permanecem vigentes
`Docs/SECURITY.md`, `Docs/GOVERNANCE.md` e a autenticação central da API.

## 2. Permissões

| Permissão | Alcance |
| --- | --- |
| `BIKE_TOUR_VISUALIZAR` | consultar eventos, recursos e disponibilidade |
| `BIKE_TOUR_OPERAR` | confirmar inscrições, registrar ocorrências e atualizar ponto de controle |
| `BIKE_TOUR_GERENCIAR` | configurar evento, recurso, equipe e logística |

A visualização não implica acesso irrestrito a documentos, telefones, CPFs ou e-mails do participante.

## 3. Dados pessoais

- coletar somente dados necessários à operação e à obrigação aplicável;
- nunca registrar dados sensíveis em logs, métricas, erros, correlação ou idempotência;
- separar consulta operacional de acesso administrativo;
- mascarar documento e CPF quando o valor integral não for necessário;
- preservar correlação por identificadores internos;
- aplicar retenção por finalidade antes de anonimizar ou excluir;
- auditar acesso excepcional e toda mutação do participante.

## 4. Auditoria e controles

Toda rota ou operação de Bike Tour deve exigir token e permissão explicitamente. Eventos de mutação, alocação,
expiração, ocorrência e encerramento devem ser gravados em auditoria com identificador do operador e da
correlação.

## 5. Riscos e tratamento

| Risco | Controle obrigatório |
| --- | --- |
| acesso excessivo a dados de participante | menor privilégio e resposta mínima |
| vazamento em observabilidade | proibição de PII em logs e métricas |
| inscrição duplicada | chave idempotente única |
| elevação por rota | RBAC no servidor |
| alteração não rastreada | trigger e identidade do ator |
| recurso indevido atribuído | validação por evento e disponibilidade |

## 6. Conclusão

O `BT-DOC-06` permanece em elaboração. Os requisitos de segurança e privacidade devem ser aprovados antes de
qualquer implementação funcional da etapa 2.7.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.6 — Segurança e Privacidade de Bike Tour |
| Entregável | `BT-DOC-06` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
