# Matriz de Respostas da API

**Etapa:** 2.3.4 --- Matriz de Respostas

**Versão contratual:** `/api/v1`

**Status:** APROVADA

## 1. Objetivo

Definir os status HTTP documentados por classe de endpoint e impedir divergência entre implementação, OpenAPI e
testes.

## 2. Baseline compatível da v1

A configuração inicial publicou `404`, `405`, `409`, `422` e `500` em todas as operações. Essa baseline permanece
no `/api/v1` por compatibilidade, mesmo quando determinado status não integra o fluxo principal de uma operação.
Uma futura versão poderá reduzir essa matriz global.

Todas as respostas de erro publicadas usam `ErrorResponse` e incluem `correlation_id`.

## 3. Matriz obrigatória

| Classe | Sucesso | Respostas específicas | Baseline v1 |
| --- | --- | --- | --- |
| saúde do processo | `200` | nenhuma | `404`, `405`, `409`, `422`, `500` |
| saúde do banco | `200` | `503` | `404`, `405`, `409`, `422`, `500` |
| login e refresh | `200` | `401` | `404`, `405`, `409`, `422`, `500` |
| logout | `204` | nenhuma | `404`, `405`, `409`, `422`, `500` |
| solicitação de recuperação | `202` | `503` | `404`, `405`, `409`, `422`, `500` |
| redefinição de credencial | `204` | `400` | `404`, `405`, `409`, `422`, `500` |
| lista protegida | `200` | `401`, `403` | `404`, `405`, `409`, `422`, `500` |
| detalhe protegido | `200` | `401`, `403`, `404` | `405`, `409`, `422`, `500` |
| criação protegida | `201` | `401`, `403`, `409` | `404`, `405`, `422`, `500` |

## 4. Regras

- sucesso deve usar schema explícito, exceto respostas `204` sem corpo;
- erros devem referenciar `ErrorResponse` no OpenAPI;
- autenticação ausente ou inválida usa `401`;
- identidade autenticada sem permissão usa `403`;
- entrada semanticamente inválida da redefinição usa `400`;
- indisponibilidade de banco ou entrega de recuperação usa `503`;
- violação de integridade usa `409`;
- validação de entrada usa `422`;
- falha inesperada usa `500` sem detalhe interno.

## 5. Evolução

Adicionar resposta de erro é mudança aditiva. Remover status, alterar schema ou substituir uma resposta de sucesso
segue a classificação de compatibilidade da ADR-016.
