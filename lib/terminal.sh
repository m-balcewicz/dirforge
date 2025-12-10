#!/usr/bin/env bash
# terminal.sh - Terminal capability detection utilities
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Get terminal width with fallback handling
# Returns the terminal width in columns, with sensible defaults
get_terminal_width() {
    local width

    # Try tput first (most reliable when available)
    if command -v tput >/dev/null 2>&1 && tput cols >/dev/null 2>&1; then
        width=$(tput cols 2>/dev/null || echo "")
    fi

    # Fall back to COLUMNS environment variable
    if [[ -z "${width:-}" && -n "${COLUMNS:-}" ]]; then
        width="$COLUMNS"
    fi

    # Fall back to stty if available
    if [[ -z "${width:-}" ]] && command -v stty >/dev/null 2>&1; then
        width=$(stty size 2>/dev/null | cut -d' ' -f2 || echo "")
    fi

    # Final fallback to 80 columns (standard terminal width)
    if [[ -z "${width:-}" ]] || [[ ! "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 20 ]]; then
        width=80
    fi

    echo "$width"
}

# Check if terminal supports cursor positioning
has_cursor_support() {
    [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput cup 0 0 >/dev/null 2>&1
}

# Check if we're running in an interactive terminal
is_interactive_terminal() {
    [[ -t 0 && -t 1 && -t 2 ]]
}

# Check if terminal supports specific tput capabilities
has_tput_capability() {
    local capability="$1"
    command -v tput >/dev/null 2>&1 && tput "$capability" >/dev/null 2>&1
}

# Get terminal height (rows)
get_terminal_height() {
    local height

    # Try tput first
    if command -v tput >/dev/null 2>&1 && tput lines >/dev/null 2>&1; then
        height=$(tput lines 2>/dev/null || echo "")
    fi

    # Fall back to LINES environment variable
    if [[ -z "${height:-}" && -n "${LINES:-}" ]]; then
        height="$LINES"
    fi

    # Fall back to stty if available
    if [[ -z "${height:-}" ]] && command -v stty >/dev/null 2>&1; then
        height=$(stty size 2>/dev/null | cut -d' ' -f1 || echo "")
    fi

    # Final fallback to 24 lines (standard terminal height)
    if [[ -z "${height:-}" ]] || [[ ! "$height" =~ ^[0-9]+$ ]] || [[ "$height" -lt 5 ]]; then
        height=24
    fi

    echo "$height"
}