<!-- cspell:words correlacao ciclista pedalista evento alocacao -->

# Matriz de Rastreabilidade de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.3 — Matriz de Rastreabilidade (`BT-DOC-03`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento de rastreabilidade
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Objetivo e limite

Esta matriz liga requisitos de Bike Tour a dados, serviços, superfícies de API e evidências de teste. Os nomes de
serviço e operação são identificadores de rastreabilidade e não constituem contratos implementados.

Nenhuma rota, payload, migration ou regra funcional é autorizada por este documento. O status final depende dos
entregáveis de fronteiras, segurança, testes e schema.

## 2. Convenções

- `BT-REQ`: requisito funcional de Bike Tour;
- `atual`: estrutura já presente na baseline ou em módulos certificados;
- `delta`: conceito que requer decisão arquitetural e schema posterior;
- `/api/v1/biketour`: superfícies candidatas da API;
- cada requisito deve possuir teste de autorização, validação e erro, além da evidência específica indicada.

## 3. Requisitos e autoridade de dados

| ID | Requisito | Autoridade e dados relacionados |
| --- | --- | --- |
| BT-REQ-001 | Definir produto de Bike Tour | Turismo: pacote e produto base; Bike Tour: produto específico |
| BT-REQ-002 | Definir evento de Bike Tour | Turismo: saída base; Bike Tour: evento e data operacional |
| BT-REQ-003 | Gerenciar disponibilidade do recurso | Bike Tour: bicicleta, acesso e bloqueio; Turismo: saída base |
| BT-REQ-004 | Bloquear e expirar recurso | Bike Tour: alocação e validade; Turismo: saída e capacidade |
| BT-REQ-005 | Confirmar inscrição | Turismo: reserva; Bike Tour: participante e recurso |
| BT-REQ-006 | Correlacionar venda e evento | Comercial: venda e contrato; Bike Tour: evento e inscrição |
| BT-REQ-007 | Registrar ponto de controle | Bike Tour: ponto, ordem e status |
| BT-REQ-008 | Registrar ocorrência | Bike Tour: evento e trilha de ocorrência |
| BT-REQ-009 | Gerenciar logística de apoio | Bike Tour: material, apoio e transporte |
| BT-REQ-010 | Controlar equipe e guia | Bike Tour: pessoal e papel operacional |
| BT-REQ-011 | Definir acompanhantes e participantes | Turismo: passageiro; Bike Tour: papel na rota |
| BT-REQ-012 | Encerrar evento e preservar histórico | Bike Tour: evento, ocorrência e relatório |
| BT-REQ-013 | Validar autorização e privacidade | Core e Segurança: RBAC; Bike Tour: dados de participante |
| BT-REQ-014 | Auditar transições sensíveis | Auditoria: evento e contexto |

## 4. Serviços e operação de API planejados

| ID | Serviço de aplicação candidato | Superfície de API candidata |
| --- | --- | --- |
| BT-REQ-001 | `ProdutoBikeTourService` | `/api/v1/biketour/produtos` |
| BT-REQ-002 | `EventoBikeTourService` | `/api/v1/biketour/eventos` |
| BT-REQ-003 | `DisponibilidadeBikeTourService` | `/api/v1/biketour/eventos/{id}/recursos` |
| BT-REQ-004 | `RecursoBikeTourService` | `/api/v1/biketour/eventos/{id}/bloqueios` |
| BT-REQ-005 | `InscricaoBikeTourService` | `/api/v1/biketour/inscricoes` |
| BT-REQ-006 | `CorrelacaoBikeTourService` | operação interna versionada |
| BT-REQ-007 | `PontoControleService` | `/api/v1/biketour/eventos/{id}/pontos-controle` |
| BT-REQ-008 | `OcorrenciaBikeTourService` | `/api/v1/biketour/eventos/{id}/ocorrencias` |
| BT-REQ-009 | `LogisticaBikeTourService` | `/api/v1/biketour/eventos/{id}/logistica` |
| BT-REQ-010 | `EquipeBikeTourService` | `/api/v1/biketour/eventos/{id}/equipes` |
| BT-REQ-011 | `ParticipanteBikeTourService` | `/api/v1/biketour/eventos/{id}/participantes` |
| BT-REQ-012 | `ConclusaoEventoService` | `/api/v1/biketour/eventos/{id}/encerramento` |
| BT-REQ-013 | `SegurancaBikeTourService` | autorização e dados sensíveis |
| BT-REQ-014 | `AuditoriaBikeTourService` | consulta administrativa restrita |

## 5. Evidências de teste requeridas

| ID | Evidência mínima de teste |
| --- | --- |
| BT-REQ-001 | produto sem rota ou nível inválido e rejeitado |
| BT-REQ-002 | evento fora de período ou sem equipe válida e rejeitado |
| BT-REQ-003 | disponibilidade por recurso respeita capacidade e bloqueios |
| BT-REQ-004 | concorrência pela última bicicleta e bloqueio expira uma vez |
| BT-REQ-005 | inscrição sem recurso ou evento válido e rejeitada |
| BT-REQ-006 | correlação duplicada ou inexistente e rejeitada |
| BT-REQ-007 | ponto de controle fora de ordem e rejeitado |
| BT-REQ-008 | ocorrência sem evento ou sem gravidade e rejeitada |
| BT-REQ-009 | logística sem material ou suporte e rejeitada |
| BT-REQ-010 | equipe sem papel ou guia válido e rejeitada |
| BT-REQ-011 | participante sem dados mínimos ou sem permissão e rejeitado |
| BT-REQ-012 | encerramento sem evento ativo e rejeitado |
| BT-REQ-013 | acesso sem permissão e negado |
| BT-REQ-014 | alteração sensível gera evento e trilha auditável |

## 6. Rastreabilidade transversal

| Controle | Requisitos atendidos | Documento responsável |
| --- | --- | --- |
| fronteiras de domínio | 001, 003, 005, 006, 011, 013 | `BT-DOC-04` |
| concorrência e transação | 003, 004, 005, 009, 010, 012 | `BT-DOC-05` |
| autorização e privacidade | 005, 011, 013, 014 | `BT-DOC-06` |
| testes e regressão | 001 a 014 | `BT-DOC-07` |
| persistência e schema | 001 a 014 | `BT-DOC-08` |

## 7. Critério de cobertura

Um requisito somente pode ser considerado implementado quando:

1. autoridade e regra estiverem aprovadas no documento responsável;
2. a representação de dados for compatível com a decisão de schema;
3. o serviço não escrever em domínio privado de outro módulo;
4. o contrato OpenAPI versionado tiver sido definido, se houver endpoint HTTP;
5. testes de unidade, integração e autorização forem aplicáveis;
6. evidências de regressão e migrations lineares forem preservadas.

## 8. Conclusão

A matriz de rastreabilidade estabelece a ligação essencial entre requisito, dado, serviço, API e teste. Ela fornece a
base documental para o gate da etapa e permanece condicionada à aprovação dos entregáveis de fronteiras,
segurança, testes e schema.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.3 — Matriz de Rastreabilidade de Bike Tour |
| Entregável | `BT-DOC-03` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

<!-- cspell:ignore inscricoes Ocorrencia ocorrencias Logistica logistica -->
