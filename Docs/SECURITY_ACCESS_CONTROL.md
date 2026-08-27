# Segurança e Controle de Acesso

## Escopo

Este documento consolida as etapas 2.2.5 a 2.2.12. A baseline continua sendo a autoridade para usuários,
perfis e permissões; as migrations da Fase 2 acrescentam somente as relações e registros operacionais ausentes.

## Modelo RBAC

`public.perfil_acesso` representa o papel RBAC. Não existe uma segunda tabela de roles. A vigência da atribuição
é determinada por `public.usuario_perfil.data_inicio` e `data_fim`, com limites inclusivos.

`public.perfil_permissao` relaciona perfis e permissões por chave primária composta. Perfis inativos ou excluídos,
permissões excluídas e relações excluídas não concedem acesso. Ausência de concessão resulta em negação.

A migration cadastra `CORE_VISUALIZAR` e `CORE_CADASTRAR` e as atribui somente ao perfil `ADMIN`. Novas concessões
dependem de decisão explícita de negócio.

## Autorização HTTP

O bearer token é validado junto com a sessão persistida. Token inválido, expirado ou associado a sessão revogada
retorna `401` com `WWW-Authenticate: Bearer`. Identidade autenticada sem a permissão exigida recebe `403`.

Todos os endpoints do Core Corporativo exigem `CORE_VISUALIZAR`. Endpoints de cadastro exigem também
`CORE_CADASTRAR`. Health checks e documentação permanecem públicos.

Os endpoints de sessão são:

- `POST /api/v1/auth/login`;
- `POST /api/v1/auth/refresh`;
- `POST /api/v1/auth/logout`.

## Recuperação de Acesso

O serviço de recuperação gera token opaco de 32 bytes, persiste somente SHA-256 e limita a validade a 30 minutos.
A solicitação tem resultado uniforme para contas ausentes ou inativas. O token é de uso único e a redefinição
revoga todas as sessões do usuário.

A entrega é definida pela porta `NotificadorRecuperacao`. Nenhum token bruto é retornado pela API, persistido ou
registrado em log. O adaptador externo de email deve ser integrado quando a infraestrutura de notificações for
definida; até lá, o caso de uso permanece disponível somente pela camada de serviço.

## Auditoria

`public.evento_seguranca` registra código, resultado, usuário e sessão opcionais, IP, agente e detalhes JSON. O
registrador rejeita chaves conhecidas de senha, credencial e tokens. Login, refresh e logout registram eventos
estruturados; falhas de login não persistem o email apresentado.

`evento_seguranca` é uma trilha append-only: possui somente `created_at` e não aceita atualização ou exclusão pela
camada de aplicação. Por não ser tabela cadastral ou transacional mutável, não recebe os campos de versionamento.

As alterações de concessões em `perfil_permissao` também usam os triggers corporativos de atualização e auditoria.

## Migrations

- `202608252300_perfil_permissao.py`: relação RBAC, índices, triggers e permissões iniciais do Core;
- `202608252330_recuperacao_auditoria.py`: tokens de recuperação e eventos de segurança.

As duas revisions são aditivas, lineares e possuem downgrade limitado aos objetos criados.
