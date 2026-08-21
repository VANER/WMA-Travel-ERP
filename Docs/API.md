# API do WMA Travel ERP

> Documentação oficial da API REST do WMA Travel ERP.

---

## Índice

- [1. Visão Geral](#1-visão-geral)
- [2. Objetivos](#2-objetivos)
- [3. Arquitetura da API](#3-arquitetura-da-api)
- [4. Padrões Adotados](#4-padrões-adotados)
- [5. Tecnologias](#5-tecnologias)
- [6. Versionamento](#6-versionamento)
- [7. Estrutura das URLs](#7-estrutura-das-urls)
- [8. Métodos HTTP](#8-métodos-http)
- [9. Formato das Requisições](#9-formato-das-requisições)
- [10. Formato das Respostas](#10-formato-das-respostas)

---

## 1. Visão Geral

A API do **WMA Travel ERP** disponibiliza serviços REST
para integração entre os módulos internos do sistema e aplicações externas.

A arquitetura foi projetada para suportar:

- ERP Web
- Aplicativo Mobile
- Dashboard Power BI
- Integrações externas
- Sistemas parceiros
- Marketplace
- APIs de Turismo
- Gateways de Pagamento

Toda comunicação utiliza JSON sobre HTTPS.

---

## 2. Objetivos

A API possui os seguintes objetivos:

- Centralizar regras de negócio
- Garantir integração entre módulos
- Permitir integração com terceiros
- Facilitar manutenção
- Oferecer alta escalabilidade
- Garantir segurança
- Disponibilizar documentação padronizada

---

## 3. Arquitetura da API

A arquitetura segue o padrão RESTful.

```text
Cliente

↓

HTTPS

↓

Nginx

↓

FastAPI

↓

Camada de Serviços

↓

Camada de Repositórios

↓

PostgreSQL
```

---

## 4. Padrões Adotados

A API segue os seguintes padrões:

- REST
- JSON
- OpenAPI 3.1
- Swagger UI
- OAuth 2.0
- JWT
- HTTPS
- UTF-8
- ISO 8601 para datas
- RFC 7807 para erros (Problem Details)

---

## 5. Tecnologias

| Tecnologia | Utilização |
| ------------ | -------------- |
| Python 3.12+ | Linguagem |
| FastAPI | Framework REST |
| SQLAlchemy | ORM |
| Alembic | Migrações |
| PostgreSQL | Banco de Dados |
| Pydantic | Validação |
| Uvicorn | Servidor ASGI |
| JWT | Autenticação |

---

## 6. Versionamento

Toda API deverá possuir versionamento.

Formato:

```text
/api/v1/
```

Exemplos:

```text
/api/v1/clientes

/api/v1/empresas

/api/v1/financeiro

/api/v1/turismo
```

Quando houver quebra de compatibilidade será criada nova versão.

Exemplo:

```text
/api/v2/
```

---

## 7. Estrutura das URLs

Formato padrão:

```text
/api/{versao}/{recurso}
```

Exemplos:

```text
/api/v1/clientes

/api/v1/usuarios

/api/v1/empresas

/api/v1/financeiro

/api/v1/pacotes
```

As URLs deverão:

- utilizar letras minúsculas;
- utilizar substantivos;
- utilizar plural;
- não utilizar verbos;
- utilizar snake_case somente quando necessário.

---

## 8. Métodos HTTP

| Método | Finalidad |
| ------ | -------------------- |
| GET | Consulta |
| POST | Inclusão |
| PUT | Atualização completa |
| PATCH | Atualização parcial |
| DELETE | Exclusão lógica |

---

### Exemplos

Consultar clientes

```http
GET /api/v1/clientes
```

Cadastrar cliente

```http
POST /api/v1/clientes
```

Atualizar cliente

```http
PUT /api/v1/clientes/{id}
```

Atualizar parcialmente

```http
PATCH /api/v1/clientes/{id}
```

Excluir

```http
DELETE /api/v1/clientes/{id}
```

---

## 9. Formato das Requisições

Todas as requisições deverão utilizar JSON.

Exemplo:

```json
{
  "nome": "João Silva",
  "email": "joao@email.com",
  "telefone": "(31)99999-9999"
}
```

Cabeçalhos obrigatórios:

```http
Content-Type: application/json

Accept: application/json
```

---

## 10. Formato das Respostas

As respostas deverão seguir estrutura padronizada.

### Sucesso

```json
{
  "success": true,
  "message": "Operação realizada com sucesso.",
  "data": {}
}
```

---

### Erro

```json
{
  "success": false,
  "message": "Erro na operação.",
  "errors": []
}
```

---

### Metadados

Quando necessário:

```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 250,
    "pages": 13
  }
}
```

---

## 11. Autenticação

A autenticação da API é baseada em **JSON Web Token (JWT)**.

Todos os endpoints protegidos exigem um token válido enviado no cabeçalho HTTP.

Exemplo:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR...
```

Os tokens possuem tempo de expiração configurável e são assinados digitalmente.

---

## 12. Autorização

Após a autenticação, o sistema verifica as permissões do usuário com base no seu perfil de acesso.

O modelo de autorização segue o conceito **RBAC (Role-Based Access Control)**.

Cada usuário poderá possuir um ou mais perfis.

Exemplos:

- Administrador
- Financeiro
- Comercial
- Fiscal
- Turismo
- Bike Tour
- Recursos Humanos
- Gestor
- Auditor
- Cliente

---

## 13. Fluxo de Autenticação

O fluxo padrão de autenticação é o seguinte:

```text
Usuário

↓

Login

↓

Validação das Credenciais

↓

Geração do Access Token

↓

Geração do Refresh Token

↓

Resposta da API

↓

Requisições Autenticadas
```

---

## 14. Endpoint de Login

### Requisição

```http
POST /api/v1/auth/login
```

### Corpo da Requisição

```json
{
  "email": "usuario@empresa.com",
  "senha": "********"
}
```

---

### Resposta

```json
{
  "success": true,
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## 15. Refresh Token

O Refresh Token permite gerar um novo Access Token sem que o usuário realize novo login.

### Endpoint

```http
POST /api/v1/auth/refresh
```

### Corpo

```json
{
  "refresh_token": "..."
}
```

---

### Resposta

```json
{
  "access_token": "...",
  "expires_in": 3600
}
```

---

## 16. Logout

O logout invalida o Refresh Token armazenado.

### Endpoint

```http
POST /api/v1/auth/logout
```

---

### Resposta

```json
{
  "success": true,
  "message": "Logout realizado com sucesso."
}
```

---

## 17. Recuperação de Senha

### Solicitação

```http
POST /api/v1/auth/forgot-password
```

### Corpo

```json
{
  "email": "usuario@empresa.com"
}
```

---

### Redefinição

```http
POST /api/v1/auth/reset-password
```

---

## 18. Alteração de Senha

```http
PUT /api/v1/auth/change-password
```

### Corpo

```json
{
  "senha_atual": "******",
  "nova_senha": "******"
}
```

---

## 19. Perfis de Usuário

Os perfis controlam o acesso aos recursos do ERP.

| Perfil | Descrição |
| --------- | ----------- |
| Administrador | Acesso total |
| Gestor | Gestão da empresa |
| Financeiro | Operações financeiras |
| Comercial | CRM e vendas |
| Fiscal | Obrigações fiscais |
| Turismo | Operação turística |
| Bike Tour | Eventos e passeios |
| RH | Recursos Humanos |
| Auditor | Auditorias |
| Cliente | Portal do Cliente |

---

## 20. Permissões

Cada funcionalidade possui permissões específicas.

Exemplos:

- Visualizar
- Inserir
- Alterar
- Excluir
- Aprovar
- Cancelar
- Exportar
- Importar
- Auditoria

---

## 21. Matriz de Permissões

| Recurso | GET | POST | PUT | DELETE |
| ---------- | --- | ---- | --- | ------ |
| Clientes | ✔ | ✔ | ✔ | ✔ |
| Empresas | ✔ | ✔ | ✔ | ✔ |
| Financeiro | ✔ | ✔ | ✔ | ✔ |
| Turismo | ✔ | ✔ | ✔ | ✔ |
| Bike Tour | ✔ | ✔ | ✔ | ✔ |

---

## 22. Expiração dos Tokens

| Token | Tempo |
| -------- | ------ |
| Access Token | 1 hora |
| Refresh Token | 30 dias |

Após a expiração do Access Token, um novo token deverá ser obtido utilizando o Refresh Token.

---

## 23. Cabeçalhos Obrigatórios

Todas as requisições autenticadas deverão conter:

```http
Authorization: Bearer <token>

Content-Type: application/json

Accept: application/json
```

---

## 24. Boas Práticas de Segurança

A API deverá seguir as seguintes recomendações:

- Utilizar HTTPS em todas as requisições.
- Nunca armazenar senhas em texto puro.
- Utilizar hash com algoritmo seguro.
- Limitar tentativas de login.
- Registrar tentativas inválidas.
- Revogar tokens comprometidos.
- Utilizar privilégios mínimos.
- Validar todas as entradas recebidas.

---

## 25. Códigos HTTP Utilizados

| Código | Significado |
| --------- | ------------- |
| 200 | OK |
| 201 | Criado |
| 204 | Sem conteúdo |
| 400 | Requisição inválida |
| 401 | Não autenticado |
| 403 | Acesso negado |
| 404 | Não encontrado |
| 409 | Conflito |
| 422 | Erro de validação |
| 429 | Muitas requisições |
| 500 | Erro interno |

---

## 26. Paginação

Todos os endpoints que retornam coleções deverão suportar paginação.

### Parâmetros

| Parâmetro | Tipo | Obrigatório | Descrição |
| ----------- | ------ | ----------- | ----------- |
| page | Integer | Não | Número da página |
| page_size | Integer | Não | Quantidade de registros |
| sort | String | Não | Campo para ordenação |
| order | String | Não | ASC ou DESC |

### Exemplo

```http
GET /api/v1/clientes?page=1&page_size=20
```

### Resposta

```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_records": 250,
    "total_pages": 13
  }
}
```

---

## 27. Ordenação

A API permite ordenar os resultados utilizando os parâmetros:

```text
sort
order
```

### Exemplo

```http
GET /api/v1/clientes?sort=nome&order=asc
```

Outro exemplo:

```http
GET /api/v1/clientes?sort=data_cadastro&order=desc
```

---

## 28. Pesquisa

Os recursos poderão implementar pesquisa textual.

### Exemplo

```http
GET /api/v1/clientes?search=João
```

Também poderão ser utilizadas pesquisas compostas.

```http
GET /api/v1/clientes?search=João&page=2
```

---

## 29. Filtros

Os endpoints poderão disponibilizar filtros específicos.

Exemplo:

```http
GET /api/v1/clientes?ativo=true
```

Outro exemplo:

```http
GET /api/v1/clientes?cidade=Betim
```

Filtros por período:

```http
GET /api/v1/clientes?data_inicio=2026-01-01&data_fim=2026-12-31
```

---

## 30. Upload de Arquivos

A API suporta envio de arquivos.

Formato:

```http
multipart/form-data
```

Exemplo:

```http
POST /api/v1/arquivos/upload
```

Tipos permitidos:

- PDF
- JPG
- PNG
- DOCX
- XLSX
- CSV

O tamanho máximo deverá ser configurável.

---

## 31. Download de Arquivos

Os documentos poderão ser recuperados através de endpoints específicos.

Exemplo:

```http
GET /api/v1/arquivos/{id}
```

Resposta:

```http
200 OK
Content-Type: application/pdf
```

---

## 32. Tratamento de Erros

Os erros deverão seguir um padrão único.

Exemplo:

```json
{
  "success": false,
  "message": "Registro não encontrado.",
  "code": "CLIENTE_NAO_ENCONTRADO",
  "errors": []
}
```

---

## 33. Validação de Dados

Todas as entradas serão validadas utilizando **Pydantic**.

Principais validações:

- campos obrigatórios;
- tamanho mínimo;
- tamanho máximo;
- formato de e-mail;
- CPF/CNPJ;
- datas;
- valores monetários;
- tipos numéricos.

---

## 34. Rate Limiting

Para proteger a infraestrutura, a API implementará limitação de requisições.

Exemplo de política:

| Endpoint | Limite |
| ----------- | -------- |
| Login | 5 requisições por minuto |
| Consultas | 300 requisições por minuto |
| Demais operações | Configurável |

Quando o limite for excedido:

```http
429 Too Many Requests
```

---

## 35. Idempotência

Operações críticas poderão utilizar uma chave de idempotência.

Cabeçalho:

```http
Idempotency-Key: 7f1b8a40-c86b-4df1-b5d8-a2b7e63f6b44
```

Esse mecanismo evita duplicidade em operações como:

- pagamentos;
- emissão de notas;
- reservas;
- geração de contratos.

---

## 36. Versionamento dos Endpoints

Toda alteração incompatível deverá gerar nova versão.

Exemplo:

```text
/api/v1/

/api/v2/
```

A coexistência de versões permitirá migração gradual dos consumidores da API.

---

## 37. Convenções de Nomenclatura

Os recursos deverão seguir convenções padronizadas.

### URLs

- letras minúsculas;
- substantivos;
- plural;
- sem espaços.

Exemplos:

```text
/clientes

/empresas

/usuarios

/centros-custos
```

### Campos JSON

Utilizar **snake_case**.

Exemplo:

```json
{
  "data_cadastro": "2026-01-01",
  "nome_cliente": "João Silva"
}
```

---

## 38. Cabeçalhos de Resposta

A API poderá retornar cabeçalhos adicionais.

Exemplo:

```http
X-Total-Count: 250

X-Request-Id: 9f6cb2b8

X-Version: 1.0.0
```

---

## 39. Correlação de Requisições

Cada requisição deverá possuir um identificador único para rastreabilidade.

Exemplo:

```http
X-Correlation-Id: 6c64c6a2-bb73-48a5-bec3-aeaf893e1a8e
```

Esse identificador será registrado nos logs do sistema.

---

## 40. Boas Práticas REST

Todos os endpoints deverão seguir as seguintes recomendações:

- utilizar substantivos;
- evitar verbos nas URLs;
- utilizar códigos HTTP corretos;
- responder em JSON;
- utilizar paginação para listas;
- documentar todos os endpoints;
- manter compatibilidade entre versões;
- validar todas as entradas;
- registrar logs de auditoria;
- retornar mensagens claras ao consumidor.

---

## 41. Endpoints da API

Os endpoints da API estão organizados por módulos do ERP.

Todos seguem o padrão:

```text
/api/v1/{modulo}/{recurso}
```

---

## 42. Autenticação

Base URL

```text
/api/v1/auth
```

| Método | Endpoint | Descrição |
| --------- | ---------- | ----------- |
| POST | /login | Realizar login |
| POST | /logout | Encerrar sessão |
| POST | /refresh | Renovar token |
| POST | /forgot-password | Solicitar recuperação de senha |
| POST | /reset-password | Redefinir senha |
| PUT | /change-password | Alterar senha |

---

## 43. Empresas

Base URL

```text
/api/v1/empresas
```

| Método | Endpoint | Descrição |
| --------- | ---------- | ----------- |
| GET | / | Listar empresas |
| GET | /{id} | Consultar empresa |
| POST | / | Cadastrar empresa |
| PUT | /{id} | Atualizar empresa |
| PATCH | /{id} | Atualização parcial |
| DELETE | /{id} | Exclusão lógica |

---

## 44. Usuários

Base URL

```text
/api/v1/usuarios
```

| Método | Endpoint | Descrição |
| --------- | ---------- | ----------- |
| GET | / | Listar usuários |
| GET | /{id} | Consultar usuário |
| POST | / | Criar usuário |
| PUT | /{id} | Atualizar usuário |
| DELETE | /{id} | Desativar usuário |

---

## 45. Perfis

Base URL

```text
/api/v1/perfis
```

Operações disponíveis:

- Cadastro
- Consulta
- Alteração
- Exclusão
- Permissões

---

## 46. Permissões

Base URL

```text
/api/v1/permissoes
```

Funcionalidades:

- Associar permissões
- Revogar permissões
- Consultar permissões
- Auditoria

---

## 47. Clientes

Base URL

```text
/api/v1/clientes
```

Principais operações:

| Método | Descrição |
| --------- | ----------- |
| GET | Listagem |
| GET | Consulta por ID |
| POST | Cadastro |
| PUT | Atualização |
| DELETE | Exclusão lógica |

Filtros:

- Nome
- CPF/CNPJ
- Cidade
- Estado
- Situação
- Data de Cadastro

---

## 48. Fornecedores

Base URL

```text
/api/v1/fornecedores
```

Operações:

- Cadastro
- Consulta
- Atualização
- Exclusão
- Pesquisa

---

## 49. Colaboradores

Base URL

```text
/api/v1/colaboradores
```

Recursos:

- Cadastro
- Consulta
- Histórico
- Documentação
- Afastamentos
- Férias

---

## 50. Financeiro

Base URL

```text
/api/v1/financeiro
```

Submódulos:

```text
Plano de Contas

Fluxo de Caixa

Contas a Pagar

Contas a Receber

Conciliação Bancária

DRE

Balancete

Centros de Custos

Movimentações

Indicadores Financeiros
```

---

## 51. Plano de Contas

Base URL

```text
/api/v1/plano-contas
```

Operações:

- Cadastro
- Consulta
- Alteração
- Exclusão
- Hierarquia

---

## 52. Fluxo de Caixa

Base URL

```text
/api/v1/fluxo-caixa
```

Funcionalidades:

- Entradas
- Saídas
- Saldo Diário
- Saldo Mensal
- Projeções

---

## 53. Contas a Pagar

Base URL

```text
/api/v1/contas-pagar
```

Operações:

- Inclusão
- Baixa
- Cancelamento
- Parcelamento
- Consulta

---

## 54. Contas a Receber

Base URL

```text
/api/v1/contas-receber
```

Operações:

- Inclusão
- Recebimento
- Cancelamento
- Parcelamento
- Consulta

---

## 55. Bancos

Base URL

```text
/api/v1/bancos
```

Recursos:

- Bancos
- Contas
- Agências
- Pix
- Carteiras

---

## 56. Comercial

Base URL

```text
/api/v1/comercial
```

Submódulos:

- CRM
- Leads
- Clientes
- Propostas
- Contratos
- Vendas

---

## 57. CRM

Base URL

```text
/api/v1/crm
```

Recursos:

- Leads
- Oportunidades
- Funil de Vendas
- Agenda
- Atividades

---

## 58. Contratos

Base URL

```text
/api/v1/contratos
```

Operações:

- Emissão
- Assinatura
- Renovação
- Cancelamento

---

## 59. Fiscal

Base URL

```text
/api/v1/fiscal
```

Submódulos:

- NFSe
- NFe
- Tributos
- Obrigações
- Simples Nacional

---

## 60. Turismo

Base URL

```text
/api/v1/turismo
```

Recursos:

- Pacotes
- Reservas
- Hotéis
- Voos
- Passeios
- Guias
- Fornecedores

---

## 61. Bike Tour

Base URL

```text
/api/v1/bike-tour
```

Recursos:

- Eventos
- Trilhas
- Inscrições
- Participantes
- Percursos
- Guias

---

## 62. Dashboard

Base URL

```text
/api/v1/dashboard
```

Indicadores:

- Financeiro
- Comercial
- Turismo
- Fiscal
- Administrativo

---

## 63. Auditoria

Base URL

```text
/api/v1/auditoria
```

Recursos:

- Logs
- Alterações
- Histórico
- Acessos
- Eventos

---

## 64. Health Check

Endpoints:

| Endpoint | Descrição |
| ---------- | ----------- |
| `/health` | Disponibilidade do processo sem acessar o banco |
| `/api/v1/health` | Disponibilidade versionada do processo |
| `/api/v1/health/database` | PostgreSQL; retorna 503 padronizado quando indisponível |

Rotas inexistentes e métodos não permitidos seguem o contrato de erro padrão com os códigos `NOT_FOUND` e
`METHOD_NOT_ALLOWED`, respectivamente. Todas as respostas de erro incluem um correlation ID.

---

## 65. Informações da API

Base URL

```text
/api/v1/info
```

Informações disponibilizadas:

- Versão
- Ambiente
- Build
- Commit
- Data da publicação
- Autor
- Licença

---

## 66. Exemplos de Requisições

### Consultar Cliente

```http
GET /api/v1/clientes/125
Authorization: Bearer <token>
Accept: application/json
```

### Resposta

```json
{
  "success": true,
  "data": {
    "id_cliente": 125,
    "nome": "João da Silva",
    "cpf": "12345678901",
    "email": "joao@email.com",
    "telefone": "(31)99999-9999",
    "ativo": true
  }
}
```

---

### Cadastro de Cliente

```http
POST /api/v1/clientes
```

```json
{
  "nome": "Maria Oliveira",
  "cpf": "98765432100",
  "email": "maria@email.com",
  "telefone": "(31)98888-8888"
}
```

Resposta

```json
{
  "success": true,
  "message": "Cliente cadastrado com sucesso.",
  "id": 248
}
```

---

## 67. Estrutura Padronizada das Respostas

### Sucesso

```json
{
  "success": true,
  "message": "Operação realizada com sucesso.",
  "data": {}
}
```

### Erro

```json
{
  "success": false,
  "message": "Erro ao processar a requisição.",
  "errors": [
    {
      "field": "email",
      "message": "E-mail inválido."
    }
  ]
}
```

---

## 68. Códigos de Erro da Aplicação

| Código | Descrição |
| --------- | ----------- |
| AUTH001 | Credenciais inválidas |
| AUTH002 | Token expirado |
| AUTH003 | Token inválido |
| AUTH004 | Usuário bloqueado |
| FIN001 | Lançamento não encontrado |
| FIN002 | Saldo insuficiente |
| CLI001 | Cliente inexistente |
| EMP001 | Empresa inexistente |
| SYS001 | Erro interno |
| SYS002 | Serviço indisponível |

---

## 69. Webhooks

A API poderá enviar notificações para sistemas externos.

Exemplos:

- pagamento confirmado;
- reserva criada;
- nota fiscal emitida;
- contrato assinado;
- novo cliente cadastrado.

Formato:

```json
{
  "event": "pagamento.confirmado",
  "timestamp": "2026-08-01T10:00:00Z",
  "data": {}
}
```

---

## 70. Integrações Externas

A API suporta integração com:

- Gateway de Pagamento
- PIX
- Open Finance
- Receita Federal
- ViaCEP
- Google Maps
- WhatsApp Business API
- Microsoft Power BI
- SMTP
- Microsoft 365
- Google Workspace

---

## 71. OpenAPI

A documentação seguirá o padrão **OpenAPI 3.1**.

Recursos disponíveis:

- documentação automática;
- exemplos;
- schemas;
- autenticação;
- testes online.

---

## 72. Swagger UI

Ambiente de documentação:

```text
https://api.wmatravel.com.br/docs
```

OpenAPI JSON:

```text
https://api.wmatravel.com.br/openapi.json
```

---

## 73. Coleção Postman

Será disponibilizada uma coleção oficial contendo:

- autenticação;
- exemplos de requisição;
- variáveis de ambiente;
- testes automáticos;
- scripts de pré-processamento.

Arquivo:

```text
WMA_Travel_API.postman_collection.json
```

---

## 74. Observabilidade

A API registra informações para monitoramento e auditoria.

Itens monitorados:

- tempo de resposta;
- consumo de recursos;
- erros;
- autenticações;
- acessos;
- operações críticas;
- integrações externas.

---

## 75. Logs

Todos os eventos relevantes serão registrados.

Exemplos:

- login;
- logout;
- criação;
- alteração;
- exclusão;
- emissão de documentos;
- movimentações financeiras.

Os logs conterão:

- data e hora;
- usuário;
- endereço IP;
- endpoint;
- método HTTP;
- tempo de execução;
- identificador de correlação.

---

## 76. Monitoramento

Ferramentas recomendadas:

- Prometheus
- Grafana
- PostgreSQL Statistics
- OpenTelemetry
- Uvicorn Logs

Indicadores monitorados:

- disponibilidade;
- latência;
- throughput;
- utilização de CPU;
- utilização de memória;
- conexões PostgreSQL;
- erros por minuto.

---

## 77. Compatibilidade

A API foi projetada para integração com:

- Front-end React;
- Aplicativo Flutter;
- Power BI;
- Sistemas parceiros;
- Integrações B2B;
- Aplicações móveis;
- Portais de Clientes;
- Portais Corporativos.

---

## 78. Boas Práticas para Consumidores

Recomenda-se que as aplicações consumidoras:

- reutilizem conexões HTTP;
- implementem timeout;
- utilizem retry com backoff exponencial;
- respeitem o Rate Limiting;
- armazenem tokens de forma segura;
- utilizem HTTPS exclusivamente;
- validem códigos HTTP;
- registrem erros localmente.

---

## 79. Referências

Documentações utilizadas como referência:

- REST API Design Best Practices
- OpenAPI Specification 3.1
- JSON Web Token (JWT)
- OAuth 2.0
- RFC 7231
- RFC 7807
- FastAPI Documentation
- PostgreSQL Documentation

---

## 80. Controle do Documento

| Campo | Valor |
| -------- | -------- |
| Documento | API.md |
| Projeto | WMA Travel ERP |
| Tipo | Documentação Técnica |
| Versão | 1.0.0 |
| Status | Oficial |
| Responsável | WMA Travel Ltda. |
| Compatibilidade | Markdownlint |
| Última atualização | 2026 |

---

## Observações

Este documento deverá ser atualizado sempre que novos endpoints forem adicionados, alterados ou removidos da API.

Toda alteração deverá ser registrada também no arquivo **CHANGELOG.md**.

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
