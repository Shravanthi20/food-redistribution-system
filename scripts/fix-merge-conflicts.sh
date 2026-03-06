#!/usr/bin/env bash
# scripts/fix-merge-conflicts.sh
#
# Merges master into both conflicted feature branches so that
# PR #16 (akshitha-hygiene-feature) and PR #17 (feature/accessibility-inclusive-ux)
# become ready to merge into master.
#
# Usage (requires push access to this repo):
#   bash scripts/fix-merge-conflicts.sh
#
# Conflict strategy: -X ours
#   When both branches changed the same lines, the feature-branch version wins.
#   This preserves all intentional feature work while incorporating master's changes.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "Fetching latest master..."
git fetch origin master

fix_branch() {
  local branch="$1"
  echo ""
  echo "── Fixing $branch ──"
  git checkout "$branch"
  git merge origin/master -X ours --no-edit \
    -m "Merge master into $branch (conflict resolution)"
  git push origin "$branch"
  echo "✓ $branch is now conflict-free"
}

fix_branch "akshitha-hygiene-feature"          # PR #16
fix_branch "feature/accessibility-inclusive-ux" # PR #17

echo ""
echo "Done. PR #16 and PR #17 are conflict-free and ready to merge."
