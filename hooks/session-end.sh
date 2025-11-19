#!/usr/bin/env bash
# SessionEnd hook for tabula-scripta plugin
# Injects working memory finalization instructions into Claude's context

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read session-end hook documentation
session_end_instructions=$(cat "${PLUGIN_ROOT}/hooks/session-end.md" 2>&1 || echo "Error reading session-end hook documentation")

# Escape for JSON
instructions_escaped=$(echo "$session_end_instructions" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionEnd",
    "additionalContext": "<IMPORTANT>\n**Tabula Scripta: Session Finalization**\n\nThis hook automatically finalizes working memory at session end.\n\n**Instructions:**\n\n${instructions_escaped}\n\n**Action Required:**\n1. Follow the session-end implementation steps above\n2. Check compaction threshold (500 lines OR 3 days old)\n3. If threshold met: extract knowledge, update entities, archive session\n4. Use the correct MCP tool names (mcp__obsidian-vault__vault, mcp__obsidian-vault__edit, etc.)\n5. Handle errors gracefully\n\n**Note:** If MCP is unavailable, notify user and provide manual cleanup steps.\n</IMPORTANT>"
  }
}
EOF

exit 0
