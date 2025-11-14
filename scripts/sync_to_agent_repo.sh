#!/bin/bash
set -e

AGENT_REPO_URL="${AGENT_REPO_URL:-https://github.com/cloudx-io/cloudx-sdk-agents}"
# Default: sibling directory to SDK repo
SDK_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_REPO_DIR="${AGENT_REPO_DIR:-$(dirname "$SDK_REPO_DIR")/cloudx-sdk-agents}"

echo "🔄 Syncing Flutter SDK to agent repository..."
echo "   Repo: $AGENT_REPO_URL"
echo "   Dir: $AGENT_REPO_DIR"

# Check if agent repo exists
if [ -d "$AGENT_REPO_DIR/.git" ]; then
    echo "📂 Agent repo exists, pulling latest..."
    cd "$AGENT_REPO_DIR"
    git fetch origin
    git checkout main
    git pull origin main
    cd "$SDK_REPO_DIR"
else
    echo "📥 Cloning agent repo to sibling directory..."
    cd "$(dirname "$SDK_REPO_DIR")"
    git clone "$AGENT_REPO_URL" cloudx-sdk-agents
    cd "$SDK_REPO_DIR"
fi

# Copy SDK_VERSION.yaml for comparison
# Note: This is the Flutter SDK's source of truth, will be merged into agent repo's SDK_VERSION.yaml (Flutter section)
cp .claude/maintenance/SDK_VERSION.yaml "$AGENT_REPO_DIR/SDK_VERSION.yaml.flutter"

echo "✅ Agent repo ready at $AGENT_REPO_DIR"
echo "💡 Run maintainer agent with AGENT_REPO_DIR=$AGENT_REPO_DIR"
