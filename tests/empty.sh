#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME"

VERBOSE=false
case "${1:-}" in
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
esac

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

expect_no_match() {
  local desc=$1 pattern=$2
  if printf '%s\n' "$OUT" | grep -Eq "$pattern"; then
    tap_not_ok "$desc"
    tap_diag "unexpected pattern: $pattern"
  else
    tap_ok "$desc"
  fi
}

echo "TAP version 13"
echo "1..6"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom")"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs with empty HOME"
else
  tap_not_ok "runs with empty HOME"
  tap_diag "exit status: $STATUS"
fi

if "$VERBOSE" || [[ $STATUS -ne 0 ]]; then
  tap_diag "vscode-broom output:"
  while IFS= read -r line; do
    tap_diag "$line"
  done < <(printf '%s\n' "$OUT")
fi

expect_match "prints 'Detected: none'" "^Detected: none$"
expect_match "prints Summary section" "^Summary:$"
expect_match "prints empty summary message" "No VS Code data found under known roots\\.$"
expect_no_match "does not print any sections" "^(Server build|Extension|Cache & Log)$"
expect_no_match "does not print missing paths by default" "^Missing "

exit "$FAILURES"
