# WMA Travel ERP — Gate Documental da Etapa 2.6

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Etapa:** 2.6 — Turismo
> **Módulo:** Turismo
> **Tipo de documento:** Gate Documental
> **Versão:** 1.0
> **Data:** 04/09/2026
> **Status:** APROVADO

## 1. Objetivo

Definir os documentos e critérios que devem anteceder a implementação funcional de Turismo. Este gate autoriza
somente inventário, análise e decisões documentais; não autoriza models, migrations, endpoints ou regras de
negócio.

## 2. Dependências satisfeitas

- etapas 2.0 a 2.5 concluídas, certificadas e integradas;
- Core Corporativo como autoridade cadastral;
- Comercial como autoridade de venda e contrato;
- Financeiro como autoridade de lançamento, pagamento e conciliação;
- sequência funcional definida pela ADR-017.

## 3. Fontes de verdade

| Fonte | Autoridade |
| --- | --- |
| `Docs/PHASE_2_EXECUTION_ORDER.md` | Ordem e dependências oficiais da etapa 2.6 |
| `Docs/PHASE_2_ROADMAP.md` | Escopo macro e sequência da Fase 2 |
| `Docs/architecture/ADR-017-PHASE-2-FUNCTIONAL-REPROGRAMMING.md` | Posicionamento de Turismo após a 2.5 |
| `Docs/DATABASE_STANDARDS.md` | Regras normativas de banco |
| `Docs/GOVERNANCE.md` | Autoridades, mudança e rastreabilidade |
| `Database/scripts/WmaTravelERP.sql` | Baseline executável certificada |
| `Docs/DATA_DICTIONARY.md` | Catálogo dos objetos da baseline |
| `Backend/openapi.json` | Contrato executável atual da API |

## 4. Entregáveis obrigatórios

| ID | Entregável | Resultado esperado | Status |
| --- | --- | --- | --- |
| TUR-DOC-01 | Inventário de Turismo | Objetos, relações, autoridades e lacunas identificados | APROVADO |
| TUR-DOC-02 | Matriz funcional | Fluxos e regras relacionados às estruturas existentes | APROVADO |
| TUR-DOC-03 | Matriz de rastreabilidade | Requisito → dado → serviço → API → teste | APROVADO |
| TUR-DOC-04 | Fronteiras de domínio | Core, Comercial, Financeiro, Turismo e Bike Tour delimitados | APROVADO |
| TUR-DOC-05 | Política transacional | Reserva, vaga, cancelamento e compensação definidos | APROVADO |
| TUR-DOC-06 | Segurança e privacidade | Permissões, dados de passageiros e auditoria definidos | APROVADO |
| TUR-DOC-07 | Plano de testes | Concorrência, capacidade, datas, falhas e regressões definidos | APROVADO |
| TUR-DOC-08 | Decisão de schema | Ausência de delta ou migration aditiva justificada | APROVADO |

## 5. Critérios para iniciar implementação

- [x] baseline e objetos existentes inventariados;
- [x] autoridades externas iniciais identificadas;
- [x] lacunas estruturais registradas sem alteração retroativa;
- [x] fluxo Produto → Pacote → Saída → Reserva → Passageiro aprovado;
- [x] semântica funcional de saída, capacidade, disponibilidade e vaga definida;
- [x] vínculo entre Venda, Contrato, Reserva e Financeiro aprovado;
- [x] tratamento de dados pessoais de passageiros aprovado;
- [x] limites transacionais e estratégia de concorrência aprovados;
- [x] contratos de API e matriz de respostas definidos;
- [x] plano de testes e decisão de schema aprovados.

## 6. Próxima execução autorizada

Os entregáveis `TUR-DOC-01` a `TUR-DOC-08` estão aprovados. O gate autoriza a implementação e certificação da
Etapa 2.6 conforme a ADR-019. A Etapa 2.7 permanece bloqueada até a integração da 2.6.

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.0 |
| Status | APROVADO |
| Última atualização | 04/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
