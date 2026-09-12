#!/usr/bin/env bash
set -u

hatch="$(dirname "$0")/hatch.sh"

"$hatch" check code --fix "$1" 1>&2
code_exit=$?
"$hatch" check fmt --fix "$1" 1>&2
fmt_exit=$?

if [ $code_exit -eq 1 ] || [ $fmt_exit -eq 1 ]; then
    exit 2
elif [ $code_exit -ne 0 ]; then
    exit $code_exit
else
    exit $fmt_exit
fi
