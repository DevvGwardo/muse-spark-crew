#!/bin/bash
# Installs the muse-spark-crew skill + 10 agent definitions into opencode config.
#
#   ./install.sh                          install (backs up existing files first)
#   ./install.sh --model-prefix musepark  install, rewriting agent `model:` lines
#   MODEL_PREFIX=musepark ./install.sh    same via env var
#   ./install.sh --dry-run                show what would change, change nothing
#   ./install.sh --uninstall              remove the skill + the 10 spark agents
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SKILL_DIR="$CONFIG_ROOT/skills/muse-spark-crew"
AGENT_DIR="$CONFIG_ROOT/agent"
MODEL_PREFIX="${MODEL_PREFIX:-opencode-go-muse}" # provider part of `model:` lines

usage() {
  sed -n '2,10p' "$0"
}

MODE="install"
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --model-prefix) MODEL_PREFIX="${2:---model-prefix needs a value}"; shift 2 ;;
    --model-prefix=*) MODEL_PREFIX="${1#*=}"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

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

  # Verify: 10 agents, skill present, model lines rewritten.
  local installed
  installed="$(ls "$AGENT_DIR"/spark-*.md 2>/dev/null | wc -l)"
  [ "$installed" -eq 10 ] || { echo "ERROR: expected 10 agents, found $installed" >&2; exit 1; }
  [ -f "$SKILL_DIR/SKILL.md" ] || { echo "ERROR: SKILL.md missing" >&2; exit 1; }
  if ! grep -q "^model: '${MODEL_PREFIX}/muse-spark-1.3-contributor'$" "$AGENT_DIR"/spark-*.md; then
    echo "ERROR: model lines not rewritten to prefix '$MODEL_PREFIX'" >&2; exit 1
  fi
  echo "Installed $installed agents (model prefix: $MODEL_PREFIX) + skill to $CONFIG_ROOT"
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
else
  do_install
fi
