"""Models SQLAlchemy que refletem as autoridades cadastrais da baseline."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    CHAR,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Identity,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.elements import conv

from app.db.base import Base


class AuditColumnsMixin:
    """Colunas históricas compartilhadas pelos cadastros auditáveis."""

    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class Localidade(Base):
    """Referência geográfica compartilhada por pessoas e empresas."""

    __tablename__ = "localidade"
    __table_args__ = (
        UniqueConstraint("cidade", "uf", "pais", name="uk_localidade_cidade_uf_pais"),
    )

    id_localidade: Mapped[int] = mapped_column(Integer, Identity(always=True), primary_key=True)
    cidade: Mapped[str] = mapped_column(String(100), nullable=False)
    uf: Mapped[str | None] = mapped_column(CHAR(2), nullable=True)
    pais: Mapped[str] = mapped_column(String(100), server_default=text("'Brasil'"), nullable=False)


class Pessoa(AuditColumnsMixin, Base):
    """Pessoa física ou jurídica da autoridade cadastral."""

    __tablename__ = "pessoa"
    __table_args__ = (
        CheckConstraint("tipo_pessoa IN ('FISICA', 'JURIDICA')", name=conv("ck_tipo_pessoa")),
    )

    id_pessoa: Mapped[int] = mapped_column(Integer, primary_key=True)
    tipo_pessoa: Mapped[str] = mapped_column(String(20), nullable=False)
    nome_razao_social: Mapped[str] = mapped_column(String(150), nullable=False)
    nome_fantasia: Mapped[str | None] = mapped_column(String(100), nullable=True)
    cpf_cnpj: Mapped[str | None] = mapped_column(String(18), nullable=True)
    rg_ie: Mapped[str | None] = mapped_column(String(30), nullable=True)
    data_nascimento: Mapped[date | None] = mapped_column(Date, nullable=True)
    telefone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    email: Mapped[str | None] = mapped_column(String(150), nullable=True)
    logradouro: Mapped[str | None] = mapped_column(String(150), nullable=True)
    numero: Mapped[str | None] = mapped_column(String(20), nullable=True)
    bairro: Mapped[str | None] = mapped_column(String(100), nullable=True)
    cep: Mapped[str | None] = mapped_column(String(10), nullable=True)
    id_localidade: Mapped[int] = mapped_column(
        ForeignKey("localidade.id_localidade", name="fk_pessoa_localidade"),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )

    localidade: Mapped[Localidade] = relationship(lazy="raise")


class Empresa(AuditColumnsMixin, Base):
    """Empresa operadora cadastrada no ERP."""

    __tablename__ = "empresa"
    __table_args__ = {"comment": "Cadastro das empresas pertencentes ao sistema WMA Travel"}

    id_empresa: Mapped[int] = mapped_column(Integer, primary_key=True)
    razao_social: Mapped[str] = mapped_column(String(150), nullable=False)
    nome_fantasia: Mapped[str] = mapped_column(String(100), nullable=False)
    cnpj: Mapped[str | None] = mapped_column(String(18), nullable=True)
    inscricao_municipal: Mapped[str | None] = mapped_column(String(30), nullable=True)
    regime_tributario: Mapped[str | None] = mapped_column(String(50), nullable=True)
    data_abertura: Mapped[date | None] = mapped_column(Date, nullable=True)
    capital_social: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    telefone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    email: Mapped[str | None] = mapped_column(String(150), nullable=True)
    site: Mapped[str | None] = mapped_column(String(150), nullable=True)
    logradouro: Mapped[str | None] = mapped_column(String(150), nullable=True)
    numero: Mapped[str | None] = mapped_column(String(20), nullable=True)
    complemento: Mapped[str | None] = mapped_column(String(100), nullable=True)
    bairro: Mapped[str | None] = mapped_column(String(100), nullable=True)
    cep: Mapped[str | None] = mapped_column(String(10), nullable=True)
    id_localidade: Mapped[int] = mapped_column(
        ForeignKey("localidade.id_localidade", name="fk_empresa_localidade"),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    versao: Mapped[int] = mapped_column(Integer, server_default=text("1"), nullable=False)

    localidade: Mapped[Localidade] = relationship(lazy="raise")


class Cliente(AuditColumnsMixin, Base):
    """Papel de cliente atribuído a uma pessoa."""

    __tablename__ = "cliente"
    __table_args__ = (
        UniqueConstraint("codigo_cliente", name="uk_cliente_codigo_cliente"),
        UniqueConstraint("id_pessoa", name="uq_cliente_id_pessoa"),
    )

    id_cliente: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_pessoa: Mapped[int] = mapped_column(
        ForeignKey("pessoa.id_pessoa", name="fk_cliente_pessoa"), nullable=False
    )
    codigo_cliente: Mapped[str | None] = mapped_column(String(20), nullable=True)
    observacao: Mapped[str | None] = mapped_column(Text, nullable=True)

    pessoa: Mapped[Pessoa] = relationship(lazy="raise")


class Fornecedor(AuditColumnsMixin, Base):
    """Papel de fornecedor atribuído a uma pessoa."""

    __tablename__ = "fornecedor"
    __table_args__ = (
        UniqueConstraint("codigo_fornecedor", name="uk_fornecedor_codigo_fornecedor"),
    )

    id_fornecedor: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_pessoa: Mapped[int] = mapped_column(
        ForeignKey("pessoa.id_pessoa", name="fk_fornecedor_pessoa"),
        nullable=False,
    )
    codigo_fornecedor: Mapped[str | None] = mapped_column(String(20), nullable=True)
    tipo_fornecedor: Mapped[str | None] = mapped_column(String(50), nullable=True)
    observacao: Mapped[str | None] = mapped_column(Text, nullable=True)

    pessoa: Mapped[Pessoa] = relationship(lazy="raise")


class TipoDocumento(AuditColumnsMixin, Base):
    """Catálogo de tipos documentais."""

    __tablename__ = "tipo_documento"
    __table_args__ = (UniqueConstraint("codigo", name="uk_tipo_documento_codigo"),)

    id_tipo_documento: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    descricao: Mapped[str] = mapped_column(String(150), nullable=False)
    categoria: Mapped[str | None] = mapped_column(String(50), nullable=True)
    prazo_validade_dias: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ativo: Mapped[bool | None] = mapped_column(Boolean, server_default=text("true"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )


class Documento(AuditColumnsMixin, Base):
    """Metadados documentais com vínculo polimórfico legado."""

    __tablename__ = "documento"

    id_documento: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_tipo_documento: Mapped[int] = mapped_column(
        ForeignKey("tipo_documento.id_tipo_documento", name="fk_documento_tipo"),
        nullable=False,
    )
    descricao: Mapped[str | None] = mapped_column(String(200), nullable=True)
    entidade_tipo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    entidade_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    data_documento: Mapped[date | None] = mapped_column(Date, nullable=True)
    data_validade: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str | None] = mapped_column(
        String(30), server_default=text("'ATIVO'"), nullable=True
    )
    observacao: Mapped[str | None] = mapped_column(Text, nullable=True)

    tipo_documento: Mapped[TipoDocumento] = relationship(lazy="raise")


class ConfiguracaoEmpresa(Base):
    """Preferências operacionais vinculadas a uma empresa."""

    __tablename__ = "configuracao_empresa"

    id_configuracao: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_empresa: Mapped[int] = mapped_column(
        ForeignKey("empresa.id_empresa", name="fk_config_empresa"),
        nullable=False,
    )
    nome_sistema: Mapped[str | None] = mapped_column(String(100), nullable=True)
    logo: Mapped[str | None] = mapped_column(Text, nullable=True)
    email_padrao: Mapped[str | None] = mapped_column(String(150), nullable=True)
    telefone_padrao: Mapped[str | None] = mapped_column(String(30), nullable=True)
    site: Mapped[str | None] = mapped_column(String(150), nullable=True)
    timezone: Mapped[str | None] = mapped_column(
        String(50), server_default=text("'America/Sao_Paulo'"), nullable=True
    )
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    empresa: Mapped[Empresa] = relationship(lazy="raise")


class ParametroSistema(AuditColumnsMixin, Base):
    """Parâmetro funcional global da aplicação."""

    __tablename__ = "parametro_sistema"
    __table_args__ = (UniqueConstraint("codigo", name="uk_parametro_sistema_codigo"),)

    id_parametro: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(50), nullable=False)
    descricao: Mapped[str | None] = mapped_column(String(150), nullable=True)
    valor: Mapped[str | None] = mapped_column(String(255), nullable=True)
    tipo: Mapped[str | None] = mapped_column(String(30), nullable=True)
    grupo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ativo: Mapped[bool | None] = mapped_column(Boolean, server_default=text("true"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
