# Segurança e Privacidade de Bike Tour

> **Projeto:** WMA Travel ERP
> **Etapa:** 2.7 — Bike Tour (`BT-DOC-06`)
> **Tipo:** Documento técnico e funcional
> **Versão:** 1.1
> **Data:** 10/09/2026
> **Status:** APROVADO E ACEITO

A6 foi aprovado e aceito em 11/09/2026; a autorização global de implementação permanece controlada pelo gate documental.
A1 permanece aceito no commit `f94f421`. Vaner confirmou em 10/09/2026 a reutilização de reserva e passageiro,
com um evento por saída. As demais escolhas abaixo são propostas concretas para revisão do responsável.

## 1. Autorização por operação

Token e contexto RBAC usam a infraestrutura existente. ADMIN recebe explicitamente as permissões na migration;
não haverá bypass implícito. Todo endpoint exige VISUALIZAR e, para mutação, a permissão adicional indicada.

| Permissão | Operações |
| --- | --- |
| BIKE_TOUR_VISUALIZAR | Listar eventos/recursos, disponibilidade, inscrições com IDs e relatórios agregados |
| BIKE_TOUR_OPERAR | Bloquear, confirmar, cancelar inscrição, presença, passagens, ocorrências, reconciliação e avaliação |
| BIKE_TOUR_GERENCIAR | Produto, evento, rota, recurso, equipe, apoio, abertura/início/encerramento e pendências externas |

Não existe endpoint de autoatendimento de participante nesta etapa. Usuário sem vínculo RBAC não ganha acesso
por ser passageiro. Gerenciar não concede operar implicitamente; papéis combinam permissões de forma explícita.
Leitura de auditoria e pendências exige VISUALIZAR e GERENCIAR. Operar sem gerenciar não cancela evento inteiro.
Escopo desta versão é corporativo, sem isolamento por filial presumido; eventual restrição futura exige novo contrato.

## 2. Dados mínimos e respostas

Bike Tour guarda IDs de passageiro/reserva e papel operacional, não nome, CPF, telefone, nascimento ou documento.
Listagens expõem IDs e estados. Dados nominativos continuam sob contrato autorizado do domínio proprietário;
nenhuma rota desta proposta precisa devolvê-los. Não coletar saúde, diagnóstico ou localização contínua.

Ocorrência usa somente tipo, gravidade e motivo enumerados; sem texto livre ou dados clínicos.
Campos pessoais extras são rejeitados por validação. Isso evita copiar PII para auditoria ou resposta idempotente.
Avaliação usa somente nota de 1 a 5; relatório usa contagens e identificadores necessários.

## 3. Retenção proposta para aceite operacional

Os prazos são escolhas operacionais propostas, não declaração de prazo legal obrigatório.
Não alteram retenção de Turismo, Comercial, Financeiro ou registros históricos certificados.

| Categoria Bike Tour | Prazo proposto | Tratamento |
| --- | --- | --- |
| Resposta idempotente mínima | Pelo menos 90 dias após a operação | Compactar para hash, IDs, status HTTP e resultado mínimo reproduzível |
| Chave/hash de operação e vínculos operacionais | 365 dias após encerramento/cancelamento | Revisão por gestor; retenção adicional exige motivo e nova data |
| Trilha técnica nova do módulo | 365 dias | Revisão conforme política corporativa; sem apagar auditoria compartilhada |

Não há apagamento automático. A tarefa administrativa deve selecionar apenas o escopo Bike Tour e registrar
contagem, período, ator e motivo. Pendência de tratamento ou preservação expressa suspende eliminação.
Antes de excluir identificadores, anonimizar referências elegíveis ou preservar a integridade e registrar impedimento.
Não encurtar unilateralmente prazos corporativos existentes. Esses prazos exigem aceite de A6 pelo responsável.

## 4. Idempotência, auditoria e segredos

Chaves são opacas, de 1 a 100 caracteres, nunca nome/documento do passageiro. Persistir hash da chave e do payload
normalizado; não armazenar tokens de autenticação. Replay exige autenticação e autorização atuais.
Resposta reproduzível inclui somente IDs, versões, estados e horários, sem nota livre ou dados nominativos.

Toda transição grava ator, operação, recurso, instante UTC, versão anterior/nova e correlation_id na mesma transação.
Triggers normativos de auditoria e updated_at devem ser instanciados, sem duplicar eventos funcionais por replay.
Falha na gravação da auditoria aborta a mutação. Erros e logs não expõem payload, segredo ou mensagem SQL.

## 5. Aceite verificável

BT-DOC-07 testa usuário sem token, sem visualizar, visualizar sem operar, operar sem gerenciar e ADMIN explícito.
Verifica também replay após revogação, respostas sem PII, rejeição de texto livre em ocorrência e falha de auditoria.
Definições de retenção e escopo de acesso devem ser aceitas antes da implementação, sem alterar A1.

## Controle e aceite

| Campo | Informação |
| --- | --- |
| Entregável | BT-DOC-06, versão 1.1 |
| Última atualização | 10/09/2026 |
| Responsável pelo aceite | Vaner |
| Evidência de aceite | Aceite formal registrado em 11/09/2026 após auditoria semântica e gates documentais aprovados |
| Implementação | Documento aceito; autorização global controlada pelo gate documental |

<!-- cspell:ignore CONCLUIDO EXECUCAO MANUTENCAO DISPONIVEL inscricao inscricoes ocorrencia ocorrencias -->
<!-- cspell:ignore logistica alocacao alocacoes correlacao reacomodacao reconciliacao permissao -->
<!-- cspell:ignore idempotencia versao obrigatorio disponivel proposta bike btree gist tstzrange offset -->
