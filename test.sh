#!/bin/bash

# Test Script for Enhanced Bug Bounty Automation
# Comprehensive testing of all components and functionality

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TARGET="example.com"
TEST_OUTPUT_DIR="/tmp/bounty_test_$(date +%s)"
MAIN_SCRIPT="$SCRIPT_DIR/bug_bounty_automation.sh"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
declare -a FAILED_TESTS=()

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%H:%M:%S")
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[$timestamp] [INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] [PASS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] [WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] [FAIL]${NC} $message"
            ;;
    esac
}

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║              Enhanced Bug Bounty Automation                 ║
║                      Test Suite                             ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_TOTAL++))
    log "INFO" "Running test: $test_name"
    
    if "$test_function"; then
        ((TESTS_PASSED++))
        log "SUCCESS" "$test_name"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        log "ERROR" "$test_name"
    fi
}

# Setup and cleanup functions
setup_test_environment() {
    log "INFO" "Setting up test environment..."
    
    # Create test output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    
    # Verify main script exists and is executable
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        log "ERROR" "Main script not found: $MAIN_SCRIPT"
        exit 1
    fi
    
    if [[ ! -x "$MAIN_SCRIPT" ]]; then
        log "ERROR" "Main script is not executable: $MAIN_SCRIPT"
        exit 1
    fi
    
    log "SUCCESS" "Test environment setup completed"
}

cleanup_test_environment() {
    log "INFO" "Cleaning up test environment..."
    
    # Remove test output directory
    if [[ -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
    
    log "SUCCESS" "Test environment cleanup completed"
}

# Individual test functions
test_help_output() {
    "$MAIN_SCRIPT" --help >/dev/null 2>&1
}

test_invalid_arguments() {
    ! "$MAIN_SCRIPT" --invalid-argument >/dev/null 2>&1
}

test_missing_target() {
    ! "$MAIN_SCRIPT" -o "$TEST_OUTPUT_DIR" >/dev/null 2>&1
}

test_invalid_target() {
    ! "$MAIN_SCRIPT" -t "invalid..domain" -n >/dev/null 2>&1
}

test_dry_run_mode() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -n >/dev/null 2>&1
}

test_verbose_mode() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -v -n >/dev/null 2>&1
}

test_debug_mode() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -d -n >/dev/null 2>&1
}

test_custom_threads() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -T 5 -n >/dev/null 2>&1
}

test_custom_output_dir() {
    local custom_dir="$TEST_OUTPUT_DIR/custom"
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$custom_dir" -n >/dev/null 2>&1
    [[ -d "$custom_dir" ]]
}

test_module_selection() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -m subdomain,tech_detection -n >/dev/null 2>&1
}

test_report_formats() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -f txt,markdown,json -n >/dev/null 2>&1
}

test_configuration_validation() {
    # Test valid configuration
    echo "TARGET=$TEST_TARGET" > "$TEST_OUTPUT_DIR/valid.conf"
    echo "THREADS=10" >> "$TEST_OUTPUT_DIR/valid.conf"
    echo "VERBOSE=true" >> "$TEST_OUTPUT_DIR/valid.conf"
    
    "$MAIN_SCRIPT" -c "$TEST_OUTPUT_DIR/valid.conf" -n >/dev/null 2>&1
}

test_invalid_configuration() {
    # Test invalid configuration
    echo "TARGET=" > "$TEST_OUTPUT_DIR/invalid.conf"
    echo "THREADS=abc" >> "$TEST_OUTPUT_DIR/invalid.conf"
    echo "VERBOSE=maybe" >> "$TEST_OUTPUT_DIR/invalid.conf"
    
    ! "$MAIN_SCRIPT" -c "$TEST_OUTPUT_DIR/invalid.conf" -n >/dev/null 2>&1
}

test_config_templates() {
    local config_files=("config/quick_scan.conf" "config/comprehensive.conf" "config/stealth.conf")
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$config_file" ]]; then
            # Set target in config
            local temp_config="$TEST_OUTPUT_DIR/$(basename "$config_file")"
            cp "$SCRIPT_DIR/$config_file" "$temp_config"
            sed -i "s/TARGET=\"\"/TARGET=\"$TEST_TARGET\"/" "$temp_config"
            
            if ! "$MAIN_SCRIPT" -c "$temp_config" -n >/dev/null 2>&1; then
                return 1
            fi
        else
            log "WARNING" "Config template not found: $config_file"
            return 1
        fi
    done
    
    return 0
}

test_module_interface() {
    local module_interface="$SCRIPT_DIR/modules/module_interface.sh"
    
    if [[ ! -f "$module_interface" ]]; then
        return 1
    fi
    
    # Test if module interface can be sourced
    bash -n "$module_interface"
}

test_subdomain_module() {
    local subdomain_module="$SCRIPT_DIR/modules/subdomain/subdomain.sh"
    
    if [[ ! -f "$subdomain_module" ]]; then
        return 1
    fi
    
    # Test syntax
    bash -n "$subdomain_module"
}

test_custom_module_example() {
    local custom_module="$SCRIPT_DIR/examples/custom_module_example.sh"
    
    if [[ ! -f "$custom_module" ]]; then
        return 1
    fi
    
    # Test syntax
    bash -n "$custom_module"
}

test_secret_patterns() {
    local patterns_file="$SCRIPT_DIR/patterns/secrets.txt"
    
    if [[ ! -f "$patterns_file" ]]; then
        return 1
    fi
    
    # Test if patterns file has content
    [[ $(wc -l < "$patterns_file") -gt 10 ]]
}

test_output_directory_structure() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -n >/dev/null 2>&1
    
    # Check if required directories are created
    local required_dirs=("subdomains" "ports" "directories" "technologies" "vulnerabilities" "secrets" "reports" "logs")
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$TEST_OUTPUT_DIR/$dir" ]]; then
            return 1
        fi
    done
    
    return 0
}

test_log_file_creation() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -n >/dev/null 2>&1
    
    # Check if log file is created
    [[ -f "$TEST_OUTPUT_DIR/automation.log" ]]
}

test_notification_flags() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" --notify -n >/dev/null 2>&1 &&
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" --no-secrets -n >/dev/null 2>&1 &&
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" --no-monitoring -n >/dev/null 2>&1
}

test_install_script() {
    local install_script="$SCRIPT_DIR/install.sh"
    
    if [[ ! -f "$install_script" ]]; then
        return 1
    fi
    
    # Test syntax and help output
    bash -n "$install_script" &&
    "$install_script" --help >/dev/null 2>&1
}

test_readme_exists() {
    [[ -f "$SCRIPT_DIR/README.md" ]] && [[ $(wc -l < "$SCRIPT_DIR/README.md") -gt 100 ]]
}

# Performance and stress tests
test_large_thread_count() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" -T 100 -n >/dev/null 2>&1
}

test_all_modules_enabled() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" \
        -m subdomain,port_scan,directory_scan,tech_detection,vulnerability_scan \
        -n >/dev/null 2>&1
}

test_all_report_formats() {
    "$MAIN_SCRIPT" -t "$TEST_TARGET" -o "$TEST_OUTPUT_DIR" \
        -f txt,markdown,html,json \
        -n >/dev/null 2>&1
}

# Main test execution
run_all_tests() {
    log "INFO" "Starting comprehensive test suite..."
    
    # Basic functionality tests
    run_test "Help output" test_help_output
    run_test "Invalid arguments handling" test_invalid_arguments
    run_test "Missing target detection" test_missing_target
    run_test "Invalid target detection" test_invalid_target
    run_test "Dry run mode" test_dry_run_mode
    run_test "Verbose mode" test_verbose_mode
    run_test "Debug mode" test_debug_mode
    
    # Configuration tests
    run_test "Custom threads" test_custom_threads
    run_test "Custom output directory" test_custom_output_dir
    run_test "Module selection" test_module_selection
    run_test "Report formats" test_report_formats
    run_test "Configuration validation" test_configuration_validation
    run_test "Invalid configuration detection" test_invalid_configuration
    run_test "Configuration templates" test_config_templates
    
    # Module system tests
    run_test "Module interface" test_module_interface
    run_test "Subdomain module" test_subdomain_module
    run_test "Custom module example" test_custom_module_example
    
    # File and structure tests
    run_test "Secret patterns file" test_secret_patterns
    run_test "Output directory structure" test_output_directory_structure
    run_test "Log file creation" test_log_file_creation
    run_test "Notification flags" test_notification_flags
    run_test "Install script" test_install_script
    run_test "README documentation" test_readme_exists
    
    # Performance tests
    run_test "Large thread count" test_large_thread_count
    run_test "All modules enabled" test_all_modules_enabled
    run_test "All report formats" test_all_report_formats
}

show_test_results() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        Test Results                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}Total Tests:   $TESTS_TOTAL${NC}"
    echo -e "${GREEN}Passed:        $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:        $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "${RED}  - $test${NC}"
        done
    fi
    
    echo
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    if [[ $success_rate -eq 100 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Success rate: $success_rate%${NC}"
        return 0
    elif [[ $success_rate -ge 90 ]]; then
        echo -e "${YELLOW}⚠️  Most tests passed. Success rate: $success_rate%${NC}"
        return 1
    else
        echo -e "${RED}❌ Multiple tests failed. Success rate: $success_rate%${NC}"
        return 1
    fi
}

# Test specific functionality if requested
run_specific_test() {
    local test_name="$1"
    
    case "$test_name" in
        "basic")
            run_test "Help output" test_help_output
            run_test "Dry run mode" test_dry_run_mode
            run_test "Configuration validation" test_configuration_validation
            ;;
        "config")
            run_test "Configuration validation" test_configuration_validation
            run_test "Invalid configuration detection" test_invalid_configuration
            run_test "Configuration templates" test_config_templates
            ;;
        "modules")
            run_test "Module interface" test_module_interface
            run_test "Subdomain module" test_subdomain_module
            run_test "Custom module example" test_custom_module_example
            ;;
        "performance")
            run_test "Large thread count" test_large_thread_count
            run_test "All modules enabled" test_all_modules_enabled
            run_test "All report formats" test_all_report_formats
            ;;
        *)
            log "ERROR" "Unknown test suite: $test_name"
            echo "Available test suites: basic, config, modules, performance"
            exit 1
            ;;
    esac
}

show_usage() {
    cat << EOF
Enhanced Bug Bounty Automation - Test Suite

Usage: $0 [OPTIONS] [TEST_SUITE]

OPTIONS:
    --target DOMAIN      Test target domain (default: example.com)
    --output-dir DIR     Test output directory (default: /tmp/bounty_test_*)
    --help               Show this help message

TEST_SUITES:
    all                  Run all tests (default)
    basic                Run basic functionality tests
    config               Run configuration tests
    modules              Run module system tests
    performance          Run performance tests

EXAMPLES:
    $0                   # Run all tests
    $0 basic             # Run basic tests only
    $0 --target test.com # Run with custom target

EOF
}

main() {
    local test_suite="all"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TEST_TARGET="$2"
                shift 2
                ;;
            --output-dir)
                TEST_OUTPUT_DIR="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            all|basic|config|modules|performance)
                test_suite="$1"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    log "INFO" "Test target: $TEST_TARGET"
    log "INFO" "Test output: $TEST_OUTPUT_DIR"
    log "INFO" "Test suite: $test_suite"
    
    # Setup test environment
    setup_test_environment
    
    # Ensure cleanup on exit
    trap cleanup_test_environment EXIT
    
    # Run tests
    if [[ "$test_suite" == "all" ]]; then
        run_all_tests
    else
        run_specific_test "$test_suite"
    fi
    
    # Show results
    if show_test_results; then
        log "SUCCESS" "Test suite completed successfully!"
        exit 0
    else
        log "ERROR" "Test suite completed with failures!"
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi