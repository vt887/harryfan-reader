#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Run terraform fmt
echo "Running Swiftformat..."
swiftformat . --swift-version 6.2

echo "✅ All pre-commit checks passed!"
