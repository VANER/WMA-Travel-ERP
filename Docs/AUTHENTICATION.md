# Autenticação Humana

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.2.2 — Autenticação

**Data:** 25/08/2026

**Status:** APROVADA E CERTIFICADA

> **Nota de evolução:** este documento preserva as fronteiras deliberadas da etapa 2.2.2. As decisões então
> adiadas foram tratadas nas etapas 2.2.3 e 2.2.4 e na certificação consolidada da 2.2; o estado operacional atual
> está descrito em `SECURITY_ACCESS_CONTROL.md`.

## 2. Objetivo

Definir e implementar a orquestração mínima que confirma uma identidade humana de `public.usuario`, sem
antecipar decisões sobre hash de credenciais, tokens, sessões, autorização ou evolução estrutural do banco.

## 3. Contrato implementado

O backend consulta o usuário pelo e-mail sem espaços externos e delega a comparação da credencial à porta
`VerificadorCredencial`. Uma autenticação somente é aceita quando, simultaneamente:

- a identidade existe em `public.usuario`;
- `ativo` é exatamente verdadeiro;
- `deleted_at` é nulo;
- existe uma credencial armazenada;
- e-mail e credencial apresentados não são vazios;
- o verificador de credencial aprova a comparação.

O resultado contém somente `id_usuario`, `nome` e `email`. Perfil legado, atribuições RBAC, permissões e dados da
credencial não integram o resultado.

## 4. Comportamento seguro

Todas as recusas produzem `AutenticacaoNegadaError`, sem revelar se o e-mail existe, se a conta está inativa ou
excluída, se não possui credencial ou se a comparação falhou. O verificador também é chamado quando a identidade
não existe; a futura implementação da política de hash deverá garantir trabalho equivalente para o valor nulo.

O repository é somente leitura, não executa `commit` ou `rollback` e não atualiza tentativas ou último acesso. A
auditoria de autenticação permanece reservada à etapa própria prevista na ordem de execução.

A caixa do e-mail é preservada porque a constraint `uk_usuario_email` da baseline é sensível a maiúsculas e
minúsculas. Tornar a identidade de e-mail insensível à caixa exige antes uma regra de normalização e uma migration
que impeça contas ambíguas.

## 5. Limites deliberados

Esta etapa não inclui:

- algoritmo, parâmetros, biblioteca ou atualização de hash;
- access token, refresh token, JWT, cookie, sessão, rotação ou revogação;
- endpoint HTTP de login, pois ainda não existe artefato de sessão aprovado para resposta;
- perfis, roles, permissions, autorização ou proteção de endpoints;
- recuperação, ativação ou bloqueio de contas;
- migration ou alteração da baseline.

No encerramento da 2.2.2, o model `Usuario` apenas refletia a tabela certificada. A política de hash e o adaptador
concreto de `VerificadorCredencial` foram implementados posteriormente na 2.2.3, sem alterar retroativamente o
escopo desta etapa.

## 6. Critérios de conclusão

- [x] autoridade humana refletida sem alterar a baseline;
- [x] consulta por e-mail sem espaços externos implementada;
- [x] estados inativo e excluído negados;
- [x] identificador e credencial vazios negados;
- [x] falha uniforme contra enumeração de contas;
- [x] política de hash isolada por contrato;
- [x] retorno restrito à identidade confirmada;
- [x] tokens, sessões, autorização e migrations não antecipados;
- [x] testes unitários dos fluxos de sucesso e recusa adicionados.

## 7. Evidências locais

A validação foi executada em Windows, Python 3.13 e PostgreSQL 18 descartável em container dedicado. O dump oficial
foi restaurado em `wma_auth_baseline_test` exclusivamente para comparação estrutural.

```text
pip check ................................ OK
ruff format --check app tests migrations . OK (54 arquivos)
ruff check . ............................. OK
mypy app tests ........................... OK (53 arquivos)
pytest -W error --run-postgresql ......... OK (171 testes)
cobertura ................................ OK (100%; mínimo 95%)
alembic check contra baseline ............ OK (nenhuma operação nova)
markdownlint dos documentos alterados .... OK
git diff --check ......................... OK
```

## 8. Evidência CI

O PR #33 foi aprovado na execução `32894861102`, em Ubuntu, Python 3.13 e PostgreSQL 18, com todos os gates do
backend aprovados. A certificação consolidada está em
`Docs/certification/PHASE_2_2_2_AUTHENTICATION_CERTIFICATION.md`.
