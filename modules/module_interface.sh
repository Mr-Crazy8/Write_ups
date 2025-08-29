#!/bin/bash

# Module Interface Definition
# All modules must implement these functions to be compatible with the automation framework

# Module metadata (must be defined by each module)
# MODULE_NAME=""
# MODULE_VERSION=""
# MODULE_DESCRIPTION=""
# MODULE_AUTHOR=""
# MODULE_DEPENDENCIES=()
# MODULE_REQUIRED_TOOLS=()

# Standard module interface functions that must be implemented:

# Initialize the module
# Parameters: None
# Returns: 0 on success, 1 on failure
module_init() {
    echo "module_init() must be implemented by the module"
    return 1
}

# Check if module prerequisites are met
# Parameters: None
# Returns: 0 if ready, 1 if not ready
module_check() {
    echo "module_check() must be implemented by the module"
    return 1
}

# Execute the main module functionality
# Parameters: target, output_directory, [additional_params...]
# Returns: 0 on success, 1 on failure
module_execute() {
    echo "module_execute() must be implemented by the module"
    return 1
}

# Clean up resources used by the module
# Parameters: None
# Returns: 0 on success
module_cleanup() {
    echo "module_cleanup() must be implemented by the module"
    return 0
}

# Get module status/statistics
# Parameters: None
# Returns: status information as key=value pairs
module_status() {
    echo "module_status() must be implemented by the module"
    return 1
}

# Standard helper functions available to all modules

# Log function (provided by main script)
module_log() {
    local level="$1"
    local message="$2"
    log "$level" "[$MODULE_NAME] $message"
}

# Progress reporting function
module_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    show_progress "$current" "$total" "[$MODULE_NAME] $operation"
}

# Configuration helper
module_get_config() {
    local key="$1"
    echo "${CONFIG[$key]}"
}

# Output file helper
module_output_file() {
    local filename="$1"
    local module_dir="${CONFIG[OUTPUT_DIR]}/${MODULE_NAME,,}"
    mkdir -p "$module_dir"
    echo "$module_dir/$filename"
}

# Check if tool is available
module_has_tool() {
    local tool="$1"
    command_exists "$tool"
}

# Run command with timeout and logging
module_run_command() {
    local timeout_duration="$1"
    shift
    local command=("$@")
    
    module_log "DEBUG" "Running command: ${command[*]}"
    
    if [[ "${CONFIG[DRY_RUN]}" == "true" ]]; then
        module_log "INFO" "DRY RUN - would execute: ${command[*]}"
        return 0
    fi
    
    timeout "$timeout_duration" "${command[@]}"
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        module_log "WARNING" "Command timed out after ${timeout_duration}s: ${command[*]}"
    elif [[ $exit_code -ne 0 ]]; then
        module_log "WARNING" "Command failed with exit code $exit_code: ${command[*]}"
    fi
    
    return $exit_code
}

# Parallel execution helper
module_run_parallel() {
    local max_jobs="$1"
    local input_file="$2"
    local command_template="$3"
    
    module_log "INFO" "Running parallel execution with $max_jobs jobs"
    
    if command_exists parallel && [[ "${CONFIG[USE_GNU_PARALLEL]}" == "true" ]]; then
        module_log "DEBUG" "Using GNU Parallel"
        parallel -j "$max_jobs" "$command_template" :::: "$input_file"
    else
        module_log "DEBUG" "Using xargs for parallel execution"
        cat "$input_file" | xargs -P "$max_jobs" -I {} bash -c "$command_template"
    fi
}

# Filter and validate results
module_filter_results() {
    local input_file="$1"
    local output_file="$2"
    local filter_type="${3:-basic}"
    
    case "$filter_type" in
        "basic")
            # Remove empty lines and duplicates
            grep -v '^$' "$input_file" | sort -u > "$output_file"
            ;;
        "domains")
            # Validate domain format
            grep -E '^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$' "$input_file" | sort -u > "$output_file"
            ;;
        "urls")
            # Validate URL format
            grep -E '^https?://[a-zA-Z0-9.-]+' "$input_file" | sort -u > "$output_file"
            ;;
        "ips")
            # Validate IP address format
            grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' "$input_file" | sort -u > "$output_file"
            ;;
    esac
    
    local filtered_count=$(wc -l < "$output_file")
    module_log "INFO" "Filtered results: $filtered_count items"
}

# Generate module report
module_generate_report() {
    local results_file="$1"
    local report_format="${2:-txt}"
    local report_title="$3"
    
    local report_file
    case "$report_format" in
        "txt")
            report_file=$(module_output_file "report.txt")
            {
                echo "=== $report_title ==="
                echo "Generated: $(date)"
                echo "Module: $MODULE_NAME v$MODULE_VERSION"
                echo "Target: ${CONFIG[TARGET]}"
                echo
                echo "=== Results ==="
                cat "$results_file"
            } > "$report_file"
            ;;
        "markdown")
            report_file=$(module_output_file "report.md")
            {
                echo "# $report_title"
                echo
                echo "- **Generated:** $(date)"
                echo "- **Module:** $MODULE_NAME v$MODULE_VERSION"
                echo "- **Target:** ${CONFIG[TARGET]}"
                echo
                echo "## Results"
                echo
                echo '```'
                cat "$results_file"
                echo '```'
            } > "$report_file"
            ;;
        "json")
            report_file=$(module_output_file "report.json")
            {
                echo "{"
                echo "  \"title\": \"$report_title\","
                echo "  \"generated\": \"$(date -Iseconds)\","
                echo "  \"module\": {"
                echo "    \"name\": \"$MODULE_NAME\","
                echo "    \"version\": \"$MODULE_VERSION\""
                echo "  },"
                echo "  \"target\": \"${CONFIG[TARGET]}\","
                echo "  \"results\": ["
                
                local first=true
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    if [[ "$first" == "true" ]]; then
                        first=false
                    else
                        echo ","
                    fi
                    printf "    \"%s\"" "$(echo "$line" | sed 's/"/\\"/g')"
                done < "$results_file"
                
                echo
                echo "  ]"
                echo "}"
            } > "$report_file"
            ;;
    esac
    
    module_log "INFO" "Report generated: $report_file"
    echo "$report_file"
}

# Send module notification
module_notify() {
    local message="$1"
    local priority="${2:-normal}"
    
    send_notification "[$MODULE_NAME] $message" "$priority"
}

# Module validation function
validate_module() {
    local module_file="$1"
    
    # Source the module file
    if ! source "$module_file"; then
        echo "ERROR: Failed to source module file: $module_file"
        return 1
    fi
    
    # Check required metadata
    local required_vars=("MODULE_NAME" "MODULE_VERSION" "MODULE_DESCRIPTION")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "ERROR: Module missing required variable: $var"
            return 1
        fi
    done
    
    # Check required functions
    local required_functions=("module_init" "module_check" "module_execute" "module_cleanup" "module_status")
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null; then
            echo "ERROR: Module missing required function: $func"
            return 1
        fi
    done
    
    echo "Module validation passed: $MODULE_NAME v$MODULE_VERSION"
    return 0
}

# Export functions for use by modules
export -f module_log module_progress module_get_config module_output_file
export -f module_has_tool module_run_command module_run_parallel
export -f module_filter_results module_generate_report module_notify