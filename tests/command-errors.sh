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

run_cmd() {
  STATUS=0
  OUT=""
  if OUT="$("$@" 2>&1)"; then
    STATUS=0
  else
    STATUS=$?
  fi
}

echo "TAP version 13"
echo "1..8"

run_cmd "$ROOT/bin/vscode-broom" --bogus
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects unknown flag"
else
  tap_not_ok "rejects unknown flag"
  tap_diag "exit status: $STATUS"
fi
expect_match "prints unknown flag error" "^error: Unknown flag: --bogus$"

run_cmd "$ROOT/bin/vscode-broom" banana
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects unexpected argument"
else
  tap_not_ok "rejects unexpected argument"
  tap_diag "exit status: $STATUS"
fi
expect_match "prints unexpected argument error" "^error: Unexpected argument: banana$"

run_cmd "$ROOT/bin/vscode-broom" extensions clean analyze
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects too many arguments"
else
  tap_not_ok "rejects too many arguments"
  tap_diag "exit status: $STATUS"
fi
expect_match "prints too many arguments error" "^error: Too many arguments: extensions$"
expect_match "prints too many arguments list (clean)" "^clean$"
expect_match "prints too many arguments list (analyze)" "^analyze$"

exit "$FAILURES"
