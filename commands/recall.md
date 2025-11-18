# Recall - Search Existing Memories

Search for existing memory notes in the Obsidian vault and present the top results.

## Usage

```
/recall [query]
```

**Arguments:**
- `query` - Search terms to find relevant memories (required)

**Examples:**
```
/recall git worktrees
/recall debugging race condition
/recall react hooks patterns
/recall authentication flow
```

## Implementation

When this command is invoked:

### 1. Parse and Validate Query

1. Parse the query by trimming whitespace from the command input
2. Validate that the query is not empty
   - If query is empty, return error message: "Query is required. Usage: /recall [query]"

### 2. Detect Project Context

1. Attempt to detect the current project from the git repository:
   - Run `git rev-parse --show-toplevel` to find the git repository root
   - Extract the project name from the repository directory name
2. If not in a git repository:
   - Fall back to using the current working directory name
   - If that fails, use 'default' as the project name
3. Store the detected project name for scoped search

### 3. Attempt Semantic Search (Smart Connections)

**Note:** Semantic search via Smart Connections plugin is an optional enhancement. If available, it provides better relevance ranking and conceptual matching.

1. Set initial search method to 'semantic' and initialize empty results array
2. Attempt to use semantic search (if Smart Connections plugin is installed):
   - Try to perform semantic search across both project notes and global entities
   - Search path: `claude/projects/{currentProject}/**` and `claude/global/**`
   - Retrieve top 10 results for ranking
3. If Smart Connections is not available or fails:
   - Set search method to 'text' for fallback
   - Continue to text search in next step

**Implementation Note:** Since obsidian-mcp-plugin does not provide native Smart Connections integration, this step may require custom MCP extensions or can be skipped in favor of text search only.

### 4. Perform Text Search

If semantic search was unavailable or returned no results, use text search:

1. Invoke MCP `search_notes` operation for project notes:
   - vault: `~/.claude-memory`
   - query: The user's search query
   - path_filter: `claude/projects/{currentProject}/**`

2. Invoke MCP `search_notes` operation for global entities:
   - vault: `~/.claude-memory`
   - query: The user's search query
   - path_filter: `claude/global/entities/**`

3. Combine the project results and global results, removing any duplicates
4. Set search method to 'text'

5. Handle errors:

   **If MCPUnavailableError:**
   - Return graceful degradation message explaining:
     - MCP server is unavailable
     - Steps to restore: ensure Obsidian is running, check plugin installation, verify config
     - Reference to docs/setup-guide.md

   **If other error:**
   - Return error message with details

### 5. Rank and Filter Results

1. Rank results by relevance:
   - If semantic search was used: Results are already ranked by vector similarity
   - If text search was used: Rank by match frequency and recency
     - Calculate match count: How many times the query appears in the result
     - Calculate recency boost: More recent notes ranked higher
     - Combine into relevance score: match count + (recency boost × 10)
     - Sort results by score in descending order

2. Limit to top 5 results for presentation

3. Check if no results were found:
   - If results are empty, return info message with:
     - "No memories found for query: '{query}'"
     - Suggestions: Try different terms, use /remember to create memories, search more broadly
     - Current project and search scope information

### 6. Track Cross-Project Recalls

Use the cross-project tracking patterns defined in the managing-working-memory skill:

1. Identify cross-project recalls by filtering results:
   - A recall is cross-project if the note's project differs from the current project
   - Exclude global entities (project = 'global') as they're expected to be cross-project

2. For each cross-project entity recall:
   - Load the current note using MCP `read_note`
   - Append a new entry to the `cross_project_recalls` frontmatter array:
     - project: Current project name
     - date: Current date (YYYY-MM-DD)
     - context: "Recalled via search: '{query}'"
   - Update the note using MCP `update_note` with:
     - Updated cross_project_recalls array
     - Updated claude_last_accessed timestamp

3. Check if promotion threshold is met:
   - If cross_project_recalls length >= 3, trigger promotion prompt (see below)
   - Promotion prompt is handled by the managing-working-memory skill

**Promotion Prompt Format (I4):**

When an entity reaches 3 cross-project recalls, display:

```
I've referenced [[{Entity Name}]] from {source-project} while working on other projects 3 times now:

1. {project-name} ({date}): {context}
2. {project-name} ({date}): {context}
3. {project-name} ({date}): {context}

This pattern seems reusable across projects. Should I promote it to global knowledge?

Options:
1. Yes, promote to global (move to ~/.claude-memory/claude/global/entities/)
2. Remind me later (ask again after 5 cross-project recalls)
3. No, it's project-specific (stop tracking)

What should I do?
```

User responses:
- If option 1: Execute promotion process (move entity, update frontmatter, create redirect)
- If option 2: Continue tracking, increase threshold to 5
- If option 3: Clear cross_project_recalls array and stop tracking

4. Handle errors silently:
   - Cross-project tracking is best-effort
   - Log warnings for failed tracking but don't interrupt the search flow

### 7. Present Results

1. Format the output message with:
   - Header: "Found {count} {memory/memories} for: '{query}'"
   - Search method used: Semantic or Text search
   - Current project name
   - Blank line

2. For each result (numbered 1-5):
   - Extract title from path (filename without extension)
   - Get type, project, and updated date from frontmatter
   - Get snippet preview from search result
   - Format as:
     ```
     {number}. [[{title}]] ({type})
        Project: {project}
        Updated: {updated}
        Preview: {first 150 chars of snippet}...
     ```

3. Add footer with options:
   - "Type a number (1-{count}) to load full note content"
   - "Continue conversation to work with these memories"
   - "Use /remember to create a new memory if nothing matches"

4. Return the formatted output as a success message

## Error Handling

### Missing Query

**Input:** `/recall`

**Output:**
```
Error: Query is required.

Usage: /recall [query]

Examples:
  /recall git worktrees
  /recall debugging race condition
  /recall react hooks patterns
```

### No Results Found

**Input:** `/recall nonexistent topic`

**Output:**
```
No memories found for query: "nonexistent topic"

Suggestions:
- Try different search terms
- Check if you've created memories for this topic (use /remember)
- Search more broadly (fewer specific terms)

Current project: tabula-scripta
Searched: Project notes + global entities
```

### MCP Unavailable

**Input:** `/recall authentication` (when MCP server is down)

**Output:**
```
Obsidian MCP server is unavailable. Cannot search memories.

To restore memory features:
1. Ensure Obsidian is running
2. Check obsidian-mcp-plugin is installed in ~/.claude-memory/
3. Verify Claude Code config includes MCP server

See docs/setup-guide.md for troubleshooting.
```

## Success Output

**Input:** `/recall git worktrees`

**Output:**
```
Found 3 memories for: "git worktrees"
Search method: Semantic (Smart Connections)
Project: tabula-scripta

1. [[Git Worktrees]] (entity)
   Project: tabula-scripta
   Updated: 2025-11-18
   Preview: Git worktrees enable isolated directory trees for parallel development. Each worktree has its own working directory but shares the .git repository...

2. [[Parallel Execution Patterns]] (topic)
   Project: global
   Updated: 2025-11-17
   Preview: Techniques for concurrent task execution including git worktrees, background processes, and isolation strategies...

3. [[2025-11-18 - Spectacular Implementation]] (session)
   Project: tabula-scripta
   Updated: 2025-11-18
   Preview: Implementing parallel phase execution using git worktrees for task isolation. Decision: Use trap handlers for cleanup...


Options:
- Type a number (1-3) to load full note content
- Continue conversation to work with these memories
- Use /remember to create a new memory if nothing matches
```

## Search Scope

The `/recall` command searches:

1. **Current project notes:**
   - `claude/projects/{current-project}/sessions/**`
   - `claude/projects/{current-project}/entities/**`

2. **Global entities:**
   - `claude/global/entities/**`
   - `claude/global/topics/**`

3. **Excludes:**
   - Archived sessions (`claude/projects/{project}/archive/**`)
   - Other project's sessions (unless global)

## Semantic Search vs Text Search

### Semantic Search (Preferred)

**Requirements:**
- Smart Connections plugin installed in Obsidian
- Plugin configured for `~/.claude-memory/` vault

**Advantages:**
- Better relevance ranking
- Finds conceptually similar notes
- Handles synonyms and related concepts

**Example:**
- Query: "concurrency issues"
- Finds: "Race Condition Debugging", "Parallel Execution Gotchas"

### Text Search (Fallback)

**When used:**
- Smart Connections not installed
- Smart Connections unavailable
- Semantic search fails

**Behavior:**
- Exact/fuzzy text matching
- Ranked by match frequency and recency
- Still effective for keyword search

**Example:**
- Query: "race condition"
- Finds: Notes containing exact phrase "race condition"

## Cross-Project Recall Tracking

When a memory from Project A is recalled while working in Project B:

1. **Silent logging:**
   - Update `cross_project_recalls` frontmatter array
   - No user-visible output (non-intrusive)

2. **Threshold detection:**
   - After 3 cross-project recalls
   - Trigger promotion prompt (via `managing-working-memory` skill)

3. **Context capture:**
   ```yaml
   cross_project_recalls:
     - project: tabula-scripta
       date: 2025-11-18
       context: "Recalled via search: \"git worktrees\""
     - project: another-project
       date: 2025-11-19
       context: "Recalled via search: \"isolation patterns\""
   ```

## Interactive Follow-Up

After presenting results, user can:

1. **Load full note content:**
   - User types: `1`
   - Claude loads: Full content of result #1

2. **Continue conversation:**
   - User asks: "What did we decide about worktree cleanup?"
   - Claude references loaded memories in response

3. **Create new memory:**
   - User types: `/remember entity Worktree Cleanup`
   - New entity created based on discussion

## Relevance Filtering

Results are filtered for relevance:

- **Minimum score threshold:** Only include results with score > 0.3
- **Recency boost:** Recently updated notes ranked higher
- **Type priority:** Entities ranked above sessions (more persistent knowledge)
- **Project scoping:** Current project results ranked above cross-project results

## Acceptance Criteria

- [ ] Finds notes via semantic search (Smart Connections) when available
- [ ] Falls back to text search when semantic search unavailable
- [ ] Presents top 5 results with relevance ranking
- [ ] Handles MCP unavailable gracefully
- [ ] Detects project context correctly from git repo
- [ ] Tracks cross-project recalls silently
- [ ] Searches both project notes and global entities
- [ ] Shows clear message when no results found
- [ ] Includes note type, project, updated date, and preview in results
- [ ] Offers interactive follow-up options

## Integration with managing-working-memory Skill

This command provides the manual interface for memory search. The `managing-working-memory` skill uses the same search logic for:
- Proactive recall at session start
- Finding related entities during updates
- Cross-project pattern detection

**Relationship:**
- `/recall` - Manual, user-initiated search
- `managing-working-memory` - Automatic, skill-driven search
- Both use same search methods (semantic → text fallback)
- Both track cross-project recalls
