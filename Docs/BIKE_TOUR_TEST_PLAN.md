# Plano de Testes de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.7 — Plano de Testes (`BT-DOC-07`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento de Teste
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Estratégia

O plano de testes de Bike Tour exige evidência de modelagem, regras de negócio, concorrência, autorização e
integração com Turismo e Comercial. O plano deve ser revisado e aprovado antes da implementação.
Os testes unitários, de integração, de API e de migrations serão executados após a implementação autorizada.

## 2. Matriz mínima

| Área | Evidência |
| --- | --- |
| validação | período, capacidade, recursos, dados obrigatórios e chaves inválidas rejeitados |
| disponibilidade | saldo e bloqueios explicam a última bicicleta ou apoio disponível |
| concorrência | duas transações disputando o mesmo recurso produzem um vencedor e um rejeitado |
| idempotência | repetição do mesmo comando não cria nova alocação, reserva ou ocorrência |
| expiração | bloqueio vencido não confirma recurso e é liberado uma única vez |
| cancelamento | transição de evento ou inscrição libera capacidade conforme regra de negócio |
| autorização | leitura, operação e gestão exigem permissões distintas |
| eventos e auditoria | mutações sensíveis geram trilha e correlação |
| regressão | Ruff, mypy, pytest e OpenAPI sincronizados |
| migration | head linear, downgrade e upgrade revisados em ambiente descartável |

## 3. Ambientes e premissas

- usar PostgreSQL local descartável com banco final em `_test`;
- nenhuma execução em produção, homologação ou banco compartilhado;
- ausência de `WMA_DATABASE_URL` ou credenciais locais deve ser registrada como pendência e não tratada como
  sucesso;
- testes de integração devem operar em transações isoladas, sem persistir dados de teste em ambiente compartilhado;
- a evidencia de Bike Tour deve preservar a baseline de Turismo e Core sem reescrever objetos históricos.

## 4. Casos obrigatórios

| Caso | Resultado esperado |
| --- | --- |
| inscrição sem evento ou recurso válido | rejeitada |
| evento sem equipe ou apoio mínimo | rejeitado |
| ponto de controle fora de ordem | rejeitado |
| ocorrência sem gravidade ou contexto | rejeitada |
| inscrição duplicada para o mesmo recurso | rejeitada ou integrada por idempotência |
| duas reservas simultâneas da mesma bicicleta | somente uma permanece confirmada |
| bloqueio expirado | liberado uma vez e não recontado |
| cancelamento de evento | participantes e recursos rastreados para liberação |
| acesso sem permissão | 403 ou equivalente de segurança |
| consulta de participação sem vínculo válido | rejeitada com contexto explícito |
| ocorrência severa | preserva trilha e correlação |
| encerramento sem evento ativo | rejeitado |

## 5. Critério de aceite

O módulo deve ser aceito apenas quando:

1. todos os testes mínimos acima forem aprovados;
2. o conjunto de regressão do backend continuar íntegro;
3. o contrato OpenAPI não apresentar divergência funcional;
4. não houver conflito de head de migration;
5. não houver perda de dados, tabela ou objeto certificado pela baseline;
6. todas as ações de Bike Tour forem autorizadas por RBAC e auditadas;
7. o comportamento de concorrência e expiração for repetível em pós-validação.

## 6. Conclusão

O plano estabelece as evidências exigidas para a entrega funcional futura. A aprovação documental do plano
precede a implementação e não substitui a execução posterior dos testes nem a certificação da etapa.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.7 — Plano de Testes de Bike Tour |
| Entregável | `BT-DOC-07` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
