<!-- cspell:words correlação alocação ponto controle -->

# Fronteiras de Domínio de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.4 — Fronteiras de Domínio (`BT-DOC-04`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento de Arquitetura Funcional
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** EM ELABORAÇÃO

As definições específicas de Bike Tour neste documento são propostas em revisão, sem aceite registrado.
A linguagem normativa descreve o comportamento pretendido e não constitui aprovação do gate.

## 1. Objetivo e limite

Este documento define a autoridade, as dependências e os contratos conceituais entre Bike Tour e os demais
módulos do Monólito Modular. Ele detalha as fronteiras aprovadas para Core, Comercial, Financeiro e Turismo,
sem autorizar implementação, schema ou migration funcional.

## 2. Princípios obrigatórios

- cada fato de negócio possui uma única autoridade de escrita;
- outro domínio consome identificadores, não tabelas internas;
- leitura direta de tabela externa não é integração autorizada;
- nenhuma operação distribuída depende de commit simultâneo entre módulos;
- comandos devem ser idempotentes e possuir identificador de correlação quando cruzam fronteiras;
- falhas externas preservam o estado local e produzem uma ação recuperável;
- dados replicados e consultas agregadas são projeções, nunca nova autoridade.

## 3. Mapa de autoridades

| Domínio | Autoridade de escrita | Bike Tour pode consumir |
| --- | --- | --- |
| Core Corporativo | cliente, fornecedor, localidade e identidade | identificador, status e dados mínimos |
| Comercial | venda, item, contrato e condições | referência e status comercial aplicável |
| Financeiro | obrigação, titulo, pagamento e estorno | referência e situação financeira requeridas |
| Turismo | produto, pacote, saida, vaga, reserva e operação | referência e base operacional |
| Bike Tour | evento, recurso, equipe, ponto de controle, ocorrência e inscrição | fatos próprios e referências externas |
| Auditoria | evento imutável e trilha de alteração | correlação e contexto mínimo autorizado |

## 4. Core Corporativo e Bike Tour

Core fornece referências validas de cliente, fornecedor e localidade. Bike Tour não cria copia autônoma desses
cadastros.

| Fluxo | Origem | Destino | Conteúdo mínimo |
| --- | --- | --- | --- |
| validar cliente | Bike Tour | Core | identificador e finalidade |
| validar fornecedor | Bike Tour | Core | identificador e papel permitido |
| resolver localidade | Bike Tour | Core | identificador e status |
| consultar identidade | Bike Tour | Core | atributos estritamente autorizados |

## 5. Turismo e Bike Tour

Turismo detém a base comum de pacote, produto e reserva. Bike Tour especializa a oferta e o evento sem redefinir a
raiz de venda ou vaga.

### 5.1 Raiz de correlação

A correlação ponta a ponta deve preservar identificadores distintos:

```text
venda -> item de venda -> contrato -> reserva -> evento de Bike Tour
```

- venda e contrato permanecem em Comercial;
- reserva continua em Turismo;
- evento e recurso permanecem em Bike Tour;
- a correlação registra identificadores externos sem transferir autoridade;
- uma inscrição não altera diretamente a venda ou a reserva base;
- a cardinalidade e a persistência da correlação serão decididas em `BT-DOC-08`.

### 5.2 Contratos conceituais

| Intenção | Solicitante | Autoridade | Resultado esperado |
| --- | --- | --- | --- |
| cotar disponibilidade | Comercial | Turismo | saldo informado com validade |
| solicitar alocação | Comercial | Turismo | bloqueio ou conflito rastreável |
| confirmar inscrição | fluxo coordenado | Bike Tour | recurso confirmado ou rejeitado |
| consultar situação | Comercial | Bike Tour | estado operacional autorizado |
| notificar cancelamento | Comercial | Bike Tour | solicitacao registrada, não mutação direta |

## 6. Financeiro e Bike Tour

Bike Tour não cria, liquida, estorna ou concilia títulos. Quando um evento operacional exigir consequência
monetaria, Bike Tour envia origem e correlação; Financeiro decide e registra o fato financeiro.

| Evento de Bike Tour | Intenção enviada | Autoridade da consequência |
| --- | --- | --- |
| inscrição confirmada | registrar origem financeira aplicável | Financeiro |
| cancelamento de evento | avaliar cancelamento e estorno | Financeiro |
| reacomodação | correlacionar diferença aprovada | Comercial e Financeiro |
| no-show | aplicar politica contratual | Comercial e Financeiro |

## 7. Bike Tour e suas especializações

| Pertence a Turismo | Pertence futuramente a Bike Tour |
| --- | --- |
| pacote e produto base | modalidade e configuração de pedal |
| reserva e passageiro | bicicleta, equipamento e suporte |
| guia geral e apoio | equipe e rota de Bike Tour |
| operação e checklist gerais | ponto de controle e ocorrência da modalidade |

## 8. Auditoria, identidade e autorização

O módulo de identidade autentica o ator e fornece claims autorizadas; Bike Tour aplica permissões de seu domínio.
Auditoria recebe eventos mínimos e não se torna repositório de payload operacional ou dado pessoal.

Todo comando entre domínios deve carregar, quando aplicável:

- identificador da requisição;
- domínio e ator de origem;
- recurso e versão esperada;
- instante e intenção de negócio;
- referência ao resultado, sem dado sensível desnecessário.

## 9. Dependências permitidas e proibidas

| Situação | Classificação |
| --- | --- |
| Bike Tour chama interface pública de Core, Comercial ou Financeiro | permitida |
| Bike Tour persiste identificador externo e correlação aprovada | permitida |
| Bike Tour importa repositório ou model privado de outro módulo | proibida |
| serviço de Bike Tour escreve tabela de Comercial ou Financeiro | proibida |
| Comercial altera diretamente evento, recurso ou inscrição | proibida |
| Bike Tour duplica entidade comum para contornar contrato | proibida |

## 10. Conclusão

O `BT-DOC-04` define a raiz conceitual e as fronteiras de Bike Tour com os demais módulos. A implementação
funcional continua bloqueada até a aprovação do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.4 — Fronteiras de Domínio de Bike Tour |
| Entregável | `BT-DOC-04` |
| Status | EM ELABORAÇÃO |
| Última atualização | 09/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
