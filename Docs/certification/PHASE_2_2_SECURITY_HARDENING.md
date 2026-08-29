# Recertificação de Hardening da Etapa 2.2

## Escopo

Esta recertificação corrige as pendências identificadas após o primeiro fechamento da etapa 2.2, sem alterar
migrations já integradas ou artefatos históricos.

## Correções

- revalidação de atividade e exclusão lógica do usuário em cada requisição autenticada;
- revogação de todas as sessões quando a conta deixa de ser válida;
- auditoria estruturada de decisões permitidas e negadas;
- endpoints HTTP de solicitação e redefinição de credencial;
- dependência explícita de transporte para entrega do token, sem egress implícito;
- proteção append-only de `evento_seguranca` no PostgreSQL;
- teste PostgreSQL ponta a ponta de JWT, sessão, perfil, permissão e endpoint.

## Limite de Transporte

O repositório não escolhe nem ativa SMTP automaticamente. O endpoint de solicitação retorna `503` enquanto a
aplicação não injetar uma implementação autorizada de `NotificadorRecuperacao`. Essa decisão evita envio de token
sensível para destino não aprovado.

### Atualização Posterior

Em 27 de agosto de 2026, o transporte foi explicitamente autorizado e integrado. Em 28 de agosto de 2026, o
provedor efetivo foi confirmado como Titan Email. A restrição acima permanece como registro da decisão vigente
na data desta recertificação e foi superada pela certificação Titan aditiva.

## Gate

Validação local executada em 26 de agosto de 2026:

- `python -m pip check`: sem dependências quebradas;
- `python -m ruff format --check .`: 71 arquivos formatados;
- `python -m ruff check .`: aprovado;
- `python -m mypy app tests`: aprovado;
- `python -m pytest -W error --cov=app --cov-report=term-missing`: 214 aprovados, 4 ignorados e 97% de
  cobertura;
- integração PostgreSQL opt-in: 4 aprovados;
- `python -m alembic check`: sem novas operações de upgrade;
- downgrade e reaplicação da revision `202608262200`: aprovados;
- mutações `UPDATE` e `DELETE` em `evento_seguranca`: bloqueadas com SQLSTATE `55000`, sem persistência do
  dado de teste;
- head Alembic único: `202608262200`.

O CI remoto permanece como gate obrigatório da integração.
