# MCP API Reference for Tabula Scripta

This document maps the conceptual operations used in hook documentation to the actual MCP tool calls provided by the Obsidian MCP server.

## Overview

The Obsidian MCP server provides a unified `mcp__obsidian-vault__vault` tool with different `action` parameters, rather than separate tools for each operation.

## Vault Operations

### Read Note

**Conceptual**: `read_note(vault, path)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "read",
  path: "claude/projects/project-name/entities/EntityName.md"
})
```

**Returns**:
```javascript
{
  result: {
    path: "...",
    content: [{ content: "...", frontmatter: {...} }],
    tags: [...],
    frontmatter: {...}
  }
}
```

**Notes**:
- Returns fragments by default (using adaptive strategy)
- To get full file, use `returnFullFile: true` parameter
- Frontmatter is automatically parsed and returned separately

### Create Note

**Conceptual**: `create_note(vault, path, content, frontmatter)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "create",
  path: "claude/projects/project-name/sessions/2025-11-18-session.md",
  content: "# Session Note\n\n## Work Log\n\n...",
  // Note: frontmatter should be included in content as YAML front matter
})
```

**Notes**:
- Frontmatter must be included in the content string as YAML front matter
- Format: `---\nkey: value\n---\n\n# Content...`
- Will fail if file already exists

### Update Note

**Conceptual**: `update_note(vault, path, content, frontmatter)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "update",
  path: "claude/projects/project-name/entities/EntityName.md",
  content: "# Updated Content\n\n...",
  // Note: include frontmatter in content
})
```

**Notes**:
- Replaces entire file content
- For partial updates, use `mcp__obsidian-vault__edit` instead (see Edit Operations below)
- Will fail if file doesn't exist

### Delete Note

**Conceptual**: `delete_note(vault, path)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "delete",
  path: "claude/projects/project-name/archive/old-file.md"
})
```

### Search Notes

**Conceptual**: `search_notes(query, path_filter)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "search",
  query: "session status:active",
  path: "claude/projects/project-name/sessions/"
})
```

**Advanced Search**:
```javascript
mcp__obsidian-vault__vault({
  action: "search",
  query: "memory system",
  includeContent: true,  // Search in content, not just filenames
  page: 1,
  pageSize: 10
})
```

**Search Operators**:
- `file:pattern` - Filter by filename
- `path:pattern` - Filter by path
- `content:text` - Search in content
- `tag:tagname` - Filter by tag
- `OR` - Multiple terms
- `"quoted phrase"` - Exact phrase
- `/regex/` - Regular expression

### List Files

**Conceptual**: `list_files(directory)`

**Actual MCP Call**:
```javascript
mcp__obsidian-vault__vault({
  action: "list",
  directory: "claude/projects/project-name/sessions"
})
```

**Returns**: Array of file paths relative to vault root

## Edit Operations

For partial updates (more efficient than replacing entire file), use the edit tool:

### Append to File

```javascript
mcp__obsidian-vault__edit({
  action: "append",
  path: "claude/projects/project-name/sessions/session.md",
  content: "\n## New Section\n\nNew content here..."
})
```

### Patch Specific Section

```javascript
mcp__obsidian-vault__edit({
  action: "patch",
  path: "claude/projects/project-name/entities/EntityName.md",
  targetType: "heading",
  target: "Key Decisions",  // Heading name
  operation: "append",  // or "prepend" or "replace"
  content: "\n- Decision made on 2025-11-18: ..."
})
```

**Patch Operations**:
- `targetType: "heading"` - Target a markdown heading
- `targetType: "block"` - Target a block by ID
- `targetType: "frontmatter"` - Update frontmatter field
- `operation: "append"` - Add after target
- `operation: "prepend"` - Add before target
- `operation: "replace"` - Replace target

### Update Frontmatter

```javascript
mcp__obsidian-vault__edit({
  action: "patch",
  path: "claude/projects/project-name/sessions/session.md",
  targetType: "frontmatter",
  target: "claude_last_accessed",  // Frontmatter key
  operation: "replace",
  content: "2025-11-18"
})
```

### Window Find/Replace

```javascript
mcp__obsidian-vault__edit({
  action: "window",
  path: "claude/projects/project-name/entities/EntityName.md",
  oldText: "old value",
  newText: "new value",
  fuzzyThreshold: 0.7  // Optional: fuzzy matching threshold
})
```

## Graph Operations

For exploring relationships between notes:

### Get Neighbors

```javascript
mcp__obsidian-vault__graph({
  action: "neighbors",
  sourcePath: "claude/projects/project-name/entities/EntityName.md"
})
```

### Get Backlinks

```javascript
mcp__obsidian-vault__graph({
  action: "backlinks",
  sourcePath: "claude/projects/project-name/entities/EntityName.md"
})
```

### Traverse Graph

```javascript
mcp__obsidian-vault__graph({
  action: "traverse",
  sourcePath: "claude/projects/project-name/_index.md",
  maxDepth: 2,
  followBacklinks: true,
  followForwardLinks: true
})
```

## Base Operations (Database-like Queries)

For structured queries over collections of notes:

### Query Base

```javascript
mcp__obsidian-vault__bases({
  action: "query",
  path: "claude/projects/project-name/queries/sessions.base",
  filters: [
    { property: "status", operator: "==", value: "active" }
  ],
  sort: { property: "created", order: "desc" },
  pagination: { page: 1, pageSize: 3 }
})
```

**Note**: Bases must be created first using action: "create"

## System Operations

### Get Server Info

```javascript
mcp__obsidian-vault__system({
  action: "info"
})
```

**Returns**:
```javascript
{
  result: {
    authenticated: true,
    service: "Obsidian MCP Plugin",
    versions: { obsidian: "1.0.0", self: "0.10.1" },
    mcp: {
      running: true,
      port: 3001,
      vault: "claude-memory"
    }
  }
}
```

## Common Patterns

### Pattern: Create Session Note with Frontmatter

```javascript
const frontmatter = {
  type: "session",
  project: "tabula-scripta",
  created: "2025-11-18",
  status: "active",
  claude_last_accessed: "2025-11-18"
};

const content = `---
${Object.entries(frontmatter).map(([k, v]) => `${k}: ${v}`).join('\n')}
---

# Session: 2025-11-18

## Work Log

- ${new Date().toISOString()}: Session started
`;

await mcp__obsidian-vault__vault({
  action: "create",
  path: "claude/projects/tabula-scripta/sessions/2025-11-18-session.md",
  content: content
});
```

### Pattern: Read and Update Note (with Conflict Detection)

```javascript
// 1. Read current note
const readResult = await mcp__obsidian-vault__vault({
  action: "read",
  path: "claude/projects/tabula-scripta/entities/EntityName.md",
  returnFullFile: true
});

const originalContent = readResult.result.content[0].content;
const loadedTimestamp = Date.now();

// 2. Parse and modify content
const updatedContent = originalContent + "\n\n## New Section\n\nNew content";

// 3. Before writing, check for conflicts by re-reading
const recheckResult = await mcp__obsidian-vault__vault({
  action: "read",
  path: "claude/projects/tabula-scripta/entities/EntityName.md",
  returnFullFile: true
});

if (recheckResult.result.content[0].content !== originalContent) {
  // Conflict detected - handle merge
  console.log("Conflict detected - file was modified");
} else {
  // No conflict - safe to update
  await mcp__obsidian-vault__vault({
    action: "update",
    path: "claude/projects/tabula-scripta/entities/EntityName.md",
    content: updatedContent
  });
}
```

### Pattern: Append to Heading (Efficient Partial Update)

```javascript
await mcp__obsidian-vault__edit({
  action: "patch",
  path: "claude/projects/tabula-scripta/entities/EntityName.md",
  targetType: "heading",
  target: "Key Decisions",
  operation: "append",
  content: `\n- 2025-11-18: Decided to use MCP unified vault API instead of separate tools`
});
```

### Pattern: Search Recent Sessions

```javascript
// Option 1: Using search with path filter
const searchResult = await mcp__obsidian-vault__vault({
  action: "search",
  query: "path:claude/projects/tabula-scripta/sessions/ file:2025-11-*",
  includeContent: false
});

// Option 2: List and filter
const listResult = await mcp__obsidian-vault__vault({
  action: "list",
  directory: "claude/projects/tabula-scripta/sessions"
});

// Then manually filter and sort by filename date
const recentSessions = listResult.result
  .filter(path => path.includes('/2025-11-'))
  .sort()
  .reverse()
  .slice(0, 3);
```

## Error Handling

### Common Errors

**FileNotFoundError**:
```javascript
{
  error: {
    code: "UNKNOWN_ERROR",
    message: "File not found: ..."
  }
}
```

**Directory Not Found**:
```javascript
{
  error: {
    code: "UNKNOWN_ERROR",
    message: "Directory not found: ..."
  }
}
```

**Absolute Path Error**:
```javascript
{
  error: {
    code: "ABSOLUTE_PATH",
    message: "Absolute paths are not allowed"
  }
}
```

### Error Handling Pattern

```javascript
try {
  const result = await mcp__obsidian-vault__vault({
    action: "read",
    path: "claude/projects/tabula-scripta/entities/EntityName.md"
  });

  // Check if result has error property
  if (result.error) {
    if (result.error.message.includes("not found")) {
      // Handle file not found
      console.log("File doesn't exist - creating new");
    } else {
      throw new Error(result.error.message);
    }
  }

  // Process result.result

} catch (error) {
  console.error("MCP operation failed:", error);
}
```

## Dataview Replacement Strategy

The hooks reference `dataview_query()` which doesn't exist in the MCP API. Here's how to replace it:

### Original Dataview Query (from hooks)
```javascript
// Conceptual dataview query
dataview_query({
  source: "claude/projects/tabula-scripta/sessions",
  filter: "status = 'active' OR status = 'archived'",
  sort: "created DESC",
  limit: 3
})
```

### Replacement Strategy

**Option 1: Use Bases (recommended for complex queries)**

1. Create a base definition first:
```javascript
await mcp__obsidian-vault__bases({
  action: "create",
  path: "claude/projects/tabula-scripta/queries/recent-sessions.base",
  config: {
    name: "Recent Sessions",
    source: "claude/projects/tabula-scripta/sessions",
    properties: {
      status: { type: "text" },
      created: { type: "date" },
      topic: { type: "text" }
    },
    views: {
      recent: {
        filters: [
          { property: "status", operator: "in", value: ["active", "archived"] }
        ],
        sort: { property: "created", order: "desc" },
        limit: 3
      }
    }
  }
});
```

2. Query the base:
```javascript
const result = await mcp__obsidian-vault__bases({
  action: "query",
  path: "claude/projects/tabula-scripta/queries/recent-sessions.base",
  viewName: "recent"
});
```

**Option 2: Use search + manual filtering (simpler, no setup)**

```javascript
// 1. List all sessions
const listResult = await mcp__obsidian-vault__vault({
  action: "list",
  directory: "claude/projects/tabula-scripta/sessions"
});

// 2. Read frontmatter for each (in parallel)
const sessions = await Promise.all(
  listResult.result.map(async path => {
    const readResult = await mcp__obsidian-vault__vault({
      action: "read",
      path: path
    });
    return {
      path,
      frontmatter: readResult.result.frontmatter,
      content: readResult.result.content[0].content
    };
  })
);

// 3. Filter and sort in code
const recentSessions = sessions
  .filter(s => s.frontmatter.status === 'active' || s.frontmatter.status === 'archived')
  .sort((a, b) => b.frontmatter.created.localeCompare(a.frontmatter.created))
  .slice(0, 3);
```

**Recommendation**: Use Option 2 (search + manual filtering) for session-start hook to keep it simple and avoid base setup overhead.

## Important Notes

1. **Paths are relative to vault root**: Always use paths relative to the vault root (e.g., `claude/projects/...`)

2. **No `vault` parameter needed**: The vault is determined by the MCP server configuration

3. **Frontmatter in content**: Unlike some APIs, frontmatter must be included in the content string as YAML front matter, not as a separate parameter

4. **Fragment vs Full File**: By default, `read` returns fragments. Use `returnFullFile: true` for complete content

5. **Prefer edit operations**: For partial updates, use `mcp__obsidian-vault__edit` (patch, append) instead of read-modify-write with vault update

6. **Error handling**: Always check for `result.error` property in responses

7. **Performance**: Use parallel operations with `Promise.all()` when loading multiple files
