# Matriz Funcional de Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6.2 — Matriz Funcional de Turismo (`TUR-DOC-02`)
> **Módulo:** Turismo
> **Tipo de documento:** Documento Funcional
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Objetivo e limite

Este documento define capacidades, atores, fluxo funcional e invariantes da Etapa 2.6. Ele relaciona o processo
pretendido às estruturas inventariadas em `TUR-DOC-01`, sem aprovar schema, migration, contrato de API ou
implementação funcional.

As entidades e os estados propostos abaixo são conceitos funcionais. Sua representação física será decidida em
`TUR-DOC-08`; portanto, este documento não autoriza alteração retroativa da baseline certificada.

## 2. Atores e responsabilidades

| Ator | Responsabilidade | Limite de autoridade |
| --- | --- | --- |
| Administrador de Turismo | Configurar catálogo, políticas e permissões operacionais | Não altera fatos financeiros |
| Produtos | Manter destino, produto, pacote, roteiro, serviços e condições | Não confirma venda ou pagamento |
| Reservas | Consultar disponibilidade e gerir reserva e passageiros | Não cria vaga nem liquida recebimento |
| Operações | Preparar e acompanhar saída, fornecedores, recursos e checklist | Não modifica contrato comercial |
| Comercial | Formalizar venda, item e contrato | Não controla capacidade operacional |
| Financeiro | Gerir obrigação, recebimento, estorno e conciliação | Não altera reserva diretamente |
| Passageiro ou cliente | Fornecer dados autorizados e receber comunicações | Acesso restrito ao próprio contexto |
| Auditor | Consultar eventos e evidências conforme permissão | Sem mutação operacional |

Core Corporativo permanece autoridade de cliente, fornecedor e localidade. Comercial permanece autoridade de
venda e contrato. Financeiro permanece autoridade de fatos monetários. Turismo é autoridade de catálogo
turístico, saída, disponibilidade, reserva, passageiros e execução operacional.

## 3. Fluxo funcional de referência

1. Produtos cadastra um produto turístico associado a destino válido.
2. Produtos compõe um pacote com roteiro, serviços e condições comerciais identificáveis.
3. Uma saída operacional materializa data, capacidade e recursos para o pacote.
4. Reservas consulta disponibilidade e solicita bloqueio temporário ou reserva de vagas.
5. Comercial formaliza venda e contrato, mantendo correlação rastreável com a reserva.
6. A confirmação aplicável converte o bloqueio em ocupação e associa os passageiros autorizados.
7. Operações aloca fornecedores, guia, hospedagem, transporte e checklist da saída.
8. Cancelamento, expiração ou reacomodação atualiza a ocupação uma única vez e dispara efeitos correlatos.
9. A saída é executada e encerrada; ocorrências e no-show permanecem auditáveis.
10. O pós-viagem admite avaliação vinculada à reserva concluída e respeita a política de privacidade.

A baseline atual concentra período e capacidade em `pacote_viagem`; ela não possui entidade distinta de saída nem
razão de disponibilidade. A palavra **saída** neste documento representa uma capacidade funcional obrigatória,
sem antecipar como será persistida.

## 4. Matriz de capacidades

| Capacidade | Entrada principal | Resultado funcional | Estruturas atuais | Situação |
| --- | --- | --- | --- | --- |
| Gerir destino | localidade, descrição e situação | destino reutilizável | `destino`, `localidade` | Parcial |
| Gerir produto | identidade, tipo e destino | produto turístico publicável | `produto_turistico` | Parcial |
| Compor pacote | produto, roteiro, serviços e condições | oferta comercial coerente | `pacote_viagem`, `roteiro_viagem` | Parcial |
| Programar saída | pacote, período, capacidade e recursos | execução operacional identificável | campos de `pacote_viagem` | Lacuna |
| Consultar disponibilidade | saída e quantidade | saldo consistente e explicável | `quantidade_vagas` | Lacuna |
| Bloquear vaga | saída, quantidade e validade | alocação temporária idempotente | inexistente | Lacuna |
| Gerir reserva | cliente, saída e quantidade | reserva rastreável e versionada | `reserva` | Parcial |
| Vincular venda e contrato | reserva e referência comercial | correlação ponta a ponta | `item_venda`, venda e contrato | Lacuna |
| Gerir passageiros | reserva e dados mínimos | viajantes autorizados na operação | `passageiro` | Parcial |
| Compor serviços | pacote, fornecedor e condições | serviços planejados e reservados | `hospedagem`, `transporte` | Lacuna |
| Planejar operação | saída, recursos e tarefas | plano operacional verificável | `checklist_viagem` | Parcial |
| Tratar cancelamento | reserva, motivo e política | vaga liberada e efeitos correlatos | status textual | Lacuna |
| Encerrar viagem | execução e ocorrências | operação concluída e auditável | checklist | Lacuna |
| Avaliar pós-viagem | reserva concluída e consentimento | avaliação válida | `avaliacao_pos_viagem` | Parcial |

## 5. Conceitos e estados funcionais

Os nomes a seguir constituem vocabulário candidato. `TUR-DOC-03`, `TUR-DOC-05` e os contratos posteriores devem
fixar códigos, transições, respostas e evidências antes de qualquer implementação.

| Conceito | Estados funcionais candidatos | Regra central |
| --- | --- | --- |
| Produto | RASCUNHO, ATIVO, INATIVO | somente produto ativo pode originar nova oferta |
| Pacote | RASCUNHO, PUBLICADO, SUSPENSO, ENCERRADO | publicação exige composição válida |
| Saída | PLANEJADA, ABERTA, ESGOTADA, EM_EXECUÇÃO, CONCLUÍDA, CANCELADA | período e capacidade são imutáveis após início |
| Vaga | DISPONÍVEL, BLOQUEADA, RESERVADA, LIBERADA | cada transição preserva a capacidade total |
| Reserva | PENDENTE, CONFIRMADA, EXPIRADA, CANCELADA, CONCLUÍDA, NO_SHOW | confirmação exige vaga válida |
| Tarefa operacional | PENDENTE, EM_EXECUÇÃO, CONCLUÍDA, CANCELADA | conclusão registra responsável e instante |

Nenhum estado pode ser persistido como texto arbitrário. A decisão de catálogo, enumeração ou constraint pertence
ao desenho técnico posterior e deve ser aditiva.

## 6. Invariantes de negócio

- datas do roteiro permanecem dentro do período operacional aplicável e respeitam ordem cronológica;
- capacidade total, quantidade solicitada, bloqueada e reservada nunca são negativas;
- vagas bloqueadas e reservadas não podem superar a capacidade efetiva da saída;
- uma reserva confirmada deve possuir ao menos um passageiro e não pode exceder as vagas alocadas;
- confirmação, cancelamento, expiração e liberação devem ser idempotentes;
- cancelamento ou expiração libera cada vaga no máximo uma vez;
- alterações concorrentes de disponibilidade devem detectar conflito, sem sobrescrever saldo mais recente;
- uma reserva possui correlação única e auditável com a origem comercial aplicável;
- efeitos financeiros são solicitados ao Financeiro por contrato explícito, nunca gravados diretamente por Turismo;
- uma saída iniciada não aceita mudança silenciosa de período, capacidade, roteiro ou recurso crítico;
- avaliação pós-viagem exige reserva elegível e não pode expor dados pessoais desnecessários;
- toda transição relevante registra ator, instante, origem e identificador de correlação.

## 7. Cenários funcionais obrigatórios

| Cenário | Resultado esperado |
| --- | --- |
| Reserva com saldo suficiente | vaga alocada e saldo reduzido de forma atômica |
| Duas solicitações para a última vaga | somente uma obtém a alocação; a outra recebe conflito previsível |
| Repetição da mesma requisição | mesmo resultado lógico, sem duplicar reserva ou ocupação |
| Bloqueio expirado | vaga liberada uma vez e evento registrado |
| Cancelamento confirmado | reserva cancelada, vaga liberada e efeitos externos correlacionados |
| Falha do Financeiro | estado local consistente e compensação ou nova tentativa rastreável |
| Mudança de passageiro após fechamento | operação rejeitada ou autorizada por política explícita |
| Cancelamento de saída | reservas afetadas identificadas para reacomodação ou cancelamento |
| No-show | ocupação histórica preservada e ocorrência registrada |
| Avaliação sem viagem concluída | operação rejeitada |

## 8. Segurança, privacidade e auditoria

Dados de passageiro devem ser mínimos para a finalidade operacional, protegidos por autorização específica e
sujeitos a retenção definida. CPF, documentos, telefone e e-mail não podem aparecer em logs, erros ou métricas.

As operações de leitura e mutação devem separar permissões de catálogo, reserva, passageiros e operação. Eventos
de acesso a dados sensíveis, alterações de capacidade, transições de reserva e decisões excepcionais precisam ser
auditáveis. Os controles definitivos serão aprovados em `TUR-DOC-06`.

## 9. Decisões encaminhadas

- `TUR-DOC-03`: rastrear cada requisito até dado, serviço, API e teste;
- `TUR-DOC-04`: formalizar contratos e propriedade entre Core, Comercial, Financeiro, Turismo e Bike Tour;
- `TUR-DOC-05`: aprovar transações, concorrência, expiração e compensações;
- `TUR-DOC-06`: aprovar autorização, minimização, retenção e auditoria;
- `TUR-DOC-07`: derivar testes dos invariantes e cenários desta matriz;
- `TUR-DOC-08`: decidir o delta de schema e migrations aditivas necessárias.

## 10. Conclusão

A matriz funcional `TUR-DOC-02` está aprovada. Ela estabelece o fluxo de referência e os invariantes sem converter
lacunas em decisões físicas prematuras. Os entregáveis sucessores `TUR-DOC-03` a `TUR-DOC-05` também foram
aprovados, e a próxima entrega autorizada é `TUR-DOC-06` — Segurança e privacidade. A implementação funcional
permanece bloqueada até a aprovação integral do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6.2 — Matriz Funcional de Turismo |
| Entregável | `TUR-DOC-02` |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
