# Bike Tour — operação administrativa de retenção

> **Data:** 28/09/2026
> **Contrato:** B06-F4, revisão e compactação controlada
> **Escopo:** integração mínima, sem migration

## Comando manual

`POST /api/v1/biketour/operacoes/{identifier}/retencao` recebe o ID de uma operação Bike Tour.
Exige autenticação, `BIKE_TOUR_VISUALIZAR` e `BIKE_TOUR_GERENCIAR` explícitos.
GERENCIAR não concede OPERAR. Cada chamada avalia exatamente uma operação.

```json
{
  "chave_idempotencia": "revisao-administrativa-001",
  "versao_esperada": 1,
  "acao": "PRORROGAR",
  "motivo": "OPERACIONAL",
  "nova_data": "2027-09-28T12:00:00Z",
  "simular": false
}
```

A versão é a da operação avaliada. A simulação é o padrão e registra apenas a evidência administrativa;
ela não altera a operação avaliada nem efetiva preservação ou extensão.
Motivo usa os códigos já aprovados em A3; dados pessoais e campos extras não são aceitos.
O gestor identifica a operação pela consulta de auditoria do evento ou pelo inventário administrativo autorizado.

| Ação | Efeito efetivo |
| --- | --- |
| REVISAR | Registra avaliação; preserva o conteúdo; não concede extensão de prazo |
| PRESERVAR | Registra preservação expressa sem vencimento automático |
| LIBERAR_HOLD | Revoga somente a preservação expressa; não remove pendência ou extensão |
| PRORROGAR | Exige motivo e nova data futura; mantém preservação expressa existente |
| COMPACTAR | Compacta somente resposta elegível sem impedimento; mantém linha, hashes e IDs |

A decisão vigente é a última revisão efetiva do alvo, registrada em `operacao_bike_tour`.
Simulações não substituem decisões efetivas. O estado de preservação e a nova data são transportados
entre decisões, sem reinterpretar a ausência de um campo como revogação.
A nova data não dispara execução. O gestor deve iniciar uma nova revisão quando apropriado.

## Prazos e impedimentos

Chave/hash e vínculos são elegíveis após 365 dias do encerramento/cancelamento terminal identificável.
O marco é a operação auditada de transição terminal, não o fim planejado do evento.
Se o evento é terminal, mas não há operação que comprove o marco, registra-se impedimento.
Operação sem evento terminal identificável usa seu próprio `created_at`, conforme B06-F4.
A trilha técnica própria está representada pelas operações; decisões administrativas permanecem preservadas.

Pendência ABERTA, preservação expressa e extensão vigente impedem compactação.
Respostas com vínculos de evento e resultados compostos são conservadas integralmente, com impedimento explícito.
Esse tratamento mantém marcos terminais, histórico e integridade sem introduzir anonimização especulativa.
A resposta idempotente fica reproduzível por pelo menos 90 dias, inclusive se o marco de evento for anterior.

A compactação conserva IDs, status e versão disponíveis, além dos hashes, ator, correlação e identidade da linha.
Após compactação, replay da chave original retorna 409 `BT_RESPOSTA_COMPACTADA`, após autorização atual.
A chave nunca executa o comando original novamente. Não há exclusão física nem exclusão lógica por retenção.

## Transação e resultado

A UoW existente aplica lock `(2700, 1)`, READ COMMITTED, controle de versão e idempotência.
Decisão, eventual compactação e auditoria são atômicas. Falha em qualquer escrita provoca rollback.
Replay administrativo devolve a primeira resposta, sem duplicar a decisão.

O resultado contém ator, `correlation_id`, instante UTC, início/fim do período avaliado, motivo,
contagem elegível, processada, preservada e impedimentos. `processada` conta compactações efetivadas;
`preservada` conta respostas sem compactação nesta chamada. A própria revisão sempre fica registrada.
A resposta informa ainda a versão da operação, preservação expressa, nova data e estado de compactação.

Auditoria compartilhada conserva seus registros anteriores; triggers podem acrescentar a auditoria da nova ação.
Nenhuma tabela de Turismo, Comercial ou Financeiro é alterada pelo comando.
O procedimento corporativo de limpeza não é chamado. Não existem scheduler, cron ou purge automático.

## Evidências

- [Contrato aprovado](certification/PHASE_2_7_BIKE_TOUR_RETENTION_CONTRACT.md).
- [Controle B06](certification/PHASE_2_7_BIKE_TOUR_RETENTION_CONTROL.md).
- [Certificação B07](certification/PHASE_2_7_BIKE_TOUR_PHYSICAL_DATABASE.md).

<!-- cspell:ignore identifier retencao revisao versao esperada acao idempotencia operacao compactada -->
