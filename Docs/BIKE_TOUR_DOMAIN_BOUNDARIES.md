# Fronteiras e Integrações de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-04`)
> **Tipo:** Documento técnico e funcional
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

A4 foi aprovado e aceito em 11/09/2026; a autorização global de implementação permanece controlada pelo gate documental.
A1 permanece aceito no commit `f94f421`. Vaner confirmou em 10/09/2026 a reutilização de reserva e passageiro,
com um evento por saída. As demais escolhas abaixo são propostas concretas para revisão do responsável.

## 1. Autoridades e cardinalidades

| Origem | Relação proposta | Autoridade de escrita |
| --- | --- | --- |
| produto_turistico | 1 → 0..1 produto_bike_tour | Turismo escreve catálogo; Bike Tour escreve atributos da modalidade |
| saida_turistica | 1 → 0..1 evento_bike_tour | Turismo escreve saída; Bike Tour escreve operação especializada |
| reserva | 1 → N passageiro → N inscrições em eventos compatíveis | Turismo mantém reserva e passageiro |
| evento e passageiro | Uma inscrição por par, inclusive após cancelamento | Bike Tour escreve somente vínculo e estado operacional |
| reserva_correlacao | Zero ou uma correlação da reserva | Turismo valida a origem; Comercial mantém venda/item/contrato |
| ativo_imobilizado, guia_turistico, transporte | Zero ou uma referência por recurso especializado | Domínio proprietário mantém cadastro; Bike Tour mantém disponibilidade |
| Financeiro | Pendência operacional referenciada por inscrição | Financeiro decide título, pagamento, estorno e conciliação |

Schema físico não transfere autoridade. Nenhum serviço Bike Tour importa model ou repository privado de outro módulo.
Nenhuma inscrição cria reserva, passageiro, venda, contrato ou lançamento financeiro.

## 2. Contratos existentes e lacunas concretas

Fontes verificadas: `Backend/app/modules/turismo/router.py`, `services.py`, `models.py`,
`Backend/app/shared/clientes.py`, `Backend/app/shared/vendas.py` e `Backend/openapi.json`.

| Capacidade | Estado observado | Uso na 2.7 |
| --- | --- | --- |
| Criar saída, reservar, confirmar/cancelar reserva e consultar vagas | Implementados em Turismo | Fluxos existentes, separados do comando Bike Tour |
| Ler passageiro e sua reserva por contrato público interno | Não encontrado no contrato atual | Contrato aditivo necessário, implementado pelo proprietário Turismo |
| Ler produto, saída e origem comercial como projeção mínima | Models existem; contrato Bike Tour ainda ausente | Porta pública interna nova, sem retornar objetos ORM |
| Validar guia, transporte e patrimônio | Tabelas existentes não equivalem a contrato público | Adaptadores no domínio proprietário; sem SQL privado no consumidor |
| Portas cadastrais e comerciais compartilhadas | Exemplos existentes em app/shared | Reutilizar padrão de projeções, não presumir métodos ausentes |

As lacunas são tarefas da implementação posterior ao aceite do desenho; não são interfaces já entregues.
Não criar novo endpoint de cadastro turístico apenas para contornar a ausência de contrato interno.

## 3. Portas propostas, versão 1

Cada porta recebe ator, finalidade e unidade de trabalho do chamador. Retorna projeção imutável,
resultado AUSENTE, INCOMPATIVEL ou INDISPONIVEL. Sem commit, envio de rede ou retorno de ORM.

| Porta | Entrada | Projeção mínima |
| --- | --- | --- |
| ContextoSaida | id_saida; proteger leitura quando houver mutação | id_saida, id_pacote, id_produto, tipo, ativo, datas, capacidade, status, versão |
| ContextoInscricao | id_saida, id_reserva, id_passageiro | Pertencimento, status/versão da reserva, quantidade, bloqueio turístico e validade |
| OrigemReserva | id_reserva | id_venda, id_item_venda, id_contrato opcionais e validade da correlação |
| RecursoOrigem | tipo e identificador | Identificador, tipo, existência e situação operacional permitida |

ContextoInscricao aceita leitura protegida: Turismo bloqueia saída → reserva → passageiro em ordem estável,
dentro da sessão recebida, sem escrever estado ou fazer commit. Bike Tour valida e escreve somente suas tabelas.
A porta deve rejeitar passageiro que não pertença à reserva e reserva sem saída integrada.
Criar passageiro, quando necessário, continua sendo operação de Turismo sob sua autorização própria.

Os serviços atuais de confirmação de Turismo fazem commit. Não podem ser chamados dentro da unidade atômica
Bike Tour como se participassem dela. O novo contrato de leitura é independente desses serviços.

## 4. Concorrência entre domínios

O bloqueio de leitura protege a decisão durante o comando Bike Tour; não impede cancelamento turístico posterior.
Depois de cancelamento na origem, o estado Bike Tour pode aguardar reconciliação, mas não pode autorizar operação:
confirmação, início e presença revalidam a origem pela porta pública e rejeitam estado incompatível.
A consulta apresenta `origem_valida=false`; nunca declara reserva turística confirmada por inferência local.

Reconciliação explícita é comando de operação, em lotes limitados por evento, sem scheduler nesta entrega.
Ela cancela inscrições inválidas e libera recursos na transação local. Se a origem estiver indisponível,
retorna 503 e não libera recursos por suposição. Corridas entre reconciliação e confirmação usam os mesmos locks.

## 5. Comercial e Financeiro

A correlação é derivada da reserva; Bike Tour não mantém uma segunda correlação comercial como autoridade.
Sem correlação comercial é permitido; identificador presente e inválido é rejeitado. Não há condição de pagamento
inferida por leitura direta de tabela financeira. O cliente não pode enviar nova venda/contrato na inscrição.

Cancelamento, no-show e encerramento com impacto potencial geram `pendencia_bike_tour` única por operação e tipo.
A pendência contém IDs e código de motivo; operador autorizado registra a referência do tratamento externo.
Nenhum comando Bike Tour cria, liquida ou estorna título. A baixa da pendência não equivale a pagamento confirmado.
Essa recuperação explícita evita perda silenciosa de intenção sem exigir fila externa ou scheduler.

## 6. Compatibilidade e decisões

Aplicar ADR-014 a transações locais e preservar as autoridades de TOURISM_DOMAIN_BOUNDARIES.md.
Compartilhar uma sessão para leitura protegida não autoriza escrita em outro domínio nem commit distribuído.
[ADR-020](architecture/ADR-020-BIKE-TOUR-DOCUMENTARY-DESIGN.md) registra a proposta e suas alternativas.
Aprovar A4 significa aceitar esse desenho e suas tarefas de integração; não certificar sua implementação.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-04, versão 1.1 |
| Última atualização | 10/09/2026 |
| Responsável pelo aceite | Vaner |
| Evidência de aceite | Aceite formal registrado em 11/09/2026 após auditoria semântica e gates documentais aprovados |
| Implementação | Documento aceito; autorização global controlada pelo gate documental |

<!-- cspell:ignore CONCLUIDO EXECUCAO MANUTENCAO DISPONIVEL inscricao inscricoes ocorrencia ocorrencias -->
<!-- cspell:ignore logistica alocacao alocacoes correlacao reacomodacao reconciliacao permissao -->
<!-- cspell:ignore idempotencia versao obrigatorio disponivel proposta bike btree gist tstzrange offset -->

<!-- cspell:ignore INCOMPATIVEL INDISPONIVEL -->
