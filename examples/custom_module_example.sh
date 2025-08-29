#!/bin/bash

# Example Custom Module
# This is a template for creating custom modules for the bug bounty automation framework

# Module metadata (required)
MODULE_NAME="example_custom"
MODULE_VERSION="1.0.0"
MODULE_DESCRIPTION="Example custom module demonstrating the module interface"
MODULE_AUTHOR="Bug Bounty Automation Team"
MODULE_DEPENDENCIES=()
MODULE_REQUIRED_TOOLS=("curl" "grep")

# Source the module interface
source "$(dirname "${BASH_SOURCE[0]}")/../module_interface.sh"

# Module-specific variables
RESULTS_FILE=""
STATISTICS_FILE=""

# Initialize the module
module_init() {
    module_log "INFO" "Initializing example custom module"
    
    # Set up output files
    RESULTS_FILE=$(module_output_file "custom_results.txt")
    STATISTICS_FILE=$(module_output_file "statistics.txt")
    
    # Clear previous results
    > "$RESULTS_FILE"
    > "$STATISTICS_FILE"
    
    module_log "SUCCESS" "Module initialized successfully"
    return 0
}

# Check if module prerequisites are met
module_check() {
    module_log "INFO" "Checking module prerequisites"
    
    local missing_tools=()
    
    # Check for required tools
    for tool in "${MODULE_REQUIRED_TOOLS[@]}"; do
        if ! module_has_tool "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        module_log "ERROR" "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    module_log "SUCCESS" "All prerequisites met"
    return 0
}

# Custom function to check if domain responds
check_domain_response() {
    local domain="$1"
    local output_file="$2"
    
    module_log "DEBUG" "Checking response for: $domain"
    
    # Use curl to check if domain responds
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
                         --connect-timeout 10 \
                         --max-time 30 \
                         "http://$domain" 2>/dev/null)
    
    if [[ -n "$response_code" && "$response_code" != "000" ]]; then
        echo "$domain:$response_code" >> "$output_file"
        return 0
    fi
    
    # Try HTTPS if HTTP failed
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
                         --connect-timeout 10 \
                         --max-time 30 \
                         "https://$domain" 2>/dev/null)
    
    if [[ -n "$response_code" && "$response_code" != "000" ]]; then
        echo "$domain:$response_code" >> "$output_file"
        return 0
    fi
    
    return 1
}

# Execute the main module functionality
module_execute() {
    local target="$1"
    local output_dir="$2"
    
    if [[ -z "$target" ]]; then
        module_log "ERROR" "Target domain is required"
        return 1
    fi
    
    module_log "INFO" "Starting custom analysis for: $target"
    
    # Initialize progress tracking
    local total_steps=5
    local current_step=0
    
    # Step 1: Basic domain check
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Checking main domain"
    
    if check_domain_response "$target" "$RESULTS_FILE"; then
        module_log "SUCCESS" "Main domain responds"
    else
        module_log "WARNING" "Main domain does not respond"
    fi
    
    # Step 2: Check common subdomains
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Checking common subdomains"
    
    local common_subdomains=("www" "mail" "ftp" "admin" "api" "dev" "staging" "test")
    local checked_count=0
    local responding_count=0
    
    for subdomain in "${common_subdomains[@]}"; do
        local full_domain="$subdomain.$target"
        if check_domain_response "$full_domain" "$RESULTS_FILE"; then
            ((responding_count++))
            module_log "DEBUG" "Subdomain responds: $full_domain"
        fi
        ((checked_count++))
    done
    
    # Step 3: Analyze response patterns
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Analyzing response patterns"
    
    if [[ -f "$RESULTS_FILE" ]]; then
        # Count different response codes
        local code_200=$(grep -c ":200$" "$RESULTS_FILE" 2>/dev/null || echo "0")
        local code_301=$(grep -c ":301$" "$RESULTS_FILE" 2>/dev/null || echo "0")
        local code_302=$(grep -c ":302$" "$RESULTS_FILE" 2>/dev/null || echo "0")
        local code_403=$(grep -c ":403$" "$RESULTS_FILE" 2>/dev/null || echo "0")
        local code_404=$(grep -c ":404$" "$RESULTS_FILE" 2>/dev/null || echo "0")
        
        module_log "INFO" "Response code analysis: 200($code_200) 301($code_301) 302($code_302) 403($code_403) 404($code_404)"
    fi
    
    # Step 4: Generate statistics
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Generating statistics"
    
    {
        echo "=== Custom Module Statistics ==="
        echo "Target: $target"
        echo "Date: $(date)"
        echo "Total Checked: $checked_count"
        echo "Responding: $responding_count"
        echo
        echo "=== Response Codes ==="
        if [[ -f "$RESULTS_FILE" ]]; then
            cut -d':' -f2 "$RESULTS_FILE" | sort | uniq -c | sort -nr
        fi
        echo
        echo "=== Responding Domains ==="
        if [[ -f "$RESULTS_FILE" ]]; then
            cut -d':' -f1 "$RESULTS_FILE" | sort
        fi
    } > "$STATISTICS_FILE"
    
    # Step 5: Generate reports
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Generating reports"
    
    # Generate reports in different formats
    local formats=$(module_get_config "REPORT_FORMAT")
    IFS=',' read -ra format_array <<< "$formats"
    
    for format in "${format_array[@]}"; do
        format=$(echo "$format" | tr -d ' ')
        module_generate_report "$RESULTS_FILE" "$format" "Custom Module Results for $target"
    done
    
    module_log "SUCCESS" "Custom module execution completed"
    module_notify "Custom analysis completed for $target: $responding_count/$checked_count domains responding" "normal"
    
    return 0
}

# Clean up resources used by the module
module_cleanup() {
    module_log "INFO" "Cleaning up custom module"
    
    # Remove any temporary files if they exist
    local temp_files=(
        "$(module_output_file "temp_responses.txt")"
        "$(module_output_file "temp_analysis.txt")"
    )
    
    for file in "${temp_files[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
    
    module_log "SUCCESS" "Module cleanup completed"
    return 0
}

# Get module status/statistics
module_status() {
    local total_results=0
    local responding_domains=0
    
    if [[ -f "$RESULTS_FILE" ]]; then
        total_results=$(wc -l < "$RESULTS_FILE")
        responding_domains=$(grep -c ":" "$RESULTS_FILE" 2>/dev/null || echo "0")
    fi
    
    echo "total_results=$total_results"
    echo "responding_domains=$responding_domains"
    echo "results_file=$RESULTS_FILE"
    echo "statistics_file=$STATISTICS_FILE"
    
    return 0
}

# Example of module-specific configuration handling
handle_custom_config() {
    local custom_timeout=$(module_get_config "CUSTOM_TIMEOUT")
    local custom_user_agent=$(module_get_config "CUSTOM_USER_AGENT")
    
    if [[ -n "$custom_timeout" ]]; then
        module_log "INFO" "Using custom timeout: $custom_timeout"
    fi
    
    if [[ -n "$custom_user_agent" ]]; then
        module_log "INFO" "Using custom user agent: $custom_user_agent"
    fi
}

# Example of parallel processing within a module
run_parallel_checks() {
    local domains_file="$1"
    local output_file="$2"
    local max_jobs=$(module_get_config "THREADS")
    
    module_log "INFO" "Running parallel domain checks with $max_jobs jobs"
    
    # Create a function that can be called in parallel
    local check_function="check_domain_response_wrapper() { 
        source $(dirname "${BASH_SOURCE[0]}")/../module_interface.sh
        check_domain_response \$1 \$2
    }"
    
    # Use the module's parallel execution helper
    module_run_parallel "$max_jobs" "$domains_file" "check_domain_response_wrapper {} $output_file"
}

# If script is run directly (for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Set up minimal environment for standalone testing
    CONFIG[TARGET]="${1:-example.com}"
    CONFIG[OUTPUT_DIR]="${2:-./test_results}"
    CONFIG[THREADS]=3
    CONFIG[TIMEOUT]=30
    CONFIG[DRY_RUN]=false
    CONFIG[REPORT_FORMAT]="txt,markdown"
    
    mkdir -p "${CONFIG[OUTPUT_DIR]}"
    
    # Simple logging for standalone mode
    log() {
        echo "[$1] $2"
    }
    
    show_progress() {
        echo "Progress: $1/$2 - $3"
    }
    
    send_notification() {
        echo "Notification: $1"
    }
    
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }
    
    echo "=== Testing Custom Module ==="
    echo "Target: ${CONFIG[TARGET]}"
    echo "Output: ${CONFIG[OUTPUT_DIR]}"
    echo
    
    # Initialize and run
    if module_init && module_check; then
        module_execute "${CONFIG[TARGET]}" "${CONFIG[OUTPUT_DIR]}"
        echo
        echo "=== Module Status ==="
        module_status
        echo
        module_cleanup
        echo "=== Test completed ==="
    else
        echo "Module initialization or check failed"
        exit 1
    fi
fi