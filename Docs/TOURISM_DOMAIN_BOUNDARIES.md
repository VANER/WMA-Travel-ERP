# Fronteiras de Domínio de Turismo

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6.4 — Fronteiras de Domínio (`TUR-DOC-04`)
> **Módulo:** Turismo
> **Tipo de documento:** Documento de Arquitetura Funcional
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Objetivo e limite

Este documento define propriedade, dependências e contratos conceituais entre Turismo e os demais módulos do
Monólito Modular. Ele detalha as fronteiras já estabelecidas pela arquitetura e pela ADR-017, sem mover objetos,
criar dependência de banco, escolher mecanismo transacional ou autorizar implementação.

Mudança futura de autoridade, direção de dependência ou comunicação entre módulos exige ADR específica. A
representação física dos vínculos permanece reservada a `TUR-DOC-08`.

## 2. Princípios obrigatórios

- cada fato de negócio possui uma única autoridade de escrita;
- outro domínio consome identificadores e contratos, não tabelas ou repositórios internos;
- leitura direta de tabela externa não constitui integração autorizada;
- nenhuma operação distribuída depende de commit simultâneo entre módulos;
- comandos devem ser idempotentes e possuir identificador de correlação quando cruzam fronteiras;
- falhas externas preservam o estado local e produzem uma ação recuperável;
- dados replicados para consulta são projeções, nunca nova autoridade;
- Bike Tour especializa Turismo sem redefinir suas regras comuns.

## 3. Mapa de autoridades

| Domínio | Autoridade de escrita | Turismo pode consumir |
| --- | --- | --- |
| Core Corporativo | cliente, fornecedor, localidade e identidade corporativa | identificador, situação e dados permitidos |
| Comercial | venda, item, contrato, condições e formalização comercial | referência e situação comercial aplicável |
| Financeiro | obrigação, título, pagamento, estorno e conciliação | referência e situação financeira necessária |
| Turismo | destino turístico, produto, pacote, saída, vaga, reserva e operação | fatos próprios e referências externas |
| Bike Tour | recursos e regras exclusivas da modalidade | contratos públicos de Turismo e Core |
| Auditoria | evento imutável e trilha de alteração | correlação e contexto mínimo autorizado |

O posicionamento físico atual em `public` não modifica a autoridade lógica. Schema não é sinônimo de domínio.

## 4. Core Corporativo e Turismo

Core fornece referências válidas de `cliente`, `fornecedor` e `localidade`. Turismo não cria cópia autônoma desses
cadastros nem atualiza seus registros para satisfazer uma reserva.

| Fluxo | Origem | Destino | Conteúdo mínimo |
| --- | --- | --- | --- |
| Validar cliente | Turismo | Core | identificador e finalidade |
| Validar fornecedor | Turismo | Core | identificador, situação e papel permitido |
| Resolver localidade | Turismo | Core | identificador e situação |
| Consultar identidade | Turismo | Core | atributos estritamente autorizados |

O passageiro pode não ser o cliente contratante. A eventual associação com pessoa corporativa é decisão posterior;
Turismo continua responsável pelos dados operacionais mínimos do viajante e não promove passageiro a cliente.

## 5. Comercial e Turismo

Comercial formaliza a aquisição; Turismo controla execução e capacidade. Produto turístico pode ser referenciado
por item de venda, mas uma venda não representa por si só uma vaga confirmada.

### 5.1 Raiz de correlação

A correlação ponta a ponta deve preservar identificadores distintos:

```text
venda -> item de venda -> contrato -> reserva -> saída
```

- venda e contrato permanecem em Comercial;
- reserva e saída permanecem em Turismo;
- a correlação registra os identificadores externos sem transferir autoridade;
- uma reserva não altera diretamente o status da venda ou do contrato;
- Comercial não altera diretamente vaga, passageiro ou status operacional;
- cardinalidade e persistência da correlação serão decididas em `TUR-DOC-05` e `TUR-DOC-08`.

### 5.2 Contratos conceituais

| Intenção | Solicitante | Autoridade | Resultado esperado |
| --- | --- | --- | --- |
| Cotar disponibilidade | Comercial | Turismo | saldo informativo com validade |
| Solicitar bloqueio | Comercial | Turismo | bloqueio ou conflito rastreável |
| Vincular formalização | Comercial | Turismo | correlação aceita ou rejeitada |
| Confirmar reserva | fluxo coordenado | Turismo | ocupação confirmada uma vez |
| Consultar situação | Comercial | Turismo | situação operacional autorizada |
| Informar cancelamento comercial | Comercial | Turismo | solicitação registrada, não mutação direta |

Consulta de disponibilidade não garante vaga. Somente o contrato transacional aprovado em `TUR-DOC-05` pode
produzir bloqueio ou confirmação.

## 6. Financeiro e Turismo

Turismo não cria, liquida, estorna ou concilia títulos. Quando um evento operacional exigir consequência
monetária, Turismo fornece origem, correlação e contexto; Financeiro decide e registra o fato financeiro.

| Evento de Turismo | Intenção enviada | Autoridade da consequência |
| --- | --- | --- |
| Reserva confirmada | registrar origem financeira aplicável | Financeiro |
| Reserva cancelada | avaliar cancelamento, crédito ou estorno | Financeiro |
| Reacomodação | correlacionar diferença aprovada | Comercial e Financeiro |
| No-show | aplicar política contratual aprovada | Comercial e Financeiro |
| Custo operacional | registrar obrigação documentada | Financeiro |

Situação financeira pode condicionar uma transição de reserva por política explícita, mas nunca é inferida por
consulta direta às tabelas financeiras. Falha no processamento externo não pode causar dupla ocupação ou dupla
consequência financeira.

## 7. Bike Tour e Turismo

Bike Tour é etapa posterior e consumidora das capacidades comuns de Turismo. A Etapa 2.6 não cria antecipadamente
bicicleta, equipamento, manutenção, termo específico, logística de pedal ou regra exclusiva de ciclismo.

| Pertence a Turismo | Pertence futuramente a Bike Tour |
| --- | --- |
| produto, pacote, saída e roteiro genéricos | modalidade e configuração de pedal |
| reserva, passageiro e disponibilidade | bicicleta, equipamento e dimensionamento |
| fornecedor, guia e serviço genéricos | manutenção e logística específica |
| operação, checklist e ocorrência genéricos | checklist e termo específicos da modalidade |

Uma especialização futura deve referenciar contratos públicos de Turismo. Ela não pode duplicar reserva, vaga ou
passageiro como nova fonte de verdade.

## 8. Auditoria, identidade e autorização

O módulo de identidade autentica o ator e fornece claims autorizadas; Turismo aplica as permissões de sua
fronteira. Auditoria recebe eventos mínimos e não se torna repositório de payload operacional ou dado pessoal.

Todo comando interdomínio relevante deve carregar, quando aplicável:

- identificador da requisição e da correlação;
- domínio e ator de origem;
- recurso e versão esperada;
- instante e intenção de negócio;
- referência ao resultado, sem dado sensível desnecessário.

CPF, documento, telefone, e-mail e conteúdo integral de contrato não integram mensagens de correlação, logs ou
eventos genéricos.

## 9. Dependências permitidas e proibidas

| Situação | Classificação |
| --- | --- |
| Turismo chama interface pública de Core, Comercial ou Financeiro | Permitida |
| Adaptador do módulo traduz contrato externo para tipo interno | Permitida |
| Turismo persiste identificador externo e correlação aprovada | Permitida |
| Turismo importa repositório ou model privado de outro módulo | Proibida |
| Serviço de Turismo escreve tabela de Comercial ou Financeiro | Proibida |
| Comercial altera diretamente reserva ou vaga | Proibida |
| Bike Tour duplica entidade comum para contornar contrato | Proibida |
| Banco compartilhado é usado para ignorar a camada do módulo | Proibida |

## 10. Falhas e consistência entre domínios

- cada domínio confirma apenas sua própria transação;
- reexecução usa a mesma chave idempotente e não repete o efeito lógico;
- timeout produz estado desconhecido recuperável, não sucesso presumido;
- rejeição externa é registrada com código estável e correlação;
- nova tentativa e compensação seguem política aprovada em `TUR-DOC-05`;
- reconciliação detecta correlação ausente, duplicada ou divergente;
- operador não corrige inconsistência escrevendo diretamente no banco.

## 11. Decisões encaminhadas

- `TUR-DOC-05` definirá bloqueio, confirmação, expiração, cancelamento e compensação;
- `TUR-DOC-06` definirá permissões, dados pessoais, retenção e eventos auditáveis;
- `TUR-DOC-07` verificará isolamento, falhas, contratos e regressões entre módulos;
- `TUR-DOC-08` decidirá como referências e correlações serão persistidas por migration aditiva.

## 12. Conclusão

O `TUR-DOC-04` aprova as autoridades e a raiz conceitual Venda → Contrato → Reserva → Saída, preservando
identificadores e transações próprios. A política transacional sucessora `TUR-DOC-05` também foi aprovada, e a
próxima entrega autorizada é `TUR-DOC-06` — Segurança e privacidade. A implementação funcional permanece bloqueada
até a aprovação integral do gate documental.

---

## Controle e Rastreabilidade

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Etapa | 2.6.4 — Fronteiras de Domínio de Turismo |
| Entregável | `TUR-DOC-04` |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
