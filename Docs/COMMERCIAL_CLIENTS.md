# Clientes do Módulo Comercial

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.4.2 — Clientes

**Data:** 30/08/2026

**Status:** APROVADA, CERTIFICADA E INTEGRADA

## 2. Objetivo e limites

Implementar os casos de uso comerciais de Cliente sobre a autoridade cadastral do Core Corporativo. Esta etapa
não cria tabela, model SQLAlchemy duplicado, migration, schema HTTP, endpoint ou alteração no contrato OpenAPI.

O cadastro `public.cliente` e o model `app.modules.corporativo.models.Cliente` permanecem sob propriedade do Core.
O módulo Comercial consome somente o contrato interno explícito publicado pelo Core.

## 3. Organização

| Caminho | Responsabilidade |
| --- | --- |
| `app/shared/clientes.py` | Contrato e projeções compartilhadas entre os domínios |
| `app/modules/corporativo/clientes.py` | Adaptador da autoridade cadastral |
| `app/modules/comercial/clientes.py` | Comando, erros e caso de uso comercial |
| `tests/test_commercial_clients.py` | Gates unitários de contrato, regras e transação |
| `tests/integration/test_postgresql.py` | Fluxo real sobre PostgreSQL descartável |

## 4. Contrato entre Core e Comercial

O protocolo `CadastroClienteCorporativo` oferece ao Comercial somente:

- consulta da projeção mínima de Pessoa;
- consulta do papel Cliente por Pessoa;
- atribuição do papel Cliente sem confirmar a transação.

As projeções imutáveis `PessoaParaCliente` e `ClienteCorporativo`, publicadas em `app/shared`, evitam que o
Comercial dependa do grafo ORM ou das implementações internas do Core. `NovoClienteCorporativo` representa o
comando aceito pela porta cadastral.

`CadastroClienteCorporativoSqlAlchemy` implementa o contrato dentro do Core. O adaptador executa `flush`, mas não
executa `commit` ou `rollback`; o limite transacional pertence ao service orquestrador conforme a ADR-014.

## 5. Caso de uso

`ClienteComercialService.habilitar` executa, nesta ordem:

1. consulta a Pessoa na autoridade corporativa;
2. rejeita identidade inexistente;
3. rejeita Pessoa logicamente excluída;
4. rejeita Pessoa que já possua o papel Cliente;
5. solicita ao Core a criação do papel;
6. confirma a unidade de trabalho uma única vez;
7. executa rollback e propaga qualquer falha de persistência ou commit.

`ClienteComercialService.obter_por_pessoa` oferece consulta interna sem alterar a transação.

## 6. Validações e erros

O comando `HabilitarCliente` exige:

- `id_pessoa` positivo;
- `codigo_cliente` não vazio quando informado;
- `codigo_cliente` com até 20 caracteres, refletindo a baseline.

Erros esperados de domínio:

| Erro | Condição |
| --- | --- |
| `PessoaNaoEncontradaError` | Pessoa não existe no Core |
| `PessoaExcluidaError` | Pessoa possui exclusão lógica |
| `ClienteJaCadastradoError` | Pessoa já possui papel Cliente |

Esses erros não são convertidos em HTTP nesta etapa. O mapeamento para respostas públicas pertence à API
Comercial 2.4.11.

## 7. Transação e concorrência

O Comercial controla `commit` e `rollback`; o gateway do Core participa da mesma sessão. Validações de
elegibilidade ocorrem antes de qualquer mutação e não alteram a transação.

A baseline não declara unicidade sobre `public.cliente.id_pessoa`. O caso de uso impede duplicidade em execução
sequencial, mas duas transações concorrentes ainda podem inserir papéis para a mesma Pessoa. Fechar essa condição
exige análise dos dados existentes e migration aditiva com constraint única, não autorizada na 2.4.2. A lacuna
permanece registrada para decisão estrutural antes de fluxos concorrentes de produção.

## 8. Validação

- 17 testes unitários cobrem contrato, projeções, consultas, validações, erros, commit e rollback;
- o fluxo de integração cria Pessoa, habilita Cliente e consulta o papel em PostgreSQL real descartável;
- as três novas camadas possuem cobertura de 100%;
- nenhuma migration ou mudança OpenAPI foi produzida.

## 9. Critérios de conclusão

- [x] autoridade cadastral do Core preservada;
- [x] contrato interno explícito criado;
- [x] caso de uso comercial implementado;
- [x] validações e erros de domínio implementados;
- [x] limite transacional coberto;
- [x] testes unitários aprovados;
- [x] integração PostgreSQL local aprovada;
- [x] limitação concorrente documentada sem migration indevida;
- [x] CI Linux/PostgreSQL aprovado;
- [x] merge e validação pós-merge registrados.
