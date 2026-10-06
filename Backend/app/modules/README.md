# Módulos funcionais

Cada subpacote representa uma fronteira de domínio do monólito modular. Regras, contratos e persistência devem
permanecer no domínio proprietário.

Um módulo não deve importar a implementação interna de outro módulo. A comunicação entre domínios usa
interfaces, serviços ou contratos internos explícitos.

Core Corporativo, Segurança, Comercial, Financeiro, Turismo e Bike Tour já possuem implementação no Backend.
A Etapa 2.7 foi integrada pelo PR #69, merge `ffcc09e`, em 04/10/2026. Pacotes reservados, como Fiscal,
não representam funcionalidades entregues. Novos casos de uso dependem de escopo autorizado.
Consulte a [ordem de execução](../../../Docs/PHASE_2_EXECUTION_ORDER.md).

O contrato de Cliente publicado em `shared/clientes.py` é implementado pelo adaptador do Core em
`corporativo/clientes.py` e consumido pelos casos de uso em `comercial/clientes.py`. O Comercial não importa o
model cadastral nem assume sua autoridade.
