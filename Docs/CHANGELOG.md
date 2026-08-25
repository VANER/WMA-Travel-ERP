# Changelog

<!-- WMA_PHASE_1_CHANGELOG_CLOSE -->

## [Não Publicado]

### Adicionado

- fluxo ponta a ponta do Core Corporativo contra PostgreSQL descartável para a etapa 2.1.7;
- plano verificável de testes das regras, persistência e API corporativas;
- API versionada das nove autoridades corporativas, com 27 operações de consulta e cadastro;
- paginação validada, respostas de conflito seguras e contratos corporativos publicados no OpenAPI;
- testes HTTP e documentação do contrato da etapa 2.1.6;
- certificação da etapa 2.1.6 com validação completa no CI Linux/PostgreSQL;
- schemas Pydantic de entrada e saída para as nove autoridades corporativas;
- testes de limites, defaults, campos administrados pelo servidor e conversão ORM da etapa 2.1.5;
- certificação da etapa 2.1.5 com validação completa no CI Linux/PostgreSQL;
- services cadastrais das nove autoridades corporativas, com commit e rollback explícitos;
- testes dos limites transacionais e da propagação de falhas da etapa 2.1.4;
- certificação da etapa 2.1.4 com validação real na baseline e no CI Linux/PostgreSQL;
- repositories tipados das nove autoridades corporativas, sem commit autônomo e com paginação limitada;
- testes dos contratos de persistência e dos limites transacionais da etapa 2.1.3;
- certificação da etapa 2.1.3 com validação real na baseline e no CI Linux/PostgreSQL;
- models SQLAlchemy das nove autoridades do Core Corporativo, com registro Alembic e testes de fidelidade;
- validação de ausência de diferenças entre os models 2.1.2 e uma restauração descartável da baseline;
- evidência aditiva da reauditoria completa da fundação 2.0;
- inventário verificável das autoridades, dependências e fronteiras do Core Corporativo para a etapa 2.1.1;
- health check HTTP validado contra PostgreSQL 18 real e descartável na certificação da fundação 2.0.11;
- regressão automatizada para o limite de conexão das migrations;
- serviço PostgreSQL 18 descartável e teste real no pipeline da etapa 2.0.10;
- gates de formatação, limite de execução e regressão da configuração do GitHub Actions;
- teste de integração opt-in contra PostgreSQL local descartável para a etapa 2.0.9;
- proteção que restringe a integração a hosts locais e bancos com sufixo `_test`;
- certificação da etapa 2.0.9 com PostgreSQL 18 real descartável e validação Linux/CI;
- matriz documental consolidada das fases e das etapas 2.0.1 a 2.0.8;
- documentação OpenAPI 3.1 da etapa 2.0.8 em `/docs`, `/redoc` e `/openapi.json`;
- metadata explícita, tags, contratos de sucesso e erros padronizados no schema OpenAPI;
- testes automatizados de documentação, versionamento, schemas e unicidade de operation IDs;
- router principal versionado e tratamento padronizado de erros HTTP da etapa 2.0.7;
- testes dos contratos `GET /health`, `GET /api/v1/health`, 404 e 405;
- configuração e política Alembic da etapa 2.0.6, com proteção da baseline no autogenerate;

### Alterado

- referências correntes que ainda apontavam para etapas 2.0 já concluídas e versões mínimas anteriores da stack;
- reconciliação documental da fundação 2.0 com o estado certificado e integrado da `main`;
- Alembic alinhado ao timeout de conexão configurado pela aplicação.
- CI ampliado para formatar migrations e aplicar `alembic upgrade head` no PostgreSQL descartável.
- gate da árvore Alembic preparado para futuras revisions lineares sem permitir branches ou merges.
- status e evidências pós-merge das etapas 2.0.2, 2.0.8 a 2.0.11 reconciliados.
- convenções SQLAlchemy para nomes de constraints e índices;
- testes da árvore de revisions e documentação de upgrade e downgrade;
- integração PostgreSQL/SQLAlchemy da etapa 2.0.5 com pool explícito e pre-ping;
- certificação da etapa 2.0.5 com validação real no PostgreSQL local do Windows;
- limite transacional reutilizável com commit em sucesso e rollback em falha;
- health check `GET /api/v1/health/database` com resposta segura para indisponibilidade;
- configuração central da etapa 2.0.4 com ambientes validados e proteção de valores sensíveis;
- certificação da etapa 2.0.4 com testes de ambiente, secrets e logging seguro;
- logging técnico em JSON com contexto HTTP, duração e correlation ID;
- bloqueio de nível `DEBUG` em produção e validação do driver PostgreSQL oficial;
- estrutura modular da etapa 2.0.3 com fronteiras para Comercial, Financeiro, Turismo, Bike Tour e Fiscal;
- pacotes reservados a integrações e recursos compartilhados, com regras explícitas de uso;
- gate automatizado que bloqueia imports diretos entre implementações internas de domínios;
- certificação técnica da etapa 2.0.3 com validação equivalente em Windows e Linux;
- bootstrap da etapa 2.0.2 em `Backend/` com FastAPI, SQLAlchemy 2, Alembic e psycopg 3;
- configuração por ambiente, correlation ID e contrato inicial de health check;
- testes HTTP e configuração de lint, tipagem e cobertura para Python 3.13+;
- pipeline de integração contínua do backend com lint, tipagem, testes e validação Alembic.
- lockfiles separados para Windows e Linux, com hashes e instalação reprodutível no CI;
- certificação técnica da etapa 2.0.2 e atualização dos status oficiais das etapas 2.0.1 e 2.0.2.

### Corrigido na etapa 2.0.2

- separação entre o identificador da etapa 2.0.2 e a versão SemVer do projeto;
- obrigatoriedade de configuração explícita da conexão PostgreSQL, sem fallback embutido no código.
- indicadores documentais obsoletos que ainda apresentavam a etapa 2.0.1 como em execução.

### Corrigido

- referências que ainda indicavam a Fase 2 como planejamento ou o PR #11 como pendente de integração;
- inclusão de `residuos_teste` no gate bloqueante efetivo da F1-FIN.13;
- remoção de duplicatas residuais concatenadas no changelog e no roadmap;
- validação ausente referenciada pelo instalador;
- falha silenciosa de `--with-validation`;
- portabilidade segura dos scripts F1-FIN para bancos de rebuild;
- hashes das certificações após normalização de encoding;
- caminhos legados e bloco Markdown inválido nas certificações;
- indicadores documentais desatualizados da Fase 1.

### Verificado

- execução final somente leitura da F1-FIN.13, com log e certificação específicos;
- gate bloqueante com zero resíduos de teste e status `F1_FIN_13_CERTIFICADA`;
- reconstrução do dump histórico em banco descartável;
- aplicação completa da evolução F1-FIN;
- equivalência quantitativa de 220 tabelas, 1.433 constraints, 391 índices e 217 sequences;
- certificação `F1_FIN_13_CERTIFICADA` no banco oficial e no rebuild;
- zero constraints inválidas, triggers desabilitados ou tabelas não excepcionadas sem PK.

## [0.2.0] - 2026-08-17

### Added

- certificação definitiva da baseline PostgreSQL;
- certificações das ETAPAS 10.12.3 a 10.12.6;
- certificação global da Fase 1;
- documento formal de transição da Fase 1 para a Fase 2;
- validação de reconstrução independente;
- comparação estrutural baseline × rebuild;
- validação de reprodutibilidade;
- hashes normalizados para certificação.

### Changed

- status da Fase 1 para concluída e certificada;
- referência técnica do banco para PostgreSQL 18.4;
- governança de alterações estruturais para migrations versionadas;
- preparação formal para início da Fase 2.

### Verified

- 8 schemas;
- 209 tabelas;
- 38 views;
- 206 sequences;
- 1176 constraints;
- 357 índices;
- 64 functions;
- 11 procedures;
- 138 triggers;
- 0 divergências estruturais críticas impeditivas.

### Project

- Fase 1 formalmente encerrada.
- Baseline certificada: `d63800e`.
- Transição para Fase 2 autorizada.

Todas as alterações relevantes do projeto **WMA Travel ERP** serão documentadas neste arquivo.

Este changelog segue o padrão **Keep a Changelog 1.1.0**
e o projeto utiliza **Versionamento Semântico (Semantic Versioning 2.0.0)**.

---

## Sumário

- [Política de Versionamento](#política-de-versionamento)
- [Não Publicado](#não-publicado)
- [1.0.0 - 2026-07-29](#100---2026-07-29)
- [Categorias](#categorias)
- [Referências](#referências)

---

## Política de Versionamento

O projeto segue os padrões:

- Keep a Changelog 1.1.0.
- Semantic Versioning 2.0.0.

Formato da versão:

```text
MAJOR.MINOR.PATCH
```

Exemplo:

```text
1.0.0
```

Significado dos números:

- **MAJOR**: alterações incompatíveis ou grandes mudanças arquiteturais.
- **MINOR**: novas funcionalidades e melhorias.
- **PATCH**: correções e ajustes de manutenção.

---

## Planejamento registrado anteriormente

Alterações planejadas para próximas versões.

### Adicionado

- Documento DATABASE_STANDARDS.md, consolidando os padrões técnicos de nomenclatura e modelagem do banco.
- Dashboards avançados de Business Intelligence.
- Framework inicial de integração com Inteligência Artificial.
- Expansão dos endpoints da API.
- Melhorias no monitoramento de desempenho.
- Novos módulos de relatórios gerenciais.

### Alterado

- Melhorias na documentação.
- Refinamentos internos da arquitetura.

### Depreciado

- Nenhum recurso depreciado.

### Removido

- Nenhum recurso removido.

### Corrigido

- Recuperação física dos arquivos DEPLOYMENT.md, GOVERNANCE.md, SECURITY.md, STYLE_GUIDE.md e
  DBA_FRAMEWORK.md, que constavam como concluídos na documentação (CHANGELOG, README,
  PROJECT_DOCUMENTATION) desde a v1.0.0, mas não existiam fisicamente no diretório do projeto.
  Conteúdo gerado e validado contra `_markdownlint.jsonc` em 2026-08-09.

### Segurança

- Melhorias contínuas de segurança.

---

## Histórico de Versões

## [1.0.0] - 2026-07-29

Primeira versão oficial do projeto **WMA Travel ERP**.

---

### Alterações da versão git init

#### Fundação do Projeto

- Estrutura inicial do repositório corporativo.
- Framework de documentação empresarial.
- Padronização da organização do projeto.
- Implantação do Versionamento Semântico.
- Padrões profissionais de documentação de software.

### Arquitetura do Banco de Dados

- Arquitetura corporativa utilizando PostgreSQL.
- Aproximadamente 190 tabelas estruturadas.
- Mais de 140 relacionamentos por chave estrangeira.
- Framework de governança de banco de dados.
- Framework de certificação da base de dados.
- Framework de validação da saúde do banco.
- Estrutura de auditoria técnica.
- Sistema de cálculo automático de qualidade.
- Padronização de nomenclatura.
- Catálogo de metadados técnicos.

### Módulos ERP

- Gestão Financeira.
- Gestão Comercial.
- Gestão Administrativa.
- Gestão de Turismo.
- Gestão WMA Bike Tour.
- Gestão de Relacionamento com Clientes (CRM).
- Fundação para Business Intelligence.

### Módulo Financeiro

- Plano de Contas corporativo.
- Fluxo de Caixa.
- Contas a Pagar.
- Contas a Receber.
- Centros de Custos.
- Estrutura de Conciliação Bancária.
- Demonstrações Financeiras.
- Estrutura de Balancete.

### Infraestrutura Técnica

- Definição da arquitetura backend utilizando FastAPI.
- Definição da arquitetura frontend utilizando React.
- Planejamento do aplicativo mobile utilizando Flutter.
- Arquitetura backend utilizando Python.
- Arquitetura de APIs REST.
- Estratégia de integração com Power BI.

### Documentação Corporativa

Criados os padrões documentais:

- README.md.
- CHANGELOG.md.
- ROADMAP.md.
- CONTRIBUTING.md.
- CODE_OF_CONDUCT.md.
- LICENSE.
- VERSION.
- ARCHITECTURE.md.
- DATABASE_GUIDE.md.
- DATA_DICTIONARY.md.
- API.md.
- DEPLOYMENT.md.
- GOVERNANCE.md.
- STYLE_GUIDE.md.
- SECURITY.md.
- DBA_FRAMEWORK.md.

---

## Categorias

As categorias utilizadas neste changelog são:

| Categoria | Descrição |
| --- | --- |
| Adicionado | Novas funcionalidades ou recursos. |
| Alterado | Alterações em funcionalidades existentes. |
| Depreciado | Recursos que serão removidos futuramente. |
| Removido | Funcionalidades removidas. |
| Corrigido | Correções de erros e ajustes. |
| Segurança | Melhorias relacionadas à segurança. |

---

## Referências

Documentações do projeto:

- README.md.
- ROADMAP.md.
- CONTRIBUTING.md.
- CODE_OF_CONDUCT.md.
- LICENSE.
- VERSION.
- ARCHITECTURE.md.
- DATABASE_GUIDE.md.
- DATABASE_STANDARDS.md.
- DATA_DICTIONARY.md.
- API.md.
- DEPLOYMENT.md.
- GOVERNANCE.md.
- STYLE_GUIDE.md.
- SECURITY.md.
- DBA_FRAMEWORK.md.

---

Referências externas:

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)

---

Copyright © 2026 WMA Travel Ltda. Todos os direitos reservados.
