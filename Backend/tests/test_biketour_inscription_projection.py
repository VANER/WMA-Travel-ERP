"""Regressao da resposta exigida pelo snapshot certificado."""

from datetime import UTC, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import EventoBikeTour, InscricaoBikeTour
from app.modules.biketour.operations import OperacoesBikeTour
from app.modules.biketour.uow import ContextoComando
from app.modules.seguranca.rbac import ContextoRbac


@pytest.mark.parametrize("status", [None, 409, 503])
def test_projecao_informa_origem_sem_ocultar_indisponibilidade(status: int | None) -> None:
    session = MagicMock()
    session.scalars.return_value.all.return_value = []
    ctx = ContextoComando(session, ContextoRbac(1, (), frozenset()), uuid4(), datetime.now(UTC))
    op = OperacoesBikeTour(ctx)
    item = InscricaoBikeTour(
        id_inscricao_bike_tour=1, id_evento_bike_tour=2, id_reserva=3, id_passageiro=4
    )
    event = EventoBikeTour(id_evento_bike_tour=2)
    with patch.object(
        op, "origem", side_effect=BikeTourError(status, "ORIGEM") if status else None
    ):
        if status == 503:
            with pytest.raises(BikeTourError) as error:
                op.inscricao_resultado(item, event)
            assert error.value.status_code == 503
        else:
            assert op.inscricao_resultado(item, event)["origem_valida"] == (status is None)
