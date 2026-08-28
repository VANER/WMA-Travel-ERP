# Integrações

Este pacote receberá adaptadores de serviços externos. Código de domínio não deve depender diretamente de SDKs
ou detalhes de fornecedores; integrações devem expor contratos internos explícitos.

`email_hostgator.py` implementa a porta de recuperação autorizada com SMTP SSL. O adaptador recebe configuração
validada e não registra destinatário, senha ou token. Website, pagamentos e operadoras serão adicionados somente
quando seus casos de uso e requisitos de segurança entrarem no escopo.
