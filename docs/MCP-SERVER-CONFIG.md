# MCP Server Configuration

This document explains how the speckit MCP server is configured to work with fresh initialization.

## Overview

The speckit MCP server is configured to work with the standard opencode integration structure:
- `.opencode/commands/` - Contains speckit command files
- `.specify/` - Contains templates, scripts, and configuration

## Configuration

The MCP server is configured in `~/.config/opencode/opencode.json`:

```json
{
  "mcp": {
    "speckit": {
      "type": "local",
      "command": ["python3", "/Users/martin/.local/lib/speckit/mcp/speckit_mcp_server.py"],
      "enabled": true,
      "environment": {
        "SPECKIT_REPO_ROOT": ".",
        "SPECKIT_COMMANDS_DIR": ".opencode/commands"
      }
    }
  }
}
```

## Environment Variables

The MCP server uses two environment variables:

1. **SPECKIT_REPO_ROOT** - The repository root directory (default: `.`)
2. **SPECKIT_COMMANDS_DIR** - The commands directory relative to repo root (default: `.opencode/commands`)

## How It Works

When you run `specify init . --integration opencode`, the following happens:

1. Creates `.opencode/commands/` with speckit command files
2. Creates `.specify/` directory with templates and scripts
3. MCP server reads from both locations using the environment variables

## Available Tools

The MCP server provides these tools:

- `speckit_check_prerequisites` - Check if spec and tasks are available
- `speckit_setup_plan` - Setup plan for the feature
- `speckit_resolve_template` - Resolve templates through preset stack
- `speckit_read_constitution` - Read constitution file
- `speckit_setup_tasks` - Setup tasks for the feature
- `speckit_checklist_setup` - Setup checklist for validation
- `speckit_read_command` - Read a specific speckit command file

## Fresh Initialization

To initialize a new project with opencode integration:

```bash
specify init . --integration opencode
```

This creates:
- `.opencode/commands/speckit.*.md` - All speckit command files
- `.specify/` - Templates, scripts, and configuration

The MCP server is automatically configured to use these files via the environment variables.
