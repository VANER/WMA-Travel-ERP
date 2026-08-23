# Inventário do Core Corporativo

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.1.1 — Inventário do Core Corporativo

**Data do levantamento:** 23/08/2026

**Status:** APROVADO E CERTIFICADO

## 2. Objetivo e limites

Este inventário identifica as estruturas da baseline relacionadas ao Core Corporativo e orienta o mapeamento
SQLAlchemy da etapa 2.1.2. Ele não cria models, migrations, tabelas ou novas decisões de domínio.

Fontes consultadas:

- `Database/scripts/WmaTravelERP.sql`, dump oficial e autoridade estrutural;
- `Docs/DATABASE_STANDARDS.md`, regras normativas de banco;
- `Docs/DATABASE_GUIDE.md`, orientação de domínio;
- `Docs/ARCHITECTURE.md`, schemas e decisões adiadas;
- ADR-001 e ADR-003, fronteiras modulares e persistência incremental.

## 3. Autoridades cadastrais

O schema `public` é a autoridade dos dados cadastrais. Os seguintes objetos formam o núcleo inicialmente
mapeável do Core:

| Objeto | Identidade | Papel | Dependências diretas |
| --- | --- | --- | --- |
| `public.localidade` | `id_localidade` | Referência geográfica compartilhada | Nenhuma no recorte do Core |
| `public.pessoa` | `id_pessoa` | Pessoa física ou jurídica | `public.localidade` |
| `public.empresa` | `id_empresa` | Empresa operadora do ERP | `public.localidade` |
| `public.cliente` | `id_cliente` | Papel comercial de uma pessoa | `public.pessoa` |
| `public.fornecedor` | `id_fornecedor` | Papel fornecedor de uma pessoa | `public.pessoa` |
| `public.tipo_documento` | `id_tipo_documento` | Catálogo de tipos documentais | Nenhuma |
| `public.documento` | `id_documento` | Metadados documentais transversais | `public.tipo_documento` |
| `public.configuracao_empresa` | `id_configuracao` | Preferências operacionais por empresa | `public.empresa` |
| `public.parametro_sistema` | `id_parametro` | Parâmetros globais da aplicação | Nenhuma |

As tabelas usam chaves inteiras alimentadas por sequences históricas. O mapeamento ORM deverá refletir essas
sequences e nunca executar `create_all()`.

## 4. Estruturas relacionadas

### 4.1 Pessoas e relações corporativas

- `public.cargo` e `public.colaborador` especializam pessoas para relações internas de trabalho;
- `public.contato_cliente` registra interações vinculadas a clientes;
- `public.fornecedor_turistico` especializa fornecedores no domínio Turismo;
- agenda, comissões, horas, tarefas e responsáveis referenciam colaboradores.

Esses objetos devem ser mapeados pelo módulo proprietário. O Core poderá expor contratos internos para suas
identidades, sem absorver regras de Comercial, Turismo ou gestão de pessoas.

### 4.2 Documentos

- `public.arquivo_digital`, `public.assinatura_digital` e `public.historico_documento` dependem de
  `public.documento`;
- `public.controle_vencimento_documento` e `public.contrato` também referenciam documentos;
- `public.sequencia_documento` controla numeração por tipo textual e ano.

`public.documento` usa `entidade_tipo` e `entidade_id` como associação polimórfica sem foreign key. A etapa de
models deve preservar esse comportamento legado e não inventar relacionamentos ORM automáticos para entidades
arbitrárias.

### 4.3 Usuários e controle de acesso

`public.usuario` é o cadastro técnico de usuários. `public.perfil_acesso`, `public.usuario_perfil`,
`public.permissao`, `public.politica_acesso` e `public.token_acesso` pertencem logicamente ao domínio de segurança,
cuja implementação está reservada para a etapa 2.2.

Na etapa 2.1, usuário pode ser referenciado apenas como identidade transversal. Senha, token, perfil, permissão,
autenticação e autorização não devem ser antecipados nem expostos por schemas do Core.

### 4.4 Configuração técnica

`config.parametro`, `config.migracao` e `config.versao_banco` são estruturas técnicas de infraestrutura e
versionamento do banco. Elas não substituem `public.configuracao_empresa` ou `public.parametro_sistema` e não
devem integrar repositories funcionais do Core.

## 5. Duplicatas, projeções e autoridade

| Estrutura | Classificação | Regra para a aplicação |
| --- | --- | --- |
| `financeiro.empresa` | Representação do módulo financeiro em consolidação | Não tratar como autoridade cadastral |
| `financeiro.cliente` | Papel financeiro ligado a `public.pessoa` | Não substituir `public.cliente` |
| `financeiro.fornecedor` | Representação financeira específica | Não substituir `public.fornecedor` |
| `financeiro.usuario` | Usuário técnico do módulo financeiro | Não substituir `public.usuario` |
| `financeiro.configuracao` | Configuração financeira | Manter no módulo Financeiro |
| `dw.dim_cliente` e `dw.dim_fornecedor` | Dimensões analíticas | Somente leitura por BI/DW |
| `public.dim_cliente` | Projeção analítica legada | Não usar como cadastro transacional |

Consolidações entre `financeiro.*` e `public.*` permanecem adiadas pela arquitetura. O inventário não autoriza
movimentação de schema nem alteração retroativa da baseline.

## 6. Dependências recebidas

As autoridades do Core são referenciadas por objetos de Comercial, Financeiro, Fiscal, Turismo e operações. Os
principais agregados consumidores são vendas e reservas (`cliente`), pedidos e comissões (`fornecedor`),
lançamentos e notas fiscais (`pessoa`, `empresa` e `cliente`) e documentos/contratos (`documento`).

Consequências para o desenho:

- exclusões físicas não devem ser presumidas;
- relações bidirecionais ORM devem ser adicionadas somente quando houver caso de uso;
- repositories do Core não podem incorporar regras dos módulos consumidores;
- carregamento de coleções deve evitar consultas implícitas e grafos excessivos.

## 7. Inconsistências e decisões pendentes

As seguintes condições pertencem à baseline e devem ser preservadas até decisão aditiva:

- schemas `seguranca` e `util` estão vazios, enquanto seus objetos lógicos permanecem em `public` por decisão
  arquitetural adiada;
- `Docs/DATABASE_STANDARDS.md` ainda registra que schemas vazios deveriam ser resolvidos no fechamento da Fase 1,
  enquanto `Docs/ARCHITECTURE.md` documenta explicitamente o adiamento; a arquitetura atual deve ser preservada;
- `public.usuario` não possui foreign key para pessoa ou empresa;
- `public.configuracao_empresa` não declara unicidade sobre `id_empresa`;
- `public.documento` possui vínculo polimórfico sem integridade referencial no banco;
- colunas de autoria alternam entre texto e foreign keys conforme a área;
- constraints históricas usam tanto `uk_` quanto o padrão normativo atual `uq_`.

Nenhum desses pontos deve ser corrigido silenciosamente durante o mapeamento ORM. Mudanças estruturais exigirão
análise própria e uma migration nova em etapa autorizada.

## 8. Recorte recomendado para a etapa 2.1.2

Primeiro conjunto de models somente para reflexão da baseline:

1. `Localidade`;
2. `Pessoa`;
3. `Empresa`;
4. `Cliente`;
5. `Fornecedor`;
6. `TipoDocumento`;
7. `Documento`;
8. `ConfiguracaoEmpresa`;
9. `ParametroSistema`.

O módulo funcional será criado em `app/modules/corporativo`. O caminho `app/core` permanece reservado à
infraestrutura técnica transversal da aplicação. Essa separação evita colisão sem antecipar models ou regras da
etapa 2.1.2.

## 9. Critérios de conclusão da etapa 2.1.1

- [x] autoridades cadastrais identificadas;
- [x] dependências diretas e consumidoras mapeadas;
- [x] usuários e segurança separados por responsabilidade;
- [x] documentos e configurações classificados;
- [x] duplicatas financeiras e projeções analíticas diferenciadas;
- [x] inconsistências da baseline registradas sem alteração estrutural;
- [x] nome e fronteira física do módulo funcional aprovados;
- [x] inventário validado e certificado no fluxo de entrega.
