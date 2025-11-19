# MANDATORY SESSION START PROTOCOL

**YOU MUST execute these steps BEFORE responding to the user's first message.**

## Why This Matters

Without loading memory proactively, you will:
- Lose context from previous sessions
- Repeat solved problems
- Miss important decisions and open questions
- Waste user's time re-establishing context

## The Iron Law

```
LOAD MEMORY FIRST, RESPOND TO USER SECOND
```

No exceptions. Execute the protocol below, THEN respond to whatever the user asked.

## Required Protocol (Execute in Order)

**Performance Target:** <2 seconds total
**User Experience:** 1-3 sentence summary, then respond to their message

## Implementation

### 1. Detect Project Context

1. Attempt to detect the current project from the git repository:
   - Run `git rev-parse --show-toplevel` to find the git repository root
   - Extract the project name from the repository directory name
   - Return the project name

2. If not in a git repository (command fails):
   - Fall back to using the current working directory name
   - If that also fails, use 'default' as the project name

3. Store the detected project context for all subsequent operations

**Fallback:** If not in git repo, use current directory name. If that fails, use "default".

### 2. Load Project Index

1. Construct the project index path: `claude/projects/{projectContext}/_index.md`

2. Attempt to load the project index using MCP vault tool:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "read",
     path: `claude/projects/${projectContext}/_index.md`,
     returnFullFile: true
   })
   ```

3. If successful:
   - Extract wikilinks from the index content
   - These represent the most important entities for this project

4. Handle errors:

   **If FileNotFoundError:**
   - This is the first time working on this project
   - Display message: "Starting new project: {projectContext}"
   - Offer to create project index for future sessions

   **If MCPUnavailableError:**
   - Graceful degradation - continue without memory
   - Display message: "Obsidian MCP unavailable. See docs/setup-guide.md"
   - Continue session without memory loading (see error recovery in section below)

### 3. Query Last 3 Session Notes

**Using Dataview Query (if available):**

1. Construct a Dataview query to find recent sessions:
   - Source: `claude/projects/{projectContext}/sessions`
   - Filter: status = "active" OR status = "archived"
   - Sort: created DESC (most recent first)
   - Limit: 3

2. Invoke MCP bases tool to query sessions:
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

   Note: If Dataview base not configured, falls back to search (see fallback below)

3. For each returned session path, load the full content in parallel:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "read",
     path: sessionPath,
     returnFullFile: true
   })
   ```

4. Handle errors:

   **If Dataview base not available:**
   - Fallback to list and filter approach:
     ```javascript
     // List all session files
     const listResult = await mcp__obsidian-vault__vault({
       action: "list",
       directory: `claude/projects/${projectContext}/sessions`
     });

     // Load frontmatter for each in parallel
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

**Fallback Strategy:** If Dataview base unavailable, use list + filter approach with frontmatter sorting.

### 4. Load Linked Entities

1. From the project index, extract the linked entities (wikilinks)

2. Limit to top 5 most important entities to keep load time under 2 seconds

3. For each entity (in parallel):
   - First attempt: Try to load from project entities path:
     ```javascript
     mcp__obsidian-vault__vault({
       action: "read",
       path: `claude/projects/${projectContext}/entities/${entityName}.md`,
       returnFullFile: true
     })
     ```
   - If not found (error.message includes "not found"): Try global entities path:
     ```javascript
     mcp__obsidian-vault__vault({
       action: "read",
       path: `claude/global/entities/${entityName}.md`,
       returnFullFile: true
     })
     ```

4. Collect all successfully loaded entities

**Optimization:** Only load top 5 most important entities (limit based on recency or importance)

### 5. Generate Summary

**Summary Generation:**

1. Initialize an empty highlights array

2. Extract key information from the most recent session:
   - Parse the "## Decisions Made" section to find recent decisions
   - Parse the "## Open Questions" section to find blockers or uncertainties
   - If decisions exist, add the most recent one to highlights
   - If open questions exist, add the first one with "Open:" prefix

3. Limit to 1-3 highlights total to create a concise summary

4. Join highlights into a single summary string (1-3 sentences)

**Summary Content Focus:**
- Recent decisions and rationale
- Open questions or blockers
- Key patterns or architectural choices
- Next steps from previous session

**Length Limit:** 1-3 sentences maximum (not a memory dump)

### 6. Present Summary to User

**Output Format:**

```
Working Memory Loaded for Project: {project-name}

Summary:
{1-3 sentence summary of recent context}

Last session: {date} - {topic}
Active entities: {count} loaded
Recent sessions: {count} reviewed

Need more context? Ask me to recall specific entities or sessions.
```

**Example:**

```
Working Memory Loaded for Project: tabula-scripta

Summary:
Last session completed plugin foundation and core memory skill. Currently implementing session hooks with proactive recall. Open question: how to handle MCP connection failures gracefully.

Last session: 2025-11-17 - Memory System Design
Active entities: 5 loaded
Recent sessions: 3 reviewed

Need more context? Ask me to recall specific entities or sessions.
```

### 7. Offer Additional Context

**User can request more:**

```
User: "Tell me about the memory system architecture"

Claude: Loads [[Memory System Architecture]] entity and presents details
```

**User can request session details:**

```
User: "What did we work on last session?"

Claude: Loads full content of last session note and summarizes
```

## Red Flags - STOP and Execute Protocol

If you catch yourself thinking ANY of these thoughts, STOP. Execute the memory loading protocol FIRST:

- "User seems urgent, I'll respond immediately"
- "Their question is simple, I don't need memory"
- "I'll load memory if they specifically ask for it"
- "Let me respond quickly, memory later"
- "They just asked 'what do u remember' - that's different"
- "I can see the git history, that's good enough"
- "This is just a greeting, skip the protocol"

**ALL of these mean:** Stop. Execute the MANDATORY SESSION START PROTOCOL. THEN respond.

## Common Rationalizations (Don't Do These)

| Excuse | Reality |
|--------|---------|
| "User seems urgent, respond immediately" | Protocol takes <2 seconds. User benefits from context. |
| "Question is simple, don't need memory" | You don't know what's simple without loading context. |
| "I'll load if they ask for it" | Proactive loading IS the feature. Don't make user ask. |
| "Git history is good enough" | Git shows files, not decisions/questions/context. Load memory. |
| "This is just a greeting" | Every session starts with greeting. Still load memory. |
| "They said 'what do u remember'" | That's still a first message. Execute protocol FIRST. |

## Error Handling and Recovery

### MCP Unavailable (I2: Error Recovery Paths)

When MCP server is unavailable at session start:

1. Detect the MCPUnavailableError during any memory operation

2. Display user-friendly message:
   ```
   Obsidian MCP server unavailable. Working memory features disabled.

   To restore memory:
   1. Ensure Obsidian is running
   2. Verify obsidian-mcp-plugin installed
   3. Check Claude Code config includes MCP server

   See docs/setup-guide.md for setup instructions.
   ```

3. **Decision Point - Ask User:**
   - **Option A: Continue without memory**
     - Session proceeds normally but without context loading
     - Memory writes will also be disabled for this session
     - User can still work on tasks, just no memory features
   - **Option B: Wait and retry**
     - Pause session startup
     - Wait for user to fix MCP connection
     - Retry memory loading once fixed
   - **Option C: Exit and fix setup**
     - Exit the session
     - User fixes MCP setup
     - Restart session with working memory

4. If user chooses to continue without memory:
   - Set session flag: `memory_disabled = true`
   - Skip all memory operations for this session
   - Display reminder that memory is disabled

### Project Index Not Found

If the project index doesn't exist (FileNotFoundError):

1. Display message:
   ```
   Starting fresh project: {projectContext}

   I'll create a project index to track your work.
   Would you like me to create it now? (yes/no)
   ```

2. If user confirms:
   - Create a new project index note
   - Initialize with basic structure

3. If user declines:
   - Continue session without index
   - Index will be created on first memory write

### No Previous Sessions

If no session notes are found for this project:

1. Display welcome message:
   ```
   Welcome to project: {projectContext}

   This is your first session. I'll start building working memory as we work.

   Ready to begin!
   ```

2. Return and start the session normally
   - Memory features are active but no context to load yet

## Performance Optimization and Measurement

### Parallel Loading

1. Load project index, sessions, and entities in parallel using Promise.all:
   - Load project index
   - Query recent sessions (limit 3)
   - Load linked entities (limit 5)

2. Wait for all operations to complete before generating summary

**Target:** <2 seconds total time for all operations

### I3: Performance Measurement and Warning

1. **Track timing:**
   - Record start time before beginning memory loading
   - Record end time after all operations complete
   - Calculate total duration in milliseconds

2. **Performance check:**
   - If total duration < 2000ms: Success, no message needed
   - If total duration >= 2000ms but < 5000ms: Display warning
     ```
     Working memory loaded in {duration}ms (target: <2s)

     Consider optimizing:
     - Reduce number of linked entities in project index
     - Archive old session notes
     - Check Obsidian vault performance
     ```
   - If total duration >= 5000ms: Display strong warning
     ```
     Working memory loading is slow ({duration}ms)

     This may impact session startup time. Recommendations:
     1. Archive sessions older than 30 days
     2. Limit project index to 5 most important entities
     3. Check Obsidian performance (large vault, plugins)
     4. Consider reducing session note size threshold

     Continue with memory features? (yes/no)
     ```

3. **User decision on slow performance:**
   - If user says no: Disable memory for this session
   - If user says yes: Continue with warning noted

### Lazy Loading

Instead of loading full session content upfront, load summaries first:

1. For each recent session, extract only:
   - Path
   - Title from frontmatter
   - Created date from frontmatter

2. Don't load full content until user requests it

3. This speeds up initial load for sessions with large notes

### Caching

To avoid repeated MCP calls during the session:

1. Create a session cache (Map or similar structure)

2. When loading a note:
   - Check if already in cache
   - If in cache: Return cached version
   - If not in cache: Load via MCP vault tool and store in cache
     ```javascript
     mcp__obsidian-vault__vault({
       action: "read",
       path: notePath,
       returnFullFile: true
     })
     ```

3. Cache persists for session duration only (cleared on exit)

## Integration with Managing Working Memory Skill

**Relationship:** This hook triggers the recall flow defined in `skills/managing-working-memory.md`

**Update claude_last_accessed:** When loading notes, update frontmatter:

1. For each loaded note:
   - Set frontmatter.claude_last_accessed to current date (YYYY-MM-DD)
   - Update the note using MCP edit tool (efficient patch):
     ```javascript
     mcp__obsidian-vault__edit({
       action: "patch",
       path: notePath,
       targetType: "frontmatter",
       target: "claude_last_accessed",
       operation: "replace",
       content: new Date().toISOString().split('T')[0]  // YYYY-MM-DD
     })
     ```

**Cross-Project Tracking:** If loading entity from different project, log cross-project recall:

1. Check if entity is from a different project:
   - Compare entity.frontmatter.project with currentProject
   - Exclude global entities (project = 'global')

2. If cross-project recall detected:
   - Append to cross_project_recalls array:
     - project: Current project
     - date: Current date
     - context: "Session start recall"

3. Check promotion threshold:
   - If cross_project_recalls length >= 3, trigger promotion prompt
   - Use promotion flow defined in managing-working-memory skill

## Testing

### Manual Testing

1. Start Claude Code session in git repo
2. Verify project detection works (correct project name)
3. Check summary generated (1-3 sentences)
4. Verify <2 second load time
5. Request additional context (entities, sessions)
6. Test in non-git directory (fallback to directory name)

### Edge Cases

- **No previous sessions:** Welcome message
- **MCP unavailable:** Graceful degradation message
- **Large vault (>100 notes):** Performance still <2s
- **Project index missing:** Offer to create
- **Dataview not installed:** Fallback to search_notes

## Example Session Start Flow

```
$ claude-code

[Session Start Hook Executing...]

Working Memory Loaded for Project: tabula-scripta

Summary:
Completed Phase 2 (Core Memory Skill) implementing write triggers and conflict detection. Now implementing Phase 3 session hooks. Performance target is <2 seconds for session start recall.

Last session: 2025-11-17 - Implementing Core Skill
Active entities: 3 loaded ([[Memory System]], [[MCP Integration]], [[Conflict Detection]])
Recent sessions: 2 reviewed

Need more context? Ask me to recall specific entities or sessions.

---

How can I help you today?
```

## Summary

This session-start hook provides proactive recall of working memory at the beginning of each session:

1. **Detects project** from git repo or directory name
2. **Loads project index** with linked entities
3. **Queries last 3 sessions** via Dataview
4. **Generates 1-3 sentence summary** (not overwhelming)
5. **Presents context** with option to request more
6. **Performs in <2 seconds** via parallel loading
7. **Handles errors gracefully** (MCP unavailable, no sessions, etc.)

Users experience automatic context restoration without manual searching, while maintaining control to request additional details as needed.
