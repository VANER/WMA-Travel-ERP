# Decisão de Dados de Bike Tour

> **Contexto de leitura — 05/10/2026:** as decisões e os estados datados deste documento preservam
> o histórico dos respectivos gates. Bike Tour 2.7 foi concluído, certificado e integrado à `main`
> em 04/10/2026 pelo PR #69, merge `ffcc09e`, com CI do PR e gates pós-merge aprovados.
> Consulte o [fechamento de rastreabilidade](BIKE_TOUR_TRACEABILITY_MATRIX.md) para o estado vigente.
> Esta nota não altera contratos, decisões de aceite nem resultados intermediários registrados.

---

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-08`)
> **Tipo:** Documento técnico
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

A1 permanece aceito e A8 foi aprovado e aceito em 11/09/2026; a execução da migration pertence à implementação.
As relações reserva/passageiro e um evento por saída foram confirmadas por Vaner em 10/09/2026.
As demais decisões são propostas para revisão conjunta com BT-DOC-02 a BT-DOC-08.

## 1. Proposta de decisão

Delta aditivo necessário, no schema `public`, mantendo autoridades existentes.
[ADR-020](architecture/ADR-020-BIKE-TOUR-DOCUMENTARY-DESIGN.md) registra alternativas e impacto.
Não criar schema `biketour`, tabelas paralelas de pessoa/produto/reserva nem modificar migrations já aplicadas.

Os nomes abaixo são desenho documental, não objetos criados. PK de cada tabela = `id_<nome_da_tabela>`.
Na API e na matriz resumida, IDs curtos são aliases. No banco, as FKs para tabelas novas usam o nome completo:
`id_evento_bike_tour`, `id_inscricao_bike_tour`, `id_recurso_bike_tour`, `id_ponto_controle_bike_tour`
e `id_operacao_bike_tour`. As referências legadas mantêm os nomes do domínio de origem.

## 2. Objetos propostos e dados

| Tabela public | Campos de negócio e FKs | Regras centrais |
| --- | --- | --- |
| produto_bike_tour | id_produto → produto_turistico; distancia_km NUMERIC(10,2); desnivel_m NUMERIC(10,2); nivel; ativo | UNIQUE id_produto; distância >0, desnível >=0; tipo CICLOTURISMO validado por porta |
| evento_bike_tour | id_saida → saida_turistica; inicio/fim TIMESTAMPTZ; capacidade INTEGER; status; versao | UNIQUE id_saida; 1..1000 participantes; inicio < fim; período dentro da saída por porta |
| recurso_bike_tour | codigo VARCHAR(30); tipo; status; id_ativo/id_guia/id_transporte opcionais | Código único; tipo BICICLETA/EQUIPAMENTO/GUIA/VEICULO; referência única quando preenchida |
| inscricao_bike_tour | id_evento → evento_bike_tour; id_reserva → reserva; id_passageiro → passageiro; papel; status | UNIQUE evento/passageiro; mesma linha reutilizada em rebloqueio elegível; vínculo reserva/passageiro/saída validado pela porta |
| alocacao_recurso_bike_tour | id_evento; id_inscricao opcional; id_recurso; inicio/fim; expira_em; status | FKs explícitas; intervalo positivo; exclusão temporal; inscrição deve pertencer ao evento |
| equipe_bike_tour | id_evento; id_recurso → recurso_bike_tour; papel LIDER/APOIO | Recurso GUIA; UNIQUE evento/recurso; um líder por evento |
| logistica_bike_tour | id_evento; id_recurso; finalidade TRANSPORTE/APOIO/MATERIAL | UNIQUE evento/recurso; recurso VEICULO/EQUIPAMENTO; alocação de apoio obrigatória |
| ponto_controle_bike_tour | id_evento; ordem INTEGER; id_localidade → localidade; distancia_km | UNIQUE evento/ordem; ordem >0; distância >=0 e crescente por service |
| passagem_bike_tour | id_inscricao; id_ponto → ponto_controle_bike_tour; instante TIMESTAMPTZ | UNIQUE inscrição/ponto; mesmo evento e ordem por service |
| ocorrencia_bike_tour | id_evento; id_inscricao opcional; tipo; gravidade; status; motivo enumerado | Mesmo evento; códigos enumerados; sem texto livre ou dados clínicos |
| avaliacao_bike_tour | id_inscricao; nota SMALLINT | UNIQUE inscrição; nota 1..5; somente inscrição concluída |
| operacao_bike_tour | id_usuario → usuario; operacao; alvo INTEGER; chave_hash; payload_hash; http_status; resultado JSONB | UNIQUE ator/operação/alvo/chave_hash; hash 64 caracteres; resultado mínimo sem PII |
| pendencia_bike_tour | id_evento; id_inscricao opcional; id_operacao; tipo; status; referencia_tratamento VARCHAR(100) | UNIQUE operação/tipo/inscrição; vínculo verificável; sem valor monetário |

`id_ativo` referencia a PK real de `ativo_imobilizado`, `id_guia` a de `guia_turistico` e `id_transporte` a de
`transporte`, mantendo nomes legados das PKs no alvo da FK. Recurso GUIA exige id_guia; VEICULO exige id_transporte.
BICICLETA/EQUIPAMENTO pode referenciar patrimônio, ou ser recurso próprio da operação sem identidade duplicada.
CHECK impede mistura de referências incompatíveis. Todas as colunas de referência acima são FKs reais, não texto.
`alvo` de operação é escopo de idempotência polimórfico, não FK; associações concretas ficam nos resultados/pendências.

## 3. Constraints, índices e exclusão

Aplicar nomes `pk_<tabela>`, `fk_<tabela>_<referenciada>`, `ck_<tabela>_<regra>` e `idx_<tabela>_<colunas>`.
Declarar explicitamente UNIQUEs e índices parciais quando necessário, sem depender de unicidade com NULL.
Para pendência sem inscrição, índice único parcial em operação/tipo; para inscrição presente, incluir inscrição.

Exclusão proposta em alocação: recurso com igualdade e `tstzrange(inicio, fim, '[)')` com sobreposição,
aplicada a status BLOQUEADA/CONFIRMADA. Requer `btree_gist`; disponibilidade local foi consultada, não instalada.
CHECK exige expira_em para BLOQUEADA e a ausência de expiração aplicável para CONFIRMADA.
Cleanup marca EXPIRADA antes de nova alocação. Não incluir `now()` em predicado de índice.

Índices adicionais: inscrição(evento,status), inscrição(reserva), alocação(evento,status,expira_em),
alocação(inscrição), ocorrência(evento,status,gravidade), ponto(evento,ordem), pendência(status,evento),
operação(ator,operação,alvo,chave_hash), e FKs restantes usadas para exclusão/consulta.
UNIQUEs já cobertos por índice não recebem índice duplicado.

Estados da matriz funcional são CHECKs nomeados; status não é texto livre. Coerência entre inscrição/alocação
usa constraint trigger diferido no commit, limitado a objetos novos, validando inscrições ativas e alocações próprias.
A ausência de bicicleta é válida apenas para inscrições terminais; confirmação exige exatamente uma bicicleta ativa.
A capacidade agregada e validação de origem permanecem regras transacionais testadas, não CHECK entre tabelas.
Para capacidade operacional contam somente PENDENTE com bloqueio válido, CONFIRMADA e PRESENTE.
CONCLUIDA, CANCELADA, EXPIRADA e NO_SHOW não contam e não mantêm alocações ativas.

## 4. Auditoria e proteção da baseline

Todas as tabelas novas seguem colunas de auditoria de DATABASE_STANDARDS.md, incluindo versao e timestamps.
Instanciar triggers updated_at e auditoria; COMMENT ON em tabelas e colunas. IDs são inteiros com identidade,
sem reutilização de códigos após exclusão lógica. Recurso com histórico não sofre exclusão física via API.

Nenhuma migration antiga, dump, tag certificada ou tabela de domínio de origem é alterada retroativamente.
A porta de leitura de passageiro pode mapear a tabela existente em Turismo; isso não cria passageiro Bike Tour.
O desenho não persiste preços ou títulos. Se surgir campo monetário, usar NUMERIC(15,2) e novo aceite de escopo.

## 5. Plano da migration futura

1. Confirmar head único e dependências no momento de implementação; hoje a revisão observada é `202609080100`.
2. Verificar FKs alvo, funções de auditoria e permissões para `btree_gist`; abortar se faltar pré-requisito.
3. Criar extensão se necessário, somente sob autorização da migration aprovada; registrar se já existia.
4. Criar tabelas novas, constraints, índices, triggers, comentários e permissões RBAC explícitas para ADMIN.
5. Validar catálogo, constraints e instalação sobre baseline restaurada em banco local descartável.
6. Executar upgrade → downgrade da nova revisão → upgrade, conferindo head e comportamento.

Downgrade exige parada da aplicação e backup dos fatos novos; remove somente objetos/permissões introduzidos.
Não remover extensão compartilhada nem suas dependências preexistentes. Nenhuma remoção de dados de Turismo.
O número da migration será alocado na implementação para evitar colisão; não há arquivo SQL ou Alembic nesta revisão.

## 6. Aceite

Aceitar A8 aprova esse plano e o delta proposto; não declara migration executada.
Aprovação depende de coerência com A2–A7 e da ADR proposta; testes físicos e CI são gates da entrega posterior.

## 7. Incremento operacional 202609130500

Em 13/09/2026, Vaner autorizou a implementação do detalhamento apresentado no diagnóstico da Fase A.
A revisão `202609130500`, sucessora de `202609130400`, implementa somente equipe, logística, pontos,
passagens, ocorrências e avaliações. `operacao_bike_tour` e `pendencia_bike_tour` ficam para revisão posterior.
O agrupamento preserva a decisão aditiva deste A8 e não certifica a conclusão funcional da Etapa 2.7.

### 7.1 Contrato físico do incremento

Todas as tabelas pertencem a `public`. PKs são `INTEGER GENERATED BY DEFAULT AS IDENTITY`, com nome
`id_<tabela>` e constraint `pk_<tabela>`. Referências usam os nomes completos das tabelas Bike Tour.
FKs não propagam exclusão física. Todos os campos de negócio são obrigatórios, exceto a inscrição da ocorrência.

| Tabela | Campos de negócio | Unicidade e verificações |
| --- | --- | --- |
| equipe_bike_tour | id_evento_bike_tour; id_recurso_bike_tour; papel VARCHAR(20) | Evento/recurso único; papel LIDER/APOIO; líder único entre linhas não excluídas do evento |
| logistica_bike_tour | id_evento_bike_tour; id_recurso_bike_tour; finalidade VARCHAR(20) | Evento/recurso único; finalidade TRANSPORTE/APOIO/MATERIAL |
| ponto_controle_bike_tour | id_evento_bike_tour; ordem INTEGER; id_localidade; distancia_km NUMERIC(10,2) | Evento/ordem único; ordem >0; distância >=0 |
| passagem_bike_tour | id_inscricao_bike_tour; id_ponto_controle_bike_tour; instante TIMESTAMPTZ | Inscrição/ponto único; instante obrigatório |
| ocorrencia_bike_tour | id_evento_bike_tour; id_inscricao_bike_tour opcional; tipo/gravidade/status VARCHAR(20); motivo VARCHAR(30) | Enums de A2/A3; status inicial ABERTA; motivo obrigatório; sem unicidade artificial de ocorrência |
| avaliacao_bike_tour | id_inscricao_bike_tour; nota SMALLINT | Inscrição única; nota 1..5; sem comentário |

Os enums de ocorrência são fechados por CHECKs:

- tipo: ATRASO, MECANICA, INTERRUPCAO, OUTRA;
- gravidade: BAIXA, MEDIA, ALTA;
- status: ABERTA, EM_ANALISE, RESOLVIDA, DESCARTADA;
- motivo: SOLICITACAO, CLIMA, RECURSO_INDISPONIVEL, ORIGEM_INVALIDA, OPERACIONAL, TRATAMENTO_CONCLUIDO.

Unicidades de negócio permanecem após exclusão lógica. O índice único de líder usa
`papel = 'LIDER' AND deleted_at IS NULL`, permitindo substituição com preservação da linha anterior.
Reutilizar o mesmo par evento/recurso requer atualizar a linha existente, sem criar outra identidade.
Não há coluna `id_alocacao` em equipe/logística: o vínculo temporal continua na alocação existente.

Índices cobrem as FKs não atendidas pelo prefixo de UNIQUEs. Ocorrência possui índice por evento/status/gravidade.
Não são criados índices redundantes sobre os mesmos conjuntos de colunas já cobertos por UNIQUE.

Auditoria reutiliza o padrão existente: `created_at` obrigatório com default `CURRENT_TIMESTAMP`,
`updated_at` e `deleted_at` opcionais, todos com fuso; atores opcionais `VARCHAR(100)`;
`versao INTEGER NOT NULL DEFAULT 1`, com CHECK `versao >= 1`.
Cada tabela instancia triggers de atualização e auditoria associados às funções corporativas existentes.
Tabelas e todas as colunas recebem comentários. Nenhuma função compartilhada é substituída.

### 7.2 Limites da entrega e regras dos serviços

A migration garante PKs, FKs, unicidades, enums, limites escalares, versão e auditoria.
As seguintes regras continuam obrigatórias na camada transacional posterior, sem serem certificadas pela 130500:

- equipe usa recurso GUIA válido e alocado; logística usa VEICULO/EQUIPAMENTO com alocação de apoio;
- abertura exige líder, veículo de apoio e rota mínima; substituições preservam alocações e histórico;
- distâncias e passagens crescem em ordem; inscrição e ponto pertencem ao mesmo evento;
- passagem exige presença, evento em execução e instante elegível;
- ocorrência vinculada à inscrição pertence ao mesmo evento; transições seguem A2;
- avaliação exige inscrição concluída;
- comandos usam autorização, lock global, idempotência e transação única conforme A3-A6.

`localidade.id_localidade` é reutilizada diretamente. Equipe referencia guia pelo recurso, sem criar colaborador
ou copiar identidade. `avaliacao_pos_viagem` permanece vinculada à reserva; não é copiada nem modificada.

### 7.3 Divergências anteriores registradas no diagnóstico

O catálogo local em 130400 e os models existentes divergem do gate em pontos ainda não corrigidos neste incremento:

- nível implementado FACIL/MODERADO/DIFICIL/AVANCADO versus INICIANTE/INTERMEDIARIO/AVANCADO de A2;
- evento usa EM_ANDAMENTO versus EM_EXECUCAO de A2;
- disponibilidade usa DISPONIVEL/INDISPONIVEL versus ATIVO de A2;
- papel da inscrição usa CICLISTA versus PARTICIPANTE de A2;
- recurso possui FKs, mas ainda não possui as unicidades de origem e compatibilidade por tipo exigidas em A8;
- algumas CHECKs anteriores possuem prefixo duplicado pela convenção do metadata;
- projeções Turismo ainda não cobrem integralmente as projeções de A4;
- models Bike Tour ainda não integram o registro central Alembic, com referências legadas por resolver.

Naquele incremento, as permissões inicialmente registradas eram `BIKETOUR_VISUALIZAR`, `BIKETOUR_OPERAR` e `BIKETOUR_GERENCIAR`.
A revisão `202609170100` posteriormente estabeleceu como contrato canônico `BIKE_TOUR_VISUALIZAR`,
`BIKE_TOUR_OPERAR` e `BIKE_TOUR_GERENCIAR`.
Os identificadores `BIKETOUR_*` permanecem aceitos internamente apenas como aliases de compatibilidade histórica.
Código novo, endpoints, documentação normativa e novos testes devem utilizar exclusivamente o vocabulário canônico `BIKE_TOUR_*`.
Nenhuma dessas divergências autoriza reescrever migrations anteriores ou reduzir a regressão C01-C09.

### 7.4 Validação e reversibilidade

O ambiente de execução é o Python do virtualenv existente em `Backend/.venv` e PostgreSQL local descartável.
O banco restaurado de migrations é `wma_phase2_test`; não usar nele fixtures genéricas que executam
`Base.metadata.drop_all()`. Testes ORM de outros domínios exigem outro banco descartável.
As URLs são fornecidas ao processo, sem persistência em arquivos ou exposição de credenciais.

O ciclo Alembic 130400 → 130500 → 130400 → 130500 foi executado no PostgreSQL 18.4.
O downgrade preservou o catálogo anterior e as contagens das tabelas de `public`;
o re-upgrade reproduziu o catálogo da 130500 com as seis tabelas vazias.
O teste permanente de reversibilidade executa o DDL em transação revertida, preservando a revisão do banco.
Downgrade operacional exige aplicação parada e backup dos fatos novos; remove somente as seis tabelas do delta.

Testes adicionados:

- `Backend/tests/test_biketour_operations_models.py`;
- `Backend/tests/test_biketour_operations_migration.py`;
- `Backend/tests/integration/test_biketour_operations_postgresql.py`.

O teste PostgreSQL C01-C09 mantém as assertivas e passa a exigir head 130500.
Hashes das quatro migrations anteriores são verificados com normalização apenas de EOL para checkout multiplataforma.
A validação física cobre catálogo, constraints, comentários, triggers, auditoria, versão, soft delete e rollback.

## 8. Gate físico 2.47F-C da revisão 202609130600

A revisão 130600 trata exclusivamente a origem de `recurso_bike_tour`, sucedendo a 130500.
`operacao_bike_tour` e `pendencia_bike_tour` permanecem para a futura 130700, não iniciada neste gate.
Este incremento resolve a lacuna de unicidade e compatibilidade de origem registrada no diagnóstico da seção 7.3.
As demais divergências anteriores e as camadas funcionais pendentes continuam fora desta certificação física.

### 8.1 Contrato e correção autorizada

- BICICLETA/EQUIPAMENTO: patrimônio opcional; guia e transporte ausentes;
- GUIA: guia obrigatório; patrimônio e transporte ausentes;
- VEICULO: transporte obrigatório; patrimônio e guia ausentes;
- UNIQUEs históricos em `id_ativo`, `id_guia` e `id_transporte`, inclusive após exclusão lógica;
- múltiplos NULLs continuam permitidos; não há índice parcial por `deleted_at`;
- a classificação externa do patrimônio não é validada por CHECK SQL.

Antes do upgrade, a compilação PostgreSQL mostrou que a convenção Alembic duplicava o prefixo e truncava
o nome da CHECK nova. Vaner autorizou corrigir o defeito e alterar o hash congelado da 130600.
A alteração da migration limita-se a `op.f()` no nome da CHECK em upgrade e downgrade.
Nenhuma migration 130100-130500 foi modificada neste gate.

Hash SHA-256 normalizado anterior da 130600:
`85fdd959ee59466d90bd106e6921caf85ce0b6fab96dbab912c996f4f96fa6c3`.

Hash SHA-256 normalizado após a correção autorizada:
`70e5a98bd1b18afb0b9b43dd03346e760e7a0b0674296fa5b0684ff295c6fcac`.

A normalização usada no cálculo substitui somente CRLF por LF.
A CHECK histórica permanece com o nome físico encontrado no banco restaurado:
`ck_recurso_bike_tour_ck_recurso_bike_tour_origem_unica`.
Ela não foi renomeada, removida ou substituída. A suíte confirma sua expressão e seu estado validado.

### 8.2 Ambiente e fixtures

Banco local descartável: `wma_phase2_test`, PostgreSQL 18.4, role proprietária `wma_phase2_app`.
A role `wma_test` conectava, mas não possuía permissões nas tabelas locais.
O responsável autorizou usar a role proprietária somente no banco descartável.
As variáveis de conexão foram definidas apenas no processo; `.env` e permissões permaneceram intactos.
O interpretador utilizado foi `Backend/.venv/Scripts/python.exe`.

Foi corrigida a fixture que iniciava `conn.begin()` após SELECTs já sujeitos a transação implícita.
A transação de diagnóstico termina antes da transação de teste, que usa READ COMMITTED, lock global e rollback.
O catálogo e o dump confirmaram os campos obrigatórios e a FK patrimonial para `categoria_ativo`.
Como `ativo_imobilizado` estava vazio, a fixture cria categoria e patrimônio sintéticos na mesma transação.
Não consulta dados pessoais e não depende de registros patrimoniais preexistentes.
O rollback verifica as contagens de recurso, guia, transporte, ativo, categoria e auditoria.

### 8.3 Evidência do ciclo físico

O banco e o sufixo `_test` foram reconfirmados antes de cada upgrade/downgrade.
Foram executadas as operações Alembic `upgrade`, `downgrade`, `current` e `heads` com a conexão protegida.

| Passo | Resultado observado |
| --- | --- |
| Inicial em 130500 | Quatro constraints da 130600 ausentes; constraint histórica presente |
| Upgrade 130600 | Três UNIQUEs e CHECK com nomes exatos; constraints anteriores preservadas |
| Suíte PostgreSQL 130600 | 16 passed, 0 skipped, 0 failed; SQLSTATE 23505 e 23514 validados |
| Regressão PostgreSQL 130400/130500/130600 | 67 passed, 0 skipped, 0 failed |
| Rollback das fixtures | Zero resíduos `pytest-bt600` nas cinco tabelas e na auditoria |
| Downgrade 130500 | Catálogo anterior e contagens de todas as tabelas de public restaurados |
| Comportamento após downgrade | GUIA sem origem aceito novamente em transação revertida |
| Re-upgrade 130600 | Catálogo reproduzido, contagens preservadas e zero resíduos |
| Estado final | current == heads == 202609130600 |

Comando da suíte física, executado em `Backend/` após configurar a conexão no processo:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/integration/test_biketour_resource_hardening_postgresql.py --run-postgresql -q --no-cov -W error
```

O teste estrutural passou com 8 testes, incluindo compilação do DDL sob a convenção real do metadata.
Após o ciclo físico, os testes PostgreSQL 130400/130500 foram atualizados somente na revisão esperada para 130600.
Essa atualização não modifica as regras ou as assertivas de integridade e reversibilidade dessas camadas.

A regressão consolidada foi executada em `Backend/`, mantendo a mesma conexão descartável no processo:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/integration/test_biketour_postgresql.py tests/integration/test_biketour_operations_postgresql.py tests/integration/test_biketour_resource_hardening_postgresql.py --run-postgresql -q --no-cov -W error -x
```

O ciclo físico e a regressão consolidada do gate 2.47F-C estão aprovados. Isso não certifica a Etapa 2.7 completa.

### 8.4 Gate geral e pendência encontrada em 13/09/2026

Ruff de `app/tests` e da migration corrigida passou; Mypy passou para `app`, `tests` e a migration.
O teste geral com cobertura foi executado adicionalmente, sem habilitar as fixtures PostgreSQL genéricas:

```powershell
.\.venv\Scripts\python.exe -m pytest -q -W error --cov=app --cov-report=term-missing
```

Resultado: 494 passed, 93 skipped e 1 failed; cobertura 99,04%, abaixo do limite obrigatório de 100%.
Os skips são testes PostgreSQL sem opt-in nesse comando; os 67 testes Bike Tour foram executados separadamente
com PostgreSQL real, conforme seção 8.3. Não foi usado SQLite como substituição.

A falha foi `test_core_models_register_only_the_inventory_authorities`, em `Backend/tests/test_core_models.py`:
o filtro de domínios do teste não contempla as tabelas Bike Tour e `passageiro_reserva` presentes no metadata global.
As 30 linhas sem cobertura estão em repositories/services de Turismo e em `app/shared/turismo.py`.
A correção dessa divergência geral não foi executada; nenhuma assertiva ou meta de cobertura foi reduzida.
O gate físico 2.47F-C está aprovado, mas o gate geral permanece bloqueado até tratar essas pendências.

### 8.5 Revisão dos gates em 14/09/2026

O inventário do teste Core passou a distinguir explicitamente as onze tabelas Bike Tour e o passageiro de Turismo.
Foram mantidas as assertivas de colunas, nulabilidade, schemas e registro das autoridades corporativas.
Os testes da fronteira agora exercitam consultas, bloqueios, projeções imutáveis, origens ausentes,
versão inválida e serviços de passageiros, sem banco substituto e sem controle transacional pela porta.

A primeira execução geral desta revisão teve 510 passed e uma falha no teste da configuração do CI,
com 100% de cobertura de `app` (3.128 instruções, nenhuma sem cobertura).
O teste ainda exigia o comando único anterior de PostgreSQL. Foi atualizado para verificar a separação
dos recortes ORM e da baseline migrada, a ordem de restauração/migrations e a inclusão de toda a integração.
A validação focada da configuração resultou em 6 passed.

A execução integral após a correção terminou com 512 passed, zero skips e zero falhas,
mantendo 100% de cobertura. Comando executado em `Backend/`:

```powershell
.\.venv\Scripts\python.exe -m pytest -q -W error --ignore=tests/integration --cov=app --cov-report=term-missing -x
```

As duas execuções PostgreSQL abaixo somam outros 93 testes aprovados, totalizando 605 testes distintos.
Alembic `current` e `heads` foram reconfirmados em `202609130600`.
O workflow foi validado localmente; ainda não houve execução deste conjunto no GitHub Actions.

O workflow mantém cobertura obrigatória de 100% nos testes rápidos. Os testes ORM usam `wma_orm_test`;
os testes Bike Tour usam `wma_phase2_test` somente após restauração e ciclo da última migration.
Não se executa `metadata.drop_all/create_all` sobre a baseline Bike Tour.

Evidências locais adicionais:

- PostgreSQL ORM: 26 passed, sem skips, no banco novo `wma_biketour_orm_20260914_test`;
- catálogo final desse banco sem tabelas em `public` e `financeiro`;
- PostgreSQL Bike Tour: 67 passed, sem skips, em `wma_phase2_test`;
- zero registros `pytest-bt600` em recurso, guia, transporte, patrimônio e categoria patrimonial;
- Ruff check, Mypy de app/tests/scripts e dependências aprovados; OpenAPI sincronizado;
- hashes 130100–130600 preservados conforme a seção 8.1 e os registros anteriores.

O gate de formatação identificou BOM inicial e duas chamadas RuntimeError com quebra desnecessária na 130600.
O arquivo congelado foi preservado até a autorização específica registrada na seção 8.6.
Os ajustes de fim de linha ficaram restritos aos testes alterados, sem normalização em massa.
A revisão não executou commit, push ou merge e não iniciou a 130700.
A certificação completa da Etapa 2.7 continua pendente das camadas funcionais documentadas em A2–A8.

### 8.6 Formatação autorizada da 130600 em 14/09/2026

Vaner autorizou remover o BOM e compactar duas chamadas RuntimeError, sem modificar SQL.
O hash normalizado anterior era `70e5a98bd1b18afb0b9b43dd03346e760e7a0b0674296fa5b0684ff295c6fcac`.
O novo hash SHA-256, normalizando somente CRLF para LF, é:

`062ebf4508d893681e4282dc19becff2c872beee959717497181f5cac08ba331`.

A comparação antes/depois confirmou AST idêntica, desconsiderando posições no arquivo.
O SQL de upgrade e downgrade compilado pelo Alembic para PostgreSQL também permaneceu idêntico.
Ruff check passou e o gate de formatação confirmou os 132 arquivos conformes.
Mypy da migration passou; os 8 testes estruturais e os 16 testes PostgreSQL da 130600 foram reexecutados
e passaram sem skips. Alembic current e heads permaneceram em `202609130600`.
Essa alteração não introduz mudança funcional nem substitui a certificação física da seção 8.3.

## 9. Infraestrutura 202609130700

A solicitação de conclusão funcional de 14/09/2026 autoriza o próximo incremento após a certificação da 130600.
A revisão 130700 fica restrita a `operacao_bike_tour` e `pendencia_bike_tour`, seus índices, checks e auditoria.
Reutiliza `usuario`, `evento_bike_tour` e `inscricao_bike_tour`; não cria identidade ou integração financeira paralela.

Detalhamento físico de A4–A6/A8 para este incremento:

- operação: ator obrigatório, operação VARCHAR(50), alvo inteiro não negativo, hashes SHA-256 hexadecimais,
  status HTTP de sucesso, resultado JSONB objeto/lista e correlation_id UUID da infraestrutura existente;
- unicidade histórica por ator/operação/alvo/hash da chave, inclusive após exclusão lógica;
- pendência: evento obrigatório, inscrição opcional, operação obrigatória e motivo enumerado de A3;
- tipos de pendência CANCELAMENTO, NO_SHOW e ENCERRAMENTO, derivados dos fatos previstos em A4;
  reconciliação produz CANCELAMENTO com motivo ORIGEM_INVALIDA;
- estados ABERTA/TRATADA; referência de tratamento obrigatória somente em TRATADA;
- dois índices únicos parciais de intenção distinguem inscrição presente e ausente, sem filtrar deleted_at;
- timestamps com fuso, versão positiva, comentários e os triggers corporativos de auditoria nas duas tabelas.

O resultado persistido não contém a chave original, payload original, token, PII ou texto clínico.
Não há expurgo automático; replay consulta também operações excluídas logicamente para não reutilizar uma chave.
Coerência do evento da pendência com a inscrição e operação será validada pelo caso de uso na mesma transação.
Downgrade remove primeiro pendências e depois operações; não modifica as revisões congeladas 130100–130600.

### 9.1 Certificação física em 15/09/2026

Banco local `wma_phase2_test`, PostgreSQL 18.4, role `wma_phase2_app` e revisão inicial 130600.
O primeiro upgrade revelou dependência de importação no tipo ORM de id_usuario; a declaração explícita
de Integer resolveu o problema, sem alterar a migration nem as autoridades de origem.

O ciclo persistente 130600 → 130700 → 130600 → 130700 foi concluído, reconfirmando `_test` antes de cada passo.
Catálogo e contagens foram comparados; o downgrade removeu somente o delta e o re-upgrade reproduziu o catálogo.
As fixtures conferem rollback de todas as tabelas de public, incluindo auditoria, e não deixaram resíduos.

- suíte física da 130700: 32 passed, sem skips, incluindo SQLSTATE 23502/23503/23505/23514;
- regressão PostgreSQL Bike Tour 130400–130700: 99 passed, sem skips;
- suíte geral sem integração: 524 passed, 100% de cobertura de app (3.154 instruções);
- Ruff check aprovado; 135 arquivos conformes no Ruff Format; Mypy aprovado em 120 arquivos;
- Alembic current == heads == 202609130700;
- hashes 130100–130600 preservados e verificados pelos testes permanentes.

Hash SHA-256 normalizado da 130700:
`36c917031c4ef547754c5edc250915aaeddc846389ca47a0b1eea59fbcb01c97`.

As suítes anteriores mudaram somente a revisão esperada para 130700, preservando suas invariantes.
Este gate certifica a infraestrutura física; replay, UoW, serviços, API e concorrência funcional continuam pendentes.

### 9.2 Referências ORM das autoridades legadas

A gravação real de recurso via ORM revelou `NoReferencedTableError`: as FKs de patrimônio, guia e transporte
apontavam para tabelas sem mapeamento no metadata do backend. As três PKs verificadas são descritas em
`app/db/legacy_references.py`, com metadata separado e sem criação de tabelas ou novo modelo de domínio.
As FKs conservam nomes e destinos físicos; as migrations permanecem inalteradas.
O teste PostgreSQL grava e relê uma bicicleta pela Session e verifica rollback integral da fixture.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-08, versão 1.1 |
| Última atualização | 10/09/2026 |
| Aceite | Vaner, 11/09/2026; decisão aditiva de schema aprovada |
| Implementação | Decisão aceita; migration será criada e validada durante a implementação |

<!-- cspell:ignore CONCLUIDO EXECUCAO MANUTENCAO DISPONIVEL inscricao inscricoes ocorrencia ocorrencias -->
<!-- cspell:ignore logistica alocacao alocacoes correlacao reacomodacao reconciliacao permissao -->
<!-- cspell:ignore idempotencia versao obrigatorio disponivel btree gist tstzrange GiST gist idempotente -->
<!-- cspell:ignore payloads timestamp timestamptz -->

<!-- cspell:ignore desnivel LIDER -->
<!-- cspell:ignore rebloqueio -->
<!-- cspell:ignore CONCLUIDA -->
<!-- cspell:ignore INTERRUPCAO INDISPONIVEL FACIL DIFICIL AVANCADO virtualenv bt600 unica -->
