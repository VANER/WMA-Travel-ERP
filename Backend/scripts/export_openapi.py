"""Exporta ou verifica o contrato OpenAPI versionado."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

# A geração do schema não executa operações criptográficas.
os.environ.setdefault("WMA_TOKEN_SIGNING_KEY", "openapi-export-only-not-a-runtime-secret")

from app.main import app

OPENAPI_PATH = Path(__file__).resolve().parents[1] / "openapi.json"


def render_openapi() -> str:
    """Serializa o contrato de forma determinística."""
    return json.dumps(app.openapi(), ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> int:
    """Atualiza o snapshot ou verifica se ele acompanha a aplicação."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="falha quando o snapshot versionado diverge da aplicação",
    )
    args = parser.parse_args()
    rendered = render_openapi()

    if args.check:
        if not OPENAPI_PATH.exists() or OPENAPI_PATH.read_text(encoding="utf-8") != rendered:
            print("Contrato OpenAPI desatualizado. Execute: python scripts/export_openapi.py")
            return 1
        print("Contrato OpenAPI sincronizado.")
        return 0

    OPENAPI_PATH.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Contrato OpenAPI exportado para {OPENAPI_PATH}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
