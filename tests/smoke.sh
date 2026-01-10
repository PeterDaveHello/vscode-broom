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
OUT_DIAGGED=false

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
    dump_out_once
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

expect_no_substring() {
  local desc=$1 needle=$2
  if [[ "$OUT" == *"$needle"* ]]; then
    tap_not_ok "$desc"
    tap_diag "unexpected substring: $needle"
  else
    tap_ok "$desc"
  fi
}

line_no() {
  local pattern=$1
  local line
  line=$(printf '%s\n' "$OUT" | grep -En "$pattern" | head -n1 | cut -d: -f1 || true)
  printf '%s' "${line:-0}"
}

dump_out_once() {
  if "$OUT_DIAGGED"; then
    return
  fi
  OUT_DIAGGED=true
  tap_diag "output (first 50 lines):"
  local line_count=0
  while IFS= read -r line; do
    tap_diag "$line"
    ((line_count++))
    if ((line_count >= 50)); then
      tap_diag "... (truncated)"
      break
    fi
  done < <(printf '%s\n' "$OUT")
}

run_target_analyze_test() {
  local target=$1

  OUT_DIAGGED=false
  STATUS=0
  if OUT="$("$ROOT/bin/vscode-broom" "$target")"; then
    STATUS=0
  else
    STATUS=$?
  fi
  if [[ $STATUS -eq 0 ]]; then
    tap_ok "runs ${target} analyze"
  else
    tap_not_ok "runs ${target} analyze"
    tap_diag "exit status: $STATUS"
  fi
  if "$VERBOSE" || [[ $STATUS -ne 0 ]]; then
    tap_diag "command: $ROOT/bin/vscode-broom $target"
    while IFS= read -r line; do
      tap_diag "$line"
    done < <(printf '%s\n' "$OUT")
    OUT_DIAGGED=true
  fi
  expect_match "${target} analyze prints Summary section" "^Summary:$"
  expect_match "${target} analyze prints reclaimable summary" "^  Reclaimable \\(est\\.\\): [0-9]+"
}

# Fixture: extensions with one stale version
mkdir -p \
  "$HOME/.vscode/extensions/extA-1.0" \
  "$HOME/.vscode/extensions/extA-0.9"
TZ=UTC touch -t 202301010000 "$HOME/.vscode/extensions/extA-1.0"
TZ=UTC touch -t 202201010000 "$HOME/.vscode/extensions/extA-0.9"

# Fixture: server builds with one stale
mkdir -p \
  "$HOME/.vscode-server/cli/servers/Stable-new" \
  "$HOME/.vscode-server/cli/servers/Stable-old"
TZ=UTC touch -t 202401010000 "$HOME/.vscode-server/cli/servers/Stable-new"
TZ=UTC touch -t 202101010000 "$HOME/.vscode-server/cli/servers/Stable-old"

# Fixture: caches
mkdir -p \
  "$HOME/.vscode-server/data/CachedExtensionVSIXs" \
  "$HOME/.vscode-server/data/logs"
echo x > "$HOME/.vscode-server/data/CachedExtensionVSIXs/dummy"
echo x > "$HOME/.vscode-server/data/logs/log"

mkdir -p \
  "$HOME/.vscode-server/data/User/workspaceStorage" \
  "$HOME/.vscode-server/data/User/globalStorage"
echo x > "$HOME/.vscode-server/data/User/workspaceStorage/w"
echo x > "$HOME/.vscode-server/data/User/globalStorage/g"

echo "TAP version 13"
echo "1..32"

OUT_DIAGGED=false
STATUS=0
if OUT="$("$ROOT/bin/vscode-broom")"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs vscode-broom"
else
  tap_not_ok "runs vscode-broom"
  tap_diag "exit status: $STATUS"
fi

if "$VERBOSE" || [[ $STATUS -ne 0 ]]; then
  tap_diag "vscode-broom output:"
  while IFS= read -r line; do
    tap_diag "$line"
  done < <(printf '%s\n' "$OUT")
fi

expect_match "prints Detected section" "^Detected:"
expect_no_substring "does not print temp HOME path" "$TMP_HOME"
expect_match "prints paths with '~/'" "~\\/"

expect_match "prints Server build section" "^Server build$"
expect_match "prints 1 old server build" "^Old server builds: 1"

expect_match "prints Extension section" "^Extension$"
expect_match "prints 1 stale extension version" "^Stale extension versions: 1"

expect_match "prints Cache & Log section" "^Cache & Log$"
expect_match "prints Summary section" "^Summary:$"
expect_match "prints Summary reclaimable total" "^  Reclaimable \\(est\\.\\): [0-9]+"
expect_no_match "does not print missing paths by default" "^Missing "

server_line=$(line_no "^Server build$")
ext_line=$(line_no "^Extension$")
cache_line=$(line_no "^Cache & Log$")
summary_line=$(line_no "^Summary:$")
if ((server_line > 0 && ext_line > 0 && cache_line > 0 && summary_line > 0 && server_line < ext_line && ext_line < cache_line && cache_line < summary_line)); then
  tap_ok "orders sections server -> extension -> cache -> summary"
else
  tap_not_ok "orders sections server -> extension -> cache -> summary"
  tap_diag "line numbers: server=$server_line extension=$ext_line cache=$cache_line summary=$summary_line"
fi

run_target_analyze_test "hosts"
run_target_analyze_test "extensions"
run_target_analyze_test "caches"

OUT_DIAGGED=false
STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" clean)"; then
  STATUS=0
else
  STATUS=$?
fi
if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs clean (dry-run)"
else
  tap_not_ok "runs clean (dry-run)"
  tap_diag "exit status: $STATUS"
fi

expect_match "clean output prints Targets list" "^Targets:"
expect_match "clean output prints stale extension dir" "extA-0\\.9"
expect_match "clean output prints stale server build dir" "Stable-old"
expect_match "clean output prints cache dirs" "CachedExtensionVSIXs"
expect_match "clean output prints dry-run reminder" "^Dry-run only\\."

if [[ -d "$HOME/.vscode/extensions/extA-0.9" && -d "$HOME/.vscode-server/cli/servers/Stable-old" && -d "$HOME/.vscode-server/data/CachedExtensionVSIXs" && -d "$HOME/.vscode-server/data/logs" ]]; then
  tap_ok "dry-run does not delete targets"
else
  tap_not_ok "dry-run does not delete targets"
fi

OUT_DIAGGED=false
STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" clean --execute)"; then
  STATUS=0
else
  STATUS=$?
fi
if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs clean --execute"
else
  tap_not_ok "runs clean --execute"
  tap_diag "exit status: $STATUS"
fi

expect_match "clean --execute prints deleted paths" "^Deleted 4 paths \\(reclaimed "

if [[ ! -d "$HOME/.vscode/extensions/extA-0.9" && -d "$HOME/.vscode/extensions/extA-1.0" && ! -d "$HOME/.vscode-server/cli/servers/Stable-old" && -d "$HOME/.vscode-server/cli/servers/Stable-new" && ! -d "$HOME/.vscode-server/data/CachedExtensionVSIXs" && ! -d "$HOME/.vscode-server/data/logs" && -d "$HOME/.vscode-server/data/User/workspaceStorage" && -d "$HOME/.vscode-server/data/User/globalStorage" ]]; then
  tap_ok "clean deletes stale items and keeps safe storage"
else
  tap_not_ok "clean deletes stale items and keeps safe storage"
fi

exit "$FAILURES"
