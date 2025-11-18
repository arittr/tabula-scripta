# Tabula Scripta - Claude Code Plugin

## Overview

Tabula Scripta is a working memory system plugin for Claude Code that integrates with Obsidian via MCP to provide persistent, cross-session memory.

## Development Commands

### Setup
- **install**: `echo "No dependencies to install - this is a Claude Code plugin"`

### Quality Checks
- **validate**: `cat plugin.json | jq .`

## Project Structure

```
.
├── plugin.json              # Plugin metadata
├── skills/                  # Core memory management skill
├── commands/                # Manual slash commands
├── hooks/                   # Session lifecycle hooks
└── docs/                    # Setup and usage documentation
```

## Architecture

This plugin uses the Obsidian MCP server to interact with an Obsidian vault at `~/.claude-memory/`. See `docs/setup-guide.md` for setup instructions.
