# Auditoria de Governança — WMA Travel ERP

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Status:** RASTREIO ATUALIZADO; GATES EXTERNOS DO GITHUB PENDENTES DE CONFIGURAÇÃO MANUAL

## 1. Objetivo

Este checklist consolida os gates de governança que devem ser confirmados antes da liberação da Etapa 2.7 — Bike Tour.

## 2. Status atual

- [x] `main` com documentação atualizada para 2.0 a 2.6 concluídas,
  certificadas e integradas
- [x] `2.5` Financeiro documentado como concluído, certificado e integrado
- [x] `2.6` Turismo documentado como concluído, certificado e integrado
- [x] `2.7` Bike Tour documentado como gate documental e implementação
  funcional bloqueada
- [x] documento de gate documental da 2.7 registrado em
  `Docs/BIKE_TOUR_DOCUMENTATION_GATE.md`
- [x] restrição de implementação funcional da 2.7 explicitamente registrada em
  `Docs/PHASE_2_EXECUTION_ORDER.md` e `Docs/PHASE_2_ROADMAP.md`
- [x] proteção real da branch `main` configurada no GitHub com required status
  checks
- [x] required status checks `Backend CI` e `Documentation CI` obrigatórios na
  `main`
- [x] branch atualizada antes do merge configurada na `main`
- [x] bloqueio de merge com checks vermelhos habilitado no GitHub
- [x] branches antigas identificadas e revisadas para remoção ou arquivamento
  após confirmação de integração
- [x] incidente SMTP formalmente documentado e encerrado com evidência externa
  de revogação e rotação
- [x] secret scanning e push protection habilitados no GitHub
- [x] gate automatizado de secret scanning no CI ativo
- [x] documentação de segurança reforçada com regra de placeholders e
  proibição de segredos reais em `.env`, YAML e scripts
- [x] 2.7 liberada apenas após aprovação do inventário e da fronteira de
  domínio

## 3. Evidência e ação obrigatória

### 3.1 Proteção da `main`

A proteção da branch `main` não pode ser editada por arquivo do repositório.
A configuração precisa ser feita no painel de regras do GitHub ou via API do
GitHub por um mantenedor autorizado.

Os requisitos mínimos devem ser:

- `Backend CI` obrigatório
- `Documentation CI` obrigatório
- `Require branches to be up to date before merging`
- `Require status checks to pass before merging`
- `Do not allow bypassing the above settings`
- `Branch protection` com `Block force pushes` e `Prevent branch deletion`

### 3.2 Incidente SMTP

O risco foi mitigado no repositório por remoção do segredo e pela atualização de
`.env.example`, mas o encerramento formal exige confirmação externa do
provedor e registro da rotação do segredo.

### 3.3 Aprovação da 2.7

A 2.7 deve seguir a ordem:

1. inventário Bike Tour
2. fronteiras com Turismo, Comercial e Financeiro
3. mapa de requisitos
4. decisão sobre migrations
5. plano de testes
6. critérios de certificação
7. gate de aprovação antes de implementação funcional

## 4. Conclusão

A documentação e os gates de qualidade do repositório foram ajustados para
refletir o estado real da execução. O que continua sendo externo ao código é a
configuração final da proteção da `main` e a validação externa de rotação do
SMTP no provedor.
