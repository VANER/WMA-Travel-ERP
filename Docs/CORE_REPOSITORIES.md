# Repositories do Core Corporativo

## 1. Escopo

**Etapa:** 2.1.3 — Repositories do Core Corporativo

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_1_3_CORE_REPOSITORIES_CERTIFICATION.md`.

Esta etapa implementa a persistência mínima dos nove models certificados na 2.1.2. Não inclui regras de negócio,
schemas HTTP, endpoints ou decisões de exclusão lógica.

## 2. Organização

| Caminho | Responsabilidade |
| --- | --- |
| `app/modules/corporativo/repositories.py` | Base tipada e repositories concretos |
| `tests/test_core_repositories.py` | Gates de contrato, paginação e transação |

## 3. Contrato de persistência

Cada repository recebe uma `Session` SQLAlchemy já criada pelo chamador e oferece:

- `obter(identifier)`: consulta pela chave primária;
- `listar(offset, limite)`: paginação ordenada deterministicamente pela chave primária;
- `adicionar(entity)`: adiciona a entidade e executa `flush`, sem `commit`.

O limite aceito por consulta é de 1 a 1000 registros e o offset não pode ser negativo. Esse gate técnico evita
consultas acidentais sem limite; a paginação exposta pela API será definida somente na etapa de schemas/API.

## 4. Repositories concretos

- `LocalidadeRepository`;
- `PessoaRepository`;
- `EmpresaRepository`;
- `ClienteRepository`;
- `FornecedorRepository`;
- `TipoDocumentoRepository`;
- `DocumentoRepository`;
- `ConfiguracaoEmpresaRepository`;
- `ParametroSistemaRepository`.

## 5. Limite transacional

Repositories não executam `commit` nem `rollback`. Eles participam da sessão fornecida pelo service ou caso de
uso, conforme as ADRs 003 e 014. O método `adicionar` usa `flush` apenas para sincronizar o estado da entidade
dentro da transação corrente.

Falhas de consulta ou `flush` são propagadas sem rollback interno, preservando no service proprietário a decisão
sobre a transação completa.

Exclusão física ou lógica não faz parte do contrato desta etapa. A presença histórica de `deleted_at` não é
suficiente para inventar uma política de exclusão antes da definição dos services.

## 6. Próximas etapas

- regras corporativas e limites dos casos de uso pertencem à etapa 2.1.4;
- schemas de entrada e saída pertencem à etapa 2.1.5;
- endpoints pertencem à etapa 2.1.6;
- consultas especializadas serão adicionadas quando um caso de uso aprovado demonstrar necessidade.
