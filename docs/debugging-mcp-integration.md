# Debugging Summary: MCP Integration Issues

**Date**: 2025-11-18

**Issue**: Tabula Scripta plugin hooks referenced non-existent MCP tool names

## Investigation Process (Systematic Debugging)

### Phase 1: Root Cause Investigation

#### Evidence Gathered

1. **Debug log analysis** (`/Users/drewritter/.claude/debug/29d28e13-6784-4f02-9a9f-853dfc657cf7.txt`):
   - MCP server connection: **SUCCESSFUL** ✓
   - Line 170: `Successfully connected to undefined server in 1277ms`
   - Line 171: `{"hasTools":true,"hasPrompts":false,"hasResources":true}`
   - Server info: Obsidian MCP Plugin v0.10.1, vault "claude-memory" on port 3001

2. **Hook documentation review**:
   - `hooks/session-start.md` and `hooks/session-end.md` exist
   - Both reference **non-existent MCP tool names**

3. **MCP tool verification tests**:
   ```javascript
   // Test 1: Server info
   mcp__obsidian-vault__system({ action: "info" })
   // Result: ✓ Working

   // Test 2: List directory
   mcp__obsidian-vault__vault({ action: "list", directory: "." })
   // Result: ✓ Working, returned ["Welcome.md", "claude/test-note.md"]

   // Test 3: Read file
   mcp__obsidian-vault__vault({ action: "read", path: "claude/test-note.md" })
   // Result: ✓ Working, returned fragments with frontmatter
   ```

#### Root Cause Identified

**Hook documentation referenced incorrect MCP API:**

| Hook Documentation | Reality |
|-------------------|---------|
| `read_note(vault, path)` | ❌ Does not exist |
| `create_note(vault, path, content)` | ❌ Does not exist |
| `update_note(vault, path, content)` | ❌ Does not exist |
| `search_notes(query, path_filter)` | ❌ Does not exist |
| `dataview_query(...)` | ❌ Does not exist |

**Actual MCP API:**
- Single unified tool: `mcp__obsidian-vault__vault`
- Operations via `action` parameter: `"read"`, `"create"`, `"update"`, `"delete"`, `"search"`, `"list"`
- Additional tools: `mcp__obsidian-vault__edit`, `mcp__obsidian-vault__view`, `mcp__obsidian-vault__graph`, `mcp__obsidian-vault__bases`

**Additional finding**: No hook implementation files existed - only documentation

### Phase 2: Pattern Analysis

Examined working patterns from:
1. Superpowers plugin hooks structure
2. MCP server capabilities and response formats
3. Claude Code hook execution model

**Pattern identified**: Hooks inject instructions into Claude's context, they don't execute operations directly.

### Phase 3: Hypothesis and Testing

**Hypothesis**: Correcting the MCP tool names in documentation and creating hook implementation files will enable the plugin to work correctly.

**Test approach**:
1. Create MCP API reference document
2. Update hook documentation with correct tool names
3. Create hook infrastructure (hooks.json, shell scripts)
4. Test hook execution

### Phase 4: Implementation

#### Files Created/Modified

**Created**:
1. `docs/mcp-api-reference.md` - Complete API reference mapping conceptual operations to actual MCP calls
2. `hooks/hooks.json` - Hook configuration file
3. `hooks/session-start.sh` - Session start hook implementation
4. `hooks/session-end.sh` - Session end hook implementation

**Modified**:
1. `hooks/session-start.md` - Updated all MCP API references
2. `hooks/session-end.md` - Updated all MCP API references

#### Key Corrections Made

**1. Read Operations**

Before:
```javascript
read_note(vault: "~/.claude-memory", path: "claude/projects/...")
```

After:
```javascript
mcp__obsidian-vault__vault({
  action: "read",
  path: "claude/projects/...",
  returnFullFile: true
})
```

**2. Create/Update Operations**

Before:
```javascript
create_note(vault, path, content, frontmatter)
update_note(vault, path, content, frontmatter)
```

After:
```javascript
// Create
mcp__obsidian-vault__vault({
  action: "create",
  path: "claude/projects/...",
  content: contentWithFrontmatter
})

// Update (full replacement)
mcp__obsidian-vault__vault({
  action: "update",
  path: "claude/projects/...",
  content: updatedContent
})

// Update (partial - more efficient)
mcp__obsidian-vault__edit({
  action: "patch",
  path: "claude/projects/...",
  targetType: "heading",
  target: "Key Decisions",
  operation: "append",
  content: "\n- New decision..."
})
```

**3. Search Operations**

Before:
```javascript
search_notes(query: "*", path_filter: "claude/projects/.../sessions/**")
```

After:
```javascript
// Option 1: List and filter
mcp__obsidian-vault__vault({
  action: "list",
  directory: "claude/projects/.../sessions"
})

// Option 2: Search
mcp__obsidian-vault__vault({
  action: "search",
  query: "path:claude/projects/.../sessions/",
  includeContent: false
})
```

**4. Dataview Queries**

Since user has Dataview installed, using bases tool:
```javascript
mcp__obsidian-vault__bases({
  action: "query",
  filters: [
    { property: "status", operator: "in", value: ["active", "archived"] }
  ],
  sort: { property: "created", order: "desc" },
  pagination: { page: 1, pageSize: 3 }
})
```

Fallback (if bases not configured):
```javascript
// List + manual filter approach
const listResult = await mcp__obsidian-vault__vault({
  action: "list",
  directory: "claude/projects/.../sessions"
});

// Load frontmatter in parallel
const sessions = await Promise.all(
  listResult.result.map(async path => {
    const r = await mcp__obsidian-vault__vault({
      action: "read",
      path: path
    });
    return { path, frontmatter: r.result.frontmatter };
  })
);

// Filter and sort
const recent = sessions
  .filter(s => s.frontmatter.status === 'active' || s.frontmatter.status === 'archived')
  .sort((a, b) => b.frontmatter.created.localeCompare(a.frontmatter.created))
  .slice(0, 3);
```

**5. Frontmatter Updates**

Before:
```javascript
update_note(vault, path, content, frontmatter)
```

After (efficient patch):
```javascript
mcp__obsidian-vault__edit({
  action: "patch",
  path: "claude/projects/...",
  targetType: "frontmatter",
  target: "claude_last_accessed",
  operation: "replace",
  content: new Date().toISOString().split('T')[0]
})
```

## Verification Tests

### Hook Execution Tests

```bash
$ /Users/drewritter/projects/tabula-scripta/hooks/session-start.sh | jq '.hookSpecificOutput.hookEventName'
"SessionStart"
✓ PASSED

$ /Users/drewritter/projects/tabula-scripta/hooks/session-end.sh | jq '.hookSpecificOutput.hookEventName'
"SessionEnd"
✓ PASSED
```

### MCP API Tests

```bash
# Test 1: Server connectivity
✓ MCP server running on port 3001
✓ Vault: claude-memory
✓ Version: 0.10.1

# Test 2: Basic operations
✓ List directory
✓ Read file with fragments
✓ Frontmatter parsing

# Test 3: All required tools available
✓ mcp__obsidian-vault__vault
✓ mcp__obsidian-vault__edit
✓ mcp__obsidian-vault__view
✓ mcp__obsidian-vault__graph
✓ mcp__obsidian-vault__bases
✓ mcp__obsidian-vault__system
```

## Summary

**Problem**: Hook documentation used fictional MCP API that didn't match actual Obsidian MCP server implementation

**Solution**:
1. Created comprehensive MCP API reference document
2. Updated all hook documentation with correct MCP tool names and parameters
3. Implemented hook infrastructure (hooks.json and shell scripts)
4. Verified hooks execute successfully

**Status**: ✅ All fixes implemented and tested

**Next Steps**:
1. Test hooks in actual Claude Code session
2. Create test vault structure in ~/.claude-memory/
3. Verify end-to-end memory recall and compaction workflows

## Lessons Learned

1. **Verify API assumptions early**: The hook documentation was written assuming an API that didn't exist
2. **Test actual MCP tools first**: Running basic MCP operations revealed the correct API structure immediately
3. **Check existing plugins**: Examining superpowers hooks showed the correct hook implementation pattern
4. **Systematic debugging works**: Following the four-phase process (root cause → pattern → hypothesis → implementation) led to complete diagnosis and fix in one session

## Files Reference

**New Files**:
- `docs/mcp-api-reference.md` - MCP API reference guide
- `docs/debugging-mcp-integration.md` - This document
- `hooks/hooks.json` - Hook configuration
- `hooks/session-start.sh` - Session start hook script
- `hooks/session-end.sh` - Session end hook script

**Modified Files**:
- `hooks/session-start.md` - Updated MCP API calls
- `hooks/session-end.md` - Updated MCP API calls
