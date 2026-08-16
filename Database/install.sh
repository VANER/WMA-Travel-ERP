#!/usr/bin/env bash
# =============================================================================
# WMA Travel ERP - install.sh
# Instala/recria o banco de dados a partir do dump completo mais recente,
# e opcionalmente roda as validações de auditoria e certificação.
#
# Modelo adotado neste projeto:
#   - O dump completo (scripts/WmaTravelERP.sql) e o "source of truth":
#     ele já reflete TODAS as migrações aplicadas ate a data de exportação
#     (schema + dados). NAO reaplique os scripts de migrations/ por cima de
#     um dump ja restaurado - eles servem como historico/auditoria de
#     mudancas, nao como passos a repetir.
#   - Use migrations/ apenas ao montar um ambiente a partir de um dump MAIS
#     ANTIGO que a migracao em questao (ver migrations/README.md).
#   - audit/ e certification/ contem scripts de VALIDACAO, seguros para
#     rodar quantas vezes quiser (nao alteram estrutura).
#
# Uso:
#   ./install.sh                 # restaura o dump mais recente
#   ./install.sh --skip-restore  # pula a restauracao (banco ja existe)
#   ./install.sh --with-validation   # roda audit/06_validar_log_auditoria.sql ao final
#   ./install.sh --help
# =============================================================================
set -euo pipefail

# --- Configuração (sobrescreva via variáveis de ambiente) ------------------
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-wma_staging}"
DB_USER="${DB_USER:-postgres}"
# Defina PGPASSWORD no ambiente antes de rodar, ou configure ~/.pgpass.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_FILE="${SCRIPT_DIR}/scripts/WmaTravelERP.sql"

SKIP_RESTORE=false
WITH_VALIDATION=false

for arg in "$@"; do
  case "$arg" in
    --skip-restore) SKIP_RESTORE=true ;;
    --with-validation) WITH_VALIDATION=true ;;
    --help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $arg" >&2
      exit 1
      ;;
  esac
done

echo "== WMA Travel ERP - install.sh =="
echo "Host: ${DB_HOST}:${DB_PORT}  Banco: ${DB_NAME}  Usuario: ${DB_USER}"

psql_cmd() {
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"
}

# --- 1) Cria o banco se não existir -----------------------------------------
DB_EXISTS=$(psql_cmd -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")
if [ "$DB_EXISTS" != "1" ]; then
  echo "-> Criando banco ${DB_NAME}..."
  psql_cmd -d postgres -c "CREATE DATABASE ${DB_NAME};"
else
  echo "-> Banco ${DB_NAME} ja existe."
fi

# --- 2) Restaura o dump completo (schema + dados já migrados) --------------
if [ "$SKIP_RESTORE" = false ]; then
  if [ ! -f "$DUMP_FILE" ]; then
    echo "ERRO: dump nao encontrado em ${DUMP_FILE}" >&2
    echo "Copie o WmaTravelERP.sql mais recente para database/scripts/ antes de rodar." >&2
    exit 1
  fi
  echo "-> Restaurando ${DUMP_FILE} (isso pode levar alguns minutos)..."
  psql_cmd -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$DUMP_FILE"
  echo "-> Restauracao concluida."
else
  echo "-> --skip-restore: pulando restauracao do dump."
fi

# --- 3) Validação opcional de auditoria -------------------------------------
if [ "$WITH_VALIDATION" = true ]; then
  echo "-> Rodando validacao funcional do log de auditoria..."
  psql_cmd -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "${SCRIPT_DIR}/audit/06_validar_log_auditoria.sql"
fi

echo "== Instalacao concluida =="
echo "Proximos passos recomendados:"
echo "  1. Conferir database/migrations/README.md - ha migracoes cujo script"
echo "     original nao esta versionado neste repositorio (ver pendencias)."
echo "  2. Rodar database/certification/ (quando os scripts da Etapa 10.4.x"
echo "     forem recuperados) para revalidar a certificacao estrutural."
