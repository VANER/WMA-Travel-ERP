# ADR-021 — Reprogramação de Execução da Fase 2

**Status:** ACEITA PARA REPROGRAMAÇÃO DOCUMENTAL

**Data:** 19/10/2026

## Contexto

A 2.7 — Bike Tour foi concluída, certificada e integrada. A preparação da integração do Website (2.8) depende de
inventário externo, homologação e confirmação de contratos ainda pendentes. O inventário fiscal 2.9.1 pode começar
por inspeção documental estática, sem depender de acesso ao site nem alterar código ou banco.

## Decisão

1. Manter a etapa 2.7 como concluída, certificada e integrada.
2. Colocar temporariamente a execução da etapa 2.8 em HOLD.
3. Iniciar a etapa 2.9 pela atividade documental 2.9.1 — Inventário Fiscal.
4. Manter a sequência numérica 2.8 antes de 2.9, conforme ADR-017; a prioridade de trabalho não renumera etapas.
5. Preservar as etapas 2.10 a 2.14 como planejadas e manter suas dependências declaradas.
6. Não considerar a 2.9.1 concluída, certificada ou implementada por este inventário.

## Critérios para retomada da 2.8

Retomar o trabalho de integração somente após registrar e validar:

- acesso autorizado ao ambiente de homologação e seus limites;
- inventário do site, versão, plugins, campos personalizados e responsáveis externos;
- contratos e mapeamentos de dados entre site e ERP, incluindo autoridade de cada domínio;
- fluxo comercial, reservas, pagamentos, cancelamentos e webhooks, com idempotência e reconciliação;
- autenticação, gestão segura de credenciais, proteção de dados e evidências sanitizadas;
- critérios de aceite e disponibilidade dos responsáveis para validar os cenários integrados.

A implantação ou teste de escrita em produção exige autorização e gate próprios.

## Dependências e cronograma

A dependência da 2.9 em relação às etapas 2.3–2.5 permanece. O início de um inventário estático não libera
implementação que dependa de Comercial ou Financeiro nem certifica essas dependências. A 2.10 mantém sua relação
com módulos operacionais; 2.11 continua dependente dos módulos operacionais; 2.12 é transversal; 2.13 depende do
conjunto funcional; e 2.14 depende da conclusão de 2.13, conforme a ordem oficial. O HOLD pode deslocar a duração
duração de calendário da 2.8 e das etapas dependentes; as estimativas existentes são mantidas até replanejamento aprovado.

## Restrições para certificação final

A certificação da Fase 2 não pode declarar integração Website concluída enquanto a 2.8 não satisfizer seu gate.
Não se pode tratar a 2.9.1 como conclusão da 2.9; o módulo Fiscal e suas dependências devem satisfazer critérios
próprios. A etapa 2.14 permanece condicionada à qualidade/hardening 2.13 e à conclusão dos módulos requeridos.

## Consequências

- Roadmap e ordem executiva registram o HOLD da 2.8 e a atividade corrente 2.9.1.
- A sequência oficial e o histórico da ADR-017 permanecem intactos.
- O cronograma não recebe nova estimativa enquanto as pendências externas e dependências não forem reavaliadas.
- Esta decisão é documental; não autoriza código, migrations, consulta ou alteração de banco.

## Reavaliação

Reavaliar o HOLD quando todos os critérios de retomada forem evidenciados, ou se houver mudança de escopo,
contratos, dependências ou cronograma que justifique nova decisão arquitetural.

## Relações

- [ADR-017 — Reprogramação Funcional da Fase 2](ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md).
- [Roadmap da Fase 2](../PHASE_2_ROADMAP.md).
- [Ordem de execução](../PHASE_2_EXECUTION_ORDER.md).
- [Preparação da integração Website](../WEBSITE_INTEGRATION_PREPARATION.md).
- [Gate do inventário fiscal 2.9.1](../FISCAL_2_9_1_GATE.md).

---

Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.
