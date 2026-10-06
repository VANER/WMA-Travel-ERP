# Revisions Alembic

As revisions da Fase 2 estão versionadas neste diretório; o head da entrega 2.7 é `202609170300`.
As dez migrations Bike Tour foram integradas pelo PR #69, merge `ffcc09e`. Novas mudanças estruturais
exigem revisions aditivas aprovadas. A baseline da Fase 1 não deve ser recriada como revision Alembic.

Cada arquivo usa o padrão `YYYYMMDDHHMM_descricao_curta.py`, revision ID `YYYYMMDDHHMM` e encadeamento linear por
`down_revision`. Múltiplos heads não são permitidos sem decisão arquitetural explícita.
