"""Registro estruturado de eventos operacionais de seguranca."""

from uuid import UUID, uuid4

from sqlalchemy.orm import Session

from app.modules.seguranca.models import EventoSeguranca

ALLOWED_RESULTS = {"SUCESSO", "NEGADO", "ERRO"}


class AuditorSeguranca:
    """Persiste eventos permitidos e rejeita campos potencialmente sensiveis."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def registrar(
        self,
        codigo: str,
        resultado: str,
        *,
        id_usuario: int | None = None,
        id_sessao: UUID | None = None,
        endereco_ip: str | None = None,
        agente_usuario: str | None = None,
        detalhes: dict[str, object] | None = None,
    ) -> EventoSeguranca:
        if resultado not in ALLOWED_RESULTS:
            raise ValueError("resultado de auditoria invalido")
        detalhes_seguros = detalhes or {}
        campos_proibidos = {"senha", "credencial", "token", "access_token", "refresh_token"}
        if campos_proibidos.intersection(key.lower() for key in detalhes_seguros):
            raise ValueError("detalhes de auditoria contem campo sensivel")
        evento = EventoSeguranca(
            id_evento=uuid4(),
            codigo=codigo,
            resultado=resultado,
            id_usuario=id_usuario,
            id_sessao=id_sessao,
            endereco_ip=endereco_ip,
            agente_usuario=agente_usuario,
            detalhes=detalhes_seguros,
        )
        self.session.add(evento)
        return evento
