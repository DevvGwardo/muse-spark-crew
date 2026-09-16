#!/bin/bash
# Installs the muse-spark-crew skill + 10 agent definitions into opencode config.
#
#   ./install.sh                          install (backs up existing files first)
#   ./install.sh --model-prefix musepark  install, rewriting agent `model:` lines
#   MODEL_PREFIX=musepark ./install.sh    same via env var
#   ./install.sh --dry-run                show what would change, change nothing
#   ./install.sh --verify                 check the installed files, change nothing
#   ./install.sh --uninstall              remove the skill + the 10 spark agents
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SKILL_DIR="$CONFIG_ROOT/skills/muse-spark-crew"
AGENT_DIR="$CONFIG_ROOT/agent"
MODEL_PREFIX="${MODEL_PREFIX:-opencode-go-muse}" # provider part of `model:` lines

usage() {
  sed -n '2,11p' "$0"
}

MODE="install"
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --model-prefix)
      if [ $# -lt 2 ]; then echo "ERROR: --model-prefix needs a value" >&2; exit 1; fi
      MODEL_PREFIX="$2"; shift 2 ;;
    --model-prefix=*) MODEL_PREFIX="${1#*=}"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --verify) MODE="verify"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

if [ "$MODE" = "install" ] && [ -z "$MODEL_PREFIX" ]; then
  echo "ERROR: --model-prefix must not be empty" >&2
  exit 1
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

backup_existing() {
  # Copy anything we are about to overwrite into a timestamped backup dir.
  local stamp backup_dir moved=0
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$CONFIG_ROOT/backups/muse-spark-crew-$stamp"
  if [ -d "$backup_dir" ]; then # two installs in the same second: don't clobber
    local n=2
    while [ -d "$backup_dir-$n" ]; do n=$((n + 1)); done
    backup_dir="$backup_dir-$n"
  fi
  for f in "$SKILL_DIR/SKILL.md" "$AGENT_DIR"/spark-*.md; do
    [ -e "$f" ] || continue
    run mkdir -p "$backup_dir"
    run cp "$f" "$backup_dir/"
    moved=1
  done
  if [ "$moved" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Backed up existing files to $backup_dir"
  fi
}

do_install() {
  backup_existing
  run mkdir -p "$SKILL_DIR" "$AGENT_DIR"
  run cp "$REPO_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"

  local count=0 src
  for src in "$REPO_DIR"/agents/spark-*.md; do
    local dest="$AGENT_DIR/$(basename "$src")"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] install $dest (model prefix: $MODEL_PREFIX)"
    else
      sed "s|^model: '[^']*'|model: '${MODEL_PREFIX}/muse-spark-1.3-contributor'|" "$src" > "$dest"
    fi
    count=$((count + 1))
  done

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would install $count agents + skill to $CONFIG_ROOT"
    return 0
  fi

  # Verify: 10 agents, skill present, every model line rewritten (per-file —
  # a single grep -q across all files would pass if only one matched).
  local installed=0 f bad=0
  for f in "$AGENT_DIR"/spark-*.md; do
    [ -e "$f" ] || continue
    installed=$((installed + 1))
    if ! grep -q "^model: '${MODEL_PREFIX}/muse-spark-1.3-contributor'$" "$f"; then
      echo "ERROR: bad model line in $f" >&2
      bad=1
    fi
  done
  [ "$installed" -eq 10 ] || { echo "ERROR: expected 10 agents, found $installed" >&2; exit 1; }
  [ -f "$SKILL_DIR/SKILL.md" ] || { echo "ERROR: SKILL.md missing" >&2; exit 1; }
  [ "$bad" -eq 0 ] || exit 1
  echo "Installed $installed agents (model prefix: $MODEL_PREFIX) + skill to $CONFIG_ROOT"
}

do_verify() {
  # Read-only health check of an existing install. Never writes.
  local fail=0 n=0 f
  if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo "ok: skill $SKILL_DIR/SKILL.md"
  else
    echo "MISSING: $SKILL_DIR/SKILL.md"
    fail=1
  fi
  for f in "$AGENT_DIR"/spark-*.md; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    if grep -q "^model: '[^']*/muse-spark-1.3-contributor'$" "$f"; then
      : # well-formed model line (any prefix — the user may have customized)
    else
      echo "BAD MODEL LINE: $f"
      fail=1
    fi
  done
  if [ "$n" -eq 10 ]; then
    echo "ok: 10 agents in $AGENT_DIR"
  else
    echo "MISSING: found $n/10 agents in $AGENT_DIR"
    fail=1
  fi
  if [ "$fail" -eq 0 ]; then
    echo "verify: OK"
  else
    echo "verify: FAILED" >&2
    exit 1
  fi
}

do_uninstall() {
  local removed=0 f
  for f in "$SKILL_DIR/SKILL.md" "$AGENT_DIR"/spark-*.md; do
    [ -e "$f" ] || continue
    run rm -f "$f"
    removed=$((removed + 1))
  done
  # Drop the skill dir if we emptied it; never touch anything else.
  if [ "$DRY_RUN" -eq 0 ] && [ -d "$SKILL_DIR" ] && [ -z "$(ls -A "$SKILL_DIR" 2>/dev/null)" ]; then
    rmdir "$SKILL_DIR"
  fi
  echo "Removed $removed file(s)."
}

if [ "$MODE" = "uninstall" ]; then
  do_uninstall
elif [ "$MODE" = "verify" ]; then
  do_verify
else
  do_install
fi
