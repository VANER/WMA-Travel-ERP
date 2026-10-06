# Recursos compartilhados

Este pacote é reservado a código genuinamente transversal e utilizado por múltiplos domínios. Ele não deve ser
usado como destino genérico para código sem proprietário definido.

Os contratos em `clientes.py`, `vendas.py`, `localidades.py` e `turismo.py` sustentam a comunicação entre
domínios, inclusive Bike Tour 2.7. A autoridade sobre dados e regras permanece no domínio proprietário.
Consulte as [fronteiras de Bike Tour](../../../Docs/BIKE_TOUR_DOMAIN_BOUNDARIES.md).
