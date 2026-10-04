# Bike Tour — Decisão de Implementação: Liberação de Alocações

## Status

APROVADO PARA IMPLEMENTAÇÃO

## Contexto

O gate documental da Etapa 2.7 estabelece que somente alocações
`BLOQUEADA` e `CONFIRMADA` participam da exclusão temporal de recursos.

Também estabelece que:

- expiração de bloqueio marca a alocação como `EXPIRADA`;
- cancelamento libera recursos ativos;
- `NO_SHOW` libera recursos ativos;
- conclusão libera recursos ativos;
- realocação libera a alocação de origem na mesma transação;
- estados terminais da inscrição não mantêm alocações ativas.

O desenho aprovado não definiu um estado persistido específico para a
liberação não causada por expiração.

Usar `EXPIRADA` para cancelamento, `NO_SHOW`, conclusão ou realocação
misturaria causas operacionais diferentes.

Manter a alocação como `CONFIRMADA` após sua liberação também seria
incompatível com a exclusion constraint, pois o recurso continuaria
ocupado temporalmente.

## Decisão

Adicionar `LIBERADA` como estado terminal técnico de
`alocacao_recurso_bike_tour`.

Estados persistidos da alocação:

- `BLOQUEADA`;
- `CONFIRMADA`;
- `EXPIRADA`;
- `LIBERADA`.

### Semântica

`BLOQUEADA`

Reserva temporária de recurso. Exige `expira_em`.

`CONFIRMADA`

Alocação operacional confirmada. Não possui `expira_em`.

`EXPIRADA`

Bloqueio temporário que perdeu validade por expiração. Não possui
`expira_em` após a transição terminal.

`LIBERADA`

Alocação anteriormente ativa que deixou de consumir o recurso por uma
ação operacional diferente de expiração, incluindo:

- cancelamento;
- `NO_SHOW`;
- conclusão;
- realocação.

`LIBERADA` não significa exclusão física do histórico.

## Exclusão temporal

A exclusion constraint continua considerando exclusivamente:

- `BLOQUEADA`;
- `CONFIRMADA`.

`EXPIRADA` e `LIBERADA` não bloqueiam reutilização temporal do recurso.

## Expiração

`expira_em` é obrigatório exclusivamente enquanto a alocação estiver
`BLOQUEADA`.

Para:

- `CONFIRMADA`;
- `EXPIRADA`;
- `LIBERADA`;

`expira_em` deve ser `NULL`.

## Auditoria

A transição para `LIBERADA` deve ocorrer dentro da mesma transação da
operação que causou a liberação e deve permanecer sujeita aos mecanismos
de auditoria e versionamento do módulo.

Nenhuma linha deve ser fisicamente removida para representar uma
liberação operacional normal.

## Compatibilidade com o gate

Esta decisão não altera:

- a máquina de estados da inscrição;
- a regra de capacidade de participantes;
- a unicidade evento/passageiro;
- a política de rebloqueio;
- a exclusão temporal de recursos ativos;
- a política de idempotência;
- a política transacional;
- o lock advisory global;
- as fronteiras Turismo/Bike Tour.

A decisão apenas torna explícita a representação persistida da liberação
de uma alocação que o gate já exige operacionalmente.

## Impacto de implementação

A migration posterior a `202609130300` deverá:

1. ampliar o CHECK de status da alocação para aceitar `LIBERADA`;
2. preservar a exclusion constraint somente para
   `BLOQUEADA`/`CONFIRMADA`;
3. preservar a regra de `expira_em`;
4. não reescrever dados existentes;
5. manter downgrade restrito ao delta Bike Tour.

A camada de domínio deverá impedir transições semânticas inválidas e
registrar a causa da operação por meio da auditoria/correlação da
operação Bike Tour.
