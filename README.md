# Tabula Scripta

>[!WARNING]
>early alpha!

> Working memory for Claude Code - never lose context between sessions

[![Install](https://img.shields.io/badge/install-arittr%2Ftabula--scripta-5B3FFF?logo=claude)](https://github.com/arittr/tabula-scripta#installation--quick-start)
[![Version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/arittr/tabula-scripta/main/.claude-plugin/plugin.json&label=version&query=$.version&color=orange)](https://github.com/arittr/tabula-scripta/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Tabula Scripta is a Claude Code plugin that gives Claude persistent, cross-session memory by integrating with Obsidian via the Model Context Protocol (MCP). Think of it as Claude's external brain - automatically capturing decisions, patterns, and context so you never have to repeat yourself.

## The Problem

Every time you start a new Claude Code session:

- Claude has no memory of your previous work
- You spend time re-explaining context, decisions, and preferences
- Debugging insights and architectural patterns are lost
- Cross-project knowledge stays siloed

## The Solution

Tabula Scripta automatically:

- **Loads relevant context** when you start a session (no manual /recall needed)
- **Tracks your work** in updateable session notes
- **Extracts knowledge** into persistent entity notes (decisions, patterns, gotchas)
- **Builds a knowledge graph** that grows smarter over time
- **Works across projects** by promoting reusable patterns to global knowledge

## Features

### Automatic Context Loading

When you start a session, Claude automatically recalls:

- Recent session notes and decisions
- Relevant entity notes (components, patterns, architectures)
- Cross-project patterns you've used before

### Three-Layer Memory System

1. **Session Notes** - Temporal scratchpad for current work (auto-compacted when >500 lines or 3 days old)
2. **Entity Notes** - Persistent knowledge about components, patterns, and concepts
3. **Topic Notes** - Maps of Content (MOCs) organizing related entities

### Proactive Memory Updates

Claude automatically stores memories after:

- Code reviews complete
- Debugging sessions finish
- Architectural decisions are made
- Reusable patterns are discovered

### Living Documentation

- Updates notes via patch operations (preserves human edits)
- Conflict detection prevents data loss
- Archives instead of deleting (full history preserved)

### Cross-Project Intelligence

- Tracks when patterns are reused across projects
- Automatically promotes frequently-used patterns to global knowledge
- Semantic linking via wikilinks builds a knowledge graph

## Quick Example

```
$ claude-code

[Session Start Hook Executing...]

Working Memory Loaded for Project: my-app

Summary:
Completed authentication system using JWT strategy. Currently implementing
rate limiting middleware. Open question: Redis vs in-memory cache for prod.

Last session: 2025-11-17 - Auth Implementation
Active entities: 3 loaded ([[JWT Auth]], [[Rate Limiting]], [[Redis Integration]])
Recent sessions: 2 reviewed

---

How can I help you today?

> Let's implement the rate limiting with Redis

I see we discussed this in the last session. Based on [[Rate Limiting]]
patterns and our [[Redis Integration]] setup, I'll implement a sliding
window counter approach...

[work happens]

[Session End Hook Executing...]

Finalizing session for project: my-app
Session note: 487 lines, 1 day old (below threshold)
Marking session as active (no compaction needed).

Updated [[Rate Limiting]] with implementation details.
Updated [[Redis Integration]] with connection pooling gotcha.

Session finalized successfully.
```

## Installation

### Prerequisites

1. **Obsidian** - [Download here](https://obsidian.md)
2. **Obsidian MCP Plugin** - [aaronsb/obsidian-mcp-plugin](https://github.com/aaronsb/obsidian-mcp-plugin)
3. **Claude Code** - The official Anthropic CLI

### Install Plugin

```bash
# Install via Claude Code plugin manager
claude-code plugins install tabula-scripta

# Or clone manually
git clone https://github.com/arittr/tabula-scripta.git ~/.claude/plugins/tabula-scripta
```

### Setup Memory Vault

```bash
# Create Obsidian vault structure
mkdir -p ~/.claude-memory/claude/{projects,global}
mkdir -p ~/.claude-memory/claude/global/{entities,topics}

# Open ~/.claude-memory in Obsidian
```

### Configure MCP Connection

Add to your `~/.config/claude-code/config.json`:

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "node",
      "args": ["/path/to/obsidian-mcp-plugin/dist/index.js"],
      "env": {
        "OBSIDIAN_VAULT_PATH": "/Users/yourusername/.claude-memory"
      }
    }
  }
}
```

See [setup-guide.md](docs/setup-guide.md) for detailed setup instructions and troubleshooting.

## Usage

### Automatic (No Commands Needed)

Tabula Scripta works automatically via session hooks:

- **Session start**: Auto-loads relevant context
- **During work**: Periodic checkpoints every 30-60 minutes
- **Session end**: Finalizes notes, compacts if needed, archives

### Manual Commands

When you need explicit control:

```bash
# Remember something specific
/remember "Use conventional commits for all PRs in this project"

# Recall knowledge
/recall "How did we implement rate limiting?"

# Update an entity note
/update-memory [[JWT Auth]] "Add note about token rotation gotcha"
```

See [memory-patterns.md](docs/memory-patterns.md) for detailed usage patterns and examples.

## How It Works

1. **Session Start**: Claude detects your project, loads recent sessions and linked entities
2. **During Work**: Claude automatically updates session notes at checkpoints and after key events
3. **Session End**:
   - If session note is large (>500 lines) or old (>3 days), knowledge is extracted into entity notes
   - Session note is archived for future reference
   - Entity notes are updated with decisions, gotchas, and patterns

All notes live in your Obsidian vault at `~/.claude-memory/`, giving you full control and visibility.

## Project Structure

```
.
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── skills/
│   └── managing-working-memory.md  # Core memory management skill
├── commands/
│   ├── remember.md           # /remember command
│   ├── recall.md             # /recall command
│   └── update-memory.md      # /update-memory command
├── hooks/
│   ├── session-start.md      # Auto-loads context at session start
│   └── session-end.md        # Finalizes and compacts at session end
└── docs/
    ├── setup-guide.md        # Detailed setup instructions
    └── memory-patterns.md    # Usage patterns and examples
```

## Memory Vault Structure

Your `~/.claude-memory/` vault is organized as:

```
claude/
├── _index.md                 # Global index
├── projects/
│   └── {project-name}/
│       ├── _index.md         # Project index
│       ├── sessions/         # Temporal work logs
│       │   └── 2025-11-18-feature.md
│       ├── entities/         # Persistent knowledge
│       │   ├── Component Name.md
│       │   └── Pattern Name.md
│       └── archive/
│           └── sessions/     # Compacted sessions
└── global/
    ├── entities/             # Cross-project patterns
    └── topics/               # Maps of Content (MOCs)
```

## Configuration

Tabula Scripta is designed to work out-of-the-box with sensible defaults:

- **Compaction threshold**: 500 lines OR 3 days old
- **Checkpoint interval**: 30-60 minutes
- **Memory write limit**: <5 per hour (spam prevention)
- **Cross-project promotion**: After 3 recalls from different projects

All thresholds and behaviors are documented in the skills and hooks.

## Development

```bash
# Validate plugin metadata
make validate

# The plugin is pure markdown - no build step needed
```

## Contributing

Contributions welcome! Please:

1. Check existing issues and PRs
2. Open an issue to discuss major changes
3. Follow the existing documentation style
4. Test with actual Claude Code sessions

## Troubleshooting

### "MCP server unavailable" error

1. Ensure Obsidian is running
2. Verify obsidian-mcp-plugin is installed in your vault
3. Check Claude Code config includes the MCP server
4. See [setup-guide.md](docs/setup-guide.md) for detailed troubleshooting

### Context not loading at session start

1. Check that session notes exist in `~/.claude-memory/claude/projects/{project}/sessions/`
2. Verify the project detection (should match your git repo or directory name)
3. Look for errors in Claude Code output

### Notes not appearing in Obsidian

1. Refresh Obsidian's file explorer
2. Verify the vault path in MCP config matches your actual vault
3. Check file permissions on `~/.claude-memory/`

## Why "Tabula Scripta"?

Latin for "written tablet" - the opposite of "tabula rasa" (blank slate). Instead of starting from scratch each session, Claude begins with context already written.

## License

MIT - see [LICENSE](LICENSE) for details

## Acknowledgments

- Built on [obsidian-mcp-plugin](https://github.com/aaronsb/obsidian-mcp-plugin) by Aaron Silberstein
- Inspired by the Zettelkasten method and knowledge graph principles
- Part of the Claude Code plugin ecosystem

## Links

- [Setup Guide](docs/setup-guide.md) - Detailed installation and configuration
- [Memory Patterns](docs/memory-patterns.md) - Usage examples and best practices
- [Issues](https://github.com/arittr/tabula-scripta/issues) - Bug reports and feature requests
- [Obsidian MCP Plugin](https://github.com/aaronsb/obsidian-mcp-plugin) - Required dependency
