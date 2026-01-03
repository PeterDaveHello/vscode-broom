#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_BIN="$TMP_HOME/bin"
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
echo "1..4"

mkdir -p \
  "$HOME/.vscode-oss/extensions/extA-1.0" \
  "$HOME/.vscode-oss/extensions/extA-0.9"

mkdir -p "$TMP_BIN"
for tool in awk bash du find head numfmt rm sort tail; do
  ln -s "$(command -v "$tool")" "$TMP_BIN/$tool"
done

STATUS=0
if OUT="$(PATH="$TMP_BIN" "$ROOT/bin/vscode-broom" extensions --prune-uninstalled)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs prune-uninstalled without OSS CLI"
else
  tap_not_ok "runs prune-uninstalled without OSS CLI"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints prune skip message for missing codium/code-oss" "^Prune-uninstalled skipped for 1 scope \\(use -v for details\\)\\.$"
expect_match "prints Extension section" "^Extension$"
expect_match "prints stale extension versions" "^Stale extension versions: 1"

exit "$FAILURES"
