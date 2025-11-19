# Session End Hook

This hook runs automatically when a Claude Code session ends, handling session note updates, threshold-based compaction, and archival.

## Overview

**Purpose:** Finalize session notes, compact if threshold exceeded, and archive completed sessions

**Compaction Threshold:** 500 lines OR 3 days old (whichever comes first)

**Archival Strategy:** Never delete, always archive to preserve history

## Implementation

### 1. Load Current Session Note

1. Detect the project context (same logic as session-start hook)

2. Determine the session note path:
   - Get current date in YYYY-MM-DD format
   - Infer session topic from work log or user input
   - Construct path: `claude/projects/{projectContext}/sessions/{date}-{topic}.md`

3. Attempt to load the session note using MCP vault tool:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "read",
     path: `claude/projects/${projectContext}/sessions/${date}-${topic}.md`,
     returnFullFile: true
   })
   ```

4. Handle different cases:

   **If session note exists:**
   - Proceed to finalize the session (next steps)

   **If FileNotFoundError:**
   - No session note was created this session
   - Display: "No session note created this session."
   - Exit normally (no-op)

   **If MCPUnavailableError:**
   - Display: "MCP unavailable. Cannot finalize session."
   - See error recovery section below for options

### 2. Final Session Note Update

1. Append session closing entry to the "## Work Log" section:
   - Add timestamp with current time
   - Add heading: "Session End"
   - Add message: "Session completed. Work finalized."

2. Update frontmatter:
   - Set updated to current date (YYYY-MM-DD)
   - Set claude_last_accessed to current date

3. Write the final update using MCP vault tool:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "update",
     path: sessionPath,
     content: updatedContentWithFrontmatter
   })
   ```

   Or use edit tool for efficient append:
   ```javascript
   // Append closing entry
   mcp__obsidian-vault__edit({
     action: "append",
     path: sessionPath,
     content: `\n### ${timestamp} - Session End\n\nSession completed. Work finalized.`
   });

   // Update frontmatter
   mcp__obsidian-vault__edit({
     action: "patch",
     path: sessionPath,
     targetType: "frontmatter",
     target: "updated",
     operation: "replace",
     content: new Date().toISOString().split('T')[0]
   });
   ```

4. Proceed to check compaction threshold (next step)

### 3. Check Compaction Threshold

**Threshold Logic:**

1. Count lines in the session note by splitting content on newlines

2. Calculate age in days:
   - Parse created date from frontmatter
   - Compare with current date
   - Calculate difference in days

3. Check if either threshold is exceeded:
   - Line threshold: >= 500 lines
   - Age threshold: >= 3 days

4. If either threshold is exceeded:
   - Display reason: "Session note {exceeds 500 lines / exceeds 3 days old}. Triggering compaction..."
   - Trigger compaction (next step)

5. If both thresholds are not exceeded:
   - Display: "Session note below threshold ({lineCount} lines, {ageInDays} days old). Keeping active."
   - Mark session status as "active" in frontmatter
   - Update the note using MCP edit tool:
     ```javascript
     mcp__obsidian-vault__edit({
       action: "patch",
       path: sessionPath,
       targetType: "frontmatter",
       target: "status",
       operation: "replace",
       content: "active"
     })
     ```

**Threshold Rules:**
- **500 lines:** Session note becomes too large to navigate efficiently
- **3 days old:** Knowledge should be consolidated into entities for long-term retention
- **Whichever comes first:** More aggressive compaction ensures timely knowledge extraction

### 4. Compact Session Note (I1: Simplified Algorithm)

**Compaction Process:**

1. Display: "Compacting session note into entity notes..."

2. Parse the session note to identify extractable knowledge:
   - Use high-level heuristics rather than detailed algorithms
   - Look for distinct concepts and decisions

3. For each identified piece of knowledge:
   - Update or create the appropriate entity note
   - See step 5 for entity update logic

4. Archive the session note (step 6)

5. Display: "Compaction complete. Session archived."

**Knowledge Extraction (Simplified):**

Parse the session note to identify key extractable knowledge:

1. **Extract decisions** from "## Decisions Made" section
   - Each decision entry becomes an update to an entity note
   - Infer which entity based on context and related entities

2. **Extract gotchas** from "## Work Log" section
   - Look for debugging work: "fixed bug", "troubleshot", "resolved issue"
   - Each gotcha updates the troubleshooting section of an entity

3. **Extract references** from wikilinks throughout the note
   - All wikilinked entities get updated with reference to this session

**Extraction Categories:**
- **Architectural decisions** → Update entity notes with decision and rationale
- **Bug fixes / gotchas** → Update entity troubleshooting section
- **New patterns** → Create topic notes or new entities
- **User preferences** → Update user preference entity

**Note:** Keep extraction logic flexible. Claude should use judgment to identify valuable knowledge rather than following rigid algorithms.

### 5. Update Entity Notes

Use the patch operations and conflict detection patterns from the managing-working-memory skill.

For each extracted piece of knowledge:

1. Determine the target entity note path:
   - `claude/projects/{projectContext}/entities/{entityName}.md`

2. Attempt to load the existing entity using MCP vault tool:
   ```javascript
   const loadResult = await mcp__obsidian-vault__vault({
     action: "read",
     path: `claude/projects/${projectContext}/entities/${entityName}.md`,
     returnFullFile: true
   });
   ```

3. Store the loaded content for conflict detection

4. Apply patch operation based on knowledge type (using efficient edit tool):
   - **Decision:** Append to "## Key Decisions" section
     ```javascript
     mcp__obsidian-vault__edit({
       action: "patch",
       path: entityPath,
       targetType: "heading",
       target: "Key Decisions",
       operation: "append",
       content: `\n- ${date}: ${decisionText}`
     })
     ```
   - **Gotcha:** Append to "## Gotchas & Troubleshooting" section
   - **Reference:** Append to "## Recent Changes" section

5. Before writing, reload the entity and check for conflicts:
   - Compare loaded content with current content
   - If conflict detected, trigger conflict resolution
   - If no conflict, proceed with update

6. Update frontmatter timestamps:
   ```javascript
   mcp__obsidian-vault__edit({
     action: "patch",
     path: entityPath,
     targetType: "frontmatter",
     target: "updated",
     operation: "replace",
     content: new Date().toISOString().split('T')[0]
   })
   ```

7. Display: "Updated [[{entityName}]] with knowledge from session."

8. Handle errors:
   - If FileNotFoundError: Create new entity from session knowledge
   - If other error: Propagate

**Conflict Handling:** Uses same timestamp-based detection as defined in `managing-working-memory.md`

### 6. Archive Session Note

**Archival Process:**

1. Determine archive path:
   - Format: `claude/projects/{projectContext}/archive/sessions/{filename}`
   - Use same filename as original session note

2. Update session note metadata:
   - Set status to "archived" in frontmatter
   - Set updated to current date
   - Add archived_date field with current date
   - Add archived_reason: "Compaction threshold exceeded"

3. Ensure archive directory exists (create if needed)

4. Copy session note to archive location using MCP vault tool:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "create",
     path: `claude/projects/${projectContext}/archive/sessions/${filename}`,
     content: sessionContentWithArchivedFrontmatter
   })
   ```

5. Verify archive was successful by attempting to read the archived note

6. If verification successful:
   - Display: "Session archived to: {archivePath}"
   - Leave original note with archived status (default behavior)
   - User can manually delete original if desired

7. If verification fails:
   - Throw error: "Archive verification failed. Session not moved."
   - Keep original note intact

**Archive Location:** `~/.claude-memory/claude/projects/{project}/archive/sessions/{date}-{topic}.md`

**Preservation Strategy:**
- Never delete notes (always archive)
- Archived notes retain full content and frontmatter
- Status marked as "archived" in frontmatter
- Original note can optionally be removed (default: keep with archived status)

### 7. Create Backlinks

**Link archived session to updated entities:**

For each entity that was updated during compaction:

1. Determine the entity path:
   - `claude/projects/{projectContext}/entities/{entityName}.md`

2. Load the entity using MCP vault tool:
   ```javascript
   mcp__obsidian-vault__vault({
     action: "read",
     path: `claude/projects/${projectContext}/entities/${entityName}.md`,
     returnFullFile: true
   })
   ```

3. Create a backlink to the archived session:
   - Format: `- [[{session-filename}]] - Archived session (compacted)`
   - Extract filename from session path (without .md extension)

4. Append the backlink to the "## References" section of the entity

5. Update the entity frontmatter:
   - Set updated to current date

6. Write the updated entity using MCP edit tool:
   ```javascript
   // Append backlink to References section
   mcp__obsidian-vault__edit({
     action: "patch",
     path: entityPath,
     targetType: "heading",
     target: "References",
     operation: "append",
     content: `\n- [[${sessionFilename}]] - Archived session (compacted)`
   });

   // Update frontmatter
   mcp__obsidian-vault__edit({
     action: "patch",
     path: entityPath,
     targetType: "frontmatter",
     target: "updated",
     operation: "replace",
     content: new Date().toISOString().split('T')[0]
   });
   ```

This creates bidirectional links between archived sessions and the entities they contributed to.

## Error Handling and Recovery (I2)

### MCP Unavailable

When MCP server is unavailable at session end:

1. Detect the MCPUnavailableError

2. Display message listing pending actions:
   ```
   Obsidian MCP unavailable. Cannot finalize session.

   Pending actions:
   - Session note update
   - Compaction check
   - Archival (if threshold exceeded)
   ```

3. **Decision Point - Ask User:**
   - **Option A: Exit without finalization**
     - Session ends without memory updates
     - User must manually run session cleanup later
     - Provide manual steps:
       1. Check session note line count and age
       2. If threshold exceeded, compact into entity notes
       3. Archive to archive/sessions/ directory
   - **Option B: Wait and retry**
     - Pause session end
     - Wait for user to fix MCP connection
     - Retry finalization once fixed
   - **Option C: Export pending work**
     - Create local file with session summary
     - User can manually update memory later
     - Provide file path and instructions

4. Display troubleshooting reference: "See docs/setup-guide.md for MCP troubleshooting."

### Compaction Failure

When compaction fails for any reason:

1. Catch the error and log it

2. **Decision Point - Do NOT archive if compaction failed**
   - Leave session note as-is
   - Session remains active until compaction succeeds

3. Display error message with manual action steps:
   ```
   Session compaction failed. Session note preserved.

   Manual action required:
   1. Review session note: {sessionPath}
   2. Extract knowledge into entity notes manually
   3. Archive session when complete

   Error: {error.message}
   ```

4. Mark session with error status:
   - Set frontmatter.status = "compaction_failed"
   - Add frontmatter.error = error message
   - Update note using MCP edit tool:
     ```javascript
     mcp__obsidian-vault__edit({
       action: "patch",
       path: sessionPath,
       targetType: "frontmatter",
       target: "status",
       operation: "replace",
       content: "compaction_failed"
     });

     mcp__obsidian-vault__edit({
       action: "patch",
       path: sessionPath,
       targetType: "frontmatter",
       target: "error",
       operation: "replace",
       content: error.message
     });
     ```

5. **Recovery options:**
   - User can manually compact and archive later
   - On next session, user can trigger manual compaction
   - Session will remain in active state with error marker

### Archive Verification Failed

When archive verification fails:

1. Detect that archived note cannot be read

2. Display error: "Archive verification failed. Session not moved."

3. **Decision Point - Abort archival, keep session active:**
   - Do NOT remove original session note
   - Revert session status to "active"
   - Add frontmatter.archive_error = "Verification failed"

4. Update the original session note using MCP edit tool:
   ```javascript
   mcp__obsidian-vault__edit({
     action: "patch",
     path: sessionPath,
     targetType: "frontmatter",
     target: "status",
     operation: "replace",
     content: "active"
   });

   mcp__obsidian-vault__edit({
     action: "patch",
     path: sessionPath,
     targetType: "frontmatter",
     target: "archive_error",
     operation: "replace",
     content: "Verification failed"
   });
   ```

5. Throw error to halt session end process:
   - "Archive failed - session preserved at original location"

6. **Recovery options:**
   - User can investigate why archive failed
   - Retry archival on next session end
   - Manually move to archive directory if needed

## Integration with Managing Working Memory Skill

**Session End Checklist:** Uses TodoWrite checklist from `skills/managing-working-memory.md`:

```markdown
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

**Compaction Triggers:** Aligns with triggers defined in managing-working-memory skill

## Performance Considerations

### Compaction Performance

To avoid session-end delays, optimize compaction performance:

1. **Track timing:**
   - Record start time before compaction begins
   - Record end time after archival completes
   - Calculate total duration in milliseconds

2. **Optimize operations:**
   - Parse session (fast - single pass)
   - Batch entity updates in parallel using Promise.all
   - Archive in single operation (not per-entity)

3. **Display timing:**
   - Show "Compaction completed in {duration}ms"

4. **Performance target:** <5 seconds for compaction (even with 10+ entity updates)

### Async Session End

Don't block session exit if MCP operations are slow:

1. Display: "Finalizing session..."

2. Run session-end hook asynchronously:
   - Execute all finalization steps
   - Allow user to exit if it takes too long

3. Handle completion:

   **If successful:**
   - Display: "Session finalized successfully."

   **If error:**
   - Display: "Session end failed: {error.message}"
   - Display: "Session state preserved. Manual cleanup may be needed."
   - Allow user to exit anyway (don't block)

## Testing

### Manual Testing

1. Create session note with >500 lines
2. Run session-end hook
3. Verify compaction triggered
4. Check entity notes updated
5. Verify session archived at correct path
6. Confirm original session marked as "archived"

### Edge Cases

- **Session note <500 lines and <3 days old:** No compaction, marked active
- **MCP unavailable:** Graceful error, pending actions logged
- **Compaction failure:** Session preserved, error status set
- **No session note:** No-op, clean exit
- **Archive directory missing:** Create directory automatically

### Threshold Testing

**Test Case 1: Line Threshold**
- Session with 600 lines, 1 day old
- Expected: Compact (exceeds 500 lines)

**Test Case 2: Age Threshold**
- Session with 300 lines, 4 days old
- Expected: Compact (exceeds 3 days)

**Test Case 3: Both Thresholds**
- Session with 600 lines, 4 days old
- Expected: Compact (exceeds both thresholds)

**Test Case 4: Neither Threshold**
- Session with 200 lines, 1 day old
- Expected: Mark active, no compaction

## Example Session End Flow

```
$ exit

[Session End Hook Executing...]

Finalizing session for project: tabula-scripta

Session note: 2025-11-18-session-hooks.md
Status: 487 lines, 1 day old (below threshold)

Marking session as active (no compaction needed).

Session finalized successfully.

---

Goodbye!
```

**With Compaction:**

```
$ exit

[Session End Hook Executing...]

Finalizing session for project: tabula-scripta

Session note: 2025-11-15-memory-design.md
Status: 623 lines, 1 day old (exceeds 500 line threshold)

Triggering compaction...

Extracting knowledge:
- 3 architectural decisions → [[Memory System Architecture]]
- 2 debugging insights → [[Conflict Detection]]
- 5 entity references → Updated backlinks

Compaction complete. Session archived to:
  archive/sessions/2025-11-15-memory-design.md

Session finalized successfully.

---

Goodbye!
```

## Summary

This session-end hook finalizes working memory at the end of each session:

1. **Loads current session note** and applies final update
2. **Checks compaction threshold** (500 lines OR 3 days old)
3. **Compacts if threshold exceeded** by extracting knowledge into entity notes
4. **Archives session note** to preserve history (never deletes)
5. **Updates entity notes** with decisions, gotchas, and patterns
6. **Creates backlinks** from entities to archived session
7. **Handles errors gracefully** (MCP unavailable, compaction failures, etc.)

Users experience automatic knowledge consolidation without manual effort, while maintaining full session history in archived notes for future reference.
