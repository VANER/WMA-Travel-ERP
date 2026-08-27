# Certificação da Etapa 2.2 — Segurança e Controle de Acesso

## Resultado

**Status:** APROVADA

**Data:** 25/08/2026

As etapas 2.2.1 a 2.2.12 foram integradas. O modelo usa as autoridades da baseline, aplica RBAC com negação por
padrão, protege o Core Corporativo, implementa sessões HTTP, recuperação segura e auditoria operacional.

## Evidências

- Ruff: aprovado;
- mypy em `app` e `tests`: aprovado;
- pytest: 209 testes aprovados e 3 testes PostgreSQL omitidos no ciclo sem opt-in;
- cobertura: 97,37%, acima do gate de 95%;
- testes PostgreSQL com opt-in: 3 aprovados;
- Alembic: uma head, `202608252330`;
- restore do dump oficial: aprovado em PostgreSQL 17 descartável;
- upgrade completo, downgrade da última revision e reupgrade: aprovados;
- `alembic check`: `No new upgrade operations detected.`;
- `pip check`: aprovado, sem dependências quebradas.

## Controles Verificados

- tokens de sessão e recuperação são persistidos somente por hash;
- reutilização e revogação invalidam capacidades de sessão;
- vigência, atividade e exclusão lógica participam da resolução RBAC;
- endpoints distinguem autenticação (`401`) de autorização (`403`);
- detalhes de auditoria rejeitam campos sensíveis;
- ausência de perfil ou permissão não concede acesso;
- migrations não alteram a baseline histórica.

## Limite Operacional

O serviço de recuperação depende de um adaptador para `NotificadorRecuperacao`. A escolha da infraestrutura de
email permanece uma decisão de integração, sem enfraquecer o armazenamento ou expor token bruto em resposta HTTP.

## Gate

Com as validações finais e o CI remoto aprovados, a etapa 2.2 pode ser integrada à `main`.
