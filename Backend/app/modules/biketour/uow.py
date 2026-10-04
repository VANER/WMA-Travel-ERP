"""Unidade atomica de comando, serializacao PostgreSQL e replay autorizado."""

import hashlib
import json
import re
from collections.abc import Callable
from copy import deepcopy
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Literal
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, OperationalError, TimeoutError
from sqlalchemy.orm import Session

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import OperacaoBikeTour, PendenciaBikeTour
from app.modules.biketour.repositories import OperacaoRepository
from app.modules.seguranca.rbac import ContextoRbac

type ResultadoJSON = dict[str, object] | list[dict[str, object]]
type PermissaoComando = Literal[
    "BIKE_TOUR_OPERAR",
    "BIKE_TOUR_GERENCIAR",
    "BIKETOUR_OPERAR",
    "BIKETOUR_GERENCIAR",
]


def _tem_permissao(permissoes: frozenset[str], codigo: str) -> bool:
    """Aceita os aliases históricos sem criar herança implícita de permissões."""
    aliases = {
        "BIKE_TOUR_VISUALIZAR": {"BIKE_TOUR_VISUALIZAR", "BIKETOUR_VISUALIZAR"},
        "BIKE_TOUR_OPERAR": {"BIKE_TOUR_OPERAR", "BIKETOUR_OPERAR"},
        "BIKE_TOUR_GERENCIAR": {"BIKE_TOUR_GERENCIAR", "BIKETOUR_GERENCIAR"},
        "BIKETOUR_OPERAR": {"BIKE_TOUR_OPERAR", "BIKETOUR_OPERAR"},
        "BIKETOUR_GERENCIAR": {"BIKE_TOUR_GERENCIAR", "BIKETOUR_GERENCIAR"},
    }
    return bool(aliases.get(codigo, {codigo}) & permissoes)


@dataclass(frozen=True, slots=True)
class ResultadoComando:
    status: int
    corpo: ResultadoJSON


@dataclass(frozen=True, slots=True)
class ContextoComando:
    """Instante obtido apos o lock; o handler nao controla commit ou rollback."""

    session: Session
    ator: ContextoRbac
    correlation_id: UUID
    agora: datetime
    pendencias: list[PendenciaBikeTour] = field(default_factory=list)


class BikeTourUnitOfWork:
    def __init__(self, session: Session) -> None:
        self.session = session
        self.operacoes = OperacaoRepository(session)

    def executar(
        self,
        *,
        ator: ContextoRbac,
        permissao: PermissaoComando,
        correlation_id: UUID,
        operacao: str,
        alvo: int,
        chave: str,
        payload: dict[str, object],
        comando: Callable[[ContextoComando], ResultadoComando],
    ) -> ResultadoComando:
        """Autoriza antes do replay; nunca confirma uma transacao preexistente."""
        if not _tem_permissao(ator.permissoes, "BIKE_TOUR_VISUALIZAR") or not _tem_permissao(
            ator.permissoes, permissao
        ):
            raise BikeTourError(403, "BT_PERMISSAO_INSUFICIENTE")
        if (
            not 1 <= len(chave) <= 100
            or not re.fullmatch(r"[a-z][a-z0-9_]{0,49}", operacao)
            or alvo < 0
        ):
            raise BikeTourError(422, "BT_COMANDO_INVALIDO")
        if self.session.in_transaction():
            raise RuntimeError("Bike Tour requer Session sem transacao preexistente")
        chave_hash = hashlib.sha256(chave.encode()).hexdigest()
        payload_hash = hashlib.sha256(
            json.dumps(payload, sort_keys=True, separators=(",", ":"), allow_nan=False).encode()
        ).hexdigest()
        try:
            with self.session.begin():
                self.session.connection(execution_options={"isolation_level": "READ COMMITTED"})
                self.session.execute(text("SET LOCAL lock_timeout = '5s'"))
                self.session.execute(text("SELECT pg_advisory_xact_lock(2700, 1)"))
                anterior = self.operacoes.obter(ator.id_usuario, operacao, alvo, chave_hash)
                if anterior is not None:
                    if anterior.payload_hash != payload_hash:
                        raise BikeTourError(409, "BT_CHAVE_REUTILIZADA")
                    if (
                        isinstance(anterior.resultado, dict)
                        and anterior.resultado.get("retencao_compactada") is True
                    ):
                        raise BikeTourError(409, "BT_RESPOSTA_COMPACTADA")
                    return ResultadoComando(anterior.http_status, deepcopy(anterior.resultado))
                contexto = ContextoComando(self.session, ator, correlation_id, datetime.now(UTC))
                resultado = comando(contexto)
                if not 200 <= resultado.status <= 299:
                    raise RuntimeError("Somente resultados bem-sucedidos podem ser persistidos")
                registro = OperacaoBikeTour(
                    id_usuario=ator.id_usuario,
                    operacao=operacao,
                    alvo=alvo,
                    chave_hash=chave_hash,
                    payload_hash=payload_hash,
                    http_status=resultado.status,
                    resultado=deepcopy(resultado.corpo),
                    correlation_id=correlation_id,
                    created_by=str(ator.id_usuario),
                )
                self.operacoes.adicionar(registro)
                for pendencia in contexto.pendencias:
                    pendencia.id_operacao_bike_tour = registro.id_operacao_bike_tour
                    self.session.add(pendencia)
                if contexto.pendencias:
                    self.session.flush()
            return resultado
        except IntegrityError as exc:
            raise BikeTourError(409, "BT_CONFLITO_INTEGRIDADE") from exc
        except OperationalError as exc:
            if getattr(exc.orig, "sqlstate", None) in {"55P03", "40P01"}:
                raise BikeTourError(409, "BT_CONTENCAO") from exc
            raise BikeTourError(503, "BT_FONTE_INDISPONIVEL") from exc
        except TimeoutError as exc:
            raise BikeTourError(503, "BT_FONTE_INDISPONIVEL") from exc
