# Update Memory - Update Existing Note

Update an existing memory note with new information, using patch operations and conflict detection.

## Usage

```
/update-memory [title]
```

**Arguments:**
- `title` - The title of the existing memory note to update (required)

**Examples:**
```
/update-memory Git Worktrees
/update-memory 2025-11-18 - Working Memory Implementation
/update-memory React Patterns
```

## Implementation

When this command is invoked:

### 1. Parse and Validate Title

1. Parse the title by trimming whitespace from the command input
2. Validate that the title is not empty
   - If title is empty, return error message: "Title is required. Usage: /update-memory [title]"

### 2. Detect Project Context

1. Attempt to detect the current project from the git repository:
   - Run `git rev-parse --show-toplevel` to find the git repository root
   - Extract the project name from the repository directory name
2. If not in a git repository:
   - Fall back to using the current working directory name
   - If that fails, use 'default' as the project name
3. Store the detected project name for locating the note

### 3. Search for Note

1. Try to find the note by checking multiple possible locations in order:
   - Current project entities: `claude/projects/{currentProject}/entities/{title}.md`
   - Current project sessions: `claude/projects/{currentProject}/sessions/{title}.md`
   - Global entities: `claude/global/entities/{title}.md`
   - Global topics: `claude/global/topics/{title}.md`

2. For each possible path:
   - Attempt to read the note using MCP `read_note`
   - If successful, store the path and note content, then stop searching
   - If FileNotFoundError, continue to next path
   - If other error, propagate it

3. If not found in standard locations, use search as fallback:
   - Invoke MCP `search_notes` with query=title and path_filter='claude/**'
   - Find exact title match in results (case-insensitive comparison)
   - If exact match found, load the note using MCP `read_note`

4. If still not found after all attempts:
   - Return error message listing all searched locations
   - Suggest using /remember to create the note
   - Provide example command

### 4. Load Note and Check Timestamps

1. Store the loaded timestamp from frontmatter for conflict detection later
   - Save note.frontmatter.updated as the loaded timestamp

2. Update claude_last_accessed in frontmatter to current date (YYYY-MM-DD)

3. Display the current note content to the user:
   - Show wikilink title, type, project, last updated date, and path
   - Display full current content
   - Add separator line
   - Prompt: "What would you like to update? I'll apply patch operations to preserve existing content."

### 5. Collect User Updates

This is a conversational step where the user describes what they want to update.

1. User provides their update request in natural language
   - Example: "Add a new decision about using trap handlers for cleanup"

2. Parse the user's intent to identify the appropriate patch operation type:
   - Append to section: Add new entry to an existing section (e.g., "## Recent Changes")
   - Add new section: Create a completely new section (e.g., "## Troubleshooting")
   - Update frontmatter: Modify frontmatter fields (e.g., add a tag)
   - Insert in list: Add item to an existing list (e.g., "## Related Entities")

3. Confirm with the user what will be done
   - Example: "I'll add this to the Key Decisions section."

### 6. Check for Conflicts (Before Writing)

Use the conflict detection logic defined in the managing-working-memory skill:

1. Before applying the patch, reload the note using MCP `read_note` to get the current state

2. Compare timestamps to detect conflicts:
   - Get the current timestamp from the reloaded note's frontmatter.updated
   - Compare with the loaded timestamp saved in step 4
   - If current timestamp > loaded timestamp: CONFLICT DETECTED (human edited since Claude loaded)
   - If timestamps match: No conflict, safe to update

3. If conflict detected:
   - Trigger conflict resolution flow (see managing-working-memory skill for detailed flow)
   - Present both changes to user and offer resolution options

4. If no conflict:
   - Proceed to apply patch operation in next step

### 7. Apply Patch Operation

Use the patch operation patterns defined in the managing-working-memory skill. Apply the identified patch operation type:

**For append_to_section:**
- Locate the specified section in the note content
- Append the new content to the end of that section
- Preserve all existing content in the section

**For add_new_section:**
- Create a new markdown section with the specified title
- Add the section content
- Insert at appropriate location in the note structure

**For update_frontmatter:**
- Modify the specified frontmatter field(s)
- Common operations: adding tags, updating status, etc.

**For insert_in_list:**
- Locate the specified list within a section
- Add the new list item
- Maintain proper markdown list formatting

After applying content changes:

1. Update frontmatter timestamps:
   - Set updated to current date (YYYY-MM-DD)
   - Set claude_last_accessed to current date (YYYY-MM-DD)

2. If adding tags, merge new tags with existing tags (remove duplicates)

### 8. Write Updated Note

1. Invoke MCP `update_note` with:
   - vault: `~/.claude-memory`
   - path: The note path
   - content: The updated content
   - frontmatter: The updated frontmatter

2. Handle the response:

   **If successful:**
   - Return success message including:
     - Confirmation with wikilink
     - Description of applied changes
     - Updated timestamp
     - Path
     - Note that Obsidian has been updated

   **If MCPUnavailableError:**
   - Return graceful degradation message explaining:
     - MCP server is unavailable
     - Steps to restore: ensure Obsidian is running, check plugin installation, verify config
     - Reference to docs/setup-guide.md
     - Offer to save pending update to a local file

   **If other error:**
   - Return error message with details

## Conflict Detection and Resolution

All conflict detection and resolution flows are defined in the managing-working-memory skill. The /update-memory command uses these patterns:

### Case 1: Clean Update (No Conflict)

Timeline:
- T1: Claude loads note (updated = "2025-11-17")
- T2: User discusses updates with Claude
- T3: Claude applies patch (updated still "2025-11-17")
- Result: No conflict, proceed with update

See managing-working-memory skill for timestamp comparison logic.

**Example Output:**
```
Updated: [[Git Worktrees]]

Applied changes:
- Added new entry to "Recent Changes"
- Appended decision about trap handlers to "Key Decisions"
- Updated tags: [entity, git, worktrees, error-handling]

Updated: 2025-11-18
Path: claude/projects/tabula-scripta/entities/Git Worktrees.md

The note has been updated in Obsidian.
```

### Case 2: Human Edit Conflict

Timeline:
- T1: Claude loads note (updated = "2025-11-17")
- T2: Human edits note in Obsidian (updated = "2025-11-18")
- T3: Claude attempts patch (detects conflict)
- Result: Conflict detected, show diff and offer resolution options

See managing-working-memory skill for conflict resolution flow and user options.

**Example Output:**
```
I want to update [[Git Worktrees]] but you've edited it since I loaded it.

Your changes (at 2025-11-18):
  + Added new section "## Performance Considerations"
  + Updated "Overview" with additional context
  ~ Modified frontmatter tags: added #optimization

My pending changes:
  - Add new entry to "Recent Changes"
  - Append decision about trap handlers to "Key Decisions"

Options:
1. Show me both diffs and I'll merge manually
2. Abort your update (keep my changes only)
3. Create new section "## Claude's Updates (conflicted)" with your changes
4. Let's discuss and resolve together

What should I do?
```

### Case 3: Major Rewrite Needed

When Claude's understanding contradicts existing note fundamentally, use the major rewrite pattern from managing-working-memory skill to present options without overwriting user knowledge.

**Example Output:**
```
My understanding of [[Git Worktrees]] changed significantly.

Current note says:
"Git worktrees are primarily for parallel feature development and should be short-lived."

But I now think:
"Git worktrees can be long-lived for maintaining multiple release branches simultaneously."

Options:
1. Create new entity note with alternative understanding
2. Update existing note (I'll show you the full diff first)
3. Let's discuss the contradiction - maybe both are valid

What should I do?
```

## Patch Operation Types

All patch operations are defined in the managing-working-memory skill. The /update-memory command uses these standard patterns:

### 1. Append to Section

Add new content at the end of an existing section. Example: Adding to "## Recent Changes" section.

See managing-working-memory skill for appendToSection pattern.

### 2. Add New Section

Create a new section in the note. Example: Adding "## Performance Considerations" section.

See managing-working-memory skill for addSection pattern.

### 3. Update Frontmatter

Modify frontmatter fields such as tags or status.

Examples:
- Adding a tag: Append to tags array
- Changing status: Set status field to new value

See managing-working-memory skill for frontmatter update pattern.

### 4. Insert in List

Add item to an existing list like "## Related Entities" or "## References".

See managing-working-memory skill for insertInList pattern.

## Error Handling

### Note Not Found

**Input:** `/update-memory Nonexistent Entity`

**Output:**
```
Error: Memory note [[Nonexistent Entity]] not found.

Searched:
- Project entities: claude/projects/tabula-scripta/entities/
- Project sessions: claude/projects/tabula-scripta/sessions/
- Global entities: claude/global/entities/
- Global topics: claude/global/topics/

Would you like to create it with /remember?

Example: /remember entity Nonexistent Entity
```

### MCP Unavailable

**Input:** `/update-memory Git Worktrees` (when MCP server is down)

**Output:**
```
Obsidian MCP server is unavailable. Cannot update memory note.

To restore memory features:
1. Ensure Obsidian is running
2. Check obsidian-mcp-plugin is installed in ~/.claude-memory/
3. Verify Claude Code config includes MCP server

See docs/setup-guide.md for troubleshooting.

Would you like me to save the pending update to a local file?
```

### Missing Title

**Input:** `/update-memory`

**Output:**
```
Error: Title is required.

Usage: /update-memory [title]

Examples:
  /update-memory Git Worktrees
  /update-memory 2025-11-18 - Working Memory Implementation
  /update-memory React Patterns
```

## Success Output (Clean Update)

**Input:** `/update-memory Git Worktrees`

**Conversation:**
```
User: /update-memory Git Worktrees

Claude: Loaded: [[Git Worktrees]]
Type: entity
Project: tabula-scripta
Last updated: 2025-11-17
Path: claude/projects/tabula-scripta/entities/Git Worktrees.md

Current content:
[... full note content ...]

---

What would you like to update? I'll apply patch operations to preserve existing content.

User: Add a decision about using trap handlers for cleanup

Claude: I'll add this to the Key Decisions section.

[Claude applies patch]

Updated: [[Git Worktrees]]

Applied changes:
- Added new entry to "Key Decisions"
  ### Trap Handlers for Cleanup
  Date: 2025-11-18
  Rationale: Ensures worktree cleanup even if subagent crashes
  Alternatives Considered: Manual cleanup (error-prone), atexit hooks (unreliable)
  Impact: Improves reliability of parallel execution

Updated: 2025-11-18
Path: claude/projects/tabula-scripta/entities/Git Worktrees.md

The note has been updated in Obsidian.
```

## Timestamp Tracking

### Frontmatter Fields

```yaml
---
created: 2025-11-17      # Never changes, original creation
updated: 2025-11-18      # Modified every save (human or Claude)
claude_last_accessed: 2025-11-18  # When Claude loaded into context
---
```

### Conflict Detection Logic

See the managing-working-memory skill for the complete timestamp comparison logic. The basic flow is:

1. **When loading:** Store the updated timestamp and set claude_last_accessed
2. **When updating:** Reload the note and compare timestamps
3. **If current timestamp > loaded timestamp:** Conflict detected
4. **If timestamps match:** Safe to update

## Graceful Degradation (MCP Unavailable)

When MCP server is unavailable:

1. **Detect failure** - Catch `MCPUnavailableError`
2. **Offer alternatives:**
   - Save pending update to local markdown file
   - Export as diff patch for manual application
   - Continue conversation without update
3. **Guide troubleshooting:**
   - Link to `docs/setup-guide.md`
   - Check Obsidian is running
   - Verify plugin installation

## Interactive Update Flow

The `/update-memory` command is conversational:

1. **Load note** - Show current content to user
2. **Collect intent** - User describes what to update
3. **Confirm operation** - Claude describes patch operation
4. **Check conflict** - Reload note to detect edits
5. **Apply or resolve** - Update cleanly or trigger conflict resolution
6. **Confirm success** - Show what changed

This ensures transparency and prevents data loss.

## Acceptance Criteria

- [ ] Loads existing note via MCP read_note
- [ ] Checks timestamps for conflict detection (updated vs loaded)
- [ ] Detects conflicts when human edited since load
- [ ] Shows diff when conflict detected
- [ ] Applies patch operations (append, add section, update frontmatter)
- [ ] Preserves existing content (no full rewrites)
- [ ] Updates frontmatter timestamps (updated, claude_last_accessed)
- [ ] Handles MCP unavailable gracefully
- [ ] Offers to create note if not found
- [ ] Searches multiple locations (project entities, sessions, global)
- [ ] Shows clear success message with changes applied

## Integration with managing-working-memory Skill

This command provides the manual interface for memory updates. The `managing-working-memory` skill uses the same update logic for:
- Automatic updates after code review
- Updates after debugging sessions
- Periodic checkpoint updates
- Session end compaction

**Relationship:**
- `/update-memory` - Manual, user-initiated updates
- `managing-working-memory` - Automatic, skill-driven updates
- Both use identical conflict detection and patch operations
- Both track timestamps for data integrity
