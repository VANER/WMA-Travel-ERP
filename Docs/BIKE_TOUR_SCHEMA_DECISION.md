# Decisão de Dados de Bike Tour

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
