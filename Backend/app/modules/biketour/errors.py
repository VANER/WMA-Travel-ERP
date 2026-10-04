"""Falhas de dominio seguras para a fronteira HTTP de Bike Tour."""


class BikeTourError(ValueError):
    """Erro previsivel sem detalhes de SQL, credenciais ou dados pessoais."""

    def __init__(self, status_code: int, code: str) -> None:
        super().__init__(code)
        self.status_code = status_code
        self.code = code
