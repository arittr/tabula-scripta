#!/bin/bash

###############################################################################
# Update version number in plugin.json
# Usage: ./scripts/update-version.sh <version>
# Example: ./scripts/update-version.sh 0.2.0
###############################################################################

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if version argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Version number required${NC}"
  echo "Usage: $0 <version>"
  echo "Example: $0 0.2.0"
  exit 1
fi

VERSION="$1"

# Validate version format (basic semver check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$ ]]; then
  echo -e "${RED}Error: Invalid version format${NC}"
  echo "Version should follow semver format (e.g., 0.2.0 or 1.0.0-beta.1)"
  exit 1
fi

echo -e "${BLUE}Updating version to ${VERSION}...${NC}\n"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq is not installed${NC}"
  echo "Please install jq to use this script:"
  echo "  macOS: brew install jq"
  echo "  Linux: apt-get install jq or yum install jq"
  exit 1
fi

# Update plugin.json
PLUGIN_JSON="$PROJECT_ROOT/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
  # Create backup
  cp "$PLUGIN_JSON" "$PLUGIN_JSON.bak"

  # Update version using jq
  jq --arg version "$VERSION" '.version = $version' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp"
  mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"

  # Remove backup if successful
  rm "$PLUGIN_JSON.bak"

  echo -e "${GREEN}✓${NC} Updated .claude-plugin/plugin.json"
else
  echo -e "${RED}✗${NC} File not found: $PLUGIN_JSON"
  exit 1
fi

echo -e "\n${GREEN}✅ Version ${VERSION} updated successfully${NC}"
