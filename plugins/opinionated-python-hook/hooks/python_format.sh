#!/usr/bin/env bash
set -u

uvx hatch fmt "$1" 1>&2
exit_code=$?
if [ $exit_code -eq 1 ]; then
    exit 2
else
    exit $exit_code
fi
