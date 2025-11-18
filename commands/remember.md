# Remember - Create New Memory Note

Create a new memory note in the Obsidian vault at `~/.claude-memory/`.

## Usage

```
/remember [type] [title]
```

**Arguments:**
- `type`: The type of memory note (required)
  - `session` - Temporal note for current work session
  - `entity` - Persistent note for a concept/component/pattern
  - `topic` - Organizational note (Map of Content)
- `title` - The title for the memory note (required)

**Examples:**
```
/remember entity Git Worktrees
/remember session 2025-11-18 - Working Memory Implementation
/remember topic React Patterns
```

## Implementation

When this command is invoked:

### 1. Parse and Validate Arguments

1. Parse the command input by splitting on spaces
2. Extract the first argument as the type
3. Extract remaining arguments and join with spaces as the title
4. Validate that type is one of the allowed values: session, entity, or topic
   - If type is invalid, return error message: "Invalid type '{type}'. Must be one of: session, entity, topic"
5. Validate that title is provided and not empty
   - If title is missing or empty, return error message: "Title is required. Usage: /remember [type] [title]"

### 2. Detect Project Context

1. Attempt to detect the current project from the git repository:
   - Run `git rev-parse --show-toplevel` to find the git repository root
   - Extract the project name from the repository directory name
2. If not in a git repository (command fails):
   - Fall back to using the current working directory name as the project
   - If that also fails, use 'default' as the project name
3. Store the detected project name for use in vault path generation

### 3. Generate Vault Path

1. Sanitize the title to create a valid filename:
   - Replace any characters that are invalid in filenames with hyphens
   - Invalid characters include: / \ : * ? " < > |
2. Generate the vault path based on the note type:
   - For session notes: `claude/projects/{project}/sessions/{sanitized-title}.md`
   - For entity notes: `claude/projects/{project}/entities/{sanitized-title}.md`
   - For topic notes: `claude/global/topics/{sanitized-title}.md`

Note that topic notes are always global (not project-specific)

### 4. Generate Frontmatter

1. Get the current date in YYYY-MM-DD format
2. Create frontmatter with the following fields:
   - type: The note type (session, entity, or topic)
   - project: The project name, or 'global' for topic notes
   - tags: Type-specific tags
     - Session notes: [session, work-in-progress]
     - Entity notes: [entity]
     - Topic notes: [topic, moc]
   - created: Current date (YYYY-MM-DD)
   - updated: Current date (YYYY-MM-DD)
   - status: 'active'
   - claude_last_accessed: Current date (YYYY-MM-DD)
   - cross_project_recalls: Empty array (for tracking cross-project usage)

### 5. Generate Note Content from Template

Use the note templates defined in the managing-working-memory skill to generate the initial content. The templates vary by note type:

**For session notes:**
- Include frontmatter with all required fields
- Add a main heading with the session title
- Include sections for:
  - Context (why we're working on this)
  - Work Log (timestamped entries of what happened)
  - Decisions Made (with rationale)
  - Open Questions (blockers or uncertainties)
  - Next Steps (action items as checkboxes)
  - Related Entities (wikilinks to relevant entities)

**For entity notes:**
- Include frontmatter with all required fields
- Add a main heading with the entity name
- Include sections for:
  - Overview (purpose and role)
  - Architecture (structure and how it works)
  - Key Decisions (with date, rationale, alternatives, impact)
  - Gotchas & Troubleshooting (symptom, root cause, solution, tags)
  - Recent Changes (timestamped log)
  - Related Entities (wikilinks with relationship descriptions)
  - References (external docs, code paths, commits)

**For topic notes:**
- Include frontmatter with project set to 'global'
- Add a main heading with the topic name
- Include sections for:
  - Overview (what the topic covers)
  - Key Concepts (wikilinks to core entities)
  - Patterns & Best Practices (descriptions and related entities)
  - Common Pitfalls (antipatterns to avoid)
  - Learning Path (ordered sequence of entities)
  - References (external resources and documentation)

All templates use placeholder text in curly braces {like this} to indicate where content should be filled in.

### 6. Invoke MCP create_note

1. Invoke the MCP `create_note` operation with:
   - vault: `~/.claude-memory`
   - path: The generated vault path
   - content: The generated note content with frontmatter

2. Handle the response:

   **If successful:**
   - Return success message including:
     - Confirmation with wikilink to the created note
     - Type and project information
     - Vault path
     - Note that the note is ready for editing

   **If FileExistsError:**
   - Return error message indicating the note already exists
   - Suggest using /update-memory to update it, or choosing a different title

   **If MCPUnavailableError:**
   - Return graceful degradation message explaining:
     - MCP server is unavailable
     - Steps to restore: ensure Obsidian is running, check plugin installation, verify config
     - Reference to docs/setup-guide.md
     - Offer to create a draft in a local markdown file instead

   **If unknown error:**
   - Return error message with the error details

## Error Handling

### Invalid Type

**Input:** `/remember invalid-type My Note`

**Output:**
```
Error: Invalid type "invalid-type". Must be one of: session, entity, topic

Usage: /remember [type] [title]

Examples:
  /remember entity Git Worktrees
  /remember session 2025-11-18 - Working Memory Implementation
  /remember topic React Patterns
```

### Missing Title

**Input:** `/remember entity`

**Output:**
```
Error: Title is required.

Usage: /remember [type] [title]

Examples:
  /remember entity Git Worktrees
  /remember session 2025-11-18 - Working Memory Implementation
  /remember topic React Patterns
```

### Note Already Exists

**Input:** `/remember entity Git Worktrees` (when it already exists)

**Output:**
```
Error: Memory note [[Git Worktrees]] already exists at claude/projects/tabula-scripta/entities/Git Worktrees.md

Use /update-memory to update an existing note, or choose a different title.
```

### MCP Unavailable

**Input:** `/remember entity My Component` (when MCP server is down)

**Output:**
```
Obsidian MCP server is unavailable. Cannot create memory note.

To restore memory features:
1. Ensure Obsidian is running
2. Check obsidian-mcp-plugin is installed in ~/.claude-memory/
3. Verify Claude Code config includes MCP server

See docs/setup-guide.md for troubleshooting.

Would you like me to create a draft in a local markdown file instead?
```

## Success Output

**Input:** `/remember entity Git Worktrees`

**Output:**
```
Created memory note: [[Git Worktrees]]

Type: entity
Project: tabula-scripta
Path: claude/projects/tabula-scripta/entities/Git Worktrees.md

The note is ready for editing in Obsidian or via /update-memory.
```

## Integration with managing-working-memory Skill

This command provides the manual interface for memory creation. The `managing-working-memory` skill uses the same underlying logic but triggers automatically based on workflow events (code review, debugging, etc.).

**Relationship:**
- `/remember` - Manual, user-initiated memory creation
- `managing-working-memory` - Automatic, skill-driven memory creation
- Both use identical frontmatter schema and note templates
- Both invoke same MCP operations

## Wikilink Generation

All created notes support Obsidian wikilinks:
- Entity reference: `[[Git Worktrees]]`
- Session reference: `[[2025-11-18 - Working Memory Implementation]]`
- Topic reference: `[[React Patterns]]`

Links work bidirectionally in Obsidian's graph view.

## Project Context Detection

The command detects project context in priority order:

1. **Git repository name** - `git rev-parse --show-toplevel`
2. **Working directory name** - `path.basename(process.cwd())`
3. **Fallback** - `'default'`

This ensures session and entity notes are scoped to the correct project.

## Acceptance Criteria

- [ ] Creates notes at correct vault path with valid frontmatter
- [ ] Validates type argument (session/entity/topic)
- [ ] Requires title argument
- [ ] Detects project context from git repo
- [ ] Generates wikilinks correctly
- [ ] Handles MCP unavailable gracefully
- [ ] Shows clear error for note already exists
- [ ] Uses templates from managing-working-memory skill
- [ ] Frontmatter includes all required fields
- [ ] Timestamp format is YYYY-MM-DD
