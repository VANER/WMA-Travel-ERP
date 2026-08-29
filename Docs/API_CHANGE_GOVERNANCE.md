# Governança de Mudanças da API

**Etapa:** 2.3.5 --- Propriedade, Aprovação e Exceções

**Status:** APROVADA

**Proprietário atual do contrato:** `@VANER`

## 1. Escopo

Esta política rege mudanças em rotas, métodos, `operationId`, parâmetros, schemas, autenticação, status HTTP,
paginação, filtros, ordenação e comportamento observável da API.

## 2. Papéis

| Papel | Responsabilidade |
| --- | --- |
| Autor da mudança | implementar, testar e declarar impacto e compatibilidade |
| Proprietário do contrato | aprovar coerência, versão, OpenAPI e comunicação |
| Data Owner do domínio | aceitar impacto funcional e regras de negócio |
| Revisor de segurança | aprovar autenticação, autorização, exposição e exceções emergenciais |
| DBA | revisar migrations, persistência e impacto na baseline certificada |

Enquanto houver um único mantenedor, `@VANER` acumula a propriedade do contrato e a decisão final. A evidência
permanece obrigatória no pull request. Quando outro revisor qualificado estiver disponível, mudanças incompatíveis
ou de segurança devem receber revisão separada.

## 3. Matriz de aprovação

| Classe | Evidências | Aprovação mínima |
| --- | --- | --- |
| aditiva | snapshot, teste e impacto | proprietário do contrato |
| comportamental compatível | snapshot, teste e justificativa | proprietário e Data Owner aplicável |
| incompatível | nova versão ou transição, ADR, changelog e plano de consumidores | proprietário e Data Owner |
| segurança emergencial | risco, contenção, testes e prazo de regularização | proprietário e revisor de segurança |

Mudanças com migration também exigem a aprovação definida em `GOVERNANCE.md`.

## 4. Evidências obrigatórias

Todo pull request que altera o contrato deve conter:

1. resumo do impacto para consumidores;
2. classificação de compatibilidade;
3. diff do snapshot `Backend/openapi.json`;
4. testes de contrato;
5. atualização documental e ADR quando necessária;
6. resultado do CI e do classificador OpenAPI;
7. plano de comunicação, depreciação ou migração quando aplicável.

## 5. Fluxo normal

```text
Proposta
  ↓
Classificação de compatibilidade
  ↓
Implementação + snapshot + testes
  ↓
Revisão dos proprietários
  ↓
CI aprovado
  ↓
Merge e validação pós-merge
```

O autor não deve usar merge administrativo para ignorar gate reprovado.

## 6. Exceção emergencial de segurança

Uma quebra imediata só é permitida para conter vulnerabilidade ativa ou risco material de exposição. A exceção
deve:

- registrar risco, alcance, decisão e responsáveis antes do merge, quando operacionalmente possível;
- preservar testes e CI, salvo indisponibilidade comprovada do provedor;
- evitar divulgar detalhes exploráveis antes da correção;
- abrir acompanhamento de regularização em até um dia útil;
- atualizar ADR, changelog, snapshot e comunicação em até dois dias úteis;
- registrar retrospectiva e encerramento da exceção.

Indisponibilidade do CI não transforma mudança comum em emergencial.

## 7. Rastreabilidade

O `CODEOWNERS` solicita o proprietário atual nos arquivos contratuais. O template de pull request coleta as
evidências, e o histórico do GitHub preserva checks, aprovações, merge e exceções.
