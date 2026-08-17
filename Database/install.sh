#!/usr/bin/env bash
# =============================================================================
# WMA Travel ERP - install.sh
# Reconstrói o banco de dados a partir do dump completo.
#
# Fonte oficial:
#   scripts/WmaTravelERP.sql
#
# O dump completo já contém a estrutura e os dados correspondentes ao estado
# exportado. Não reaplicar migrations sobre um dump já restaurado.
#
# Diretórios:
#   scripts/        -> dumps e scripts SQL
#   audit/          -> validações de auditoria
#   baseline/       -> referências estruturais
#   migrations/     -> histórico de migrações
#   certification/ -> certificações
#
# Uso:
#   ./install.sh
#   ./install.sh --skip-restore
#   ./install.sh --with-validation
#   ./install.sh --help
# =============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-wma_staging}"
DB_USER="${DB_USER:-postgres}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_FILE="${SCRIPT_DIR}/scripts/WmaTravelERP.sql"

SKIP_RESTORE=false
WITH_VALIDATION=false

for arg in "$@"; do
  case "$arg" in
    --skip-restore)
      SKIP_RESTORE=true
      ;;
    --with-validation)
      WITH_VALIDATION=true
      ;;
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
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "Banco: ${DB_NAME}"
echo "Usuario: ${DB_USER}"
echo "Diretorio: ${SCRIPT_DIR}"
echo "Dump: ${DUMP_FILE}"

psql_cmd() {
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"
}

# --- 1) Criar banco se não existir -------------------------------------------

DB_EXISTS="$(
  psql_cmd -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'"
)"

if [ "$DB_EXISTS" != "1" ]; then
  echo "-> Criando banco ${DB_NAME}..."
  psql_cmd -d postgres -c "CREATE DATABASE ${DB_NAME};"
else
  echo "-> Banco ${DB_NAME} ja existe."
fi

# --- 2) Restaurar dump completo ----------------------------------------------

if [ "$SKIP_RESTORE" = false ]; then

  if [ ! -f "$DUMP_FILE" ]; then
    echo "ERRO: dump nao encontrado:" >&2
    echo "  ${DUMP_FILE}" >&2
    exit 1
  fi

  echo "-> Restaurando dump completo..."
  echo "-> ${DUMP_FILE}"

  psql_cmd \
    -d "$DB_NAME" \
    -v ON_ERROR_STOP=1 \
    -f "$DUMP_FILE"

  echo "-> Restauracao concluida."

else
  echo "-> --skip-restore: restauracao ignorada."
fi

# --- 3) Validação opcional ---------------------------------------------------

if [ "$WITH_VALIDATION" = true ]; then

  VALIDATION_FILE="${SCRIPT_DIR}/audit/06_validar_log_auditoria.sql"

  if [ ! -f "$VALIDATION_FILE" ]; then
    echo "AVISO: validacao solicitada, mas o arquivo nao existe:"
    echo "  ${VALIDATION_FILE}"
    echo "-> Nenhuma validacao adicional executada."
  else
    echo "-> Executando validacao:"
    echo "  ${VALIDATION_FILE}"

    psql_cmd \
      -d "$DB_NAME" \
      -v ON_ERROR_STOP=1 \
      -f "$VALIDATION_FILE"

    echo "-> Validacao concluida."
  fi
fi

echo ""
echo "== Instalacao concluida =="
echo "Banco: ${DB_NAME}"
echo "Dump utilizado: scripts/WmaTravelERP.sql"
echo ""
echo "Estrutura Database:"
echo "  scripts/"
echo "  audit/"
echo "  baseline/"
echo "  migrations/"
echo "  certification/"
