# Changelog

## 1.1.0 — 2026-09-16

- `install.sh`: backs up existing files to a timestamped dir under `~/.config/opencode/backups/` before overwriting (no more silent clobbering).
- `install.sh`: new `--model-prefix` flag (`MODEL_PREFIX` env also works) rewrites the agents' `model:` lines at install time — no more hand-editing 10 files when your provider isn't the default.
- `install.sh`: new `--dry-run`, `--uninstall`, `--help` flags; respects `XDG_CONFIG_HOME`; verifies 10 agents + skill + rewritten model lines after install and fails loudly otherwise.
- `agents/`: every agent file now carries a shared `RETURN CONTRACT` (≤30 lines, verdict first, files changed, verification with re-measured numbers) so agents are self-describing even when the orchestrator's brief is thin.
- `agents/`: the no-commit/no-push/no-merge rule now covers all six implementers (`backend`, `frontend`, `api`, `data`, `test`, `perf`) — previously backend-only.
- `spark-security`: report-only — findings, not fixes.
- `spark-test`: new behavior tests must be shown red against the old code (`git stash`) at least once per batch.
- `spark-debug`: repro/bisect must be non-destructive (no data deletion, no table drops, no `rm -rf` outside scratch dirs).
- `spark-reviewer`: verdict (`APPROVED`/`BLOCKED`) first, details after.
- `SKILL.md` / `README.md`: documented install options and the model-prefix override; fixed the model string to match the shipped agent files.
