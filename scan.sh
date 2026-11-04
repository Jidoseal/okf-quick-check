#!/usr/bin/env bash
# Runs the JidoSeal Self-Check on one folder, on this machine, and reports the grade.
# Inputs (environment): INPUT_PATH, INPUT_MIN_TIER (none|bronze|silver|gold), INPUT_VERSION.
# Optional: JIDOSEAL_BIN (use this command instead of installing from PyPI; used by the tests).
# Writes tier / bronze-coverage / silver-coverage / gold-coverage to $GITHUB_OUTPUT when set.
set -euo pipefail

path="${INPUT_PATH:-.}"
min_tier="${INPUT_MIN_TIER:-none}"
version="${INPUT_VERSION:-0.1.5}"

case "$min_tier" in none|bronze|silver|gold) ;; *)
  echo "::error::min-tier must be none, bronze, silver or gold (got '$min_tier')"; exit 2;; esac
[ -d "$path" ] || { echo "::error::path '$path' is not a folder"; exit 2; }

bin="${JIDOSEAL_BIN:-}"
if [ -z "$bin" ]; then
  venv="${RUNNER_TEMP:-$(mktemp -d)}/jidoseal-venv"
  python3 -m venv "$venv"
  "$venv/bin/pip" install --quiet "jidoseal==${version}"
  bin="$venv/bin/jidoseal"
fi

out="$("$bin" --root "$path")"
printf '%s\n' "$out"

cov() { printf '%s\n' "$out" | sed -n "s/^[[:space:]]*$1[[:space:]]*coverage:[[:space:]]*\([0-9.]*\)%.*/\1/p" | head -1; }
bronze="$(cov Bronze)"; silver="$(cov Silver)"; gold="$(cov Gold)"
if [ -z "$bronze" ] || [ -z "$silver" ] || [ -z "$gold" ]; then
  echo "::error::could not read the coverage lines from the jidoseal output"; exit 3
fi

full() { [ "$(awk -v v="$1" 'BEGIN{print (v+0>=100)?1:0}')" = 1 ]; }
tier=none
full "$bronze" && tier=bronze
full "$bronze" && full "$silver" && tier=silver
full "$bronze" && full "$silver" && full "$gold" && tier=gold

rank() { case "$1" in none) echo 0;; bronze) echo 1;; silver) echo 2;; gold) echo 3;; esac; }

echo "Grade: $tier (Bronze ${bronze}%, Silver ${silver}%, Gold ${gold}%)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "tier=$tier"; echo "bronze-coverage=$bronze"
    echo "silver-coverage=$silver"; echo "gold-coverage=$gold"
  } >> "$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  printf '### JidoSeal OKF quick check\n\nGrade: **%s**. Bronze %s%%, Silver %s%%, Gold %s%%.\n' \
    "$tier" "$bronze" "$silver" "$gold" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$(rank "$tier")" -lt "$(rank "$min_tier")" ]; then
  echo "::error::folder reaches '$tier', below the required '$min_tier'"; exit 1
fi
