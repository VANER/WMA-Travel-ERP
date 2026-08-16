# Database - WMA Travel ERP

Camada de dados do WMA Travel ERP (PostgreSQL, multi-schema: `public`, `financeiro`, `auditoria`,
`config`, `dw`, e os schemas reservados `logs`, `seguranca`, `util` — ainda não migrados).

## Estrutura

```text
database/
├── install.sh          # instala/recria o banco a partir do dump mais recente
├── migrations/          # histórico versionado de mudanças estruturais (não reaplicar sobre um dump restaurado)
├── scripts/              # dumps completos (schema + dados) usados como base de instalação
├── audit/                # scripts de validação funcional (seguros para rodar repetidamente)
└── certification/        # scripts de certificação estrutural (nomenclatura, PK/índice/comentário)
```

## Uso rápido

```bash
export PGPASSWORD=<senha>
cd database
./install.sh --with-validation
```

Veja `install.sh --help` para opções, e o `README.md` de cada subpasta para detalhes e pendências
conhecidas.

## Estado da Fase 1 (Fundação)

| Item | Status |
|---|---|
| Normalização 3FN de endereços (Migração 01) | ✅ Concluído |
| Consolidação `financeiro.*` → `public.*` (Migração 02) | ⏸ Deferido (depende da estabilização do módulo financeiro) |
| Colunas de auditoria em `financeiro.*` (Migração 03) | ✅ Concluído — script original a recuperar |
| PKs em `auditoria.*` (Migração 04) | ✅ Concluído — script original a recuperar |
| Triggers de auditoria (Migração 05) | ✅ Concluído — script original a recuperar |
| Validação funcional do log de auditoria (06) | ✅ Concluído (2026-08-15) |
| Certificação estrutural "Etapa 10.4.x" | ✅ Concluído — scripts originais a recuperar |
| `DATA_DICTIONARY.md` (209/209 tabelas, estrutura real) | ✅ Concluído — descrições de negócio pendentes |
| `VERSION` corrigido | ✅ Concluído |
| Comentários de colunas (`COMMENT ON COLUMN`) | 🔴 Pendente — 2.341 colunas sem comentário |
| Migração dos schemas `logs`/`seguranca`/`util` | ⏸ Deferido (acoplado à Migração 02) |
| Duplicatas estruturais em `dw.*` | 🔴 Pendente — não endereçado por nenhuma migração |
| Framework de score ICB (`auditoria.regra` etc.) | 🔴 Pendente — estrutura pronta, nunca populada/executada |

---

**Copyright © 2026 WMA Travel Ltda.**
