#!/bin/bash

# Subdomain Enumeration Module
# Comprehensive subdomain discovery using multiple tools and techniques

# Module metadata
MODULE_NAME="subdomain"
MODULE_VERSION="1.0.0"
MODULE_DESCRIPTION="Comprehensive subdomain enumeration using multiple passive and active techniques"
MODULE_AUTHOR="Enhanced Bug Bounty Automation"
MODULE_DEPENDENCIES=()
MODULE_REQUIRED_TOOLS=("subfinder" "assetfinder")

# Source the module interface
source "$(dirname "${BASH_SOURCE[0]}")/../module_interface.sh"

# Module-specific variables
SUBDOMAIN_RESULTS_FILE=""
LIVE_SUBDOMAINS_FILE=""
PASSIVE_RESULTS_FILE=""
ACTIVE_RESULTS_FILE=""

# Initialize the module
module_init() {
    module_log "INFO" "Initializing subdomain enumeration module"
    
    # Set up output files
    SUBDOMAIN_RESULTS_FILE=$(module_output_file "subdomains_all.txt")
    LIVE_SUBDOMAINS_FILE=$(module_output_file "subdomains_live.txt")
    PASSIVE_RESULTS_FILE=$(module_output_file "subdomains_passive.txt")
    ACTIVE_RESULTS_FILE=$(module_output_file "subdomains_active.txt")
    
    # Clear previous results
    > "$SUBDOMAIN_RESULTS_FILE"
    > "$LIVE_SUBDOMAINS_FILE"
    > "$PASSIVE_RESULTS_FILE"
    > "$ACTIVE_RESULTS_FILE"
    
    module_log "SUCCESS" "Module initialized successfully"
    return 0
}

# Check if module prerequisites are met
module_check() {
    module_log "INFO" "Checking module prerequisites"
    
    local missing_tools=()
    
    # Check for at least one subdomain enumeration tool
    if ! module_has_tool "subfinder" && ! module_has_tool "assetfinder" && ! module_has_tool "amass"; then
        missing_tools+=("subfinder OR assetfinder OR amass")
    fi
    
    # Check for httpx for live subdomain verification
    if ! module_has_tool "httpx"; then
        module_log "WARNING" "httpx not found - live subdomain verification will be skipped"
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        module_log "ERROR" "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    module_log "SUCCESS" "All prerequisites met"
    return 0
}

# Run subfinder for subdomain enumeration
run_subfinder() {
    if ! module_has_tool "subfinder"; then
        module_log "WARNING" "subfinder not available, skipping"
        return 0
    fi
    
    module_log "INFO" "Running subfinder for passive subdomain enumeration"
    
    local subfinder_output=$(module_output_file "subfinder_results.txt")
    local target=$(module_get_config "TARGET")
    local timeout_duration=$(module_get_config "TIMEOUT")
    
    local cmd=(subfinder -d "$target" -silent -o "$subfinder_output")
    
    # Add custom resolvers if configured
    local dns_resolvers=$(module_get_config "DNS_RESOLVERS")
    if [[ -n "$dns_resolvers" ]]; then
        local resolvers_file=$(module_output_file "resolvers.txt")
        echo "$dns_resolvers" | tr ',' '\n' > "$resolvers_file"
        cmd+=(-r "$resolvers_file")
    fi
    
    if module_run_command "$timeout_duration" "${cmd[@]}"; then
        if [[ -f "$subfinder_output" ]]; then
            local count=$(wc -l < "$subfinder_output")
            module_log "SUCCESS" "subfinder found $count subdomains"
            cat "$subfinder_output" >> "$PASSIVE_RESULTS_FILE"
        fi
    else
        module_log "ERROR" "subfinder execution failed"
    fi
}

# Run assetfinder for subdomain enumeration
run_assetfinder() {
    if ! module_has_tool "assetfinder"; then
        module_log "WARNING" "assetfinder not available, skipping"
        return 0
    fi
    
    module_log "INFO" "Running assetfinder for passive subdomain enumeration"
    
    local assetfinder_output=$(module_output_file "assetfinder_results.txt")
    local target=$(module_get_config "TARGET")
    local timeout_duration=$(module_get_config "TIMEOUT")
    
    local cmd=(assetfinder --subs-only "$target")
    
    if module_run_command "$timeout_duration" "${cmd[@]}" > "$assetfinder_output"; then
        if [[ -f "$assetfinder_output" ]]; then
            local count=$(wc -l < "$assetfinder_output")
            module_log "SUCCESS" "assetfinder found $count subdomains"
            cat "$assetfinder_output" >> "$PASSIVE_RESULTS_FILE"
        fi
    else
        module_log "ERROR" "assetfinder execution failed"
    fi
}

# Run amass for subdomain enumeration
run_amass() {
    if ! module_has_tool "amass"; then
        module_log "WARNING" "amass not available, skipping"
        return 0
    fi
    
    local passive_only=$(module_get_config "SUBDOMAIN_PASSIVE_ONLY")
    if [[ "$passive_only" == "true" ]]; then
        run_amass_passive
    else
        run_amass_active
    fi
}

# Run amass in passive mode
run_amass_passive() {
    module_log "INFO" "Running amass in passive mode"
    
    local amass_output=$(module_output_file "amass_passive_results.txt")
    local target=$(module_get_config "TARGET")
    local timeout_duration=$(($(module_get_config "TIMEOUT") * 3))  # Amass needs more time
    
    local cmd=(amass enum -passive -d "$target" -o "$amass_output")
    
    if module_run_command "$timeout_duration" "${cmd[@]}"; then
        if [[ -f "$amass_output" ]]; then
            local count=$(wc -l < "$amass_output")
            module_log "SUCCESS" "amass passive found $count subdomains"
            cat "$amass_output" >> "$PASSIVE_RESULTS_FILE"
        fi
    else
        module_log "ERROR" "amass passive execution failed"
    fi
}

# Run amass in active mode
run_amass_active() {
    module_log "INFO" "Running amass in active mode"
    
    local amass_output=$(module_output_file "amass_active_results.txt")
    local target=$(module_get_config "TARGET")
    local timeout_duration=$(($(module_get_config "TIMEOUT") * 5))  # Active mode needs even more time
    
    local cmd=(amass enum -active -d "$target" -o "$amass_output")
    
    if module_run_command "$timeout_duration" "${cmd[@]}"; then
        if [[ -f "$amass_output" ]]; then
            local count=$(wc -l < "$amass_output")
            module_log "SUCCESS" "amass active found $count subdomains"
            cat "$amass_output" >> "$ACTIVE_RESULTS_FILE"
        fi
    else
        module_log "ERROR" "amass active execution failed"
    fi
}

# Run certificate transparency lookup
run_certificate_transparency() {
    module_log "INFO" "Checking certificate transparency logs"
    
    local ct_output=$(module_output_file "certificate_transparency.txt")
    local target=$(module_get_config "TARGET")
    
    # Use curl to query crt.sh
    local ct_url="https://crt.sh/?q=%25.$target&output=json"
    
    if module_run_command 30 curl -s "$ct_url" > "${ct_output}.json"; then
        # Extract domains from JSON response
        if command_exists jq; then
            jq -r '.[].name_value' "${ct_output}.json" 2>/dev/null | \
                grep -E "^[a-zA-Z0-9.-]+\.$target$" | \
                sed 's/\*\.//g' | \
                sort -u > "$ct_output"
        else
            # Fallback without jq
            grep -o '"name_value":"[^"]*"' "${ct_output}.json" 2>/dev/null | \
                cut -d'"' -f4 | \
                grep -E "^[a-zA-Z0-9.-]+\.$target$" | \
                sed 's/\*\.//g' | \
                sort -u > "$ct_output"
        fi
        
        if [[ -f "$ct_output" ]]; then
            local count=$(wc -l < "$ct_output")
            module_log "SUCCESS" "Certificate transparency found $count subdomains"
            cat "$ct_output" >> "$PASSIVE_RESULTS_FILE"
        fi
    else
        module_log "WARNING" "Certificate transparency lookup failed"
    fi
    
    # Clean up
    rm -f "${ct_output}.json"
}

# Verify live subdomains
verify_live_subdomains() {
    if ! module_has_tool "httpx"; then
        module_log "WARNING" "httpx not available - skipping live verification"
        cp "$SUBDOMAIN_RESULTS_FILE" "$LIVE_SUBDOMAINS_FILE"
        return 0
    fi
    
    module_log "INFO" "Verifying live subdomains with httpx"
    
    local threads=$(module_get_config "THREADS")
    local timeout_duration=$(module_get_config "TIMEOUT")
    
    local cmd=(httpx -l "$SUBDOMAIN_RESULTS_FILE" -silent -threads "$threads" -timeout "$timeout_duration")
    
    if module_run_command $((timeout_duration * 10)) "${cmd[@]}" > "$LIVE_SUBDOMAINS_FILE"; then
        local live_count=$(wc -l < "$LIVE_SUBDOMAINS_FILE")
        local total_count=$(wc -l < "$SUBDOMAIN_RESULTS_FILE")
        module_log "SUCCESS" "Found $live_count live subdomains out of $total_count total"
        
        # Update global counter
        LIVE_SUBDOMAINS=$live_count
    else
        module_log "ERROR" "Live subdomain verification failed"
        # Fallback to all subdomains
        cp "$SUBDOMAIN_RESULTS_FILE" "$LIVE_SUBDOMAINS_FILE"
    fi
}

# Generate subdomain statistics
generate_statistics() {
    local stats_file=$(module_output_file "statistics.txt")
    local total_subdomains=$(wc -l < "$SUBDOMAIN_RESULTS_FILE")
    local live_subdomains=$(wc -l < "$LIVE_SUBDOMAINS_FILE")
    local passive_subdomains=$(wc -l < "$PASSIVE_RESULTS_FILE")
    local active_subdomains=$(wc -l < "$ACTIVE_RESULTS_FILE")
    
    {
        echo "=== Subdomain Enumeration Statistics ==="
        echo "Target: $(module_get_config 'TARGET')"
        echo "Date: $(date)"
        echo
        echo "Total Subdomains Found: $total_subdomains"
        echo "Live Subdomains: $live_subdomains"
        echo "Passive Results: $passive_subdomains"
        echo "Active Results: $active_subdomains"
        echo
        echo "=== Top Level Domains ==="
        cut -d'.' -f2- "$SUBDOMAIN_RESULTS_FILE" | sort | uniq -c | sort -nr | head -10
        echo
        echo "=== Subdomain Length Distribution ==="
        awk -F'.' '{print NF-1 " subdomains"}' "$SUBDOMAIN_RESULTS_FILE" | sort | uniq -c | sort -nr
    } > "$stats_file"
    
    module_log "INFO" "Statistics generated: $stats_file"
}

# Execute the main module functionality
module_execute() {
    local target="$1"
    local output_dir="$2"
    
    if [[ -z "$target" ]]; then
        module_log "ERROR" "Target domain is required"
        return 1
    fi
    
    module_log "INFO" "Starting subdomain enumeration for: $target"
    
    # Initialize progress tracking
    local total_steps=7
    local current_step=0
    
    # Step 1: Run passive tools
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Running passive enumeration"
    
    run_subfinder
    run_assetfinder
    run_certificate_transparency
    
    # Step 2: Run amass
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Running amass enumeration"
    run_amass
    
    # Step 3: Combine all results
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Combining results"
    
    cat "$PASSIVE_RESULTS_FILE" "$ACTIVE_RESULTS_FILE" | sort -u > "$SUBDOMAIN_RESULTS_FILE"
    
    # Step 4: Filter and validate results
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Filtering results"
    
    local temp_file=$(module_output_file "subdomains_temp.txt")
    module_filter_results "$SUBDOMAIN_RESULTS_FILE" "$temp_file" "domains"
    mv "$temp_file" "$SUBDOMAIN_RESULTS_FILE"
    
    # Step 5: Verify live subdomains
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Verifying live subdomains"
    verify_live_subdomains
    
    # Step 6: Generate statistics
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Generating statistics"
    generate_statistics
    
    # Step 7: Generate reports
    ((current_step++))
    module_progress "$current_step" "$total_steps" "Generating reports"
    
    local formats=$(module_get_config "REPORT_FORMAT")
    IFS=',' read -ra format_array <<< "$formats"
    
    for format in "${format_array[@]}"; do
        format=$(echo "$format" | tr -d ' ')
        module_generate_report "$SUBDOMAIN_RESULTS_FILE" "$format" "Subdomain Enumeration Results"
    done
    
    # Update global statistics
    TOTAL_SUBDOMAINS=$(wc -l < "$SUBDOMAIN_RESULTS_FILE")
    
    module_log "SUCCESS" "Subdomain enumeration completed - found $TOTAL_SUBDOMAINS subdomains"
    module_notify "Subdomain enumeration completed: $TOTAL_SUBDOMAINS total, $LIVE_SUBDOMAINS live" "normal"
    
    return 0
}

# Clean up resources used by the module
module_cleanup() {
    module_log "INFO" "Cleaning up subdomain enumeration module"
    
    # Remove temporary files
    local temp_files=(
        "$(module_output_file "resolvers.txt")"
        "$(module_output_file "subdomains_temp.txt")"
        "$(module_output_file "certificate_transparency.json")"
    )
    
    for file in "${temp_files[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
    
    module_log "SUCCESS" "Module cleanup completed"
    return 0
}

# Get module status/statistics
module_status() {
    local total_subdomains=0
    local live_subdomains=0
    
    if [[ -f "$SUBDOMAIN_RESULTS_FILE" ]]; then
        total_subdomains=$(wc -l < "$SUBDOMAIN_RESULTS_FILE")
    fi
    
    if [[ -f "$LIVE_SUBDOMAINS_FILE" ]]; then
        live_subdomains=$(wc -l < "$LIVE_SUBDOMAINS_FILE")
    fi
    
    echo "total_subdomains=$total_subdomains"
    echo "live_subdomains=$live_subdomains"
    echo "results_file=$SUBDOMAIN_RESULTS_FILE"
    echo "live_file=$LIVE_SUBDOMAINS_FILE"
    
    return 0
}

# If script is run directly, execute with provided arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Set up minimal environment for standalone testing
    CONFIG[TARGET]="${1:-example.com}"
    CONFIG[OUTPUT_DIR]="${2:-./test_results}"
    CONFIG[THREADS]=5
    CONFIG[TIMEOUT]=30
    CONFIG[DRY_RUN]=false
    CONFIG[SUBDOMAIN_PASSIVE_ONLY]=false
    CONFIG[REPORT_FORMAT]="txt"
    
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
    
    # Initialize and run
    module_init
    if module_check; then
        module_execute "${CONFIG[TARGET]}" "${CONFIG[OUTPUT_DIR]}"
        module_status
        module_cleanup
    else
        echo "Module check failed"
        exit 1
    fi
fi