# Tabula Scripta: Working Memory System Design

**Date:** 2025-11-17
**Status:** Design complete, ready for implementation
**Purpose:** Enable Claude to maintain proactive, updateable working memory using Obsidian as the backend

---

## Problem Statement

### Current Pain Points

1. **Context loss between sessions** - Episodic-memory requires manual search; Claude doesn't proactively recall relevant context
2. **No living memory** - Current systems are either write-only (journals) or read-only (episodic search)
3. **Decisions/rationale disappear** - Important architectural decisions and debugging insights get lost in conversation history
4. **No memory updates** - Can only append new memories, not evolve understanding as context changes

### What We Need

- **Proactive recall**: Claude loads relevant memories at session start automatically
- **Living memory**: Update notes as understanding evolves during sessions
- **Autonomous management**: Claude decides what to remember and when (not just user-directed)
- **Human-curated fallback**: Notes are human-readable/editable in Obsidian
- **Multi-pattern support**: Support topic-based, entity-based, and temporal organization simultaneously

---

## Core Design Principles

### Automatic with Selective Asking (B with lite C)

**Claude manages memory automatically:**
- Writes memories when decisions are made, architectures chosen, bugs diagnosed
- Updates entities as understanding evolves
- Compacts session notes into permanent memory
- Skill-driven triggers determine when to remember

**Claude asks permission for subjective content:**
- User preferences (coding style, tool choices)
- Project-specific conventions
- Anything that feels like "opinion" vs "fact"
- Contradictions to existing entity notes (show diff, ask to merge)

### Human-Readable Backend: Obsidian

**Why Obsidian:**
- Markdown files are version-controllable and portable
- Rich linking via `[[wikilinks]]` and `#tags`
- User can browse/edit/curate in familiar UI
- Graph view for knowledge exploration
- Plugin ecosystem for semantic search (Smart Connections, Omnisearch)
- Dataview queries for structured retrieval

**Integration:**
- Use existing Obsidian vault (not separate vault per project)
- Namespace under `claude/` folder to prevent pollution
- Notes integrate with user's personal knowledge graph
- User can reorganize/promote notes out of `claude/` namespace

---

## Architecture

### Three-Layer Memory Granularity

#### 1. Session Notes (temporal, ephemeral)

**Purpose:** Updateable scratchpad for current thinking

**Location:** `claude/projects/{project}/sessions/{date}-{topic}.md`

**Content:**
- Stream of consciousness during work
- Decisions made and why
- Approaches tried and failed
- Open questions
- Context for resuming later

**Lifecycle:**
- Created at session start or when new topic begins
- Updated continuously during session
- Compacted into entity notes at session end or when exceeding threshold (500 lines or 3 days old)
- Archived after compaction (not deleted - useful for reference)

**Example:**
```
claude/projects/spectacular/sessions/2025-11-17-memory-design.md
```

#### 2. Entity Notes (persistent, specific)

**Purpose:** One note per concept/component/pattern

**Location:**
- Project-specific: `claude/projects/{project}/entities/{Entity Name}.md`
- Cross-project: `claude/global/entities/{Entity Name}.md`

**Content:**
- Purpose/overview
- Architecture/structure
- Key decisions and rationale
- Gotchas and troubleshooting
- Related entities (backlinks)
- Recent changes log

**Lifecycle:**
- Created when new concept/component encountered
- Updated when understanding evolves (patch operations, not full rewrites)
- Linked via `[[wikilinks]]` to form knowledge graph
- Never deleted (archive if obsolete)

**Example:**
```
claude/projects/spectacular/entities/Execute Command.md
claude/projects/spectacular/entities/Git Worktrees.md
claude/global/entities/TDD Patterns.md
```

#### 3. Index Notes (persistent, organizational)

**Purpose:** Topic clusters and Maps of Content (MOC)

**Location:** `claude/global/topics/{Topic Name}.md`

**Content:**
- Links to related entities
- Conceptual frameworks
- Best practices
- Curated organization of related knowledge

**Lifecycle:**
- Created when pattern emerges across multiple entities
- Human-curated over time (Claude suggests, user organizes)
- Acts as entry point for topic exploration

**Example:**
```
claude/global/topics/Testing Strategies.md
claude/global/topics/Parallel Execution.md
```

### Vault Structure

**Obsidian-native approach: Namespace within existing vault**

```
~/your-vault/                      # User's existing Obsidian vault
  claude/                          # Top-level namespace for Claude memory
    projects/
      spectacular/
        sessions/
          2025-11-17-memory-design.md
          2025-11-18-execute-refactor.md
        entities/
          Execute Command.md
          Git Worktrees.md
          Parallel Phase Orchestration.md
        _index.md                  # Project MOC
      other-project/
        sessions/
        entities/
        _index.md
    global/                        # Cross-project knowledge
      entities/
        TDD Patterns.md
        React Server Actions.md
        Debugging Race Conditions.md
      topics/
        Testing Strategies.md
        Parallel Execution.md
        Git Workflows.md
    _index.md                      # Claude memory MOC

  # User's own notes (can link to Claude notes)
  daily/
  projects/
  reference/
```

**Why this structure:**
- Integrates with existing vault graph (user can link `[[Git Worktrees]]` from their own notes)
- User can browse/edit in normal Obsidian workflow
- Dataview queries can span both Claude and user notes
- Namespace `claude/` prevents pollution but enables discovery
- User can reorganize/promote notes out of `claude/` namespace
- Fallback: If user doesn't have vault, create `~/.claude-memory/` vault (designed to be mergeable later)

### Frontmatter Schema

**Every note includes metadata:**

```yaml
---
type: entity|session|topic
project: spectacular|global
tags: [debugging, patterns, architecture]
created: 2025-11-17
updated: 2025-11-17
status: active|archived|draft
claude_last_accessed: 2025-11-17
---
```

**Usage:**
- Dataview queries filter by type/project/tags
- Track staleness via `updated` timestamp
- Detect human edits via `updated` vs `claude_last_accessed`
- Status enables archival without deletion

---

## Write Strategy: When Claude Remembers

### Automatic Triggers (no permission needed)

**After code review completes:**
- Update project entity note for reviewed component
- Record architectural decisions in entity note
- Link to related entities

**After debugging session:**
- Update troubleshooting patterns (project or global entity)
- Record root cause and fix
- Tag with symptom keywords for future search

**After architectural decision:**
- Create or update entity note with rationale
- Record alternatives considered
- Link to related architectural entities

**After discovering reusable pattern:**
- Update topic note or create new entity
- Link to examples from current project

**Periodic checkpoints during long sessions:**
- Update session note with current context
- Checkpoint every 30-60 minutes or after major milestones

**End of session:**
- Final session note update
- Compact session note into entity notes if threshold exceeded
- Archive session note

### Ask-First Triggers (subjective content)

**User states preference:**
- "I prefer X over Y for Z reason"
- Confirm before recording: "Should I remember this preference?"

**Contradicts existing entity note:**
- Show diff between current understanding and new information
- Ask: "Update? Create alternative? Discuss?"

**Creating new global entity:**
- Ask: "This seems reusable across projects. Create global entity?"

**Large-scale reorganization:**
- Ask: "I want to split this entity into 3 separate notes. Proceed?"

### Implementation: Skill + Hook System

**Skill: `managing-working-memory`**

Defines:
- When to write (trigger conditions)
- What to write (content templates)
- How to organize (session → entity → topic flow)
- Conflict resolution steps
- TodoWrite checklists for memory checkpoints

**Hook integration points:**

1. **SessionStart hook** - Proactive recall (see Read Strategy below)
2. **SessionEnd hook** - Compaction and archival
3. **Skill-specific hooks** - Memory checkpoints in superpowers skills:
   - `requesting-code-review` → update component entity after review
   - `systematic-debugging` → record troubleshooting pattern
   - `finishing-a-development-branch` → update project context

---

## Read Strategy: When Claude Recalls

### Session Start (automatic, proactive)

**When:** Claude Code session begins in a project

**Process:**

1. **Detect project context** (from git repo, working directory path)
2. **Graph query:** Load project index + entities linked to project
3. **Dataview query:** Get last 3 session notes for this project
4. **Semantic search (if available):** "Notes related to [project name]"
5. **Present summary:** "I remember we were working on X, decided Y because Z. Anything else I should recall?"

**Implementation:** SessionStart hook triggers memory load

**Visibility:** Summary mode - show what was recalled, don't spam details

**Example output:**
```
I remember from our last session:
- Working on parallel execution improvements in spectacular
- Decided to use git worktrees for isolation (see [[Git Worktrees]])
- Open question: How to handle cleanup when subagent fails?

Should I load anything else?
```

### During Session (on-demand, contextual)

**When encountering unknown term/component:**
- Search entity notes via graph or text search
- If found → load silently into context
- If not found → ask "Should I remember this as a new entity?"

**When making architectural decision:**
- Query topic notes tagged `#architecture` or `#patterns`
- Load similar past decisions via semantic search
- Reference them in current reasoning
- Example: "I recall we used similar pattern in [[React Server Actions]]"

**When debugging:**
- Query notes tagged `#debugging` or `#troubleshooting`
- Load patterns matching error symptoms
- Semantic search: "race condition debugging strategies"
- Apply past learnings to current problem

**When user asks about past work:**
- "What did we decide about X?"
- Graph search for entity, load full context
- Reference specific sections via block links

### Query Strategy: Hybrid Search

**Use Obsidian MCP Plugin (aaronsb) for:**
- **Graph queries:** "Find all entities linked to `[[Spectacular]]`"
- **Dataview queries:** "All decisions tagged `#architecture` in last 30 days"
- **Path finding:** "How are `[[Git Worktrees]]` and `[[Parallel Execution]]` connected?"
- **Backlink analysis:** "What references this entity?"

**Use Smart Connections Plugin (if available) for:**
- **Semantic search:** "Find notes similar to 'debugging race conditions'"
- **Embedding-based similarity:** Fuzzy matching without exact keywords
- **Auto-suggestions:** Related notes based on current context

**Fallback (no semantic plugin):**
- Simple text search via Obsidian MCP
- Good enough for v1, semantic search is enhancement

---

## Update Strategy: Handling Conflicts

### Update vs Create Decision Tree

**When to update existing entity note:**
- Entity already exists (check via graph or title search)
- Understanding evolved (not contradicted)
- Adding new context, links, or recent changes
- **Action:** Patch operation (insert under headings, don't rewrite)

**When to create new entity note:**
- New concept/component encountered (doesn't exist in graph)
- Alternative approach to existing pattern (complement, not replace)
- Session note for new work session (always create fresh)

**When to ask user:**
- Understanding contradicts existing entity note (show diff)
- Major rewrite needed (not just additive update)
- Unsure if knowledge is project-specific or global

### Conflict Resolution Flow

**Case 1: Clean update (no conflict)**

1. Claude loads entity note at session start (timestamp: T1)
2. During session, understanding evolves
3. At checkpoint, Claude patches note (insert under `## Recent Changes`)
4. User reviews later via Obsidian

**Case 2: Human edited since load (conflict detected)**

1. Claude loaded version A at session start (timestamp: T1)
2. Human edited to version B during session (timestamp: T2)
3. Claude tries to patch at checkpoint
4. System detects conflict: `updated > claude_last_accessed`
5. **Ask user:** "I want to update `[[Git Worktrees]]` but you've edited it since I loaded it. Options:"
   - Show diff and merge manually
   - Abort my update
   - Create new section `## Claude's Updates (conflicted)`
   - Discuss and resolve together

**Case 3: Major rewrite needed (understanding changed)**

1. Claude's understanding contradicts existing note fundamentally
2. Don't silently overwrite user's knowledge
3. **Ask user:** "My understanding of X changed significantly. Current note says Y, but I now think Z. Options:"
   - Create new entity note with alternative understanding
   - Update existing note (I'll show you the diff first)
   - Let's discuss the contradiction

**Implementation:**
- Track `updated` timestamp in frontmatter when loading note
- Before patch, check if `updated` changed (indicates human or other Claude session edited)
- If changed → trigger conflict resolution flow
- Always preserve human edits (user knowledge wins over Claude)

---

## Implementation Roadmap

### Phase 1: Foundation (MVP)

**Goal:** Basic read/write with manual triggers

**Components:**

1. **Obsidian MCP Integration**
   - Use aaronsb's mcp-obsidian plugin directly
   - Configure for user's existing vault or create new vault
   - Test graph queries, Dataview, basic CRUD operations

2. **Skill: `managing-working-memory`**
   - Define write triggers (automatic vs ask-first)
   - Define content templates (session/entity/topic note structures)
   - Define TodoWrite checklists for memory checkpoints
   - Document conflict resolution steps

3. **Manual memory commands**
   - `/remember [type] [title]` - Create new memory note
   - `/recall [query]` - Search existing memories
   - `/update-memory [title]` - Update existing note
   - Validates skill patterns before automation

4. **Basic session notes**
   - Create session note at start of work
   - Manual updates during session
   - Manual compaction at end

**Success criteria:**
- Can create/read/update notes via skill
- Notes appear correctly in Obsidian vault
- Graph links and tags work
- Conflict detection works

### Phase 2: Proactive Recall

**Goal:** Automatic memory loading at session start

**Components:**

1. **SessionStart hook**
   - Detect project context from git/directory
   - Query vault for relevant memories (graph + Dataview)
   - Load last N session notes for project
   - Present summary to user

2. **Semantic search integration**
   - Test Smart Connections plugin in Obsidian
   - If available: Use for fuzzy recall queries
   - If not: Fallback to text search (good enough for v2)

3. **On-demand recall during session**
   - When encountering unknown term → search entities
   - When debugging → query troubleshooting notes
   - When making decision → query similar past decisions

**Success criteria:**
- Claude remembers context from last session automatically
- Relevant entities loaded without asking
- User can override/supplement recalled context

### Phase 3: Autonomous Memory Management

**Goal:** Automatic writing and compaction

**Components:**

1. **Skill-driven write triggers**
   - Hook into `requesting-code-review` skill → update component entity
   - Hook into `systematic-debugging` skill → record troubleshooting pattern
   - Hook into `finishing-a-development-branch` skill → update project context
   - Periodic checkpoints during long sessions → update session note

2. **SessionEnd hook**
   - Review session note
   - Identify entity notes to update
   - Compact decisions into structured notes
   - Ask about promoting to global entities
   - Archive session note

3. **Automatic entity creation**
   - Detect new concepts during session
   - Create entity notes with proper linking
   - Tag appropriately
   - Ask for global vs project classification

**Success criteria:**
- Claude writes memories without prompting
- Session notes compact automatically
- Entity notes stay updated
- User rarely needs to manually manage memory

### Phase 4: Advanced Features (Future)

**Goal:** Smart organization and curation

**Components:**

1. **Memory summarization**
   - Weekly/monthly rollups of key learnings
   - Topic note suggestions based on entity clustering
   - Stale memory detection and archival

2. **Cross-session learning**
   - Pattern extraction across projects
   - Suggest promoting project patterns to global entities
   - Identify contradictions in knowledge graph

3. **User memory integration**
   - Detect when user's own notes relate to Claude memories
   - Suggest backlinks between user notes and Claude notes
   - Enable user to "teach" Claude via their own notes

4. **Quality improvements**
   - Better conflict resolution (3-way merge UI)
   - Memory deduplication (detect redundant entities)
   - Graph-based memory retrieval (path-finding for complex queries)

---

## Design Decisions

### 1. Memory Loading Visibility: Summary Mode

**Decision:** Show 1-3 sentence summary of recalled context at session start

**Rationale:** Transparency without noise. User knows what Claude remembered and can request details or corrections.

**Implementation:**
- Load memories silently into context
- Display concise summary: "I recall X, Y, Z from our last session"
- User can ask "show me what you remember about X" for details
- Verbosity: Show highlights only (2-3 key entities + open questions), not full list

**Example:**
```
I remember from our last session:
- Working on parallel execution improvements in spectacular
- Decided to use git worktrees for isolation (see [[Git Worktrees]])
- Open question: How to handle cleanup when subagent fails?

Should I load anything else?
```

---

### 2. Session Note Lifecycle: Threshold-Based Compaction

**Decision:** Compact when note exceeds 500 lines OR 3 days old, whichever comes first

**Rationale:** Preserves WIP context for ongoing work while preventing permanent vault clutter

**Implementation:**
- Check thresholds at session end
- If exceeded: Compact session note into entity notes
- Archive session note (don't delete - useful for reference)
- Archive location: `claude/projects/{project}/archive/sessions/`
- User can manually compact earlier if desired

**Compaction process:**
1. Parse session note for decisions, entities, patterns
2. Update or create entity notes with extracted knowledge
3. Move session note to archive
4. Create backlink in entity notes to archived session (provenance)

---

### 3. Global vs Project Entity: Default Project, Promote Later

**Decision:** Always create entities in project scope initially, suggest promotion when pattern proves reusable

**Rationale:** Avoids premature generalization. Let usage patterns emerge naturally.

**Cross-Project Pattern Detection:**

When Claude is working in **project B** and loads a memory from **project A**, that's a signal the pattern might be reusable.

**Implementation - Recall-time detection:**

1. **Track cross-project recalls in frontmatter:**
```yaml
---
type: entity
project: spectacular
cross_project_recalls:
  - project: other-app
    date: 2025-11-17
    context: "Used worktree pattern for parallel tasks"
  - project: another-app
    date: 2025-11-18
    context: "Referenced for git-spice setup"
---
```

2. **When threshold reached (3 cross-project recalls):**
   - Claude detects: "I've referenced this pattern 3 times from other projects"
   - **Ask user:** "I keep using `[[Git Worktrees]]` from spectacular when working on other projects (3 times now). Should I promote this to global knowledge so it's easier to find?"
   - User options: promote now / remind me later / no, it's project-specific

3. **Automatic logging:**
   - When semantic search or graph query returns entity from different project than current session
   - Append to `cross_project_recalls` list
   - No user-visible noise until threshold

**Why this works:**
- Natural detection during normal work (not special analysis jobs)
- Context-aware (Claude knows WHY pattern was reused)
- Non-intrusive (only asks when pattern proves useful multiple times)
- Autonomous (Claude manages tracking, user just approves promotion)

**Promotion threshold:** 3 cross-project recalls = suggestion (tunable via user preference)

---

### 4. Semantic Search: Smart Connections Plugin

**Decision:** Support Smart Connections plugin as primary semantic search backend

**Rationale:** Most popular, actively maintained, free, easy to install. Provides local embeddings without API costs.

**Implementation:**
- Detect if Smart Connections is installed in user's vault
- If available: Use for semantic queries ("find notes similar to X")
- If not available: Fallback to text search via Obsidian MCP
- Don't block MVP on semantic search (nice-to-have, not required)
- Document installation instructions for users who want semantic features

**Configuration:**
- Check for Smart Connections plugin via MCP
- No auto-install (user choice)
- Graceful degradation if not present

---

## Success Metrics

**How do we know this is working?**

**Quantitative:**
- Session start recall rate: >80% of sessions load relevant context
- Memory write frequency: 3-5 memories per hour-long session
- Conflict rate: <5% of updates trigger conflicts
- Time to recall: <2 seconds for session start load

**Qualitative:**
- User stops manually explaining past context ("you remember when...")
- Claude references past decisions naturally during work
- User browses claude/ folder in Obsidian voluntarily
- Reduced repetition of already-learned patterns

**Anti-metrics (what to avoid):**
- Memory spam: Claude writing too frequently
- Recall irrelevance: Loading unrelated memories
- Edit conflicts: Constant human-Claude collisions
- Vault pollution: Too many low-quality notes

---

## Technical Stack

**Storage:**
- Obsidian vault (markdown files)
- Frontmatter YAML for metadata
- `[[wikilinks]]` for relationships
- `#tags` for categorization

**MCP Server:**
- **Primary:** aaronsb/obsidian-mcp-plugin
  - Graph queries
  - Dataview integration
  - CRUD operations
  - Path finding and backlink analysis

**Semantic Search (optional):**
- Smart Connections Obsidian plugin (if installed)
- Fallback to text search via MCP

**Claude Code Integration:**
- Skill: `managing-working-memory`
- Hooks: SessionStart, SessionEnd
- Integration points in superpowers skills

**Git Integration:**
- Vault itself can be git-tracked (user choice)
- Session notes can reference git commits/branches
- Memory notes can link to code via file paths

---

## References

**Related Projects:**
- episodic-memory: https://github.com/obra/episodic-memory
- private-journal-mcp: https://github.com/obra/private-journal-mcp
- obsidian-mcp-plugin: https://github.com/aaronsb/obsidian-mcp-plugin

**Obsidian Ecosystem:**
- Obsidian docs: https://docs.obsidian.md/Home
- Smart Connections: https://github.com/brianpetro/obsidian-smart-connections
- Dataview: https://blacksmithgu.github.io/obsidian-dataview/

**Knowledge Management Patterns:**
- Zettelkasten method (atomic notes, linking)
- PARA method (Projects, Areas, Resources, Archives)
- MOC (Maps of Content) pattern

---

## Next Steps

**Design decisions:** ✅ Complete

All critical questions resolved:
- Memory loading: Summary mode (1-3 sentence highlights)
- Session lifecycle: Threshold-based (500 lines OR 3 days)
- Global vs project: Default project, promote at 3 cross-project recalls
- Semantic search: Smart Connections with text search fallback

**Ready for implementation:**

1. **Set up tabula-scripta repo:**
   - Initialize as Claude Code plugin
   - Create plugin.json metadata
   - Define skill structure
   - Write CLAUDE.md and README.md

2. **Prototype vault structure:**
   - Create example notes (session, entity, topic)
   - Test Obsidian MCP plugin integration (aaronsb)
   - Validate graph queries and Dataview
   - Confirm frontmatter schema works

3. **Write skill: managing-working-memory:**
   - Use superpowers TDD approach
   - Define trigger conditions precisely
   - Create content templates (session/entity/topic)
   - Write conflict resolution flows
   - Add TodoWrite checklists

4. **Implement Phase 1 (MVP):**
   - Manual memory commands (`/remember`, `/recall`, `/update-memory`)
   - Basic session note creation and updates
   - Conflict detection (human edit tracking)
   - Validate skill patterns before automation

**Target:** Phase 1 complete within 1-2 sessions

---

**Document Status:** ✅ Design complete, ready for implementation
