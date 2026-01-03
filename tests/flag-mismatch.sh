#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME"

EXT_DIR="$HOME/ext-dir"
CONFIG_DIR="$HOME/config-dir"
HOST_DIR="$HOME/host-dir"
mkdir -p "$EXT_DIR" "$CONFIG_DIR" "$HOST_DIR"

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
echo "1..10"

run_cmd "$ROOT/bin/vscode-broom" extensions --include-workspace-storage
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects cache flags with extensions target"
else
  tap_not_ok "rejects cache flags with extensions target"
fi
expect_match "prints cache/target mismatch" "^error: Cache flags used while target is extensions$"

run_cmd "$ROOT/bin/vscode-broom" caches --extensions-path "$EXT_DIR"
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects extension flags with caches target"
else
  tap_not_ok "rejects extension flags with caches target"
fi
expect_match "prints extension/target mismatch" "^error: Extension flags used while target is caches$"

run_cmd "$ROOT/bin/vscode-broom" hosts --prune-uninstalled
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects extension flags with hosts target"
else
  tap_not_ok "rejects extension flags with hosts target"
fi
expect_match "prints hosts/extension mismatch" "^error: Extension flags used while target is hosts$"

run_cmd "$ROOT/bin/vscode-broom" extensions --host-path "$HOST_DIR"
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects host flags with extensions target"
else
  tap_not_ok "rejects host flags with extensions target"
fi
expect_match "prints host/target mismatch" "^error: Host flags used while target is extensions$"

run_cmd "$ROOT/bin/vscode-broom" caches --host-path "$HOST_DIR"
if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects host flags with caches target"
else
  tap_not_ok "rejects host flags with caches target"
fi
expect_match "prints host/target mismatch (caches)" "^error: Host flags used while target is caches$"

exit "$FAILURES"
