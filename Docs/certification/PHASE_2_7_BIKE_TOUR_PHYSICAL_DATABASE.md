# Bike Tour — análise de reutilização física B07

## Estado da verificação

Data: 27/09/2026. Branch: `feature/2.7-bike-tour`.
HEAD: `ba45b3c1c544a05a6ed317445f31ba737c497919`.

`B07_PHYSICAL_DATABASE_CERTIFICATION=BLOCKED`.
`B07_REBUILD_REQUIRED=UNDETERMINED`.

Não foi comprovada mudança física posterior a T24. Também não foi comprovada a identidade completa
dos arquivos de migration atuais com os usados naquela execução. Não se repetiu reconstrução com base
apenas nessa incerteza. Nenhum banco foi acessado nesta análise.

## Evidência física histórica preservada

Fonte: [B05, seção 7](PHASE_2_7_BIKE_TOUR_TEST_EVIDENCE.md), confirmada pelo responsável na solicitação.
Banco da execução de 26/09/2026: `wma_phase2_t24_20260926_184756_test`.

| Verificação histórica | Resultado certificado |
| --- | --- |
| Reconstrução | PASS |
| Paridade | 1016 objetos |
| ONLY_TARGET | 0 |
| ONLY_REFERENCE | 0 |
| Alembic head | 202609170300 |
| Downgrade | 202609170300 para 202609170200 |
| Reupgrade | 202609170200 para 202609170300 |
| Inventário preservado | Sim |
| Bancos protegidos preservados | Sim |

SHA-256 certificado de `Database/install.sh`, confirmado nesta execução:

```text
40D7AA9E6C102A93082750B6CB807FC9904301BAA6DDA033BC401C7CB4D73055
```

SHA-256 do documento B05, confirmado antes de qualquer alteração:

```text
14E266B0AE98EA41E09B594ED47D3DC33E1B4D73AC906FAE349627AC35E712CE
```

Esta análise não supersede nem invalida o resultado histórico de T24.
Ela mantém aberta a demonstração de aplicabilidade ao conjunto atual.

## Verificação atual e limite da prova

- `python -m alembic heads`: head único `202609170300`.
- As dez migrations Bike Tour atuais estão sem rastreamento no Git. O HEAD, isoladamente, não fixa seu conteúdo.
- A cadeia declarada segue 130100, 130200, 130300, 130400, 130500, 130600, 130700, 170100, 170200 e 170300,
  todos com prefixo de data `202609`.
- Os testes existentes congelam hashes normalizados das seis primeiras revisões.
  A seção 9.1 da decisão de schema registra também o hash normalizado da 130700.
- As datas locais de última escrita das migrations precedem T24, mas não são prova de identidade de conteúdo.
- B05 registra o hash do instalador, mas não um manifesto de hashes das migrations usadas em T24.
  Não foi localizado manifesto contemporâneo, fora de backups, que cubra as revisões 170100, 170200 e 170300.
- `git diff --name-only -- Database Backend/migrations` mostra apenas o instalador já modificado antes
  desta execução. Seu hash coincide com o certificado. Nenhuma alteração rastreada da baseline foi observada.
- B06 não introduziu migration. Nenhuma migration foi editada durante esta análise.

Não se pode converter ausência de diff de arquivos sem rastreamento em prova de preservação pós-T24.
Também não se pode declarar que uma migration mudou apenas porque seu manifesto histórico está ausente.
Por isso a necessidade de reconstrução permanece indeterminada, sem declarar YES ou NO sem suporte.

## Condição de fechamento

Recuperar evidência contemporânea de T24 que identifique o conteúdo das migrations, principalmente
170100, 170200 e 170300, e compará-la ao conjunto atual. Se a identidade for demonstrada e B06 não exigir
migration, reutilizar formalmente T24 e fechar B07 sem reconstrução.

Se houver alteração relevante confirmada, realizar nova certificação em outro banco descartável explicitamente
nomeado, incluindo paridade, downgrade e reupgrade. Nunca utilizar `wma_travel`.
Uma eventual migration de B06 exige nova reconstrução conforme a regra da solicitação.

## Complemento físico de 28/09/2026

Este complemento supersede o estado indeterminado da análise anterior para fins de aplicabilidade estrutural.
O resultado histórico T24 e seus 1016 objetos permanecem preservados.
Nenhum rebuild, upgrade ou downgrade foi repetido nesta execução.

### Verificação independente do catálogo

Foram acessados somente os bancos locais `wma_phase2_t24_20260926_184756_test` e `wma_phase2_test`.
Ambos apresentaram head `202609170300`.
O inventário atual possui 249 tabelas, 241 sequências, 488 índices e 38 views: 1016 objetos.

O DDL completo foi obtido com `pg_dump --schema-only --no-owner --no-privileges`, sem exportar dados.
A comparação em memória removeu somente as linhas aleatórias de restrição do próprio pg_dump.
Nenhum dump foi adicionado ao repositório.

SHA-256 idêntico nos dois bancos:

```text
e2200fce2e36883b4572c7278dc11acbe86921d2f95bb37037c694464e4b6d32
```

Diferenças de linhas: zero em ambas as direções. A comparação inclui constraints, funções,
triggers, comentários, colunas, índices e views, além do inventário de objetos.
O total de 2440 entradas no DDL inclui comentários e subobjetos; não substitui a métrica histórica de 1016 objetos.

### Migrations e instalação

Não houve alteração de migration, cadeia, head, baseline ou instalador nesta execução B06/B07.
B06 reutiliza tabelas e UoW existentes, sem delta físico.
O hash do instalador continua exatamente igual ao certificado na seção histórica.

Os 21 testes de operations/idempotency migration passaram, incluindo as verificações de hashes congelados.
A revisão 130700 coincide também com o hash publicado em A8.
As datas locais das dez migrations precedem T24; esse dado é corroborativo, não prova isolada.

As três revisões finais foram inspecionadas contra o banco T24:

- 170100: as três permissões canônicas existem com concessão explícita ao ADMIN;
- 170200: constraint do evento contém PLANEJADO, ABERTO, EM_EXECUCAO, CONCLUIDO e CANCELADO;
- 170300: constraint de nível contém INICIANTE, INTERMEDIARIO e AVANCADO.

Manifesto atual, normalizando exclusivamente CRLF para LF:

| Revisão | SHA-256 |
| --- | --- |
| 202609130100 | 17ea083821e3e97ce8af0e30e9ef23b1f4274e6ecbf2f6850bf358cc2e6eb7e0 |
| 202609130200 | 15766127590e950663a32db1d49b50fee7de8df1e404adb2f721d20bc4957cfd |
| 202609130300 | 3949abe1a058e3f63605b5f9de11da3b6851318e6e4a70819f38196d30f96f19 |
| 202609130400 | 51bb855d8ffb4d1c2cf119bdf364193dbe1b6489fc51216bdb93dc11c4fc9119 |
| 202609130500 | 221ea91b8de2513cff0a0000196c07e42bbe0119543941035c909be7a1fc83fc |
| 202609130600 | 062ebf4508d893681e4282dc19becff2c872beee959717497181f5cac08ba331 |
| 202609130700 | 36c917031c4ef547754c5edc250915aaeddc846389ca47a0b1eea59fbcb01c97 |
| 202609170100 | 8f9154e4952dd38fca447bc7b84c85af3722765fa67736593ad7a2c8b94ed72f |
| 202609170200 | 021c6891397ece489efa3afbd1a217bb1d4ba23bafa2da27afc60b6b5d220161 |
| 202609170300 | a423565a130c15109e97f9659181f49ca43cf66bc1b3a8e513d39b537edb4b4a |

Este manifesto é atual. Não é apresentado como manifesto capturado durante T24.
A prova nova estabelece equivalência estrutural com o banco certificado, não identidade histórica byte a byte
dos arquivos que não possuíam manifesto contemporâneo. Nenhuma mudança física relevante foi identificada.
Essa distinção preserva a limitação histórica registrada acima, sem inventar evidência retrospectiva.

### Decisão de reutilização

`B07_REBUILD_REQUIRED=NO`.

A certificação histórica de reconstrução, downgrade e reupgrade é reutilizada com a verificação estrutural atual.
O banco certificado foi consultado somente para leitura. Auditoria e inventário não sofreram mutação.
Nenhuma conexão foi feita com `wma_travel`.

<!-- cspell:ignore CONCLUIDO AVANCADO -->

## Fechamento contemporâneo B07 — 02/10/2026

A situação histórica registrada anteriormente neste documento permanece
preservada como evidência das execuções realizadas antes do fechamento B07.

Em 01/10/2026 e 02/10/2026 foi executada uma nova certificação física
independente em banco PostgreSQL descartável dedicado:

`wma_phase2_b07_20261001_test`

### Reconstrução da baseline

A baseline certificada foi reconstruída utilizando o instalador oficial do
projeto.

Antes da aplicação das migrations da Fase 2, foram confirmados os objetos
críticos:

- `public.usuario`;
- `fn_atualiza_updated_at()`;
- `fn_log_auditoria()`.

A tabela `alembic_version` estava ausente antes da aplicação das migrations.

### Aplicação das migrations

A cadeia Alembic atual foi aplicada integralmente até o head único:

`202609170300`

Após a aplicação foram confirmadas 13 tabelas Bike Tour no schema `public`.

O inventário físico registrado após a aplicação apresentou:

- 8 schemas;
- 249 tabelas;
- 38 views;
- 170 sequences.

### Downgrade e reupgrade

No mesmo banco descartável foi executado o ciclo:

`202609170300 -> 202609170200 -> 202609170300`

O downgrade foi concluído com sucesso e o reupgrade retornou corretamente ao
head `202609170300`.

Após o ciclo, a constraint de nível permaneceu alinhada ao vocabulário
canônico:

- `INICIANTE`;
- `INTERMEDIARIO`;
- `AVANCADO`.

As 13 tabelas Bike Tour permaneceram presentes.

### Regressão PostgreSQL

A regressão PostgreSQL Bike Tour foi executada no mesmo banco preservado.

Foram executados 122 testes distribuídos pelos oito arquivos de integração
PostgreSQL Bike Tour.

Resultado:

```text
122 passed in 397.39s (0:06:37)
```

Após os testes, o banco permaneceu no estado esperado:

```text
database=wma_phase2_b07_20261001_test
alembic_version=202609170300
bike_tour_tables=13
```

### Correção do guard do teste de retenção

Na primeira execução da regressão, cinco testes de retenção foram interrompidos
antes do corpo funcional porque o teste exigia literalmente o banco
`wma_phase2_test`.

A análise confirmou que o contrato global de segurança dos testes PostgreSQL
permite banco local dedicado cujo nome termine em `_test`.

O guard específico do teste de retenção foi alinhado a esse contrato.

Após a correção mínima, a mesma regressão foi executada novamente no mesmo
banco B07 preservado.

Resultado final:

```text
122/122 PASS
```

SHA-256 do teste de retenção utilizado na certificação:

```text
7986D0571B6EC41BC8F693A342D7F28474B1C941CD3A1F0B04CC208C078A674E
```

### Decisão final B07

A nova reconstrução fornece evidência contemporânea independente para a
reprodutibilidade física da etapa 2.7.

As informações históricas de T24 permanecem preservadas nas seções anteriores
deste documento.

`B07_PHYSICAL_DATABASE_CERTIFICATION=PASS`

`B07_REBUILD_REQUIRED=COMPLETED`

O gate físico B07 está fechado para o conjunto de migrations e testes
certificado nesta execução.

Nenhum banco protegido foi utilizado como alvo da reconstrução B07.
