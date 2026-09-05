# Segurança e Privacidade de Turismo

> **Etapa:** 2.6.6 — Segurança e Privacidade (`TUR-DOC-06`)
> **Data:** 05/09/2026
> **Status:** APROVADO

## 1. Objetivo

Definir autorização, minimização, auditoria e retenção aplicáveis a Turismo, especialmente aos dados de
passageiros. Permanecem vigentes `Docs/SECURITY.md` e a autenticação central da API.

## 2. Permissões

| Permissão | Alcance |
| --- | --- |
| `TURISMO_VISUALIZAR` | consultar catálogo, saídas e disponibilidade |
| `TURISMO_OPERAR` | criar, confirmar e cancelar reservas |
| `TURISMO_GERENCIAR` | gerir saídas, capacidade e configuração operacional |

As três permissões são concedidas ao perfil `ADMIN` pela migration e aplicadas no servidor. Visualizar não implica
acesso irrestrito a CPF, documento, telefone ou e-mail.

## 3. Dados pessoais

- coletar somente dados necessários à execução e obrigação aplicável;
- nunca registrar dados sensíveis em logs, métricas, chaves idempotentes ou erros;
- separar consulta operacional de exportação ou acesso administrativo;
- mascarar documento e CPF quando o valor integral não for necessário;
- preservar correlação por identificadores internos;
- definir retenção por finalidade antes de automatizar anonimização ou exclusão;
- auditar acesso excepcional e toda mutação de passageiro.

## 4. Auditoria e controles

As novas tabelas recebem triggers de atualização e auditoria já existentes na baseline. Toda rota exige token e
permissão explícita. Mutação concorrente usa transação, versão e chave idempotente. Erros expõem apenas mensagem de
domínio e correlation ID do middleware.

## 5. Riscos e tratamento

| Risco | Controle obrigatório |
| --- | --- |
| acesso excessivo a passageiro | menor privilégio e resposta mínima |
| vazamento em observabilidade | proibição de PII em logs e métricas |
| reserva duplicada | chave idempotente única |
| elevação por rota | dependência RBAC no servidor |
| alteração não rastreada | trigger e identidade do ator |

## 6. Conclusão

O `TUR-DOC-06` está aprovado. A próxima entrega é `TUR-DOC-07` — Plano de testes.
