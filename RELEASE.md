# Release Tagging Guide

This guide explains how to create and manage releases for UltraCursorFX, following CurseForge's API guidelines.

## Quick Start

```bash
# Make script executable (first time only)
chmod +x release.sh

# Show current version and available commands
./release.sh info

# Create a new release
./release.sh minor    # New feature release
./release.sh patch    # Bug fix release
./release.sh alpha    # Dev/testing build
```

## Quick Reference

| Command | Creates | Use Case | Updates Files? |
|---------|---------|----------|----------------|
| `./release.sh info` | - | Show current version | No |
| `./release.sh major` | v1.0.0 | Breaking changes | Yes ✅ |
| `./release.sh minor` | v0.3.0 | New features | Yes ✅ |
| `./release.sh patch` | v0.2.1 | Bug fixes | Yes ✅ |
| `./release.sh beta` | v0.3.0-beta | Beta testing | No |
| `./release.sh alpha` | v0.2.0-a1b2c3d | Dev/test build | No |
| `./release.sh custom-alpha` | v0.2.0-custom | Custom alpha | No |

## Version Formats

### Semantic Versioning
We follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

### CurseForge Release Types

CurseForge categorizes releases into three types:

| Type | Format | CurseForge Type | Use Case |
|------|--------|-----------------|----------|
| Release | `v0.1.0` | `release` | Stable production releases |
| Beta | `v0.1.0-beta` | `beta` | Beta testing releases |
| Alpha | `v0.1.0-alpha`<br>`v0.1.0-a1b2c3d` | `alpha` | Development/testing builds |

## Release Commands

### Standard Releases

#### Increment Major Version
```bash
./release.sh major
```
- Creates: `v1.0.0` from `v0.2.0`
- Use for: Breaking changes, major rewrites
- Updates: README.md, CHANGELOG.md
- Commits and tags automatically

#### Increment Minor Version
```bash
./release.sh minor
```
- Creates: `v0.3.0` from `v0.2.0`
- Use for: New features, enhancements
- Updates: README.md, CHANGELOG.md
- Commits and tags automatically

#### Increment Patch Version
```bash
./release.sh patch
```
- Creates: `v0.2.1` from `v0.2.0`
- Use for: Bug fixes, small tweaks
- Updates: README.md, CHANGELOG.md
- Commits and tags automatically

### Pre-release / Testing Versions

#### Beta Release
```bash
./release.sh beta
```
- Creates: `v0.3.0-beta` from `v0.2.0`
- Use for: Feature-complete but needs testing
- Does NOT update version files (pre-release only)
- Creates tag without commit

#### Alpha Release (Auto Hash)
```bash
./release.sh alpha
```
- Creates: `v0.2.0-a1b2c3d` (uses current git commit hash)
- Use for: Development builds, testing specific commits
- Does NOT update version files
- Perfect for distributing test builds

#### Custom Alpha Release
```bash
./release.sh custom-alpha
# Then enter suffix like: alpha.1, alpha, rc1, etc.
```
- Creates: `v0.2.0-alpha.1` (or whatever suffix you provide)
- Use for: Numbered alpha builds, release candidates
- Does NOT update version files

## CI/CD Pipeline

### Automatic Release Creation

When you push a tag, GitHub Actions automatically:

1. ✅ **Runs Full Test Suite** (167 tests)
   - Unit tests for all modules
   - Integration tests
   - Docker-based test environment
   - **Release is BLOCKED if tests fail**

2. 📦 **Creates Release Package**
   - Updates TOC file with version
   - Packages all addon files
   - Removes dev/test files
   - Creates .zip file

3. 🚀 **Publishes Release**
   - Creates GitHub Release
   - Uploads .zip file
   - Marks as pre-release (for alpha/beta)
   - Adds changelog
   - **CurseForge webhook automatically receives release event**

4. 📤 **CurseForge Auto-Deploy** (via webhook)
   - Webhook receives GitHub release event
   - Uses correct release type (alpha/beta/release)
   - Publishes to CurseForge automatically
   - No manual upload needed!

### Monitoring Releases

After pushing a tag, monitor the release process:

```bash
# View GitHub Actions
https://github.com/Stackout/ultra-cursor-fx/actions

# View releases
https://github.com/Stackout/ultra-cursor-fx/releases
```

## Examples

### Scenario 1: New Feature Release

You've added a new feature and want to release v0.3.0:

```bash
# Ensure all changes are committed
git status

# Create release
./release.sh minor
# This will:
# - Update version to 0.3.0 in README.md
# - Update CHANGELOG.md with release date
# - Create commit: "chore: bump version to 0.3.0"
# - Create tag: v0.3.0
# - Prompt to push

# Push the tag
git push origin v0.3.0

# GitHub Actions will automatically:
# - Run tests
# - Create GitHub release
# - Upload to CurseForge
```

### Scenario 2: Bug Fix

You've fixed bugs and want to release v0.2.1:

```bash
./release.sh patch
# Follow prompts
```

### Scenario 3: Testing Build

You want to share a development build for testing:

```bash
# Option A: Auto-hash (recommended)
./release.sh alpha
# Creates: v0.2.0-a1b2c3d

# Option B: Custom naming
./release.sh custom-alpha
# Enter: test-feature-x
# Creates: v0.2.0-test-feature-x
```

### Scenario 4: Beta Release

Feature is complete, needs user testing:

```bash
./release.sh beta
# Creates: v0.3.0-beta
# This is marked as pre-release on GitHub
# CurseForge will categorize as beta
```

## CurseForge Integration

### Webhook Setup

CurseForge uses GitHub webhooks to automatically receive releases. No manual upload needed!

**Setup (one-time):**

1. Go to your CurseForge project settings
2. Enable GitHub webhook integration
3. Connect your GitHub repository
4. Configure which tags trigger releases (e.g., `v*`)

**How it works:**

1. You push a tag: `git push origin v0.3.0`
2. GitHub Actions creates a release
3. CurseForge webhook receives the event
4. CurseForge automatically:
   - Downloads the .zip file
   - Detects release type from tag format
   - Publishes to CurseForge
   - Uses the changelog from GitHub release

### Release Types Mapping

| Git Tag | CurseForge Type | Visibility |
|---------|-----------------|------------|
| `v0.1.0` | `release` | Public, default download |
| `v0.1.0-beta` | `beta` | Public, opt-in |
| `v0.1.0-alpha`<br>`v0.1.0-[hash]` | `alpha` | Public, opt-in |

## Workflow Details

### What Gets Updated

#### For Standard Releases (major/minor/patch):
- ✅ `README.md` - Version badge
- ✅ `CHANGELOG.md` - Release date
- ✅ `UltraCursorFX.toc` - Version (during CI/CD)
- ✅ Git commit created
- ✅ Git tag created

#### For Pre-releases (alpha/beta):
- ❌ No version file updates
- ✅ Git tag created only
- ✅ Marked as pre-release on GitHub

### Git Tag Format

All tags follow the format: `v{version}`

Examples:
- `v0.1.0` - Release
- `v0.2.0-beta` - Beta
- `v0.2.0-alpha` - Named alpha
- `v0.2.0-a1b2c3d` - Commit hash alpha

### Changelog Management

The script expects CHANGELOG.md to follow this format:

```markdown
# Changelog

## [Unreleased]
- Feature in progress

## [0.2.0] - 2026-01-22
- Feature A
- Feature B
```

When creating a release, `[Unreleased]` is replaced with `[0.3.0] - 2026-01-23`.

## Troubleshooting

### Tag Already Exists

```bash
Error: Tag v0.3.0 already exists
```

**Solution:** Choose a different version or delete the old tag:
```bash
git tag -d v0.3.0           # Delete locally
git push origin :v0.3.0     # Delete remotely
```

### Dirty Working Directory

```bash
Error: Working directory is not clean
```

**Solution:** Commit or stash your changes:
```bash
git status
git add .
git commit -m "your message"
# Then retry release script
```

### Tests Fail During Release

The CI/CD pipeline will block the release if tests fail.

**Solution:**
1. Check GitHub Actions for test results
2. Fix failing tests locally:
   ```bash
   ./test.sh all
   ```
3. Commit fixes
4. Delete the tag and recreate:
   ```bash
   git tag -d v0.3.0
   git push origin :v0.3.0
   ./scripts/release.sh minor
   ```

### CurseForge Upload Fails

If CurseForge webhook doesn't receive the release:

1. **Check Webhook Configuration**: Verify webhook is enabled in CurseForge project settings
2. **Check GitHub Release**: Ensure GitHub release was created successfully
3. **Tag Format**: Verify tag matches webhook filter (e.g., `v*`)
4. **Manual Trigger**: May need to manually trigger from CurseForge if webhook fails

## Best Practices

### Before Releasing

1. ✅ Run full test suite: `./test.sh all`
2. ✅ Update `CHANGELOG.md` with changes
3. ✅ Commit all changes
4. ✅ Verify current version: `./scripts/release.sh info`

### Version Strategy

- **Patch** (0.0.X): Bug fixes only
- **Minor** (0.X.0): New features, backwards compatible
- **Major** (X.0.0): Breaking changes (rare for addons)
- **Alpha**: Testing specific features/fixes
- **Beta**: Release candidates, feature-complete

### Testing Strategy

1. **Alpha builds**: Share with testers, iterate quickly
2. **Beta builds**: Broader testing, feature-complete
3. **Release**: Stable, well-tested, production-ready

### Hotfix Process

For urgent bug fixes:

```bash
# Fix the bug
git add .
git commit -m "fix: critical bug in cursor rendering"

# Create patch release
./scripts/release.sh patch

# Push tag
git push origin v0.2.1
```

## Manual Override

If you need to create a tag manually:

```bash
# Create annotated tag
git tag -a v0.3.0 -m "Release v0.3.0"

# Push tag
git push origin v0.3.0

# GitHub Actions will still run
```

## Reference Links

- **CurseForge API Docs:** https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-api
- **GitHub Actions:** https://github.com/Stackout/ultra-cursor-fx/actions
- **Semantic Versioning:** https://semver.org/
- **Project on CurseForge:** https://www.curseforge.com/wow/addons/ultra-cursor-fx (check X-Curse-Project-ID)

## Support

Questions or issues with the release process?

1. Check this guide
2. Review GitHub Actions logs
3. Check CurseForge API documentation
4. Open an issue on GitHub
