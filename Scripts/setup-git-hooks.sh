#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
git -C "$root" config --local core.hooksPath .githooks
printf '%s\n' 'Enabled repository commit hooks.'
