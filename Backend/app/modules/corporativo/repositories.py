"""Repositories SQLAlchemy do Core Corporativo."""

from sqlalchemy import select
from sqlalchemy.orm import InstrumentedAttribute, Session

from app.db.base import Base
from app.modules.corporativo.models import (
    Cliente,
    ConfiguracaoEmpresa,
    Documento,
    Empresa,
    Fornecedor,
    Localidade,
    ParametroSistema,
    Pessoa,
    TipoDocumento,
)


class Repository[ModelT: Base]:
    """Persistência mínima compartilhada, sem controlar a transação."""

    def __init__(
        self,
        session: Session,
        model_type: type[ModelT],
        identifier: InstrumentedAttribute[int],
    ) -> None:
        self.session = session
        self.model_type = model_type
        self.identifier = identifier

    def obter(self, identifier: int) -> ModelT | None:
        """Obtém uma entidade pela chave primária."""
        return self.session.get(self.model_type, identifier)

    def listar(self, *, offset: int = 0, limite: int = 100) -> list[ModelT]:
        """Lista entidades deterministicamente, com paginação explícita."""
        if offset < 0:
            raise ValueError("offset não pode ser negativo")
        if limite < 1 or limite > 1000:
            raise ValueError("limite deve estar entre 1 e 1000")

        statement = select(self.model_type).order_by(self.identifier).offset(offset).limit(limite)
        return list(self.session.scalars(statement).all())

    def adicionar(self, entity: ModelT) -> ModelT:
        """Adiciona e sincroniza a entidade sem confirmar a transação."""
        self.session.add(entity)
        self.session.flush()
        return entity


class LocalidadeRepository(Repository[Localidade]):
    """Persistência de localidades."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Localidade, Localidade.id_localidade)


class PessoaRepository(Repository[Pessoa]):
    """Persistência de pessoas."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Pessoa, Pessoa.id_pessoa)


class EmpresaRepository(Repository[Empresa]):
    """Persistência de empresas."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Empresa, Empresa.id_empresa)


class ClienteRepository(Repository[Cliente]):
    """Persistência de clientes."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Cliente, Cliente.id_cliente)


class FornecedorRepository(Repository[Fornecedor]):
    """Persistência de fornecedores."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Fornecedor, Fornecedor.id_fornecedor)


class TipoDocumentoRepository(Repository[TipoDocumento]):
    """Persistência de tipos documentais."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, TipoDocumento, TipoDocumento.id_tipo_documento)


class DocumentoRepository(Repository[Documento]):
    """Persistência de documentos."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, Documento, Documento.id_documento)


class ConfiguracaoEmpresaRepository(Repository[ConfiguracaoEmpresa]):
    """Persistência de configurações por empresa."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, ConfiguracaoEmpresa, ConfiguracaoEmpresa.id_configuracao)


class ParametroSistemaRepository(Repository[ParametroSistema]):
    """Persistência de parâmetros globais."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, ParametroSistema, ParametroSistema.id_parametro)
