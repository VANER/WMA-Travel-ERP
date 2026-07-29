# Guia de Banco de Dados - WMA Travel ERP

**Versão do Documento:** 1.0.0  
**Última Atualização:** 29/07/2026  
**Banco de Dados:** PostgreSQL  
**Status:** Em Desenvolvimento  

---

## 1. Objetivo

Este documento define os padrões técnicos, arquiteturais e operacionais utilizados no banco de dados corporativo do **WMA Travel ERP**.

O objetivo é garantir uma base de dados:

- Segura;
- Estruturada;
- Escalável;
- Auditável;
- Padronizada;
- Preparada para crescimento empresarial.

Este guia deve ser utilizado como referência para:

- Desenvolvimento;
- Modelagem;
- Manutenção;
- Auditoria;
- Evolução da plataforma.

---

## 2. Visão Geral do Banco de Dados

O banco de dados do **WMA Travel ERP** utiliza arquitetura relacional baseada no PostgreSQL.

A estrutura foi projetada para suportar processos administrativos, financeiros, turísticos e gerenciais da empresa.

Principais módulos:

- Cadastro Corporativo;
- Financeiro;
- Fiscal;
- Comercial;
- Turismo;
- WMA Bike Tour;
- CRM;
- Auditoria;
- Business Intelligence.

---

## 3. Tecnologia Utilizada

| Componente | Tecnologia |

| Banco de Dados | PostgreSQL |
| Linguagem | SQL |
| Modelagem | DBML / dbdiagram.io |
| Versionamento | Git |
| Documentação | Markdown |
| BI | Power BI |
| Backend Futuro | Python / FastAPI |

---

## 4. Princípios da Arquitetura

O banco de dados segue princípios corporativos:

- Integridade dos dados;
- Normalização;
- Baixa redundância;
- Segurança;
- Rastreabilidade;
- Auditoria;
- Alta disponibilidade;
- Facilidade de manutenção.

---

## 5. Arquitetura Geral

```text
WMA Travel ERP

PostgreSQL

├── Core Corporativo
│
├── Cadastros Gerais
│
├── Financeiro
│
├── Fiscal
│
├── Comercial
│
├── Turismo
│
├── CRM
│
├── Auditoria
│
└── Business Intelligence
```

---

## 6. Organização dos Schemas

A estrutura lógica do banco deve utilizar separação por domínio.

Exemplo:

```sql
CREATE SCHEMA core;

CREATE SCHEMA financeiro;

CREATE SCHEMA fiscal;

CREATE SCHEMA turismo;

CREATE SCHEMA auditoria;

CREATE SCHEMA bi;
```

---

## 7. Padrão de Nomenclatura

## 7.1 Tabelas

Padrão:

- Português;
- Singular;
- Letras minúsculas;
- Separação por underscore.

Exemplos:

```text
empresa
cliente
fornecedor
conta_bancaria
lancamento_financeiro
```

---

## 7.2 Campos

Padrão:

```text
id_nome_tabela
```

Exemplos:

```text
id_empresa
id_cliente
id_fornecedor
```

---

## 7.3 Campos de Controle

Toda tabela deve possuir:

```sql
created_at TIMESTAMP;
updated_at TIMESTAMP;
deleted_at TIMESTAMP;
```

---

## 8. Estrutura das Tabelas

Modelo padrão:

```sql
CREATE TABLE cliente
(
    id_cliente BIGSERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    cpf_cnpj VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
```

---

## 9. Chaves Primárias

Todas as tabelas devem possuir chave primária.

Padrão:

```text
id_nome_tabela
```

Exemplo:

```text
id_cliente
```

---

## 10. Chaves Estrangeiras

Relacionamentos devem utilizar Foreign Keys.

Exemplo:

```sql
ALTER TABLE pedido
ADD CONSTRAINT fk_pedido_cliente
FOREIGN KEY(id_cliente)
REFERENCES cliente(id_cliente);
```

---

## 11. Integridade Referencial

O banco deve garantir:

- Relacionamentos válidos;
- Dados consistentes;
- Controle de exclusão;
- Histórico preservado.

---

## 12. Índices

Índices devem ser criados para:

- Chaves estrangeiras;
- Pesquisas frequentes;
- Relatórios;
- Consultas críticas.

Exemplo:

```sql
CREATE INDEX idx_cliente_documento
ON cliente(cpf_cnpj);
```

---

## 13. Constraints

Tipos utilizados:

- PRIMARY KEY;
- FOREIGN KEY;
- UNIQUE;
- NOT NULL;
- CHECK.

Exemplo:

```sql
ALTER TABLE conta_financeira
ADD CONSTRAINT chk_valor
CHECK(valor >= 0);
```

---

## 14. Views

Views serão utilizadas para:

- Relatórios;
- Dashboards;
- Indicadores;
- Consultas gerenciais.

Exemplo:

```sql
CREATE VIEW vw_fluxo_caixa AS

SELECT
data_movimento,
valor
FROM lancamento_financeiro;
```

---

## 15. Functions e Procedures

Utilizadas para:

- Processamentos automáticos;
- Regras de negócio;
- Cálculos;
- Integrações.

Toda função deve possuir:

- Documentação;
- Versionamento;
- Testes.

---

## 16. Triggers

Utilizadas principalmente para:

- Auditoria;
- Histórico;
- Controle automático.

Exemplo:

```sql
CREATE TRIGGER trg_auditoria

AFTER UPDATE ON cliente

FOR EACH ROW

EXECUTE FUNCTION registrar_auditoria();
```

---

## 17. Auditoria do Banco

O banco possui framework de auditoria responsável por registrar:

- Usuário;
- Operação;
- Data;
- Hora;
- Registro alterado.

Operações:

```text
INSERT
UPDATE
DELETE
```

---

## 18. Framework DBA WMA

O Framework DBA possui:

- Auditoria estrutural;
- Validação de tabelas;
- Controle de relacionamentos;
- Verificação de índices;
- Análise de qualidade;
- Relatórios técnicos.

---

## 19. Governança de Dados

A governança garante:

- Padronização;
- Confiabilidade;
- Segurança;
- Controle de alterações.

---

## 20. Segurança

Princípios:

- Menor privilégio;
- Controle de usuários;
- Proteção de credenciais;
- Auditoria de acessos.

---

## 21. Versionamento SQL

Estrutura:

```text
Database

├── migrations
├── scripts
├── functions
├── views
├── procedures
└── backups
```

---

## 22. Migrações

Toda alteração deve possuir:

- Script de alteração;
- Data;
- Responsável;
- Descrição;
- Rollback.

---

## 23. Backup e Restore

Política recomendada:

- Backup diário;
- Backup incremental;
- Teste de restauração;
- Controle de retenção.

---

## 24. Performance

Boas práticas:

- Índices adequados;
- Queries otimizadas;
- Análise de execução;
- Monitoramento.

Ferramenta:

```sql
EXPLAIN ANALYZE;
```

---

## 25. Processo de Alteração

Fluxo:

1. Documentar alteração;
2. Criar modelo;
3. Desenvolver script;
4. Executar testes;
5. Validar impacto;
6. Aplicar alteração;
7. Atualizar documentação.

---

## 26. Checklist DBA

- [ ] Modelo revisado
- [ ] Script criado
- [ ] Backup realizado
- [ ] Testes executados
- [ ] Constraints validadas
- [ ] Índices revisados
- [ ] Documentação atualizada

---

## 27. Certificação da Base

Critérios:

- Integridade;
- Segurança;
- Performance;
- Padronização;
- Auditoria;
- Documentação.

Status:

```text
Banco estruturado e preparado para evolução contínua.
```

---

## 28. Glossário Técnico

| Termo | Significado |

| DBA | Administrador de Banco de Dados |
| ERP | Sistema Integrado de Gestão |
| PK | Chave Primária |
| FK | Chave Estrangeira |
| SQL | Linguagem de Banco de Dados |
| BI | Business Intelligence |

---

## 29. Documentos Relacionados

- README.md
- ARCHITECTURE.md
- DATA_DICTIONARY.md
- API.md
- DEPLOYMENT.md
- GOVERNANCE.md
- SECURITY.md

---

**Copyright © 2026 WMA Travel Ltda.**  
**Todos os direitos reservados.**
