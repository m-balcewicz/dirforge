#!/usr/bin/env bash
# lib/user_input.sh
# User input helpers for interactive prompting when detection fails

set -euo pipefail

# Prompt user to specify project version when detection returns "unknown"
# Usage: prompt_for_version
# Returns: version string or defaults to 1.0.22 if non-interactive
prompt_for_version() {
  # Check if we're in a TTY (interactive mode)
  if [[ ! -t 0 ]]; then
    # Non-interactive mode - use default
    echo "1.0.22"
    return 0
  fi
  
  echo "⚠️  Could not automatically detect the project version."
  echo
  echo "Please specify the project version:"
  echo
  echo "  1) 1.0.22   - Latest with .integrity metadata system"
  echo "  2) 1.0.21   - Recent version"
  echo "  3) 1.0.20   - Older version"
  echo "  4) 1.0.17   - Legacy version"
  echo "  5) Manual   - I'll specify the version manually"
  echo
  read -p "Enter choice (1-5): " version_choice
  
  case "$version_choice" in
    1) echo "1.0.22" ;;
    2) echo "1.0.21" ;;
    3) echo "1.0.20" ;;
    4) echo "1.0.17" ;;
    5)
      read -p "Enter version (e.g., 1.0.22): " manual_version
      echo "$manual_version"
      ;;
    *)
      echo "Invalid choice. Using latest version 1.0.22."
      echo "1.0.22"
      ;;
  esac
}

# Prompt user to specify world type when detection returns "unknown"
# Usage: prompt_for_world_type
# Returns: world type string or defaults to RESEARCH_WORLD if non-interactive
prompt_for_world_type() {
  # Check if we're in a TTY (interactive mode)
  if [[ ! -t 0 ]]; then
    # Non-interactive mode - use default
    echo "RESEARCH_WORLD"
    return 0
  fi
  
  echo "⚠️  Could not automatically detect the world type."
  echo
  echo "Please specify the world type for this project:"
  echo
  echo "  1) RESEARCH_WORLD   - Research projects with studies and supervision"
  echo "  2) JOURNAL_WORLD    - Journal/publication with role-based structure"
  echo "  3) CODING_WORLD     - Software and development projects"
  echo "  4) LECTURE_WORLD    - Course and lecture materials"
  echo "  5) OFFICE_WORLD     - Business and office management"
  echo "  6) PRIVATE_WORLD    - Personal and private documents"
  echo "  7) LITERATURE_WORLD - Books, articles, and literature"
  echo "  8) Manual           - I'll specify the world type manually"
  echo
  read -p "Enter choice (1-8): " world_choice
  
  case "$world_choice" in
    1) echo "RESEARCH_WORLD" ;;
    2) echo "JOURNAL_WORLD" ;;
    3) echo "CODING_WORLD" ;;
    4) echo "LECTURE_WORLD" ;;
    5) echo "OFFICE_WORLD" ;;
    6) echo "PRIVATE_WORLD" ;;
    7) echo "LITERATURE_WORLD" ;;
    8)
      read -p "Enter world type (e.g., RESEARCH_WORLD): " manual_world
      echo "$manual_world"
      ;;
    *)
      echo "Invalid choice. Defaulting to RESEARCH_WORLD."
      echo "RESEARCH_WORLD"
      ;;
  esac
}

# Prompt user to confirm an action
# Usage: confirm_action "Action description"
# Returns 0 if confirmed, 1 if not
confirm_action() {
  local action_description="${1:-Proceed}"
  echo
  read -p "❓ $action_description? (y/n): " confirm
  
  case "$confirm" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Display a list of suggestions and ask user to choose
# Usage: select_from_suggestions "Question" "option1" "option2" "option3"
# Returns the selected option
select_from_suggestions() {
  local question="$1"
  shift
  local options=("$@")
  
  echo "❓ $question"
  echo
  
  local index=1
  for option in "${options[@]}"; do
    echo "  $index) $option"
    ((index++))
  done
  echo
  
  read -p "Enter choice (1-${#options[@]}): " choice
  
  # Validate choice
  if [[ "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
    echo "${options[$((choice - 1))]}"
  else
    echo "Invalid choice. Using first option: ${options[0]}"
    echo "${options[0]}"
  fi
}
