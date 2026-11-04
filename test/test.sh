#!/usr/bin/env bash
# Local test: runs scan.sh (the action's shell logic) against the sample folders with the real
# jidoseal CLI. Usage: test/test.sh [path-to-jidoseal-binary]   (installs jidoseal==0.1.5 if omitted)
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
cp -r "$here/examples/sample-gold" "$here/examples/sample-mixed" "$work/"
export JIDOSEAL_BIN="${1:-}"
fail=0
check() { # name, expected_exit, expected_tier, path, min
  local out="$work/out-$1"; : > "$out"
  GITHUB_OUTPUT="$out" INPUT_PATH="$4" INPUT_MIN_TIER="$5" bash "$here/scan.sh" > "$work/log-$1" 2>&1
  local rc=$? tier; tier="$(sed -n 's/^tier=//p' "$out")"
  if [ "$rc" = "$2" ] && [ "$tier" = "$3" ]; then echo "PASS $1 (exit $rc, tier $tier)"
  else echo "FAIL $1: exit $rc tier '$tier' (wanted $2 / $3)"; cat "$work/log-$1"; fail=1; fi
}
check gold-ok        0 gold   "$work/sample-gold"  gold
check mixed-none-ok  0 none   "$work/sample-mixed" none
check mixed-fails    1 none   "$work/sample-mixed" bronze
check bad-min        2 ""     "$work/sample-gold"  platinum
check bad-path       2 ""     "$work/nope"         none
exit $fail
