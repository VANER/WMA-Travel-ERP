# Fase 2 — Backend e API

## Estado

**Início:** 18/08/2026

**Branch inicial:** `feature/fase-2-backend-api`

**Fundação:** tag imutável `phase-1-final-2026-08-18`

## Objetivo

Construir a camada de aplicação do WMA Travel ERP sobre a fundação PostgreSQL certificada na Fase 1, sem
reescrever o histórico do banco.

## Escopo inicial

- estrutura do backend Python 3.12+;
- aplicação FastAPI;
- configuração por ambiente;
- conexão com PostgreSQL;
- SQLAlchemy e Alembic;
- models e repositórios;
- serviços de domínio;
- contratos e endpoints REST;
- autenticação e autorização;
- tratamento padronizado de erros;
- testes unitários e de integração;
- documentação OpenAPI.

## Governança do banco

Toda alteração persistente posterior à Fase 1 deve:

1. ser criada como migration nova em `Database/migrations/` ou pelo Alembic;
2. possuir identificador e ordem inequívocos;
3. declarar objetivo, dependências e objetos afetados;
4. incluir validações pré e pós-aplicação;
5. incluir rollback ou justificar sua impossibilidade;
6. ser testada sobre uma reconstrução da Fase 1;
7. preservar a tag `phase-1-final-2026-08-18` e todos os seus artefatos.

É proibido editar retroativamente:

- `Database/scripts/WmaTravelERP.sql`;
- `Database/scripts/WMA_Travel_Schema.sql`;
- `Database/scripts/F1_FIN/`;
- `Database/baseline/`;
- documentos e evidências de certificação da Fase 1.

## Gate inicial

- [x] Fase 1 certificada.
- [x] Tag final publicada e conferida.
- [x] Repositório sem arquivos temporários versionados conhecidos.
- [x] Diretório de migrations preparado.
- [x] Branch da Fase 2 criada a partir do marco final.
- [ ] Backend inicial criado.
- [ ] Pipeline de testes do backend configurado.
- [ ] Primeira migration da Fase 2 validada, quando necessária.
