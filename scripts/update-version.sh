#!/bin/bash

# CloudX Flutter SDK - Version Updater Script
# Updates Flutter SDK version across critical files
#
# Usage: ./scripts/update-version.sh <new-version> [options]
#
# Arguments:
#   new-version    Version in x.y.z format (e.g., 0.9.0)
#
# Options:
#   -y, --yes           Skip confirmation prompts (non-interactive mode)
#   --no-commit         Don't create git commit
#   -q, --quiet         Minimal output
#   -h, --help          Show this help message
#
# Exit codes:
#   0 - Success
#   1 - Error (invalid arguments, file not found, etc.)
#   2 - User cancelled
#
# Examples:
#   ./scripts/update-version.sh 0.9.0                      # Interactive mode
#   ./scripts/update-version.sh 0.9.0 -y                   # Auto-confirm
#   ./scripts/update-version.sh 0.9.0 -y --no-commit       # For release scripts

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
AUTO_YES=false
NO_COMMIT=false
QUIET=false

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to repo root
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

# Get current Flutter SDK version from pubspec.yaml
get_current_version() {
    if [[ ! -f "cloudx_flutter_sdk/pubspec.yaml" ]]; then
        print_error "pubspec.yaml not found"
        return 1
    fi

    local version=$(grep '^version:' cloudx_flutter_sdk/pubspec.yaml | sed 's/version: *//' | tr -d '\r\n')
    echo "$version"
}

# Show help message
show_help() {
    cat << EOF
CloudX Flutter SDK - Version Updater

Updates Flutter SDK version across critical files:
  - cloudx_flutter_sdk/pubspec.yaml
  - cloudx_flutter_sdk/android/build.gradle
  - cloudx_flutter_sdk/ios/cloudx_flutter.podspec
  - README.md (root and SDK)

Usage: $0 <new-version> [options]

Arguments:
  new-version    Version in x.y.z format (e.g., 0.9.0)

Options:
  -y, --yes           Skip confirmation prompts (non-interactive mode)
  --no-commit         Don't create git commit
  -q, --quiet         Minimal output
  -h, --help          Show this help message

Exit codes:
  0 - Success
  1 - Error (invalid arguments, file not found, etc.)
  2 - User cancelled

Examples:
  $0 0.9.0                    # Interactive mode
  $0 0.9.0 -y                 # Auto-confirm
  $0 0.9.0 -y --no-commit     # For release scripts (no commit)

EOF
}

# =============================================================================
# Update Functions
# =============================================================================

update_pubspec() {
    local old_version="$1"
    local new_version="$2"
    local file="cloudx_flutter_sdk/pubspec.yaml"

    print_info "Updating $file..."
    sed -i.bak "s/^version: $old_version/version: $new_version/" "$file"
    rm -f "${file}.bak"
    print_success "Updated pubspec.yaml"
}

update_build_gradle() {
    local old_version="$1"
    local new_version="$2"
    local file="cloudx_flutter_sdk/android/build.gradle"

    print_info "Updating $file..."
    sed -i.bak "s/^version '$old_version'/version '$new_version'/" "$file"
    rm -f "${file}.bak"
    print_success "Updated android/build.gradle"
}

update_podspec() {
    local old_version="$1"
    local new_version="$2"
    local file="cloudx_flutter_sdk/ios/cloudx_flutter.podspec"

    print_info "Updating $file..."
    sed -i.bak "s/s\.version *= *'$old_version'/s.version          = '$new_version'/" "$file"
    rm -f "${file}.bak"
    print_success "Updated cloudx_flutter.podspec"
}

update_readmes() {
    local old_version="$1"
    local new_version="$2"

    print_info "Updating README files..."

    # Update root README.md
    if [[ -f "README.md" ]]; then
        sed -i.bak "s/cloudx_flutter: \^$old_version/cloudx_flutter: ^$new_version/g" README.md
        sed -i.bak "s/ref: v$old_version/ref: v$new_version/g" README.md
        rm -f README.md.bak
    fi

    # Update SDK README.md
    if [[ -f "cloudx_flutter_sdk/README.md" ]]; then
        sed -i.bak "s/cloudx_flutter: \^$old_version/cloudx_flutter: ^$new_version/g" cloudx_flutter_sdk/README.md
        sed -i.bak "s/ref: v$old_version/ref: v$new_version/g" cloudx_flutter_sdk/README.md
        rm -f cloudx_flutter_sdk/README.md.bak
    fi

    print_success "Updated README files"
}

update_all_files() {
    local old_version="$1"
    local new_version="$2"

    update_pubspec "$old_version" "$new_version"
    update_build_gradle "$old_version" "$new_version"
    update_podspec "$old_version" "$new_version"
    update_readmes "$old_version" "$new_version"
}

# =============================================================================
# Git Functions
# =============================================================================

create_commit() {
    local old_version="$1"
    local new_version="$2"

    if [[ "$NO_COMMIT" == true ]]; then
        print_info "Skipping git commit (--no-commit flag)"
        return 0
    fi

    if ! confirm "Create git commit for these changes?"; then
        print_info "Skipping commit"
        return 0
    fi

    # Stage changes
    git add cloudx_flutter_sdk/pubspec.yaml \
            cloudx_flutter_sdk/android/build.gradle \
            cloudx_flutter_sdk/ios/cloudx_flutter.podspec \
            README.md \
            cloudx_flutter_sdk/README.md

    # Create commit
    local commit_msg="Update Flutter SDK version to $new_version

- Updated version from $old_version to $new_version
- Updated pubspec.yaml, build.gradle, and podspec

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    git commit -m "$commit_msg"

    print_success "Changes committed successfully"

    if [[ "$QUIET" == false ]]; then
        echo ""
        git log -1 --oneline
    fi
}

show_diff() {
    if [[ "$QUIET" == false ]]; then
        echo ""
        print_info "Changes made:"
        echo ""
        git diff HEAD cloudx_flutter_sdk/pubspec.yaml \
                      cloudx_flutter_sdk/android/build.gradle \
                      cloudx_flutter_sdk/ios/cloudx_flutter.podspec \
                      README.md \
                      cloudx_flutter_sdk/README.md || true
        echo ""
    fi
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    # Parse arguments
    local new_version=""

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
            --no-commit)
                NO_COMMIT=true
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
                if [[ -z "$new_version" ]]; then
                    new_version="$1"
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
    if [[ -z "$new_version" ]]; then
        print_error "Missing required argument: new-version"
        echo ""
        echo "Usage: $0 <new-version> [options]"
        echo "Use --help for more information"
        exit 1
    fi

    # Validate version format
    if ! validate_version "$new_version"; then
        exit 1
    fi

    # Get current version
    local old_version=$(get_current_version)

    if [[ -z "$old_version" ]]; then
        print_error "Could not detect current Flutter SDK version"
        exit 1
    fi

    # Check if already at target version
    if [[ "$old_version" == "$new_version" ]]; then
        print_warning "Current version is already $new_version"
        exit 0
    fi

    # Show summary
    if [[ "$QUIET" == false ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "CloudX Flutter SDK - Version Update"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Old Version:   $old_version"
        echo "New Version:   $new_version"
        echo ""
        echo "Will update:"
        echo "  ✓ cloudx_flutter_sdk/pubspec.yaml"
        echo "  ✓ cloudx_flutter_sdk/android/build.gradle"
        echo "  ✓ cloudx_flutter_sdk/ios/cloudx_flutter.podspec"
        echo "  ✓ README.md"
        echo "  ✓ cloudx_flutter_sdk/README.md"
        echo ""
    fi

    # Confirm (unless -y flag)
    if ! confirm "Proceed with update?"; then
        print_info "Cancelled by user"
        exit 2
    fi

    # Update files
    update_all_files "$old_version" "$new_version"

    # Show diff
    show_diff

    # Create commit
    create_commit "$old_version" "$new_version"

    print_success "Version update complete: $old_version → $new_version"

    if [[ "$QUIET" == false ]]; then
        echo ""
        print_warning "Remember to update CHANGELOG.md manually"
    fi
}

# Run main function
main "$@"
