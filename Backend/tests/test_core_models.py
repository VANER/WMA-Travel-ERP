"""Gates dos models que refletem as autoridades do Core Corporativo."""

from sqlalchemy import CheckConstraint, Identity, UniqueConstraint

from app.db import models as registered_models
from app.db.base import Base

EXPECTED_COLUMNS = {
    "localidade": {"id_localidade", "cidade", "uf", "pais"},
    "pessoa": {
        "id_pessoa",
        "tipo_pessoa",
        "nome_razao_social",
        "nome_fantasia",
        "cpf_cnpj",
        "rg_ie",
        "data_nascimento",
        "telefone",
        "email",
        "logradouro",
        "numero",
        "bairro",
        "cep",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
        "id_localidade",
    },
    "empresa": {
        "id_empresa",
        "razao_social",
        "nome_fantasia",
        "cnpj",
        "inscricao_municipal",
        "regime_tributario",
        "data_abertura",
        "capital_social",
        "telefone",
        "email",
        "site",
        "logradouro",
        "numero",
        "complemento",
        "bairro",
        "cep",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
        "id_localidade",
    },
    "cliente": {
        "id_cliente",
        "id_pessoa",
        "codigo_cliente",
        "observacao",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    },
    "fornecedor": {
        "id_fornecedor",
        "id_pessoa",
        "codigo_fornecedor",
        "tipo_fornecedor",
        "observacao",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    },
    "tipo_documento": {
        "id_tipo_documento",
        "codigo",
        "descricao",
        "categoria",
        "prazo_validade_dias",
        "ativo",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    },
    "documento": {
        "id_documento",
        "id_tipo_documento",
        "descricao",
        "entidade_tipo",
        "entidade_id",
        "data_documento",
        "data_validade",
        "status",
        "observacao",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    },
    "configuracao_empresa": {
        "id_configuracao",
        "id_empresa",
        "nome_sistema",
        "logo",
        "email_padrao",
        "telefone_padrao",
        "site",
        "timezone",
        "created_at",
        "updated_at",
        "deleted_at",
    },
    "parametro_sistema": {
        "id_parametro",
        "codigo",
        "descricao",
        "valor",
        "tipo",
        "grupo",
        "ativo",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    },
}

REQUIRED_COLUMNS = {
    "localidade": {"id_localidade", "cidade", "pais"},
    "pessoa": {
        "id_pessoa",
        "tipo_pessoa",
        "nome_razao_social",
        "created_at",
        "id_localidade",
    },
    "empresa": {
        "id_empresa",
        "razao_social",
        "nome_fantasia",
        "created_at",
        "versao",
        "id_localidade",
    },
    "cliente": {"id_cliente", "id_pessoa"},
    "fornecedor": {"id_fornecedor", "id_pessoa"},
    "tipo_documento": {"id_tipo_documento", "codigo", "descricao", "created_at"},
    "documento": {"id_documento", "id_tipo_documento"},
    "configuracao_empresa": {"id_configuracao", "id_empresa"},
    "parametro_sistema": {"id_parametro", "codigo", "created_at"},
}

EXPECTED_REGISTERED_MODELS = {
    "Banco",
    "Categoria",
    "CentroCusto",
    "Classificacao",
    "Cliente",
    "Conciliacao",
    "CondicaoComercial",
    "ConfiguracaoEmpresa",
    "Contrato",
    "Conta",
    "ContaBancaria",
    "Documento",
    "Empresa",
    "EventoSeguranca",
    "Fornecedor",
    "FunilVenda",
    "Grupo",
    "InteracaoLead",
    "ItemProposta",
    "ItemVenda",
    "Lead",
    "Lancamento",
    "Localidade",
    "Movimentacao",
    "Operadora",
    "Oportunidade",
    "OrigemLead",
    "ParametroSistema",
    "Pagamento",
    "Parcela",
    "PeriodoFinanceiro",
    "PerfilAcesso",
    "PerfilPermissao",
    "Permissao",
    "Proposta",
    "RecuperacaoCredencial",
    "Pessoa",
    "SessaoUsuario",
    "TipoDocumento",
    "Transferencia",
    "Usuario",
    "UsuarioPerfil",
    "Venda",
}


def test_core_models_register_only_the_inventory_authorities() -> None:
    security_tables = {
        "perfil_acesso",
        "perfil_permissao",
        "permissao",
        "recuperacao_credencial",
        "sessao_usuario",
        "evento_seguranca",
        "usuario",
        "usuario_perfil",
    }
    commercial_tables = {
        "condicao_comercial",
        "contrato",
        "funil_vendas",
        "interacao_lead",
        "item_proposta",
        "item_venda",
        "lead",
        "operadora",
        "oportunidade",
        "origem_lead",
        "proposta",
        "venda",
    }
    financial_tables = {
        "afac",
        "ativo_imobilizado",
        "banco",
        "caixa",
        "capital_social",
        "cartao",
        "categoria",
        "centro_custo",
        "classificacao",
        "conciliacao_bancaria",
        "conta",
        "conta_bancaria",
        "depreciacao_ativo",
        "distribuicao_lucro",
        "emprestimo",
        "emprestimo_parcela",
        "fatura_cartao",
        "fatura_cartao_item",
        "grupo",
        "lancamento",
        "lancamento_parcela",
        "movimentacao_bancaria",
        "pagamento",
        "periodo_financeiro",
        "pro_labore",
        "subcategoria",
        "transferencia",
        "tributo",
    }
    tourism_tables = {
        "alocacao_vaga",
        "destino",
        "pacote_viagem",
        "produto_turistico",
        "reserva",
        "reserva_correlacao",
        "saida_turistica",
    }
    excluded_tables = security_tables | commercial_tables | financial_tables | tourism_tables
    table_names = {
        table.name for table in Base.metadata.tables.values() if table.name not in excluded_tables
    }

    assert table_names == set(EXPECTED_COLUMNS)
    assert all(
        table.schema is None
        for table in Base.metadata.tables.values()
        if table.name not in financial_tables
    )
    assert set(registered_models.__all__) == EXPECTED_REGISTERED_MODELS | {
        "AlocacaoVaga",
        "Destino",
        "PacoteViagem",
        "ProdutoTuristico",
        "Reserva",
        "ReservaCorrelacao",
        "SaidaTuristica",
    }


def test_core_model_columns_and_nullability_match_the_baseline() -> None:
    for table_name, expected_columns in EXPECTED_COLUMNS.items():
        table = Base.metadata.tables[table_name]
        required_columns = {column.name for column in table.columns if not column.nullable}

        assert set(table.columns.keys()) == expected_columns
        assert required_columns == REQUIRED_COLUMNS[table_name]


def test_core_models_preserve_historical_constraint_names() -> None:
    expected_foreign_keys = {
        "fk_pessoa_localidade",
        "fk_empresa_localidade",
        "fk_cliente_pessoa",
        "fk_fornecedor_pessoa",
        "fk_documento_tipo",
        "fk_config_empresa",
    }
    expected_unique_constraints = {
        "uk_cliente_codigo_cliente",
        "uk_fornecedor_codigo_fornecedor",
        "uk_tipo_documento_codigo",
        "uk_parametro_sistema_codigo",
        "uk_localidade_cidade_uf_pais",
        "uq_cliente_id_pessoa",
    }

    foreign_keys = {
        constraint.name
        for table in Base.metadata.tables.values()
        if table.name in EXPECTED_COLUMNS
        for constraint in table.foreign_key_constraints
    }
    unique_constraints = {
        constraint.name
        for table in Base.metadata.tables.values()
        if table.name in EXPECTED_COLUMNS
        for constraint in table.constraints
        if isinstance(constraint, UniqueConstraint)
    }
    pessoa_checks = {
        constraint.name
        for constraint in Base.metadata.tables["pessoa"].constraints
        if isinstance(constraint, CheckConstraint)
    }

    assert foreign_keys == expected_foreign_keys
    assert unique_constraints == expected_unique_constraints
    assert pessoa_checks == {"ck_tipo_pessoa"}


def test_localidade_preserves_generated_always_identity() -> None:
    identity = Base.metadata.tables["localidade"].c.id_localidade.identity

    assert isinstance(identity, Identity)
    assert identity.always


def test_polymorphic_document_link_remains_without_foreign_key() -> None:
    documento = Base.metadata.tables["documento"]

    assert not documento.c.entidade_tipo.foreign_keys
    assert not documento.c.entidade_id.foreign_keys
