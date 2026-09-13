---
name: muse-spark-crew
description: Deep senior engineering crew - fans out 10 Muse Spark 1.3 contributor subagents (architect, backend, frontend, api, data, test, debug, security, perf, reviewer) for implementation, debugging, and review. Use for any non-trivial coding task.
---

# muse-spark-crew — 10x Muse Spark 1.3 deep engineering crew

All 10 crew members run `opencode-go/muse-spark-1.3-contributor` (your configured main model). They live in `~/.config/opencode/agent/spark-*.md`. (If your setup uses a `musepark` provider instead, swap the `model:` prefix in those files to match.)

## The crew (all 10, always consider all 10)

| # | Agent | Remit |
|---|-------|-------|
| 1 | `spark-architect` | system decomposition, file ownership, interfaces |
| 2 | `spark-backend` | services, business logic, workers, CLI |
| 3 | `spark-frontend` | UI, components, state, styling |
| 4 | `spark-api` | endpoints, schemas, validation, error shapes |
| 5 | `spark-data` | schema, migrations, queries, indexes |
| 6 | `spark-test` | repro + unit/integration tests, suite run |
| 7 | `spark-debug` | root cause, bisect, log/trace analysis |
| 8 | `spark-security` | auth, secrets, injection, SSRF, traversal |
| 9 | `spark-perf` | hot paths, N+1, bundle, caching |
| 10 | `spark-reviewer` | READ-ONLY final gate, approve/block |

## When to use

Invoke this skill for any non-trivial coding task: implement feature, fix bug, refactor, audit, perf work. For trivial single-file edits (<20 lines), skip the crew and do it directly.

Triggers: "use spark crew", "spark crew", "deep crew", "10 agents", "muse spark subagents", "senior crew".

## Sizing the crew (scale to the task — capacity is finite)

Subagent calls bill against a monthly usage limit. Launching all 10 on a
small batch burns a week of capacity for no gain. Size the crew:

- **Full crew (all 10):** multi-area builds only — feature spanning
  UI + services + schema + tests, or a broad audit/triage sweep.
- **Squad (3–5):** single-area work. Pick exactly the roles the task needs
  (e.g. backend + test + reviewer for a service fix; architect + frontend +
  test for a UI feature). Always include `spark-reviewer` as the last gate
  for anything that ships.
- **Solo + reviewer (2):** bug fix with a known location, docs-only tracks,
  plan-writing tracks.
- **In-session (0):** trivial edits, or when capacity is exhausted — do the
  work directly with the same gates instead of failing to launch.

Default to the SMALLEST crew that covers the task. Never launch agents
"for coverage" on files the task doesn't touch.

## How to launch

Fan out with parallel `task` tool calls — one per selected crew member. Do NOT run them sequentially. Each gets a self-contained prompt with: goal, files it owns, what to return.

### Pattern

```
task(subagent_type="spark-architect", description="spark architect", prompt="<goal + repo context + return ownership map>")
task(subagent_type="spark-backend", description="spark backend", prompt="...")
task(subagent_type="spark-frontend", description="spark frontend", prompt="...")
task(subagent_type="spark-api", description="spark api", prompt="...")
task(subagent_type="spark-data", description="spark data", prompt="...")
task(subagent_type="spark-test", description="spark test", prompt="...")
task(subagent_type="spark-debug", description="spark debug", prompt="...")
task(subagent_type="spark-security", description="spark security", prompt="...")
task(subagent_type="spark-perf", description="spark perf", prompt="...")
task(subagent_type="spark-reviewer", description="spark review gate", prompt="...")
```

Or `@mention` all 10 in one message if the task tool is unavailable.

### Phase order

1. **Wave 1 (parallel, sized crew):** architect decomposes (full-crew runs only — squads get ownership directly from the orchestrator); implementers build their slices; debug investigates if bug; test writes repro; security + perf audit the diff surface when in the crew.
2. **Wave 2 (gate):** spark-reviewer runs LAST, read-only, over all Wave-1 outputs. It returns APPROVED or BLOCKED with file:line fixes.
3. If BLOCKED, re-launch only the owning agents with the reviewer's fix list, then re-gate.

### Rules for the orchestrator

- Give each agent disjoint file ownership — never two writers on the same file. For parallel implementation tracks, add one branch per track and forbid shared files (`STATE.md`, `PLAN*.md`, `package.json`, version files, `.env*`); the orchestrator owns records and integration.
- Each subprompt must state: goal, exact files, return format (files changed + verification), and a ≤30-line return cap.
- Subagents never merge to main, never release/deploy, never push without an explicit ask. They push feature branches and open PRs; the orchestrator merges.
- Verification commands are mandatory in every implementer brief: `npx tsc -b --force` (NOT bare `-b` — the incremental cache masks errors a clean-room build catches), targeted vitest, then the full suite. Numbers are re-measured at report time, never quoted from memory.
- Prefer behavioral pins over source-text pins in tests the crew writes: assert what the code DOES (call it with the evil input), not what it SAYS (regex over source). A new behavior test must be shown red against the old code (stash-and-run) at least once per batch.
- Main agent synthesizes, does not duplicate subagent work.
- Verify: `ls ~/.config/opencode/agent/spark-*.md` must show 10 files; skill dir is `~/.config/opencode/skills/muse-spark-crew/SKILL.md`.

### Capacity and failure handling

- A `Monthly usage limit reached` failure is workspace-side billing, not auth. Do NOT retry-loop it, and do NOT swap credentials to dodge it — a different key does not change workspace billing.
- Never ask for, paste, or store API keys in chat. Auth lives in the harness auth store; if a key is ever exposed in chat/logs, rotate it and say so.
- On capacity exhaustion: fall back to in-session work (same gates, sequential), and say plainly what is parked vs progressing. Never report a track as done that never launched.
- `gh` CLI calls from subagents use the ambient keyring auth — verify `gh auth status` identity matches the intended account before any push or PR.

## Minimal example

User: "use spark crew to add pagination to /api/items"

1. Size it: single-area work → squad of 3 (spark-api, spark-test, spark-reviewer).
2. spark-api owns the route, spark-test owns pagination tests, both run parallel.
3. spark-reviewer gates. Ship only on APPROVED.
