#!/usr/bin/env bash
# ============================================================================
# ./compile.sh — the only command you need.
#
#   ./compile.sh               refresh snapshots, compile what changed, build the site
#   ./compile.sh --dev         same, then start the dev server
#   ./compile.sh --no-build    refresh snapshots + compile notes only
#   ./compile.sh --no-cache    ignore the note cache and recompile everything
#   ./compile.sh --check       verify that sources/ matches your live documents
#                              (cheap: no typst, no build — used by pre-push)
#
# Compilation always happens from sources/<slug>.typ, the committed snapshot,
# never from the project checkout. The typst binary is pinned in blog.toml and
# downloaded into .tools/ on first run. Compiled artifacts are cached in .cache/
# (machine-local, never committed), so unchanged notes are not recompiled.
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
    sed -n '2,/^# ====/p' "$0"
    ;;
  "")
    exec pnpm build
    ;;
  --no-cache)
    python3 scripts/compile.py --no-cache
    exec pnpm build
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 2
    ;;
esac
