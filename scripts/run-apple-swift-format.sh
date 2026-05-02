#!/usr/bin/env bash
set -euo pipefail

# Run Apple's swift-format (or fall back to nicklockwood swiftformat)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0")"
cd "$REPO_ROOT"

if command -v swift-format >/dev/null 2>&1; then
  echo "Running swift-format..."
  swift-format format --in-place --recursive .
elif command -v swiftformat >/dev/null 2>&1; then
  echo "Running swiftformat (nicklockwood)..."
  swiftformat .
else
  echo "warning: neither 'swift-format' nor 'swiftformat' is installed; skipping swift formatting"
  exit 0
fi

