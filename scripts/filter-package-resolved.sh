#!/usr/bin/env bash
set -euo pipefail

# Minimal filter for Package.resolved used by pre-commit.
# Placeholder implementation: validates file exists and outputs it unchanged.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0")"
cd "$REPO_ROOT"

FILE="Package.resolved"
if [[ ! -f "$FILE" ]]; then
  echo "No $FILE found in repo root; nothing to do." >&2
  exit 0
fi

# In some projects this script removes transient pins or normalizes the file.
# Keep a no-op for now so pre-commit won't fail when no special filtering is
# required. If you have a canonical transformation, replace the `cat` below.
cat "$FILE"

exit 0

