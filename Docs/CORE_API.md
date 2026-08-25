# API do Core Corporativo

**Etapa:** 2.1.6 — API do Core Corporativo

## 1. Objetivo

Expor os casos de uso cadastrais mínimos das nove autoridades do Core Corporativo por contratos HTTP versionados,
sem alterar a baseline do banco e sem antecipar autenticação, atualização ou exclusão.

## 2. Contrato HTTP

Todas as rotas usam o prefixo `/api/v1`, a tag OpenAPI `core-corporativo` e os schemas certificados na etapa
2.1.5. Cada recurso oferece:

- `GET /<recurso>`: coleção paginada por `offset` (mínimo zero) e `limite` (de 1 a 1000);
- `GET /<recurso>/{identifier}`: consulta por identificador inteiro positivo;
- `POST /<recurso>`: cadastro atômico, com resposta `201 Created`.

Os recursos expostos são `localidades`, `pessoas`, `empresas`, `clientes`, `fornecedores`, `tipos-documento`,
`documentos`, `configuracoes-empresa` e `parametros-sistema`.

## 3. Erros e transações

- entradas inválidas retornam `422 VALIDATION_ERROR`;
- recursos inexistentes retornam `404 NOT_FOUND`;
- violações de integridade retornam `409 RESOURCE_CONFLICT`, sem detalhes internos do PostgreSQL;
- erros inesperados preservam o contrato global e o correlation ID;
- os services mantêm a responsabilidade por `commit` e `rollback`.

## 4. Limites da etapa

A etapa não inclui alteração, exclusão, filtros de domínio, autenticação, autorização ou migrations. A ampliação
dos cenários de integração e cobertura pertence à etapa 2.1.7.

## 5. Validação verificável

Os contratos são exercitados em `Backend/tests/test_core_api.py`, incluindo as 27 operações, paginação,
identificadores, ausência de recurso, conflito de integridade e exposição no OpenAPI.
