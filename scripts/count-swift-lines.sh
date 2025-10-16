#!/bin/sh
# Count Swift files and lines in Sources and Tests directories (POSIX shell)
# Variable-based implementation (no temporary file).
set -eu

lines_and_files() {
  dir="$1"
  count=0
  lines=0
  comment_lines=0
  files=$(find "$dir" -name '*.swift' -type f 2>/dev/null)

  while IFS= read -r f; do
    # Skip empty lines defensively
    [ -n "$f" ] || continue
    count=$((count + 1))
    # Add this file's line count (silence errors if file disappears mid-scan)
    lc=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
    lc=${lc:-0}
    lines=$((lines + lc))
    # Count single-line comments
    slc=$(grep -E '^\s*//' "$f" | wc -l | tr -d ' ')
    # Count block comment lines
    blc=$(awk '/\/\*/{c=1} c; /\*\//{c=0}' "$f" | wc -l | tr -d ' ')
    comment_lines=$((comment_lines + slc + blc))
  done <<EOF
$files
EOF

  printf '%s %s %s\n' "$lines" "$count" "$comment_lines"
}

# Helper: assign_counts DIR PREFIX -> sets ${PREFIX}_files and ${PREFIX}_lines
assign_counts() {
  dir="$1"; prefix="$2"
  set -- $(lines_and_files "$dir")
  eval "${prefix}_files=\$2"
  eval "${prefix}_lines=\$1"
  eval "${prefix}_comment_lines=\$3"
}

# New: print summary helper
print_summary() {
  printf "Swift statistics by directory (files / lines / %% comments):\n"
  src_pct=0; test_pct=0; total_pct=0
  if [ "$src_lines" -gt 0 ]; then
    src_pct=$(awk "BEGIN {printf \"%.1f\", ($src_comment_lines/$src_lines)*100}")
  fi
  if [ "$test_lines" -gt 0 ]; then
    test_pct=$(awk "BEGIN {printf \"%.1f\", ($test_comment_lines/$test_lines)*100}")
  fi
  total_lines=$((src_lines + test_lines))
  total_files=$((src_files + test_files))
  total_comment_lines=$((src_comment_lines + test_comment_lines))
  if [ "$total_lines" -gt 0 ]; then
    total_pct=$(awk "BEGIN {printf \"%.1f\", ($total_comment_lines/$total_lines)*100}")
  fi
  printf "Sources: %3d / %5d / %5.1f%%\n" "$src_files" "$src_lines" "$src_pct"
  printf "Tests:   %3d / %5d / %5.1f%%\n" "$test_files" "$test_lines" "$test_pct"
  printf "Total:   %3d / %5d / %5.1f%%\n" "$total_files" "$total_lines" "$total_pct"
}

# Initialize counts
assign_counts "Sources" src
assign_counts "Tests" test

# Use the summary function (was lines 40–44)
print_summary
