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

run_cmd() {
  local desc=$1
  shift

  STATUS=0
  if OUT="$("$@")"; then
    STATUS=0
  else
    STATUS=$?
  fi

  if [[ $STATUS -eq 0 ]]; then
    tap_ok "$desc"
  else
    tap_not_ok "$desc"
    tap_diag "exit status: $STATUS"
  fi

  if "$VERBOSE" || [[ $STATUS -ne 0 ]]; then
    tap_diag "command: $*"
    while IFS= read -r line; do
      tap_diag "$line"
    done < <(printf '%s\n' "$OUT")
  fi
}

count_matches() {
  local pattern=$1
  printf '%s\n' "$OUT" | grep -Ec "$pattern" || true
}

echo "TAP version 13"
echo "1..8"

# Fixture: extensions with one stale version
mkdir -p \
  "$HOME/.vscode/extensions/extA-1.0" \
  "$HOME/.vscode/extensions/extA-0.9"
TZ=UTC touch -t 202301010000 "$HOME/.vscode/extensions/extA-1.0"
TZ=UTC touch -t 202201010000 "$HOME/.vscode/extensions/extA-0.9"

run_cmd "analyze dedupes repeated --extensions-path" \
  "$ROOT/bin/vscode-broom" extensions \
  --extensions-path "$HOME/.vscode/extensions" \
  --extensions-path "$HOME/.vscode/extensions"

dir_lines=$(count_matches "^  .*~\\/.vscode\\/extensions$")
if [[ $dir_lines -eq 1 ]]; then
  tap_ok "prints extension root once"
else
  tap_not_ok "prints extension root once"
  tap_diag "matching lines: $dir_lines"
fi

if printf '%s\n' "$OUT" | grep -Eq "^Stale extension versions: 1 \\("; then
  tap_ok "stale version count is not double-counted"
else
  tap_not_ok "stale version count is not double-counted"
fi

stale_count=$(printf '%s\n' "$OUT" | sed -n 's/^Stale extension versions: \([0-9][0-9]*\).*/\1/p' | head -n1 || true)
if [[ "$stale_count" == "1" ]]; then
  tap_ok "extracts analyze stale count"
else
  tap_not_ok "extracts analyze stale count"
  tap_diag "stale_count: ${stale_count:-<empty>}"
fi

run_cmd "clean dedupes repeated --extensions-path (dry-run)" \
  "$ROOT/bin/vscode-broom" extensions clean \
  --extensions-path "$HOME/.vscode/extensions" \
  --extensions-path "$HOME/.vscode/extensions"

paths_count=$(printf '%s\n' "$OUT" | grep -E '^Reclaimable \(est\.\):' | grep -Eo '\([0-9]+ paths\)$' | head -n1 | tr -cd '0-9' || true)
if [[ "$paths_count" == "1" ]]; then
  tap_ok "extracts clean reclaimable path count"
else
  tap_not_ok "extracts clean reclaimable path count"
  tap_diag "paths_count: ${paths_count:-<empty>}"
fi

if [[ -n "$stale_count" && -n "$paths_count" && "$paths_count" == "$stale_count" ]]; then
  tap_ok "clean path count matches analyze stale count"
else
  tap_not_ok "clean path count matches analyze stale count"
  tap_diag "stale_count=$stale_count paths_count=$paths_count"
fi

if printf '%s\n' "$OUT" | grep -Eq "extA-0\\.9"; then
  tap_ok "clean output includes stale extension path"
else
  tap_not_ok "clean output includes stale extension path"
fi

exit "$FAILURES"
