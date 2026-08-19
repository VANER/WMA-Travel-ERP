# Changelog

<!-- WMA_PHASE_1_CHANGELOG_CLOSE -->

## [Não Publicado]

### Adicionado

- bootstrap da etapa 2.0.2 em `Backend/` com FastAPI, SQLAlchemy 2, Alembic e psycopg 3;
- configuração por ambiente, correlation ID e contrato inicial de health check;
- testes HTTP e configuração de lint, tipagem e cobertura para Python 3.13+.

### Corrigido

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
