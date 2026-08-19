# WMA Travel ERP --- Certificação da ETAPA 2.0.1

## Arquitetura Tecnológica da Fase 2

**Projeto:** WMA Travel ERP\
**Fase:** 2 --- Backend, API e Integrações\
**Etapa:** 2.0.1 --- Definição e Certificação da Arquitetura
Tecnológica\
**Data:** 18/08/2026\
**Status documental:** APROVADA

## 1. Objetivo

Registrar a conclusão documental da arquitetura tecnológica necessária
para autorizar o bootstrap do backend da Fase 2.

Esta certificação aprova decisões arquiteturais. Ela não afirma que o
backend, CI, banco de teste ou integrações já foram implementados; esses
itens serão validados nas etapas de implementação correspondentes.

## 2. Pré-condição

A Fase 1 é tratada como baseline certificada e protegida. A Fase 2
deverá evoluir o banco exclusivamente por migrations versionadas.

## 3. ADRs certificadas

  ADR       Tema                                       Status
  --------- ------------------------------------------ ----------
  ADR-001   Monólito Modular                           APROVADA
  ADR-002   Stack Tecnológica                          APROVADA
  ADR-003   Persistência e SQLAlchemy                  APROVADA
  ADR-004   Banco de Dados e Migrations                APROVADA
  ADR-005   Padrões de API                             APROVADA
  ADR-006   Configuração, Ambientes e Secrets          APROVADA
  ADR-007   Segurança, Autenticação e Autorização      APROVADA
  ADR-008   Estratégia de Testes                       APROVADA
  ADR-009   Integrações e Webhooks                     APROVADA
  ADR-010   Observabilidade e Auditoria Técnica        APROVADA
  ADR-011   Tratamento de Erros e Exceções             APROVADA
  ADR-012   Logging e Correlation ID                   APROVADA
  ADR-013   Convenções de Código e Estrutura Modular   APROVADA
  ADR-014   Limites Transacionais entre Módulos        APROVADA
  ADR-015   Integração com wmatravel.com.br            APROVADA

## 4. Critérios documentais

- Arquitetura inicial definida: OK.
- Fronteiras modulares definidas: OK.
- Stack tecnológica definida: OK.
- Persistência definida: OK.
- Política de migrations definida: OK.
- Padrões de API definidos: OK.
- Configuração e secrets definidos: OK.
- Princípios de segurança definidos: OK.
- Estratégia de testes definida: OK.
- Integrações e webhooks definidos: OK.
- Observabilidade definida: OK.
- Tratamento de erros definido: OK.
- Logging e correlação definidos: OK.
- Convenções de código definidas: OK.
- Limites transacionais definidos: OK.
- Integração com o website definida: OK.
- Proteção da baseline da Fase 1 definida: OK.
- Índice de ADRs criado: OK.

## 5. Decisões centrais

A arquitetura oficial inicial da Fase 2 é Monólito Modular.

A stack de referência é Python 3.13+, FastAPI, SQLAlchemy 2.x, Alembic,
psycopg 3, PostgreSQL 18.x, Pydantic v2, pytest, HTTPX, Uvicorn, OpenAPI
e GitHub Actions, com versões exatas fixadas após validação no
bootstrap.

O ERP é o núcleo corporativo. Sistemas externos, incluindo
wmatravel.com.br, devem integrar-se por API/webhooks e não podem acessar
diretamente o PostgreSQL corporativo.

## 6. Restrições

Esta certificação não autoriza:

- reescrever a baseline da Fase 1;
- usar create_all() como implantação oficial;
- versionar secrets;
- permitir acesso direto do website ao PostgreSQL;
- ignorar migrations para mudanças estruturais;
- quebrar fronteiras modulares sem decisão arquitetural formal.

## 7. Gate

``` text
Arquitetura ...................... OK
Monólito Modular ................. OK
Stack tecnológica ................ OK
Persistência ..................... OK
Migrations ....................... OK
API .............................. OK
Configuração e secrets ........... OK
Segurança ........................ OK
Testes ........................... OK
Integrações ...................... OK
Observabilidade .................. OK
Erros e exceções ................. OK
Logging/correlation .............. OK
Convenções ....................... OK
Transações ....................... OK
Website .......................... OK
Índice ADR ....................... OK
Baseline Fase 1 protegida ........ OK
```

## 8. Resultado

**ETAPA 2.0.1 --- ARQUITETURA TECNOLÓGICA: APROVADA DOCUMENTALMENTE**

O projeto está autorizado a iniciar a **ETAPA 2.0.2 --- Bootstrap do
Backend**, desde que a implementação respeite as ADRs vigentes.

## 9. Evidência e versionamento

O fechamento da etapa foi publicado e integrado pelo PR #2. O commit de
merge `7f5317b` em `main` registra a arquitetura e esta certificação sem
alterar a tag imutável `phase-1-final-2026-08-18`.
