#!/bin/bash

# SDK Release Preparation Script
# Creates release branch from main for QA testing (GitFlow Workflow 1)
#
# Usage: ./scripts/release.sh <version> [options]
#
# Arguments:
#   version        Version in x.y.z format (e.g., 0.8.0)
#
# Options:
#   -y, --yes           Skip confirmation prompts (non-interactive mode)
#   -q, --quiet         Minimal output
#   -h, --help          Show this help message
#
# Exit codes:
#   0 - Success
#   1 - Error (validation failure, git error, etc.)
#   2 - User cancelled
#
# What this does:
#   1. Creates release/<version> branch from main (version already correct)
#   2. Pushes release branch to remote
#   3. Bumps main to next version (e.g., 0.8.0 → 0.9.0)
#   4. Commits and pushes main
#
# After running this:
#   - Update CHANGELOG.md on release branch
#   - QA tests on release branch
#   - Fix bugs directly on release branch (commit and push normally)
#   - Run scripts/publish.sh when QA approves

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
AUTO_YES=false
QUIET=false

# Get repo root and change to it
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# =============================================================================
# Helper Functions
# =============================================================================

print_success() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${GREEN}✓ $1${NC}"
    fi
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

print_warning() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${YELLOW}⚠ $1${NC}"
    fi
}

print_info() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${BLUE}ℹ $1${NC}"
    fi
}

print_header() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${CYAN}$1${NC}"
    fi
}

# Ask user for confirmation (respects AUTO_YES)
confirm() {
    local prompt="$1"

    if [[ "$AUTO_YES" == true ]]; then
        return 0
    fi

    echo -n -e "${YELLOW}${prompt} (y/n): ${NC}"
    read -r response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Validate version format (semantic versioning)
validate_version() {
    local version="$1"

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Version must be in semantic versioning format: x.y.z (e.g., 1.2.3)"
        return 1
    fi

    return 0
}

# Calculate next minor version (e.g., 0.8.0 → 0.9.0)
calculate_next_version() {
    local version="$1"

    # Extract major, minor, patch
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)

    # Increment minor, reset patch
    minor=$((minor + 1))
    echo "${major}.${minor}.0"
}

# Show help message
show_help() {
    cat << EOF
SDK Release Preparation Script

Creates a release candidate branch from main for QA testing (GitFlow).

Usage: $0 <version> [options]

Arguments:
  version        Version in x.y.z format (e.g., 0.8.0)

Options:
  -y, --yes           Skip confirmation prompts (non-interactive mode)
  -q, --quiet         Minimal output
  -h, --help          Show this help message

Exit codes:
  0 - Success
  1 - Error (validation failure, git error, etc.)
  2 - User cancelled

What this does:
  1. Creates release/<version> branch from main (version already correct)
  2. Pushes release branch to remote
  3. Bumps main to next version (e.g., 0.8.0 → 0.9.0)
  4. Commits and pushes main

After running this:
  - Update CHANGELOG.md on release branch
  - QA tests on release branch
  - Fix bugs directly on release branch (commit and push normally)
  - Run scripts/publish.sh when QA approves

Examples:
  $0 0.8.0              # Interactive mode
  $0 0.8.0 -y           # Auto-confirm

EOF
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

preflight_checks() {
    local version="$1"
    local failed=false

    print_header "📋 Pre-flight Checks"
    echo ""

    # Check 1: Current branch is main
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" ]]; then
        print_error "Current branch is '$current_branch', must be 'main'"
        echo "  Run: git checkout main"
        failed=true
    else
        print_success "On main branch"
    fi

    # Check 2: Working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        print_error "Working directory has uncommitted changes"
        echo "  Run: git status"
        echo "  Commit or stash changes before creating release"
        failed=true
    else
        print_success "Working directory is clean"
    fi

    # Check 3: main is up to date with remote
    git fetch origin main --quiet
    local local_commit=$(git rev-parse main)
    local remote_commit=$(git rev-parse origin/main)
    if [[ "$local_commit" != "$remote_commit" ]]; then
        print_error "main is not up to date with origin/main"
        echo "  Run: git pull origin main"
        failed=true
    else
        print_success "main is up to date with remote"
    fi

    # Check 4: Release branch doesn't already exist
    if git show-ref --verify --quiet "refs/heads/release/$version"; then
        print_error "Release branch 'release/$version' already exists locally"
        echo "  Run: git branch -d release/$version"
        failed=true
    else
        print_success "Release branch doesn't exist locally"
    fi

    if git show-ref --verify --quiet "refs/remotes/origin/release/$version"; then
        print_error "Release branch 'release/$version' already exists on remote"
        echo "  A release for version $version is already in progress"
        failed=true
    else
        print_success "Release branch doesn't exist on remote"
    fi

    # Check 5: No other release branches in progress
    local other_releases=$(git branch -r | grep "origin/release/" | grep -v "release/$version" || true)
    if [[ -n "$other_releases" ]]; then
        print_error "Other release branches in progress:"
        echo "$other_releases" | sed 's/^/  /'
        echo "  Only one release branch should exist at a time (GitFlow)"
        echo "  Complete or delete existing releases before creating new one"
        failed=true
    else
        print_success "No other release branches in progress"
    fi

    # Check 6: Version tag doesn't already exist
    if git show-ref --verify --quiet "refs/tags/v$version"; then
        print_error "Tag 'v$version' already exists - this version has already been released"
        echo "  Use a different version number or delete the tag if this is intentional"
        echo "  Existing tags: $(git tag -l | tail -5 | tr '\n' ' ')"
        failed=true
    else
        print_success "Version tag doesn't exist"
    fi

    # Check 7: Version update script exists (optional)
    if [[ ! -f "scripts/update-version.sh" ]]; then
        print_warning "Version update script not found: scripts/update-version.sh"
        print_warning "Version will need to be updated manually on main"
    fi

    echo ""

    if [[ "$failed" == true ]]; then
        print_error "Pre-flight checks failed. Please fix issues above."
        exit 1
    fi

    print_success "All pre-flight checks passed"
    echo ""
}

# =============================================================================
# Main Workflow
# =============================================================================

main() {
    # Parse arguments
    local version=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [[ -z "$version" ]]; then
                    version="$1"
                else
                    print_error "Too many arguments"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$version" ]]; then
        print_error "Missing required argument: version"
        echo ""
        echo "Usage: $0 <version> [options]"
        echo "Use --help for more information"
        exit 1
    fi

    # Validate version format
    if ! validate_version "$version"; then
        exit 1
    fi

    # Calculate next version for main branch
    local next_version=$(calculate_next_version "$version")

    # Run pre-flight checks
    preflight_checks "$version"

    # Show preview
    if [[ "$QUIET" == false ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 Release Preparation Plan for v$version"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Will perform these actions:"
        echo "  1. Create branch release/$version from main (version already correct)"
        echo "  2. Push release/$version to remote"
        echo "  3. Bump main to next version ($next_version)"
        echo "  4. Push main to remote"
        echo ""
        print_warning "After this completes, you must update CHANGELOG.md on the release branch"
        echo ""
        echo "Version will remain $version throughout QA testing."
        echo "Fix bugs directly on release branch during QA (commit and push normally)."
        echo ""
    fi

    # Confirm
    if ! confirm "Proceed with release preparation?"; then
        print_info "Cancelled by user"
        exit 2
    fi

    echo ""
    print_header "🚀 Creating Release Branch"
    echo ""

    # Step 1: Create release branch
    print_info "Creating branch release/$version from main..."
    git checkout -b "release/$version"

    # Verify branch was created
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "release/$version" ]]; then
        print_error "Failed to create release branch"
        exit 1
    fi
    print_success "Created branch release/$version"

    # Step 2: Push release branch
    print_info "Pushing release/$version to remote..."
    git push -u origin "release/$version"
    print_success "Pushed release/$version to remote"

    # Step 3: Return to main branch and bump version
    echo ""
    print_header "📦 Bumping Main Branch Version"
    echo ""

    print_info "Checking out main..."
    git checkout main

    print_info "Updating version to $next_version..."

    # Run version update script if it exists
    if [[ -f "scripts/update-version.sh" ]]; then
        scripts/update-version.sh "$next_version" -y --no-commit -q

        if [[ $? -ne 0 ]]; then
            print_error "Failed to update version"
            exit 1
        fi

        print_success "Updated version to $next_version"
    else
        print_warning "Version update script not found: scripts/update-version.sh"
        print_warning "Please update version manually before continuing"
        echo ""
        if ! confirm "Have you updated the version to $next_version?"; then
            print_error "Version not updated. Please update manually and re-run script."
            exit 1
        fi
    fi

    # Step 4: Commit and push main branch
    print_info "Committing version bump..."

    git add .
    git commit -m "Bump version to $next_version

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    print_success "Committed version bump"

    print_info "Pushing main to remote..."
    git push origin main
    print_success "Pushed main to remote"

    # Step 5: Verify and report
    echo ""
    print_header "✅ Release v$version Preparation Complete"
    echo ""

    # Get commit hash
    git checkout "release/$version" --quiet
    local release_commit=$(git rev-parse --short HEAD)
    git checkout main --quiet

    echo "Branch: release/$version"
    echo "Status: Pushed to remote"
    echo "Commit: $release_commit"
    echo ""

    print_warning "Next: Update CHANGELOG.md on release/$version branch"
    echo ""
    echo "After CHANGELOG is updated:"
    echo "  - Hand off to QA for testing on release/$version"
    echo "  - Fix bugs directly on release branch (commit and push normally)"
    echo "  - Run scripts/publish.sh when QA approves"
    echo ""
}

# Run main function
main "$@"
