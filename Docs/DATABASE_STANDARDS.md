# Padrões de Banco de Dados - WMA Travel ERP

**Versão do Documento:** 1.0.0
**Última Atualização:** 06/08/2026
**Status:** Em Desenvolvimento

---

## 1. Objetivo

Este documento é o conjunto normativo (regras de "deve"/"não deve") usado pelo `DBA_FRAMEWORK.md` para
calcular o Índice de Conformidade do Banco (ICB). Enquanto `DATABASE_GUIDE.md` explica e exemplifica os
padrões, este documento os declara de forma objetiva e verificável, para servir de checklist e de base
para os scripts de auditoria automatizada.

---

## 2. Nomenclatura

| Objeto | Regra | Exemplo válido | Exemplo inválido |
| --- | --- | --- | --- |
| Schema | minúsculas, sem acento, singular | `financeiro` | `Financeiro`, `financeiros` |
| Tabela | português, singular, `snake_case` | `centro_custo` | `CentroCusto`, `centros_custos` |
| Coluna PK | `id_<tabela>` | `id_cliente` | `id`, `cliente_id` |
| Coluna FK | `id_<tabela_referenciada>` | `id_pessoa` | `pessoa_id`, `fk_pessoa` |
| Índice | `idx_<tabela>_<coluna(s)>` | `idx_cliente_documento` | `index1` |
| Constraint PK | `pk_<tabela>` | `pk_cliente` | (nome gerado automaticamente sem padrão) |
| Constraint FK | `fk_<tabela>_<tabela_referenciada>` | `fk_pedido_cliente` | `fk1` |
| Constraint CHECK | `ck_<tabela>_<regra>` | `ck_tipo_pessoa` | `check1` |
| Constraint UNIQUE | `uq_<tabela>_<coluna>` | `uq_cliente_documento` | (sem padrão) |
| View | prefixo `vw_` | `vw_dashboard_financeiro` | `dashboard_financeiro` |
| Function/Procedure | prefixo `fn_` / `sp_` | `fn_atualiza_updated_at` | `atualiza` |
| Trigger | prefixo `trg_` | `trg_pessoa_updated_at` | `trigger1` |
| Sequence | `<tabela>_<coluna>_seq` (padrão do PostgreSQL) | `cliente_id_cliente_seq` | - |

---

## 3. Regras Obrigatórias por Tabela

1. Toda tabela **deve** ter chave primária explícita (`PRIMARY KEY`), não apenas um índice único.
2. Toda tabela transacional/cadastral **deve** ter as colunas de auditoria:

   ```sql
   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
   updated_at TIMESTAMP,
   deleted_at TIMESTAMP,
   created_by VARCHAR(100),
   updated_by VARCHAR(100),
   deleted_by VARCHAR(100),
   versao INTEGER DEFAULT 1
   ```

3. Toda tabela com as colunas acima **deve** ter os triggers correspondentes instanciados
   (`trg_<tabela>_updated_at` associado a `fn_atualiza_updated_at`, e trigger de auditoria associado a
   `fn_log_auditoria`). Ter a função criada sem o `CREATE TRIGGER` correspondente é considerado
   não conformidade (ver `DBA_FRAMEWORK.md`, critério de auditoria estrutural).
4. Toda coluna que referencia outra tabela **deve** ter `FOREIGN KEY` declarada — não apenas
   convenção de nome.
5. Não é permitido armazenar o mesmo dado de negócio em mais de uma tabela de schemas diferentes sem
   uma relação de FK entre elas (ver Seção 5, duplicidade `public` × `financeiro`).
6. Colunas de valor monetário usam `NUMERIC(15,2)`, nunca `FLOAT`/`REAL`.
7. Colunas de data/hora usam `TIMESTAMP` (sem fuso) para dados internos e são documentadas quando
   exigirem fuso horário explícito.

---

## 4. Normalização

- O banco deve estar, no mínimo, em **3ª Forma Normal (3FN)** para tabelas cadastrais e transacionais.
- Dependências transitivas (uma coluna não-chave que depende de outra coluna não-chave, e não
  diretamente da chave primária) devem ser eliminadas, movendo o dado para a tabela de origem e
  referenciando-a por FK.
  - Exemplo real corrigido pelo script `01_normalizar_3fn_enderecos.sql`: `pessoa.cidade`/`estado`
    dependiam de `pessoa.id_localidade`, não diretamente de `pessoa.id_pessoa`.
- Desnormalizações propositais (ex.: colunas de cache para performance de relatório) devem ser
  documentadas explicitamente no `DATA_DICTIONARY.md`, indicando a fonte de verdade.

---

## 5. Autoridade de Dados entre Schemas

Quando dois schemas possuem tabelas com o mesmo nome ou mesmo propósito:

- O schema com mais referências de FK externas e colunas de auditoria completas é a
  **fonte de autoridade**.
- O outro schema deve consolidar seus dados na tabela de autoridade e, durante o período de
  transição, expor uma `VIEW` com o nome original para não quebrar consumidores existentes.
- Situação atual documentada: `public.*` é autoridade cadastral (12+ FKs externas); as 11 tabelas
  duplicadas em `financeiro.*` são consolidadas pelo script `02_consolidar_financeiro_public.sql`.

---

## 6. Schemas do Projeto

| Schema | Propósito | Status |
| --- | --- | --- |
| `public` | Dados cadastrais de autoridade (pessoa, empresa, cliente, fornecedor, destino etc.) | Ativo |
| `financeiro` | Módulo financeiro (plano de contas, lançamentos, conciliação) | Ativo, em consolidação |
| `auditoria` | Governança, health check, compliance, catálogo técnico | Ativo |
| `dw` | Data Warehouse (dimensões e fatos para BI) | Ativo |
| `config` | Parâmetros e configurações gerais do sistema | Ativo |
| `logs` | Reservado para logs de aplicação/infraestrutura | **Vazio - propósito a definir ou depreciar** |
| `seguranca` | Reservado para controle de acesso e políticas de segurança | **Vazio - propósito a definir ou depreciar** |
| `util` | Reservado para funções utilitárias compartilhadas | **Vazio - propósito a definir ou depreciar** |

Schemas marcados como vazios devem ser resolvidos até o fechamento da Fase 1: populados com uma
finalidade clara ou removidos com `DROP SCHEMA`, para não permanecerem como dívida técnica silenciosa.

---

## 7. Checklist de Conformidade Rápida

- [ ] Tabela possui `PRIMARY KEY`.
- [ ] Tabela possui colunas de auditoria completas (quando aplicável).
- [ ] Triggers de auditoria instanciados via `CREATE TRIGGER`.
- [ ] Todas as FKs declaradas explicitamente.
- [ ] Nenhuma dependência transitiva não documentada.
- [ ] Nenhuma duplicidade de dado de negócio entre schemas sem relação de FK/view de compatibilidade.
- [ ] Nomenclatura de objetos segue a Seção 2.

---

## 8. Documentos Relacionados

- `DATABASE_GUIDE.md`
- `DBA_FRAMEWORK.md`
- `DATA_DICTIONARY.md`
- `GOVERNANCE.md`

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
