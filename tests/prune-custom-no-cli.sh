#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_BIN="$TMP_HOME/bin"
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME"

CUSTOM_EXT="$HOME/custom/extensions"
mkdir -p "$CUSTOM_EXT/extA-1.0"

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
echo "1..4"

mkdir -p "$TMP_BIN"
for tool in awk bash du find head numfmt rm sort tail; do
  ln -s "$(command -v "$tool")" "$TMP_BIN/$tool"
done

STATUS=0
OUT=""
if OUT="$(PATH="$TMP_BIN" "$ROOT/bin/vscode-broom" extensions clean --prune-uninstalled --extensions-path "$CUSTOM_EXT" 2>&1)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -ne 0 ]]; then
  tap_ok "fails when custom extensions root lacks CLI"
else
  tap_not_ok "fails when custom extensions root lacks CLI"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints CLI missing error" "not found; --prune-uninstalled requires the VS Code CLI"
expect_no_match "does not print prune skip message" "^Prune-uninstalled skipped"
expect_no_match "does not print deletions" "^Deleted "

exit "$FAILURES"
