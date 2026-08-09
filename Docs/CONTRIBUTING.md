# Guia de Contribuição

**Projeto:** WMA Travel ERP

**Versão:** 1.0.0

**Última atualização:** 29/07/2026

---

## Objetivo

Este documento estabelece os padrões oficiais para contribuição no projeto **WMA Travel ERP**.

Seu objetivo é garantir:

  qualidade do código;
  padronização;
  rastreabilidade;
  segurança;
  facilidade de manutenção;
  escalabilidade;
  governança técnica.

Todos os colaboradores devem seguir estas diretrizes.

---

## Princípios

Todo desenvolvimento deve respeitar os seguintes princípios:

  simplicidade;
  legibilidade;
  reutilização;
  responsabilidade única;
  documentação adequada;
  segurança;
  desempenho;
  testes automatizados;
  melhoria contínua.

---

## Estrutura do projeto

```text
WMATRAVEL_ERP/
├── backend/
├── frontend/
├── mobile/
├── database/
├── docs/
├── scripts/
├── tests/
├── ci/
├── tools/
├── README.md
├── CHANGELOG.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
└── VERSION
```

Cada diretório possui responsabilidade específica e não deve conter arquivos de outros domínios.

---

## Fluxo de desenvolvimento

Todo desenvolvimento deverá seguir o fluxo abaixo:

1. Criar uma Issue.
2. Criar uma Branch.
3. Desenvolver a funcionalidade.
4. Executar os testes.
5. Atualizar a documentação quando necessário.
6. Abrir um Pull Request.
7. Passar por Code Review.
8. Realizar o Merge após aprovação.

Alterações diretas na branch principal não são permitidas.

---

## Estratégia de branches

### Main

```text
main
```

Contém apenas versões estáveis.

### Develop

```text
develop
```

Integra todas as funcionalidades aprovadas.

### Feature

```text
feature/nome-da-funcionalidade
```

Exemplos:

```text
feature/financeiro
feature/dashboard
feature/clientes
feature/plano-contas
```

### Fix

```text
fix/nome-da-correcao
```

Exemplos:

```text
fix/index-cliente
fix/fk-pedido
```

### Hotfix

```text
hotfix/correcao-producao
```

Destinada exclusivamente a correções críticas.

### Release

```text
release/1.1.0
```

Utilizada para preparação de novas versões.

---

## Convenção de commits

O projeto utiliza o padrão **Conventional Commits**.

Exemplos:

```text
feat: adiciona módulo financeiro

fix: corrige relacionamento cliente

docs: atualiza documentação

refactor: reorganiza procedures

perf: melhora consulta financeira

test: adiciona testes unitários

style: padroniza formatação

build: atualiza dependências

ci: ajusta pipeline

chore: limpeza do projeto
```

---

## Padrão SQL

### Nomenclatura

Objetos devem utilizar:

  letras minúsculas;
  underscore (`_`);
  nomes descritivos.

Exemplo:

```text
cliente

conta_receber

movimento_financeiro
```

### Chaves primárias

Formato:

```text
id_nome_tabela
```

Exemplos:

```text
id_cliente

id_empresa

id_conta_receber
```

### Chaves estrangeiras

Devem possuir exatamente o mesmo nome da chave primária referenciada.

### Índices

Formato:

```text
idx_tabela_coluna
```

Exemplo:

```text
idx_cliente_nome
```

### Constraints

Formato:

```text
pk_cliente

fk_pedido_cliente

uk_empresa_cnpj

ck_status
```

### Comentários

Toda tabela deverá possuir:

```sql
COMMENT ON TABLE cliente IS 'Descrição da tabela.';
```

Toda coluna deverá possuir:

```sql
COMMENT ON COLUMN cliente.nome IS 'Nome do cliente.';
```

---

## Padrão Python

O código Python deverá seguir integralmente o **PEP 8**.

### Classes

```python
class ClienteService:
    pass
```

### Funções

```python
def listar_clientes():
    pass
```

### Variáveis

```python
valor_total
```

### Constantes

```python
MAX_TENTATIVAS
```

### Tipagem

Toda função pública deverá utilizar *type hints*.

Exemplo:

```python
def buscar_cliente(id_cliente: int):
    ...
```

---

## Padrão Front-end

### Componentes

Utilizar **PascalCase**.

Exemplos:

```text
DashboardPage

ClienteForm

FinanceiroCard
```

### Arquivos utilitários

Utilizar **camelCase**.

---

## Documentação

Toda funcionalidade deverá atualizar a documentação correspondente quando necessário.

Documentos principais:

  README.md;
  CHANGELOG.md;
  ROADMAP.md;
  CONTRIBUTING.md;
  CODE_OF_CONDUCT.md.

---

## Testes

Toda funcionalidade deverá possuir testes compatíveis com seu escopo.

Quando aplicável, executar:

  testes unitários;
  testes de integração;
  testes de banco de dados;
  testes de API;
  testes de interface.

Nenhuma funcionalidade crítica deverá ser integrada sem validação.

---

## Revisão de código

Todo Pull Request deverá verificar:

  compilação sem erros;
  testes executados;
  documentação atualizada;
  ausência de código duplicado;
  ausência de código morto;
  conformidade com os padrões do projeto.

Checklist mínimo:

  [ ] Código revisado
  [ ] Testes executados
  [ ] Documentação atualizada
  [ ] Sem conflitos
  [ ] Padrões atendidos

---

## Banco de dados

Toda alteração estrutural deverá:

  possuir script versionado;
  manter integridade referencial;
  possuir documentação;
  preservar compatibilidade quando aplicável;
  incluir plano de rollback para mudanças críticas.

Alterações manuais em produção são proibidas.

---

## Segurança

É proibido:

  armazenar senhas em texto puro;
  realizar commit de arquivos `.env`;
  publicar credenciais;
  expor chaves privadas;
  utilizar dados sensíveis em testes sem anonimização.

---

## Versionamento

O projeto utiliza **Semantic Versioning (SemVer)**.

Formato:

```text
MAJOR.MINOR.PATCH
```

Exemplo:

```text
1.0.0
```

---

## Qualidade

O projeto adota como referência:

  Clean Code;
  SOLID;
  Clean Architecture;
  Domain-Driven Design (DDD);
  Semantic Versioning;
  Keep a Changelog.

---

## Dúvidas

Antes de iniciar uma nova implementação:

1. Consulte a documentação oficial do projeto.
2. Verifique se existe uma Issue relacionada.
3. Confirme se não há desenvolvimento semelhante em andamento.
4. Siga os padrões definidos neste documento.

---

## Direitos autorais

Copyright © 2026 WMA Travel Ltda.

Todos os direitos reservados.
