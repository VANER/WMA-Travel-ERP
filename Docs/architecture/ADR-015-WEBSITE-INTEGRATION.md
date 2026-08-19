# ADR-015 --- Integração com wmatravel.com.br

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Arquitetura Tecnológica\
**Status:** APROVADA\
**Data:** 18/08/2026

## Contexto

O wmatravel.com.br é canal digital do negócio e precisa trocar catálogo,
disponibilidade, clientes, reservas/pedidos e estados de pagamento com o
ERP.

## Problema

Evitar duas fontes conflitantes de verdade e impedir acesso inseguro do
WordPress/WooCommerce ao banco corporativo.

## Decisão

Tratar o ERP como núcleo corporativo e o website como canal integrado
por HTTPS/API e webhooks. O website nunca acessará diretamente o
PostgreSQL do ERP. Mapeamentos e propriedade de dados serão definidos
por entidade durante a etapa 2.7.

## Alternativas consideradas

- Banco compartilhado entre WordPress e ERP --- proibido.
- Sincronização manual como solução principal --- rejeitada.
- Website como autoridade de todos os dados comerciais --- rejeitado
    por fragmentar governança.

## Consequências positivas

- Fonte corporativa consistente.
- Integração auditável.
- Segurança por isolamento.
- Possibilidade de trocar/evoluir o website sem redesenhar o domínio.

## Consequências negativas

- Sincronização exige tratamento de conflitos.
- Dependência de APIs/plugins do website.
- Pode haver latência entre sistemas em fluxos assíncronos.

## Regras obrigatórias

- Comunicação somente por HTTPS/API/webhooks.
- Credenciais exclusivas para a integração.
- Idempotência para pedidos, reservas e pagamentos.
- Mapear IDs externos sem substituir chaves internas.
- Não expor entidades/tabelas internas desnecessariamente.
- Registrar falhas e permitir reconciliação.
- LGPD e minimização de dados devem ser respeitadas.

## Critérios de reavaliação

Esta decisão deverá ser reavaliada quando ocorrer um ou mais dos
seguintes cenários:

- Substituição de WordPress/WooCommerce.
- Marketplace ou múltiplos canais digitais.
- Necessidade de sincronização em volume muito maior.
- Mudança da autoridade de dados.
- Adoção de arquitetura orientada a eventos.

## Status

**APROVADA**

Esta ADR integra a certificação da ETAPA 2.0.1 da Fase 2. Alterações
substanciais nesta decisão deverão ser registradas por nova ADR ou por
revisão formal rastreável, sem apagar o histórico da decisão original.
