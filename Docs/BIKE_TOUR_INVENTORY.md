# Inventário de Bike Tour

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.7.1 — Inventário de Bike Tour (`BT-DOC-01`)
> **Módulo:** Bike Tour
> **Tipo de documento:** Documento técnico
> **Versão:** 1.0
> **Data:** 09/09/2026
> **Status:** APROVADO E ACEITO

O inventário consolidado no commit `f94f421` foi aceito formalmente por Vaner em 10/09/2026.
O aceite abrange o levantamento e suas lacunas; propostas de solução permanecem sujeitas a A2–A8.
Este aceite não aprova o gate completo nem autoriza implementação funcional.

## 1. Objetivo e limite

Este inventário identifica os objetos, limites e lacunas do domínio de Bike Tour antes da implementação. Ele
preserva a baseline certificada e não cria models, migrations, endpoints, services ou regras de negócio.

Fontes consultadas:

- `Database/scripts/WmaTravelERP.sql`;
- `Docs/DATA_DICTIONARY.md`;
- `Docs/PHASE_2_EXECUTION_ORDER.md` e `Docs/PHASE_2_ROADMAP.md`;
- `Docs/TOURISM_INVENTORY.md`, `Docs/TOURISM_DOMAIN_BOUNDARIES.md` e `Docs/TOURISM_MODULE.md`;
- `Backend/openapi.json`;
- modelos e contratos aprovados de Core e Turismo.

## 2. Autoridade e fronteiras

A autoridade de Bike Tour deve permanecer especializada e derivada de Core e Turismo. O módulo não deve duplicar
clientes, fornecedores, localidades, reservas, vagas, passageiros, produtos ou contratos comerciais.

| Domínio | Autoridade consumida por Bike Tour |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| Core Corporativo | `cliente`, `fornecedor`, `localidade`, `identidade` |
| Comercial | `venda`, `item_venda`, `contrato`, `condicao` |
| Financeiro | responsabilidade financeira, cobrança, pagamento e estorno |
| Turismo | `produto_turistico`, `pacote_viagem`, `roteiro_viagem`, `saida`, `reserva`, `passageiro`, `guia`, `servico` |
| Bike Tour | recursos e regras próprias da modalidade |
| Auditoria | trilha e evento imutável |

A etapa 2.7 não cria nova autoridade para `reserva`, `vaga`, `passageiro` ou `produto`. Qualquer especialização
necessária deve manter a raiz já definida por Turismo e ampliar apenas o escopo próprio da modalidade.

## 3. Objetos existentes e reutilização

| Objeto existente | Papel observado | Reuso esperado |
| ----------------------------- | ---------------------------- | -------------------------------------------- |
| `public.localidade` | local de operação e destino | referência de origem, destino e apoio |
| `public.cliente` | cliente do sistema | referência de contratante e participante |
| `public.fornecedor` | cadastro corporativo | referência de fornecedor e apoio operacional |
| `public.produto_turistico` | catálogo de oferta | base para produto de modalidade |
| `public.pacote_viagem` | oferta de pacote | base para pacote de Bike Tour |
| `public.roteiro_viagem` | percurso e etapa | base para rota e deslocamento |
| `public.reserva` | reserva de cliente | base para inscrição e participação |
| `public.passageiro` | viajante associado | base para participante |
| `public.fornecedor_turistico` | especialização de fornecedor | base para apoio e operação |
| `public.guia_turistico` | operação de equipe | base para guia e liderança |
| `public.transporte` | recurso de deslocamento | base para suporte de logística |
| `public.hospedagem` | alojamento e suporte | base para apoio em rota |
| `public.checklist_viagem` | itens operacionais | base para checklist de modalidade |

A presença de objetos em Core e Turismo reduz o escopo inicial da etapa. O módulo deve operar sobre estruturas
existentes, sem duplicar fatos transacionais de outro domínio.

### 3.1 Constatações verificáveis da revisão

O dump oficial já permite `CICLOTURISMO` em `produto_turistico.tipo_produto`,
pela constraint `ck_tipo_produto`. Portanto, uma oferta da modalidade não exige
duplicar o catálogo turístico; atributos específicos ainda precisam ser
decididos. A existência da tabela não comprova interface pública disponível
para integração.

O dump também contém `ativo_imobilizado`, `colaborador`, `vw_kpis_turismo` e
`vw_rentabilidade_turismo`. Esses objetos devem entrar na análise de
reaproveitamento e dependências, sem presumir que patrimônio representa
bicicleta disponível, colaborador representa equipe alocada ou que views
analíticas sejam autoridade transacional.

Os nomes conceituais de domínio neste inventário não são uma lista certificada
de tabelas ou contratos executáveis. As evidências consolidadas do levantamento estão na seção 3.2.
O aceite desse levantamento está registrado na seção 9 e não aprova os contratos e decisões de A2–A8.

### 3.2 Evidências consolidadas da baseline

A revisão do dump oficial e do Backend confirmou que o domínio Turismo já
possui estruturas que devem ser tratadas como autoridades existentes antes
da implementação de Bike Tour.

`produto_turistico.tipo_produto` possui a constraint `ck_tipo_produto`, que
admite explicitamente `CICLOTURISMO`. Assim, a modalidade Bike Tour pode ser
representada no catálogo turístico existente sem duplicação da entidade de
produto.

A cadeia estrutural existente inclui, entre outras relações verificadas:

- `pacote_viagem.id_produto -> produto_turistico.id_produto`;
- `reserva.id_pacote -> pacote_viagem.id_pacote`;
- `passageiro.id_reserva -> reserva.id_reserva`;
- `roteiro_viagem.id_pacote -> pacote_viagem.id_pacote`;
- `roteiro_viagem.id_destino -> destino.id_destino`;
- `checklist_viagem.id_pacote -> pacote_viagem.id_pacote`;
- `fornecedor_turistico.id_fornecedor -> fornecedor.id_fornecedor`;
- `hospedagem.id_fornecedor_turistico -> fornecedor_turistico.id_fornecedor_turistico`;
- `transporte.id_fornecedor_turistico -> fornecedor_turistico.id_fornecedor_turistico`;
- `ativo_imobilizado.id_categoria_ativo -> categoria_ativo.id_categoria_ativo`.

O Backend também implementa autoridades do domínio Turismo para
`ProdutoTuristico`, `PacoteViagem`, `SaidaTuristica`, `Reserva`,
`AlocacaoVaga`, `ReservaCorrelacao` e `ReservaOperacao`.

Essas evidências estabelecem reutilização obrigatória das autoridades
existentes quando aplicáveis. Elas não autorizam inferir que
`ativo_imobilizado` represente, isoladamente, disponibilidade operacional de
bicicletas, nem que `colaborador` represente alocação de equipe Bike Tour.

As views `vw_kpis_turismo` e `vw_rentabilidade_turismo` permanecem
classificadas como estruturas analíticas e não como autoridades
transacionais.

Não foi identificada implementação funcional de Bike Tour além da fronteira
de módulo existente. A definição dos atributos, agregados e relacionamentos
específicos de Bike Tour permanece sujeita aos documentos subsequentes do
gate.

## 4. Necessidades específicas do domínio

Os itens abaixo estão na fronteira do domínio e não existem como entidade funcional certificada na baseline atual.

| Necessidade específica | Escopo provável | Autoridade esperada |
| -------------------------------- | --------------------------------------------- | ------------------- |
| produto específico da modalidade | ciclo, distância, nível, apoio e regras | Bike Tour |
| evento de Bike Tour | execução planejada e calendário | Bike Tour |
| bicicleta ou equipamento | recurso alocado à inscrição | Bike Tour |
| equipe e liderança | grupo, guia e suporte | Bike Tour |
| ponto de controle | parada e monitoramento operacional | Bike Tour |
| ocorrência e incidente | falha operacional, atraso ou emergência | Bike Tour |
| inscrição e participação | vínculo de pessoa ao evento e ao recurso | Bike Tour |
| logística de apoio | veículo, material e deslocamento | Bike Tour |
| disponibilidade por recurso | bicicleta, equipamento e equipe por intervalo | Bike Tour |

Essas entidades devem especializar o modelo de Turismo sem redefinir a raiz de venda, reserva, cliente, produto
geral ou contrato comercial.

## 5. Lacunas e riscos

1. A baseline atual não define recurso exclusivo de Bike Tour, como bicicleta, equipe, ponto de controle ou
   logística de suporte.
2. `reserva` e `vaga` ainda não expressam disponibilidade por recurso específico da modalidade.
3. A capacidade em Turismo não distingue modalidade, tipo de equipamento, nível de risco, tolerância e apoio
   operacional da rota.
4. Não há rastreabilidade documental entre evento, participante e recurso sem duplicar a entidade de reserva.
5. Ocorrência operacional e logística de apoio ainda são fatos ad hoc e não possuem um modelo de estado definido.
6. A regra de acesso e retenção de dados pessoais específicos do evento ainda precisa ser definida em segurança e
   privacidade.
7. A correlação entre venda/contrato e a inscrição de Bike Tour ainda não foi validada como contrato transacional.
8. O domínio não pode assumir autoridade direta sobre fatos financeiros ou comerciais sem quebrar a fronteira
   documentada.

## 6. Estruturas fora do escopo

Os itens abaixo permanecem fora do escopo da abertura documental da etapa 2.7:

- frontend e aplicativo móvel;
- integrações externas do site ou CRM;
- ajustes de financeiro, fiscal ou BI sem dependência explícita;
- migração estrutural da baseline histórica;
- criação de models, repositories, services ou rotas antes da aprovação do gate.

## 7. Decisões exigidas antes da implementação

Antes da implementação funcional, o gate documental deve decidir:

- distinguir produto comercial, pacote turístico e evento operacional de Bike Tour;
- definir se a inscrição usa a reserva existente ou cria uma especialização de reserva;
- definir a relação entre participante, cliente contratante e documento operacional;
- definir disponibilidade por bicicleta, equipe e ponto de controle;
- definir estados e transições de inscrição, ocorrência e logística;
- preservar a fronteira Comercial e Financeiro sem duplicação de fatos;
- aprovar política de privacidade e retenção de dados sensíveis do evento;
- definir a modelagem de recursos e suporte sem alterar a baseline da Fase 1.

## 8. Conclusão

O inventário confirma que a etapa 2.7 depende de uma base existente em Turismo e Core, mas ainda não possui a
modelagem e a regra transacional próprias da modalidade. A estrutura do módulo deve ser tratada como especialização
futura, não como duplicação de autoridade.

Este documento serve de base para o `BT-DOC-02` e demais entregáveis da etapa. A implementação funcional continua
bloqueada até a aprovação do gate documental.

---

## 9. Aceite formal

| Campo | Evidência |
| --- | --- |
| Responsável | Vaner, responsável pelo projeto |
| Data do aceite | 10/09/2026 |
| Documento e versão | BT-DOC-01 — Inventário de Bike Tour, versão 1.0 |
| Commit aceito | `f94f421d19bc118de0c645c917d9de4b88cb527c` |
| Origem | Manifestação explícita do responsável nesta revisão |
| Resultado | A1 fechado; BT-DOC-01 aprovado e aceito |

> Aprovo e aceito formalmente o BT-DOC-01 — Inventário de Bike Tour,
> versão consolidada no commit f94f421.

O registro atualiza apenas status e rastreabilidade. O conteúdo técnico aceito permanece referenciado ao commit
acima. As decisões da seção 7 seguem para os entregáveis subsequentes; A2–A8 continuam pendentes.

## Controle e Rastreabilidade

| Campo | Informação |
| ------------------ | ------------------------------- |
| Projeto | WMA Travel ERP |
| Etapa | 2.7.1 — Inventário de Bike Tour |
| Entregável | `BT-DOC-01` |
| Status | APROVADO E ACEITO |
| Última atualização | 10/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

<!-- cspell:ignore kpis Alocacao Correlacao -->
