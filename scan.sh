#!/usr/bin/env bash
# Runs the JidoSeal Self-Check on one folder, on this machine, and reports the grade.
# v2: grades against OKF Folder Criteria v1.0.0 (jidoseal 0.2.0 or later).
# Inputs (environment): INPUT_PATH, INPUT_MIN_TIER (none|okf-certified|bronze|silver|gold), INPUT_VERSION.
# Optional: JIDOSEAL_BIN (use this command instead of installing from PyPI; used by the tests).
# Writes tier, criteria-version, score and the four coverage figures to $GITHUB_OUTPUT when set.
set -euo pipefail

path="${INPUT_PATH:-.}"
min_tier="${INPUT_MIN_TIER:-none}"
version="${INPUT_VERSION:-0.2.0}"

case "$min_tier" in none|okf-certified|bronze|silver|gold) ;; *)
  echo "::error::min-tier must be none, okf-certified, bronze, silver or gold (got '$min_tier')"; exit 2;; esac
[ -d "$path" ] || { echo "::error::path '$path' is not a folder"; exit 2; }

bin="${JIDOSEAL_BIN:-}"
if [ -z "$bin" ]; then
  venv="${RUNNER_TEMP:-$(mktemp -d)}/jidoseal-venv"
  python3 -m venv "$venv"
  "$venv/bin/pip" install --quiet "jidoseal==${version}"
  bin="$venv/bin/jidoseal"
fi

"$bin" --root "$path" --criteria 1.0.0

# The grade comes from the manifest the scan just wrote, not from the printed lines.
summary="$(python3 - "$path/.jidoseal/manifest.json" <<'PY'
import json, sys
try:
    c = json.load(open(sys.argv[1]))["corpus"]
    cov = c["coverage"]
    print(c["criteria_version"], c["grade"], c["score"],
          cov["okf-certified"], cov["bronze"], cov["silver"], cov["gold"])
except Exception:
    sys.exit(1)
PY
)" || { echo "::error::could not read the v1.0.0 grade from the manifest; jidoseal-version must be 0.2.0 or later"; exit 3; }
read -r criteria tier score okf bronze silver gold <<<"$summary"

rank() { case "$1" in none) echo 0;; okf-certified) echo 1;; bronze) echo 2;; silver) echo 3;; gold) echo 4;; esac; }

echo "Grade: $tier (criteria v$criteria; score $score; OKF Certified ${okf}%, Bronze ${bronze}%, Silver ${silver}%, Gold ${gold}%)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "tier=$tier"; echo "criteria-version=$criteria"; echo "score=$score"
    echo "okf-certified-coverage=$okf"; echo "bronze-coverage=$bronze"
    echo "silver-coverage=$silver"; echo "gold-coverage=$gold"
  } >> "$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  printf '### JidoSeal OKF quick check\n\nGrade: **%s** (OKF Folder Criteria v%s). Score %s. OKF Certified %s%%, Bronze %s%%, Silver %s%%, Gold %s%%.\n' \
    "$tier" "$criteria" "$score" "$okf" "$bronze" "$silver" "$gold" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$(rank "$tier")" -lt "$(rank "$min_tier")" ]; then
  echo "::error::folder reaches '$tier', below the required '$min_tier'"; exit 1
fi
