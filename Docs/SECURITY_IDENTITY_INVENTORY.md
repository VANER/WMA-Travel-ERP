# Inventário e Modelo de Identidade

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.2.1 — Inventário e Modelo de Identidade

**Data do levantamento:** 25/08/2026

**Status:** EM VALIDAÇÃO

## 2. Objetivo e limites

Este inventário define as autoridades existentes para identidades humanas e de aplicações antes da implementação
de autenticação. Ele não cria tabelas, models, tokens, hashes ou endpoints e não autoriza o uso de credenciais da
baseline em qualquer ambiente.

Fontes consultadas:

- `Database/scripts/WmaTravelERP.sql`, autoridade estrutural certificada;
- `Docs/SECURITY.md`, política geral de segurança;
- `Docs/architecture/ADR-007-SECURITY.md`, decisão obrigatória de autenticação e autorização;
- `Docs/DATABASE_STANDARDS.md`, padrões para futuras migrations;
- `Docs/CORE_CORPORATE_INVENTORY.md`, fronteira entre Core e Segurança.

## 3. Identidade humana corporativa

| Objeto | Papel atual | Classificação para a etapa 2.2 |
| --- | --- | --- |
| `public.usuario` | Cadastro técnico, email único e hash opcional | Autoridade da identidade humana |
| `public.perfil_acesso` | Catálogo de perfis ativos | Autoridade de agrupamento RBAC |
| `public.usuario_perfil` | Associação temporal usuário–perfil | Autoridade das atribuições de perfil |
| `public.permissao` | Catálogo granular por módulo | Autoridade das permissões |
| `public.politica_acesso` | Catálogo independente de módulo, ação e nível | Política declarativa ainda sem vínculo |

`public.usuario` permanece em `public` nesta etapa. O schema `seguranca` está vazio e nenhuma movimentação de
objetos é autorizada sem análise de dependências e migration aditiva.

## 4. Identidades de aplicações

`public.aplicacao_api`, `public.chave_api` e `public.token_acesso` formam um agregado de credenciais técnicas para
integrações. `public.token_acesso.id_aplicacao` referencia `public.aplicacao_api`, portanto esse token não é uma
sessão de usuário e não pode ser reutilizado como access token ou refresh token humano.

As permissões JSON de `public.chave_api` também não substituem o RBAC de usuários. Identidades de aplicações
devem usar autenticação, rotação, auditoria e escopos próprios.

## 5. Identidade financeira legada

`financeiro.usuario` possui hash obrigatório, indicador de administrador e relações com objetos do próprio schema.
Ele não substitui `public.usuario` e não deve autenticar diretamente os endpoints corporativos. A reconciliação ou
migração de contas financeiras exige etapa própria, preservando as foreign keys existentes.

## 6. Lacunas estruturais comprovadas

- não existe associação entre `public.perfil_acesso` e `public.permissao`;
- `public.usuario.perfil` duplica parcialmente o conceito de `public.usuario_perfil` como texto legado;
- `public.usuario.senha_hash` aceita `NULL`, sem distinguir conta convidada, externa ou ainda não ativada;
- não há sessão de usuário, refresh token, revogação por sessão ou identificador de família de tokens;
- não há recuperação de acesso, expiração de credencial, tentativas ou bloqueio de autenticação;
- não há vínculo direto entre `public.usuario` e `public.pessoa` ou `public.empresa`;
- `public.politica_acesso` não possui associação com usuário, perfil ou permissão;
- não há registro funcional específico para eventos de autenticação e autorização.

Essas lacunas não devem ser corrigidas retroativamente no dump. Cada mudança aprovada exigirá nova migration,
validações pré e pós-aplicação e rollback quando viável.

## 7. Modelo conceitual aprovado

```text
Identidade humana: public.usuario
    ↓ N:N
Atribuição temporal: public.usuario_perfil
    ↓ N:1
Perfil: public.perfil_acesso
    ↓ N:N (lacuna a implementar)
Permissão: public.permissao

Identidade técnica: public.aplicacao_api
    ├── public.chave_api
    └── public.token_acesso
```

O campo legado `public.usuario.perfil` será somente leitura durante a transição e não será fonte de autorização.
O backend deverá negar acesso por padrão quando não houver atribuição RBAC válida.

## 8. Decisões exigidas antes da autenticação

1. selecionar o algoritmo de hash moderno e seus parâmetros;
2. definir access token, refresh token, rotação, revogação e tempos de vida;
3. aprovar a migration de associação perfil–permissão;
4. definir ativação e recuperação de contas sem armazenar tokens em texto claro;
5. decidir o vínculo opcional entre usuário, pessoa e empresa;
6. definir política de compatibilidade e desativação de `financeiro.usuario`;
7. definir eventos auditáveis e retenção sem registrar secrets.

## 9. Critérios de conclusão

- [x] autoridades humanas identificadas;
- [x] identidades de aplicações separadas;
- [x] usuário financeiro legado classificado;
- [x] relações e ausências verificadas na baseline;
- [x] modelo conceitual e negação por padrão registrados;
- [x] mudanças estruturais futuras reservadas a migrations aditivas;
- [x] decisões obrigatórias anteriores à autenticação explicitadas.
