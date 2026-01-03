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
echo "1..5"

mkdir -p \
  "$HOME/.vscode-server/cli/servers/build same a" \
  "$HOME/.vscode-server/cli/servers/build same b"

TZ=UTC touch -t 202401010000 "$HOME/.vscode-server/cli/servers/build same a"
TZ=UTC touch -t 202401010000 "$HOME/.vscode-server/cli/servers/build same b"

STATUS=0
OUT=""
if OUT="$("$ROOT/bin/vscode-broom" hosts clean 2>&1)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs hosts clean (dry-run)"
else
  tap_not_ok "runs hosts clean (dry-run)"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints Targets list" "^Targets:$"
expect_match "prints stale build same b when mtimes tie" "build same b"
expect_no_match "does not print build same a when mtimes tie" "build same a"
expect_match "prints dry-run reminder" "^Dry-run only\\.$"

exit "$FAILURES"
