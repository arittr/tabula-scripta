# Vault Structure Guide

This guide documents the expected Obsidian vault structure for Tabula Scripta's working memory system.

## Overview

Tabula Scripta stores working memory in an Obsidian vault at `~/.claude-memory/`. The vault is organized hierarchically with projects, sessions, entities, and archives.

## Directory Structure

```
~/.claude-memory/
└── claude/
    ├── projects/                    # Project-specific memory
    │   └── {project-name}/
    │       ├── _index.md            # Project overview (required)
    │       ├── sessions/            # Active session notes
    │       │   └── YYYY-MM-DD-{topic}.md
    │       ├── entities/            # Project-specific knowledge
    │       │   └── {Entity Name}.md
    │       ├── archive/             # Archived content
    │       │   └── sessions/
    │       │       └── YYYY-MM-DD-{topic}.md
    │       └── {project}.base       # Dataview base (optional)
    └── global/                      # Cross-project memory
        └── entities/                # Shared knowledge
            └── {Entity Name}.md
```

## File Types and Templates

### 1. Project Index (`_index.md`)

The project index is the entry point for a project's memory. It links to the most important entities.

**Location:** `claude/projects/{project-name}/_index.md`

**Template:**
```markdown
---
type: project-index
project: {project-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# {Project Name} Project

Brief description of the project.

## Key Entities

- [[Entity Name 1]] - Brief description
- [[Entity Name 2]] - Brief description
- [[Entity Name 3]] - Brief description

## Recent Focus

What you've been working on recently.

## Active Goals

1. Current goal 1
2. Current goal 2
3. Current goal 3
```

**Example:**
```markdown
---
type: project-index
project: tabula-scripta
created: 2025-11-18
updated: 2025-11-19
---

# Tabula Scripta Project

Working memory system plugin for Claude Code that integrates with Obsidian via MCP.

## Key Entities

- [[MCP Integration]] - Obsidian MCP server integration patterns
- [[Memory System Architecture]] - Core system design and workflows
- [[Session Hooks]] - Automatic recall and compaction hooks

## Recent Focus

Building session lifecycle hooks and testing compaction workflow.

## Active Goals

1. Complete end-to-end testing
2. Document setup process
3. Package for plugin marketplace
```

### 2. Session Notes

Session notes track work done during a Claude Code session, including decisions, questions, and context.

**Location:** `claude/projects/{project-name}/sessions/YYYY-MM-DD-{topic}.md`

**Naming Convention:**
- Date: `YYYY-MM-DD` (ISO 8601 format)
- Topic: lowercase, hyphen-separated, descriptive (e.g., `debugging-mcp`, `implementing-hooks`)

**Template:**
```markdown
---
type: session
project: {project-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: active
claude_last_accessed: YYYY-MM-DD
topic: {topic}
---

# Session: YYYY-MM-DD - {Topic Title}

## Work Log

### YYYY-MM-DDTHH:MM:SS - Session Started

Description of what you're working on.

### YYYY-MM-DDTHH:MM:SS - {Activity}

Details about the work performed.

## Decisions Made

- YYYY-MM-DD: Decision description and rationale

## Open Questions

- Question or blocker requiring resolution

## Entities Referenced

- [[Entity Name 1]]
- [[Entity Name 2]]

## Next Steps

- Task 1
- Task 2
```

**Example:**
```markdown
---
type: session
project: tabula-scripta
created: 2025-11-19
updated: 2025-11-19
status: active
claude_last_accessed: 2025-11-19
topic: vault-structure-docs
---

# Session: 2025-11-19 - Vault Structure Documentation

## Work Log

### 2025-11-19T14:30:00 - Session Started

Creating comprehensive vault structure documentation with examples and best practices.

### 2025-11-19T14:45:00 - Documentation Structure

Outlined main sections:
- Directory structure overview
- File type templates with examples
- Naming conventions
- Setup instructions

## Decisions Made

- 2025-11-19: Include both templates and real examples for clarity
- 2025-11-19: Document both required and optional files

## Open Questions

None

## Entities Referenced

- [[Documentation Standards]]
- [[Setup Process]]

## Next Steps

- Complete documentation
- Test setup instructions
- Add to README
```

### 3. Entity Notes

Entity notes capture persistent knowledge about concepts, patterns, gotchas, and architectural decisions.

**Location:**
- Project-specific: `claude/projects/{project-name}/entities/{Entity Name}.md`
- Global: `claude/global/entities/{Entity Name}.md`

**Naming Convention:**
- Use Title Case with spaces (e.g., `MCP Integration.md`, `Memory System Architecture.md`)
- Descriptive, specific names
- Avoid abbreviations unless widely known

**Template:**
```markdown
---
type: entity
project: {project-name or "global"}
created: YYYY-MM-DD
updated: YYYY-MM-DD
claude_last_accessed: YYYY-MM-DD
tags:
  - tag1
  - tag2
cross_project_recalls: []
---

# {Entity Name}

Brief description of what this entity represents.

## Overview

Detailed explanation of the concept, system, or pattern.

## Key Decisions

- YYYY-MM-DD: Decision description and rationale

## Architecture / Concepts / Patterns

Technical details, design patterns, or conceptual explanations.

## Gotchas & Troubleshooting

- **Issue description** - How to avoid or resolve it

## References

- Related files, documentation, or sessions
- External links
```

**Example:**
```markdown
---
type: entity
project: tabula-scripta
created: 2025-11-18
updated: 2025-11-19
claude_last_accessed: 2025-11-19
tags:
  - mcp
  - obsidian
  - integration
cross_project_recalls: []
---

# MCP Integration

Integration with Obsidian via Model Context Protocol (MCP) server.

## Overview

The Obsidian MCP server provides a unified API through the `mcp__obsidian-vault__vault` tool with different action parameters.

## Key Decisions

- 2025-11-18: Use unified vault API instead of separate tools
- 2025-11-18: Prefer edit tool for partial updates (more efficient)
- 2025-11-18: Include frontmatter in content string as YAML front matter

## Architecture

### MCP Tools Available

1. **vault** - Core CRUD operations (read, create, update, delete, search, list)
2. **edit** - Efficient partial updates (window, append, patch, at_line)
3. **view** - View operations (file, window, active)
4. **graph** - Graph navigation (neighbors, traverse, backlinks)

### API Patterns

**Read with full content:**
```javascript
mcp__obsidian-vault__vault({
  action: "read",
  path: "claude/projects/...",
  returnFullFile: true
})
```

## Gotchas & Troubleshooting

- **Paths are relative to vault root** - Use `claude/projects/...` not absolute paths
- **Path handling** - MCP vault paths must be relative to vault root, not absolute filesystem paths

## References

- API Reference: `docs/mcp-api-reference.md`
- Server: Obsidian MCP Plugin v0.10.1
- [[2025-11-19-vault-structure-docs]] - Session where this was refined
```

### 4. Archived Sessions

Archived sessions are compacted session notes moved to preserve history while keeping the sessions directory manageable.

**Location:** `claude/projects/{project-name}/archive/sessions/YYYY-MM-DD-{topic}.md`

**Structure:** Same as active session notes, but with:
- `status: archived` in frontmatter
- `compacted_date: YYYY-MM-DD` added to frontmatter
- Full content preserved (never truncated)

**Example:**
```markdown
---
type: session
project: tabula-scripta
created: 2025-11-15
updated: 2025-11-15
status: archived
claude_last_accessed: 2025-11-15
topic: test-compaction
compacted_date: 2025-11-19
---

# Session: 2025-11-15 - Test Compaction Workflow

[Full session content preserved...]
```

### 5. Dataview Base (Optional)

A Dataview base file defines queries and views for efficient session access.

**Location:** `claude/projects/{project-name}/{project-name}.base`

**Example:** See `docs/vault-structure.md` for the sessions.base example created earlier.

## Frontmatter Field Reference

### Required Fields (All Files)

- **type**: File type (`project-index`, `session`, `entity`)
- **project**: Project name or `"global"`
- **created**: Creation date (YYYY-MM-DD)
- **updated**: Last updated date (YYYY-MM-DD)

### Session-Specific Fields

- **status**: `active`, `archived`, or `compaction_failed`
- **claude_last_accessed**: Date (YYYY-MM-DD)
- **topic**: Session topic slug
- **compacted_date**: (archived only) Date of compaction

### Entity-Specific Fields

- **tags**: Array of tags
- **cross_project_recalls**: Array of cross-project recall records (optional)

## Naming Conventions

### Project Names

- Lowercase, hyphen-separated
- Match git repository name when possible
- Examples: `tabula-scripta`, `my-web-app`, `data-pipeline`

### Session Topics

- Lowercase, hyphen-separated
- Descriptive but concise
- Examples: `debugging-mcp`, `implementing-hooks`, `refactoring-auth`

### Entity Names

- Title Case with spaces
- Specific and descriptive
- Examples: `MCP Integration`, `Authentication System`, `Database Schema`

## Best Practices

### Project Index

1. **Keep entity list to 5-10 most important items** - This is what loads on session start
2. **Update "Recent Focus" regularly** - Helps with context restoration
3. **Link to entities, not sessions** - Sessions are temporal, entities are persistent

### Session Notes

1. **Use timestamped work log entries** - Makes timeline clear
2. **Record decisions with dates** - Track when and why choices were made
3. **Link to entities liberally** - Creates backlinks and context
4. **Keep open questions updated** - Remove when resolved or move to entity notes

### Entity Notes

1. **Focus on WHY not WHAT** - Code shows what, entities explain why
2. **Keep gotchas section updated** - Save future you from repeated mistakes
3. **Use consistent section structure** - Makes scanning easier
4. **Link to related entities** - Build knowledge graph

### Archiving

1. **Let hooks handle it** - Don't manually archive unless needed
2. **Check archived sessions occasionally** - Ensure knowledge was extracted
3. **Never delete archived sessions** - They're historical record

## Setup Instructions

### Initial Vault Creation

1. Create the vault directory:
   ```bash
   mkdir -p ~/.claude-memory/claude/projects
   mkdir -p ~/.claude-memory/claude/global/entities
   ```

2. Initialize Obsidian vault:
   - Open Obsidian
   - "Open folder as vault"
   - Select `~/.claude-memory`
   - Name it "claude-memory"

3. Install required Obsidian plugins:
   - Dataview (for queries)
   - Obsidian MCP Plugin (for Claude Code integration)

4. Configure MCP server in Claude Code:
   - Add to `~/.config/claude-code/config.json`:
   ```json
   {
     "mcpServers": {
       "obsidian-vault": {
         "command": "node",
         "args": ["/path/to/obsidian-mcp-server/index.js"],
         "env": {
           "OBSIDIAN_VAULT_PATH": "/Users/you/.claude-memory"
         }
       }
     }
   }
   ```

### Creating Your First Project

1. Create project directory:
   ```bash
   mkdir -p ~/.claude-memory/claude/projects/my-project/sessions
   mkdir -p ~/.claude-memory/claude/projects/my-project/entities
   mkdir -p ~/.claude-memory/claude/projects/my-project/archive/sessions
   ```

2. Create project index (copy template above):
   ```bash
   # Use Obsidian or create with editor
   vim ~/.claude-memory/claude/projects/my-project/_index.md
   ```

3. Start a Claude Code session in your project:
   - Session start hook will detect project name from git
   - First session will create initial session note
   - Add entities as you work

### Migrating Existing Projects

If you have existing work to migrate:

1. **Create session note for current state:**
   - Document current architecture and decisions
   - List open questions and next steps
   - Reference existing documentation

2. **Extract key entities:**
   - Create entity notes for major subsystems
   - Document architectural decisions
   - Capture gotchas and patterns

3. **Update project index:**
   - Link to newly created entities
   - Summarize recent focus
   - List active goals

## Troubleshooting

### Vault Not Found

**Symptom:** Session start hook shows "MCP unavailable"

**Solutions:**
1. Verify vault path: `ls ~/.claude-memory/claude`
2. Check Obsidian is running
3. Verify MCP plugin installed and enabled
4. Check Claude Code config has correct vault path

### Session Not Loading

**Symptom:** Session start doesn't show context

**Solutions:**
1. Check project index exists: `ls ~/.claude-memory/claude/projects/{project}/_index.md`
2. Verify session files have correct frontmatter
3. Check entity files are linked in project index
4. Review hook execution: `cat /tmp/claude-code-hooks.log`

### Compaction Not Triggering

**Symptom:** Old sessions not archived

**Solutions:**
1. Check session age: Should be >3 days or >500 lines
2. Verify session has `status: active` in frontmatter
3. Check session-end hook executed
4. Manually trigger compaction if needed

### Entity Not Found

**Symptom:** Entity referenced but not loaded

**Solutions:**
1. Check entity file exists in either:
   - `claude/projects/{project}/entities/{name}.md`
   - `claude/global/entities/{name}.md`
2. Verify wikilink syntax: `[[Entity Name]]` (exact match with filename)
3. Check for typos in project index
4. Ensure entity has correct frontmatter

## Advanced Topics

### Cross-Project Entities

When an entity is useful across multiple projects, it can be promoted to global:

1. **Automatic promotion:** After 3+ cross-project recalls, Claude suggests promotion
2. **Manual promotion:** Move file from project entities to global entities
3. **Update project field:** Change `project: specific-project` to `project: global`

### Custom Dataview Queries

Create custom queries for specific needs:

```dataview
TABLE status, topic, created
FROM "claude/projects/my-project/sessions"
WHERE created >= date(today) - dur(30 days)
SORT created DESC
```

### Backup Strategy

Recommended backup approach:

1. **Git repository:**
   ```bash
   cd ~/.claude-memory
   git init
   git add .
   git commit -m "Memory snapshot"
   ```

2. **Automated backups:**
   - Use Time Machine (macOS)
   - Or sync to cloud storage
   - Or use Obsidian Sync

3. **Periodic exports:**
   - Export to Markdown
   - Archive old projects
   - Clean up unused entities

## Examples

### Small Project (Single Developer)

```
my-tool/
├── _index.md              # Links to 3-5 key entities
├── sessions/
│   ├── 2025-11-15-initial-setup.md
│   └── 2025-11-19-feature-x.md
├── entities/
│   ├── CLI Design.md
│   ├── Configuration System.md
│   └── Testing Strategy.md
└── archive/
    └── sessions/
        └── (compacted sessions)
```

### Large Project (Team)

```
web-platform/
├── _index.md              # Links to 8-10 critical entities
├── sessions/
│   ├── 2025-11-01-auth-redesign.md
│   ├── 2025-11-05-api-performance.md
│   └── ... (active sessions)
├── entities/
│   ├── Authentication System.md
│   ├── API Architecture.md
│   ├── Database Schema.md
│   ├── Caching Strategy.md
│   ├── Deployment Pipeline.md
│   ├── Error Handling.md
│   ├── Frontend Framework.md
│   └── Testing Infrastructure.md
├── archive/
│   └── sessions/
│       └── ... (many archived sessions)
└── web-platform.base      # Custom Dataview queries
```

## Summary

The vault structure is designed to:
- **Scale** from small to large projects
- **Organize** knowledge hierarchically
- **Connect** related concepts through links
- **Preserve** history through archiving
- **Optimize** for quick session startup (<2s)

Key principles:
- Projects contain sessions and entities
- Sessions are temporal, entities are persistent
- Archive preserves history without clutter
- Global entities enable cross-project reuse
- Consistent structure enables automation

For more information, see:
- `docs/setup-guide.md` - Installation and configuration
- `docs/mcp-api-reference.md` - MCP API details
- `hooks/session-start.md` - Session start workflow
- `hooks/session-end.md` - Compaction workflow
