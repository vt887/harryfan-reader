#!/usr/bin/env bash
set -euo pipefail

# Update license headers in Swift source files under Sources/HarryFanReader
# Replaces any existing header up to the file comment (//  <File>.swift)

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0")"
cd "$REPO_ROOT"

HEADER='// Copyright 2026 Scythify LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
'

for f in Sources/HarryFanReader/*.swift; do
  [ -f "$f" ] || continue
  echo "Processing $f"

  # Find the file header marker (e.g., '//  Foo.swift')
  marker_line=$(grep -nE '^//\s{2}.+\.swift$' -- "$f" | head -n1 | cut -d: -f1 || true)

  if [ -n "$marker_line" ]; then
    # Preserve file header from marker_line to end
    tail -n +$marker_line -- "$f" > "$f.tmp"
    printf "%s\n" "$HEADER" > "$f"
    cat "$f.tmp" >> "$f"
    rm "$f.tmp"
  else
    # No marker found, just prepend header
    printf "%s\n" "$HEADER" > "$f.tmp"
    cat "$f" >> "$f.tmp"
    mv "$f.tmp" "$f"
  fi
done

echo "License headers updated. Review changes and git add/commit as needed."

