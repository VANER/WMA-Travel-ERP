# Contratos e Rastreabilidade de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-03`)
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

Este documento é uma proposta revisável, não aprovação de A3 ou autorização de código.
O aceite de A1 permanece restrito ao inventário do commit `f94f421`.

## 1. Convenções do contrato proposto

Prefixo `/api/v1/biketour`. IDs positivos; nomes `{id}` se referem ao recurso pai do caminho.
GET de lista usa offset >=0 e limite 1..100, padrão 20, ordenação por ID crescente, resposta lista de projeções.
Toda mutação POST ou PATCH exige `chave_idempotencia` opaca.
Alteração de recurso existente também exige `versao_esperada` inteira >=1.
A chave de idempotência não substitui o controle otimista de versão.
Toda mutação retorna o recurso atualizado com ID, status quando houver, versao e created_at/updated_at.
Campos extras são rejeitados com 422; null somente para campos explicitamente opcionais.

Legenda: V = BIKE_TOUR_VISUALIZAR; O = V + BIKE_TOUR_OPERAR; G = V + BIKE_TOUR_GERENCIAR.
Todas as rotas: 401/403 para autenticação/autorização, 422 para validação, 503 para dependência indisponível,
500 para falha inesperada. Rotas por ID ou referência podem retornar 404. Mutações podem retornar 409.
Não criar novo envelope de erro: usar `ErrorResponse` de `Backend/app/core/schemas.py`.
Preservar os códigos globais atuais; não prometer subcódigos de domínio que o handler ainda não implementa.

## 2. Operações, dados e rastreabilidade

GETs retornam somente os campos do recurso descritos na seção 3, nunca ORM ou dados pessoais de origem.
Cada POST tem operationId único, prefixado por `biketour_` mais o identificador da operação abaixo.
Cada GET usa prefixo `biketour_consultar_` ou `biketour_listar_`, mais seu recurso, sem colisão.

| Operação | Método e caminho relativo | Entrada | Sucesso | Acesso | BT-REQ / teste |
| --- | --- | --- | --- | --- | --- |
| criar_produto | POST /produtos | Produto | 201 Produto | G | 001 / T01 |
| listar_produtos | GET /produtos | Paginação | 200 lista | V | 001 / T01 |
| alterar_produto | PATCH /produtos/{id} | Atributos ou ativo; versão/chave | 200 Produto | G | 001 / T01 |
| criar_evento | POST /eventos | Evento | 201 Evento PLANEJADO | G | 002 / T02 |
| listar_eventos | GET /eventos | Paginação | 200 lista | V | 002 / T02 |
| consultar_evento | GET /eventos/{id} | ID | 200 Evento | V | 002 / T02 |
| alterar_evento | PATCH /eventos/{id} | Período/capacidade; versão/chave | 200 Evento | G | 002 / T02 |
| acao_evento | POST /eventos/{id}/acoes | ABRIR, INICIAR, CANCELAR ou CONCLUIR; motivo | 200 Evento | G | 002,012 / T02,T12 |
| criar_recurso | POST /recursos | Recurso | 201 Recurso | G | 003 / T03 |
| listar_recursos | GET /recursos | Paginação | 200 lista | V | 003 / T03 |
| alterar_recurso | PATCH /recursos/{id} | Status; versão/chave | 200 Recurso | G | 003 / T03 |
| consultar_disponibilidade | GET /eventos/{id}/disponibilidade | inicio, fim opcionais dentro do evento | 200 saldo e recursos elegíveis | V | 003 / T03,T15 |
| bloquear_inscricao | POST /eventos/{id}/inscricoes | Inscrição, recursos e chave | 201 inscrição nova; 200 rebloqueio da mesma inscrição elegível | O | 004,011 / T04,T11 |
| listar_inscricoes | GET /eventos/{id}/inscricoes | Paginação | 200 lista com origem_valida | V | 011 / T11 |
| acao_inscricao | POST /inscricoes/{id}/acoes | CONFIRMAR, CANCELAR, PRESENCA, NO_SHOW ou CONCLUIR; motivo | 200 Inscrição | O | 005,012 / T05,T12 |
| reacomodar_recursos | POST /inscricoes/{id}/recursos | IDs de recursos destino | 200 Inscrição e alocações | O | 003,005 / T18 |
| consultar_correlacao | GET /inscricoes/{id}/origem | ID | 200 IDs comerciais opcionais | G | 006 / T06 |
| definir_pontos | POST /eventos/{id}/pontos | Lista Ponto substitui rota em PLANEJADO | 200 lista Ponto | G | 007 / T07 |
| registrar_passagem | POST /inscricoes/{id}/passagens | id_ponto, instante | 201 Passagem | O | 007 / T07 |
| registrar_ocorrencia | POST /eventos/{id}/ocorrencias | Ocorrência | 201 Ocorrência | O | 008 / T08 |
| alterar_ocorrencia | PATCH /ocorrencias/{id} | Status e motivo; versão/chave | 200 Ocorrência | O | 008 / T08 |
| listar_ocorrencias | GET /eventos/{id}/ocorrencias | Paginação | 200 lista de códigos e estados | V | 008,013 / T08,T13 |
| definir_logistica | POST /eventos/{id}/logistica | Lista Apoio | 200 plano de apoio | G | 009 / T09 |
| definir_equipe | POST /eventos/{id}/equipe | Lista Guia | 200 equipe | G | 010 / T10 |
| reconciliar_evento | POST /eventos/{id}/reconciliacao | cursor opcional; limite 1..100 | 200 IDs tratados, próximo cursor | O | 004,006 / T16,T19 |
| expirar_evento | POST /eventos/{id}/expiracao | versão/chave | 200 IDs expirados | O | 004 / T16 |
| avaliar_inscricao | POST /inscricoes/{id}/avaliacao | nota inteira 1..5 | 201 Avaliação | O | 012 / T12 |
| relatorio_evento | GET /eventos/{id}/relatorio | ID | 200 contagens e IDs operacionais | V | 012,014 / T12,T14 |
| listar_pendencias | GET /eventos/{id}/pendencias | Paginação/status | 200 lista | G | 006 / T06,T19 |
| tratar_pendencia | POST /pendencias/{id}/tratamento | referencia_tratamento; motivo | 200 Pendência | G | 006 / T19 |
| consultar_auditoria | GET /eventos/{id}/auditoria | Paginação | 200 trilha mínima | G | 014 / T14 |

Definir equipe/logística substitui o conjunto atomicamente, incluindo as alocações de apoio, somente antes da abertura.
Na inscrição, a origem comercial é lida, não recebida como payload. GET origem exige G para limitar exposição.
Relatório não retorna nome/documento de passageiro; ocorrência não aceita texto livre.

## 3. Dicionário de payloads e respostas

Todo campo listado é obrigatório, salvo indicação. Campos de resposta comuns: ID, versão e timestamps.
O payload de atualização é parcial; pelo menos um atributo alterável é obrigatório. Referências de origem são imutáveis.

| Tipo | Campos de entrada | Campos de resposta além dos comuns |
| --- | --- | --- |
| Produto | id_produto; distancia_km decimal >0; desnivel_m decimal >=0; nivel enum | Mesmos atributos, ativo |
| Evento | id_saida; inicio/fim com fuso; capacidade 1..1000 | Mesmos atributos e status |
| Recurso | codigo 1..30; tipo; id_ativo/id_guia/id_transporte opcionais conforme tipo | Campos de origem, tipo e status; sem cadastro externo |
| Inscrição | id_reserva; id_passageiro; papel; id_bicicleta; ids_equipamentos opcionais únicos | IDs, papel, status, expira_em, alocações por ID |
| Ponto | ordem >0; id_localidade; distancia_km >=0 | id_ponto, id_evento e os mesmos atributos |
| Passagem | id_ponto; instante com fuso, dentro do evento e não futuro | id_inscricao, id_ponto e instante |
| Ocorrência | id_inscricao opcional; tipo; gravidade; motivo enumerado | IDs, tipo, gravidade, motivo e status |
| Guia | id_recurso tipo GUIA; papel LIDER/APOIO | id_evento, recurso, papel e id_alocacao |
| Apoio | id_recurso tipo VEICULO/EQUIPAMENTO; finalidade | id_evento, recurso, finalidade e id_alocacao |
| Avaliação | nota inteira 1..5 | id_inscricao e nota |
| Pendência | Criada pelo sistema, não por payload público | IDs, tipo, status e referência de tratamento opcional |

Motivo: código obrigatório em cancelamento, no-show, descarte, conclusão excepcional e tratamento.
Códigos: SOLICITACAO, CLIMA, RECURSO_INDISPONIVEL, ORIGEM_INVALIDA, OPERACIONAL e TRATAMENTO_CONCLUIDO.
Ocorrência: tipo ATRASO, MECANICA, INTERRUPCAO ou OUTRA; gravidade BAIXA, MEDIA ou ALTA.
Não usar nota livre como código de motivo. Campo `instante` de passagem não altera o horário auditado do servidor.

## 4. Erros e precedência

| Situação | HTTP | Efeito |
| --- | --- | --- |
| Sem token / permissão | 401 / 403 | Rejeitar antes de consultar resposta idempotente |
| Entrada malformada, enum/tamanho/intervalo inválido | 422 | Sem escrita |
| ID não encontrado dentro do acesso permitido | 404 | Sem escrita |
| Referências existentes porém incompatíveis | 409 | Sem escrita; ex.: passageiro de outra reserva |
| Estado, versão, capacidade, duplicidade ou chave divergente | 409 | Rollback integral |
| Dependência ou banco indisponível | 503 | Sem sucesso parcial |
| Falha inesperada | 500 | Rollback; envelope seguro com correlação |

Após autenticação e validação estrutural, replay precede revalidação da versão antiga, mas nunca precede autorização.
Inscrição confirmada com chave repetida após cancelamento retorna o resultado original sem reativar estado.
OpenAPI futuro deve documentar respostas por rota e comparar compatibilidade contra a main; não será gerado agora.

## 5. Implementação rastreável futura

Produto/evento → caso de uso de configuração; recurso/apoio → alocação; inscrição → operação turística especializada;
passagem/ocorrência → acompanhamento; pendência → reconciliação. Repositories escrevem somente tabelas de A8.
Portas de A4 resolvem referências. T01–T25 de A7 comprovam regras, contratos e isolamento.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-03, versão 1.1 |
| Última atualização | 10/09/2026 |
| Aceite | Vaner, 11/09/2026; auditoria semântica e gates documentais aprovados |
| Implementação | Documento aceito; autorização global controlada pelo gate documental |

<!-- cspell:ignore inscricao inscricoes ocorrencia ocorrencias logistica alocacao alocacoes correlacao -->
<!-- cspell:ignore reacomodacao reconciliacao idempotencia versao btree gist payloads fixtures operationId -->

<!-- cspell:ignore PRESENCA desnivel LIDER INDISPONIVEL CONCLUIDO INTERRUPCAO -->
<!-- cspell:ignore rebloqueio -->
