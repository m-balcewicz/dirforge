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