# Managing Working Memory

Use this skill to manage Claude's working memory system using Obsidian as the backend storage. This skill defines when, what, and how to write memories, enabling proactive recall and living documentation that evolves with your understanding.

## When to Use This Skill

### Automatic Triggers (No Permission Needed)

Use this skill automatically in these scenarios:

1. **After code review completes** - Update project entity notes for reviewed components with architectural decisions and links to related entities
2. **After debugging session** - Record troubleshooting patterns, root causes, fixes, and tag with symptom keywords for future search
3. **After architectural decision** - Create or update entity notes with rationale, alternatives considered, and links to related architectural entities
4. **After discovering reusable pattern** - Update topic notes or create new entities with links to examples from current project
5. **Periodic checkpoints during long sessions** - Update session note with current context every 30-60 minutes or after major milestones
6. **End of session** - Final session note update, compact if threshold exceeded, and archive

### Ask-First Triggers (Subjective Content)

Ask user permission before writing in these scenarios:

1. **User states preference** - When user says "I prefer X over Y for Z reason", confirm: "Should I remember this preference?"
2. **Contradicts existing entity note** - Show diff between current understanding and new information, ask: "Update? Create alternative? Discuss?"
3. **Creating new global entity** - Ask: "This seems reusable across projects. Create global entity?"
4. **Large-scale reorganization** - Ask: "I want to split this entity into 3 separate notes. Proceed?"

### Memory Spam Prevention

**Trust the triggers:** Memory writes are naturally throttled by the selectivity of automatic triggers. Don't impose arbitrary limits.

**Natural rate limiting:**
- Automatic triggers only fire after meaningful events (code reviews, debugging completions, architectural decisions)
- Periodic checkpoints are already spaced 30-60 minutes apart
- Session-end compaction consolidates session notes into entities

**Batching strategy:**
- When multiple related entities need updates (e.g., after code review touching 3 components), batch into a single operation
- Group related changes to avoid redundant MCP calls
- Example: Update [[Component A]], [[Component B]], [[Component C]] in parallel, not sequentially

**User control:**
- Users can always disable memory features if they find them intrusive
- For subjective content (preferences, contradictions), still ask permission before writing

## Memory Granularity

### Three-Layer System

1. **Session Notes** (temporal, ephemeral)
   - Location: `~/.claude-memory/claude/projects/{project}/sessions/{date}-{topic}.md`
   - Purpose: Updateable scratchpad for current work
   - Lifecycle: Created at session start, updated during session, compacted into entity notes when exceeding threshold (500 lines OR 3 days old)
   - Content: Stream of consciousness, decisions and why, approaches tried/failed, open questions, context for resuming

2. **Entity Notes** (persistent, specific)
   - Location: `~/.claude-memory/claude/projects/{project}/entities/{Entity Name}.md`
   - Global: `~/.claude-memory/claude/global/entities/{Entity Name}.md`
   - Purpose: One note per concept/component/pattern
   - Lifecycle: Created when new concept encountered, updated via patch operations (not full rewrites), never deleted (archive if obsolete)
   - Content: Purpose/overview, architecture/structure, key decisions and rationale, gotchas/troubleshooting, related entities, recent changes log

3. **Topic Notes** (organizational)
   - Location: `~/.claude-memory/claude/global/topics/{Topic Name}.md`
   - Purpose: Maps of Content (MOC) for topic clusters
   - Lifecycle: Created when pattern emerges across multiple entities, human-curated over time
   - Content: Links to related entities, conceptual frameworks, best practices, curated organization

## Integration with Superpowers Skills

### Code Review Integration

When using `requesting-code-review` skill:
- After review completes → update component entity note
- Record architectural decisions made during review
- Link to related entities
- Example trigger: Review approved, acceptance criteria met

### Debugging Integration

When using `systematic-debugging` skill:
- After root cause identified → record troubleshooting pattern
- Update entity note with fix and rationale
- Tag with symptom keywords (error messages, stack traces)
- Example trigger: Bug fixed and verified

### Brainstorming Integration

When using `brainstorming` skill:
- After architectural decision finalized → create/update entity
- Record alternatives considered and why they were rejected
- Link to related architectural entities
- Example trigger: Design approved, ready for implementation

## Note Templates with Frontmatter

### Session Note Template

```markdown
---
type: session
project: {project-name}
tags: [session, work-in-progress]
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
status: active
claude_last_accessed: {YYYY-MM-DD}
cross_project_recalls: []
---

# Session: {date} - {topic}

## Context

{Why we're working on this, what we're trying to accomplish}

## Work Log

### {Time} - {Milestone}

{What happened, decisions made, approaches tried}

## Decisions Made

- **{Decision}**: {Rationale}
- **{Decision}**: {Rationale}

## Open Questions

- {Question requiring further investigation}
- {Blocker or uncertainty}

## Next Steps

- [ ] {Action item}
- [ ] {Action item}

## Related Entities

- [[Entity Name]] - {Why it's relevant}
- [[Entity Name]] - {Why it's relevant}
```

### Entity Note Template

```markdown
---
type: entity
project: {project-name}
tags: [component, pattern, debugging, architecture]
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
status: active
claude_last_accessed: {YYYY-MM-DD}
cross_project_recalls: []
---

# {Entity Name}

## Overview

{What this entity is, its purpose and role}

## Architecture

{Structure, key components, how it works}

## Key Decisions

### {Decision Title}

**Date:** {YYYY-MM-DD}
**Rationale:** {Why we chose this approach}
**Alternatives Considered:** {What we didn't do and why}
**Impact:** {How this affects the system}

## Gotchas & Troubleshooting

### {Problem/Symptom}

**Symptom:** {How it manifests}
**Root Cause:** {Why it happens}
**Solution:** {How to fix it}
**Tags:** #debugging #troubleshooting

## Recent Changes

### {Date} - {Change Description}

{What changed and why}

## Related Entities

- [[Entity Name]] - {Relationship description}
- [[Entity Name]] - {Relationship description}

## References

- {External documentation}
- {Code file paths}
- {Commits or PRs}
```

### Topic Note Template

```markdown
---
type: topic
project: global
tags: [topic, moc, patterns]
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
status: active
claude_last_accessed: {YYYY-MM-DD}
cross_project_recalls: []
---

# {Topic Name}

## Overview

{What this topic covers, why it's important}

## Key Concepts

- [[Entity Name]] - {Core concept}
- [[Entity Name]] - {Core concept}
- [[Entity Name]] - {Core concept}

## Patterns & Best Practices

### {Pattern Name}

{Description of pattern, when to use, examples}

**Related Entities:** [[Entity A]], [[Entity B]]

### {Pattern Name}

{Description of pattern, when to use, examples}

**Related Entities:** [[Entity C]], [[Entity D]]

## Common Pitfalls

- {Antipattern or common mistake}
- {How to avoid it}

## Learning Path

1. Start with: [[Entity Name]]
2. Then explore: [[Entity Name]]
3. Advanced: [[Entity Name]]

## References

- {External resources}
- {Documentation links}
```

## Living Memory Update Logic

### Patch Operations

**Principle:** Preserve existing content, append new insights

**Implementation:**
1. Load existing note via MCP `read_note`
2. Parse markdown structure (identify sections)
3. Append to relevant sections (don't rewrite entire sections)
4. Add new sections if needed
5. Update frontmatter: `updated` timestamp, `claude_last_accessed`
6. Write back via MCP `update_note`

**Example patch patterns:**
- Append to `## Recent Changes` with new entry
- Add new `### Gotcha` under `## Gotchas & Troubleshooting`
- Insert new `### Decision` under `## Key Decisions`
- Append to `## Related Entities` with new links

### Conflict Detection

**Timestamp Comparison Logic:**

```
When loading note:
  Store: note.frontmatter.updated as LOADED_TIMESTAMP
  Update: note.frontmatter.claude_last_accessed = CURRENT_DATE

When updating note:
  Reload: note.frontmatter.updated as CURRENT_TIMESTAMP

  IF CURRENT_TIMESTAMP > LOADED_TIMESTAMP:
    CONFLICT DETECTED (human edited since Claude loaded)
    TRIGGER CONFLICT RESOLUTION
  ELSE:
    SAFE TO UPDATE (no human edits)
    APPLY PATCH
```

**Fields used:**
- `created`: Never changes, original creation date
- `updated`: Modified every time note is saved (by human or Claude)
- `claude_last_accessed`: Updated when Claude loads note into context

### Conflict Resolution Flow

**Case 1: Clean Update (No Conflict)**

```
1. Claude loaded version A at T1
2. No human edits since T1
3. Apply patch operation
4. Update frontmatter:
   - updated = CURRENT_DATE
   - claude_last_accessed = CURRENT_DATE
5. Write via MCP update_note
```

**Case 2: Human Edit Conflict**

```
1. Claude loaded version A at T1 (updated = T1, claude_last_accessed = T1)
2. Human edited to version B at T2 (updated = T2)
3. Claude attempts patch at T3
4. Detect: T2 > T1 (updated > loaded timestamp)
5. Show user:

   "I want to update [[{Entity Name}]] but you've edited it since I loaded it.

   Your changes (at {T2}):
   {DIFF: show what human changed}

   My changes (at {T3}):
   {DIFF: show what Claude wants to add}

   Options:
   1. Show me both diffs and I'll merge manually
   2. Abort your update (keep my changes only)
   3. Create new section '## Claude's Updates (conflicted)'
   4. Let's discuss and resolve together

   What should I do?"

6. Wait for user decision
7. Execute chosen resolution
```

**Case 3: Major Rewrite Needed**

```
1. Claude's understanding contradicts existing note fundamentally
2. Don't silently overwrite user's knowledge
3. Ask user:

   "My understanding of [[{Entity Name}]] changed significantly.

   Current note says:
   {EXCERPT: key claim from existing note}

   But I now think:
   {EXCERPT: contradictory understanding}

   Options:
   1. Create new entity note with alternative understanding
   2. Update existing note (I'll show you the full diff first)
   3. Let's discuss the contradiction - maybe both are valid

   What should I do?"

4. Wait for user decision
5. Execute chosen resolution
```

## Cross-Project Pattern Detection

### Tracking Cross-Project Recalls

**When it happens:**
- Claude is working in Project B
- Loads memory from Project A (via search, graph query, or explicit recall)
- This signals the pattern might be reusable

**Automatic logging:**

```
1. Detect cross-project recall:
   - Current project context: {project-b}
   - Loaded entity: {entity-from-project-a}
   - Entity frontmatter.project: {project-a}
   - IF project-a ≠ project-b: CROSS-PROJECT RECALL

2. Update entity frontmatter:
   Append to cross_project_recalls array:

   cross_project_recalls:
     - project: project-b
       date: 2025-11-18
       context: "Used worktree pattern for parallel tasks"

3. No user-visible noise (silent tracking)
```

### Promotion Threshold Logic

**When to prompt:**
- Entity has 3 or more cross-project recalls
- Entity is currently project-scoped (not global)

**Promotion prompt:**

```
"I've referenced [[{Entity Name}]] from {project-a} while working on other projects 3 times now:

1. {project-b} ({date}): {context}
2. {project-c} ({date}): {context}
3. {project-d} ({date}): {context}

This pattern seems reusable across projects. Should I promote it to global knowledge?

Options:
1. Yes, promote to global (move to ~/.claude-memory/claude/global/entities/)
2. Remind me later (ask again after 5 cross-project recalls)
3. No, it's project-specific (stop tracking)

What should I do?"
```

**Promotion process:**

```
1. User approves promotion
2. Move entity from:
   ~/.claude-memory/claude/projects/{project-a}/entities/{Entity}.md
   TO:
   ~/.claude-memory/claude/global/entities/{Entity}.md
3. Update frontmatter:
   - project: global (was: project-a)
   - Add tag: #global-pattern
4. Create redirect note in original location:
   "This entity has been promoted to global. See [[{Entity}]]"
5. Update all links in project-a notes to point to global entity
6. Confirm: "Promoted [[{Entity}]] to global knowledge."
```

## MCP Operation Patterns

### Required MCP Server

**Dependency:** `obsidian-mcp-plugin` by aaronsb
**Repository:** https://github.com/aaronsb/obsidian-mcp-plugin

### Operations Used

#### 1. create_note

**Purpose:** Create new session, entity, or topic note

**Usage:**
```javascript
mcp.create_note({
  vault: "~/.claude-memory",
  path: "claude/projects/{project}/entities/{Entity Name}.md",
  content: "{markdown content with frontmatter}"
})
```

**Error handling:**
```
TRY:
  create_note(...)
CATCH FileExistsError:
  "Note [[{Entity Name}]] already exists. Use update_note instead."
CATCH MCPUnavailableError:
  "Obsidian MCP server unavailable. Check setup-guide.md for configuration."
```

#### 2. read_note

**Purpose:** Load existing note for updating or reference

**Usage:**
```javascript
mcp.read_note({
  vault: "~/.claude-memory",
  path: "claude/projects/{project}/entities/{Entity Name}.md"
})
```

**Returns:**
```javascript
{
  content: "{full markdown content}",
  frontmatter: {
    type: "entity",
    updated: "2025-11-17",
    claude_last_accessed: "2025-11-16",
    ...
  }
}
```

**Error handling:**
```
TRY:
  read_note(...)
CATCH FileNotFoundError:
  "Note [[{Entity Name}]] not found. Create it with /remember?"
CATCH MCPUnavailableError:
  GRACEFUL_DEGRADATION (see below)
```

#### 3. update_note

**Purpose:** Update existing note with patch operation

**Usage:**
```javascript
mcp.update_note({
  vault: "~/.claude-memory",
  path: "claude/projects/{project}/entities/{Entity Name}.md",
  content: "{updated markdown content}",
  frontmatter: {
    updated: "{CURRENT_DATE}",
    claude_last_accessed: "{CURRENT_DATE}"
  }
})
```

**Error handling:**
```
TRY:
  update_note(...)
CATCH FileNotFoundError:
  "Note disappeared. Create new one?"
CATCH MCPUnavailableError:
  GRACEFUL_DEGRADATION (see below)
```

#### 4. search_notes

**Purpose:** Text search across vault

**Usage:**
```javascript
mcp.search_notes({
  vault: "~/.claude-memory",
  query: "{search term}",
  path_filter: "claude/projects/{project}/**"
})
```

**Returns:**
```javascript
[
  {
    path: "claude/projects/{project}/entities/{Entity}.md",
    snippet: "{matching text}",
    score: 0.95
  },
  ...
]
```

**Error handling:**
```
TRY:
  search_notes(...)
CATCH MCPUnavailableError:
  "Cannot search memories - MCP unavailable."
```

#### 5. graph_query

**Purpose:** Find linked entities via wikilinks

**Usage:**
```javascript
mcp.graph_query({
  vault: "~/.claude-memory",
  start_node: "[[{Entity Name}]]",
  depth: 2,
  direction: "outgoing" // or "incoming" for backlinks
})
```

**Returns:**
```javascript
{
  nodes: [
    { name: "Entity A", type: "entity" },
    { name: "Entity B", type: "entity" }
  ],
  edges: [
    { from: "Entity A", to: "Entity B", type: "wikilink" }
  ]
}
```

**Error handling:**
```
TRY:
  graph_query(...)
CATCH MCPUnavailableError:
  FALLBACK to search_notes (less precise but functional)
```

#### 6. dataview_query

**Purpose:** Query notes using Dataview syntax

**Usage:**
```javascript
mcp.dataview_query({
  vault: "~/.claude-memory",
  query: `
    LIST FROM "claude/projects/{project}/sessions"
    WHERE status = "active"
    SORT created DESC
    LIMIT 3
  `
})
```

**Returns:**
```javascript
[
  {
    path: "claude/projects/{project}/sessions/2025-11-17-memory-design.md",
    frontmatter: { ... }
  },
  ...
]
```

**Error handling:**
```
TRY:
  dataview_query(...)
CATCH DataviewNotInstalledError:
  FALLBACK to search_notes with path filter
CATCH MCPUnavailableError:
  GRACEFUL_DEGRADATION (see below)
```

### Graceful Degradation

**When MCP unavailable:**

```
1. Detect MCP connection failure
2. Show user:
   "Obsidian MCP server is unavailable. I can't access working memory.

   To restore memory features:
   1. Ensure Obsidian is running
   2. Check obsidian-mcp-plugin is installed
   3. Verify Claude Code config includes MCP server

   See docs/setup-guide.md for troubleshooting.

   Continue without memory? (yes/no)"

3. If user says yes:
   - Continue session without memory reads/writes
   - Track what would have been written
   - Offer to export pending writes to markdown file

4. If user says no:
   - Pause work until MCP restored
   - Guide user through troubleshooting
```

**Fallback strategies:**

- graph_query unavailable → use search_notes
- dataview_query unavailable → use search_notes with path filtering
- semantic search unavailable → use text search
- All MCP unavailable → offer manual markdown file export

## TodoWrite Integration

### Memory Checkpoint Checklist

Use when periodic checkpoint time (30-60 min) or major milestone reached:

```
- [ ] Review current session note
- [ ] Identify key decisions made since last checkpoint
- [ ] Update session note with new context
- [ ] Check if any entities need updating
- [ ] Apply patch operations to relevant entity notes
- [ ] Update frontmatter timestamps
- [ ] Verify write count (under 5 per hour limit)
- [ ] Mark checkpoint complete
```

### Session End Checklist

Use at end of work session:

```
- [ ] Final session note update with closing context
- [ ] Check session note size (line count)
- [ ] Check session note age (created date)
- [ ] If threshold met (500 lines OR 3 days old):
  - [ ] Parse session note for extractable knowledge
  - [ ] Identify entities to create or update
  - [ ] Apply patches to entity notes
  - [ ] Create new entities if needed
  - [ ] Archive session note to archive/sessions/
  - [ ] Verify archive successful
- [ ] If threshold not met:
  - [ ] Mark session note status: active
  - [ ] Note next checkpoint time
- [ ] Review cross-project recall tracking
- [ ] Check for promotion threshold (3 recalls)
- [ ] Confirm all writes successful
```

### Compaction Checklist

Use when compacting session note into entity notes:

```
- [ ] Load session note content
- [ ] Parse for distinct concepts/decisions:
  - [ ] Architectural decisions → entity notes
  - [ ] Bug fixes → entity notes (troubleshooting)
  - [ ] New patterns → topic notes or entities
  - [ ] Preferences → user preference entity
- [ ] For each extractable item:
  - [ ] Identify target entity (existing or new)
  - [ ] Prepare patch content
  - [ ] Check for conflicts (timestamp comparison)
  - [ ] Apply patch or resolve conflict
  - [ ] Update frontmatter
- [ ] Create backlinks from entities to archived session
- [ ] Move session note to archive:
  - [ ] Copy to ~/.claude-memory/claude/projects/{project}/archive/sessions/
  - [ ] Verify archive successful
  - [ ] Update session note status: archived
- [ ] Confirm compaction complete
- [ ] Update project index if new entities created
```

## Usage Examples

### Example 1: After Code Review

```
Context: Just completed code review using requesting-code-review skill

Trigger: Automatic (code review complete, no permission needed)

Action:
1. Identify reviewed component: "Git Worktrees Integration"
2. Check if entity exists: search_notes("Git Worktrees")
3. If exists:
   - Load entity via read_note
   - Check timestamps (conflict detection)
   - Append to "## Recent Changes":
     ### 2025-11-18 - Code Review Findings
     - Reviewed implementation of worktree cleanup
     - Decision: Use trap handlers for cleanup on failure
     - Rationale: Ensures cleanup even if subagent crashes
     - Related: [[Error Handling Patterns]]
   - Update frontmatter: updated, claude_last_accessed
   - Write via update_note
4. If not exists:
   - Create entity via create_note (use entity template)
   - Populate with review findings
   - Link to related entities: [[Parallel Execution]], [[Spectacular]]

Result: [[Git Worktrees]] entity updated with code review insights
```

### Example 2: After Debugging

```
Context: Fixed race condition bug using systematic-debugging skill

Trigger: Automatic (debugging complete, no permission needed)

Action:
1. Create or update entity: "Race Condition Debugging"
2. Add to "## Gotchas & Troubleshooting":
   ### Parallel Phase Cleanup Race Condition

   **Symptom:** Worktree cleanup fails intermittently with "directory not empty"
   **Root Cause:** Cleanup runs before subagent finishes writing
   **Solution:** Add wait for background processes before cleanup
   **Tags:** #debugging #race-condition #parallel-execution

   **Code:**
   ```bash
   # Wait for all background processes
   wait
   # Then cleanup
   rm -rf worktree
   ```
3. Update session note with debugging story (context for future)
4. Link to related entities: [[Parallel Execution]], [[Error Handling]]

Result: [[Race Condition Debugging]] entity created/updated, pattern documented
```

### Example 3: User Preference (Ask First)

```
Context: User says "I prefer conventional commits for all commits"

Trigger: Ask-first (user preference)

Action:
1. Detect preference statement
2. Ask user:
   "You mentioned preferring conventional commits. Should I remember this preference?

   This would create/update an entity: [[User Preferences - Commits]]

   Options:
   1. Yes, remember this
   2. No, just for this session
   3. Let me think about it

   What should I do?"

3. If user approves:
   - Create/update [[User Preferences - Commits]]
   - Add to "## Commit Style":
     **Preference:** Conventional commits
     **Format:** type(scope): description
     **Rationale:** {what user said}
     **Date noted:** 2025-11-18
   - Apply in future commits automatically

Result: User preference documented and respected in future sessions
```

### Example 4: Cross-Project Recall

```
Context: Working in project-b, recalled [[Git Worktrees]] from project-a

Trigger: Automatic (silent tracking, no user-visible action)

Action:
1. Detect cross-project recall:
   - Current project: project-b
   - Entity project: project-a
   - Different → log it

2. Update [[Git Worktrees]] frontmatter:
   cross_project_recalls:
     - project: project-a
       date: 2025-11-16
       context: "Initial creation"
     - project: project-b
       date: 2025-11-18
       context: "Used worktree pattern for parallel tasks"

3. Check count: 2 cross-project recalls (threshold is 3)
4. No action yet (wait for threshold)

Later: Third cross-project recall from project-c

Action:
1. Detect: 3 cross-project recalls (threshold met)
2. Ask user:
   "I've referenced [[Git Worktrees]] from project-a while working on other projects 3 times now:

   1. project-b (2025-11-18): Used worktree pattern for parallel tasks
   2. project-c (2025-11-19): Referenced for isolation strategy
   3. project-d (2025-11-20): Applied to test environment setup

   This pattern seems reusable. Promote to global knowledge?

   Options:
   1. Yes, promote to global
   2. Remind me at 5 recalls
   3. No, it's project-specific

   What should I do?"

3. If approved: Execute promotion (move to global/entities/, update links)

Result: Pattern promoted to global knowledge, easier discovery in future
```

## Best Practices

### Do's

- ✅ Preserve existing content (patch operations, not rewrites)
- ✅ Always check timestamps before updating (conflict detection)
- ✅ Show diffs when conflicts detected (transparency)
- ✅ Link entities via wikilinks (build knowledge graph)
- ✅ Tag appropriately (enables Dataview queries)
- ✅ Update frontmatter every write (timestamps critical)
- ✅ Ask permission for subjective content (preferences, contradictions)
- ✅ Batch related updates (reduce write spam)
- ✅ Archive, don't delete (preserve history)
- ✅ Use descriptive entity names (clear, searchable)

### Don'ts

- ❌ Don't rewrite entire notes (use patch operations)
- ❌ Don't skip conflict detection (causes data loss)
- ❌ Don't write more than 5 times per hour (spam)
- ❌ Don't create duplicate entities (search first)
- ❌ Don't overwrite human edits silently (ask first)
- ❌ Don't create entities prematurely (wait for pattern to emerge)
- ❌ Don't delete notes (archive instead)
- ❌ Don't forget cross-project tracking (promotion opportunity)
- ❌ Don't write without frontmatter (breaks queries)
- ❌ Don't use vague entity names (be specific)

## Troubleshooting

### Issue: MCP Connection Failed

**Symptom:** `MCPUnavailableError` when trying to read/write notes

**Diagnosis:**
1. Check Obsidian is running
2. Check obsidian-mcp-plugin installed in vault
3. Check Claude Code config includes MCP server
4. Check vault path is correct

**Solution:** See docs/setup-guide.md for full MCP setup instructions

**Workaround:** Continue without memory, export pending writes to markdown file at session end

### Issue: Conflict Detection False Positive

**Symptom:** Conflict detected but user didn't edit note

**Diagnosis:**
1. Check if another Claude session edited note
2. Check if Obsidian sync changed timestamps
3. Check if filesystem events triggered spurious update

**Solution:**
- Show diff to user (likely minor)
- If diff is empty: ignore conflict, proceed with update
- If diff is real but minor: ask user to merge
- If false positive pattern repeats: adjust timestamp granularity

### Issue: Memory Spam

**Symptom:** Too many write operations, cluttering vault

**Diagnosis:**
1. Count writes in current session
2. Review what triggered each write
3. Identify if triggers are too aggressive

**Solution:**
- Batch related updates into single operation
- Increase checkpoint interval (60-90 min instead of 30-60)
- Ask user: "Reduce memory write frequency?"
- Adjust trigger sensitivity

### Issue: Search Returns Irrelevant Results

**Symptom:** Recalled memories not related to current work

**Diagnosis:**
1. Check search query (too broad?)
2. Check if semantic search is available (better relevance)
3. Review entity tags (improve discoverability)

**Solution:**
- Refine search queries (use more specific terms)
- Add tags to entities (improve filtering)
- Install Smart Connections plugin (semantic search)
- Use graph queries instead of text search (more precise)

### Issue: Session Note Too Large

**Symptom:** Session note exceeds 500 lines, performance degrading

**Diagnosis:**
1. Check line count: `wc -l session-note.md`
2. Review if compaction threshold was missed
3. Check if threshold detection is working

**Solution:**
- Trigger compaction immediately
- Extract knowledge into entity notes
- Archive session note
- Adjust threshold if too high (reduce to 300 lines?)

### Issue: Cross-Project Promotion Not Triggering

**Symptom:** Entity used across projects but no promotion prompt

**Diagnosis:**
1. Check cross_project_recalls frontmatter (is it logging?)
2. Check recall count (reached threshold of 3?)
3. Review detection logic (cross-project recall tracking)

**Solution:**
- Manually check entity frontmatter
- If logging works but prompt missing: check promotion threshold logic
- If logging not working: verify cross-project detection in recall flow
- Ask user manually: "Should [[Entity]] be global?"

---

## Summary

This skill enables Claude to maintain proactive, updateable working memory using Obsidian as the backend. Key principles:

1. **Automatic with selective asking** - Write memories autonomously, ask for subjective content
2. **Three-layer granularity** - Session (temporal), Entity (persistent), Topic (organizational)
3. **Living memory** - Patch operations preserve existing content while adding new insights
4. **Conflict detection** - Timestamp comparison prevents data loss from human edits
5. **Cross-project patterns** - Track reuse, promote to global at threshold
6. **Graceful degradation** - Fallback strategies when MCP unavailable
7. **Memory spam prevention** - Limit writes to <5 per hour
8. **TodoWrite integration** - Checklists for checkpoints, session end, compaction

Use this skill to ensure context persists across sessions, decisions are documented with rationale, and patterns are captured for future reuse.
