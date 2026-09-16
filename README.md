# muse-spark-crew

Skill repo for the **muse-spark-crew** — a 10-agent senior engineering crew running on Muse Spark 1.3 (`opencode-go-muse/muse-spark-1.3-contributor` by default).

## Contents

- `SKILL.md` — orchestrator instructions (sizing, fan-out pattern, phase order, gates)
- `agents/` — 10 subagent definitions (`spark-architect`, `spark-backend`, `spark-frontend`, `spark-api`, `spark-data`, `spark-test`, `spark-debug`, `spark-security`, `spark-perf`, `spark-reviewer`)
- `CHANGELOG.md` — what changed per release

## Install

```bash
./install.sh
```

This installs to the opencode paths the skill expects:

- skill → `~/.config/opencode/skills/muse-spark-crew/SKILL.md`
- agents → `~/.config/opencode/agent/spark-*.md`

Existing files are backed up to a timestamped dir under `~/.config/opencode/backups/` before being overwritten. Respects `XDG_CONFIG_HOME`.

```bash
./install.sh --model-prefix musepark  # rewrite agent `model:` lines for your provider
./install.sh --dry-run                 # show what would change, change nothing
./install.sh --uninstall               # remove the skill + the 10 spark agents
./install.sh --help
```

Verify:

```bash
ls ~/.config/opencode/agent/spark-*.md   # must show 10 files
ls ~/.config/opencode/skills/muse-spark-crew/SKILL.md
```

## Use

Triggers: "use spark crew", "spark crew", "deep crew", "10 agents", "muse spark subagents", "senior crew".

- Full crew (10): multi-area builds only
- Squad (3–5): single-area work, always end with `spark-reviewer`
- Solo + reviewer (2): known-location bug fix, docs, plans
- In-session (0): trivial edits or capacity exhausted

Source of truth is the local opencode config this was exported from. Keep this repo in sync when `SKILL.md` or `agents/` change.
