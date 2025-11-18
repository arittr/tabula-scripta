# Working Memory Patterns & Examples

This guide demonstrates practical usage patterns for the tabula-scripta working memory system, showing how to integrate memory management with your daily Claude Code workflows.

## Overview

The working memory system provides three layers of memory granularity, each serving distinct purposes in building persistent context across sessions.

### Three-Layer Memory Model

#### Session Notes (Temporal, Ephemeral)
- **Location:** `~/.claude-memory/claude/projects/{project}/sessions/{date}-{topic}.md`
- **Purpose:** Updateable scratchpad for current work
- **Lifecycle:** Created at session start, updated during work, compacted when threshold met (500 lines OR 3 days old)
- **Best for:** Stream of consciousness, tracking decisions as they happen, capturing context for resuming work

#### Entity Notes (Persistent, Specific)
- **Location:** `~/.claude-memory/claude/projects/{project}/entities/{Entity Name}.md`
- **Global:** `~/.claude-memory/claude/global/entities/{Entity Name}.md`
- **Purpose:** One note per concept/component/pattern
- **Lifecycle:** Created when concept emerges, updated via patches (not rewrites), archived if obsolete (never deleted)
- **Best for:** Component documentation, architectural decisions, debugging patterns, gotchas and troubleshooting

#### Topic Notes (Organizational)
- **Location:** `~/.claude-memory/claude/global/topics/{Topic Name}.md`
- **Purpose:** Maps of Content (MOC) linking related entities
- **Lifecycle:** Created when pattern emerges across multiple entities, human-curated over time
- **Best for:** Conceptual frameworks, learning paths, best practice collections

### Memory Lifecycle and Transitions

```
Session Start
    ↓
Session Note Created (temporal)
    ↓
Work happens → Decisions captured → Patterns emerge
    ↓
Checkpoint (30-60 min) → Update session note
    ↓
Threshold Met (500 lines OR 3 days)
    ↓
Compaction: Extract knowledge → Update entity notes
    ↓
Session Note Archived → Entity notes persist
    ↓
Cross-project recalls (3+) → Promote to global entity
    ↓
Related entities clustered → Topic note created
```

---

## Pattern Examples

### Pattern 1: Debugging Session → Entity Update

**Scenario:** You've been debugging a race condition for the past hour. The bug is fixed, tests pass, and you've learned a valuable troubleshooting pattern.

**Memory Flow:**

1. **During debugging:** Session note tracks your investigation
   ```markdown
   ## Work Log

   ### 14:30 - Race Condition Investigation

   Seeing intermittent failures in parallel phase cleanup. Error: "directory not empty".

   Tried:
   - Adding sleep (didn't work - timing-dependent)
   - Checking for file locks (not the issue)
   - Reviewing cleanup order (found it!)

   ## Decisions Made

   - **Wait for background processes before cleanup**: Cleanup was running while subagent still writing
   - **Rationale**: Race condition - cleanup must wait for all background work to complete
   - **Implementation**: Add `wait` before `rm -rf worktree`
   ```

2. **After fix verified:** Automatic trigger fires (systematic-debugging skill completes)

3. **Entity update:** Create or update `[[Race Condition Debugging]]` entity
   ```markdown
   ---
   type: entity
   project: tabula-scripta
   tags: [debugging, race-condition, parallel-execution]
   created: 2025-11-15
   updated: 2025-11-15
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Race Condition Debugging

   ## Gotchas & Troubleshooting

   ### Parallel Phase Cleanup Race Condition

   **Symptom:** Worktree cleanup fails intermittently with "directory not empty"
   **Root Cause:** Cleanup runs before subagent finishes writing files
   **Solution:** Add wait for background processes before cleanup
   **Tags:** #debugging #race-condition #parallel-execution

   **Code:**
   ```bash
   # Wait for all background processes
   wait
   # Then cleanup
   rm -rf worktree
   ```

   **Detection:** Non-deterministic failures, works sometimes, fails others
   **Prevention:** Always wait for async operations before cleanup

   ## Related Entities

   - [[Parallel Execution Patterns]] - Context for parallel workflows
   - [[Error Handling]] - General error handling strategies
   ```

**Result:** Bug fix documented, pattern captured for future reference, searchable by symptom keywords.

---

### Pattern 2: Architecture Decision → Topic Note

**Scenario:** You've been refining the memory system architecture across multiple sessions, making decisions about granularity, triggers, and conflict resolution. These decisions form a cohesive architectural pattern.

**Memory Flow:**

1. **Multiple entity notes created:**
   - `[[Memory Granularity]]` - Decision: Three-layer system (session/entity/topic)
   - `[[Conflict Detection]]` - Decision: Timestamp-based conflict detection
   - `[[Write Triggers]]` - Decision: Automatic vs ask-first triggers
   - `[[Cross-Project Patterns]]` - Decision: Promotion threshold at 3 recalls

2. **Pattern emerges:** These entities form a conceptual cluster

3. **Topic note created:** `[[Memory System Architecture]]`
   ```markdown
   ---
   type: topic
   project: global
   tags: [topic, moc, architecture, memory-systems]
   created: 2025-11-15
   updated: 2025-11-15
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Memory System Architecture

   ## Overview

   Architectural patterns for building Claude Code working memory systems using Obsidian as the backend. This topic covers granularity design, conflict resolution, trigger strategies, and cross-project knowledge promotion.

   ## Key Concepts

   - [[Memory Granularity]] - Three-layer system design (session/entity/topic)
   - [[Conflict Detection]] - Timestamp-based conflict prevention
   - [[Write Triggers]] - Automatic vs ask-first trigger strategies
   - [[Cross-Project Patterns]] - Knowledge promotion and reuse
   - [[MCP Integration]] - Obsidian MCP operations and graceful degradation

   ## Patterns & Best Practices

   ### Pattern: Temporal to Persistent Knowledge Flow

   Start with session notes (temporal scratchpad), extract knowledge into entity notes (persistent), cluster entities into topic notes (organizational).

   **Why it works:** Captures context quickly during work, distills into reusable knowledge over time.

   **Related Entities:** [[Memory Granularity]], [[Session Compaction]]

   ### Pattern: Conflict-Aware Living Memory

   Always check timestamps before updating notes. Human edits win. Show diffs for transparency.

   **Why it works:** Prevents data loss from concurrent edits, maintains trust through transparency.

   **Related Entities:** [[Conflict Detection]], [[Patch Operations]]

   ### Pattern: Cross-Project Knowledge Promotion

   Track when entities are recalled across projects. At 3 recalls, prompt to promote to global knowledge.

   **Why it works:** Identifies reusable patterns without premature abstraction.

   **Related Entities:** [[Cross-Project Patterns]], [[Global Entities]]

   ## Common Pitfalls

   - **Memory spam:** Don't write more than 5 times per hour. Batch related updates.
   - **Premature entities:** Wait for patterns to emerge (2-3 occurrences) before creating entities.
   - **Rewriting instead of patching:** Always append to existing content, don't replace.
   - **Skipping conflict detection:** Always check timestamps before updating.

   ## Learning Path

   1. Start with: [[Memory Granularity]] - Understand the three-layer model
   2. Then explore: [[Write Triggers]] - Know when to write memories
   3. Then explore: [[Conflict Detection]] - Handle concurrent edits safely
   4. Advanced: [[Cross-Project Patterns]] - Build global knowledge

   ## References

   - Spec: `specs/e22e0d-working-memory-system/spec.md`
   - Skill: `skills/managing-working-memory.md`
   - Setup: `docs/setup-guide.md`
   ```

**Result:** Architectural knowledge organized, learning path defined, reusable across projects.

---

### Pattern 3: Code Review → Entity Refinement

**Scenario:** You've just completed a code review using the `requesting-code-review` skill. The review revealed architectural insights about the component being reviewed.

**Memory Flow:**

1. **Code review completes:** Acceptance criteria met, review approved

2. **Automatic trigger fires:** No permission needed (code review completion)

3. **Check for existing entity:** Search for `[[Git Worktrees Integration]]`

4. **Entity exists:** Load and check timestamps
   ```yaml
   updated: 2025-11-17
   claude_last_accessed: 2025-11-17
   ```

5. **No conflict:** Current timestamp (2025-11-17) > loaded timestamp (2025-11-16), no human edits

6. **Patch operation:** Append to Recent Changes section
   ```markdown
   ## Recent Changes

   ### 2025-11-17 - Code Review Findings

   Reviewed implementation of worktree cleanup logic.

   **Decision:** Use trap handlers for cleanup on failure
   **Rationale:** Ensures cleanup even if subagent crashes mid-execution
   **Implementation:** Added `trap 'cleanup_worktree' EXIT ERR INT TERM`
   **Impact:** More robust failure handling, prevents orphaned worktrees

   **Related:** [[Error Handling Patterns]], [[Parallel Execution]]
   ```

7. **Update frontmatter:**
   ```yaml
   updated: 2025-11-17
   claude_last_accessed: 2025-11-17
   ```

**Result:** Code review insights captured, architectural decision documented with rationale.

---

### Pattern 4: Cross-Project Pattern Promotion

**Scenario:** You've been using the git worktrees pattern across multiple projects. It's time to promote it to global knowledge.

**Memory Flow:**

1. **Initial creation (Project A - tabula-scripta):**
   ```yaml
   type: entity
   project: tabula-scripta
   cross_project_recalls: []
   ```

2. **First cross-project recall (Project B - another-tool):**
   - Working in Project B, search recalls `[[Git Worktrees]]` from Project A
   - Automatic logging (silent, no user interruption):
   ```yaml
   cross_project_recalls:
     - project: another-tool
       date: 2025-11-16
       context: "Recalled via search: 'isolation patterns'"
   ```

3. **Second cross-project recall (Project C - web-app):**
   ```yaml
   cross_project_recalls:
     - project: another-tool
       date: 2025-11-16
       context: "Recalled via search: 'isolation patterns'"
     - project: web-app
       date: 2025-11-17
       context: "Recalled via search: 'parallel tasks'"
   ```

4. **Third cross-project recall (Project D - cli-tool):**
   - Threshold met (3 cross-project recalls)
   - Promotion prompt triggered:
   ```
   I've referenced [[Git Worktrees]] from tabula-scripta while working on other projects 3 times now:

   1. another-tool (2025-11-16): Recalled via search: 'isolation patterns'
   2. web-app (2025-11-17): Recalled via search: 'parallel tasks'
   3. cli-tool (2025-11-17): Session start recall

   This pattern seems reusable across projects. Should I promote it to global knowledge?

   Options:
   1. Yes, promote to global (move to ~/.claude-memory/claude/global/entities/)
   2. Remind me later (ask again after 5 cross-project recalls)
   3. No, it's project-specific (stop tracking)

   What should I do?
   ```

5. **User approves (Option 1):**
   - Move entity from `claude/projects/tabula-scripta/entities/Git Worktrees.md`
   - To: `claude/global/entities/Git Worktrees.md`
   - Update frontmatter: `project: global`
   - Add tag: `#global-pattern`
   - Create redirect in original location:
   ```markdown
   This entity has been promoted to global knowledge.

   See: [[Git Worktrees]]
   ```

**Result:** Pattern promoted to global knowledge, easier discovery across all future projects.

---

### Pattern 5: Session Compaction → Knowledge Extraction

**Scenario:** You've been working on implementing the memory system for several days. Your session note has grown to 520 lines and contains valuable architectural decisions, debugging insights, and pattern discoveries.

**Memory Flow:**

1. **Session end triggered:** Claude Code session ending

2. **Threshold detection:**
   ```
   Session note: 2025-11-15-memory-design.md
   Status: 520 lines, 1 day old
   Threshold: 500 lines OR 3 days old
   Result: EXCEEDS line threshold → Compaction triggered
   ```

3. **Knowledge extraction:** Parse session note for extractable knowledge
   ```markdown
   ## Extractable Knowledge Identified:

   Architectural Decisions (3):
   - Three-layer memory system (session/entity/topic)
   - Timestamp-based conflict detection
   - Automatic vs ask-first trigger strategy

   Debugging Insights (2):
   - Race condition in parallel phase cleanup
   - MCP connection retry logic

   Entity References (5):
   - [[Memory Granularity]]
   - [[Conflict Detection]]
   - [[Write Triggers]]
   - [[Parallel Execution Patterns]]
   - [[MCP Integration]]
   ```

4. **Entity updates:** Apply patch operations to update entities

   **Example: Update [[Memory Granularity]] entity**
   ```markdown
   ---
   type: entity
   project: tabula-scripta
   tags: [architecture, memory-system]
   created: 2025-11-14
   updated: 2025-11-15  # Updated during compaction
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Memory Granularity

   ## Recent Changes

   ### 2025-11-15 - Architecture Decision (from session compaction)

   **Decision:** Three-layer memory system
   - **Layers:** Session notes (temporal), Entity notes (persistent), Topic notes (organizational)
   - **Rationale:** Balances quick capture during work with long-term knowledge retention
   - **Flow:** Session → Entity (compaction) → Topic (clustering)
   - **Source:** Session 2025-11-15-memory-design (archived)

   **Related:** [[Session Compaction]], [[Entity Notes]], [[Topic Notes]]
   ```

   **Example: Update [[Parallel Execution Patterns]] entity**
   ```markdown
   ## Gotchas & Troubleshooting

   ### Cleanup Race Condition (from session compaction)

   **Symptom:** Worktree cleanup fails with "directory not empty"
   **Root Cause:** Cleanup runs before background processes finish
   **Solution:** Add `wait` before cleanup to ensure all processes complete
   **Tags:** #debugging #race-condition #parallel

   **Code:**
   ```bash
   # Wait for all background processes
   wait
   # Then cleanup
   rm -rf worktree
   ```

   **Source:** Session 2025-11-15-memory-design (archived)
   ```

5. **Session archival:**
   - Move session note from: `sessions/2025-11-15-memory-design.md`
   - To: `archive/sessions/2025-11-15-memory-design.md`
   - Update frontmatter:
   ```yaml
   status: archived
   archived_date: 2025-11-15
   archived_reason: "Compaction threshold exceeded (520 lines)"
   ```

6. **Create backlinks:** Link entities to archived session
   ```markdown
   ## References (in each updated entity)

   - [[2025-11-15-memory-design]] - Archived session (compacted)
   ```

7. **Compaction summary:**
   ```
   Compaction complete:
   - Extracted 3 architectural decisions → 3 entity updates
   - Extracted 2 debugging insights → 2 entity updates
   - Updated 5 entity backlinks
   - Archived session to: archive/sessions/2025-11-15-memory-design.md
   - Completed in 1.2s
   ```

**Result:** Session knowledge consolidated into persistent entities, session archived for historical reference, knowledge graph enriched with new connections.

---

## Skill Integration Patterns

### Integration: requesting-code-review

**When:** After code review completes successfully

**Scenario:** You've completed a code review for the worktree cleanup implementation using the `requesting-code-review` skill. The review revealed important architectural decisions about error handling.

**Complete Workflow:**

1. **Code review completes:**
   ```
   User: /review this PR
   Claude: [Runs requesting-code-review skill]
   - Reviews code against acceptance criteria
   - Identifies architectural patterns
   - Approves implementation
   - Review complete: All acceptance criteria met
   ```

2. **Automatic memory trigger fires:**
   - Skill detects review completion
   - Identifies component: "Git Worktrees Integration"
   - Prepares entity update with review findings

3. **What user sees:**
   ```
   Code review complete. All acceptance criteria met.

   Updating memory with review findings...
   Updated [[Git Worktrees Integration]] with code review insights.
   ```

4. **Entity update (behind the scenes):**
   ```markdown
   ---
   type: entity
   project: tabula-scripta
   tags: [git-worktrees, parallel-execution, architecture]
   created: 2025-11-14
   updated: 2025-11-15  # Updated by code review
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Git Worktrees Integration

   ## Recent Changes

   ### 2025-11-15 - Code Review Findings

   Reviewed implementation of worktree cleanup logic.

   **Decision:** Use trap handlers for cleanup on failure
   **Rationale:** Ensures cleanup even if subagent crashes mid-execution
   **Implementation:** Added `trap 'cleanup_worktree' EXIT ERR INT TERM`
   **Impact:** More robust failure handling, prevents orphaned worktrees

   **Code Pattern:**
   ```bash
   cleanup_worktree() {
     rm -rf "$WORKTREE_PATH"
   }
   trap 'cleanup_worktree' EXIT ERR INT TERM
   ```

   **Related:** [[Error Handling Patterns]], [[Parallel Execution]]
   ```

5. **Session note updated (context tracking):**
   ```markdown
   ## Work Log

   ### 15:30 - Code Review Complete

   Reviewed worktree cleanup implementation. Key decision: trap handlers for robust cleanup.

   **Memory Updated:** [[Git Worktrees Integration]]
   ```

**Result:** Code review insights captured automatically, architectural decisions documented with rationale, knowledge available for future sessions.

**Trigger:** Automatic (no permission needed - review completion is objective)

---

### Integration: systematic-debugging

**When:** After root cause identified and fix verified

**Scenario:** You've spent 45 minutes debugging a race condition in parallel phase cleanup. Using the `systematic-debugging` skill, you identified the root cause and verified the fix.

**Complete Workflow:**

1. **Debugging session:**
   ```
   User: Tests are failing intermittently with "directory not empty"
   Claude: [Runs systematic-debugging skill]
   - Phase 1: Root cause investigation
     - Adds instrumentation to cleanup code
     - Identifies race condition with background processes
   - Phase 2: Pattern analysis
     - Recognizes common race condition pattern
     - Identifies similar issues in codebase
   - Phase 3: Hypothesis testing
     - Tests fix: Add `wait` before cleanup
     - Verifies fix: Tests pass consistently
   - Phase 4: Implementation
     - Applies fix to production code
     - All tests passing
   ```

2. **Automatic memory trigger fires:**
   - Skill detects debugging completion (fix verified)
   - Identifies component: "Parallel Execution Patterns"
   - Prepares troubleshooting pattern for entity

3. **What user sees:**
   ```
   Bug fixed and verified. All tests passing.

   Recording troubleshooting pattern...
   Updated [[Parallel Execution Patterns]] with debugging insights.
   ```

4. **Entity update (behind the scenes):**
   ```markdown
   ---
   type: entity
   project: tabula-scripta
   tags: [parallel-execution, debugging, race-conditions]
   created: 2025-11-14
   updated: 2025-11-15  # Updated by debugging
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Parallel Execution Patterns

   ## Gotchas & Troubleshooting

   ### Cleanup Race Condition

   **Symptom:** Worktree cleanup fails intermittently with "directory not empty"
   **Root Cause:** Cleanup runs before background processes finish writing files
   **Solution:** Add `wait` before cleanup to ensure all processes complete
   **Tags:** #debugging #race-condition #parallel-execution

   **Code:**
   ```bash
   # Wait for all background processes
   wait
   # Then cleanup
   rm -rf worktree
   ```

   **Detection:** Non-deterministic failures, works sometimes, fails others
   **Prevention:** Always wait for async operations before cleanup

   **Debugging Session:** 2025-11-15, 45 minutes, systematic-debugging skill

   **Related:** [[Race Condition Debugging]], [[Error Handling]]
   ```

5. **Session note updated (debugging story):**
   ```markdown
   ## Work Log

   ### 14:30 - Race Condition Investigation

   Seeing intermittent failures in parallel phase cleanup. Error: "directory not empty".

   Tried:
   - Adding sleep (didn't work - timing-dependent)
   - Checking for file locks (not the issue)
   - Reviewing cleanup order (found it!)

   **Solution:** Add `wait` before cleanup. Tests now passing consistently.

   **Memory Updated:** [[Parallel Execution Patterns]]
   ```

**Result:** Troubleshooting pattern captured with symptom keywords for search, fix documented with rationale, debugging time saved for future similar issues.

**Trigger:** Automatic (no permission needed - debugging completion is objective)

---

### Integration: brainstorming

**When:** After architectural decision finalized and ready for implementation

**Scenario:** You've used the `brainstorming` skill to refine the memory granularity design. After exploring alternatives, you've decided on a three-layer system (session/entity/topic) and are ready to implement.

**Complete Workflow:**

1. **Brainstorming session:**
   ```
   User: /brainstorm How should we structure the memory system?
   Claude: [Runs brainstorming skill]
   - Question 1: What granularity levels do we need?
     - Option A: Single-level (all notes equal)
     - Option B: Two-level (temporal + persistent)
     - Option C: Three-level (temporal + persistent + organizational)
     - User chooses: C
   - Question 2: How should knowledge flow between levels?
     - Option A: Manual promotion
     - Option B: Automatic compaction
     - Option C: Hybrid (auto + manual)
     - User chooses: B
   - Question 3: What triggers compaction?
     - Explores: Size threshold, age threshold, hybrid
     - User approves: 500 lines OR 3 days
   - Design finalized, ready for implementation
   ```

2. **Automatic memory trigger fires:**
   - Skill detects design completion
   - Identifies architectural decision: "Memory Granularity"
   - Prepares entity with decision rationale

3. **What user sees:**
   ```
   Design finalized. Ready to implement three-layer memory system.

   Recording architectural decision...
   Created [[Memory Granularity]] entity.
   ```

4. **Entity creation (behind the scenes):**
   ```markdown
   ---
   type: entity
   project: tabula-scripta
   tags: [architecture, memory-system, design-decision]
   created: 2025-11-15
   updated: 2025-11-15
   status: active
   claude_last_accessed: 2025-11-15
   cross_project_recalls: []
   ---

   # Memory Granularity

   ## Overview

   Three-layer memory system for Claude Code working memory, balancing quick capture with long-term knowledge retention.

   ## Key Decisions

   ### 2025-11-15 - Three-Layer Architecture

   **Decision:** Implement three-layer memory system
   - **Layers:** Session notes (temporal), Entity notes (persistent), Topic notes (organizational)
   - **Flow:** Session → Entity (compaction) → Topic (clustering)

   **Alternatives Considered:**
   - **Single-level:** Rejected - no distinction between temporal and persistent knowledge
   - **Two-level:** Rejected - missing organizational layer for knowledge clustering

   **Rationale:**
   - Temporal layer: Captures context quickly during active work
   - Persistent layer: Distills knowledge into reusable components
   - Organizational layer: Clusters related entities into conceptual maps

   **Expected Impact:**
   - Faster session notes (no need to organize during work)
   - Better long-term retention (structured entities)
   - Easier knowledge discovery (topic maps)

   **Implementation Details:**
   - **Compaction Threshold:** 500 lines OR 3 days old
   - **Compaction Trigger:** Automatic at session end
   - **Promotion Trigger:** 3 cross-project recalls

   **Related:** [[Session Compaction]], [[Entity Notes]], [[Topic Notes]]
   ```

5. **Session note updated (design context):**
   ```markdown
   ## Decisions Made

   - **Memory Granularity:** Three-layer system (session/entity/topic)
   - **Rationale:** Balances quick capture with long-term retention
   - **Alternatives:** Rejected single-level and two-level designs

   **Memory Created:** [[Memory Granularity]]
   ```

**Result:** Architectural decision documented with full context, alternatives recorded with rejection rationale, implementation plan ready for execution.

**Trigger:** Automatic (no permission needed - design finalized is objective)

---

## Conflict Resolution Examples

### Example 1: Clean Update (No Conflict)

**Scenario:** Claude wants to update an entity, no human edits since last load.

**Flow:**

1. **Load entity at T1 (2025-11-16 14:00):**
   ```yaml
   updated: 2025-11-16
   claude_last_accessed: 2025-11-16
   ```

2. **Work happens, Claude prepares update at T2 (2025-11-17 10:00)**

3. **Reload entity to check timestamps:**
   ```yaml
   updated: 2025-11-16  # Still same, no human edits
   claude_last_accessed: 2025-11-16
   ```

4. **Conflict check:** T2 updated (2025-11-16) == T1 loaded (2025-11-16) → No conflict

5. **Apply patch:**
   - Append new content to relevant sections
   - Update frontmatter:
   ```yaml
   updated: 2025-11-17
   claude_last_accessed: 2025-11-17
   ```

6. **Write via MCP update_note**

**Result:** Clean update, no conflicts, content preserved.

---

### Example 2: Human Edit Conflict (Show Diff, Merge)

**Scenario:** Claude loaded entity at T1, human edited at T2, Claude wants to update at T3.

**Flow:**

1. **Claude loads at T1 (2025-11-16 14:00):**
   ```yaml
   updated: 2025-11-16
   claude_last_accessed: 2025-11-16
   ```

2. **Human edits at T2 (2025-11-17 09:00):**
   - User adds new section in Obsidian: "## Performance Considerations"
   - Frontmatter updated:
   ```yaml
   updated: 2025-11-17
   ```

3. **Claude prepares update at T3 (2025-11-17 10:00):**
   - Wants to add to "## Gotchas & Troubleshooting"

4. **Reload entity to check timestamps:**
   ```yaml
   updated: 2025-11-17  # Changed! Human edit detected
   claude_last_accessed: 2025-11-16  # Claude last saw older version
   ```

5. **Conflict detected:** T3 updated (2025-11-17) > T1 loaded (2025-11-16) → Conflict!

6. **Show user the conflict:**
   ```
   I want to update [[Git Worktrees]] but you've edited it since I loaded it.

   Your changes (at 2025-11-17):
   ───────────────────────────────
   + ## Performance Considerations
   +
   + Worktree creation is fast (<100ms) but cleanup can be slow for large
   + directories. Consider using parallel cleanup for multiple worktrees.

   My changes (at 2025-11-17 10:00):
   ───────────────────────────────
   Adding to "## Gotchas & Troubleshooting":

   + ### Cleanup Race Condition
   +
   + **Symptom:** Cleanup fails with "directory not empty"
   + **Solution:** Wait for background processes before cleanup

   Options:
   1. Show me both diffs and I'll merge manually
   2. Abort your update (keep my changes only)
   3. Create new section '## Claude's Updates (conflicted)'
   4. Let's discuss and resolve together

   What should I do?
   ```

7. **User chooses Option 1 (manual merge):**
   - Claude shows full content with both changes highlighted
   - User merges in Obsidian
   - Confirms merge complete

8. **Claude reloads and verifies merge**

**Result:** Both changes preserved, no data loss, transparent resolution.

---

### Example 3: Major Rewrite Conflict (Abort, Discuss)

**Scenario:** Claude's understanding contradicts existing note fundamentally.

**Flow:**

1. **Existing entity says:**
   ```markdown
   ## Architecture

   The memory system uses a two-tier structure: session notes and global entities.
   ```

2. **Claude's new understanding:**
   - After further design work: "Actually, we need three tiers (session/entity/topic)"

3. **Contradiction detected:**
   - Claude recognizes fundamental conflict with existing note

4. **Ask user before overwriting:**
   ```
   My understanding of [[Memory System Architecture]] changed significantly.

   Current note says:
   ───────────────────
   "The memory system uses a two-tier structure: session notes and global entities."

   But I now think:
   ───────────────────
   "The memory system uses a three-tier structure: session notes (temporal),
   entity notes (persistent), and topic notes (organizational)."

   Options:
   1. Create new entity note with alternative understanding
   2. Update existing note (I'll show you the full diff first)
   3. Let's discuss the contradiction - maybe both are valid

   What should I do?
   ```

5. **User chooses Option 2 (update with diff):**
   - Claude shows full diff of proposed changes
   - User reviews and approves
   - Claude applies update

**Result:** Major conceptual shift handled transparently, user maintains control.

---

## Frontmatter Examples

### Session Note Frontmatter

```yaml
---
type: session
project: tabula-scripta
tags: [session, work-in-progress, memory-system]
created: 2025-11-15
updated: 2025-11-15
status: active
claude_last_accessed: 2025-11-15
cross_project_recalls: []
---
```

**Fields explained:**
- `type`: Always "session" for session notes
- `project`: Detected from git repo or working directory
- `tags`: Session-specific tags (always includes "session")
- `created`: When session note was first created (never changes)
- `updated`: Last time note was modified (by human or Claude)
- `status`: "active" during work, "archived" after compaction
- `claude_last_accessed`: Last time Claude loaded this note
- `cross_project_recalls`: Always empty for session notes (project-scoped)

---

### Entity Note Frontmatter

```yaml
---
type: entity
project: tabula-scripta
tags: [entity, architecture, git-worktrees, parallel-execution]
created: 2025-11-14
updated: 2025-11-17
status: active
claude_last_accessed: 2025-11-17
cross_project_recalls:
  - project: another-tool
    date: 2025-11-16
    context: "Recalled via search: 'isolation patterns'"
  - project: web-app
    date: 2025-11-17
    context: "Session start recall"
---
```

**Fields explained:**
- `type`: Always "entity" for entity notes
- `project`: Project name or "global" for global entities
- `tags`: Descriptive tags for Dataview queries and search
- `created`: When entity was first created (never changes)
- `updated`: Last modification time (conflict detection key)
- `status`: "active" (in use), "archived" (obsolete but preserved), "draft" (incomplete)
- `claude_last_accessed`: Tracks when Claude last loaded (conflict detection)
- `cross_project_recalls`: Tracks cross-project usage for promotion

---

### Topic Note Frontmatter

```yaml
---
type: topic
project: global
tags: [topic, moc, patterns, architecture]
created: 2025-11-15
updated: 2025-11-17
status: active
claude_last_accessed: 2025-11-17
cross_project_recalls: []
---
```

**Fields explained:**
- `type`: Always "topic" for topic notes (Maps of Content)
- `project`: Always "global" (topic notes are never project-scoped)
- `tags`: Always includes "topic" and "moc"
- `created`: When topic note was created
- `updated`: Last modification time
- `status`: Typically "active" (topic notes rarely archived)
- `claude_last_accessed`: When Claude last referenced this topic
- `cross_project_recalls`: Always empty (topic notes are inherently global)

---

### Cross-Project Recall Tracking

**Example: Entity recalled 3 times from different projects**

```yaml
---
type: entity
project: tabula-scripta
tags: [entity, git-worktrees, isolation]
created: 2025-11-14
updated: 2025-11-17
status: active
claude_last_accessed: 2025-11-17
cross_project_recalls:
  - project: another-tool
    date: 2025-11-16
    context: "Recalled via search: 'isolation patterns'"
  - project: web-app
    date: 2025-11-17
    context: "Recalled via search: 'parallel tasks'"
  - project: cli-tool
    date: 2025-11-17
    context: "Session start recall"
---
```

**Promotion logic:**
- At 3 cross-project recalls (threshold met)
- Trigger promotion prompt
- Ask user to promote to global
- If approved: Move to `claude/global/entities/`, update `project: global`

---

## Troubleshooting Section

### Issue: MCP Connection Issues

**Symptom:** Errors like `MCPUnavailableError`, "Cannot connect to Obsidian MCP server"

**Diagnosis:**
1. Check if Obsidian is running
2. Verify obsidian-mcp-plugin is installed in `~/.claude-memory/` vault
3. Check Claude Code config includes MCP server in `.claude/config.json` or `.claude/mcp.json`
4. Test MCP connection with simple operation (read a known note)

**Solution:**

1. **Ensure Obsidian is running:**
   ```bash
   # macOS: Check if Obsidian is in running processes
   ps aux | grep -i obsidian
   ```

2. **Install obsidian-mcp-plugin if missing:**
   - Open Obsidian
   - Go to Settings > Community Plugins
   - Search for "MCP Plugin" by aaronsb
   - Install and enable

3. **Verify Claude Code MCP config:**
   ```json
   {
     "mcpServers": {
       "obsidian": {
         "command": "obsidian-mcp",
         "args": ["~/.claude-memory"]
       }
     }
   }
   ```

4. **Test connection:**
   - Try `/recall test` to search for any note
   - If successful: MCP is working
   - If fails: Check plugin logs in Obsidian

**Reference:** See `docs/setup-guide.md` for full setup instructions

---

### Issue: Vault Not Found

**Symptom:** Error "Vault path not found: ~/.claude-memory/"

**Diagnosis:**
1. Check if vault directory exists
2. Verify path is correct in MCP config
3. Check file permissions

**Solution:**

1. **Create vault directory if missing:**
   ```bash
   mkdir -p ~/.claude-memory/claude/projects
   mkdir -p ~/.claude-memory/claude/global/entities
   mkdir -p ~/.claude-memory/claude/global/topics
   ```

2. **Initialize as Obsidian vault:**
   - Open Obsidian
   - File > Open Folder as Vault
   - Select `~/.claude-memory/`
   - Vault initialized

3. **Verify permissions:**
   ```bash
   ls -la ~/.claude-memory/
   # Should be readable/writable by your user
   ```

4. **Test vault access:**
   ```bash
   # Try creating a test note
   /remember entity Test Note
   # Check if it appears in Obsidian
   ```

**Prevention:** Follow setup instructions in `docs/setup-guide.md` to initialize vault structure

---

### Issue: Conflict Resolution Stuck

**Symptom:** Repeated conflict warnings, unable to update note, "I keep detecting conflicts"

**Diagnosis:**
1. Check if multiple Claude sessions are running
2. Check if Obsidian sync is causing timestamp changes
3. Review `claude_last_accessed` vs `updated` timestamps
4. Check for filesystem events (Dropbox, iCloud sync)

**Solution:**

1. **Close other Claude sessions:**
   - Only one Claude session should write to memory at a time
   - Coordinate if running multiple sessions

2. **Disable Obsidian sync temporarily:**
   - If using Obsidian Sync, pause during active Claude session
   - Resume sync after session ends

3. **Check timestamps manually:**
   ```bash
   # View frontmatter of conflicted note
   head -20 ~/.claude-memory/claude/projects/myproject/entities/MyEntity.md
   ```
   - If `updated` and `claude_last_accessed` are very close (seconds apart): False positive
   - If far apart (hours/days): Real conflict

4. **Reset conflict tracking:**
   - If false positive persists, manually update `claude_last_accessed` to match `updated`
   - Claude will recognize no real conflict on next update

**Prevention:**
- Use single Claude session per project
- Pause file sync services during active sessions
- Review conflicts carefully (may be real!)

---

### Issue: Memory Spam (Too Many Writes)

**Symptom:** Vault cluttered with many small updates, >5 writes per hour, notifications overwhelming

**Diagnosis:**
1. Count memory write operations in session
2. Review what triggered each write
3. Check if triggers are too aggressive
4. Review session duration vs write count

**Solution:**

1. **Review write count:**
   ```
   Session duration: 2 hours
   Memory writes: 15
   Rate: 7.5 writes/hour (exceeds limit of 5/hour)
   ```

2. **Identify aggressive triggers:**
   - Are checkpoints too frequent? (Reduce from 30min to 60min)
   - Are minor decisions triggering writes? (Batch related updates)
   - Are automatic triggers firing when ask-first would be better?

3. **Batch related updates:**
   - Instead of writing after each decision, collect 3-5 decisions
   - Write once with all updates batched
   - Example:
   ```
   Before: Write after each of 5 decisions = 5 writes
   After: Collect 5 decisions, write once = 1 write
   ```

4. **Adjust trigger sensitivity:**
   - Ask Claude: "Reduce memory write frequency?"
   - Claude adjusts automatic triggers to be more selective
   - Focus on significant decisions only

5. **Use session notes more, entity notes less:**
   - During active work: Write to session note frequently (it's temporal)
   - At session end: Extract key knowledge into entities (1-2 writes)
   - Reduces entity churn

**Prevention:**
- Set clear write limits at session start
- Use session notes as scratchpad during work
- Compact session into entities at end (not during)
- Ask permission for subjective content (slows down trigger rate)

**Target:** <5 writes per hour-long session for entity/topic notes

---

### Issue: Session Compaction Failures

**Symptom:** Errors like "Compaction failed", "Session preserved", session status marked as "compaction_failed"

**Diagnosis:**
1. Check if MCP connection is available
2. Verify entity notes can be read and updated
3. Check for file permission issues in archive directory
4. Review session note for parsing errors
5. Check for disk space issues

**Solution:**

1. **Check MCP connection status:**
   ```bash
   # Verify Obsidian is running
   ps aux | grep -i obsidian

   # Check MCP plugin is enabled in Obsidian
   # Settings > Community Plugins > MCP Plugin
   ```

2. **Check entity note conflicts:**
   - Review error message for conflicted entity names
   - Manually resolve timestamp conflicts if needed
   - Check if entity notes are locked or in use by another process

3. **Verify archive directory permissions:**
   ```bash
   # Check if archive directory exists and is writable
   ls -la ~/.claude-memory/claude/projects/{project}/archive/sessions/

   # Create if missing
   mkdir -p ~/.claude-memory/claude/projects/{project}/archive/sessions/

   # Fix permissions if needed
   chmod 755 ~/.claude-memory/claude/projects/{project}/archive/
   ```

4. **Manual compaction recovery:**
   - Load the session note (status: compaction_failed)
   - Manually extract key knowledge into entity notes
   - Archive session note manually:
     ```bash
     # Move session to archive
     mv ~/.claude-memory/claude/projects/{project}/sessions/{session}.md \
        ~/.claude-memory/claude/projects/{project}/archive/sessions/{session}.md
     ```
   - Update session frontmatter: `status: archived`

5. **Check session note parsing:**
   - Open session note in Obsidian
   - Verify frontmatter is valid YAML (no syntax errors)
   - Check for malformed markdown (unclosed code blocks, etc.)
   - Fix any parsing issues and retry compaction

**Prevention:**
- Keep MCP connection stable during sessions
- Avoid editing entity notes during active compaction
- Monitor disk space (compaction creates temporary copies)
- Use valid YAML frontmatter syntax
- Test compaction with small sessions first

**Recovery Process:**
```
1. Identify failed session: Search for status: compaction_failed
2. Review error message in frontmatter.error field
3. Fix underlying issue (MCP, permissions, conflicts)
4. Manually compact or trigger retry
5. Verify session archived successfully
6. Update status to archived
```

---

## Summary

This guide demonstrates the practical application of the tabula-scripta working memory system through four key pattern categories:

1. **Memory Flow Patterns:** How information transitions from session notes to entities to topics
2. **Skill Integration Patterns:** How memory management integrates with superpowers workflows
3. **Conflict Resolution Patterns:** How to handle concurrent edits safely and transparently
4. **Troubleshooting Patterns:** Common issues and proven solutions

**Key Principles:**
- Start temporal (session notes), distill to persistent (entities), organize conceptually (topics)
- Let automatic triggers handle routine memory writes, ask permission for subjective content
- Always check timestamps before updating (human edits win)
- Track cross-project recalls, promote patterns at threshold
- Batch updates to prevent memory spam (<5 writes/hour)

**Next Steps:**
- Review `skills/managing-working-memory.md` for detailed skill documentation
- See `docs/setup-guide.md` for MCP configuration
- Try the patterns in your next session
- Refine memory management based on your workflows
