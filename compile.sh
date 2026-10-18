#!/usr/bin/env bash
# ============================================================================
# ./compile.sh — the only command you need.
#
#   ./compile.sh               refresh snapshots, compile notes, build the site
#   ./compile.sh --dev         same, then start the dev server
#   ./compile.sh --no-build    refresh snapshots + compile notes only
#   ./compile.sh --check       verify that sources/ matches your live documents
#                              (cheap: no typst, no build — used by pre-push)
#
# Compilation always happens from sources/<slug>.typ, the committed snapshot,
# never from the project checkout. The typst binary is pinned in blog.toml and
# downloaded into .tools/ on first run.
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  --check)
    exec python3 scripts/compile.py --check
    ;;
  --no-build)
    exec python3 scripts/compile.py
    ;;
esac

if [ ! -d node_modules ]; then
  echo "==> installing dependencies"
  pnpm install
fi

case "${1:-}" in
  --dev)
    exec pnpm dev
    ;;
  -h|--help)
    sed -n '2,12p' "$0"
    ;;
  "")
    exec pnpm build
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 2
    ;;
esac
