# Política Transacional de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-05`)
> **Tipo:** Documento técnico
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

A1 permanece aceito e A5 foi aprovado e aceito em 11/09/2026; a autorização global permanece controlada pelo gate.
As relações reserva/passageiro e um evento por saída foram confirmadas por Vaner em 10/09/2026.
As demais decisões são propostas para revisão conjunta com BT-DOC-02 a BT-DOC-08.

## 1. Unidade de trabalho e isolamento

Todo comando mutável tem uma única transação PostgreSQL READ COMMITTED, controlada pelo caso de uso.
Repositories não fazem commit. O adaptador do domínio de origem apenas lê projeções com bloqueio quando necessário.
Nenhuma chamada SMTP, HTTP externo ou mutação financeira ocorre dentro dessa transação.

Ordem proposta para a primeira versão:

1. adquirir lock transacional consultivo exclusivo do módulo, chave reservada `(2700, 1)`;
2. autenticar/autorização já realizada; consultar replay e proteger a linha da operação;
3. obter projeções turísticas protegidas: saídas e reservas em ordem crescente, depois passageiros;
4. bloquear recursos, eventos, inscrições e alocações em ordem crescente dentro de cada conjunto;
5. expirar bloqueios elegíveis, validar, aplicar todas as escritas, gravar resultado e auditoria;
6. confirmar uma vez; qualquer falha provoca rollback integral.

O lock consultivo serializa mutações Bike Tour, inclusive entre eventos, e dura até commit/rollback.
É uma escolha conservadora para evitar ciclos na limpeza de alocações de outros eventos; não é lock em memória.
O custo é limitar vazão de escrita do módulo. Sua substituição por locks granulares exige ADR e regressão de corrida.
Leituras não adquirem o lock global. Writes fora do service continuam protegidos por FKs, checks e exclusão temporal.
Lock timeout limitado a 5 segundos; contenção retorna 409 e resultado não é registrado como sucesso.

## 2. Capacidade e recursos

Participantes comprometidos = PENDENTE com bloqueio válido + CONFIRMADA + PRESENTE.
CONCLUIDA, CANCELADA, EXPIRADA e NO_SHOW não consomem capacidade operacional e não mantêm alocações ativas.
Esse total não excede a capacidade do evento nem a quantidade de passageiros elegíveis por reserva.
A capacidade turística não é consumida novamente. Cada recurso individual tem capacidade um por intervalo.
Guia e veículo de apoio usam alocação do evento; bicicleta e equipamento pessoal usam alocação da inscrição.

Proteção de sobreposição: exclusão GiST por recurso e intervalo `[inicio, fim)`, para BLOQUEADA ou CONFIRMADA.
A restrição não usa o relógio em seu predicado. Bloqueio vencido ainda ativo é primeiro marcado EXPIRADA sob lock;
só então nova alocação é inserida. Isso impede conflito artificial de índice sem aceitar sobreposição real.
Recursos em manutenção não recebem bloqueio. Inativação/manutenção com alocação ativa retorna 409.

## 3. Idempotência observável

Todos os POST/PATCH recebem `chave_idempotencia` opaca, 1 a 100 caracteres.
Alterações de recursos existentes também exigem `versao_esperada` inteira >=1;
idempotência não substitui controle otimista de versão.
Escopo único = ator autenticado + operação + alvo; para criação o alvo é zero e o tipo da operação diferencia recursos.
Persistir hash SHA-256 da chave e do payload canônico, IDs, status HTTP e corpo mínimo da resposta.
Corpo canônico inclui ação, parâmetros, referências e versão esperada; exclui a própria chave e correlation_id.

| Requisição | Resultado |
| --- | --- |
| Mesma chave e mesmo payload | Mesmo status HTTP e corpo de negócio; sem nova auditoria funcional |
| Mesma chave com payload diferente | 409; nenhuma alteração |
| Repetição concorrente | Aguarda transação vencedora; retorna sua resposta persistida |
| Falha antes do commit | Nenhuma operação bem-sucedida registrada; nova tentativa pode executar |
| Nova chave com intenção duplicada | Unicidade de negócio e versão esperada continuam valendo |
| Replay após perda da permissão | 401/403 antes de ler a resposta persistida |

O correlation_id do envelope de erro/headers pode mudar por requisição; resultado funcional não muda.
Garantia de replay por pelo menos 90 dias após a operação. Após esse prazo, manter registro mínimo e rejeitar 409
se não houver resposta preservada; nunca reinterpretar a chave conhecida como comando novo.
Limpeza não remove tombstones de operações enquanto o recurso puder receber novos comandos.

## 4. Ciclo de vida dos bloqueios

Criar inscrição gera PENDENTE e uma alocação BLOQUEADA por 15 minutos, limitada ao início do evento e à validade
A inscrição é única por evento e passageiro. Em rebloqueio elegível, reutilizar a mesma inscrição, incrementar
sua versão e criar somente as novas alocações necessárias; não inserir segunda inscrição.
restante de eventual bloqueio turístico. Validade não positiva retorna 409. Confirmar exige reserva CONFIRMADA.
Confirmar converte a mesma alocação para CONFIRMADA; não cria segundo consumo.
Expiração marca alocação EXPIRADA e inscrição EXPIRADA na mesma transação, sem alterar a reserva de Turismo.
Cancelamento libera alocações ativas, preserva inscrições e grava pendência operacional quando aplicável.

Quem executa: serviço de comando realiza limpeza antes de calcular capacidade para mutação; operador também pode
invocar expiração/reconciliação explícita. GET calcula saldo lógico, não altera banco e não gera auditoria de limpeza.
Não há scheduler. Expiração física atrasada não permite confirmação de bloqueio logicamente vencido.

## 5. Atomicidade dos comandos compostos

| Comando | Unidade indivisível |
| --- | --- |
| Criar bloqueio | Inscrição, alocações, versão, resposta idempotente e auditoria |
| Confirmar | Estado da inscrição, alocações confirmadas e resposta |
| Cancelar inscrição | Estado terminal, liberação, pendência de origem, resposta e auditoria |
| Reacomodar recursos | Validar destino, criar alocação destino, liberar origem e registrar vínculo |
| Cancelar evento | Inscrições, apoio, recursos liberados e pendências, sem sucesso parcial |
| Encerrar evento | Validar resultados finais, liberar apoio, estado final e resumo auditado |
| Reconciliar origem | Validar origem acessível; cancelar vínculos inválidos e liberar recursos |

Lote de reconciliação tem limite 100 inscrições; cursor explícito. Cada lote é atômico e reporta se há mais itens.
Cancelamento de evento não usa sucesso parcial: o comando inteiro é atômico, com limite operacional de 1000 inscrições
por evento nesta proposta. Acima desse limite a criação/configuração retorna 422, antes de iniciar a operação.

## 6. Falhas e origem turística

Após commit Bike Tour, Turismo pode cancelar uma reserva. O vínculo fica inelegível para operação até reconciliação;
leituras indicam origem inválida e os comandos críticos a revalidam. Não há promessa de sincronização imediata.
Se a origem estiver indisponível, retornar 503 e preservar recursos, nunca tratar indisponibilidade como cancelamento.

Consequências comerciais/financeiras são pendências com IDs, tipo e estado ABERTA/TRATADA, sem chamada externa.
Gestor registra referência do tratamento na autoridade de origem. Reexecução não duplica pendência nem fato externo.
Erro inesperado ou falha de auditoria reverte tudo e retorna envelope 500 sem detalhes internos.

## 7. Validação obrigatória

BT-DOC-07 exige duas conexões PostgreSQL, corrida pela última bicicleta e entre eventos distintos,
confirmação contra cancelamento, rollback após inscrição/alocação/pendência, replay e falha da origem.
Não considerar testes sequenciais ou SQLite evidência de concorrência real.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-05, versão 1.1 |
| Última atualização | 10/09/2026 |
| Aceite | Vaner, 11/09/2026; auditoria semântica e gates documentais aprovados |
| Implementação | Documento aceito; autorização global controlada pelo gate documental |

<!-- cspell:ignore CONCLUIDO EXECUCAO MANUTENCAO DISPONIVEL inscricao inscricoes ocorrencia ocorrencias -->
<!-- cspell:ignore logistica alocacao alocacoes correlacao reacomodacao reconciliacao permissao -->
<!-- cspell:ignore idempotencia versao obrigatorio disponivel btree gist tstzrange GiST gist idempotente -->
<!-- cspell:ignore payloads timestamp timestamptz -->
<!-- cspell:ignore rebloqueio -->
<!-- cspell:ignore CONCLUIDA -->
