#!/usr/bin/env bash
# resolve-pr-conflicts.sh
#
# Resolves merge conflicts in PR #16 (akshitha-hygiene-feature) and
# PR #17 (feature/accessibility-inclusive-ux) by merging master into
# each feature branch, using the feature branch changes to resolve
# any conflicts.
#
# Usage:
#   chmod +x scripts/resolve-pr-conflicts.sh
#   ./scripts/resolve-pr-conflicts.sh
#
# Requirements:
#   - Run from the root of the food-redistribution-system repository
#   - Must have push access to the origin remote

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "================================================"
echo "  Resolving merge conflicts in PR #16 and #17  "
echo "================================================"
echo ""

# Ensure we have the latest master
echo "Fetching latest changes from origin..."
git fetch origin

# ---- PR #16: akshitha-hygiene-feature ----
echo ""
echo "--- PR #16: akshitha-hygiene-feature ---"
git checkout akshitha-hygiene-feature
echo "Merging master into akshitha-hygiene-feature..."
if git merge origin/master -X ours --no-edit \
     -m "Merge master into akshitha-hygiene-feature, resolving conflicts"; then
  echo "Merge successful."
else
  echo "ERROR: Merge failed. Manual resolution required."
  exit 1
fi

# Ensure flutter_background_geolocation dep (added in master) is present
PUBSPEC="food_redistribution_app/pubspec.yaml"
if ! grep -q "flutter_background_geolocation" "$PUBSPEC"; then
  echo "Re-adding flutter_background_geolocation dependency from master..."
  # Insert flutter_background_geolocation after the dart_geohash line.
  # The exact indentation (2 spaces) matches pubspec.yaml dependency format.
  # Using Python for cross-platform compatibility (macOS sed -i differs from GNU).
  python3 - "$PUBSPEC" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
old = '  dart_geohash: ^2.0.0'
new = '  dart_geohash: ^2.0.0\n  flutter_background_geolocation: ^4.13.0'
with open(path, 'w') as f:
    f.write(content.replace(old, new, 1))
PYEOF
  git add "$PUBSPEC"
  git commit -m "chore: restore flutter_background_geolocation dep from master"
fi

echo "Pushing akshitha-hygiene-feature..."
git push origin akshitha-hygiene-feature
echo "PR #16 is now conflict-free. ✓"

# ---- PR #17: feature/accessibility-inclusive-ux ----
echo ""
echo "--- PR #17: feature/accessibility-inclusive-ux ---"
git checkout feature/accessibility-inclusive-ux
echo "Merging master into feature/accessibility-inclusive-ux..."
if git merge origin/master -X ours --no-edit \
     -m "Merge master into feature/accessibility-inclusive-ux, resolving conflicts"; then
  echo "Merge successful."
else
  echo "ERROR: Merge failed. Manual resolution required."
  exit 1
fi

echo "Pushing feature/accessibility-inclusive-ux..."
git push origin feature/accessibility-inclusive-ux
echo "PR #17 is now conflict-free. ✓"

echo ""
echo "================================================"
echo "  Done! PR #16 and PR #17 are conflict-free.   "
echo "================================================"
