#!/usr/bin/env bash
# colors.sh - ANSI color management utilities
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Global color variables (initialized by init_colors)
COLOR_RESET=""
COLOR_BOLD=""
COLOR_DIM=""
COLOR_RED=""
COLOR_GREEN=""
COLOR_YELLOW=""
COLOR_BLUE=""
COLOR_MAGENTA=""
COLOR_CYAN=""
COLOR_WHITE=""
COLOR_GRAY=""

# Check if terminal supports color output
# Respects NO_COLOR and FORCE_COLOR environment variables
has_color_support() {
    # NO_COLOR environment variable disables color (https://no-color.org/)
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi

    # FORCE_COLOR environment variable forces color output
    if [[ -n "${FORCE_COLOR:-}" ]]; then
        return 0
    fi

    # Check if we have a terminal and it supports colors
    if [[ ! -t 1 ]]; then
        return 1
    fi

    # Check terminal capabilities
    if command -v tput >/dev/null 2>&1; then
        local colors
        colors=$(tput colors 2>/dev/null || echo "0")
        [[ "$colors" -ge 8 ]]
    else
        # Basic terminal type check
        case "${TERM:-}" in
            *color*|xterm*|screen*|tmux*|rxvt*)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

# Initialize global color variables based on terminal capabilities
init_colors() {
    if has_color_support; then
        COLOR_RESET="\033[0m"
        COLOR_BOLD="\033[1m"
        COLOR_DIM="\033[2m"
        COLOR_RED="\033[31m"
        COLOR_GREEN="\033[32m"
        COLOR_YELLOW="\033[33m"
        COLOR_BLUE="\033[34m"
        COLOR_MAGENTA="\033[35m"
        COLOR_CYAN="\033[36m"
        COLOR_WHITE="\033[37m"
        COLOR_GRAY="\033[90m"
    else
        COLOR_RESET=""
        COLOR_BOLD=""
        COLOR_DIM=""
        COLOR_RED=""
        COLOR_GREEN=""
        COLOR_YELLOW=""
        COLOR_BLUE=""
        COLOR_MAGENTA=""
        COLOR_CYAN=""
        COLOR_WHITE=""
        COLOR_GRAY=""
    fi
}

# Apply color formatting to text with safe fallback
# Usage: colorize "text" "color_code"
colorize() {
    local text="$1"
    local color="${2:-}"
    
    if has_color_support && [[ -n "$color" ]]; then
        echo -e "${color}${text}${COLOR_RESET}"
    else
        echo "$text"
    fi
}

# Convenience functions for common color applications
red() { colorize "$1" "$COLOR_RED"; }
green() { colorize "$1" "$COLOR_GREEN"; }
yellow() { colorize "$1" "$COLOR_YELLOW"; }
blue() { colorize "$1" "$COLOR_BLUE"; }
magenta() { colorize "$1" "$COLOR_MAGENTA"; }
cyan() { colorize "$1" "$COLOR_CYAN"; }
white() { colorize "$1" "$COLOR_WHITE"; }
gray() { colorize "$1" "$COLOR_GRAY"; }
bold() { colorize "$1" "$COLOR_BOLD"; }
dim() { colorize "$1" "$COLOR_DIM"; }

# Strip ANSI color codes from text
strip_colors() {
    local text="$1"
    # Remove ANSI escape sequences
    echo "$text" | sed -E 's/\x1b\[[0-9;]*m//g'
}