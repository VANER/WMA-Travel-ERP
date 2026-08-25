# Tokens e Sessões

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.2.4 — Tokens e Sessões

**Data:** 25/08/2026

**Status:** IMPLEMENTADA; CERTIFICAÇÃO PENDENTE

## 2. Objetivo

Definir e implementar o ciclo de vida de sessões humanas após a autenticação, sem antecipar perfis, roles,
permissions, autorização, proteção de endpoints ou recuperação de acesso.

## 3. Política de tokens

O access token é um JWT assinado com HS256 e validade padrão de 15 minutos. A validação fixa o algoritmo no
servidor e exige `iss`, `aud`, `sub`, `sid`, `jti`, `iat`, `nbf`, `exp` e `typ=access`. Emissor, audiência, tempo de
vida e chave de assinatura são configurações validadas; a chave possui no mínimo 32 caracteres e nunca aparece
no `repr` das settings.

O refresh token é opaco, gerado com 32 bytes do gerador criptográfico do sistema e validade padrão de 30 dias.
Somente seu SHA-256 hexadecimal é persistido. Cada renovação invalida o token anterior, cria uma sessão sucessora
na mesma família e emite um novo par.

## 4. Reutilização e revogação

A consulta do refresh token usa bloqueio `FOR UPDATE` para serializar rotações concorrentes. Token expirado,
sessão excluída ou reutilização de token já revogado invalida toda a família. Logout por refresh token também
revoga a família e é idempotente para valores desconhecidos.

`public.sessao_usuario` é a autoridade das sessões humanas. Ela não reutiliza `public.token_acesso`, que permanece
restrita às credenciais técnicas de aplicações. A tabela possui FK para `public.usuario`, vínculo opcional com a
sessão sucessora, constraints explícitas, colunas de auditoria e os triggers certificados da baseline.

## 5. Fronteira transacional

O repository não executa `commit` ou `rollback`. Início, rotação e revogação devem ocorrer dentro da unidade de
trabalho controlada pelo chamador para que invalidação e criação da sucessora sejam atômicas. A migration falha
explicitamente quando a baseline ou suas funções de auditoria não estão presentes.

## 6. Limites deliberados

Esta etapa não inclui:

- endpoint HTTP de login, refresh ou logout;
- cookie e política específica de armazenamento no frontend ou aplicativo;
- perfis, roles, permissions ou claims de autorização;
- middleware de proteção de endpoints;
- recuperação, ativação, bloqueio ou MFA;
- lista de revogação individual para access tokens curtos;
- rotação automática da chave de assinatura ou cofre de segredos.

## 7. Referências

- [PyJWT — API](https://pyjwt.readthedocs.io/en/stable/api.html);
- [Python — módulo secrets](https://docs.python.org/3/library/secrets.html);
- [RFC 7519 — JSON Web Token](https://www.rfc-editor.org/rfc/rfc7519.html);
- [RFC 8725 — JWT Best Current Practices](https://www.rfc-editor.org/rfc/rfc8725.html).

## 8. Evidências locais

As seguintes validações foram executadas em 25 de agosto de 2026:

- `python -m pip check`: aprovado;
- `python -m ruff format --check app tests migrations`: aprovado em 59 arquivos;
- `python -m ruff check .`: aprovado;
- `python -m mypy app tests`: aprovado em 57 arquivos;
- `python -m pytest -W error --run-postgresql --cov=app --cov-report=term-missing`: 194 testes aprovados,
  sem testes ignorados e cobertura de 100%;
- restauração do dump oficial em PostgreSQL 18 descartável: aprovada;
- upgrade, downgrade, reaplicação e `alembic check`: aprovados, sem drift;
- 14 comentários de coluna, 2 triggers comentados e auditoria real de inserção e atualização: aprovados;
- `python -m pip_audit --local --progress-spinner off`: nenhuma vulnerabilidade conhecida;
- Markdownlint nos documentos alterados: aprovado;
- `git diff --check`: aprovado.

A certificação formal permanece pendente até a execução do pipeline completo da pull request.
