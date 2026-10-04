"""Adiciona permissoes RBAC do modulo Bike Tour.

Revision ID: 202609170100
Revises: 202609130700
"""

from collections.abc import Sequence

from alembic import op

revision: str = "202609170100"
down_revision: str | None = "202609130700"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Registra permissoes Bike Tour e concede-as explicitamente ao ADMIN."""
    op.execute(
        """
        INSERT INTO public.permissao
            (codigo, descricao, modulo, created_by)
        VALUES
            (
                'BIKE_TOUR_VISUALIZAR',
                'Visualizar operacao Bike Tour',
                'BIKE_TOUR',
                'migration'
            ),
            (
                'BIKE_TOUR_OPERAR',
                'Operar inscricoes e execucao Bike Tour',
                'BIKE_TOUR',
                'migration'
            ),
            (
                'BIKE_TOUR_GERENCIAR',
                'Gerenciar estrutura e operacao Bike Tour',
                'BIKE_TOUR',
                'migration'
            )
        ON CONFLICT (codigo) DO NOTHING;

        INSERT INTO public.perfil_permissao
            (id_perfil, id_permissao, created_by)
        SELECT
            perfil.id_perfil,
            permissao.id_permissao,
            'migration'
        FROM public.perfil_acesso AS perfil
        CROSS JOIN public.permissao AS permissao
        WHERE perfil.codigo = 'ADMIN'
          AND permissao.codigo IN (
              'BIKE_TOUR_VISUALIZAR',
              'BIKE_TOUR_OPERAR',
              'BIKE_TOUR_GERENCIAR'
          )
        ON CONFLICT (id_perfil, id_permissao) DO NOTHING;
        """
    )


def downgrade() -> None:
    """Remove somente concessoes e permissoes criadas por esta migration."""
    op.execute(
        """
        DELETE FROM public.perfil_permissao
        WHERE id_permissao IN (
            SELECT id_permissao
            FROM public.permissao
            WHERE codigo IN (
                'BIKE_TOUR_VISUALIZAR',
                'BIKE_TOUR_OPERAR',
                'BIKE_TOUR_GERENCIAR'
            )
        )
          AND created_by = 'migration';

        DELETE FROM public.permissao
        WHERE codigo IN (
            'BIKE_TOUR_VISUALIZAR',
            'BIKE_TOUR_OPERAR',
            'BIKE_TOUR_GERENCIAR'
        )
          AND created_by = 'migration';
        """
    )
