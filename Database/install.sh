#!/usr/bin/env bash
# =============================================================================
# WMA Travel ERP - install.sh
# Reconstrói o banco a partir do dump histórico e da evolução F1-FIN.
#
# Fonte oficial:
#   scripts/WmaTravelERP.sql
#
# O dump contém a baseline histórica certificada. A evolução financeira
# posterior é aplicada uma única vez pelos scripts F1-FIN.04 a F1-FIN.11.
# Não reaplicar migrations históricas além da sequência controlada abaixo.
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
#   ./install.sh --skip-financial
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
SKIP_FINANCIAL=false
WITH_VALIDATION=false

for arg in "$@"; do
  case "$arg" in
    --skip-restore)
      SKIP_RESTORE=true
      ;;
    --skip-financial)
      SKIP_FINANCIAL=true
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

# --- 3) Evolução financeira da Fase 1 ----------------------------------------

if [ "$SKIP_FINANCIAL" = false ]; then
  FINANCIAL_DIR="${SCRIPT_DIR}/scripts/F1_FIN"
  FINANCIAL_FILES=(
    "F1_FIN_04_CORRECOES_MINIMAS.sql"
    "F1_FIN_05_PLANO_CONTAS_CLASSIFICACOES.sql"
    "F1_FIN_06_AP_AR_PARCELAMENTOS.sql"
    "F1_FIN_07_CAIXA_BANCOS_CARTOES_TRANSFERENCIAS.sql"
    "F1_FIN_08_RATEIOS_CENTROS_CUSTO.sql"
    "F1_FIN_09_CONCILIACAO_MOVIMENTACAO.sql"
    "F1_FIN_10_CAPITAL_AFAC_PRO_LABORE_LUCROS.sql"
    "F1_FIN_11_TRIBUTOS_EMPRESTIMOS_IMOBILIZADO.sql"
  )

  echo "-> Aplicando evolucao financeira certificada da Fase 1..."

  for financial_file in "${FINANCIAL_FILES[@]}"; do
    financial_path="${FINANCIAL_DIR}/${financial_file}"

    if [ ! -f "$financial_path" ]; then
      echo "ERRO: script financeiro nao encontrado:" >&2
      echo "  ${financial_path}" >&2
      exit 1
    fi

    echo "  ${financial_file}"
    psql_cmd \
      -d "$DB_NAME" \
      -v ON_ERROR_STOP=1 \
      -v expected_database="$DB_NAME" \
      -f "$financial_path"
  done

  echo "-> Evolucao financeira concluida."
else
  echo "-> --skip-financial: evolucao financeira ignorada."
fi

# --- 4) Validação opcional ---------------------------------------------------

if [ "$WITH_VALIDATION" = true ]; then

  VALIDATION_FILE="${SCRIPT_DIR}/audit/06_validar_log_auditoria.sql"

  if [ ! -f "$VALIDATION_FILE" ]; then
    echo "ERRO: validacao solicitada, mas o arquivo nao existe:" >&2
    echo "  ${VALIDATION_FILE}"
    exit 1
  else
    echo "-> Executando validacao:"
    echo "  ${VALIDATION_FILE}"

    psql_cmd \
      -d "$DB_NAME" \
      -v ON_ERROR_STOP=1 \
      -f "$VALIDATION_FILE"

    for certification_file in \
      "${SCRIPT_DIR}/scripts/F1_FIN/F1_FIN_12_AUDITORIA_INTEGRIDADE_FINANCEIRA.sql" \
      "${SCRIPT_DIR}/scripts/F1_FIN/F1_FIN_13_CERTIFICACAO_ESTRUTURAL_FINANCEIRO.sql"; do
      if [ ! -f "$certification_file" ]; then
        echo "ERRO: certificacao financeira nao encontrada:" >&2
        echo "  ${certification_file}" >&2
        exit 1
      fi

      psql_cmd \
        -d "$DB_NAME" \
        -v ON_ERROR_STOP=1 \
        -v expected_database="$DB_NAME" \
        -f "$certification_file"
    done

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
