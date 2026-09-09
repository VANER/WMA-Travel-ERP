# Incidente de Credencial SMTP — Registro de Mitigação e Encerramento

> **Projeto:** WMA Travel ERP
> **Data:** 09/09/2026
> **Status:** ENCERRADO

## 1. Resumo

Este incidente foi tratado em duas camadas distintas:

- a mitigação no repositório, que removeu a exposição de segredos dos arquivos
  versionados e reforçou as políticas de segurança;
- a revogação e rotação da credencial no provedor SMTP, que validou a troca da
  conta de envio e a eliminação do uso da credencial antiga.

A correção no código e na documentação foi aplicada sem reescrever o histórico
Git, e o encerramento formal foi registrado após confirmação externa na
infraestrutura de e-mail.

## 2. Evidências de encerramento

- Credencial SMTP anterior invalidada por troca da senha da conta Titan;
- Nova credencial configurada exclusivamente no ambiente local não versionado;
- SMTP host: `smtp.titan.email`;
- SMTP port: `465`;
- Carregamento da nova credencial: `PASS`;
- Autenticação SMTP SSL: `PASS`;
- Envio operacional real: `PASS`;
- Testes unitários do adaptador Titan: `4 passed`;
- Segredo não versionado no Git: `PASS`;
- Reescrita do histórico Git: `NÃO EXECUTADA`, por ausência de necessidade
  técnica adicional neste encerramento.

## 3. Mitigação no repositório

A mitigação no repositório foi concluída com evidência registrada em:

- remoção da atribuição real de `WMA_SMTP_PASSWORD` de
  `Backend/.env.example`;
- reforço da regra em `Docs/SECURITY.md` para proibir segredos reais em
  `.env`, YAML, scripts e documentação;
- criação do workflow de varredura de segredos em
  `.github/workflows/secret-scan.yml`;
- registro formal do incidente neste documento.

Esse estado representa a proteção do código e do histórico versionado. Ele não
substitui a validação externa da infraestrutura de e-mail.

## 4. Revogação e rotação da credencial no provedor

A revogação e rotação da credencial foram executadas no provedor do serviço SMTP,
com confirmação de que:

1. a credencial antiga foi invalidada;
2. a nova credencial foi criada e utilizada exclusivamente por ambiente local ou
   de execução real;
3. a autenticação por `SMTP_SSL` foi validada com sucesso;
4. o envio real do e-mail foi concluído com sucesso;
5. a credencial antiga não autentica mais em testes de validação;
6. a nova credencial não foi versionada em Git.

## 5. Decisão final

O incidente foi encerrado com evidência técnica e operacional. A mitigação no
repositório e a revogação/rotação no provedor são tratadas como fases distintas,
mas ambas foram concluídas no escopo do incidente.

A reescrita do histórico Git não foi executada porque não havia necessidade
adicional de limpeza de histórico após a remoção da exposição do segredo,
validada pela revisão da infraestrutura, pelos testes e pela ausência de
segredo em arquivos versionados.

> Estado final: mitigação no repositório concluída; revogação e rotação da
> credencial do provedor concluídas; incidente formal encerrado com evidência.
