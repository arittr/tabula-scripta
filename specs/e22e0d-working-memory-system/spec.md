# Feature: Working Memory System for Claude Code

---
runId: e22e0d
feature: working-memory-system
created: 2025-11-17
status: draft
---

**Status**: Draft
**Created**: 2025-11-17
**Plugin**: tabula-scripta

## Problem Statement

### Current State

Claude Code loses context between sessions:
- **No proactive recall** - Episodic-memory requires manual search; Claude doesn't automatically load relevant context
- **Write-only journals** - Private-journal-mcp is append-only; can't update understanding as it evolves
- **Lost decisions** - Architectural choices, debugging insights, and rationale disappear in conversation history
- **No living memory** - Cannot evolve notes as understanding deepens during sessions

### Desired State

Claude maintains proactive, updateable working memory:
- **Automatic context loading** - Relevant memories loaded at session start without user asking
- **Living notes** - Update understanding as sessions progress (not just append)
- **Autonomous management** - Claude decides what to remember and when (skill-driven triggers)
- **Human-curated fallback** - All memories stored as human-readable Obsidian notes

### Gap

Need a Claude Code plugin that bridges Obsidian (human knowledge graph) with autonomous memory management (Claude-driven updates).

---

## Requirements

### Functional Requirements

**FR1: Three-Layer Memory Granularity**
- Session notes (temporal, ephemeral): `~/.claude-memory/claude/projects/{project}/sessions/{date}-{topic}.md`
- Entity notes (persistent, specific): `~/.claude-memory/claude/projects/{project}/entities/{Entity Name}.md`
- Topic notes (organizational): `~/.claude-memory/claude/global/topics/{Topic Name}.md`

**FR2: Proactive Session Start Recall**
- Detect project context from git repo / working directory
- Load project index + linked entities
- Query last 3 session notes via Dataview
- Present 1-3 sentence summary (not overwhelming)
- User can request additional context

**FR3: Autonomous Memory Writing**
- Automatic triggers: After code review, debugging, architectural decision, periodic checkpoints (30-60 min), session end
- Ask-first triggers: User preferences, contradictions to existing notes, global entity creation
- Integration with superpowers skills: `requesting-code-review`, `systematic-debugging`, `brainstorming`

**FR4: Living Memory Updates**
- Patch operations (append to sections, preserve existing content)
- Conflict detection (human edited since Claude loaded)
- Timestamp tracking: `updated` vs `claude_last_accessed`
- Conflict resolution: Show diff, ask user to merge/abort/discuss

**FR5: Cross-Project Pattern Detection**
- Track when entity from project A recalled while working in project B
- Log to `cross_project_recalls` frontmatter
- After 3 cross-project recalls → ask user to promote to global entity

**FR6: Manual Memory Commands (Phase 1)**
- `/remember [type] [title]` - Create new memory note
- `/recall [query]` - Search existing memories
- `/update-memory [title]` - Update existing note

**FR7: Session Note Lifecycle**
- Threshold-based compaction: 500 lines OR 3 days old (whichever first)
- Compact: Parse session → extract knowledge → update entity notes → archive session
- Archive location: `~/.claude-memory/claude/projects/{project}/archive/sessions/`

### Non-Functional Requirements

**NFR1: Obsidian Integration**
- All notes stored in `~/.claude-memory/` vault (user can browse/edit in Obsidian)
- Uses aaronsb/obsidian-mcp-plugin (assumes pre-configured)
- Graph links via `[[wikilinks]]`, categorization via `#tags`
- Dataview queries for structured retrieval

**NFR2: Performance**
- Session start recall: <2 seconds
- Memory write operations: Non-blocking, don't interrupt user flow
- Semantic search (optional): Smart Connections plugin if available, fallback to text search

**NFR3: User Experience**
- Summary mode: 1-3 sentence highlights at session start (not full memory dump)
- Conflict transparency: Always show diff before overwriting
- Ask permission for subjective content (preferences, contradictions)
- Memory spam prevention: <5 writes per hour-long session

**NFR4: Durability**
- Markdown files are git-trackable and portable
- Human-readable frontmatter (YAML)
- Never delete notes (archive if obsolete, preserve history)

---

## Architecture

### Plugin Structure

**tabula-scripta/** (Claude Code plugin)
```
plugin.json                    # Plugin metadata, requires obsidian MCP
skills/
  managing-working-memory.md   # Core skill (write triggers, templates, conflicts)
commands/
  remember.md                  # /remember - Create new memory
  recall.md                    # /recall - Search memories
  update-memory.md             # /update-memory - Update existing note
hooks/
  session-start.md             # Proactive recall (Phase 2)
  session-end.md               # Compaction + archival (Phase 3)
docs/
  setup-guide.md               # Obsidian MCP configuration
  memory-patterns.md           # Usage examples
```

**~/.claude-memory/** (Obsidian vault)
```
claude/
  projects/
    {project-name}/
      sessions/        # Temporal notes
      entities/        # Persistent concepts
      archive/
        sessions/      # Archived session notes
      _index.md        # Project MOC
  global/
    entities/          # Cross-project knowledge
    topics/            # Maps of Content
  _index.md            # Top-level MOC
.obsidian/             # Obsidian config (user manages)
```

### Components

**New Files:**

**Plugin files:**
- `plugin.json` - Metadata, requires obsidian MCP server
- `skills/managing-working-memory.md` - Core skill defining when/what/how to write
- `commands/remember.md` - Slash command for manual memory creation
- `commands/recall.md` - Slash command for memory search
- `commands/update-memory.md` - Slash command for memory updates
- `hooks/session-start.md` - Hook for proactive recall
- `hooks/session-end.md` - Hook for compaction and archival
- `docs/setup-guide.md` - MCP configuration instructions
- `docs/memory-patterns.md` - Usage patterns and examples

**Vault files (created at runtime):**
- `~/.claude-memory/claude/_index.md` - Top-level MOC
- `~/.claude-memory/claude/projects/{project}/_index.md` - Per-project MOC
- Session/entity/topic notes created dynamically via skill

### Frontmatter Schema

**All notes include:**
```yaml
---
type: entity|session|topic
project: {project-name}|global
tags: [debugging, architecture, patterns]
created: 2025-11-17
updated: 2025-11-17
status: active|archived|draft
claude_last_accessed: 2025-11-17
cross_project_recalls: []  # For global promotion
---
```

### Dependencies

**MCP Server:**
- `obsidian-mcp-plugin` by aaronsb (assumes user has configured)
- Operations: `create_note`, `read_note`, `update_note`, `search_notes`, `graph_query`, `dataview_query`
- See: https://github.com/aaronsb/obsidian-mcp-plugin

**Optional Enhancement:**
- Smart Connections Obsidian plugin (for semantic search)
- Fallback to text search if not available

### Integration Points

**Claude Code Hooks:**
- SessionStart hook → Load memories automatically
- SessionEnd hook → Compact and archive
- No modifications to core Claude Code (plugin only)

**Superpowers Skills Integration:**
- `requesting-code-review` → Trigger entity update after review
- `systematic-debugging` → Record troubleshooting pattern
- `brainstorming` → Create/update entity with architectural decision
- Integration via skill-driven triggers (not hook modifications)

**MCP Architecture:**
- Plugin invokes obsidian-mcp operations
- No direct file I/O (all via MCP for safety)
- Graceful degradation if MCP unavailable

---

## Acceptance Criteria

### Phase 1: Manual Commands (MVP)
- [ ] `/remember` creates notes at correct vault path with valid frontmatter
- [ ] `/recall` finds notes via graph/text search and presents results
- [ ] `/update-memory` detects conflicts (timestamp comparison)
- [ ] All notes appear correctly in Obsidian vault
- [ ] Graph links `[[Entity]]` work in Obsidian

### Phase 2: Proactive Recall
- [ ] SessionStart hook loads project context automatically
- [ ] Summary is 1-3 sentences (not overwhelming)
- [ ] Last 3 session notes loaded via Dataview
- [ ] Project detection works for git repos
- [ ] User can request additional context

### Phase 3: Autonomous Management
- [ ] Skill-driven triggers fire after code review, debugging, decisions
- [ ] Session notes compact at threshold (500 lines OR 3 days)
- [ ] Compacted notes archived (not deleted)
- [ ] Cross-project recall tracking logs to frontmatter
- [ ] Global promotion asks user after 3 cross-project recalls
- [ ] Periodic checkpoints (30-60 min) update session note

### Quality Gates
- [ ] Conflict detection prevents data loss (human edits win)
- [ ] No memory spam (<5 writes per hour-long session)
- [ ] Recall relevance: >80% of loaded memories are relevant
- [ ] Performance: Session start recall <2 seconds
- [ ] User stops manually explaining past context

### Skill Testing
- [ ] `managing-working-memory` skill tested with subagents before hook integration
- [ ] TodoWrite checklists validated (memory checkpoint, session end, compaction)
- [ ] Conflict resolution flows tested (clean update, human edit, major rewrite)

---

## Open Questions

None - Design complete per @docs/plans/2025-11-17-working-memory-design.md

---

## References

**Design Documentation:**
- Full Design: @docs/plans/2025-11-17-working-memory-design.md
- Architecture decisions, lifecycle flows, conflict resolution

**External Dependencies:**
- Obsidian MCP Plugin: https://github.com/aaronsb/obsidian-mcp-plugin
- Smart Connections (optional): https://github.com/brianpetro/obsidian-smart-connections
- Obsidian Dataview: https://blacksmithgu.github.io/obsidian-dataview/

**Knowledge Management Patterns:**
- Zettelkasten: Atomic notes, linking
- MOC (Maps of Content): Topic organization
- PARA: Projects, Areas, Resources, Archives

**Related Projects:**
- episodic-memory: https://github.com/obra/episodic-memory
- private-journal-mcp: https://github.com/obra/private-journal-mcp
