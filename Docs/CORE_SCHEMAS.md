# Schemas do Core Corporativo

## 1. Escopo

**Etapa:** 2.1.5 — Schemas do Core Corporativo

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_1_5_CORE_SCHEMAS_CERTIFICATION.md`.

Esta etapa define contratos Pydantic de entrada e saída para as nove autoridades corporativas. As classes não
criam endpoints e não alteram models, banco ou migrations.

## 2. Organização

| Caminho | Responsabilidade |
| --- | --- |
| `app/modules/corporativo/schemas.py` | Contratos `Create` e `Response` |
| `tests/test_core_schemas.py` | Gates de validação, defaults e conversão ORM |

## 3. Separação dos contratos

Para cada autoridade existem dois contratos:

- `*Create`: campos aceitos para cadastro, sem chave primária ou auditoria;
- `*Response`: representação de saída com identidade, auditoria aplicável e leitura por atributos ORM.

Entradas rejeitam campos desconhecidos e removem espaços nas extremidades das strings. Respostas não incluem
relacionamentos ORM, evitando carregamentos implícitos e grafos não autorizados.

## 4. Validações aplicadas

- tamanhos máximos refletem `VARCHAR` e `CHAR` da baseline;
- chaves estrangeiras de entrada devem ser positivas;
- `tipo_pessoa` aceita somente `FISICA` ou `JURIDICA`, conforme a constraint histórica;
- valores monetários permanecem `Decimal`, com 15 dígitos e duas casas decimais;
- prazo de validade em dias não pode ser negativo;
- defaults de país, status, timezone e flags de atividade refletem o banco.

Não foram inventadas validações de formato para CPF, CNPJ, telefone, e-mail, CEP, timezone ou vínculos
polimórficos. Essas regras exigem decisão de domínio própria e não podem divergir silenciosamente dos dados
históricos.

## 5. Limites para continuidade

- os endpoints serão implementados somente na etapa 2.1.6;
- conversão de falhas de integridade em respostas públicas pertence à API;
- autenticação e autorização permanecem reservadas à etapa 2.2;
- contratos de atualização serão adicionados apenas quando os casos de uso correspondentes forem aprovados.
