### ✅ Semgrep scan — Summary

**Findings:** {{findings}} ({{blocking}} blocking)

- **Rules run:** {{rules_run}}
- **Files scanned:** {{files_scanned}}
- **Parsed lines:** {{parsed_lines}}
- **Scan skipped:** {{skipped_files}}
- **Duration:** {{duration}}
- **Semgrep version:** {{semgrep_version}}

Artifacts
- JSON results: {{artifact_json_link}}
- SARIF uploaded to GitHub Code Scanning: {{sarif_status}}

Notes
- Scan was limited to files tracked by git (unless your CI overrides this).
- For a detailed list of skipped files and lines, re-run semgrep with `--verbose`.
- To re-run locally: `semgrep scan --config auto --verbose`.

Need more rules?
- Run `semgrep login` to access additional registry rules.

Guidance for CI / Action that posts this comment
- Fill the placeholders above using `jq` (from `semgrep-results.json`) and then use `peter-evans/create-or-update-comment` to post/update the PR comment. Example placeholder mappings you may want to extract from `semgrep-results.json`:
  - `findings` -> total number of findings (sum of all severities)
  - `blocking` -> number of findings you consider blocking (configure in CI)
  - `rules_run` -> (manually set to your rule count or compute from rules metadata)
  - `files_scanned` -> number of scanned files
  - `parsed_lines` -> approximate percent of parsed lines (if available)
  - `skipped_files` -> list or count of skipped files
  - `duration` -> job duration in seconds
  - `semgrep_version` -> output of `semgrep --version`
  - `artifact_json_link` -> link to the uploaded artifact (Actions artifact URL)
  - `sarif_status` -> indicate whether SARIF was uploaded to code scanning (e.g., "Yes" or "No")

Example (high-level) GitHub Actions steps to generate and post this summary
1. Run Semgrep and save `semgrep-results.json` and `semgrep-results.sarif` (already implemented in `.github/workflows/semgrep.yml`).
2. Upload artifacts (already implemented).
3. Parse `semgrep-results.json` with `jq` to compute the placeholder values.
4. Use `peter-evans/create-or-update-comment` to post the filled template into the PR body.

If you want, I can add the parsing step and the comment step to your workflow so the template is used automatically. Just tell me whether you want the comment to always be posted or only on PRs and whether to fail the workflow when findings exceed a threshold.

