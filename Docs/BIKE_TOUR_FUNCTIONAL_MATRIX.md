# Matriz Funcional de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-02`)
> **Tipo:** Documento técnico e funcional
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

A2 foi aprovado e aceito em 11/09/2026; a autorização global de implementação permanece controlada pelo gate documental.
A1 permanece aceito no commit `f94f421`. Vaner confirmou em 10/09/2026 a reutilização de reserva e passageiro,
com um evento por saída. As demais escolhas abaixo são propostas concretas para revisão do responsável.

## 1. Identidades e alcance

- Evento: especialização de uma `saida_turistica`; uma saída tem zero ou um evento Bike Tour.
- Produto: atributos da modalidade ligados ao `produto_turistico` do tipo `CICLOTURISMO`; sem catálogo paralelo.
- Rota: distância, nível e sequência de pontos vinculados ao evento; roteiro turístico geral continua em Turismo.
- Inscrição: vínculo operacional de um `passageiro` de uma `reserva` da mesma saída. Não consome nova vaga turística.
- Cliente contratante não é necessariamente passageiro. Não se cria cliente para representar participante.
- Cada participante, inclusive acompanhante que pedala, precisa de passageiro próprio na reserva.
- Uma bicicleta individual por inscrição; acessórios adicionais são recursos individuais opcionais.
- Guias e veículos são recursos de apoio do evento; não são participantes nem ocupam vaga de inscrição.
- Bicicleta própria pode ser cadastrada como recurso operacional sem patrimônio obrigatório, sem copiar proprietário.

A existência de cadastro não comprova disponibilidade. Toda alocação usa intervalo com início inclusivo e fim exclusivo.
Não há checkout público, inscrição autônoma, frontend, aplicativo, integração com site ou scheduler nesta etapa.
O participante é o beneficiário; o operador autenticado registra presença e ocorrências por ele.

## 2. Regras e resultados por requisito

| ID BT-REQ | Entrada e precondição | Resultado e aceite |
| --- | --- | --- |
| 001 | Produto turístico ativo, tipo CICLOTURISMO; distância positiva e nível válido | Especialização única; produto ausente 404, duplicado 409 |
| 002 | Saída existente; período do evento dentro das datas da saída; capacidade entre 1 e 1000 | Evento PLANEJADO único por saída; segunda criação 409 |
| 003 | Recurso ATIVO; intervalo válido | Disponibilidade calculada por sobreposição em todos os eventos; não garante bloqueio |
| 004 | Evento ABERTO; reserva elegível e passageiro vinculado; bicicleta livre | Inscrição PENDENTE e bloqueio por 15 minutos, limitado ao início do evento |
| 005 | Bloqueio vigente; reserva turística CONFIRMADA | Inscrição CONFIRMADA e mesma alocação confirmada, sem vaga adicional em Turismo |
| 006 | Inscrição com origem turística | Correlação consultada pela reserva; venda e contrato opcionais, nunca inseridos em Bike Tour |
| 007 | Evento em execução; ponto pertencente à rota; inscrição presente | Passagem única; ordem crescente; repetição não duplica |
| 008 | Evento existente; tipo e gravidade válidos | Ocorrência auditada; inexistência rejeitada, nunca registro parcialmente válido |
| 009 | Evento planejado ou aberto; veículo/equipamento ATIVO e livre | Plano de apoio com alocações exclusivas; ausência ou conflito impede abertura |
| 010 | Guia válido e recurso livre; papel LIDER ou APOIO | Equipe vinculada; um líder obrigatório para abrir; sobreposição entre eventos rejeitada |
| 011 | Passageiro da reserva e mesma saída; papel PARTICIPANTE ou ACOMPANHANTE | Uma inscrição por evento e passageiro; sem duplicar pessoa ou dados pessoais |
| 012 | Evento em execução, inscrições com resultado final e ocorrências graves tratadas | Evento CONCLUIDO; recursos liberados, histórico preservado |
| 013 | Token válido e permissão por ação | 401 sem autenticação; 403 sem permissão; resposta com identificadores mínimos |
| 014 | Qualquer mutação aceita | Ator, instante, correlação, versão e transição auditados na mesma transação |

Nível: INICIANTE, INTERMEDIARIO ou AVANCADO. Distância e desnível usam decimal; distância maior que zero,
desnível não negativo. Período com fuso obrigatório, convertido para UTC. Capacidade do evento não excede a da saída.
Abertura exige rota com pelo menos dois pontos, líder e veículo de apoio alocados; ausência produz 409.
Confirmar inscrição não registra presença: presença é ato operacional distinto, após início do evento.

## 3. Estados e transições

| Agregado | Transições permitidas | Restrições |
| --- | --- | --- |
| Produto específico | ATIVO ↔ INATIVO | Inativação impede novos eventos; não apaga eventos existentes |
| Evento | PLANEJADO → ABERTO → EM_EXECUCAO → CONCLUIDO | Abrir exige preparação; iniciar exige horário e origem elegível |
| Evento | PLANEJADO ou ABERTO → CANCELADO | Cancela inscrições ativas e libera recursos atomicamente |
| Evento | EM_EXECUCAO → CANCELADO | Gestão, motivo e ocorrência; preserva passagens e fatos já executados |
| Recurso | ATIVO ↔ INATIVO ou MANUTENCAO | Alteração bloqueada enquanto houver alocação ativa; reacomodar antes |
| Inscrição | PENDENTE → CONFIRMADA, EXPIRADA ou CANCELADA | Expiração somente para pendente; confirmação exige bloqueio vigente |
| Inscrição | CONFIRMADA → PRESENTE, NO_SHOW ou CANCELADA | Presença/no-show somente no evento iniciado; justificativa obrigatória |
| Inscrição | PRESENTE → CONCLUIDA ou CANCELADA | Conclusão exige último ponto ou encerramento justificado por gestor |
| Ocorrência | ABERTA → EM_ANALISE → RESOLVIDA ou DESCARTADA | Resolução ou descarte exige justificativa, sem apagar histórico |

Estados terminais não reabrem. Nova tentativa após expiração/cancelamento cria nova operação e reativa a mesma
inscrição apenas enquanto o evento estiver ABERTO, mediante comando explícito de novo bloqueio; incrementa versão.
A inscrição é única por evento e passageiro. A primeira criação retorna HTTP 201. Quando uma inscrição existente
estiver elegível para novo bloqueio e o evento permanecer ABERTO, reutilizar a mesma inscrição, incrementar sua
versão e retornar HTTP 200. Não criar segunda inscrição para o mesmo par evento/passageiro.
A inscrição é única por evento e passageiro. A primeira criação retorna HTTP 201. Quando uma inscrição existente
estiver elegível para novo bloqueio e o evento permanecer ABERTO, reutilizar a mesma inscrição, incrementar sua
versão e retornar HTTP 200. Não criar segunda inscrição para o mesmo par evento/passageiro.
Produto, período e capacidade do evento só mudam em PLANEJADO e sem inscrições/alocações ativas.
Pontos só mudam antes da abertura. Alterações fora dessas condições retornam 409, mesmo com permissão de gestão.

## 4. Capacidade e casos compostos

Bloqueios válidos e inscrições confirmadas/presentes não excedem a capacidade do evento.
Participantes comprometidos são inscrições PENDENTES com bloqueio válido, CONFIRMADAS ou PRESENTES.
CONCLUIDA, CANCELADA, EXPIRADA e NO_SHOW não consomem capacidade operacional e não mantêm alocações ativas.
Participantes comprometidos são inscrições PENDENTES com bloqueio válido, CONFIRMADAS ou PRESENTES.
CONCLUIDA, CANCELADA, EXPIRADA e NO_SHOW não consomem capacidade operacional e não mantêm alocações ativas.
Bicicleta, guia e veículo não podem estar alocados em eventos que se sobrepõem; eventos consecutivos podem reutilizar.
Reacomodação troca recursos na mesma inscrição/evento, apenas PENDENTE ou CONFIRMADA antes do início.
Obter destino e liberar origem na mesma transação. NO_SHOW, cancelamento e conclusão liberam alocações ativas,
preservando o intervalo e o histórico.
Transferência para outra saída exige fluxo de Turismo e novo vínculo; não altera silenciosamente a reserva existente.

Cancelamento Bike Tour não cancela automaticamente reserva, venda ou pagamento. Registra pendência operacional
para avaliação pelo domínio de origem. A reserva cancelada em Turismo impede confirmação, presença e início;
reconciliação explícita cancela o vínculo Bike Tour e libera recursos, preservando a origem e o histórico.

Avaliação pós-evento: nota inteira de 1 a 5, uma por inscrição concluída, sem texto livre ou dados pessoais adicionais.
Relatório do evento agrega inscrições, passagens e ocorrências; não cria fato comercial ou financeiro.

## 5. Dependências

Contratos e testes estão em BT-DOC-03/07; as regras de transação em BT-DOC-05 e a decisão de dados em BT-DOC-08.
A relação saída/evento e reserva/passageiro foi confirmada pelo responsável; as demais regras exigem aceite de A2.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-02, versão 1.1 |
| Última atualização | 10/09/2026 |
| Responsável pelo aceite | Vaner |
| Evidência de aceite | Aceite formal registrado em 11/09/2026 após auditoria semântica e gates documentais aprovados |
| Implementação | Documento aceito; autorização global controlada pelo gate documental |

<!-- cspell:ignore CONCLUIDO EXECUCAO MANUTENCAO DISPONIVEL inscricao inscricoes ocorrencia ocorrencias -->
<!-- cspell:ignore logistica alocacao alocacoes correlacao reacomodacao reconciliacao permissao -->
<!-- cspell:ignore idempotencia versao obrigatorio disponivel proposta bike btree gist tstzrange offset -->

<!-- cspell:ignore LIDER AVANCADO CONCLUIDA -->
