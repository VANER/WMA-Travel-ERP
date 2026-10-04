"""Alvos de FK legados sem autoridade de DDL ou mapeamento ORM paralelo.

Metadata separado: estes objetos nao integram Base.metadata nem autogenerate.
Somente as PKs fisicas verificadas sao descritas; as portas dos proprietarios
continuam responsaveis por ler e validar os cadastros completos.
"""

from sqlalchemy import Column, Integer, MetaData, Table

_references = MetaData()

ativo_imobilizado = Table(
    "ativo_imobilizado", _references, Column("id_ativo", Integer, primary_key=True)
)
guia_turistico = Table("guia_turistico", _references, Column("id_guia", Integer, primary_key=True))
transporte = Table("transporte", _references, Column("id_transporte", Integer, primary_key=True))
