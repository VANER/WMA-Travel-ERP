# Módulos funcionais

Cada subpacote representa uma fronteira de domínio do monólito modular. Regras, contratos e persistência devem
permanecer no domínio proprietário.

Um módulo não deve importar a implementação interna de outro módulo. A comunicação entre domínios será criada
progressivamente por interfaces, serviços ou contratos internos explícitos.

Os pacotes começam somente com sua declaração de fronteira. Models, repositories, services, schemas e routers
serão adicionados quando o respectivo caso de uso entrar no escopo.
