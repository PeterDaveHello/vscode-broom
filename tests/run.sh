#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERBOSE=false
case "${1:-}" in
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
esac

require_cmd() {
  command -v "$1" > /dev/null 2>&1
}

require_test_deps() {
  local cmd
  for cmd in find sort mktemp; do
    if ! require_cmd "$cmd"; then
      echo "missing required command: $cmd" >&2
      exit 1
    fi
  done
}

require_test_deps

if command -v prove > /dev/null 2>&1; then
  args=()
  "$VERBOSE" && args+=("-v")
  mapfile -t tests < <(find "$ROOT/tests" -maxdepth 1 -type f -name '*.sh' ! -name 'run.sh' | sort)
  if prove "${args[@]}" "${tests[@]}"; then
    exit 0
  fi
  status=$?
  if ! "$VERBOSE"; then
    echo
    echo "Re-running failed tests with -v for diagnostics."
    prove -v "${tests[@]}" || true
  fi
  exit "$status"
fi

mapfile -t tests < <(find "$ROOT/tests" -maxdepth 1 -type f -name '*.sh' ! -name 'run.sh' | sort)

passed=0
failed=0
total=${#tests[@]}

for test in "${tests[@]}"; do
  name=$(basename "$test")
  if "$VERBOSE"; then
    echo "==> $name"
    if "$test" -v; then
      printf '%s: ok\n' "$name"
      ((++passed))
    else
      printf '%s: FAIL\n' "$name"
      ((++failed))
    fi
    echo
    continue
  fi

  OUT=""
  STATUS=0
  if OUT="$("$test" 2>&1)"; then
    STATUS=0
  else
    STATUS=$?
  fi

  if [[ $STATUS -eq 0 ]]; then
    printf '%s: ok\n' "$name"
    ((++passed))
  else
    printf '%s: FAIL (exit %d)\n' "$name" "$STATUS"
    printf '%s\n' "$OUT"
    ((++failed))
  fi
done

if ((failed == 0)); then
  printf 'tests: ok (%d/%d)\n' "$passed" "$total"
  exit 0
fi

printf 'tests: failed (%d/%d)\n' "$failed" "$total"
exit 1
