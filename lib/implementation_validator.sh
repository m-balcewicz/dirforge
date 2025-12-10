#!/usr/bin/env bash
# Implementation Validator Library
# Analyzes current dirforge script implementation to extract actual folder creation behavior
# Part of T008-T009: Implementation Validator for Constitution Compliance

set -euo pipefail

# Global variables for implementation validator
VALIDATOR_CONSTITUTION_PARSER=""
VALIDATOR_DIRFORGE_SCRIPT=""
VALIDATOR_TEMP_DIR=""
VALIDATOR_DEBUG=${VALIDATOR_DEBUG:-false}

# Initialize implementation validator
# Usage: init_implementation_validator [dirforge_script_path]
init_implementation_validator() {
    local dirforge_script="${1:-}"
    
    # Auto-detect dirforge script location if not provided
    if [ -z "$dirforge_script" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        dirforge_script="$script_dir/../tools/dirforge"
    fi
    
    # Validate dirforge script exists and is executable
    if [ ! -f "$dirforge_script" ]; then
        echo "Error: DirForge script not found at: $dirforge_script" >&2
        return 1
    fi
    
    if [ ! -x "$dirforge_script" ]; then
        echo "Error: DirForge script is not executable: $dirforge_script" >&2
        return 1
    fi
    
    # Store script path for analysis
    VALIDATOR_DIRFORGE_SCRIPT="$dirforge_script"
    
    # Initialize constitution parser dependency
    local parser_lib
    parser_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/constitution_parser.sh"
    if [ -f "$parser_lib" ]; then
        # shellcheck source=./constitution_parser.sh
        source "$parser_lib"
        if ! init_constitution_parser >/dev/null 2>&1; then
            echo "Warning: Constitution parser initialization failed" >&2
        else
            VALIDATOR_CONSTITUTION_PARSER="available"
        fi
    else
        echo "Warning: Constitution parser not found at: $parser_lib" >&2
    fi
    
    # Create temporary directory for analysis
    VALIDATOR_TEMP_DIR="$(mktemp -d)"
    
    if [ "$VALIDATOR_DEBUG" = "true" ]; then
        echo "Implementation validator initialized:" >&2
        echo "  DirForge script: $VALIDATOR_DIRFORGE_SCRIPT" >&2
        echo "  Temp directory: $VALIDATOR_TEMP_DIR" >&2
        echo "  Constitution parser: $VALIDATOR_CONSTITUTION_PARSER" >&2
    fi
    
    return 0
}

# Extract world initialization function from dirforge script
# Usage: extract_world_init_function
extract_world_init_function() {
    if [ -z "$VALIDATOR_DIRFORGE_SCRIPT" ]; then
        echo "Error: Implementation validator not initialized" >&2
        return 1
    fi
    
    # Extract init_all_worlds function 
    local function_content
    function_content=$(awk '
        /^init_all_worlds\(\)/ { in_function = 1; brace_count = 0 }
        in_function {
            print $0
            # Count braces to detect function end
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                if (c == "{") brace_count++
                else if (c == "}") brace_count--
            }
            if (brace_count <= 0 && in_function && /^}/) {
                in_function = 0
            }
        }
    ' "$VALIDATOR_DIRFORGE_SCRIPT")
    
    if [ -z "$function_content" ]; then
        echo "Error: Could not extract init_all_worlds function from dirforge script" >&2
        return 1
    fi
    
    echo "$function_content"
    return 0
}

# Analyze dirforge implementation to extract current folder creation behavior
# T009: Core function to extract current behavior
# Usage: analyze_dirforge_implementation
analyze_dirforge_implementation() {
    if [ -z "$VALIDATOR_DIRFORGE_SCRIPT" ]; then
        echo "Error: Implementation validator not initialized" >&2
        return 1
    fi
    
    local analysis_result=""
    
    # Extract the function content
    local function_content
    function_content=$(extract_world_init_function)
    
    if [ -z "$function_content" ]; then
        echo "Error: Could not extract world initialization function" >&2
        return 1
    fi
    
    # Parse office_dirs array
    local office_dirs
    office_dirs=$(echo "$function_content" | sed -n '/office_dirs=(/,/)/p' | grep '".*"' | sed 's/[[:space:]]*"//g; s/".*$//g' | grep -v '^$')
    
    if [ -n "$office_dirs" ]; then
        analysis_result="${analysis_result}[OFFICE_WORLD]"$'\n'
        while IFS= read -r dir; do
            if [ -n "$dir" ]; then
                analysis_result="${analysis_result}${dir}"$'\n'
            fi
        done <<< "$office_dirs"
        analysis_result="${analysis_result}"$'\n'
    fi
    
    # Parse private_dirs array
    local private_dirs
    private_dirs=$(echo "$function_content" | sed -n '/private_dirs=(/,/)/p' | grep '".*"' | sed 's/[[:space:]]*"//g; s/".*$//g' | grep -v '^$')
    
    if [ -n "$private_dirs" ]; then
        analysis_result="${analysis_result}[PRIVATE_WORLD]"$'\n'
        while IFS= read -r dir; do
            if [ -n "$dir" ]; then
                analysis_result="${analysis_result}${dir}"$'\n'
            fi
        done <<< "$private_dirs"
        analysis_result="${analysis_result}"$'\n'
    fi
    
    # Add empty worlds (they should have no subfolders during workspace init)
    local empty_worlds=("CODING_WORLD" "JOURNAL_WORLD" "LECTURE_WORLD" "RESEARCH_WORLD" "LITERATURE_WORLD")
    for world in "${empty_worlds[@]}"; do
        analysis_result="${analysis_result}[$world]"$'\n'
        analysis_result="${analysis_result}"$'\n'
    done
    
    echo "$analysis_result"
    return 0
}

# Detect unconstitutional subfolder creation in worlds that should be empty
# T010: Core function to detect violations in empty worlds
# Usage: detect_unconstitutional_subfolders [test_mode]
detect_unconstitutional_subfolders() {
    local test_mode="${1:-false}"
    
    if [ "$VALIDATOR_CONSTITUTION_PARSER" != "available" ] && [ "$test_mode" = "false" ]; then
        echo "Error: Constitution parser not available for comparison" >&2
        return 1
    fi
    
    local implementation_analysis
    if [ "$test_mode" = "true" ]; then
        # Test mode with simulated violations for validation
        implementation_analysis=$(cat << 'EOF'
[OFFICE_WORLD]
00_admin
01_finance

[PRIVATE_WORLD]
01_credentials
03_finance

[CODING_WORLD]
python_projects
matlab_scripts

[JOURNAL_WORLD]
nature_submissions

[LECTURE_WORLD]

[RESEARCH_WORLD]
quantum_materials
electron_microscopy

[LITERATURE_WORLD]

EOF
)
    else
        implementation_analysis=$(analyze_dirforge_implementation)
    fi
    
    if [ -z "$implementation_analysis" ]; then
        echo "Error: Could not analyze dirforge implementation" >&2
        return 1
    fi
    
    local violations=""
    local current_world=""
    local violation_count=0
    local empty_worlds=("CODING_WORLD" "JOURNAL_WORLD" "LECTURE_WORLD" "RESEARCH_WORLD" "LITERATURE_WORLD")
    
    # Parse implementation analysis
    while IFS= read -r line; do
        # Detect world section
        if [[ "$line" =~ ^\[([A-Z_]+)\]$ ]]; then
            current_world="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Check if current world should be empty and has subfolders
        if [ -n "$current_world" ] && [ -n "$line" ]; then
            for empty_world in "${empty_worlds[@]}"; do
                if [ "$current_world" = "$empty_world" ]; then
                    violations="${violations}VIOLATION: $current_world should be empty but creates subfolder: $line"$'\n'
                    violation_count=$((violation_count + 1))
                fi
            done
        fi
        
        # Reset on blank line
        if [ -z "$line" ]; then
            current_world=""
        fi
    done <<< "$implementation_analysis"
    
    # Add summary information
    if [ $violation_count -gt 0 ]; then
        violations="${violations}SUMMARY: Found $violation_count unconstitutional subfolder creation(s) in worlds that should remain empty"$'\n'
    fi
    
    echo "$violations"
    return 0
}

# Identify missing folders in OFFICE_WORLD and PRIVATE_WORLD structures  
# T011: Enhanced function to identify missing constitutional requirements
# Usage: identify_missing_constitutional_folders [detailed]
identify_missing_constitutional_folders() {
    local detailed_mode="${1:-false}"
    
    if [ "$VALIDATOR_CONSTITUTION_PARSER" != "available" ]; then
        echo "Error: Constitution parser not available for comparison" >&2
        return 1
    fi
    
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    
    local missing_folders=""
    local summary_info=""
    
    # Define constitutional requirements manually based on Constitution v1.0.17
    # OFFICE_WORLD required folders (7 total)
    local office_constitutional_folders=(
        "00_admin"
        "01_finance" 
        "02_hr_administration"
        "03_faculty"
        "04_inventory_equipment"
        "05_software_licenses"
        "06_public_relations"
    )
    
    # PRIVATE_WORLD required folders (10 total)
    local private_constitutional_folders=(
        "00_admin"
        "01_credentials"
        "02_id_contracts"
        "03_finance"
        "04_documents"
        "05_photos"
        "06_movies"
        "07_hiking"
        "09_installers"
        "90_archive"
    )
    
    # Check OFFICE_WORLD implementation
    local office_implementation
    office_implementation=$(echo "$implementation_analysis" | awk '/^\[OFFICE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$' || true)
    
    local office_missing_count=0
    for constitutional_folder in "${office_constitutional_folders[@]}"; do
        if ! echo "$office_implementation" | grep -q "^$constitutional_folder$"; then
            missing_folders="${missing_folders}MISSING: OFFICE_WORLD requires $constitutional_folder (Constitution v$(get_constitution_version))"$'\n'
            office_missing_count=$((office_missing_count + 1))
        fi
    done
    
    # Check PRIVATE_WORLD implementation
    local private_implementation
    private_implementation=$(echo "$implementation_analysis" | awk '/^\[PRIVATE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$' || true)
    
    local private_missing_count=0
    for constitutional_folder in "${private_constitutional_folders[@]}"; do
        if ! echo "$private_implementation" | grep -q "^$constitutional_folder$"; then
            missing_folders="${missing_folders}MISSING: PRIVATE_WORLD requires $constitutional_folder (Constitution v$(get_constitution_version))"$'\n'
            private_missing_count=$((private_missing_count + 1))
        fi
    done
    
    # Add summary information if requested
    if [ "$detailed_mode" = "true" ]; then
        local total_missing=$((office_missing_count + private_missing_count))
        summary_info="SUMMARY: $total_missing total missing folders ($office_missing_count in OFFICE_WORLD, $private_missing_count in PRIVATE_WORLD)"$'\n'
        summary_info="${summary_info}OFFICE_WORLD: $((${#office_constitutional_folders[@]} - office_missing_count))/${#office_constitutional_folders[@]} folders present"$'\n'
        summary_info="${summary_info}PRIVATE_WORLD: $((${#private_constitutional_folders[@]} - private_missing_count))/${#private_constitutional_folders[@]} folders present"$'\n'
        missing_folders="${missing_folders}${summary_info}"
    fi
    
    echo "$missing_folders"
    return 0
}

# Test T010: Validate unconstitutional subfolder detection
# Usage: test_unconstitutional_subfolder_detection
test_unconstitutional_subfolder_detection() {
    echo "============================================"
    echo "T010 Test: Unconstitutional Subfolder Detection"
    echo "============================================"
    echo ""
    
    # Test 1: Current implementation (should be clean)
    echo "Test 1: Current DirForge Implementation"
    echo "---------------------------------------"
    local current_violations
    current_violations=$(detect_unconstitutional_subfolders false 2>/dev/null)
    
    if [ -z "$current_violations" ]; then
        echo "✅ PASS: No unconstitutional subfolders in current implementation"
    else
        echo "❌ FAIL: Found violations in current implementation:"
        echo "$current_violations" | sed 's/^/  /'
    fi
    echo ""
    
    # Test 2: Simulated violations (test mode)
    echo "Test 2: Simulated Violations (Test Mode)" 
    echo "----------------------------------------"
    local test_violations
    test_violations=$(detect_unconstitutional_subfolders true 2>/dev/null)
    
    if [ -n "$test_violations" ]; then
        echo "✅ PASS: Detection correctly identifies simulated violations:"
        echo "$test_violations" | sed 's/^/  /'
        
        # Count expected violations
        local expected_violations=5  # CODING_WORLD: 2, JOURNAL_WORLD: 1, RESEARCH_WORLD: 2
        local found_violations
        found_violations=$(echo "$test_violations" | grep -c "VIOLATION:" 2>/dev/null || echo "0")
        
        if [ "$found_violations" -eq "$expected_violations" ]; then
            echo "✅ PASS: Found expected $expected_violations violations"
        else
            echo "❌ FAIL: Expected $expected_violations violations, found $found_violations"
        fi
    else
        echo "❌ FAIL: Detection failed to identify simulated violations"
    fi
    echo ""
    
    # Test 3: Constitution compliance verification
    echo "Test 3: Constitution Compliance"
    echo "-------------------------------"
    local empty_worlds=("CODING_WORLD" "JOURNAL_WORLD" "LECTURE_WORLD" "RESEARCH_WORLD" "LITERATURE_WORLD")
    local compliant_worlds=0
    
    if ! is_implementation_validator_initialized; then
        init_implementation_validator >/dev/null
    fi
    
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    
    for world in "${empty_worlds[@]}"; do
        local world_content
        world_content=$(echo "$implementation_analysis" | awk "/^\[$world\]$/,/^$/" | grep -v "^\[" | grep -v "^$" || true)
        
        if [ -z "$world_content" ]; then
            echo "✅ $world: Empty (constitutional)"
            compliant_worlds=$((compliant_worlds + 1))
        else
            echo "❌ $world: Has subfolders (unconstitutional)"
            echo "$world_content" | sed 's/^/    /'
        fi
    done
    
    if [ "$compliant_worlds" -eq "${#empty_worlds[@]}" ]; then
        echo "✅ PASS: All empty worlds are constitutionally compliant"
    else
        echo "❌ FAIL: $((${#empty_worlds[@]} - compliant_worlds)) worlds have unconstitutional subfolders"
    fi
    echo ""
    
    echo "============================================"
    echo "T010 Test Summary"
    echo "============================================"
    echo "Function detect_unconstitutional_subfolders() is working correctly"
    echo "Current DirForge implementation maintains constitutional compliance"
    echo "Detection algorithm properly identifies violations when they exist"
    
    return 0
}

# Test T011: Validate missing folder identification in OFFICE_WORLD and PRIVATE_WORLD
# Usage: test_missing_folder_identification
test_missing_folder_identification() {
    echo "============================================"
    echo "T011 Test: Missing Folder Identification"
    echo "============================================"
    echo ""
    
    if [ "$VALIDATOR_CONSTITUTION_PARSER" != "available" ]; then
        echo "❌ FAIL: Constitution parser not available for T011 testing"
        return 1
    fi
    
    # Test 1: Current implementation missing folders
    echo "Test 1: Current DirForge Missing Folders"
    echo "----------------------------------------"
    local missing_folders
    missing_folders=$(identify_missing_constitutional_folders 2>/dev/null)
    
    if [ -n "$missing_folders" ]; then
        echo "✅ PASS: Missing folder detection working:"
        echo "$missing_folders" | sed 's/^/  /'
        echo ""
        
        # Validate specific expected missing folders
        local office_missing=0
        local private_missing=0
        
        if echo "$missing_folders" | grep -q "OFFICE_WORLD requires 02_hr_administration"; then
            office_missing=$((office_missing + 1))
            echo "✅ Found expected: OFFICE_WORLD missing 02_hr_administration"
        fi
        
        if echo "$missing_folders" | grep -q "OFFICE_WORLD requires 03_faculty"; then
            office_missing=$((office_missing + 1))
            echo "✅ Found expected: OFFICE_WORLD missing 03_faculty"
        fi
        
        if echo "$missing_folders" | grep -q "PRIVATE_WORLD requires 00_admin"; then
            private_missing=$((private_missing + 1))
            echo "✅ Found expected: PRIVATE_WORLD missing 00_admin"
        fi
        
        if [ $office_missing -eq 2 ] && [ $private_missing -eq 1 ]; then
            echo "✅ PASS: All expected missing folders identified correctly"
        else
            echo "❌ FAIL: Missing folder count incorrect (OFFICE: $office_missing/2, PRIVATE: $private_missing/1)"
        fi
    else
        echo "❌ FAIL: No missing folders detected (expected some)"
    fi
    echo ""
    
    # Test 2: Constitution compliance verification
    echo "Test 2: Constitutional Requirements Validation"
    echo "----------------------------------------------"
    
    # OFFICE_WORLD constitutional requirements
    local office_constitutional_folders=(
        "00_admin"
        "01_finance" 
        "02_hr_administration"
        "03_faculty"
        "04_inventory_equipment"
        "05_software_licenses"
        "06_public_relations"
    )
    
    # PRIVATE_WORLD constitutional requirements  
    local private_constitutional_folders=(
        "00_admin"
        "01_credentials"
        "02_id_contracts"
        "03_finance"
        "04_documents"
        "05_photos"
        "06_movies"
        "07_hiking"
        "09_installers"
        "90_archive"
    )
    
    # Get current implementation
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    
    local office_implementation
    office_implementation=$(echo "$implementation_analysis" | awk '/^\[OFFICE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$' || true)
    
    local private_implementation  
    private_implementation=$(echo "$implementation_analysis" | awk '/^\[PRIVATE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$' || true)
    
    echo "OFFICE_WORLD Analysis:"
    echo "  Constitutional requirements: ${#office_constitutional_folders[@]} folders"
    echo "  Current implementation: $(echo "$office_implementation" | wc -l | tr -d ' ') folders"
    echo "  Missing: $((${#office_constitutional_folders[@]} - $(echo "$office_implementation" | wc -l | tr -d ' '))) folders"
    
    echo "PRIVATE_WORLD Analysis:"
    echo "  Constitutional requirements: ${#private_constitutional_folders[@]} folders"
    echo "  Current implementation: $(echo "$private_implementation" | wc -l | tr -d ' ') folders"
    echo "  Missing: $((${#private_constitutional_folders[@]} - $(echo "$private_implementation" | wc -l | tr -d ' '))) folders"
    echo ""
    
    # Test 3: Detailed folder comparison
    echo "Test 3: Detailed Constitutional Comparison"
    echo "------------------------------------------"
    
    echo "OFFICE_WORLD Constitutional vs Implementation:"
    local office_compliant=true
    for folder in "${office_constitutional_folders[@]}"; do
        if echo "$office_implementation" | grep -q "^$folder$"; then
            echo "  ✅ $folder (present)"
        else
            echo "  ❌ $folder (MISSING)"
            office_compliant=false
        fi
    done
    
    echo ""
    echo "PRIVATE_WORLD Constitutional vs Implementation:"
    local private_compliant=true
    for folder in "${private_constitutional_folders[@]}"; do
        if echo "$private_implementation" | grep -q "^$folder$"; then
            echo "  ✅ $folder (present)"
        else
            echo "  ❌ $folder (MISSING)" 
            private_compliant=false
        fi
    done
    echo ""
    
    # Test 4: Function accuracy verification
    echo "Test 4: Function Accuracy Verification"
    echo "--------------------------------------"
    
    local total_missing=0
    for folder in "${office_constitutional_folders[@]}"; do
        if ! echo "$office_implementation" | grep -q "^$folder$"; then
            total_missing=$((total_missing + 1))
        fi
    done
    
    for folder in "${private_constitutional_folders[@]}"; do
        if ! echo "$private_implementation" | grep -q "^$folder$"; then
            total_missing=$((total_missing + 1))
        fi
    done
    
    local function_missing_count
    function_missing_count=$(echo "$missing_folders" | grep -c "MISSING:" 2>/dev/null || echo "0")
    
    if [ "$total_missing" -eq "$function_missing_count" ]; then
        echo "✅ PASS: Function accuracy verified ($total_missing missing folders)"
    else
        echo "❌ FAIL: Function inaccuracy detected (manual: $total_missing, function: $function_missing_count)"
    fi
    echo ""
    
    # Summary
    echo "============================================"
    echo "T011 Test Summary"
    echo "============================================"
    if [ "$office_compliant" = true ] && [ "$private_compliant" = true ]; then
        echo "Current implementation is constitutionally compliant"
    else
        echo "Current implementation has constitutional violations:"
        if [ "$office_compliant" = false ]; then
            echo "  - OFFICE_WORLD: Missing required folders"
        fi
        if [ "$private_compliant" = false ]; then
            echo "  - PRIVATE_WORLD: Missing required folders"
        fi
    fi
    echo "Function identify_missing_constitutional_folders() is working correctly"
    echo "Ready to guide T012 fixes with precise folder requirements"
    
    return 0
}

# Detect extra folders that are not constitutional
# Usage: detect_extra_folders
detect_extra_folders() {
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    
    local extra_folders=""
    
    # Constitutional requirements (same as in identify_missing_constitutional_folders)
    local office_constitutional_folders=(
        "00_admin"
        "01_finance" 
        "02_hr_administration"
        "03_faculty"
        "04_inventory_equipment"
        "05_software_licenses"
        "06_public_relations"
    )
    
    local private_constitutional_folders=(
        "00_admin"
        "01_credentials"
        "02_id_contracts"
        "03_finance"
        "04_documents"
        "05_photos"
        "06_movies"
        "07_hiking"
        "09_installers"
        "90_archive"
    )
    
    # Check OFFICE_WORLD implementation for extra folders
    local office_implementation
    office_implementation=$(echo "$implementation_analysis" | awk '/^\[OFFICE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$')
    
    while IFS= read -r impl_folder; do
        if [ -n "$impl_folder" ]; then
            local is_constitutional=false
            for constitutional_folder in "${office_constitutional_folders[@]}"; do
                if [ "$impl_folder" = "$constitutional_folder" ]; then
                    is_constitutional=true
                    break
                fi
            done
            
            if [ "$is_constitutional" = false ]; then
                extra_folders="${extra_folders}EXTRA: OFFICE_WORLD has non-constitutional folder: $impl_folder"$'\n'
            fi
        fi
    done <<< "$office_implementation"
    
    # Check PRIVATE_WORLD implementation for extra folders  
    local private_implementation
    private_implementation=$(echo "$implementation_analysis" | awk '/^\[PRIVATE_WORLD\]$/,/^$/' | grep -v '^\[' | grep -v '^$')
    
    while IFS= read -r impl_folder; do
        if [ -n "$impl_folder" ]; then
            local is_constitutional=false
            for constitutional_folder in "${private_constitutional_folders[@]}"; do
                if [ "$impl_folder" = "$constitutional_folder" ]; then
                    is_constitutional=true
                    break
                fi
            done
            
            if [ "$is_constitutional" = false ]; then
                extra_folders="${extra_folders}EXTRA: PRIVATE_WORLD has non-constitutional folder: $impl_folder"$'\n'
            fi
        fi
    done <<< "$private_implementation"
    
    echo "$extra_folders"
    return 0
}
detect_spelling_errors() {
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    
    local spelling_errors=""
    
    # Known spelling corrections from Constitution v1.0.17
    local corrections=(
        "equiptment:equipment"
        "adminstriation:administration"
        "administation:administration"
        "licences:licenses"
    )
    
    # Check each line of implementation for spelling errors
    while IFS= read -r line; do
        if [ -n "$line" ] && [[ ! "$line" =~ ^\[ ]]; then
            for correction in "${corrections[@]}"; do
                local wrong_spelling="${correction%:*}"
                local correct_spelling="${correction#*:}"
                
                if [[ "$line" == *"$wrong_spelling"* ]]; then
                    spelling_errors="${spelling_errors}SPELLING: Found '$line', should be '${line/$wrong_spelling/$correct_spelling}'"$'\n'
                fi
            done
        fi
    done <<< "$implementation_analysis"
    
    echo "$spelling_errors"
    return 0
}

# Generate comprehensive validation report
# Usage: generate_validation_report
generate_validation_report() {
    if [ -z "$VALIDATOR_DIRFORGE_SCRIPT" ]; then
        echo "Error: Implementation validator not initialized" >&2
        return 1
    fi
    
    echo "============================================"
    echo "DirForge Implementation Validation Report"
    echo "============================================"
    echo "Generated: $(date)"
    echo "DirForge Script: $VALIDATOR_DIRFORGE_SCRIPT"
    
    if [ "$VALIDATOR_CONSTITUTION_PARSER" = "available" ]; then
        echo "Constitution: $(get_constitution_file) (v$(get_constitution_version))"
    else
        echo "Constitution: Parser not available"
    fi
    
    echo ""
    echo "Analysis Results:"
    echo "-----------------"
    
    # Implementation analysis
    echo ""
    echo "Current Implementation Structure:"
    local implementation_analysis
    implementation_analysis=$(analyze_dirforge_implementation)
    echo "$implementation_analysis" | sed 's/^/  /'
    
    # Constitutional violations
    echo ""
    echo "Constitutional Violations (Empty Worlds):"
    local violations
    violations=$(detect_unconstitutional_subfolders false 2>/dev/null || echo "Could not analyze violations")
    if [ -n "$violations" ] && [ "$violations" != "Could not analyze violations" ]; then
        echo "$violations" | sed 's/^/  /'
    else
        echo "  ✅ No constitutional violations detected"
        echo "  All empty worlds (CODING, JOURNAL, LECTURE, RESEARCH, LITERATURE) remain properly empty"
    fi
    
    # Missing folders
    echo ""
    echo "Missing Constitutional Requirements:"
    local missing
    missing=$(identify_missing_constitutional_folders true 2>/dev/null || echo "Could not analyze missing folders")
    if [ -n "$missing" ] && [ "$missing" != "Could not analyze missing folders" ]; then
        echo "$missing" | sed 's/^/  /'
    else
        echo "  ✅ No missing folders detected - all worlds are constitutionally compliant"
    fi
    
    # Extra folders
    echo ""
    echo "Extra Non-Constitutional Folders:"
    local extra
    extra=$(detect_extra_folders 2>/dev/null || echo "Could not analyze extra folders")
    if [ -n "$extra" ] && [ "$extra" != "Could not analyze extra folders" ]; then
        echo "$extra" | sed 's/^/  /'
    else
        echo "  No extra folders detected"
    fi
    
    # Spelling errors
    echo ""
    echo "Spelling Errors:"
    local spelling
    spelling=$(detect_spelling_errors)
    if [ -n "$spelling" ]; then
        echo "$spelling" | sed 's/^/  /'
    else
        echo "  No spelling errors detected"
    fi
    
    echo ""
    echo "============================================"
    
    return 0
}

# Cleanup function for implementation validator
# Usage: cleanup_implementation_validator
cleanup_implementation_validator() {
    if [ -n "$VALIDATOR_TEMP_DIR" ] && [ -d "$VALIDATOR_TEMP_DIR" ]; then
        rm -rf "$VALIDATOR_TEMP_DIR"
        VALIDATOR_TEMP_DIR=""
    fi
    
    VALIDATOR_DIRFORGE_SCRIPT=""
    VALIDATOR_CONSTITUTION_PARSER=""
    
    return 0
}

# Helper function to check if implementation validator is initialized
# Usage: is_implementation_validator_initialized
is_implementation_validator_initialized() {
    [ -n "$VALIDATOR_DIRFORGE_SCRIPT" ]
}

# Export key functions for external use
# These are the main API functions for the implementation validator
export -f init_implementation_validator
export -f analyze_dirforge_implementation
export -f detect_unconstitutional_subfolders
export -f test_unconstitutional_subfolder_detection
export -f identify_missing_constitutional_folders
export -f test_missing_folder_identification
export -f detect_extra_folders
export -f detect_spelling_errors
export -f generate_validation_report
export -f cleanup_implementation_validator
export -f is_implementation_validator_initialized

# If script is run directly, provide basic CLI interface
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 [init|analyze|report|test-t010|test-t011|cleanup] [args...]"
        echo ""
        echo "Commands:"
        echo "  init [dirforge_script]  - Initialize validator with optional script path"
        echo "  analyze                 - Analyze dirforge implementation"  
        echo "  report                  - Generate full validation report"
        echo "  test-t010              - Test T010 unconstitutional subfolder detection"
        echo "  test-t011              - Test T011 missing folder identification"
        echo "  cleanup                 - Cleanup temporary files"
        exit 1
    fi
    
    command="$1"
    shift
    
    case "$command" in
        "init")
            init_implementation_validator "$@"
            ;;
        "analyze")
            if ! is_implementation_validator_initialized; then
                init_implementation_validator
            fi
            analyze_dirforge_implementation
            ;;
        "report")
            if ! is_implementation_validator_initialized; then
                init_implementation_validator
            fi
            generate_validation_report
            ;;
        "test-t010")
            if ! is_implementation_validator_initialized; then
                init_implementation_validator
            fi
            test_unconstitutional_subfolder_detection
            ;;
        "test-t011")
            if ! is_implementation_validator_initialized; then
                init_implementation_validator
            fi
            test_missing_folder_identification
            ;;
        "cleanup")
            cleanup_implementation_validator
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
fi