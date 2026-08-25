# Hash de Credenciais

## 1. Identificação

**Fase:** 2 — Backend e API

**Etapa:** 2.2.3 — Hash de Credenciais

**Data:** 25/08/2026

**Status:** CONCLUÍDA E CERTIFICADA

## 2. Objetivo

Definir e implementar a política de hash das credenciais humanas consumida pela autenticação, sem antecipar
tokens, sessões, autorização, endpoints ou alterações estruturais no banco.

## 3. Política aprovada

O algoritmo aprovado é Argon2id, por meio de `argon2-cffi==25.1.0`, com parâmetros explícitos:

| Parâmetro | Valor |
| --- | ---: |
| memória | 65.536 KiB (64 MiB) |
| iterações | 3 |
| paralelismo | 4 |
| salt | 16 bytes, aleatório por hash |
| hash | 32 bytes |
| versão Argon2 | 19 |

O formato PHC armazenado inclui algoritmo, versão, parâmetros, salt e hash. Senha, pepper ou qualquer segredo não
é registrado no código, em logs ou em configuração versionada.

## 4. Operações

`PoliticaHashArgon2id.gerar` cria hashes somente para credenciais não vazias com até 1.024 bytes em UTF-8.
`verificar` aceita o hash opcional exigido pelo contrato da autenticação e sempre executa uma verificação Argon2id
para identidade ausente. Hashes malformados são recusados e também acionam a verificação fictícia.

`precisa_rehash` identifica hashes inválidos ou produzidos com parâmetros diferentes da política atual. A
atualização persistente após autenticação bem-sucedida exige uma decisão transacional própria e não integra esta
etapa.

## 5. Limites deliberados

Esta etapa não inclui:

- migration ou alteração de `public.usuario.senha_hash`;
- importação ou conversão automática de hashes legados;
- pepper ou integração com cofre de segredos;
- atualização automática de hash durante login;
- política funcional de criação ou troca de senha;
- tokens, sessões, autorização ou endpoint HTTP.

## 6. Critérios de conclusão

- [x] Argon2id e parâmetros definidos explicitamente;
- [x] salts aleatórios delegados à biblioteca especializada;
- [x] geração e verificação implementadas;
- [x] identidade ausente protegida por hash fictício;
- [x] hashes inválidos recusados sem exceção observável;
- [x] limite de entrada aplicado contra consumo abusivo;
- [x] necessidade de rehash detectável;
- [x] dependência direta e lockfiles reproduzíveis gerados e validados;
- [x] tokens, sessões, autorização e migrations não antecipados.

## 7. Referências

- [argon2-cffi — API PasswordHasher](https://argon2-cffi.readthedocs.io/en/stable/api.html);
- [OWASP — Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html);
- [RFC 9106 — Argon2 Memory-Hard Function](https://www.rfc-editor.org/rfc/rfc9106.html).

## 8. Evidências locais

As seguintes validações foram executadas em 25 de agosto de 2026:

- `python -m pip check`: aprovado;
- `python -m ruff format --check app tests migrations`: aprovado em 56 arquivos;
- `python -m ruff check .`: aprovado;
- `python -m mypy app tests`: aprovado em 55 arquivos;
- `python -m pytest -W error --run-postgresql --cov=app --cov-report=term-missing`: 180 testes aprovados,
  sem testes ignorados e cobertura de 100%;
- testes da política Argon2id em Linux com Python 3.13: 9 testes aprovados;
- `python -m alembic heads`: aprovado;
- `python -m alembic upgrade head` em PostgreSQL 18 descartável: aprovado;
- `python -m pip_audit --local --progress-spinner off`: nenhuma vulnerabilidade conhecida;
- Markdownlint nos documentos alterados: aprovado;
- `git diff --check`: aprovado.

A certificação formal está registrada em
`Docs/certification/PHASE_2_2_3_CREDENTIAL_HASHING_CERTIFICATION.md`.
