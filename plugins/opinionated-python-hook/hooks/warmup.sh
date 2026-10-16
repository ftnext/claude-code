#!/usr/bin/env bash
# Pre-build the hatch environments in the background so the first Python edit
# is not slow. hatch keys its environments by project directory, so this must
# run from the project (the hook's cwd); only the throwaway file and ruff's
# cache go to a temp dir, keeping the project free of .ruff_cache.
set -u

command -v uvx >/dev/null 2>&1 || exit 0

hatch="$(cd "$(dirname "$0")" && pwd)/hatch.sh"
tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT

printf 'x = 1\n' > "$tmp/warmup.py"
export RUFF_CACHE_DIR="$tmp/ruff_cache"
"$hatch" check code --preview "$tmp/warmup.py" >/dev/null 2>&1
"$hatch" check fmt "$tmp/warmup.py" >/dev/null 2>&1
exit 0
