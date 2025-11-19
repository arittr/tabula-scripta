#!/usr/bin/env bash
# SessionStart hook for tabula-scripta plugin
# Injects working memory recall instructions into Claude's context

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read session-start hook documentation
session_start_instructions=$(cat "${PLUGIN_ROOT}/hooks/session-start.md" 2>&1 || echo "Error reading session-start hook documentation")

# Escape for JSON
instructions_escaped=$(echo "$session_start_instructions" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<IMPORTANT>\n**Tabula Scripta: Working Memory System**\n\nThis hook automatically loads relevant context from previous sessions.\n\n**Instructions:**\n\n${instructions_escaped}\n\n**Action Required:**\n1. Follow the session-start implementation steps above\n2. Use the correct MCP tool names (mcp__obsidian-vault__vault, mcp__obsidian-vault__edit, etc.)\n3. Present a concise 1-3 sentence summary to the user\n4. Complete within 2 seconds performance target\n\n**Note:** If MCP is unavailable, gracefully degrade and continue without memory.\n</IMPORTANT>"
  }
}
EOF

exit 0
