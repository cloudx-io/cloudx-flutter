#!/bin/bash

# SDK Release Publishing Script
# Publishes release to production by creating tags and merging back to main (GitFlow Workflow 2)
#
# Usage: ./scripts/publish.sh [options]
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
#   1. Extracts version from current release branch
#   2. Prompts to confirm CHANGELOG has been updated
#   3. Creates git tag v<version> on release branch
#   4. Pushes tag to remote (triggers GitHub Action to create release)
#   5. Merges release/<version> → main
#   6. Deletes release branch (tag preserves release state)
#
# Prerequisites:
#   - Must be run from a release branch (e.g., release/0.11.0)
#
# After running this:
#   - Release is tagged and live on GitHub
#   - Publish to package registry when ready (if applicable)
#   - Announce to customers

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

# Show help message
show_help() {
    cat << EOF
SDK Release Publishing Script

Publishes release to production by creating tags and merging back to main (GitFlow).

Usage: $0 [options]

Options:
  -y, --yes           Skip confirmation prompts (non-interactive mode)
  -q, --quiet         Minimal output
  -h, --help          Show this help message

Exit codes:
  0 - Success
  1 - Error (validation failure, git error, etc.)
  2 - User cancelled

What this does:
  1. Extracts version from current release branch
  2. Prompts to confirm CHANGELOG has been updated
  3. Creates git tag v<version> on release branch
  4. Pushes tag to remote (triggers GitHub Action to create release)
  5. Merges release/<version> → main
  6. Deletes release branch (tag preserves release state)

Prerequisites:
  - Must be run from a release branch (e.g., release/0.11.0)

After running this:
  - Release is tagged and live on GitHub
  - Publish to package registry when ready (if applicable)
  - Announce to customers

Examples:
  $0                    # Interactive mode
  $0 -y                 # Auto-confirm

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

    # Check 1: Current branch is release branch
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "release/$version" ]]; then
        print_error "Current branch is '$current_branch', must be 'release/$version'"
        echo "  Run: git checkout release/$version"
        failed=true
    else
        print_success "On release/$version branch"
    fi

    # Check 2: Working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        print_error "Working directory has uncommitted changes"
        echo "  Run: git status"
        echo "  Commit or stash changes before publishing"
        failed=true
    else
        print_success "Working directory is clean"
    fi

    # Check 3: Release branch is up to date with remote
    git fetch origin "release/$version" --quiet 2>/dev/null || true
    local local_commit=$(git rev-parse "release/$version" 2>/dev/null || echo "")
    local remote_commit=$(git rev-parse "origin/release/$version" 2>/dev/null || echo "")

    if [[ -n "$local_commit" ]] && [[ -n "$remote_commit" ]]; then
        if [[ "$local_commit" != "$remote_commit" ]]; then
            print_error "Release branch is not up to date with origin/release/$version"
            echo "  Run: git pull"
            failed=true
        else
            print_success "Release branch is up to date with remote"
        fi
    fi

    # Check 4: Git tag doesn't already exist
    if git show-ref --verify --quiet "refs/tags/v$version"; then
        print_error "Tag 'v$version' already exists - this release is already published"
        echo "  This version has already been released"
        echo "  Use a different version or delete the tag if this is intentional"
        failed=true
    else
        print_success "Version tag doesn't exist"
    fi

    # Check 5: main is up to date with remote
    git fetch origin main --quiet
    local main_local=$(git rev-parse main)
    local main_remote=$(git rev-parse origin/main)
    if [[ "$main_local" != "$main_remote" ]]; then
        print_error "main is not up to date with origin/main"
        echo "  Run: git checkout main && git pull"
        failed=true
    else
        print_success "main is up to date with remote"
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
                print_error "Unexpected argument: $1"
                echo "This command takes no positional arguments"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Step 1: Get version from current branch
    local current_branch=$(git branch --show-current)

    if [[ ! "$current_branch" =~ ^release/ ]]; then
        print_error "Not on a release branch"
        echo ""
        echo "Current branch: $current_branch"
        echo ""
        echo "This script must be run from a release branch."
        echo "Please checkout the release branch first:"
        echo "  git checkout release/<version>"
        exit 1
    fi

    local version="${current_branch#release/}"

    print_header "📋 Publishing Release v$version"
    echo ""

    # Run pre-flight checks
    preflight_checks "$version"

    # Step 2: CHANGELOG Review Gate
    print_header "📝 CHANGELOG Review"
    echo ""

    if ! confirm "Has CHANGELOG been updated with release notes for v$version?"; then
        print_error "CHANGELOG not ready - please update before publishing"
        exit 1
    fi

    print_success "CHANGELOG confirmed"
    echo ""

    # Step 3: Show preview
    if [[ "$QUIET" == false ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 Publishing v$version"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Actions:"
        echo "  1. Create and push tag v$version"
        echo "  2. Merge release/$version → main"
        echo "  3. Delete release/$version branch"
        echo ""
    fi

    # Confirm
    if ! confirm "Proceed with production release?"; then
        print_info "Cancelled by user"
        exit 2
    fi

    echo ""
    print_header "🚀 Publishing Release"
    echo ""

    # Step 4: Create git tag
    print_info "Creating tag v$version..."
    git checkout "release/$version" --quiet
    git pull origin "release/$version" --quiet
    git tag -a "v$version" -m "Release v$version"
    git push origin "v$version"
    print_success "Created and pushed tag v$version"

    # Step 5: Merge release → main
    print_info "Merging release/$version → main..."
    git checkout main --quiet
    git pull origin main --quiet

    # Attempt merge
    if git merge --no-ff "release/$version" -m "Merge release/$version to main" 2>/dev/null; then
        print_success "Merged without conflicts"
    else
        # Conflicts detected
        print_error "Merge conflicts detected"
        echo ""
        echo "Conflicting files:"
        git diff --name-only --diff-filter=U | sed 's/^/  /'
        echo ""
        echo "Please resolve conflicts manually:"
        echo "  1. Resolve conflicts in the listed files"
        echo "  2. git add <files>"
        echo "  3. git commit"
        echo "  4. git push origin main"
        echo "  5. Manually delete release branch: git push origin --delete release/$version"
        echo ""
        echo "To abort:"
        echo "  git merge --abort"
        exit 1
    fi

    print_info "Pushing main to remote..."
    git push origin main
    print_success "Pushed main to remote"

    # Step 6: Delete release branch
    print_info "Deleting release branch..."
    git branch -d "release/$version"
    git push origin --delete "release/$version"
    print_success "Deleted release/$version branch"

    # Step 7: Final report
    echo ""
    print_header "✅ Production Release v$version Complete!"
    echo ""

    local tag_commit=$(git rev-parse --short "v$version")

    echo "Summary:"
    echo "  ✓ Created tag v$version"
    echo "  ✓ Tagged commit: $tag_commit"
    echo "  ✓ Merged release/$version → main"
    echo "  ✓ Deleted release/$version branch (tag preserves release state)"
    echo "  ✓ Pushed to remote"
    echo ""

    echo "Next steps:"
    echo "  1. GitHub Action will create release automatically (on tag push)"
    echo "  2. Publish to package registry when ready (if applicable)"
    echo "  3. Announce release to customers"
    echo ""
    echo "Release v$version is now live!"
    echo ""
}

# Run main function
main "$@"
