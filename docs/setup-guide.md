# Tabula Scripta Setup Guide

## Overview

Tabula Scripta is a working memory system plugin for Claude Code that provides persistent, cross-session memory by integrating with Obsidian via the Model Context Protocol (MCP).

## Prerequisites

Before setting up Tabula Scripta, ensure you have:

1. **Obsidian** - Download from [obsidian.md](https://obsidian.md)
2. **Obsidian MCP Plugin** - Install from [aaronsb/obsidian-mcp-plugin](https://github.com/aaronsb/obsidian-mcp-plugin)
3. **Claude Code** - The official Anthropic CLI for Claude

### Optional Enhancements

- **Dataview Plugin** - For structured note queries (highly recommended)
- **Smart Connections Plugin** - For semantic search capabilities (optional)

---

## Vault Setup

### 1. Create the Memory Vault

Create an Obsidian vault at `~/.claude-memory/`:

```bash
mkdir -p ~/.claude-memory/claude/{projects,global}
mkdir -p ~/.claude-memory/claude/global/{entities,topics}
```

### 2. Initialize Vault Structure

Create the top-level index file:

```bash
cat > ~/.claude-memory/claude/_index.md << EOF
---
type: index
project: global
tags: [index, moc]
created: $(date +%Y-%m-%d)
updated: $(date +%Y-%m-%d)
status: active
---

# Claude Working Memory

This vault contains Claude's working memory across all projects and sessions.

## Structure

- **Projects** - Project-specific memories organized by repository
- **Global** - Cross-project knowledge and patterns

## Quick Links

- [[Projects MOC]]
- [[Global Entities]]
- [[Topics MOC]]
EOF
```

### 3. Open Vault in Obsidian

1. Launch Obsidian
2. Choose "Open folder as vault"
3. Select `~/.claude-memory/`
4. Obsidian will initialize the vault

### 4. Install Required Plugins

Within Obsidian:

1. Go to Settings > Community Plugins
2. Disable Safe Mode (if enabled)
3. Browse and install:
   - **Dataview** (required for structured queries)
   - **Smart Connections** (optional for semantic search)
4. Enable both plugins after installation

---

## MCP Server Configuration

### 1. Configure Obsidian MCP Plugin

Follow the [obsidian-mcp-plugin setup instructions](https://github.com/aaronsb/obsidian-mcp-plugin#setup) to:

1. Install the MCP server component
2. Configure the server to point to `~/.claude-memory/`
3. Start the MCP server

### 2. Configure Claude Code

Add the Obsidian MCP server to your Claude Code configuration:

**Location**: `~/.config/claude-code/config.json` (or platform-specific config location)

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

**Important**: Replace `/path/to/obsidian-mcp-plugin/dist/index.js` with the actual path to your installed MCP server, and update the vault path to match your home directory.

### 3. Restart Claude Code

After updating the configuration:

```bash
# Restart Claude Code to pick up the new MCP server configuration
```

---

## Testing the Setup

### 1. Verify Vault Structure

Confirm the vault directory and structure were created correctly:

```bash
# Test 1: Verify vault directory exists
ls -la ~/.claude-memory/claude/

# Test 2: Verify index file was created
cat ~/.claude-memory/claude/_index.md

# Test 3: Verify project and global directories exist
ls -la ~/.claude-memory/claude/projects/
ls -la ~/.claude-memory/claude/global/
```

### 2. Verify MCP Connection

Test that Claude Code can communicate with the Obsidian MCP server:

```bash
# In a Claude Code session, check that MCP tools are available
# You should see Obsidian operations like: create_note, read_note, update_note, search_notes
```

### 3. Verify in Obsidian

1. Open your `~/.claude-memory/` vault in Obsidian
2. Confirm the folder structure appears in the file explorer
3. Open `_index.md` and verify the frontmatter dates are populated correctly
4. Check that the vault is properly initialized

---

## Troubleshooting

### MCP Connection Issues

**Problem**: "MCP server not available" or connection errors

**Solutions**:
1. Verify the Obsidian MCP plugin is running:
   ```bash
   ps aux | grep obsidian-mcp
   ```
2. Check the MCP server logs for errors
3. Confirm the vault path in config matches your actual vault location
4. Restart both Obsidian and Claude Code

### Vault Not Found

**Problem**: "Vault path does not exist" errors

**Solutions**:
1. Verify vault exists:
   ```bash
   ls -la ~/.claude-memory/
   ```
2. Check permissions:
   ```bash
   chmod -R u+rw ~/.claude-memory/
   ```
3. Ensure the path in MCP config uses absolute paths (no `~` expansion in some contexts)

### Notes Not Appearing in Obsidian

**Problem**: Notes created via MCP don't show up in Obsidian UI

**Solutions**:
1. Refresh the file explorer in Obsidian (click folder icon twice)
2. Check if Obsidian has the vault open
3. Verify the MCP server is writing to the correct vault path
4. Look for the file directly in the filesystem to confirm it was created

---

## Next Steps

Once setup is complete:

1. **Verify the foundation**: Ensure the vault structure is correct and MCP is connected
2. **Explore your vault**: Browse the `~/.claude-memory/` folder in Obsidian
3. **Wait for Phase 2**: Additional features (commands, skills, automation) will be added in subsequent phases

---

## Additional Resources

- **Obsidian MCP Plugin**: https://github.com/aaronsb/obsidian-mcp-plugin
- **Dataview Documentation**: https://blacksmithgu.github.io/obsidian-dataview/
- **Smart Connections**: https://github.com/brianpetro/obsidian-smart-connections
- **Zettelkasten Method**: https://zettelkasten.de/overview/
- **MOC Pattern**: Maps of Content for knowledge organization

---

## Support

For issues specific to:
- **Tabula Scripta plugin**: Check this repository's issues
- **Obsidian MCP plugin**: https://github.com/aaronsb/obsidian-mcp-plugin/issues
- **Obsidian itself**: https://obsidian.md/community
