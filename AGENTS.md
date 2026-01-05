# Repository Guidelines

## Dos and Don'ts

- Do keep `clean` as a dry-run unless `--execute` is set.
- Do keep path safety checks when adding new path flags; `validate_user_dir` rejects `/` and `$HOME`.
- Do update `usage()` output and related tests when adding or renaming flags; CLI output is asserted.
- Do keep changes minimal; avoid large reformatting or unrelated refactors.
- Do run `./tests/run.sh` locally after changes; CI does not replace local runs.
- Don't loosen deletion safeguards or root-path checks without explicit discussion.
- Don't add dependencies or broaden deletion scope without discussion.

## Project Structure & Module Organization

- `bin/vscode-broom`: main CLI (bash) that inspects and cleans VS Code artifacts.
- `tests/*.sh`: TAP-style shell tests.
- `README.md`: user-facing usage and behavior notes.

## Architecture Overview

- Single-file bash CLI that handles argument parsing, auto-detection of VS Code paths, and cleanup logic.
- `tests/run.sh` discovers and runs all test scripts under `tests/`.

## Requirements

- bash >= 4
- findutils (`find`)
- coreutils (`du`, `sort`, `numfmt`, `rm`, `tail`, `mktemp`)
- awk
- VS Code CLI is required only for `--prune-uninstalled`

## Build, Test, and Development Commands

- No build step. Run locally: `./bin/vscode-broom` or `./bin/vscode-broom -h`.
- First-time setup: `chmod +x ./bin/vscode-broom`.
- Dry-run clean: `./bin/vscode-broom clean`.
- Apply clean: `./bin/vscode-broom clean --execute`.
- Run all tests: `./tests/run.sh` (uses `prove` if available).
- Verbose test output: `./tests/run.sh -v`.
- Run a single test: `./tests/smoke.sh`.
- Lint:
  - `shellcheck bin/vscode-broom`
  - `rg --files -g '*.sh' | xargs shellcheck`

## Coding Style & Naming Conventions

- Scripts use `#!/usr/bin/env bash`.
- CLI uses `set -uo pipefail` and `IFS=$'\n\t'`; tests use `set -euo pipefail`.
- Indentation: 2 spaces.
- Use `snake_case` for functions/vars; UPPER_CASE for constants/flags.
- Use `local` in functions and quote variables.
- Prefer explicit `if/else` for assertions instead of `&&/||`.
- Use `human_path` for user-facing paths.

## Testing Guidelines

- Tests are executable shell scripts emitting TAP output.
- Add new tests under `tests/` and list them in `README.md`.
- Test filenames use descriptive kebab-case (e.g., `host-space-name.sh`).
- Keep tests hermetic; use isolated `HOME` via `mktemp`.
- Avoid interactive commands and network access in tests.

## Commit & Pull Request Guidelines

- Commit messages: imperative, capitalized subject; blank line before body; no trailing period; wrap body at 72 chars; explain what/why.
- PRs: include summary, tests run, and any behavior/output changes; link issues if applicable.
- Update `README.md` when flags or defaults change.

## Safety Notes

- `clean` is dry-run unless `--execute`; it deletes user data and is part of the CLI contract.
- Do not broaden deletion roots without tests and clear rationale.
