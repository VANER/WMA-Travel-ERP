# Incidente de Credencial SMTP — Registro de Mitigação e Encerramento

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Status:** MITIGADO NO REPOSITÓRIO; ENCERRAMENTO FORMAL PENDENTE DE
EVIDÊNCIA EXTERNA

## 1. Resumo

Foi identificada exposição de credencial SMTP associada ao projeto,
posteriormente removida dos arquivos atualmente versionados. A correção no
código e na documentação foi aplicada removendo a referência ao valor sensível
no exemplo de configuração e reforçando as regras de segurança do projeto.

## 2. Evidência registrada no repositório

- remoção da atribuição real de `WMA_SMTP_PASSWORD` de
  `Backend/.env.example`;
- reforço da regra em `Docs/SECURITY.md` para proibir segredos reais em
  `.env`, YAML, scripts e documentação;
- registro do incidente e da política de mitigação neste documento.

## 3. Status de encerramento

### Mitigado

O risco foi mitigado no repositório porque a credencial exposta foi removida do
diretório versionado e não deve continuar disponível em arquivos rastreados pelo
Git.

### Encerramento formal

O encerramento formal do incidente exige evidência externa e responsável, com confirmação de:

1. revogação da credencial antiga no provedor SMTP;
2. rotação para nova credencial;
3. uso exclusivo de variável de ambiente ou cofre de segredos em produção;
4. decisão registrada sobre limpeza do histórico Git;
5. confirmação de que a produção não usa mais o segredo antigo.

## 4. Decisão do projeto

A política do repositório é considerar o incidente em estado de mitigação até a
apresentação da evidência externa. O histórico Git continua preservado por
política de rastreabilidade, mas a limpeza de histórico somente deve ser
executada com autorização explícita e após validação técnica e legal.

## 5. Encerramento recomendado

O incidente deve ser considerado encerrado apenas quando a equipe responsável registrar:

- data da revogação;
- data da rotação;
- nome do responsável;
- referência do provedor ou chamado;
- evidência de uso da nova variável de ambiente em produção;
- decisão final sobre limpeza de histórico.

> Enquanto essa evidência não existir, o estado correto é: mitigado no
> repositório, não fechado formalmente até confirmação externa.
