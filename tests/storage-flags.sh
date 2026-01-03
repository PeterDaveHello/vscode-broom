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
echo "1..5"

mkdir -p \
  "$HOME/.vscode-server/data/CachedExtensionVSIXs" \
  "$HOME/.vscode-server/data/logs" \
  "$HOME/.vscode-server/data/User/workspaceStorage" \
  "$HOME/.vscode-server/data/User/globalStorage"

echo x > "$HOME/.vscode-server/data/logs/log"

OUT="$("$ROOT/bin/vscode-broom" caches clean --execute)"
if [[ -d "$HOME/.vscode-server/data/User/workspaceStorage" && -d "$HOME/.vscode-server/data/User/globalStorage" ]]; then
  tap_ok "default caches clean keeps storage"
else
  tap_not_ok "default caches clean keeps storage"
fi
expect_match "prints delete summary for default caches clean" "^Deleted 2 paths \\(reclaimed "

mkdir -p \
  "$HOME/.vscode-server/data/CachedExtensionVSIXs" \
  "$HOME/.vscode-server/data/logs"
echo x > "$HOME/.vscode-server/data/logs/log"

OUT="$("$ROOT/bin/vscode-broom" caches clean --include-workspace-storage --include-global-storage --execute)"
expect_match "prints delete summary for storage flags" "^Deleted 4 paths \\(reclaimed "
if [[ ! -d "$HOME/.vscode-server/data/User/workspaceStorage" && ! -d "$HOME/.vscode-server/data/User/globalStorage" ]]; then
  tap_ok "storage dirs removed when flags set"
else
  tap_not_ok "storage dirs removed when flags set"
fi
if [[ ! -d "$HOME/.vscode-server/data/CachedExtensionVSIXs" && ! -d "$HOME/.vscode-server/data/logs" ]]; then
  tap_ok "cache dirs removed when flags set"
else
  tap_not_ok "cache dirs removed when flags set"
fi

exit "$FAILURES"
