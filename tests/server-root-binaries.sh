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

mkdir -p "$HOME/.vscode-server" "$HOME/.vscode-server-insiders"

printf 'x' > "$HOME/.vscode-server/code-old"
printf 'x' > "$HOME/.vscode-server/code-new"
printf 'x' > "$HOME/.vscode-server-insiders/code-insiders-old"
printf 'x' > "$HOME/.vscode-server-insiders/code-insiders-new"

chmod +x \
  "$HOME/.vscode-server/code-old" \
  "$HOME/.vscode-server/code-new" \
  "$HOME/.vscode-server-insiders/code-insiders-old" \
  "$HOME/.vscode-server-insiders/code-insiders-new"

TZ=UTC touch -t 202401010000 "$HOME/.vscode-server/code-old"
TZ=UTC touch -t 202402010000 "$HOME/.vscode-server/code-new"
TZ=UTC touch -t 202301010000 "$HOME/.vscode-server-insiders/code-insiders-old"
TZ=UTC touch -t 202403010000 "$HOME/.vscode-server-insiders/code-insiders-new"

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

expect_match "prints server build section" "^Server build$"
expect_match "prints server root path" "~\\/\\.vscode-server$"
expect_match "prints server insiders root path" "~\\/\\.vscode-server-insiders$"
expect_match "prints 2 old server builds" "^Old server builds: 2"

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

if [[ ! -e "$HOME/.vscode-server/code-old" && -e "$HOME/.vscode-server/code-new" && ! -e "$HOME/.vscode-server-insiders/code-insiders-old" && -e "$HOME/.vscode-server-insiders/code-insiders-new" ]]; then
  tap_ok "removes old server binaries and keeps newest"
else
  tap_not_ok "removes old server binaries and keeps newest"
fi

exit "$FAILURES"
