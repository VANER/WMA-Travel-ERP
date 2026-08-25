# Models do Core Corporativo

## 1. Escopo

**Etapa:** 2.1.2 — Models do Core Corporativo

**Status:** EM EXECUÇÃO

Os models refletem as nove autoridades aprovadas em `Docs/CORE_CORPORATE_INVENTORY.md`. Esta etapa não cria
tabelas, migration, repository, service, schema HTTP ou endpoint.

## 2. Organização

| Caminho | Responsabilidade |
| --- | --- |
| `app/modules/corporativo/models.py` | Models e relações internas do domínio corporativo |
| `app/db/models.py` | Registro central dos models gerenciados pelo Alembic |
| `migrations/env.py` | Carregamento do registro antes do autogenerate |

`app/core` permanece reservado à infraestrutura técnica transversal. O módulo `corporativo` participa do gate
que impede imports diretos entre implementações de domínios.

## 3. Models mapeados

| Model | Tabela da baseline | Relação ORM explícita |
| --- | --- | --- |
| `Localidade` | `public.localidade` | Nenhuma coleção implícita |
| `Pessoa` | `public.pessoa` | `localidade` |
| `Empresa` | `public.empresa` | `localidade` |
| `Cliente` | `public.cliente` | `pessoa` |
| `Fornecedor` | `public.fornecedor` | `pessoa` |
| `TipoDocumento` | `public.tipo_documento` | Nenhuma coleção implícita |
| `Documento` | `public.documento` | `tipo_documento` |
| `ConfiguracaoEmpresa` | `public.configuracao_empresa` | `empresa` |
| `ParametroSistema` | `public.parametro_sistema` | Nenhuma |

As relações usam `lazy="raise"` para impedir consultas implícitas. Collections reversas serão adicionadas somente
quando repositories ou casos de uso demonstrarem necessidade.

## 4. Fidelidade à baseline

- `public` é o schema padrão da conexão e não é qualificado no metadata, evitando diferenças falsas no Alembic;
- `Localidade.id_localidade` preserva `GENERATED ALWAYS AS IDENTITY`;
- os demais identificadores preservam o comportamento serial/sequence reconhecido pelo PostgreSQL;
- tipos, tamanhos, nulabilidade, defaults e precisão monetária refletem o dump oficial;
- constraints históricas `uk_` e foreign keys com nomes específicos permanecem inalteradas;
- `ck_tipo_pessoa` usa o nome histórico sem passar pela convenção de nomes atual;
- o comentário existente de `public.empresa` é preservado;
- `Documento.entidade_tipo` e `Documento.entidade_id` continuam sem foreign key ou relação ORM inventada;
- objetos ainda não mapeados permanecem protegidos contra remoção pelo filtro de autogenerate.

## 5. Validação sobre baseline restaurada

A comparação deve usar um PostgreSQL local descartável restaurado diretamente de
`Database/scripts/WmaTravelERP.sql`. Após configurar `WMA_DATABASE_URL`, execute:

```powershell
python -m alembic check
```

O resultado esperado é `No new upgrade operations detected.`. Não execute essa comparação contra produção ou
um banco compartilhado.

## 6. Limites para as próximas etapas

- repositories serão tratados somente na etapa 2.1.3;
- regras de negócio pertencem à etapa 2.1.4;
- schemas de entrada e saída pertencem à etapa 2.1.5;
- credenciais, perfis, tokens e autorização permanecem reservados à etapa 2.2;
- qualquer diferença estrutural necessária deverá ser proposta por migration nova e autorizada, nunca por edição
  do dump certificado.
