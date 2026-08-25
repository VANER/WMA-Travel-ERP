# WMA Travel ERP --- Architecture Decision Records

## Fase 2 --- Backend, API e Integrações

**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Data-base:** 18/08/2026\
**Status do conjunto:** APROVADO

## Objetivo

Este diretório mantém as decisões arquiteturais oficiais da Fase 2 do
WMA Travel ERP. As ADRs preservam contexto, decisão, alternativas,
consequências, regras e critérios de reavaliação.

## Regras de governança

- ADR aprovada não deve ser apagada para esconder histórico.
- Mudança substancial deve gerar nova ADR ou revisão formal
    rastreável.
- Implementação deve respeitar ADRs vigentes.
- Divergência intencional deve ser documentada antes de se tornar
    padrão.
- A baseline certificada da Fase 1 permanece protegida.

## Índice

| ADR | Decisão | Status |
| --- | --- | --- |
| ADR-001 | [Monólito Modular](ADR-001-MODULAR-MONOLITH.md) | APROVADA |
| ADR-002 | [Stack Tecnológica](ADR-002-TECH-STACK.md) | APROVADA |
| ADR-003 | [Persistência e SQLAlchemy](ADR-003-PERSISTENCE.md) | APROVADA |
| ADR-004 | [Banco de Dados e Migrations](ADR-004-DATABASE-MIGRATIONS.md) | APROVADA |
| ADR-005 | [Padrões de API](ADR-005-API-STANDARDS.md) | APROVADA |
| ADR-006 | [Configuração, Ambientes e Secrets](ADR-006-CONFIGURATION-SECRETS.md) | APROVADA |
| ADR-007 | [Segurança, Autenticação e Autorização](ADR-007-SECURITY.md) | APROVADA |
| ADR-008 | [Estratégia de Testes](ADR-008-TESTING.md) | APROVADA |
| ADR-009 | [Integrações e Webhooks](ADR-009-INTEGRATIONS.md) | APROVADA |
| ADR-010 | [Observabilidade e Auditoria Técnica](ADR-010-OBSERVABILITY.md) | APROVADA |
| ADR-011 | [Tratamento de Erros e Exceções](ADR-011-ERROR-HANDLING.md) | APROVADA |
| ADR-012 | [Logging e Correlation ID](ADR-012-LOGGING-CORRELATION.md) | APROVADA |
| ADR-013 | [Convenções de Código e Estrutura Modular](ADR-013-CODE-CONVENTIONS.md) | APROVADA |
| ADR-014 | [Limites Transacionais entre Módulos](ADR-014-TRANSACTION-BOUNDARIES.md) | APROVADA |
| ADR-015 | [Integração com wmatravel.com.br](ADR-015-WEBSITE-INTEGRATION.md) | APROVADA |

## Relação com a execução

A conclusão documental deste conjunto autoriza a certificação da ETAPA
2.0.1. A criação do backend real pertence à ETAPA 2.0.2 e deverá seguir
estas decisões.

## Continuidade da execução

A fundação 2.0 foi concluída e certificada após estas decisões. O status corrente da Fase 2 é mantido em
`../PHASE_2_EXECUTION_ORDER.md`; as etapas 2.1.1 a 2.1.3 também estão concluídas e a próxima etapa é a 2.1.4 —
Services do Core Corporativo.
