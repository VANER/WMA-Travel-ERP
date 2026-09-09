# Módulo Turismo

> **Etapa:** 2.6 — Turismo
> **Data:** 05/09/2026
> **Status:** CONCLUÍDA, CERTIFICADA E INTEGRADA

## Escopo implementado

O módulo integra as estruturas legadas de Turismo e adiciona saída operacional, controle transacional de vagas e
correlação Comercial. A API sob `/api/v1/turismo` permite listar e criar saídas, consultar disponibilidade e criar,
confirmar ou cancelar reservas com RBAC.

## Arquitetura

```text
Router -> Schema -> Service -> Repository -> Model -> PostgreSQL
```

Turismo não grava fatos de Core, Comercial ou Financeiro. A migration aditiva `202609050100` preserva a baseline e
mantém um único head Alembic.

## Validação

Os gates obrigatórios são Ruff, Ruff Format, mypy strict, pytest com warnings como erro e cobertura de 100%,
OpenAPI sincronizado e integração PostgreSQL opt-in.

## Hardening complementar da 2.6

A revisão `202609080100` acrescenta constraints de quantidade e valor, unicidade de alocação por reserva,
índice de ocupação por saída/status/expiração e coerência de estado verificada no commit. Valores totais nulos
continuam admitidos pelo legado; valores negativos são recusados. Dados existentes incompatíveis interrompem
a migration, sem correção automática.

A confirmação e o cancelamento persistem a resposta original em `reserva_operacao`, na mesma transação da
reserva e da alocação. O escopo é usuário autenticado, reserva, operação e chave; chamadas internas sem usuário
usam escopo próprio. A repetição retorna o snapshot original mesmo após uma transição posterior, sem executar
a ação novamente. Chave nova passa pelas regras do estado atual. As ações não possuem outro conteúdo mutável;
confirmar e cancelar são operações distintas. Não há expurgo automático dos snapshots nesta etapa.

Recursos ausentes retornam `404`, capacidade/estado incompatível retornam `409`, entrada inválida retorna `422`
e autenticação/autorização permanecem em `401/403`. As permissões são revalidadas antes de qualquer repetição.
Venda, item e contrato são consultados antes da escrita; item requer venda e deve pertencer a ela. Quando venda
e contrato são fornecidos juntos, devem corresponder. Criar reserva sem correlação continua permitido.

Todas as mutações de vagas adquirem locks na ordem saída, reserva, alocação. A criação, inclusive os flushes
intermediários, é revertida integralmente em falhas. O resultado concorrente perdedor não persiste reserva,
alocação ou correlação parcial.

### Expiração de bloqueios

A ocupação ignora bloqueios cujo prazo UTC venceu, mesmo que ainda estejam fisicamente `BLOQUEADA`.
Consultas de disponibilidade são somente leitura. A rotina interna `expirar_bloqueios(session, id_saida)`
é executável pela manutenção operacional do backend, sob lock da saída; materializa `BLOQUEADA → EXPIRADA`
em transação própria e pode ser repetida. Ela mantém `expira_em` e a reserva `PENDENTE`, preservando o histórico.
Os triggers de auditoria de `alocacao_vaga` registram a transição quando a transação confirma. A rotina deve
usar a identidade de manutenção configurada no banco. Nenhum scheduler ou endpoint novo foi introduzido;
até a execução da rotina, a expiração lógica garante a disponibilidade correta. Um job futuro poderá chamar
a mesma rotina, com identidade e frequência definidas em escopo próprio.

A certificação complementar está em `Docs/certification/PHASE_2_6_TOURISM_HARDENING.md`.
A certificação original da 2.6 permanece histórica e não foi modificada.
