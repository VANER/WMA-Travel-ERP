"""Services transacionais do Core Corporativo."""

from sqlalchemy.orm import Session

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
from app.modules.corporativo.repositories import (
    ClienteRepository,
    ConfiguracaoEmpresaRepository,
    DocumentoRepository,
    EmpresaRepository,
    FornecedorRepository,
    LocalidadeRepository,
    ParametroSistemaRepository,
    PessoaRepository,
    Repository,
    TipoDocumentoRepository,
)


class CadastroService[ModelT: Base]:
    """Caso de uso cadastral com limite transacional explícito."""

    def __init__(self, session: Session, repository: Repository[ModelT]) -> None:
        self.session = session
        self.repository = repository

    def obter(self, identifier: int) -> ModelT | None:
        """Obtém uma entidade sem alterar a transação."""
        return self.repository.obter(identifier)

    def listar(self, *, offset: int = 0, limite: int = 100) -> list[ModelT]:
        """Lista entidades usando a paginação protegida do repository."""
        return self.repository.listar(offset=offset, limite=limite)

    def cadastrar(self, entity: ModelT) -> ModelT:
        """Persiste uma entidade em uma transação atômica."""
        try:
            persisted_entity = self.repository.adicionar(entity)
            self.session.commit()
        except Exception:
            self.session.rollback()
            raise
        return persisted_entity


class LocalidadeService(CadastroService[Localidade]):
    """Casos de uso cadastrais de localidades."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, LocalidadeRepository(session))


class PessoaService(CadastroService[Pessoa]):
    """Casos de uso cadastrais de pessoas."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, PessoaRepository(session))


class EmpresaService(CadastroService[Empresa]):
    """Casos de uso cadastrais de empresas."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, EmpresaRepository(session))


class ClienteService(CadastroService[Cliente]):
    """Casos de uso cadastrais de clientes."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, ClienteRepository(session))


class FornecedorService(CadastroService[Fornecedor]):
    """Casos de uso cadastrais de fornecedores."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, FornecedorRepository(session))


class TipoDocumentoService(CadastroService[TipoDocumento]):
    """Casos de uso cadastrais de tipos documentais."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, TipoDocumentoRepository(session))


class DocumentoService(CadastroService[Documento]):
    """Casos de uso cadastrais de documentos."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, DocumentoRepository(session))


class ConfiguracaoEmpresaService(CadastroService[ConfiguracaoEmpresa]):
    """Casos de uso cadastrais de configurações por empresa."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, ConfiguracaoEmpresaRepository(session))


class ParametroSistemaService(CadastroService[ParametroSistema]):
    """Casos de uso cadastrais de parâmetros globais."""

    def __init__(self, session: Session) -> None:
        super().__init__(session, ParametroSistemaRepository(session))
