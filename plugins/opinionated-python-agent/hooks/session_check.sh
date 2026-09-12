#!/usr/bin/env bash
set -u

if command -v uvx >/dev/null 2>&1; then
    exit 0
fi

cat 1>&2 <<'MSG'
uvx not found. The Python formatter hook runs hatch through uvx and will fail until uv is installed:
https://docs.astral.sh/uv/getting-started/installation/
MSG
exit 1
