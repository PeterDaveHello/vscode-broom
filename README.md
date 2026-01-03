# vscode-broom

Shell-based CLI to inspect and clean Visual Studio Code extension, cache, and server build artifacts on Linux and other Unix-like systems. Safe defaults keep the newest versions and run in dry-run mode unless `--execute` is provided.

## Install

Run from the repo:

```bash
chmod +x ./bin/vscode-broom
./bin/vscode-broom -h
```

Optional: add to PATH (example):

```bash
ln -sf "$(pwd)/bin/vscode-broom" ~/.local/bin/vscode-broom
```

## Requirements

Runtime:

- bash (>= 4)
- findutils (`find`)
- coreutils (`du`, `sort`, `numfmt`, `rm`, `tail`)
- awk
- Matching VS Code CLI is required for `--prune-uninstalled` (`code`, `code-insiders`, `codium`, or `code-oss`; server roots use their bundled CLI)

Tests:

- coreutils (`mktemp`)
- `prove` is optional (used automatically when available)

## Usage

```
vscode-broom [target] [action] [options]
(defaults: target=all, action=analyze)

Targets (default action: analyze)
  extensions     Inspect/clean extension folders (keep newest version)
  caches         Inspect/clean VS Code caches (CachedData, CachedExtensionVSIXs, logs)
  hosts          Inspect/clean VS Code server builds (keep newest by mtime)
  all            Run on extensions + caches + hosts

Actions
  analyze        Report disk usage
  clean          Delete planned targets (requires --execute)

Extension options
  -p, --prune-uninstalled         Remove extension dirs not in "code --list-extensions"
  -E, --extensions-path DIR       Add an extensions directory to scan

Cache options
  -w, --include-workspace-storage Include User/workspaceStorage
  -g, --include-global-storage    Include User/globalStorage (settings/data)
  -C, --config-path DIR           Add a config directory to scan (CachedData,...)

Host options
  -H, --host-path DIR             Add a server build directory to scan (e.g., ~/.vscode-server/bin)

Global options
  -x, --execute                   Execute deletions (otherwise dry-run)
  -v, --verbose                   Show missing paths in detail
  -h, --help                      Show this help

Examples
  vscode-broom
  vscode-broom clean
  vscode-broom clean --execute
  vscode-broom hosts clean --execute
  vscode-broom extensions clean --prune-uninstalled --execute
  vscode-broom caches clean --execute
```

## Default coverage

- Extension: auto-detects `~/.vscode*` and server variants, scanning their `extensions` folders and keeping only the newest version per extension.
- Cache/Log: auto-detects existing Code/Insiders/VSCodium config roots plus server `data` folders; workspace/global storage is touched only when flags are set.
- Server build: auto-detects VS Code server install dirs under `~/.vscode-server` (root `code-*` binaries), `~/.vscode-server/bin`, `~/.vscode-server/cli/servers`, and Insiders equivalents; keeps the newest by mtime.
- Missing paths stay quiet by default; use `-v` to see ignored paths. All paths are shown with `~` for readability.

## Typical flows

- Inspect disk usage: `vscode-broom` or `vscode-broom analyze`
- Preview clean-up: `vscode-broom clean` (dry-run)
- Apply clean-up: `vscode-broom clean --execute`
- Remove old server builds: `vscode-broom hosts clean --execute`
- Remove uninstalled extensions and stale versions: `vscode-broom extensions clean --prune-uninstalled --execute`

## Safety

- `clean` is a dry-run unless `--execute` is provided.
- `--prune-uninstalled` uses the matching desktop CLI (`code`, `code-insiders`, or `codium`/`code-oss`) and the newest server CLI under each server root. Missing or failing CLIs cause pruning to be skipped for default roots (use `-v` for details); custom `--extensions-path` roots require a working CLI and will error if missing or failing. For VSCodium/OSS, when both `codium` and `code-oss` are available, both are queried and the results are combined.
- User-provided `--extensions-path`, `--config-path`, and `--host-path` must be existing directories and cannot be `/`, `$HOME`, or the parent of `$HOME` (e.g., `$HOME/..`).
- `User/workspaceStorage` and `User/globalStorage` are never touched unless explicitly enabled via flags.

## Tests

- Run all tests (TAP): `./tests/run.sh`
- Include captured CLI output: `./tests/run.sh -v`
- Individual tests: see `tests/README.md`

## License

GPL-3.0-or-later. See `LICENSE`.

Copyright (C) 2026 Peter Dave Hello
