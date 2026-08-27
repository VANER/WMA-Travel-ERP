# Hardening Transacional da Recuperação 2.2

## Resultado

**Status:** APROVADA

**Data:** 26/08/2026

## Correção

O fluxo de solicitação separa a preparação do token da entrega externa. O hash, a validade e o evento de
solicitação são confirmados antes de o `NotificadorRecuperacao` receber o token efêmero. Assim, uma falha de
`commit` não permite que um token inexistente seja entregue ao usuário.

Falhas do transportador retornam `503` e registram `RECUPERACAO_ENTREGUE/ERRO` em uma nova transação. O token
bruto permanece restrito à memória do processo e não participa do evento de auditoria.

## Gate

Validação local executada em 26 de agosto de 2026:

- `python -m pip check`: sem dependências quebradas;
- `python -m ruff format --check .`: 71 arquivos formatados;
- `python -m ruff check .`: aprovado;
- `python -m mypy app tests`: aprovado;
- `python -m pytest -W error --cov=app --cov-report=term-missing`: 215 aprovados, 4 ignorados e 97% de
  cobertura;
- integração PostgreSQL opt-in: 4 aprovados;
- head Alembic único: `202608262200`;
- markdownlint dos documentos alterados: aprovado.

O CI remoto permanece como gate obrigatório da integração.
