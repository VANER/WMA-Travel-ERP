# Testes do Core Corporativo

**Etapa:** 2.1.7 — Testes do Core Corporativo

## 1. Objetivo

Consolidar a validação automatizada das regras, persistência e API implementadas nas etapas 2.1.1 a 2.1.6, com
cobertura local determinística e um fluxo ponta a ponta em PostgreSQL real descartável.

## 2. Camadas cobertas

- fidelidade dos nove models à baseline certificada;
- paginação, consulta e persistência dos repositories;
- limites transacionais de commit e rollback dos services;
- validação, defaults e conversão ORM dos schemas;
- 27 operações HTTP, erros padronizados e contrato OpenAPI;
- fluxo integrado entre API, services, repositories, SQLAlchemy e PostgreSQL.

## 3. Teste PostgreSQL

O teste opt-in em `Backend/tests/integration/test_postgresql.py` aceita apenas host local e banco terminado em
`_test`. Ele monta as nove tabelas corporativas, cadastra a cadeia de dependências, verifica leitura, paginação,
defaults do servidor e conflito de unicidade, e remove as tabelas no bloco de finalização.

```powershell
$env:WMA_TEST_DATABASE_URL = "postgresql+psycopg://usuario@localhost:5432/wma_core_test"
pytest -W error --run-postgresql --cov=app --cov-report=term-missing
```

O comando é destrutivo apenas para as tabelas do recorte no banco descartável informado. A fixture rejeita banco
remoto ou sem o sufixo `_test`.

## 4. Critério de aprovação

- todos os testes rápidos aprovados;
- integração PostgreSQL aprovada no CI Linux;
- cobertura total igual ou superior a 95%;
- Ruff, Mypy, dependências e Alembic sem erros;
- nenhuma alteração retroativa na baseline ou migration histórica.
