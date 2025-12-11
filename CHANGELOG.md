## [1.0.21] - 2025-12-11

### Added
- **Parent-Only Mode**: New simplified world-type initialization
  - `dirforge init <world-type>` now creates only the parent directory (e.g., RESEARCH_WORLD/)
  - No prompts, no subfolders, no project-specific configuration
  - Available for all world types: research, lecture, coding, journal, office, private
  - Useful for setting up workspace structure before creating specific projects
  - Examples: `dirforge init research`, `dirforge init coding`, `dirforge init journal`

- **Role-Based Journal Organization**: Complete redesign of JOURNAL_WORLD structure  
  - **New Structure**: Four role-based directories replace journal-name organization
    - `00_admin/`: Manual organization for subscriptions, memberships
    - `01_primary_authorship/`: Lead author projects (`--name "paper" --first`)
    - `02_coauthor_invites/`: Collaborative projects (`--name "paper" --coauthor`)
    - `03_journal_service/`: Review/editorial work (`--name "journal" --id "ID" --service`)
  - **Command Changes**: Unified `--name` flag replaces separate `--journal`/`--paper` flags
    - Primary: `dirforge init journal --name "thermal_analysis" --first`
    - Co-author: `dirforge init journal --name "2021_elastic_properties" --coauthor`
    - Service: `dirforge init journal --name "Nature Geoscience" --id "NGS-2024-123" --service`
  - **Breaking Change**: Requires manual migration from v1.0.20 journal structure
  - **Enhanced Validation**: Comprehensive error messages with examples and guidance
  - **Migration Support**: Complete migration documentation in help system

### Changed
- **Help System**: Updated all world-type help to document parent-only mode
- **Main Command Logic**: Enhanced dispatch to detect and handle parent-only mode
- **Error Handling**: Added validation for invalid flag combinations (e.g., `--id` without `--journal`)
- **Journal Command Interface**: Breaking change from `--journal`/`--id` to role-based flags
  - Old: `--journal "Name" --id "ID"` → New: `--name "Name" --id "ID" --service`
  - Added: `--first` and `--coauthor` flags for authorship roles
  - Enhanced: `--year` flag with automatic extraction from paper names
- **Constitution Version**: Updated to v1.0.21 with role-based journal requirements

### Fixed
- **User Experience**: Simplified common workflow of creating world directories
- **Journal Organization**: Clearer separation of different academic journal roles
- **Command Consistency**: All journal commands now use unified `--name` flag pattern

### Migration Notes
- **Breaking Change**: Journal commands require flag changes and structure migration
- **Old Structure**: `JOURNAL_WORLD/JOURNAL_NAME/ID/` no longer supported
- **New Structure**: Role-based organization improves workflow clarity
- Use `dirforge init journal --help` for complete migration guidance and examples

## [1.0.20] - 2025-12-11

### Added
- **Short Help Mode**: New `--help` (short) vs `--help-long` (detailed) help system
  - Default `-h`/`--help` now shows concise quick reference (54 lines)
  - New `--help-long` flag shows comprehensive documentation (152 lines)
  - Short help optimized for daily workflow and quick rechecks
  - Progressive disclosure guides users to detailed help when needed
  - Both modes cached for performance

### Changed
- **Consistent Flag Naming**: Standardized all world types to use `--name`/`-n` for new projects
  - Research: Changed from `--title`/`-t` to `--name`/`-n` (consistent with lecture/coding)
  - Kept `--project`/`-p` specifically for referencing existing projects
  - Updated all help text, error messages, and documentation
  - Updated all test files to use new flag naming
  - Improves consistency: all world types now use `-n` for creation, `-p` for reference

### Fixed
- **Help System UX**: Reduced information overload with two-tier help system
- **Flag Consistency**: Unified interface across all world types

## [1.0.19] - 2025-12-11

### Added
- **Short Flag Support**: Convenient short flags for all commands
  - Research: `-n` (--name), `-p` (--project), `-s` (--study)
  - Lecture: `-n` (--name)
  - Coding: `-l` (--language), `-p` (--project)
  - Journal: `-j` (--journal), `-i` (--id)
  - Examples: `dirforge init research -n "Project"`, `dirforge init coding -l python -p my_tool`
  - Improves CLI ergonomics for frequently used commands
  - All short flags use single dash syntax (`-n`, not `--n`)

### Changed
- **Constitution Version**: Updated to v1.0.19 across all files
- **Help System**: Updated to reference Constitution v1.0.19
- **Documentation**: All references updated to v1.0.19

### Fixed
- **Flag Parsing**: Consistent flag handling across all world types

## [1.0.18] - 2025-12-11

### Added
- **Enhanced Error Handling System**: New modular error handling architecture (`lib/error.sh`)
  - Context-aware error messages with user input echo
  - Language-specific examples for coding projects
  - Consistent error formatting across all world types
  - Separation of error detection (in dirforge) and formatting (in error.sh)
  - Improved user experience with actionable error messages
- **Installation Wizard**: Interactive terminal-based installation wizard (`scripts/dirforge_install_wizard.sh`)
  - User-friendly installation process with system detection
  - Automatic PATH configuration
  - Post-installation testing
  - Clear progress indicators and error handling
- **Uninstallation Support**: Complete uninstallation system (`scripts/uninstall_dirforge.sh`)
  - Interactive and command-line uninstallation modes
  - Support for local, system, and all installations
  - Safe removal with confirmation prompts
  - Automatic cleanup of empty directories
- **Enhanced Installation Documentation**: Comprehensive installation guide in README.md
  - Multiple installation methods explained
  - Uninstallation instructions
  - System requirements and troubleshooting
- **Updated Help Content**: Comprehensive coding world help (`templates/help/world_help_coding.txt`)
  - Updated to reflect actual command-line options (--language, --project)
  - Language-specific examples for python, matlab, fortran, bash
  - Error handling documentation

### Changed
- **Error Architecture**: Refactored error handling into dedicated `lib/error.sh` module
  - All error messages now use consistent formatting functions
  - Error functions are reusable across all world types
  - Improved maintainability and testability
- **Installation Process**: Improved user experience with wizard-based installation
- **Documentation Structure**: Reorganized installation section for better discoverability
- **Code Organization**: Better separation of concerns between business logic and presentation

### Fixed
- **Template Path Resolution**: Fixed template directory detection for development and installed modes
  - Added `TEMPLATES_DIR` variable alongside `LIB_DIR`
  - Templates now correctly resolved from `templates/` directory
  - Fixed "template not found" errors during research project creation
- **Installation Feedback**: Better error messages and success confirmations
- **PATH Detection**: Improved shell configuration detection and setup
- **Version Consistency**: Updated all constitution version references to v1.0.18 across codebase

### Changed (BREAKING)
- **Research World Study-Based Structure**: Complete reorganization of RESEARCH_WORLD from flat project structure to study-based organization
  - Projects now have `00_admin/`, `01_project_management/`, `02_studies/` at top level
  - Individual studies contained within `02_studies/<study_name>/` with complete workflow directories
  - Removed old numbered directories (03-08) - replaced with study-specific organization
  - Projects created as `RESEARCH_WORLD/<project_id>/` instead of `RESEARCH_WORLD/01_projects/<project_id>/`

### Added
- **Study Creation**: New `dirforge init research --project <id> --study "Study Name"` command
- **Combined Project+Study Creation**: `dirforge init research --title "Project" --study "First Study"`
- **Study-Based Organization**: Each study contains independent `00_protocols/`, `01_code/`, `02_data/`, `03_outputs/`, `04_publication/`, `05_presentations/`
- **Study Metadata**: Automatic `metadata.yaml` generation in study `02_data/` directories
- **Study Integrity**: Checksum and manifest directories for each study
- **Migration Guide**: Comprehensive migration documentation for v1.0.16 → v1.0.17
- **Example Projects**: Multi-study project examples demonstrating new organization

### Updated
- **Help System**: Updated all help content to reflect study-based workflow
- **Documentation**: README.md updated with new research project examples
- **Test Suite**: Comprehensive tests for study creation, name sanitization, and backward compatibility
- **Constitution References**: All version references updated to v1.0.17

### Removed
- **Old Research Structure**: Directories 03_analysis through 08_archive no longer created
- **Flat Project Organization**: Projects no longer nested under 01_projects/

### Migration Notes
- **BREAKING CHANGE**: Existing research projects must be manually migrated
- Use the migration guide at `docs/migration-v1.0.16-to-v1.0.17.md`
- Automated migration script provided for bulk conversion
- Study-based organization enables better separation of concerns and independent study workflows

## [1.0.16] - 2025-12-09

### Added
- Constitution v1.0.16 ratification
- Enhanced validation and integrity checking
- Improved help system performance
- Better error handling and user feedback

### Changed
- Minor improvements to directory structure validation
- Updated help content formatting

### Fixed
- Various bug fixes and stability improvements

## [1.0.15] - 2025-11-15

### Added
- Initial public release
- Complete workspace initialization
- All world types: research, lecture, coding, journal, office, private
- Constitution compliance validation
- Comprehensive help system
- Dry-run and JSON output modes

### Changed
- Migrated from Python prototype to pure Bash implementation
- Improved performance and reduced dependencies

### Fixed
- Initial bug fixes and stability improvements