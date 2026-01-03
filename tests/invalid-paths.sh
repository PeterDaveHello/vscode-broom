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
echo "1..22"

echo "x" > "$HOME/not-a-dir"
ln -s / "$HOME/root-link"

run_cmd() {
  STATUS=0
  OUT=""
  if OUT="$("$@" 2>&1)"; then
    STATUS=0
  else
    STATUS=$?
  fi
}

run_cmd "$ROOT/bin/vscode-broom" extensions --extensions-path "$HOME/not-a-dir"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects non-directory --extensions-path"
else
  tap_not_ok "rejects non-directory --extensions-path"
fi

expect_match "prints directory error" "^error: --extensions-path requires an existing directory: "

run_cmd "$ROOT/bin/vscode-broom" extensions --extensions-path "$HOME"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects unsafe --extensions-path"
else
  tap_not_ok "rejects unsafe --extensions-path"
fi

expect_match "prints unsafe path error" "^error: --extensions-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" extensions --extensions-path "$HOME/.."

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects parent --extensions-path"
else
  tap_not_ok "rejects parent --extensions-path"
fi

expect_match "prints parent unsafe path error" "^error: --extensions-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" extensions --extensions-path /

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects root --extensions-path"
else
  tap_not_ok "rejects root --extensions-path"
fi

expect_match "prints extensions root unsafe path error" "^error: --extensions-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" extensions --extensions-path "$HOME/root-link"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects symlinked root --extensions-path"
else
  tap_not_ok "rejects symlinked root --extensions-path"
fi

expect_match "prints extensions symlink unsafe path error" "^error: --extensions-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" caches --config-path "$HOME/not-a-dir"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects non-directory --config-path"
else
  tap_not_ok "rejects non-directory --config-path"
fi

expect_match "prints config directory error" "^error: --config-path requires an existing directory: "

run_cmd "$ROOT/bin/vscode-broom" caches --config-path "$HOME"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects unsafe --config-path"
else
  tap_not_ok "rejects unsafe --config-path"
fi

expect_match "prints config unsafe path error" "^error: --config-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" caches --config-path /

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects root --config-path"
else
  tap_not_ok "rejects root --config-path"
fi

expect_match "prints config root unsafe path error" "^error: --config-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" hosts --host-path "$HOME/not-a-dir"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects non-directory --host-path"
else
  tap_not_ok "rejects non-directory --host-path"
fi

expect_match "prints host directory error" "^error: --host-path requires an existing directory: "

run_cmd "$ROOT/bin/vscode-broom" hosts --host-path "$HOME"

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects unsafe --host-path"
else
  tap_not_ok "rejects unsafe --host-path"
fi

expect_match "prints host unsafe path error" "^error: --host-path refuses to use unsafe path: "

run_cmd "$ROOT/bin/vscode-broom" hosts --host-path /

if [[ $STATUS -ne 0 ]]; then
  tap_ok "rejects root --host-path"
else
  tap_not_ok "rejects root --host-path"
fi

expect_match "prints host root unsafe path error" "^error: --host-path refuses to use unsafe path: "

exit "$FAILURES"
