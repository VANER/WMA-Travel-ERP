# Gate de transição — Turismo 2.6 para Bike Tour 2.7

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Status:** CONCLUÍDO; APENAS O GATE DOCUMENTAL DE BIKE TOUR PERMANECE ABERTO

## 1. Base auditada e fechamento do PR #60

O [PR #60](https://github.com/VANER/WMA-Travel-ERP/pull/60) foi integrado após corrigir a hierarquia do changelog
e os parágrafos contraditórios da certificação complementar. O
[CI do PR](https://github.com/VANER/WMA-Travel-ERP/actions/runs/34304027266) e o
[CI documental pós-merge](https://github.com/VANER/WMA-Travel-ERP/actions/runs/34304106278) passaram.

A `main` foi sincronizada por `git pull --ff-only origin main`, com árvore limpa e igualdade entre HEAD e
`origin/main` no SHA `f48b46566b1031dd089e9a14ca7ed0f226339f1a`.

## 2. Regressão e correção

| Gate da base auditada | Resultado |
| --------------------------------- | ------------------------------------------------------------ |
| Dependências | `pip check` aprovado |
| Ruff e formato | aprovados; 110 arquivos formatados |
| Mypy | aprovado; 101 arquivos |
| Alembic | head único `202609080100` |
| Banco restaurado de validação | head `202609080100`; zero constraints pendentes de validação |
| OpenAPI | sincronizado; comparador sem incompatibilidades |
| Markdownlint | aprovado; 141 arquivos no escopo do CI |
| CSpell | aprovado no escopo de documentos vivos do CI |
| Diff e commit | `git diff --check` e `git show --check` aprovados |
| Pytest com PostgreSQL e cobertura | 405 aprovados, 2 falhas, 1 erro; cobertura 99,93% |

A execução longa revelou que `tests/test_tokens.py` capturava o horário na coleta e emitia tokens com esse
instante horas depois. Os tokens expiravam antes da validação. A correção local renova o instante em cada teste,
sem alterar TTL, assinatura, validação de expiração ou código de produção.

O erro de configuração foi `PermissionError` na pasta temporária padrão do pytest, antes de executar o teste.
A nova execução usa uma pasta exclusiva e descartável dentro de `Backend/.venv`, ignorada pelo Git.

| Validação após a correção local | Resultado |
| ------------------------------------------------------ | ------------------------------------ |
| Ruff, formato e mypy | APROVADOS |
| Coleta simulada uma hora antes da execução | 14 testes de tokens aprovados |
| Suíte completa, PostgreSQL real e cobertura | 408 aprovados; 100%; 157,57 segundos |
| Integração da correção e regressão posterior da `main` | PENDENTE |

A validação aprovada corresponde à base `f48b465` mais a correção local em `Backend/tests/test_tokens.py`,
na branch `fix/2.6-transition-regression`. Ela não equivale a uma nova certificação da `main` sem essa correção.

O banco de integração é `wma_transicao_26_27_20260909_test`, local e descartável. A verificação de migrations
usa separadamente `wma_turismo_hardening_migration_20260908_test`. Nenhum banco compartilhado foi utilizado.

## 3. Situação SMTP e histórico

A mitigação no repositório foi concluída e o incidente foi encerrado com evidência
operacional no documento [Docs/SECURITY_INCIDENT_SMTP_CLOSURE.md](../SECURITY_INCIDENT_SMTP_CLOSURE.md).
A credencial antiga foi invalidada por troca de senha; a nova credencial foi configurada;
a autenticação SMTP SSL e o envio real foram validados com sucesso; os testes
unitários do adaptador Titan ficaram verdes; o segredo permaneceu fora do Git;
e não houve reescrita do histórico.

| Evidência | Situação |
| ----------------------------------- | --------------- |
| Credencial SMTP anterior invalidada | `PASS` |
| Nova credencial configurada | `PASS` |
| Autenticação SMTP SSL | `PASS` |
| Envio operacional real | `PASS` |
| Testes unitários Titan | `4 passed` |
| Segredo fora do Git | `PASS` |
| Reescrita do histórico Git | `NÃO EXECUTADA` |
| Incidente SMTP | `ENCERRADO` |

## 4. Decisão de transição

O gate de transição da 2.6 para a 2.7 está concluído. A regressão local foi
corrigida, validada e a segurança do SMTP foi encerrada com evidência documental
operacional. A proteção da branch `main` também foi habilitada com required status
checks ativos e política strict.

O único bloqueio relevante para a implementação funcional da 2.7 passa a ser o
[gate documental de Bike Tour](../BIKE_TOUR_DOCUMENTATION_GATE.md), que organiza o
inventário, as fronteiras de domínio, os requisitos e os critérios de aceite para o
módulo. A implementação funcional da 2.7 continua não autorizada até a aprovação
desse gate.

## 5. Adendo de auditoria do gate

Consulta ao GitHub em 09/09/2026 confirmou o
[PR #65 integrado](https://github.com/VANER/WMA-Travel-ERP/pull/65) em
`5856477a13d1919627197c775fdcfe3b693d5605`, com os três checks do PR aprovados.
No mesmo SHA da `main`, também foram aprovados:

- [Backend CI](https://github.com/VANER/WMA-Travel-ERP/actions/runs/34389139893);
- [Documentation CI](https://github.com/VANER/WMA-Travel-ERP/actions/runs/34389139783);
- [Secret Scan](https://github.com/VANER/WMA-Travel-ERP/actions/runs/34389139993).

O Backend CI inclui PostgreSQL real, cobertura, OpenAPI, restauração da baseline e ciclo de reversão/reaplicação.
A compatibilidade OpenAPI é verificada no PR; esse passo é pulado por condição no push pós-merge.
A linha `PENDENTE` da seção 2 representa o estado histórico daquela execução local, superado por esta evidência.
Os resultados e tempos históricos foram preservados; não representam falha atual nem nova medição desta auditoria.

O [registro SMTP](../SECURITY_INCIDENT_SMTP_CLOSURE.md), seção 6, identifica Vaner, data de 09/09/2026,
testes locais no VS Code e ausência de produção. A validação em produção é requisito da futura implantação.
A decisão de não reescrever o histórico está registrada; isso não significa ausência do segredo antigo no histórico.

O HEAD local desta auditoria é `74685c6`; `origin/main` aponta para `5856477`. Os históricos divergem,
mas `git diff HEAD origin/main` não mostrou diferenças de conteúdo versionado. Não houve sincronização ou reset.
Os documentos Bike Tour em elaboração são alterações locais adicionais e não estão cobertos pelos CIs acima.

A [matriz do gate 2.7](../BIKE_TOUR_GATE_AUDIT.md) preserva os bloqueadores documentais reais.
**ETAPA 2.7 = BLOQUEADA.**

<!-- cspell:ignore transicao -->
