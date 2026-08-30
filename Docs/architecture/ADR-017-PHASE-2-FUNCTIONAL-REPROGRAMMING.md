# ADR-017 --- Reprogramação Funcional da Fase 2

**Status:** APROVADA

**Data:** 29/08/2026

**Decisão:** reinserir o módulo Comercial como etapa 2.4 e deslocar, sem sobreposição, as etapas funcionais
posteriores.

## Contexto

A ADR-016 reservou a etapa 2.3 para Governança de API e preservou o planejamento Comercial anterior como bloco
legado suspenso. Após a certificação e integração da 2.3, a continuidade da Fase 2 exige uma sequência oficial que
restabeleça o Comercial antes dos módulos que dependem de vendas, propostas, contratos e reservas.

## Decisão

A sequência oficial posterior à 2.3 passa a ser:

| Etapa | Entrega |
| --- | --- |
| 2.4 | Comercial |
| 2.5 | Financeiro |
| 2.6 | Turismo |
| 2.7 | Bike Tour |
| 2.8 | Integração wmatravel.com.br |
| 2.9 | Fiscal |
| 2.10 | Integrações Externas |
| 2.11 | BI/DW |
| 2.12 | Auditoria e Observabilidade |
| 2.13 | Qualidade e Hardening |
| 2.14 | Certificação da Fase 2 |

Os antigos identificadores 2.4 a 2.13 eram projeções ainda não iniciadas e não possuíam certificações próprias.
Seu deslocamento é exclusivamente prospectivo. A etapa 2.3, suas subetapas, evidências, PRs e certificação não
podem ser renumerados.

## Dependências

- Comercial depende das fundações 2.1, 2.2 e 2.3;
- Financeiro depende do Core e da integração Comercial;
- Turismo depende de Comercial e Financeiro;
- módulos posteriores mantêm suas dependências funcionais, ajustadas apenas à nova numeração;
- nenhuma etapa posterior pode começar antes da certificação de seu predecessor obrigatório.

## Consequências

- `PHASE_2_ROADMAP.md` e `PHASE_2_EXECUTION_ORDER.md` devem refletir a mesma sequência;
- a próxima execução autorizada é 2.4.1 --- Inventário Comercial;
- referências históricas permanecem imutáveis;
- novas certificações devem usar exclusivamente a numeração reprogramada.

## Gate

A reprogramação é considerada concluída quando cronograma, ordem executiva, índices e documentos de estado não
apresentarem colisões de numeração e declararem a 2.4.1 como próxima execução.
