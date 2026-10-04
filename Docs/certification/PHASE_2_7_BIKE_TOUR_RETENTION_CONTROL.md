# Bike Tour — controle de retenção B06

## Estado da verificação

Data: 27/09/2026. Branch: `feature/2.7-bike-tour`.
HEAD: `ba45b3c1c544a05a6ed317445f31ba737c497919`.

`B06_CLASSIFICATION=BLOCKED_BY_CONTRACT`.
`B06_RETENTION_CONTROL=BLOCKED`. `T23=CONTROLLED_OPEN`.

Esta análise complementa a seção 6 da
[evidência B05](PHASE_2_7_BIKE_TOUR_TEST_EVIDENCE.md), cujo conteúdo foi preservado.
Não supersede a execução histórica de testes nem converte a política aprovada em execução certificada.
B05 permanece fechado conforme declaração expressa do responsável nesta execução.

## Contrato e categorias

Fontes: [A6](../BIKE_TOUR_SECURITY_PRIVACY.md), seção 3;
[A5](../BIKE_TOUR_TRANSACTION_POLICY.md), seção 3;
[T23](../BIKE_TOUR_TEST_PLAN.md), seção 2.

| Categoria | Marco e prazo | Tratamento autorizado |
| --- | --- | --- |
| Resposta idempotente mínima | Pelo menos 90 dias após a operação | Preservar resposta reproduzível; eventual compactação conserva resultado mínimo |
| Chave/hash e vínculos operacionais | 365 dias após encerramento/cancelamento | Revisão por gestor; retenção adicional com motivo e nova data |
| Trilha técnica nova do módulo | 365 dias | Revisão conforme política corporativa; auditoria compartilhada preservada |

O prazo de 365 dias não autoriza exclusão automática. Pendência de tratamento ou preservação expressa
suspende eliminação. A5 impede remover registros mínimos de operações enquanto o recurso aceitar comandos.
Repetição de chave conhecida nunca pode ser reinterpretada como comando novo.
Integridade referencial, histórico operacional, auditoria compartilhada e dados de Turismo, Comercial e
Financeiro devem permanecer preservados. A6 não reduz prazos corporativos.

## Mecanismos encontrados

- `Database/scripts/WmaTravelERP.sql`, procedimento `auditoria.sp_limpar_historico`:
  executa `DELETE FROM auditoria.execucao` filtrando apenas `data_inicio` por número de dias.
  Não restringe Bike Tour, não implementa preservação expressa e não atende ao contrato de B06.
  O procedimento não foi executado.
- `public.conformidade_lgpd.retencao_dias`: parâmetro cadastral; a tabela não registra decisão por evento,
  próxima revisão ou impedimento individual. Sua existência não comprova execução administrativa.
- `Backend/app/modules/biketour/uow.py`: infraestrutura reutilizável de permissão, ator, correlação,
  idempotência, lock e transação. Não possui comando de revisão de retenção.
- `Backend/app/modules/biketour/models.py`: `OperacaoBikeTour` persiste resultado, ator e correlação;
  `PendenciaBikeTour` representa tratamento externo, com tipos CANCELAMENTO, NO_SHOW e ENCERRAMENTO.
  Não equivale a um registro de preservação expressa ou prorrogação de retenção.
- `Backend/scripts/`: exportação e compatibilidade OpenAPI; nenhum comando administrativo de retenção.
- Os testes Bike Tour não apresentam teste específico de revisão administrativa T23.
  Limpeza de fixtures e expiração de alocações não são tratamento de retenção.

A busca considerou fontes atuais, documentos de domínio, scripts, migrations e testes.
Backups não foram usados como evidência. Não foi encontrado mecanismo específico que permita declarar
`EXISTING_MECHANISM_SUFFICIENT`. A infraestrutura transacional é reutilizável, mas sua existência não fecha T23.

## Ambiguidade que impede implementação

Os documentos não se contradizem sobre proibição de exclusão automática. A ambiguidade é de abrangência
e representação da revisão exigida; não há autorização para escolher silenciosamente seu significado.

1. A6, seção 3, exige motivo/nova data e preservação expressa. A3
   ([rastreabilidade](../BIKE_TOUR_TRACEABILITY_MATRIX.md), seções 2 e 3) não define operação ou payload
   para essa revisão. A8 ([schema](../BIKE_TOUR_SCHEMA_DECISION.md), seções 2 e 9) não define seu registro.
2. A6 inclui chave/hash e vínculos após encerramento/cancelamento, mas A3 também contempla operações de
   produto/recurso sem evento. Falta definir a unidade de revisão dessas operações sem evento terminal.
3. A6 distingue trilha técnica nova e auditoria compartilhada. A8 exige triggers corporativos nas tabelas
   novas; a delimitação da categoria técnica sujeita a revisão não está explicitada por objeto.

São lacunas entre os contratos citados, não evidência de defeito no código existente.
T23 exige demonstração administrativa; documentação da política, isoladamente, não atende à seção 6 do B05.
Não é possível decidir de forma conclusiva entre integração, comando novo ou migration antes dessa definição.

## Proposta submetida para esclarecimento

Revisão administrativa por evento, sem exclusão nem anonimização, persistindo a decisão em
`operacao_bike_tour` pela UoW existente. Exigir VISUALIZAR e GERENCIAR, ator autenticado,
`correlation_id`, motivo, data da próxima revisão e resultado determinístico.
Preservar integralmente a auditoria compartilhada. A data futura não dispara execução automática.

A proposta depende de definição do responsável sobre seu escopo, incluindo operações sem evento e trilha
técnica. Não constitui contrato aprovado nem implementação. A consulta foi apresentada durante a execução.
Retenção adicional e impedimentos não foram registrados ficticiamente como decisões administrativas reais.

## Validação e limites

Nenhum código, rota, schema, migration ou teste foi criado ou modificado nesta análise.
Não houve acesso ao PostgreSQL, execução de limpeza, scheduler ou expurgo automático.
Não há nova operação cuja autorização, rollback ou idempotência possam ser declarados testados.
Os gates estáticos e testes existentes verificam regressão; não substituem a evidência administrativa T23.

Para fechar B06: esclarecer o contrato acima, classificar novamente, implementar somente a lacuna confirmada
e demonstrar execução administrativa com preservação de dados, RBAC e rollback conforme aplicável.
Se houver implementação PostgreSQL, os testes físicos devem usar `wma_phase2_test`.

## Implementação de 28/09/2026 — B06-F4

O contrato aprovado em [B06-F4](PHASE_2_7_BIKE_TOUR_RETENTION_CONTRACT.md) supersede a ambiguidade
registrada acima. O diagnóstico anterior permanece como histórico.
A presente implementação não altera o documento B05 nem as evidências históricas de T23.

`B06_CLASSIFICATION=MINIMAL_INTEGRATION_REQUIRED`.

A lacuna comprovada era a ausência de ação administrativa que aplicasse o contrato.
A tabela de operações e a UoW existentes comportam a decisão auditável sem nova tabela ou migration.
O procedimento genérico de limpeza permanece inadequado e não foi reutilizado.

### Desenho físico mínimo

Foi acrescentado `POST /api/v1/biketour/operacoes/{identifier}/retencao`, com resposta tipada.
Cada chamada avalia uma operação. Exige autenticação, VISUALIZAR e GERENCIAR explícitos,
motivo enumerado, versão esperada e chave idempotente. Não há concessão implícita de OPERAR.

A UoW mantém lock transacional, ator, correlação, resposta determinística e rollback integral.
A decisão é uma nova linha de `operacao_bike_tour`, com operação `revisar_retencao` e alvo avaliado.
Seu resultado preserva período, motivo, contagens, impedimentos, preservação expressa e próxima revisão.
Não se reutiliza pendência de outro domínio como armazenamento administrativo.
A última decisão efetiva define a preservação e a extensão; simulações não substituem esse estado.

A simulação é padrão e registra somente sua evidência, sem modificar o alvo.
A revisão efetiva incrementa a versão do alvo. A própria evidência administrativa não é compactável.
O [procedimento operacional](../BIKE_TOUR_RETENTION_OPERATIONS.md) descreve ações e payload.

### Categorias, preservação e compactação

- Operação vinculada a evento terminal: 365 dias contados da operação auditada de encerramento/cancelamento.
- Evento terminal sem marco verificável: impedimento expresso, sem compactação.
- Operação sem evento terminal identificável: 365 dias a partir de seu próprio `created_at`.
- Replay: resultado reproduzível por pelo menos 90 dias após a operação.
- Pendência ABERTA: preserva os registros necessários ao tratamento.
- Preservação expressa: permanece até liberação administrativa explícita.
- Extensão: exige motivo e data futura; não revoga preservação expressa.
- Resposta ligada a evento ou resultado composto: preservada integralmente, com impedimento registrado.
- Resposta independente elegível: compactação mantém IDs, status, versão, linha, hashes e identidade técnica.
- Chave compactada: retorna 409 no replay autorizado; nunca executa novamente a intenção original.

O mecanismo não altera vínculos operacionais, não remove linhas e não executa anonimização.
Auditoria compartilhada conserva todas as linhas anteriores; triggers registram a nova ação.
Turismo, Comercial e Financeiro não recebem escritas pelo comando.
Não há scheduler, cron, serviço em segundo plano ou purge automático.

### Arquivos da integração

- `Backend/app/modules/biketour/retention.py`: critérios e decisão administrativa.
- `Backend/app/modules/biketour/retention_router.py`: rota administrativa tipada.
- `Backend/app/modules/biketour/router.py`: inclusão da rota.
- `Backend/app/modules/biketour/uow.py`: replay de resposta compactada retorna 409.
- `Backend/tests/test_biketour_retention.py`: contratos, prazos, impedimentos e autorização.
- `Backend/tests/integration/test_biketour_retention_postgresql.py`: prova física T23.
- `Backend/openapi.json`: rota e dois schemas novos.
- `Docs/BIKE_TOUR_RETENTION_OPERATIONS.md`: procedimento administrativo.

Não foram modificados os testes protegidos de API operacional e UoW PostgreSQL.
O snapshot anterior foi verificado antes da alteração autorizada.
Removendo exclusivamente a rota nova e seus dois schemas, a geração do OpenAPI reproduz exatamente
o SHA-256 certificado `5154DDD7D5C717A49D7756D7F31127344D26A02A9FEE93A9A89063667BBB00AE`.
Isso comprova ausência de alteração nos contratos anteriores, inclusive Turismo, Comercial e Financeiro.

A comparação OpenAPI com HEAD registra uma diferença preexistente em disponibilidade de Turismo.
O resultado não foi ocultado: o HEAD não contém toda a baseline local certificada fornecida para este gate.
A verificação exata pelo hash anterior isola a adição de B06.

### Lacuna comprovada na regressão operacional

A regressão PostgreSQL encontrou uma falha anterior à integração de retenção:
`InscricaoResponse` exige `origem_valida`, mas a projeção de comandos não produzia esse campo.
O teste existente `test_fluxo_operacional_http_com_postgresql_e_rollback` falhou com
`ResponseValidationError` no bloqueio de inscrição. Resultado da primeira regressão: 121 aprovados e uma falha.

Após backup local, `operations.py` foi corrigido para produzir o campo segundo a validação de origem existente.
Origem incompatível resulta em falso; indisponibilidade continua sendo erro, sem ser apresentada como origem inválida.
Não se mudou schema, contrato externo ou expectativa do teste PostgreSQL existente.
O teste novo `test_biketour_inscription_projection.py` cobre origem válida, incompatível e indisponível.
A correção é registrada separadamente para não atribuir a B06 uma regressão que já existia no produtor da resposta.

---

## Fechamento B06 — Retention Control / T23

**Status:** PASS — FECHADO

O B06 certifica o mecanismo administrativo de retenção do módulo Bike Tour.

Evidências de fechamento:

- política de retenção de 365 dias;
- replay idempotente completo preservado por no mínimo 90 dias;
- ações administrativas `REVISAR`, `PRESERVAR`, `LIBERAR_HOLD`, `PRORROGAR` e `COMPACTAR`;
- preservação de tombstone, hashes, identidade da operação e trilha técnica;
- ausência de purge, scheduler, cron ou exclusão física automática;
- autorização administrativa por `BIKE_TOUR_GERENCIAR`;
- rota `POST /api/v1/biketour/operacoes/{identifier}/retencao`;
- `operationId=biketour_revisar_retencao`;
- testes unitários de retenção;
- testes HTTP de autenticação e autorização;
- prova física PostgreSQL de prazos, compactação, replay, hold, rollback, evento terminal e pendência;
- regressão não PostgreSQL: 910 testes aprovados;
- cobertura global: 100%;
- regressão PostgreSQL: 122 testes aprovados;
- OpenAPI sincronizado e sem `operationId` duplicado;
- teste PostgreSQL de retenção registrado no workflow oficial.

O mecanismo não exclui fisicamente `operacao_bike_tour`, não remove auditoria compartilhada
e não altera objetos pertencentes a Turismo, Comercial ou Financeiro.

O documento B05 permanece imutável. A indicação histórica de T23 como aberto no B05 representa
o estado existente quando o B05 foi certificado. O fechamento posterior de T23 é registrado neste B06.

`B06=PASS`

`T23=PASS`

O fechamento do B06 é independente do B07/T24. O B07 permanece aberto para a certificação física e reprodutível do banco.

---
