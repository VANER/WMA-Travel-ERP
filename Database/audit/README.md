# Validações de banco de dados

Os scripts deste diretório são somente leitura ou encerram suas alterações com `ROLLBACK`. Eles devem ser
idempotentes e executados com `ON_ERROR_STOP`.

## Scripts

| Script | Finalidade |
| --- | --- |
| `06_validar_log_auditoria.sql` | Valida funções, triggers, constraints e chaves primárias obrigatórias. |

Execução direta no Windows:

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' `
  -X -w -h localhost -p 5432 -U postgres -d wma_travel `
  -v ON_ERROR_STOP=1 -f 'Database\audit\06_validar_log_auditoria.sql'
```

O instalador executa esse script quando recebe `--with-validation`. A ausência do arquivo é bloqueante.
