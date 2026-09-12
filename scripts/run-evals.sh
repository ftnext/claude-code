#!/usr/bin/env bash
# Run `claude plugin eval` for a plugin, then re-check every produced .py file
# with a real (non --fix) `hatch check` run from a plain copy of the kept temp dir.
#
# Usage: scripts/run-evals.sh <plugin-dir> [extra claude plugin eval args...]
set -u

plugin="${1:?usage: scripts/run-evals.sh <plugin-dir> [extra claude plugin eval args...]}"
shift
# Resolve to an absolute path up front: later hatch checks cd into a scratch
# copy dir, so a relative $plugin would stop resolving once we do.
plugin=$(cd "$plugin" && pwd)

timestamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
results_dir="$plugin/evals/results/$timestamp"
mkdir -p "$results_dir"
out="$results_dir/run-evals.json"
log="$results_dir/run-evals.log"

claude plugin eval "$plugin" --trust-plugin --no-publish --allow-tools Write Edit \
    --scaffold --keep-temp --json "$out" "$@" >"$log" 2>&1
eval_exit=$?
echo "claude plugin eval exit code: $eval_exit (log: $log)"

hatch="$plugin/hooks/hatch.sh"
hatch_failed=0
hatch_rows=()

kept_dirs=$(grep -o 'kept /private/tmp/e-[A-Za-z0-9]*' "$log" | awk '{print $2}')
# Kept dirs of the with-plugin arm, from the run JSON (tracePath lives inside the kept dir).
# Only these decide the exit code; the without-plugin ablation arm is shown as baseline.
with_dirs=$(jq -r '.cases[].arms.with[]?.tracePath // empty' "$out" 2>/dev/null | sed 's|/out/trace.jsonl$||')

for dir in $kept_dirs; do
    if printf '%s\n' "$with_dirs" | grep -qx "$dir"; then arm=with; else arm=without; fi
    chmod u+rx "$dir" "$dir/sealed" 2>/dev/null
    cwd="$dir/sealed/home/cwd"
    [ -d "$cwd" ] || { chmod -R u+rwx "$dir" 2>/dev/null; rm -rf "$dir"; continue; }

    copy_dir=$(mktemp -d)
    find "$cwd" -name '*.py' -exec cp {} "$copy_dir/" \;

    for f in "$copy_dir"/*.py; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        # Run with cwd = copy_dir and a relative filename: an absolute path
        # makes ruff misdetect the lone file as an implicit namespace package
        # (INP001) since there's no pyproject.toml above it.
        if (cd "$copy_dir" && "$hatch" check code "$name") >/dev/null 2>&1; then code_status=PASS; else code_status=FAIL; fi
        if (cd "$copy_dir" && "$hatch" check fmt "$name") >/dev/null 2>&1; then fmt_status=PASS; else fmt_status=FAIL; fi
        if [ "$arm" = with ]; then
            [ "$code_status" = FAIL ] && hatch_failed=1
            [ "$fmt_status" = FAIL ] && hatch_failed=1
        fi
        hatch_rows+=("$arm	$(basename "$dir")/$name	code=$code_status	fmt=$fmt_status")
    done

    rm -rf "$copy_dir"
    chmod -R u+rwx "$dir" 2>/dev/null
    rm -rf "$dir"
done

echo
echo "== Case scores =="
jq -r '.cases[] | "\(.name): \(.aggregates.score)"' "$out" 2>/dev/null

echo
echo "== Failing graders =="
jq -r '.cases[].arms.with[].graders[]? | select(.passed==false) | "\(.name): \(.explanation)"' "$out" 2>/dev/null

echo
echo "== hatch check (no --fix) on produced files (arm, run/file; only the with arm affects the exit code) =="
if [ "${#hatch_rows[@]}" -eq 0 ]; then
    echo "(no kept run dirs with .py files found)"
else
    printf '%s\n' "${hatch_rows[@]}" | column -t -s "$(printf '\t')"
fi

if [ "$eval_exit" -ne 0 ] || [ "$hatch_failed" -ne 0 ]; then
    exit 1
fi
exit 0
