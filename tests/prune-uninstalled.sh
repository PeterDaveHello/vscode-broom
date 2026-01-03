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
echo "1..9"

mkdir -p \
  "$HOME/.vscode/extensions/extA-1.0" \
  "$HOME/.vscode/extensions/extB-1.0" \
  "$HOME/bin"

cat << 'EOF' > "$HOME/bin/code"
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--list-extensions" ]]; then
  echo "extA"
  exit 0
fi
exit 1
EOF
chmod +x "$HOME/bin/code"
export PATH="$HOME/bin:$PATH"

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" extensions clean --prune-uninstalled)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs prune-uninstalled dry-run"
else
  tap_not_ok "runs prune-uninstalled dry-run"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints Targets list" "^Targets:$"
expect_match "prints uninstalled extension" "extB-1\\.0"
expect_no_match "does not print installed extension" "extA-1\\.0"
expect_match "prints dry-run reminder" "^Dry-run only\\."

if [[ -d "$HOME/.vscode/extensions/extB-1.0" ]]; then
  tap_ok "dry-run keeps uninstalled extension dir"
else
  tap_not_ok "dry-run keeps uninstalled extension dir"
fi

STATUS=0
if OUT="$("$ROOT/bin/vscode-broom" extensions clean --prune-uninstalled --execute)"; then
  STATUS=0
else
  STATUS=$?
fi

if [[ $STATUS -eq 0 ]]; then
  tap_ok "runs prune-uninstalled --execute"
else
  tap_not_ok "runs prune-uninstalled --execute"
  tap_diag "exit status: $STATUS"
fi

expect_match "prints deleted path count is 1" "^Deleted 1 paths \\(reclaimed "
if [[ ! -d "$HOME/.vscode/extensions/extB-1.0" && -d "$HOME/.vscode/extensions/extA-1.0" ]]; then
  tap_ok "keeps installed extension and removes uninstalled"
else
  tap_not_ok "keeps installed extension and removes uninstalled"
fi

exit "$FAILURES"
