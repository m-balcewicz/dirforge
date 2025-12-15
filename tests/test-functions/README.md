# DirForge Test Functions - Constitutional Compliance v1.0.21

This directory contains all individual test functions for DirForge, organized according to constitutional requirements established in Constitution v1.0.21.

## Directory Structure

```
tests/
├── run_tests.sh                         # MAIN TEST RUNNER - Single entry point for all testing
├── test-functions/                      # Individual feature test scripts (THIS DIRECTORY)
│   ├── test_<feature_name>_v<version>.sh # Versioned test scripts for specific features
│   └── README.md                        # This documentation file
└── fixtures/                           # Test data and mock structures
    └── [test data files]
```

## Constitutional Requirements

According to Constitution v1.0.21, Section "Testing Environment and Infrastructure":

1. **Location**: ALL test files must be located exclusively in `tests/` directory
2. **Organization**: Individual test scripts must be in `tests/test-functions/`
3. **Naming**: Test scripts follow pattern `test_<feature_name>_v<version>.sh`
4. **Versioning**: Version indicates when the test was developed (e.g., v1.0.21)
5. **Discovery**: Main runner automatically discovers and executes all test scripts
6. **Single Entry**: Only one test runner (`tests/run_tests.sh`) in main tests directory

## Current Test Scripts

This directory contains **32 versioned test scripts** covering:

- **Core Functionality**: Basic scaffolding, dry-run modes, workspace initialization
- **World Types**: Research, lecture, journal, office, private, coding world implementations  
- **Migration Logic**: Version detection, world-type awareness, migration handling
- **Integration**: End-to-end testing, regression validation, manifest handling
- **Help System**: Content validation, accessibility, terminal integration
- **Constitutional Compliance**: Structure validation, requirement enforcement

## Usage

To run all tests:
```bash
cd /path/to/dirforge
./tests/run_tests.sh
```

The main test runner will:
1. Discover all `test_*_v*.sh` scripts in this directory
2. Execute each test in isolated environment
3. Provide consolidated pass/fail reporting
4. Clean up test artifacts automatically

## Test Script Standards

Each test script in this directory must:
- Be executable (`chmod +x`)
- Exit with code 0 for pass, non-zero for failure
- Clean up temporary files/directories
- Include descriptive test names and failure messages
- Be self-contained and not depend on external state

## Version History

- **v1.0.21**: Constitutional reorganization - all tests moved to test-functions/
- **Previous versions**: Various individual implementations across test directories

## Rationale

This structure ensures:
- **Comprehensive Coverage**: All features validated before code changes accepted
- **Regression Prevention**: Historical tests maintain functionality across updates  
- **Maintainability**: Clear organization and version tracking for future development
- **Constitutional Compliance**: Adherence to established testing infrastructure standards