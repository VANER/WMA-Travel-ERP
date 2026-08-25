# AGENTS.md — WMA Travel ERP

## Escopo e estado atual

Estas instruções valem para todo o repositório.

O projeto está na Fase 2 — Backend e API. A Fase 1 foi encerrada pela tag imutável
`phase-1-final-2026-08-18`. O backend FastAPI está sendo criado incrementalmente em `Backend/`; as etapas 2.0.1 a
2.0.11 e as etapas 2.1.1 e 2.1.2 estão integradas e certificadas; a etapa 2.1.3 — Repositories do Core
Corporativo está em execução. Frontend React e
aplicativo Flutter continuam planejados e não devem ser antecipados sem escopo explícito.

Nunca mova, recrie ou force a tag `phase-1-final-2026-08-18`. Não reescreva os dumps, scripts F1-FIN,
certificações ou evidências pertencentes ao marco histórico. Correções futuras devem ser aditivas e rastreáveis.

## Fontes de verdade

- `Docs/PHASE_1_TO_PHASE_2_TRANSITION.md`: marco de governança e proteção da baseline.
- `Docs/DATABASE_STANDARDS.md`: regras normativas para objetos PostgreSQL.
- `Docs/DATABASE_GUIDE.md`: orientação e exemplos de banco de dados.
- `Docs/STYLE_GUIDE.md`: padrões de código, commits e Markdown.
- `Docs/SECURITY.md` e `Docs/GOVERNANCE.md`: requisitos de segurança e governança.
- `Database/scripts/WmaTravelERP.sql`: dump completo oficial para reconstrução.
- `Database/baseline/`: referências históricas de reconstrução e comparação.
- `Database/certification/`: evidências de certificação; não são testes genéricos nem arquivos descartáveis.

Em caso de divergência, preserve a baseline certificada e siga primeiro o documento mais específico e mais
recente. Registre inconsistências encontradas em vez de resolvê-las silenciosamente.

## Regras de trabalho

1. Leia os documentos relacionados ao domínio antes de implementar.
2. Faça mudanças pequenas e focadas; não reformate dumps SQL ou documentos inteiros sem necessidade.
3. Preserve alterações locais do usuário. Inspecione `git status --short` antes e depois do trabalho.
4. Não edite artefatos históricos em `Database/baseline/`, `Database/certification/`, `Database/logs/` ou
   `Database_backup_*`, salvo solicitação explícita que justifique a atualização da evidência.
5. Nunca inclua credenciais, senhas, dados pessoais, `.env`, dumps locais ou logs sensíveis no Git.
6. Não execute comandos destrutivos contra banco compartilhado, homologação ou produção. Restauração, `DROP`,
   testes de rollback e certificações mutáveis devem usar um banco local descartável e explicitamente nomeado.
7. Se uma alteração afetar arquitetura, schema, instalação, API ou comportamento observável, atualize a
   documentação correspondente no mesmo trabalho.

## Banco de dados e migrations

- PostgreSQL é o banco oficial. A baseline 10.12.2 está associada ao commit `d63800e`; o fechamento integral da
  Fase 1 está associado à tag `phase-1-final-2026-08-18`. Ambos devem permanecer reproduzíveis e auditáveis.
- Não altere retroativamente o dump oficial, scripts F1-FIN ou migrations já aplicadas para introduzir mudanças
  estruturais. Toda evolução de banco da Fase 2 deve ser uma migration nova, versionada e rastreável em
  `Database/migrations/`.
- Não reaplique migrations históricas sobre um banco restaurado de `Database/scripts/WmaTravelERP.sql`: o dump
  completo já contém o estado exportado.
- Cada migration deve declarar objetivo, objetos e dependências afetados, validações pré e pós-aplicação e,
  quando viável, rollback. Use transação e `ON_ERROR_STOP` quando compatíveis com a operação.
- SQL deve ser seguro para o contexto declarado. Scripts de auditoria destinados a repetição devem ser
  idempotentes e não deixar dados de teste persistidos.
- Objetos usam português, singular, minúsculas e `snake_case`. Siga exatamente os padrões de PK, FK, índices,
  constraints, views, funções, procedures e triggers de `Docs/DATABASE_STANDARDS.md`.
- Declare PKs, FKs e constraints explicitamente. Valores monetários usam `NUMERIC(15,2)`, nunca `FLOAT` ou
  `REAL`. Documente tabelas e colunas com `COMMENT ON`.
- Preserve a autoridade dos schemas e as decisões adiadas registradas na arquitetura. Não mova objetos entre
  `public`, `financeiro`, `auditoria`, `config`, `dw`, `logs`, `seguranca` ou `util` sem análise de dependências.

## Configuração do agente de código

Este `AGENTS.md` é a configuração compartilhada para Codex e demais agentes de código no repositório. O agente
deve começar por `git status --short`, preservar alterações locais e trabalhar somente dentro do escopo solicitado.
Para alterações no backend, a validação mínima verificável é executada em `Backend/`:

```powershell
python -m pip check
python -m ruff check .
python -m mypy app tests
python -m pytest -W error --cov=app --cov-report=term-missing
python -m alembic heads
```

O health check real requer PostgreSQL local descartável e `WMA_DATABASE_URL`; não inventar sucesso quando o banco,
Docker ou o CI Linux não estiverem disponíveis. Não instalar dependências ou criar arquivos de configuração de
agente alternativos sem necessidade comprovada.

## Validação

Execute a menor validação suficiente para a mudança e informe exatamente o que foi ou não executado.

Para reconstrução completa, em um ambiente Bash com PostgreSQL e `psql` disponíveis:

```bash
export PGPASSWORD='<senha-local>'
cd Database
DB_NAME=wma_staging ./install.sh --with-validation
```

Para validar sem restaurar novamente o dump:

```bash
cd Database
DB_NAME=wma_staging ./install.sh --skip-restore --with-validation
```

`Database/install.sh` cria o banco informado caso ele não exista. Portanto, confirme que `DB_NAME` aponta para
um banco descartável antes de executar. Em Windows sem Bash, use WSL/Git Bash ou execute os comandos `psql`
equivalentes; não alegue sucesso se a ferramenta necessária não estiver instalada.

Para documentação, respeite `.markdownlint.jsonc` e `.markdownlintignore`: português do Brasil, uma única H1,
linhas de até 120 caracteres, linguagem nos blocos de código, listas cercadas por linhas em branco e uma única
quebra de linha ao final do arquivo.

## Desenvolvimento da Fase 2

O desenvolvimento novo deve começar pelo Backend/API:

- Backend: Python 3.13+, FastAPI, SQLAlchemy e Alembic; PEP 8, `snake_case`, classes `PascalCase`, type hints em
  funções públicas, separação por domínio e testes automatizados.
- API: contratos versionados, validação de entrada, autenticação/autorização, respostas de erro padronizadas e
  documentação OpenAPI.
- Banco: models e migrations Alembic devem refletir mudanças novas sem modificar a baseline da Fase 1.
- Frontend: React, TypeScript e Material UI; componentes `PascalCase`, hooks prefixados com `use` e separação
  entre apresentação e acesso a estado/API. Não iniciar sem escopo da fase correspondente.
- Mobile: Flutter; classes `PascalCase`, arquivos `snake_case` e separação entre dados, domínio e apresentação.
  Não iniciar sem escopo da fase correspondente.

Ao adicionar uma camada, inclua no mesmo conjunto de mudanças o manifesto de dependências, configuração mínima,
comandos reais de lint/teste/execução e documentação. Não registre comandos ainda não verificáveis.

## Commits e entrega

Use Conventional Commits no formato `tipo(escopo): descrição`, preferencialmente em português. Tipos aceitos:
`feat`, `fix`, `docs`, `style`, `refactor`, `test` e `chore`. Não faça commit, push ou abra pull request sem pedido
explícito.

Ao concluir, resuma arquivos alterados, impacto funcional, validações executadas e riscos ou pendências. Se não
foi possível validar por ausência de PostgreSQL, Bash, dependências ou credenciais, diga isso claramente.
