# Certificação HostGator da Recuperação 2.2

## Resultado

**Status:** SUBSTITUÍDA PELA CERTIFICAÇÃO TITAN

**Data:** 27/08/2026

**Substituição:** 28/08/2026

Esta evidência preserva a configuração inicialmente assumida. O provedor efetivo foi posteriormente confirmado
como Titan Email; a configuração vigente está em `PHASE_2_2_TITAN_RECOVERY_CERTIFICATION.md`.

## Escopo Autorizado

O transporte usa a conta HostGator `vaner@wmatravel.com.br`, servidor `mail.wmatravel.com.br`, porta 465 e SSL.
O token de recuperação pode ser enviado somente ao email da conta que originou a solicitação. A URL inicial é
`https://wmatravel.com.br/redefinir-senha`.

## Controles

- senha SMTP recebida exclusivamente por `WMA_SMTP_PASSWORD` e ocultada na representação da configuração;
- contexto TLS criado com as autoridades confiáveis do sistema;
- timeout de rede limitado a 15 segundos;
- token restrito ao corpo da mensagem e ausente de logs, banco e auditoria;
- transportador desativado com resposta `503` quando a senha não foi injetada;
- host, porta, remetente e URL configuráveis sem alteração de código;
- senha vazia rejeitada e URL limitada a HTTPS;
- testes sem conexão externa e sem credenciais reais.

## Gate

Validação local executada em 27 de agosto de 2026:

- `python -m pip check`: sem dependências quebradas;
- `python -m ruff format --check .`: aprovado;
- `python -m ruff check .`: aprovado;
- `python -m mypy app tests`: aprovado;
- `python -m pytest -W error --cov=app --cov-report=term-missing`: 225 aprovados, 4 ignorados e 97% de
  cobertura;
- head Alembic único: `202608262200`;
- testes do adaptador usam mock integral de TLS e SMTP, sem egress;
- markdownlint dos documentos alterados: aprovado.

O Docker Desktop local ficou indisponível na repetição opt-in. A mudança não altera persistência; as quatro
integrações PostgreSQL permanecem como gate obrigatório do CI Linux. O envio real depende da injeção operacional
da senha da conta HostGator e não é executado pela certificação automatizada.
