#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME"

TEST_NUM=0
FAILURES=0

tap_diag() {
  printf '# %s\n' "$*"
}

tap_ok() {
  local desc=$1
  ((++TEST_NUM))
  printf 'ok %d - %s\n' "$TEST_NUM" "$desc"
}

tap_not_ok() {
  local desc=$1
  ((++TEST_NUM))
  printf 'not ok %d - %s\n' "$TEST_NUM" "$desc"
  FAILURES=1
}

expect_match() {
  local desc=$1 pattern=$2
  if printf '%s\n' "$OUT" | grep -Eq "$pattern"; then
    tap_ok "$desc"
  else
    tap_not_ok "$desc"
    tap_diag "expected pattern: $pattern"
  fi
}

echo "TAP version 13"
echo "1..8"

mkdir -p "$HOME/.vscode"
mkdir -p "$HOME/.vscode-server/data"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" extensions -v)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs extensions -v"
else
  tap_not_ok "runs extensions -v"
  tap_diag "exit status: $STATUS"
fi

expect_match "extensions prints none message" "^Extension: none found under known roots\\.$"
expect_match "extensions prints missing list header" "^Missing extension paths:"
expect_match "extensions prints ~/.vscode/extensions path" "~\\/\\.vscode\\/extensions$"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" caches -v)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs caches -v"
else
  tap_not_ok "runs caches -v"
  tap_diag "exit status: $STATUS"
fi

expect_match "caches prints none message" "^Cache & Log: none found under known roots\\.$"
expect_match "caches prints missing list header" "^Missing cache paths:"
expect_match "caches prints ~/.vscode-server/data/logs path" "~\\/\\.vscode-server\\/data\\/logs$"

exit "$FAILURES"
