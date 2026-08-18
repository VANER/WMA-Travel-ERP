# AGENTS.md — WMA Travel ERP

## Escopo e estado atual

Estas instruções valem para todo o repositório.

O projeto está na transição da Fase 1 (banco de dados certificado) para a Fase 2 (backend e API).
Hoje, a árvore versionada contém principalmente `Database/` e `Docs/`. Backend FastAPI, frontend React e
aplicativo Flutter são arquitetura planejada; não presuma que essas camadas, seus comandos ou dependências já
existam. Antes de alterar qualquer área, confirme a estrutura real do repositório.

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

- PostgreSQL é o banco oficial. A baseline certificada está associada ao commit `d63800e` e deve permanecer
  reproduzível e auditável.
- Não altere retroativamente o dump oficial ou migrations já aplicadas para introduzir mudanças estruturais.
  Crie uma migration nova, versionada e rastreável em `Database/migrations/`.
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

## Camadas futuras

Quando uma camada for efetivamente criada, siga as decisões já documentadas sem inventar ferramentas ausentes:

- Backend: Python 3.12+, FastAPI, SQLAlchemy e Alembic; PEP 8, `snake_case`, classes `PascalCase`, type hints em
  funções públicas e separação por domínio.
- Frontend: React, TypeScript e Material UI; componentes `PascalCase`, hooks prefixados com `use` e separação
  entre apresentação e acesso a estado/API.
- Mobile: Flutter; classes `PascalCase`, arquivos `snake_case` e separação entre dados, domínio e apresentação.

Ao adicionar uma camada, inclua no mesmo conjunto de mudanças o manifesto de dependências, configuração mínima,
comandos reais de lint/teste/execução e documentação. Não registre comandos ainda não verificáveis.

## Commits e entrega

Use Conventional Commits no formato `tipo(escopo): descrição`, preferencialmente em português. Tipos aceitos:
`feat`, `fix`, `docs`, `style`, `refactor`, `test` e `chore`. Não faça commit, push ou abra pull request sem pedido
explícito.

Ao concluir, resuma arquivos alterados, impacto funcional, validações executadas e riscos ou pendências. Se não
foi possível validar por ausência de PostgreSQL, Bash, dependências ou credenciais, diga isso claramente.
