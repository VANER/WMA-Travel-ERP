# Services do Core Corporativo

## 1. Escopo

**Etapa:** 2.1.4 — Services do Core Corporativo

**Status:** CONCLUÍDA E CERTIFICADA

Certificação: `Docs/certification/PHASE_2_1_4_CORE_SERVICES_CERTIFICATION.md`.

Esta etapa implementa os casos de uso cadastrais mínimos sobre os repositories certificados na 2.1.3. Não inclui
schemas de entrada e saída, endpoints, autenticação ou regras ainda não autorizadas pela documentação do domínio.

## 2. Organização

| Caminho | Responsabilidade |
| --- | --- |
| `app/modules/corporativo/services.py` | Limites transacionais e services concretos |
| `tests/test_core_services.py` | Gates de delegação, commit, rollback e propagação de falhas |

## 3. Contrato dos services

Cada service recebe uma `Session` SQLAlchemy e oferece:

- `obter(identifier)`: consulta sem alterar a transação;
- `listar(offset, limite)`: listagem delegada ao repository;
- `cadastrar(entity)`: inclusão atômica, com `commit` em sucesso e `rollback` em qualquer falha.

Falhas do repository ou do próprio commit são propagadas após o rollback. O service não converte exceções em
respostas HTTP, pois esse tratamento pertence às etapas de schemas e API.

## 4. Services concretos

- `LocalidadeService`;
- `PessoaService`;
- `EmpresaService`;
- `ClienteService`;
- `FornecedorService`;
- `TipoDocumentoService`;
- `DocumentoService`;
- `ConfiguracaoEmpresaService`;
- `ParametroSistemaService`.

## 5. Regras preservadas

- constraints PostgreSQL continuam sendo a autoridade final de integridade;
- nenhuma política de exclusão física ou lógica foi inventada;
- nenhuma unicidade ausente na baseline foi simulada pela aplicação;
- o vínculo polimórfico de documentos permanece inalterado;
- autenticação, autorização, perfis e tokens permanecem reservados à etapa 2.2;
- validação e normalização de dados externos serão definidas nos schemas da etapa 2.1.5.

## 6. Limites para continuidade

Os services cadastrais representam unidades de trabalho atômicas individuais. Orquestrações futuras que envolvam
múltiplos módulos deverão definir um limite transacional superior, conforme a ADR-014, sem encadear commits
parciais destes casos de uso.
