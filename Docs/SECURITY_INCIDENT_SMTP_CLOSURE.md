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

## 5. Encerramento do incidente

No dia 09/09/2026, o responsável confirmou que:

- a credencial antiga foi revogada;
- a nova credencial foi criada e utilizada apenas em ambiente local ou de execução controlada;
- a autenticação via `SMTP_SSL` foi validada com sucesso;
- o envio real do e-mail foi concluído com sucesso;
- a credencial antiga deixou de autenticar em validações;
- a nova credencial não foi versionada em Git.

A correção foi conduzida em duas frentes: remoção da exposição do segredo no repositório e rotação da
credencial junto ao provedor SMTP. A reescrita do histórico Git não foi realizada, porque não havia necessidade
adicional de alteração retroativa e a preservação da rastreabilidade do projeto foi considerada preferível.

> Encerramento: mitigação concluída; rotação da credencial concluída; incidente encerrado com evidência
> técnica, operacional e documental.

## 6. Ressalva de auditoria complementar

As evidências acima validam o encerramento do ambiente existente. Esta auditoria não repetiu login nem envio em
produção e não teve acesso a evidência de implantação em produção. Até o presente momento, não existe
implantação em produção.

A ausência de segredo na versão atual não elimina a necessidade de preservar o histórico do Git e a revogação da
credencial antiga. Os testes do adaptador SMTP foram realizados localmente e não substituem a validação do
provedor nem a checagem final em ambiente de produção.

### 6.1 Atestação do responsável

Em 09/09/2026, Vaner atestou: "testes realizados e documentados". A confirmação foi registrada e referenciada
na seção 2 deste documento. Nenhum valor de credencial foi solicitado ou incluído nesta evidência.

### 6.2 Abrangência final confirmada

- Responsável: Vaner
- Data: 09/09/2026
- Ambiente: local no VS Code; produção ainda não existe
- Referência: seções 2 e 4

A validação da operação SMTP em produção, antes da primeira implantação, permanece obrigatória e deve ser
executada sem reutilizar ou divulgar a credencial revogada.
