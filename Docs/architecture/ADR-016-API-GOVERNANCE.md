# ADR-016 --- Governança e Ciclo de Vida da API

**Projeto:** WMA Travel ERP  
**Fase:** 2 --- Backend, API e Integrações  
**Etapa:** 2.3 --- Governança de API  
**Status:** APROVADA  
**Data:** 28/08/2026

## Contexto

A ADR-005 definiu REST/JSON, o prefixo `/api/v1`, schemas explícitos e OpenAPI como contrato. Com a conclusão das
etapas 2.0 a 2.2, a API passou a expor saúde, Core Corporativo e Segurança. A evolução dos próximos módulos exige
regras verificáveis para compatibilidade, depreciação e revisão do contrato.

## Decisão

1. O documento OpenAPI gerado pela aplicação é o contrato executável da API.
2. Operações funcionais permanecem sob `/api/v1`; endpoints estritamente técnicos podem permanecer fora da versão.
3. Toda operação deve declarar tag, `operationId`, respostas de sucesso e schemas de entrada e saída quando houver
   corpo.
4. Alterações aditivas compatíveis podem permanecer na versão atual.
5. Remoção, renomeação ou mudança incompatível de semântica, tipo, obrigatoriedade ou status exige nova versão.
6. Uma versão ou operação só pode ser depreciada com marcação OpenAPI, comunicação no changelog e alternativa
   documentada.
7. A retirada exige ao menos 180 dias desde o aviso de depreciação, salvo correção emergencial de segurança.
8. Pull requests que alterem rotas, schemas ou respostas devem incluir teste de contrato e registrar o impacto.
9. Coleções potencialmente grandes devem adotar paginação antes de uso produtivo externo.
10. Erros seguem a ADR-011 e devem preservar o correlation ID definido pela ADR-012.

## Classificação de compatibilidade

| Classe | Exemplos | Tratamento |
| --- | --- | --- |
| aditiva | novo endpoint ou campo opcional | permitida em `/api/v1` |
| comportamental compatível | correção sem quebra do contrato | permitida com testes |
| incompatível | remoção, tipo alterado ou novo campo obrigatório | nova versão |
| segurança emergencial | bloqueio de comportamento vulnerável | exceção documentada |

## Fiscalização

O conjunto mínimo de CI deve verificar:

- geração válida do OpenAPI;
- unicidade e presença de `operationId`;
- tags e respostas de sucesso em todas as operações;
- schemas de sucesso e erro nos contratos aplicáveis;
- testes automatizados e cobertura integral exigida pelo projeto.

O snapshot canônico `Backend/openapi.json` deve acompanhar a aplicação. O comando
`python scripts/export_openapi.py --check` fiscaliza essa correspondência no CI, enquanto o diff do snapshot torna
mudanças de contrato visíveis para revisão no pull request.

Em pull requests, `python scripts/check_openapi_compatibility.py` compara o snapshot com a branch-base e bloqueia
remoções, novas obrigatoriedades e alterações incompatíveis conhecidas. O classificador é conservador e deve ser
ampliado quando o projeto adotar novas construções OpenAPI.

## Consequências

- mudanças de API passam a declarar compatibilidade explicitamente;
- consumidores recebem uma janela previsível de migração;
- o OpenAPI deixa de ser apenas documentação e integra o gate de mudança;
- manter duas versões simultâneas pode elevar o custo operacional.

## Relação com o planejamento

A etapa 2.3 é Governança de API. O bloco anteriormente denominado 2.3 --- Comercial permanece preservado como
planejamento legado, sem autorização de execução, até a revisão aditiva da numeração das etapas subsequentes.

## Status

**APROVADA**

Esta ADR complementa as ADR-005, ADR-011 e ADR-012 sem alterar o histórico dessas decisões.
