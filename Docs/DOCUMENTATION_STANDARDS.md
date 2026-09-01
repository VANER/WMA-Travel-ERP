# WMA Travel ERP — Padrões de Documentação

> **Projeto:** WMA Travel ERP
> **Empresa:** WMA Travel Ltda.
> **Fase:** Fase 2 — Backend, API e Integrações
> **Tipo de documento:** Norma de Documentação
> **Versão:** 1.0
> **Data:** 01/09/2026
> **Status:** VIGENTE

## 1. Objetivo

Definir as regras de classificação, identidade, metadados, status, rastreabilidade, cabeçalhos, rodapés e
templates da documentação do WMA Travel ERP.

## 2. Princípios

- preservar a baseline e as evidências históricas certificadas;
- manter documentos vivos sincronizados com o estado verificável do projeto;
- não inventar datas, versões, responsáveis, commits, pull requests, CI ou certificações;
- aplicar consistência dentro de cada família documental;
- usar português do Brasil e as regras de `.markdownlint.jsonc` e `.cspell.json`;
- registrar divergências entre fontes sem reescrever silenciosamente a história.

## 3. Famílias documentais

| Família | Exemplos | Regra de evolução |
| --- | --- | --- |
| Institucional | README, índices e apresentação | Documento vivo e sintético |
| Documento vivo | roadmap, ordem de execução, changelog e guias | Deve acompanhar o estado atual |
| Documentação técnica | contratos, módulos e inventários ativos | Evolução controlada e rastreável |
| Planejamento | roadmap e cronogramas de execução | Atualização conforme gates oficiais |
| Norma ou padrão | padrões, segurança e governança | Alteração com análise de impacto |
| Certificação | `Docs/certification/` | Registro histórico após encerramento |
| ADR | `Docs/architecture/ADR-*` | Essencialmente imutável após aprovação |
| Evidência histórica | baseline, logs e certificações de banco | Não alterar por estética |
| Template | `Docs/templates/` | Documento vivo para novas entregas |

O inventário e a classificação individual estão em `Docs/DOCUMENTATION_INVENTORY.md`.

## 4. Fontes de verdade

```text
Git e CI
  → certificação
  → PHASE_2_EXECUTION_ORDER
  → PHASE_2_ROADMAP
  → PROJECT_DOCUMENTATION
  → README
```

Para arquitetura, ADR precede documentação técnica e implementação. Para banco, baseline e migrations precedem
normas derivadas, documentação e models. O README nunca é fonte primária de certificação.

## 5. Identidade institucional

| Elemento | Forma oficial |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Fase 1 | Fase 1 — Fundação e Banco de Dados |
| Fase 2 | Fase 2 — Backend, API e Integrações |
| Arquitetura | Monólito Modular |
| Banco | PostgreSQL 18.x |
| Backend | Python 3.13+, FastAPI, SQLAlchemy 2, Alembic e Pydantic |
| API | REST sob `/api/v1`, com OpenAPI versionado |

Documentos legais e históricos preservam a denominação registrada no momento de sua emissão.

## 6. Cabeçalho de documentos vivos e novos

O cabeçalho usa uma H1 e um bloco de metadados. Somente campos aplicáveis são incluídos:

```markdown
# WMA Travel ERP — Título do Documento

> **Projeto:** WMA Travel ERP  
> **Empresa:** WMA Travel Ltda.  
> **Fase:** Fase 2 — Backend, API e Integrações  
> **Etapa:** 2.X — Nome  
> **Módulo:** Nome  
> **Tipo de documento:** Documento Técnico  
> **Versão:** 1.0  
> **Data:** DD/MM/AAAA  
> **Status:** STATUS CONTROLADO
```

Não inserir módulo, etapa ou qualquer metadado sem aplicação ou evidência real. Documentos institucionais podem
usar um cabeçalho reduzido. ADRs preservam seu formato próprio.

## 7. Vocabulário de status

Documentos vivos usam preferencialmente:

- `PLANEJADA`;
- `EM EXECUÇÃO`;
- `IMPLEMENTADA`;
- `EM CERTIFICAÇÃO`;
- `CERTIFICADA`;
- `INTEGRADA`;
- `CONCLUÍDA, CERTIFICADA E INTEGRADA`;
- `BLOQUEADA`;
- `SUPERADA`;
- `ARQUIVADA`;
- `VIGENTE`, para normas em aplicação.

Condições como CI pendente ou aprovação local pertencem às evidências, não criam novos estados institucionais.
Certificações históricas podem preservar o vocabulário vigente quando foram emitidas.

## 8. Rodapé de documentos vivos e novos

Documentos formais vivos usam a seção `Controle do Documento`, com projeto, empresa, versão, status, última
atualização, repositório e documento mestre quando esses dados forem verificáveis. O encerramento oficial é:

```markdown
**WMA Travel ERP — Documento oficial e versionado do projeto.**
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**
```

Campos irrelevantes são omitidos. Evidências e certificações históricas não recebem novos rodapés apenas por
estética. Novas certificações usam a seção `Controle e Rastreabilidade` do template oficial.

## 9. Templates oficiais

| Finalidade | Template |
| --- | --- |
| Documento técnico | `Docs/templates/TECHNICAL_DOCUMENT_TEMPLATE.md` |
| Certificação | `Docs/templates/CERTIFICATION_TEMPLATE.md` |
| Cronograma de execução | `Docs/templates/EXECUTION_SCHEDULE_TEMPLATE.md` |
| ADR | `Docs/templates/ADR_TEMPLATE.md` |

Seções não aplicáveis podem ser removidas de documentos simples; se a ausência for relevante, ela deve ser
declarada expressamente.

## 10. Regras de Markdown

- uma única H1;
- títulos ATX;
- linhas de texto limitadas a 120 caracteres;
- blocos de código com linguagem;
- listas cercadas por linhas em branco;
- links Markdown válidos;
- uma única quebra de linha ao final do arquivo;
- sem alteração das configurações de lint para ocultar erros.

Catálogos gerados a partir da baseline podem ter exceção explícita em `.markdownlintignore` quando a correção
exigiria reformatar massivamente conteúdo certificado sem ganho semântico. A exceção não se aplica a documentos
escritos manualmente nem permite ocultar links quebrados ou metadados contraditórios.

---

## Controle do Documento

| Campo | Informação |
| --- | --- |
| Projeto | WMA Travel ERP |
| Empresa | WMA Travel Ltda. |
| Versão | 1.0 |
| Status | VIGENTE |
| Última atualização | 01/09/2026 |
| Repositório | `VANER/WMA-Travel-ERP` |
| Documento mestre | `Docs/PROJECT_DOCUMENTATION.md` |

**WMA Travel ERP — Documento oficial e versionado do projeto.**  
**Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.**

Alterações neste documento devem ser versionadas e manter a rastreabilidade pelo Git.
