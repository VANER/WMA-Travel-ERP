# WMA Travel ERP — Preparação da Etapa 2.8

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Etapa:** 2.8 — Integração wmatravel.com.br
> **Tipo de documento:** Plano de preparação
> **Versão:** 1.0
> **Data:** 06/10/2026
> **Status:** EM PREPARAÇÃO — INVENTÁRIO EXTERNO PENDENTE

## 1. Objetivo e autorização

Preparar a implementação da integração entre o site e o ERP após o
[fechamento final da 2.7](certification/PHASE_2_7_BIKE_TOUR_FINAL_CLOSURE.md).
A solicitação do responsável autoriza esta preparação e o levantamento da 2.8.1.
Este plano não declara a integração implementada nem autoriza mudanças no site produtivo.

O ERP permanece núcleo corporativo; o site é canal digital conectado por HTTPS/API e webhooks.
Não haverá acesso do WordPress ao PostgreSQL corporativo. Frontend React e Mobile permanecem fora do escopo.

## 2. Fontes e divergências resolvidas para execução

- [ADR-017](architecture/ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md): integração do site corresponde à 2.8.
- [ADR-015](architecture/ADR-015-WEBSITE-INTEGRATION.md): arquitetura da integração; sua referência histórica
  à 2.7 antecede a reprogramação e permanece preservada.
- [ADR-009](architecture/ADR-009-INTEGRATIONS.md): adaptadores, timeouts, retries limitados e idempotência.
- [Ordem oficial](PHASE_2_EXECUTION_ORDER.md): sequência executiva 2.8.1–2.8.10.
- [Roadmap](PHASE_2_ROADMAP.md): seis blocos temáticos; não constituem uma segunda sequência executiva.

| Bloco temático do roadmap | Entregas da ordem oficial |
| --- | --- |
| Inventário | 2.8.1 |
| Mapeamento | 2.8.2 |
| API | 2.8.3–2.8.6 |
| Sincronização | 2.8.4–2.8.6 e 2.8.8 |
| Webhooks | 2.8.7 |
| Segurança | 2.8.3, com testes em 2.8.9 e certificação em 2.8.10 |

## 3. Baseline conhecida e limites do levantamento

As etapas 2.1–2.7 estão integradas. O Backend contém os domínios Corporativo, Segurança, Comercial,
Financeiro, Turismo e Bike Tour. `Backend/app/integrations/` contém o adaptador de e-mail Titan;
não foi identificado adaptador de integração do website nesse pacote.
As fronteiras existentes em `Backend/app/shared/` devem ser avaliadas antes de propor novos contratos.
Sua existência não significa que estejam prontas para exposição ao canal externo.

WordPress e WooCommerce são tecnologias previstas pelos documentos oficiais. Versões, plugins, endpoints,
campos e configuração efetivamente ativos no site ainda não foram verificados nesta preparação.
Não houve acesso administrativo ao site, teste de escrita, consulta a dados pessoais ou transação financeira.

## 4. Inventário 2.8.1 — informações necessárias

| ID | Informação ou evidência sanitizada | Estado | Responsável a confirmar |
| --- | --- | --- | --- |
| I01 | URL de homologação, isolamento de produção e permissões de leitura | PENDENTE | Responsável do site |
| I02 | Versões WordPress/WooCommerce, plugins ativos e customizações | PENDENTE | Responsável do site |
| I03 | Produtos, categorias, variações, datas, capacidade e regras de preço | PENDENTE | Operação/Turismo |
| I04 | Pedidos, clientes, passageiros, formulários e campos personalizados | PENDENTE | Comercial/site |
| I05 | Provedores de pagamento, estados, estornos e ambiente de testes | PENDENTE | Financeiro/site |
| I06 | APIs e webhooks habilitados, documentação e amostras sem dados pessoais | PENDENTE | Responsável do site |
| I07 | Volumes, frequência, limites, latência aceitável e retenção | PENDENTE | Operação/site |
| I08 | Gestão de credenciais exclusivas, rotação e responsáveis por acesso | PENDENTE | Segurança/site |

Registrar origem, data, ambiente e responsável de cada evidência. Não versionar exportações com clientes,
senhas, tokens, chaves ou dados de pagamento. Referenciar o mecanismo de secrets sem registrar seus valores.
Sem homologação confirmada, concluir somente o inventário documental; não disparar operações em produção.
Em 06/10/2026, o responsável informou ainda não conhecer o ambiente disponível e solicitou registrar a pendência.
Nenhuma URL de homologação, versão de plugin ou capacidade externa foi presumida.

## 5. Mapeamento preliminar a validar em 2.8.2

| Fluxo | Autoridade corporativa candidata | Decisão ainda necessária |
| --- | --- | --- |
| ERP → catálogo do site | Turismo | Produtos, preços, datas e versão da publicação |
| Site → lead/cliente/pedido | Corporativo e Comercial | Identidade externa, deduplicação e criação autorizada |
| Site → reserva/passageiros | Turismo | Capacidade, concorrência, consentimento e cancelamento |
| Provedor/site → pagamento | Financeiro | Evidência de liquidação, estados e tratamento de estorno |
| Oferta Bike Tour no canal | Bike Tour e Turismo | Confirmar inclusão na primeira entrega e limites de autoridade |

Não inferir pagamento confirmado de um estado textual do pedido. Não reservar vagas sem as regras
transacionais do domínio. IDs externos devem ser correlacionados, sem substituir chaves corporativas.
O aceite deve definir autoridade por campo, direção, transformação, conflito e fonte de cada evento.

## 6. Sequência e critérios de aceite

| Etapa | Entrega concreta | Aceite mínimo |
| --- | --- | --- |
| 2.8.1 | Inventário do site com evidências I01–I08 | Ambiente e capacidades reais identificados; lacunas explícitas |
| 2.8.2 | Matriz de entidades, campos, estados e autoridades | Mapeamento revisado pelos responsáveis de domínio |
| 2.8.3 | Contrato de segurança e desenho da integração | Autenticação exclusiva, HTTPS, limites, validação e auditoria definidos |
| 2.8.4 | Adaptador e contrato de catálogo | Publicação repetível sem duplicação; regras de preço e capacidade preservadas |
| 2.8.5 | Entrada Comercial/Turismo | Pedido, cliente, reserva e passageiros sem duplicação ou excesso de vagas |
| 2.8.6 | Integração Financeira | Confirmação e estorno autenticados e reconciliáveis, sem dupla contabilização |
| 2.8.7 | Processamento de webhooks | Autenticidade, repetição, ordem e falhas tratados de forma auditável |
| 2.8.8 | Reconciliação e reprocessamento | Divergências detectadas; recuperação controlada sem perda de eventos |
| 2.8.9 | Testes de contrato e ponta a ponta em homologação | Casos positivos e negativos aprovados com evidências sanitizadas |
| 2.8.10 | Certificação e integração por PR | Gates locais/remotos aprovados, operação e recuperação documentadas |

As cinco semanas do roadmap são estimativa histórica, não compromisso de início ou término.
O primeiro incremento de código deve ser pequeno e escolhido após 2.8.1–2.8.3; catálogo somente leitura
é candidato, sujeito às capacidades e ao mapeamento confirmados. Não criar endpoints ou schema por suposição.

## 7. Decisões exigidas antes do código de integração

- protocolo de autenticação máquina a máquina e validação de webhooks conforme o provedor real;
- contrato de payload, limites, erros HTTP, versão e documentação OpenAPI;
- idempotência, ordenação, repetição, timeouts e política de retries com limites;
- correlação de IDs, estados de processamento, armazenamento e retenção;
- isolamento de transações, concorrência e compensação após falhas externas;
- necessidade de migration aditiva e plano de reversão, sem alterar migrations aplicadas;
- métricas, logs sem dados pessoais, auditoria e responsáveis pelo reprocessamento;
- escopo do primeiro incremento e critérios mensuráveis de sucesso em homologação.

## 8. Plano mínimo de testes e gates

Cobrir autenticação ausente/inválida, payload inválido, evento duplicado, replay, evento fora de ordem,
timeout, indisponibilidade, retry esgotado, concorrência por vaga, cancelamento e estorno repetidos.
Verificar que logs não revelam credenciais nem dados pessoais e que falhas não deixam transação parcial.
Usar simuladores locais e dados sintéticos; testes externos dependem do ambiente de homologação identificado.

Os gates Backend seguem o AGENTS.md: dependências, Ruff, Mypy, pytest com cobertura e árvore Alembic.
Mudanças de API exigem `python scripts/export_openapi.py --check`, executado em `Backend/`, e testes de contrato.
Mudanças de banco exigem baseline migrada em banco descartável e validação de reversão quando segura.
Documentation CI, Backend CI e Secret Scan devem passar no PR e após o merge.
Nenhum desses testes de integração da 2.8 foi executado ou declarado aprovado nesta preparação.

## 9. Estado de prontidão

```text
PHASE_2_7=CLOSED
PHASE_2_8=PREPARATION
NEXT_EXECUTION=2.8.1_SITE_INVENTORY
EXTERNAL_INVENTORY=PENDING
IMPLEMENTATION_READINESS=BLOCKED_BY_EXTERNAL_INVENTORY_AND_CONTRACTS
PRODUCTION_CHANGES=NOT_AUTHORIZED_BY_THIS_PLAN
```

A próxima ação concreta é obter I01–I08 e fechar o inventário com os responsáveis. Ausência dessas evidências
é pendência da 2.8, não reabertura da certificação Bike Tour. Nenhum aceite externo é presumido.
