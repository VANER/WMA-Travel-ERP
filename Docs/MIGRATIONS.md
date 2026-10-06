# Migrations da Fase 2

## Objetivo

Definir o processo auditável para evoluções PostgreSQL posteriores à baseline certificada da Fase 1, usando
Alembic sem recriar, reordenar ou ocultar o histórico existente.

## Baseline protegida

O dump `Database/scripts/WmaTravelERP.sql` já contém a baseline integral da Fase 1. Por isso:

- não existe revision Alembic inicial reproduzindo o dump;
- um ambiente novo deve restaurar o dump antes de executar migrations da Fase 2;
- um banco restaurado da baseline começa na base da árvore Alembic;
- `alembic stamp head` não pode ser usado para ignorar revisions pendentes;
- scripts históricos e evidências da Fase 1 não podem ser modificados.

## Nomenclatura e encadeamento

Os arquivos usam `YYYYMMDDHHMM_descricao_curta.py`; os revision IDs usam somente `YYYYMMDDHHMM`, em UTC.
A descrição usa letras minúsculas e `snake_case`, conforme as revisions versionadas no Backend.
Cada revision deve apontar para o head anterior em `down_revision`. A árvore deve permanecer linear; múltiplos
heads exigem decisão arquitetural e plano de merge explícitos.

Exemplo:

```powershell
cd Backend
python -m alembic revision `
  --rev-id 202610061530 `
  -m "adiciona tabela exemplo"
```

Autogenerate pode auxiliar a revisão, mas nunca substitui a inspeção do SQL, das constraints, dos schemas e do
rollback. Uma revision vazia ou criada apenas para marcar etapa não deve ser versionada.

O filtro `include_managed_object` impede que tabelas refletidas da baseline, mas ainda não representadas em
`Base.metadata`, sejam interpretadas como remoções. Essa proteção não autoriza aceitar cegamente o autogenerate:
todo delta produzido continua sujeito a revisão manual.

## Conteúdo obrigatório

Cada revision deve registrar no cabeçalho ou documentação associada:

- objetivo e justificativa;
- schemas e objetos afetados;
- dependências e pré-condições;
- validações antes e depois da aplicação;
- estratégia de rollback ou justificativa técnica para sua impossibilidade;
- impacto de lock, volume de dados e compatibilidade, quando aplicável.

`upgrade()` aplica somente a evolução declarada. `downgrade()` deve reverter a mudança quando isso não causar
perda indevida de dados. Rollbacks destrutivos exigem banco local descartável, backup ou procedimento manual
documentado.

## Fluxo de validação

Confirme primeiro que `WMA_DATABASE_URL` aponta para um banco local descartável restaurado da baseline.

```powershell
cd Backend
python -m alembic heads
python -m alembic history --verbose
python -m alembic current
python -m alembic upgrade head
python -m alembic current
```

Quando houver revision reversível, valide também em banco descartável:

```powershell
python -m alembic downgrade -1
python -m alembic upgrade head
```

O gate exige um único head, upgrade aprovado, downgrade testado quando seguro, schema esperado após a aplicação,
testes automatizados e nenhuma diferença não explicada contra a baseline.

## Primeiro ciclo da Fase 2

Registro histórico da estrutura inicial, anterior às primeiras migrations funcionais:

Enquanto não houver mudança estrutural aprovada, `migrations/versions/` permanece sem revisions e
`python -m alembic heads` não imprime identificadores. A primeira revision futura terá `down_revision = None` e
deverá conter somente o primeiro delta da Fase 2.

## Estado versionado em 05/10/2026

O diretório `Backend/migrations/versions/` contém as evoluções integradas da Fase 2.
O head da entrega 2.7 é `202609170300`, incluindo dez migrations Bike Tour integradas pelo PR #69,
merge `ffcc09e`. A situação de cada banco deve ser consultada separadamente; este registro não executa migrations.
A [certificação física Bike Tour](certification/PHASE_2_7_BIKE_TOUR_PHYSICAL_DATABASE.md) preserva as evidências.
