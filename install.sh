#!/bin/bash

# Enhanced Bug Bounty Automation - Installation Script
# This script installs all required tools and dependencies

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Installation settings
INSTALL_DIR="$HOME/go/bin"
SKIP_SYSTEM_PACKAGES=false
FORCE_INSTALL=false

# Tool versions (latest stable)
declare -A TOOL_REPOS=(
    ["subfinder"]="projectdiscovery/subfinder/v2/cmd/subfinder"
    ["assetfinder"]="tomnomnom/assetfinder"
    ["amass"]="owasp-amass/amass/v4/..."
    ["httpx"]="projectdiscovery/httpx/cmd/httpx"
    ["nuclei"]="projectdiscovery/nuclei/v2/cmd/nuclei"
    ["ffuf"]="ffuf/ffuf"
    ["gobuster"]="OJ/gobuster/v3"
    ["gau"]="lc/gau/v2/cmd/gau"
    ["waybackurls"]="tomnomnom/waybackurls"
)

# System packages
SYSTEM_PACKAGES=("nmap" "masscan" "curl" "jq" "parallel" "git")

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[$timestamp] [INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] [SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] [WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] [ERROR]${NC} $message"
            ;;
    esac
}

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║              Enhanced Bug Bounty Automation                 ║
║                    Installation Script                      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if Go is installed
    if ! command -v go >/dev/null 2>&1; then
        log "ERROR" "Go is not installed. Please install Go 1.18+ from https://golang.org/dl/"
        exit 1
    fi
    
    local go_version
    go_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | head -1)
    log "SUCCESS" "Go is installed: $go_version"
    
    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        log "ERROR" "Git is not installed. Please install git first."
        exit 1
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log "INFO" "Adding $INSTALL_DIR to PATH in ~/.bashrc"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> ~/.bashrc
        export PATH="$PATH:$INSTALL_DIR"
    fi
    
    log "SUCCESS" "Prerequisites check completed"
}

install_system_packages() {
    if [[ "$SKIP_SYSTEM_PACKAGES" == "true" ]]; then
        log "INFO" "Skipping system package installation"
        return 0
    fi
    
    log "INFO" "Installing system packages..."
    
    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        log "INFO" "Detected APT package manager"
        
        # Update package list
        sudo apt-get update -qq
        
        # Install packages
        for package in "${SYSTEM_PACKAGES[@]}"; do
            if ! dpkg -l "$package" >/dev/null 2>&1; then
                log "INFO" "Installing $package..."
                sudo apt-get install -y "$package"
                log "SUCCESS" "$package installed"
            else
                log "INFO" "$package is already installed"
            fi
        done
        
    elif command -v yum >/dev/null 2>&1; then
        log "INFO" "Detected YUM package manager"
        
        for package in "${SYSTEM_PACKAGES[@]}"; do
            if ! rpm -q "$package" >/dev/null 2>&1; then
                log "INFO" "Installing $package..."
                sudo yum install -y "$package"
                log "SUCCESS" "$package installed"
            else
                log "INFO" "$package is already installed"
            fi
        done
        
    elif command -v brew >/dev/null 2>&1; then
        log "INFO" "Detected Homebrew package manager"
        
        for package in "${SYSTEM_PACKAGES[@]}"; do
            if ! brew list "$package" >/dev/null 2>&1; then
                log "INFO" "Installing $package..."
                brew install "$package"
                log "SUCCESS" "$package installed"
            else
                log "INFO" "$package is already installed"
            fi
        done
        
    else
        log "WARNING" "No supported package manager found. Please install the following packages manually:"
        printf '%s\n' "${SYSTEM_PACKAGES[@]}"
    fi
}

install_go_tools() {
    log "INFO" "Installing Go-based security tools..."
    
    for tool in "${!TOOL_REPOS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1 && [[ "$FORCE_INSTALL" != "true" ]]; then
            log "INFO" "$tool is already installed, skipping"
            continue
        fi
        
        log "INFO" "Installing $tool..."
        local repo="${TOOL_REPOS[$tool]}"
        
        if go install -v "github.com/$repo@latest"; then
            log "SUCCESS" "$tool installed successfully"
        else
            log "ERROR" "Failed to install $tool"
        fi
    done
}

verify_installation() {
    log "INFO" "Verifying installation..."
    
    local failed_tools=()
    
    # Check Go tools
    for tool in "${!TOOL_REPOS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version
            version=$("$tool" -version 2>/dev/null || "$tool" --version 2>/dev/null || echo "unknown")
            log "SUCCESS" "$tool: $version"
        else
            log "ERROR" "$tool: not found"
            failed_tools+=("$tool")
        fi
    done
    
    # Check system tools
    for package in "${SYSTEM_PACKAGES[@]}"; do
        if command -v "$package" >/dev/null 2>&1; then
            local version
            version=$("$package" --version 2>/dev/null | head -1 || echo "installed")
            log "SUCCESS" "$package: $version"
        else
            log "WARNING" "$package: not found"
        fi
    done
    
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log "ERROR" "Some tools failed to install: ${failed_tools[*]}"
        log "INFO" "You can try to install them manually or re-run with --force"
        return 1
    fi
    
    log "SUCCESS" "All tools installed successfully!"
    return 0
}

update_nuclei_templates() {
    log "INFO" "Updating Nuclei templates..."
    
    if command -v nuclei >/dev/null 2>&1; then
        if nuclei -update-templates; then
            log "SUCCESS" "Nuclei templates updated"
        else
            log "WARNING" "Failed to update Nuclei templates"
        fi
    else
        log "WARNING" "Nuclei not found, skipping template update"
    fi
}

create_config_directory() {
    log "INFO" "Setting up configuration directory..."
    
    local config_dir="$HOME/.config/bug-bounty-automation"
    mkdir -p "$config_dir"
    
    # Copy default configuration if it doesn't exist
    if [[ ! -f "$config_dir/default.conf" ]] && [[ -f "./config/default.conf" ]]; then
        cp "./config/default.conf" "$config_dir/"
        log "SUCCESS" "Default configuration copied to $config_dir"
    fi
    
    # Create symbolic link to patterns
    if [[ -d "./patterns" ]] && [[ ! -L "$config_dir/patterns" ]]; then
        ln -s "$(pwd)/patterns" "$config_dir/patterns"
        log "SUCCESS" "Secret patterns linked to $config_dir"
    fi
}

show_usage() {
    cat << EOF
Enhanced Bug Bounty Automation - Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    --skip-system-packages    Skip installation of system packages (nmap, etc.)
    --force                   Force reinstallation of existing tools
    --install-dir DIR         Custom installation directory (default: $HOME/go/bin)
    --help                    Show this help message

EXAMPLES:
    $0                        # Full installation
    $0 --skip-system-packages # Skip system packages
    $0 --force                # Force reinstall all tools

REQUIREMENTS:
    - Go 1.18+ installed
    - Internet connection
    - sudo access (for system packages)

EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-system-packages)
                SKIP_SYSTEM_PACKAGES=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    log "INFO" "Starting installation process..."
    log "INFO" "Installation directory: $INSTALL_DIR"
    
    # Run installation steps
    check_prerequisites
    install_system_packages
    install_go_tools
    update_nuclei_templates
    create_config_directory
    
    if verify_installation; then
        echo
        log "SUCCESS" "Installation completed successfully!"
        echo
        echo -e "${GREEN}Next steps:${NC}"
        echo "1. Restart your terminal or run: source ~/.bashrc"
        echo "2. Test the installation: ./bug_bounty_automation.sh --help"
        echo "3. Run your first scan: ./bug_bounty_automation.sh -t example.com -n"
        echo
        echo -e "${BLUE}Happy Bug Hunting! 🐛🔍${NC}"
    else
        echo
        log "ERROR" "Installation completed with errors. Please check the output above."
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi