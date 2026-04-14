# GitHub Workflows Documentation

This document describes the automated workflows configured for HarryFan Reader.

## Workflows Overview

### 1. Multi-Arch Build (`build.yml`)
Builds and tests the application on both x86_64 and ARM64 (Apple Silicon) architectures.

**Triggers:**
- Push to any branch
- Manual trigger via GitHub Actions interface

**Jobs:**
- **count**: Counts Swift lines of code
- **build**: Compiles on x86_64 and ARM64
- **test**: Runs test suite on both architectures

**Requirements:**
- Self-hosted macOS runners with labels `X64` and `ARM64`

**Status Badge:**
```markdown
[![Multi-Arch Build](https://github.com/vt887/harryfan-reader/actions/workflows/build.yml/badge.svg)](https://github.com/vt887/harryfan-reader/actions/workflows/build.yml)
```

### 2. Semgrep Security Scan (`semgrep.yml`)
Performs automated security and code quality scanning using Semgrep.

**Triggers:**
- Pull requests
- Pushes to any branch
- Manual trigger via GitHub Actions interface
- Daily schedule (15:00 UTC)

**Features:**
- Scans against automatic Semgrep rule set
- Generates JSON and SARIF reports
- Uploads to GitHub Code Scanning
- Posts scan summary as PR comment

**Artifacts:**
- `semgrep-results.json` - Detailed findings in JSON format
- `semgrep-results.sarif` - SARIF format for GitHub integration

**Status Badge:**
```markdown
[![Semgrep Scan](https://github.com/vt887/harryfan-reader/actions/workflows/semgrep.yml/badge.svg)](https://github.com/vt887/harryfan-reader/actions/workflows/semgrep.yml)
```

## Workflow Commands

### Run a specific workflow
```bash
# View workflow status
gh workflow view build.yml

# Run workflow manually
gh workflow run build.yml

# List all workflow runs
gh run list
```

### View job logs
```bash
# View latest run for a workflow
gh run view --workflow=build.yml

# View specific job logs
gh run view <run-id> --log
```

## Local Testing Before Push

To avoid workflow failures, test locally before pushing:

```bash
# Build the project
make build

# Run all tests
make test

# Format and lint code
make lint
make style

# Check for security issues (if Semgrep installed locally)
semgrep scan --config auto
```

## Continuous Integration Best Practices

1. **Keep workflows fast** - Aim for <10 minutes total
2. **Cache dependencies** - Avoid repeated downloads
3. **Fail fast** - Stop early on critical failures
4. **Clear error messages** - Help developers diagnose issues
5. **Test multiple configurations** - Different architectures, Swift versions

## Customizing Workflows

### Adding a new workflow
1. Create a new `.yml` file in `.github/workflows/`
2. Use descriptive names (e.g., `lint.yml`, `deploy.yml`)
3. Include documentation in this file
4. Reference the workflow in README badges

### Modifying existing workflows
1. Test changes in a feature branch
2. Use `git push` to trigger the workflow
3. Review results in the Actions tab
4. Merge changes after successful testing

## Troubleshooting

### Build fails on self-hosted runner
- Verify runner has required software (Swift, Xcode)
- Check runner health: `gh run view <run-id> --log`
- Review runner configuration in repository settings

### Security scan shows false positives
- Update Semgrep rules: `semgrep login && semgrep update`
- Add suppressions for false positives in `.semgrep.yml`
- File issue with Semgrep team if rule needs adjustment

### PR comment not posted
- Verify `GITHUB_TOKEN` permissions (check workflow `permissions:`)
- Ensure template file exists and is properly formatted
- Check `peter-evans/create-or-update-comment` version compatibility

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semgrep Documentation](https://semgrep.dev/docs)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [Swift Package Manager Actions](https://github.com/marketplace?type=actions&query=swift)
