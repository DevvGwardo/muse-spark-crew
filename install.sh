#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config/opencode/skills/muse-spark-crew
mkdir -p ~/.config/opencode/agent

cp "$REPO_DIR/SKILL.md" ~/.config/opencode/skills/muse-spark-crew/SKILL.md
cp "$REPO_DIR"/agents/spark-*.md ~/.config/opencode/agent/

echo "Installed:"
ls ~/.config/opencode/skills/muse-spark-crew/SKILL.md
ls ~/.config/opencode/agent/spark-*.md
