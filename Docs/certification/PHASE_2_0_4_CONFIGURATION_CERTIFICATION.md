# WMA Travel ERP — Certificação da ETAPA 2.0.4

## Configuração, Ambientes e Secrets

**Projeto:** WMA Travel ERP

**Fase:** 2 — Backend, API e Integrações

**Etapa:** 2.0.4 — Configuração

**Data:** 20/08/2026

**Status:** APROVADA E CERTIFICADA

## 1. Objetivo

Certificar a configuração central por ambiente, a validação das variáveis obrigatórias, a proteção de valores
sensíveis e o logging técnico estruturado, sem credenciais no código ou no repositório.

## 2. Escopo auditado

- `Backend/app/core/config.py`: settings tipadas, prefixo `WMA_` e regras de produção;
- `Backend/app/core/logging.py`: JSON, níveis, contexto e whitelist de campos;
- `Backend/app/core/middleware.py`: correlation ID, status e duração HTTP;
- `Backend/.env.example`: variáveis documentadas sem credenciais reais;
- testes de configuração, logging, erros e health check;
- `.gitignore` para `.env`, caches e artefatos locais.

## 3. Pendências residuais tratadas

- validação estrutural da URL PostgreSQL, incluindo driver, host e banco;
- teste explícito do carregamento de `WMA_ENVIRONMENT` e `WMA_LOG_LEVEL`;
- teste explícito de que `database_url` e senha não entram no JSON de logging;
- certificação formal da etapa, ausente apesar de o gate já estar marcado como aprovado.

## 4. Evidências de validação

O gate original da etapa foi executado no commit `5677b7e`, com 19 testes e 100% de cobertura. O workflow Linux
do PR #5 e o workflow pós-merge em `main` foram aprovados para o merge commit `c961061`.

Após o fechamento das pendências residuais, a suíte da etapa foi executada novamente em Windows, com Python
3.13.15:

```text
pip check ................................ OK
ruff check . ............................. OK
mypy app tests ........................... OK
pytest -W error --cov=app ................. OK (23 testes; 100%)
alembic heads ............................ OK
git diff --check ......................... OK
```

## 5. Segurança e governança

- `WMA_DATABASE_URL` é obrigatória e não possui fallback embutido no código;
- `.env` é ignorado e somente `.env.example` é versionado;
- `hide_input_in_errors=True` impede exposição dos valores de entrada em erros Pydantic;
- `database_url` não aparece no `repr` de `Settings`;
- o formatter JSON usa whitelist de contexto e não serializa secrets arbitrários;
- `DEBUG` é proibido em produção;
- o access log padrão do Uvicorn é desativado para evitar exposição acidental de parâmetros;
- nenhuma baseline, migration histórica, credencial ou evidência da Fase 1 foi alterada.

## 6. Gate

```text
Settings tipadas por ambiente ............ OK
Variáveis obrigatórias ................... OK
Valores WMA_* carregados ................. OK
URL PostgreSQL validada .................. OK
Proteção de secrets ...................... OK
Logging JSON estruturado ................. OK
Correlation ID e contexto HTTP ........... OK
DEBUG bloqueado em produção .............. OK
.env ignorado e .env.example seguro ...... OK
Testes automatizados ..................... OK (100%)
Lint e tipagem ........................... OK
Validação Windows ........................ OK
Validação Linux/CI da etapa 2.0.4 ........ OK
```

## 7. Rastreabilidade

- implementação: commit `5677b7e`;
- pull request original: PR #5;
- merge em `main`: commit `c961061`;
- CI do PR: execução `32319649017`, aprovada;
- CI pós-merge: execução `32319789140`, aprovada.

## 8. Resultado

**ETAPA 2.0.4 — CONFIGURAÇÃO: APROVADA E CERTIFICADA**

As pendências técnicas e documentais conhecidas da etapa foram encerradas. O projeto está autorizado a manter a
execução da etapa 2.0.5 — PostgreSQL e SQLAlchemy.
