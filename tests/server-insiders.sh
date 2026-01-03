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
echo "1..7"

mkdir -p \
  "$HOME/.vscode-server-insiders/cli/servers/Insiders-new" \
  "$HOME/.vscode-server-insiders/cli/servers/Insiders-old"
TZ=UTC touch -t 202401010000 "$HOME/.vscode-server-insiders/cli/servers/Insiders-new"
TZ=UTC touch -t 202101010000 "$HOME/.vscode-server-insiders/cli/servers/Insiders-old"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" hosts)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs hosts analyze"
else
  tap_not_ok "runs hosts analyze"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints server insiders variant" "VS Code Server Insiders"
expect_match "prints server build section" "^Server build$"
expect_match "prints insiders server builds path" "~\\/\\.vscode-server-insiders\\/cli\\/servers$"
expect_match "prints 1 old server build" "^Old server builds: 1"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" hosts clean --execute)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs hosts clean --execute"
else
  tap_not_ok "runs hosts clean --execute"
  tap_diag "exit status: $STATUS"
fi

if [[ ! -d "$HOME/.vscode-server-insiders/cli/servers/Insiders-old" && -d "$HOME/.vscode-server-insiders/cli/servers/Insiders-new" ]]; then
  tap_ok "removes old build and keeps newest"
else
  tap_not_ok "removes old build and keeps newest"
fi

exit "$FAILURES"
