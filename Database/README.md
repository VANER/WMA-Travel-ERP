# Database - WMA Travel ERP

Camada de dados PostgreSQL do WMA Travel ERP. A fundação da Fase 1 e seus schemas são preservados
pelo instalador certificado. A evolução funcional até Bike Tour 2.7 está em
`Backend/migrations/versions/`, com head `202609170300`; consulte [Migrations](../Docs/MIGRATIONS.md).
A tabela histórica abaixo descreve a Fase 1, não o catálogo completo após as revisions da Fase 2.

## Estrutura

```text
Database/
├── install.sh           # restaura a baseline e aplica a evolução financeira certificada
├── baseline/            # referências históricas preservadas
├── certification/       # documentos e evidências de certificação
├── logs/                # evidências consolidadas e logs locais ignorados
├── migrations/          # histórico e regras para mudanças estruturais posteriores
├── scripts/             # dump certificado e evolução F1-FIN
└── audit/               # validações repetíveis e bloqueantes
```

## Uso rápido

Confirmar que `wma_staging` é um banco local descartável antes da execução. O instalador pode criar o banco
e restaurar sua estrutura; este exemplo não se destina a produção.

```bash
export PGPASSWORD='<senha-local>'
cd Database
DB_NAME=wma_staging ./install.sh --with-validation
```

O instalador restaura `scripts/WmaTravelERP.sql`, aplica os scripts persistentes F1-FIN.04 a F1-FIN.11 e, com
`--with-validation`, executa a validação estrutural e as certificações F1-FIN.12 e F1-FIN.13. Use
`--skip-financial` apenas para reproduzir a baseline histórica anterior ao fechamento do módulo financeiro.

Veja `install.sh --help` para todas as opções.

## Estado da Fase 1 (Fundação)

| Item | Status |
| --- | --- |
| Normalização 3FN de endereços (Migração 01) | ✅ Concluído |
| Consolidação `financeiro.*` → `public.*` (Migração 02) | Cancelada: `financeiro` é a autoridade do domínio |
| Colunas de auditoria em `financeiro.*` (Migração 03) | ✅ Incorporado à baseline; original não preservado |
| PKs em `auditoria.*` (Migração 04) | ✅ Incorporado à baseline; original não preservado |
| Triggers de auditoria (Migração 05) | ✅ Incorporado à baseline; original não preservado |
| Validação funcional do log de auditoria (06) | ✅ Concluído (2026-08-15) |
| Certificação estrutural "Etapa 10.4.x" | ✅ Evidência preservada; scripts originais não preservados |
| `DATA_DICTIONARY.md` da baseline histórica | ✅ 209/209 tabelas; descrições funcionais em evolução |
| `VERSION` corrigido | ✅ Concluído |
| Módulo financeiro F1-FIN | ✅ Certificado e reproduzível após a baseline histórica |
| Comentários de colunas fora do módulo financeiro | Aceito para evolução incremental na Fase 2 |
| Schemas reservados `logs`/`seguranca`/`util` | Decisão arquitetural deferida e documentada |
| Duplicatas controladas em `public`/`financeiro` e `dw` | Aceitas com autoridade documentada; revisar na Fase 2 |
| Framework de score ICB | Estrutura disponível; automação operacional pertence à Fase 2 |

---

**Copyright © 2026 WMA Travel Ltda.**
