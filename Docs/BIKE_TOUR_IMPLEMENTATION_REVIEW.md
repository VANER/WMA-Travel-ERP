# Revisão da implementação da etapa 2.7 — Bike Tour

> **Projeto:** WMA Travel ERP
> **Fase:** 2 — Backend e API
> **Etapa:** 2.7 — Bike Tour
> **Tipo:** Revisão técnica e funcional
> **Versão:** 1.2
> **Data:** 23/09/2026
> **Status:** AUDITADA; CERTIFICAÇÃO BLOQUEADA

## 1. Escopo e autorização

A revisão atende à solicitação de diagnosticar, concluir, corrigir, validar, auditar e integrar a etapa 2.7.
O gate documental foi aprovado em 11/09/2026. A aprovação autoriza implementação, sem comprovar sua conclusão.
As alterações locais anteriores foram preservadas. Dumps, baseline, tags e migrations históricas não foram reescritos.
Este registro segue o modelo de documento técnico; certificação e SHA final dependem dos gates de entrega.

## 2. Diagnóstico e correções

O estado inicial continha infraestrutura de banco e API de produto/evento, com os demais fluxos ainda ausentes.
A cobertura anterior de 100% media somente o código existente; não comprovava a implementação dos requisitos ausentes.

Correções realizadas durante a revisão:

- releitura de versão e timestamps após triggers, antes de persistir a resposta idempotente;
- exclusão lógica respeitada nas consultas e alterações de produto/evento;
- validação de rota, apoio, horário, origem e condições de encerramento;
- cancelamento de evento com liberação e pendências na mesma transação;
- alinhamento das fixtures à revisão `202609170200`, sem usuário PostgreSQL fixo no teste HTTP;
- correção de tipagem e de duplicações/contradições documentais;
- propagação da correlação HTTP para os comandos e ampliação da consulta de auditoria por evento.

## 3. Implementação funcional

Os comandos novos estão em `Backend/app/modules/biketour/operations.py`, com contratos em
`operational_schemas.py`, rotas em `operational_router.py` e consultas sem escrita em `queries.py`.
Reutilizam a unidade de trabalho e suas permissões explícitas, lock PostgreSQL, rollback e idempotência.

| Área | Implementação | Validação necessária para encerramento |
| --- | --- | --- |
| Produto/evento | Cadastro, alteração, abertura, início, cancelamento e conclusão | T01, T02, T12 |
| Recursos | Cadastro, estado, disponibilidade e exclusividade temporal | T03, T15 |
| Inscrição | Bloqueio, rebloqueio, confirmação, presença, no-show e conclusão | T04, T05, T11, T16, T17 |
| Reacomodação | Destino e liberação da origem na mesma unidade de trabalho | T18, T20 |
| Preparação | Rota, equipe e logística; substituição preserva histórico | T07, T09, T10 |
| Operação | Passagens ordenadas, ocorrências, avaliação e relatório | T07, T08, T12 |
| Recuperação | Expiração, reconciliação e tratamento de pendências | T06, T16, T19 |
| Segurança | V/O/G, respostas mínimas e replay autorizado | T13, T14, T22 |

As pendências externas são vinculadas à operação após a persistência do resultado e antes do commit.
Falha em qualquer escrita reverte também as transições e as alocações. Não há mutação comercial ou financeira.
GET não executa limpeza nem atualiza estado. Não há scheduler ou expurgo automático nesta etapa.

## 4. Evidências disponíveis

- Retomada controlada em 23/09/2026, na branch `feature/2.7-bike-tour`.
- HEAD de referência: `ba45b3c1c544a05a6ed317445f31ba737c497919`; as alterações auditadas não estão nesse commit.
- Precheck: 20 arquivos rastreados modificados e 55 novos; nenhum arquivo foi alterado durante o precheck.
- `git diff --check`: aprovado. `git diff --stat`: 20 arquivos, 6.277 inserções e 194 exclusões.
- O inventário completo foi registrado pela saída de `git status --short`; o diff estatístico não inclui novos arquivos.
- Windows, Python 3.13.15, Pytest 9.1.1, ambiente virtual `Backend/.venv`.
- Suíte oficial estável: 842 coletados, 842 aprovados, zero falhas, zero ignorados; duração de 244,57 segundos.
- Cobertura: 4.348 linhas executáveis, zero ausentes, 100,00%. A medição anterior de 99,45% foi substituída.
- A configuração oficial não habilita medição de branches; esse indicador é N/A, não 100% presumido.
- Nenhum teste artificial, exclusão de cobertura ou alteração de comportamento foi introduzido nesta retomada.
- Ruff Format apontou somente terminadores mistos em `app/core/logging.py`; a normalização preservou texto e linhas.
- Ruff, Format (163 arquivos), Mypy (145 arquivos) e `pip check`: aprovados.
- OpenAPI: snapshot sincronizado, 31 operações Bike Tour e 31 identificadores únicos.
- Compatibilidade contra `origin/main` local: nenhuma incompatibilidade detectada; não houve atualização remota.
- Markdownlint: 156 documentos rastreados e dois novos aprovados; CSpell dos documentos vivos e novos aprovado.

Comandos oficiais de backend, executados em `Backend/` com o Python do ambiente virtual:

```powershell
python -m pip check
ruff check .
ruff format --check app tests migrations scripts
mypy app tests scripts
pytest -W error --ignore=tests/integration --cov=app --cov-report=term-missing
alembic heads
python scripts/export_openapi.py --check
python scripts/check_openapi_compatibility.py --base-ref origin/main
```

As fontes são `.github/workflows/backend-ci.yml` e `.github/workflows/documentation-ci.yml`.
Os executáveis Python foram invocados pelo ambiente virtual com `python -m`; argumentos e configurações preservados.
Os filtros documentais do Bash foram traduzidos para PowerShell, mantendo o mesmo conjunto de arquivos do workflow.
Os dois documentos novos foram verificados adicionalmente, pois ainda não aparecem em `git ls-files '*.md'`.
O snapshot não foi regenerado nesta retomada. Não foram executados commit, push, PR ou merge.

### 4.1 PostgreSQL

O fluxo HTTP ampliado passou no banco local descartável `wma_phase2_test`, com rollback da fixture externa.
Inclui preparação, abertura, inscrição, replay, reacomodação, cancelamento da inscrição, pendência e tratamento,
reconciliação, expiração, resolução de ocorrência, confirmação, presença, passagens, avaliação e conclusão.
A suíte oficial consolidada passou: 110 coletados, 110 aprovados, zero falhas e zero ignorados, em 129,96 segundos.
Foram usados os seis arquivos Bike Tour listados no workflow, com `--run-postgresql --no-cov`.
As URLs são fornecidas somente ao processo, sem registrar credenciais. Produção não foi acessada.

Alembic apresentou head único `202609170200`. No mesmo banco descartável, sem eventos persistidos,
foram executados `alembic current`, `alembic upgrade head`, `alembic downgrade -1`, `alembic upgrade head`
e `alembic current`. O ciclo `202609170200 → 202609170100 → 202609170200` passou e manteve zero eventos.
Não foi repetida a restauração completa da baseline nem executado o CI Linux nesta retomada.
As evidências físicas históricas foram preservadas, sem transformá-las em certificação do conjunto atual.

### 4.2 Auditoria semântica do contrato

Sincronização com a aplicação não significa conformidade com o contrato documental aprovado.

| Verificação | Resultado | Evidência e consequência |
| --- | --- | --- |
| Prefixo | PASS | A3 e implementação convergem em `/api/v1/biketour`; alias `/api/v1/bike-tour` preservado somente para compatibilidade e oculto do OpenAPI |
| Métodos e operações | PASS | As 31 operações previstas estão implementadas, com identificadores únicos |
| Respostas operacionais | FAIL | Inscrição usa `ResultadoJSON` genérico; o sucesso 200 do rebloqueio não descreve schema |
| Códigos de erro | PASS | Rotas operacionais descrevem 401/403/404/409/422/500/503; testes verificam traduções |
| RBAC | PASS | V/O/G explícitos nas dependências; UoW autoriza antes do replay; aliases históricos preservados |
| Vocabulário | FAIL | Nível usa FACIL/MODERADO/DIFICIL, divergindo de INICIANTE/INTERMEDIARIO de A2 |
| Motivo do evento | FAIL | `EventoAcaoRequest.motivo` aceita texto livre; A3 exige códigos enumerados |
| Auditoria consultável | FAIL | Consulta não relaciona passagem/avaliação ao evento pelo vínculo da inscrição |

A divergência de nível já constava da seção 7.3 da decisão de schema. O papel PARTICIPANTE é convertido em CICLISTA;
o estado DISPONIVEL permanece diferente do ATIVO documental. Essas diferenças exigem conciliação explícita.
A auditoria física por triggers existe, mas não substitui a completude da projeção pública por evento.
Essa projeção também não apresenta versões anterior/nova. Nenhuma dessas diferenças foi ocultada regenerando o snapshot.

## 5. Pendências de fechamento

- Conciliar vocabulário, schemas de resposta e motivos com A2/A3, sem reescrever migrations históricas.
- Completar a consulta de auditoria por evento e verificar versões/transições/correlação de ponta a ponta.
- Executar corridas funcionais da última bicicleta e de expiração versus confirmação em conexões independentes.
- Injetar falhas após destino da reacomodação e após cada escrita de inscrição/alocação/pendência/resposta.
- Validar retenção administrativa, preservação expressa e impedimentos de eliminação, conforme A6/T23.
- Atualizar a documentação de execução e o CHANGELOG com o incremento funcional; os registros atuais são parciais.
- Certificação funcional, Secret Scan e CI do SHA final permanecem pendentes; não se reutiliza o gate documental.
- Publicação e integração estão proibidas nesta retomada; revisão humana deve anteceder qualquer operação desse tipo.

### 5.1 Requisitos funcionais

PASS significa que as evidências do recorte foram verificadas; não elimina pendências dos testes adversariais abaixo.

| BT-REQ | Resultado | Evidência ou bloqueio |
| --- | --- | --- |
| 001 | FAIL | Cadastro e unicidade testados; enum de nível diverge do aceite |
| 002 | PASS | Período, capacidade, unicidade, preparação e transições cobertos em services/API |
| 003 | FAIL | Exclusividade física testada; disponibilidade GET não revalida a situação da origem do recurso |
| 004 | PASS | Bloqueio e rebloqueio com mesma identidade, prazo e versão exercitados |
| 005 | PASS | Confirmação valida reserva/prazo e reutiliza alocação |
| 006 | PASS | Porta comercial, reconciliação e pendência sem escrita financeira |
| 007 | PASS | Rota e passagens com pertencimento, ordem, horário e unicidade |
| 008 | PASS | Ocorrência enumerada, transições e resolução exercitadas |
| 009 | PENDENTE | Substituição implementada; falta falha injetada no fluxo real preservando plano anterior |
| 010 | PENDENTE | Liderança única e histórico testados; falta disputa funcional do mesmo guia entre eventos |
| 011 | PASS | Origem reserva/passageiro validada; nenhuma pessoa criada pelo módulo |
| 012 | PASS | Presença, resultados finais, ocorrência grave, avaliação e fechamento exercitados |
| 013 | FAIL | RBAC e ocorrência restrita aprovados; motivo livre de evento permite conteúdo fora dos códigos |
| 014 | FAIL | Persistência auditada existe; consulta por evento omite operações e versões |

### 5.2 Casos do plano T01–T25

| Caso | Resultado | Evidência ou bloqueio |
| --- | --- | --- |
| T01 | FAIL | Origem/duplicidade testadas; vocabulário público de nível divergente |
| T02 | PASS | Testes de criação, período, capacidade, preparação e unicidade |
| T03 | PENDENTE | Manutenção/sobreposição cobertas em testes unitários; falta cenário físico de intervalos consecutivos |
| T04 | PASS | Fluxo real reutiliza inscrição após cancelamento e expiração |
| T05 | PASS | Confirmação e rejeições por origem/prazo cobertas |
| T06 | PASS | Portas comerciais testadas e consulta restrita a identificadores |
| T07 | PASS | Testes de passagem e fluxo HTTP real |
| T08 | PASS | Schemas fechados e resolução de ocorrência no PostgreSQL |
| T09 | PENDENTE | Falta injeção de falha na substituição de apoio pelo serviço real |
| T10 | PENDENTE | Líder único e histórico testados; falta disputa funcional do mesmo guia entre eventos |
| T11 | PASS | Testes de pertencimento de passageiro/reserva/saída |
| T12 | PASS | Transições, avaliação única e conclusão exercitadas |
| T13 | FAIL | Matriz RBAC testada; motivo de evento não segue a restrição de códigos |
| T14 | FAIL | Triggers e rollback testados; projeção auditável incompleta |
| T15 | PENDENTE | Lock/replay real não substitui corrida funcional pela última bicicleta |
| T16 | PENDENTE | Expiração sequencial testada; corrida contra confirmação ainda sem evidência |
| T17 | PASS | Duas conexões comprovam espera/replay; divergência de payload e revogação testadas |
| T18 | PENDENTE | Reacomodação bem-sucedida testada; falha após reservar destino ainda sem evidência real |
| T19 | PASS | Reconciliação real e teste unitário distinguindo indisponibilidade de origem inválida |
| T20 | PENDENTE | Rollback genérico após flush não cobre todos os pontos de falha pedidos |
| T21 | PASS | Testes físicos de FK, CHECK, unicidade e integridade diferida |
| T22 | PASS | Replay exige permissão atual; ocorrência rejeita texto fora dos códigos |
| T23 | PASS | Política administrativa de retenção implementada e comprovada por testes unitários, HTTP e PostgreSQL |
| T24 | PENDENTE | Ciclos dos deltas e revisão final passaram; reconstrução integral do conjunto atual não repetida |
| T25 | FAIL | Snapshot sincronizado e prefixo conforme A3; motivos, vocabulário e schemas ainda divergem do contrato aprovado |

Frontend, aplicativo, scheduler e autoatendimento são N/A nesta etapa, conforme escopo aprovado.
O gate de roadmap exige módulo operacional e a ordem de execução exige certificação: ambos permanecem não encerrados.

## 6. Documentos relacionados

- [Gate documental](BIKE_TOUR_DOCUMENTATION_GATE.md).
- [Matriz funcional](BIKE_TOUR_FUNCTIONAL_MATRIX.md).
- [Contrato e rastreabilidade](BIKE_TOUR_TRACEABILITY_MATRIX.md).
- [Plano de testes](BIKE_TOUR_TEST_PLAN.md).
- [Decisão de schema](BIKE_TOUR_SCHEMA_DECISION.md).
- [Política transacional](BIKE_TOUR_TRANSACTION_POLICY.md).

## 7. Resultado da retomada

A meta de cobertura foi atingida sem criar testes nem alterar produção para elevar o indicador.
As únicas edições desta retomada foram a normalização de terminadores de `logging.py` e este relatório.
O inventário final continua com 20 arquivos rastreados modificados e 55 novos; alterações anteriores preservadas.

| Fluxo PostgreSQL exercitado | Resultado | Limite da evidência |
| --- | --- | --- |
| Reacomodação | PASS | Caminho bem-sucedido; rollback após destino permanece em T18 |
| Cancelamento | PASS | Inscrição; cancelamento de evento com inscrições ativas tem somente testes unitários |
| Pendência | PASS | Criação e tratamento; falhas entre escritas permanecem em T20 |
| Reconciliação | PASS | Cancelamento da origem e recuperação; indisponibilidade coberta por teste unitário |
| Expiração | PASS | Execução sequencial; corrida com confirmação permanece em T16 |
| Ocorrência | PASS | Criação, análise e resolução |
| Histórico | PASS | Identidade no rebloqueio, unicidade após exclusão lógica e substituição de liderança |

Não há autorização de certificação nesta revisão: existem FAIL e PENDENTE bloqueantes nas matrizes acima.
O Secret Scan não foi executado localmente: Gitleaks não está disponível. Não houve instalação de ferramenta.
Os gates do GitHub e a certificação por SHA final dependem de uma futura publicação autorizada.
A próxima ação é revisar os bloqueios, corrigir o contrato e as lacunas funcionais, e produzir evidência adversarial.
Nenhum commit, push, PR ou merge foi realizado. A entrega permanece para revisão humana.

## Controle de alterações

| Versão | Data | Alteração |
| --- | --- | --- |
| 1.0 | 23/09/2026 | Diagnóstico, implementação em validação e pendências reais de fechamento |
| 1.1 | 23/09/2026 | Medição estável de 100%, retomada sem publicação e auditoria dos contratos e T01–T25 |
| 1.2 | 23/09/2026 | Prefixo A3 alinhado em `/api/v1/biketour`; alias legado preservado fora do OpenAPI e T25 mantido bloqueado pelas demais divergências contratuais |

<!-- cspell:ignore FACIL DIFICIL -->
