#!/usr/bin/env bash
# Run both plugins' python_format.sh hook on small fixtures and check the exit
# code and diagnostics. Each case runs in its own temp dir with a relative file
# name (an absolute path makes ruff report a bogus INP001).
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

# run_case <hook> <label> <fixture> <expected exit> [expected stderr text]
run_case() {
    local hook=$1 label=$2 fixture=$3 expected_exit=$4 expected_text=${5:-}
    local tmp actual_exit status=PASS
    tmp=$(mktemp -d) || exit 1
    printf '%b' "$fixture" > "$tmp/module.py"
    (cd "$tmp" && RUFF_CACHE_DIR="$tmp/ruff_cache" "$hook" module.py) 2> "$tmp/stderr" >/dev/null
    actual_exit=$?
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        status=FAIL
    elif [ -n "$expected_text" ] && ! grep -q "$expected_text" "$tmp/stderr"; then
        status=FAIL
    fi
    echo "$status  $label (exit $actual_exit, expected $expected_exit${expected_text:+ with $expected_text})"
    if [ "$status" = FAIL ]; then
        failed=1
        sed 's/^/    /' "$tmp/stderr"
    fi
    rm -rf "$tmp"
}

for plugin in opinionated-python-hook opinionated-python-agent; do
    hook="$repo/plugins/$plugin/hooks/python_format.sh"
    run_case "$hook" "$plugin: clean file" 'x = 1\n' 0
    run_case "$hook" "$plugin: unused async (preview rule)" 'async def f() -> int:\n    return 1\n' 2 RUF029
done

exit $failed
