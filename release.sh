#!/bin/bash
set -e

# UltraCursorFX Release Tagging Script
# Follows CurseForge API guidelines for version tagging
# 
# CurseForge Release Types:
# - release: v0.1.0 (stable production release)
# - beta: v0.1.0-beta (beta testing)
# - alpha: v0.1.0-alpha or v0.1.0-[commitHash] (alpha/dev builds)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current version from README
get_current_version() {
    grep -oP 'version-\K[0-9]+\.[0-9]+\.[0-9]+' README.md | head -1
}

# Parse version components
parse_version() {
    local version=$1
    IFS='.' read -r MAJOR MINOR PATCH <<< "$version"
}

# Get short commit hash
get_commit_hash() {
    git rev-parse --short HEAD
}

# Check if git is clean (except CHANGELOG.md)
check_git_clean() {
    # Get all uncommitted changes except CHANGELOG.md
    local dirty_files=$(git status -s | grep -v 'CHANGELOG.md')
    
    if [[ -n "$dirty_files" ]]; then
        echo -e "${RED}Error: Working directory has uncommitted changes${NC}"
        echo "Please commit or stash these files first:"
        echo "$dirty_files"
        echo ""
        echo -e "${YELLOW}Note: CHANGELOG.md is allowed to have uncommitted changes${NC}"
        exit 1
    fi
}

# Check that CHANGELOG.md has the new version and uncommitted changes
check_changelog() {
    local new_version=$1
    
    # Check if CHANGELOG.md has uncommitted changes
    if ! git status -s | grep -q 'CHANGELOG.md'; then
        echo -e "${RED}Error: CHANGELOG.md has no uncommitted changes${NC}"
        echo "You must update CHANGELOG.md with release notes before creating a release."
        echo ""
        echo "Add a section like:"
        echo "  ## [$new_version] - $(date +%Y-%m-%d)"
        echo "  - Feature 1"
        echo "  - Feature 2"
        exit 1
    fi
    
    # Check if CHANGELOG.md contains the new version number
    if ! grep -q "## \[$new_version\]" CHANGELOG.md; then
        echo -e "${RED}Error: CHANGELOG.md does not contain version $new_version${NC}"
        echo "Please add a section for version $new_version in CHANGELOG.md"
        echo ""
        echo "Expected format:"
        echo "  ## [$new_version] - $(date +%Y-%m-%d)"
        exit 1
    fi
    
    echo -e "${GREEN}✓ CHANGELOG.md has changes for version $new_version${NC}"
}

# Update version in files
update_version_files() {
    local new_version=$1
    
    # Update README.md badge
    sed -i "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+/version-$new_version/g" README.md
    
    echo -e "${GREEN}✓ Updated README.md version badge${NC}"
}

# Create and push tag
create_tag() {
    local version=$1
    local tag_name=$2
    local message=$3
    local is_prerelease=${4:-false}
    
    # Check if tag already exists
    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        echo -e "${RED}Error: Tag $tag_name already exists${NC}"
        exit 1
    fi
    
    # Create annotated tag
    git tag -a "$tag_name" -m "$message"
    
    echo -e "${GREEN}✓ Created tag: $tag_name${NC}"
    
    # Show what will be pushed
    echo -e "\n${BLUE}Tag created locally. Review and push with:${NC}"
    echo -e "  git push origin $tag_name"
    echo -e "\n${YELLOW}Or push now? (y/n)${NC}"
    read -r push_now
    
    if [[ "$push_now" == "y" || "$push_now" == "Y" ]]; then
        git push origin "$tag_name"
        echo -e "${GREEN}✓ Tag pushed to origin${NC}"
        echo -e "\n${BLUE}GitHub Actions will now:${NC}"
        echo -e "  1. Run full test suite"
        echo -e "  2. Create GitHub release"
        if [[ "$is_prerelease" == "true" ]]; then
            echo -e "  3. Mark as pre-release (alpha/beta)"
        else
            echo -e "  3. Mark as stable release"
        fi
        echo -e "\n${BLUE}Monitor at: https://github.com/Stackout/ultra-cursor-fx/actions${NC}"
    else
        echo -e "${YELLOW}Tag created locally but not pushed${NC}"
        echo -e "Push later with: git push origin $tag_name"
    fi
}

# Increment major version (X.0.0)
increment_major() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    
    local new_version="$((MAJOR + 1)).0.0"
    local tag_name="v$new_version"
    
    echo -e "${BLUE}Incrementing MAJOR version${NC}"
    echo -e "Current: v$current"
    echo -e "New:     $tag_name"
    echo -e "\n${YELLOW}This is a BREAKING CHANGE release. Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    check_changelog "$new_version"
    update_version_files "$new_version"
    
    # Commit version bump
    git add README.md CHANGELOG.md
    git commit -m ":arrow_up: Bump version to $new_version."
    
    create_tag "$new_version" "$tag_name" "Release $tag_name" false
}

# Increment minor version (0.X.0)
increment_minor() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    
    local new_version="$MAJOR.$((MINOR + 1)).0"
    local tag_name="v$new_version"
    
    echo -e "${BLUE}Incrementing MINOR version${NC}"
    echo -e "Current: v$current"
    echo -e "New:     $tag_name"
    echo -e "\n${YELLOW}This adds new features. Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    check_changelog "$new_version"
    update_version_files "$new_version"
    
    # Commit version bump
    git add README.md CHANGELOG.md
    git commit -m ":arrow_up: Bump version to $new_version."
    
    create_tag "$new_version" "$tag_name" "Release $tag_name" false
}

# Increment patch version (0.0.X)
increment_patch() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    
    local new_version="$MAJOR.$MINOR.$((PATCH + 1))"
    local tag_name="v$new_version"
    
    echo -e "${BLUE}Incrementing PATCH version${NC}"
    echo -e "Current: v$current"
    echo -e "New:     $tag_name"
    echo -e "\n${YELLOW}This is a bug fix release. Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    check_changelog "$new_version"
    update_version_files "$new_version"
    
    # Commit version bump
    git add README.md CHANGELOG.md
    git commit -m ":arrow_up: Bump version to $new_version."
    
    create_tag "$new_version" "$tag_name" "Release $tag_name" false
}

# Create beta release (0.X.0-beta)
create_beta() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    
    # For beta, increment minor and add -beta suffix
    local new_version="$MAJOR.$((MINOR + 1)).0-beta"
    local tag_name="v$new_version"
    
    echo -e "${BLUE}Creating BETA release${NC}"
    echo -e "Current: v$current"
    echo -e "New:     $tag_name"
    echo -e "\n${YELLOW}This is a BETA pre-release. Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    # Don't update version files for pre-releases
    create_tag "$new_version" "$tag_name" "Beta Release $tag_name" true
}

# Create alpha release with commit hash (0.X.0-[hash])
create_alpha() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    local commit_hash=$(get_commit_hash)
    
    # For alpha, use current version + commit hash
    local new_version="$MAJOR.$MINOR.$PATCH-$commit_hash"
    local tag_name="v$new_version"
    
    echo -e "${BLUE}Creating ALPHA/DEV release${NC}"
    echo -e "Current: v$current"
    echo -e "New:     $tag_name"
    echo -e "\n${YELLOW}This is an ALPHA dev build. Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    # Don't update version files for alpha releases
    create_tag "$new_version" "$tag_name" "Alpha/Dev Release $tag_name" true
}

# Create custom alpha release (e.g., 0.X.0-alpha.1)
create_custom_alpha() {
    check_git_clean
    
    local current=$(get_current_version)
    parse_version "$current"
    
    echo -e "${BLUE}Creating CUSTOM ALPHA release${NC}"
    echo -e "Current base version: v$current"
    echo -e "\nEnter alpha suffix (e.g., 'alpha.1', 'alpha', 'rc1'):"
    read -r suffix
    
    if [[ -z "$suffix" ]]; then
        echo -e "${RED}Error: Suffix cannot be empty${NC}"
        exit 1
    fi
    
    local new_version="$MAJOR.$MINOR.$PATCH-$suffix"
    local tag_name="v$new_version"
    
    echo -e "\nNew tag: $tag_name"
    echo -e "${YELLOW}Continue? (y/n)${NC}"
    read -r confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    create_tag "$new_version" "$tag_name" "Alpha Release $tag_name" true
}

# Show current version info
show_info() {
    local current=$(get_current_version)
    parse_version "$current"
    local commit_hash=$(get_commit_hash)
    
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}  UltraCursorFX Version Information${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "Current version: ${GREEN}v$current${NC}"
    echo -e "  Major: $MAJOR"
    echo -e "  Minor: $MINOR"
    echo -e "  Patch: $PATCH"
    echo -e "\nCurrent commit: ${YELLOW}$commit_hash${NC}"
    echo -e "\nLast tags:"
    git tag --sort=-version:refname | head -5 | sed 's/^/  /'
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# Show usage
usage() {
    echo -e "${BLUE}UltraCursorFX Release Tagging Script${NC}"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}major${NC}         Increment major version (X.0.0) - Breaking changes"
    echo -e "  ${GREEN}minor${NC}         Increment minor version (0.X.0) - New features"
    echo -e "  ${GREEN}patch${NC}         Increment patch version (0.0.X) - Bug fixes"
    echo -e "  ${GREEN}beta${NC}          Create beta pre-release (0.X.0-beta)"
    echo -e "  ${GREEN}alpha${NC}         Create alpha dev build (0.X.0-[commitHash])"
    echo -e "  ${GREEN}custom-alpha${NC}  Create custom alpha (0.X.0-<custom>)"
    echo -e "  ${GREEN}info${NC}          Show current version information"
    echo ""
    echo "Examples:"
    echo "  $0 minor          # Create v0.3.0 from v0.2.0"
    echo "  $0 patch          # Create v0.2.1 from v0.2.0"
    echo "  $0 beta           # Create v0.3.0-beta"
    echo "  $0 alpha          # Create v0.2.0-a1b2c3d"
    echo ""
    echo -e "${YELLOW}CurseForge Release Types:${NC}"
    echo "  • release: Stable versions (v0.1.0)"
    echo "  • beta:    Beta testing (v0.1.0-beta)"
    echo "  • alpha:   Dev/testing builds (v0.1.0-alpha, v0.1.0-[hash])"
}

# Main script
main() {
    local command=${1:-}
    
    if [[ -z "$command" ]]; then
        usage
        exit 1
    fi
    
    case "$command" in
        major)
            increment_major
            ;;
        minor)
            increment_minor
            ;;
        patch)
            increment_patch
            ;;
        beta)
            create_beta
            ;;
        alpha)
            create_alpha
            ;;
        custom-alpha)
            create_custom_alpha
            ;;
        info)
            show_info
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}\n"
            usage
            exit 1
            ;;
    esac
}

main "$@"
