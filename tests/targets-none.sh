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

echo "TAP version 13"
echo "1..15"

run_cmd "runs hosts analyze with empty HOME" "$ROOT/bin/vscode-broom" hosts
expect_match "hosts prints section message" "^Server build: none found under known roots\\.$"
expect_match "hosts prints Summary section" "^Summary:$"
expect_match "hosts prints empty summary message" "No server build data found under known roots\\.$"
expect_no_match "hosts does not print other sections" "^(Extension|Cache & Log)$"

run_cmd "runs extensions analyze with empty HOME" "$ROOT/bin/vscode-broom" extensions
expect_match "extensions prints section message" "^Extension: none found under known roots\\.$"
expect_match "extensions prints Summary section" "^Summary:$"
expect_match "extensions prints empty summary message" "No extension data found under known roots\\.$"
expect_no_match "extensions does not print other sections" "^(Server build|Cache & Log)$"

run_cmd "runs caches analyze with empty HOME" "$ROOT/bin/vscode-broom" caches
expect_match "caches prints section message" "^Cache & Log: none found under known roots\\.$"
expect_match "caches prints Summary section" "^Summary:$"
expect_match "caches prints empty summary message" "No cache/log data found under known roots\\.$"
expect_no_match "caches does not print other sections" "^(Server build|Extension)$"

exit "$FAILURES"
