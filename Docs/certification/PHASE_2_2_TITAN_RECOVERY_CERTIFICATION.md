# Certificação Titan Email da Recuperação 2.2

## Resultado

**Status:** APROVADA LOCALMENTE

**Data:** 28/08/2026

## Escopo Autorizado

O transporte usa Titan Email com a conta `vaner@wmatravel.com.br`, servidor `smtp.titan.email`, porta 465 e SSL.
O token pode ser enviado somente ao email da conta que originou a solicitação. A URL reservada para o frontend é
`https://wmatravel.com.br/redefinir-senha`; sua interface permanece fora do escopo da Fase 2.

## Controles

- senha recebida exclusivamente por `WMA_SMTP_PASSWORD` e ausente do Git;
- TLS com autoridades confiáveis do sistema e timeout de 15 segundos;
- autenticação SMTP com o endereço completo da conta;
- senha vazia rejeitada e URL limitada a HTTPS;
- token ausente de logs, banco e auditoria;
- transportador desativado com `503` quando o segredo não foi injetado;
- testes com mock integral de TLS e SMTP, sem envio real.

## Gate

Validação local executada em 28 de agosto de 2026:

- `python -m pip check`: sem dependências quebradas;
- `python -m ruff check .`: aprovado;
- `python -m ruff format --check .`: 73 arquivos formatados;
- `python -m mypy app tests`: aprovado;
- `python -m pytest -W error --cov=app --cov-report=term-missing`: 235 aprovados, 4 ignorados e 100% de
  cobertura;
- gate permanente `--cov-fail-under=100` configurado no `pyproject.toml`;
- head Alembic único: `202608262200`;
- markdownlint dos documentos alterados: aprovado.

O CI remoto permanece como gate da integração. O teste de envio real exige a senha operacional da conta e não
integra a certificação automatizada.
