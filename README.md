# Enhanced Bug Bounty Automation Script

A comprehensive, modular bug bounty automation framework for responsible security testing and reconnaissance.

![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)

## 🚀 Features

### Core Capabilities
- **Modular Architecture**: Pluggable modules for easy customization and extension
- **Comprehensive Reconnaissance**: Subdomain enumeration, port scanning, directory discovery, technology detection
- **Multiple Output Formats**: TXT, Markdown, HTML, JSON reports
- **Resource Monitoring**: Real-time CPU, memory, and disk usage monitoring
- **Progress Tracking**: Progress bars and estimated completion times
- **Error Resilience**: Centralized error handling with detailed reporting
- **Notification System**: Telegram, Discord, email, and webhook notifications

### Security Features
- **Secret Detection**: Automatic detection of API keys, tokens, and credentials
- **OSINT-Safe Mode**: Passive reconnaissance to avoid detection
- **Rate Limiting**: Configurable request rate limiting
- **Privacy Controls**: Data anonymization and privacy-aware logging

### Performance Optimizations
- **Parallel Execution**: GNU Parallel and xargs support for optimal performance
- **Resource Throttling**: Automatic throttling based on system resource usage
- **Caching System**: Intelligent caching to avoid duplicate work
- **Memory Optimization**: Efficient handling of large subdomain lists

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Modules](#modules)
- [Usage Examples](#usage-examples)
- [Advanced Features](#advanced-features)
- [Custom Modules](#custom-modules)
- [Troubleshooting](#troubleshooting)
- [Safety Guidelines](#safety-guidelines)
- [Contributing](#contributing)
- [License](#license)

## 🛠 Installation

### Prerequisites

**Required Tools:**
```bash
# Core tools (at least one from each category)
# Subdomain enumeration
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install -v github.com/owasp-amass/amass/v4/...@master

# HTTP probing
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# Port scanning
sudo apt-get install nmap masscan

# Directory discovery
go install github.com/ffuf/ffuf@latest
go install github.com/OJ/gobuster/v3@latest

# Vulnerability scanning
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

# Additional tools
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
```

**Optional Dependencies:**
```bash
# For enhanced parallel processing
sudo apt-get install parallel

# For JSON processing
sudo apt-get install jq

# For notifications
sudo apt-get install mailutils  # for email notifications
```

### Installation Steps

1. **Clone the repository:**
```bash
git clone https://github.com/Mr-Crazy8/Write_ups.git
cd Write_ups
```

2. **Make the script executable:**
```bash
chmod +x bug_bounty_automation.sh
```

3. **Verify installation:**
```bash
./bug_bounty_automation.sh --help
```

## 🚀 Quick Start

### Basic Usage

**Simple scan:**
```bash
./bug_bounty_automation.sh -t example.com
```

**Verbose scan with custom output directory:**
```bash
./bug_bounty_automation.sh -t example.com -o ./results -v
```

**Quick reconnaissance (passive only):**
```bash
./bug_bounty_automation.sh -t example.com -c config/quick_scan.conf
```

### Configuration Templates

The script comes with pre-configured templates for different use cases:

- **`config/quick_scan.conf`** - Fast, passive reconnaissance
- **`config/comprehensive.conf`** - Full-featured scanning with all modules
- **`config/stealth.conf`** - OSINT-safe reconnaissance with minimal footprint

## ⚙️ Configuration

### Configuration File Format

Configuration files use simple `KEY=VALUE` format:

```bash
# Target configuration
TARGET="example.com"
OUTPUT_DIR="./results"

# Execution settings
THREADS=10
TIMEOUT=30
VERBOSE=true

# Module selection
MODULES_ENABLED="subdomain,port_scan,directory_scan"

# Report formats
REPORT_FORMAT="txt,markdown,html"
```

### Key Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `TARGET` | Target domain (required) | "" |
| `OUTPUT_DIR` | Output directory for results | "./results" |
| `THREADS` | Number of parallel threads | 10 |
| `MODULES_ENABLED` | Comma-separated list of modules | "subdomain,port_scan,directory_scan,tech_detection" |
| `REPORT_FORMAT` | Output formats | "txt,markdown" |
| `NOTIFICATION_ENABLED` | Enable notifications | false |
| `SECRET_DETECTION` | Enable secret detection | true |
| `RESOURCE_MONITORING` | Monitor system resources | true |

### Environment Variables

You can also use environment variables:

```bash
export BOUNTY_TARGET="example.com"
export BOUNTY_OUTPUT_DIR="/tmp/results"
export BOUNTY_THREADS=20

./bug_bounty_automation.sh
```

## 🧩 Modules

### Available Modules

#### 1. Subdomain Enumeration (`subdomain`)
- **Tools Used**: subfinder, assetfinder, amass, certificate transparency
- **Features**: Passive and active enumeration, live verification
- **Output**: Lists of all discovered and live subdomains

#### 2. Port Scanning (`port_scan`)
- **Tools Used**: nmap, masscan
- **Features**: TCP/UDP scanning, service detection, version detection
- **Output**: Open ports with service information

#### 3. Directory Discovery (`directory_scan`)
- **Tools Used**: ffuf, gobuster
- **Features**: Directory and file discovery, custom wordlists
- **Output**: Discovered directories and files with status codes

#### 4. Technology Detection (`tech_detection`)
- **Tools Used**: httpx, custom fingerprinting
- **Features**: Web technology identification, security headers analysis
- **Output**: Technology stack and security posture information

#### 5. Vulnerability Scanning (`vulnerability_scan`)
- **Tools Used**: nuclei
- **Features**: CVE detection, security misconfiguration identification
- **Output**: Identified vulnerabilities with severity ratings

### Module Configuration

Enable/disable modules:
```bash
# Enable specific modules
MODULES_ENABLED="subdomain,tech_detection"

# Enable all modules
MODULES_ENABLED="subdomain,port_scan,directory_scan,tech_detection,vulnerability_scan"
```

## 💡 Usage Examples

### Basic Reconnaissance

```bash
# Basic subdomain enumeration
./bug_bounty_automation.sh -t example.com -m subdomain

# Subdomain enumeration with technology detection
./bug_bounty_automation.sh -t example.com -m subdomain,tech_detection -v

# Full reconnaissance with progress tracking
./bug_bounty_automation.sh -t example.com -m subdomain,port_scan,directory_scan -v
```

### Advanced Usage

```bash
# Comprehensive scan with notifications
./bug_bounty_automation.sh -t example.com \
  -c config/comprehensive.conf \
  --notify \
  -o /tmp/results

# Stealth reconnaissance
./bug_bounty_automation.sh -t example.com \
  -c config/stealth.conf \
  --no-monitoring

# Custom thread count and output format
./bug_bounty_automation.sh -t example.com \
  -T 20 \
  -f markdown,html,json \
  -o ./custom_results
```

### Dry Run Mode

Test your configuration without executing:
```bash
./bug_bounty_automation.sh -t example.com -n
```

## 🔧 Advanced Features

### Notification System

Configure notifications to stay informed about scan progress:

**Telegram:**
```bash
NOTIFICATION_ENABLED=true
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

**Discord:**
```bash
NOTIFICATION_ENABLED=true
DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
```

**Email:**
```bash
NOTIFICATION_ENABLED=true
EMAIL="your@email.com"
```

### Resource Monitoring

The script automatically monitors system resources:

```bash
# Set resource thresholds
MAX_CPU_USAGE=80      # Warn if CPU usage exceeds 80%
MAX_MEMORY_USAGE=80   # Warn if memory usage exceeds 80%
MAX_DISK_USAGE=90     # Warn if disk usage exceeds 90%

# Enable/disable monitoring
RESOURCE_MONITORING=true
```

### Secret Detection

Automatically scan discovered content for sensitive information:

```bash
# Enable secret detection
SECRET_DETECTION=true

# Custom patterns file
SECRET_PATTERNS_FILE="/path/to/custom/patterns.txt"
```

Common secrets detected:
- API keys (AWS, Google, GitHub, etc.)
- Database passwords
- JWT tokens
- Private keys
- Email addresses
- Internal IP addresses

### Parallel Processing

Optimize performance with parallel execution:

```bash
# Use GNU Parallel (recommended)
USE_GNU_PARALLEL=true

# Adjust thread count based on system capabilities
THREADS=20

# Custom timeout for long-running operations
TIMEOUT=60
```

## 🔌 Custom Modules

### Creating a Custom Module

1. **Create module directory:**
```bash
mkdir modules/custom/my_module
```

2. **Create module script:**
```bash
cat > modules/custom/my_module/my_module.sh << 'EOF'
#!/bin/bash

# Module metadata
MODULE_NAME="my_module"
MODULE_VERSION="1.0.0"
MODULE_DESCRIPTION="Custom module description"
MODULE_AUTHOR="Your Name"

# Source the module interface
source "$(dirname "${BASH_SOURCE[0]}")/../../module_interface.sh"

# Implement required functions
module_init() {
    module_log "INFO" "Initializing custom module"
    return 0
}

module_check() {
    module_log "INFO" "Checking prerequisites"
    return 0
}

module_execute() {
    local target="$1"
    local output_dir="$2"
    
    module_log "INFO" "Executing custom module for $target"
    
    # Your custom logic here
    local results_file=$(module_output_file "results.txt")
    echo "Custom results for $target" > "$results_file"
    
    module_generate_report "$results_file" "txt" "Custom Module Results"
    
    return 0
}

module_cleanup() {
    module_log "INFO" "Cleaning up custom module"
    return 0
}

module_status() {
    echo "custom_results=1"
    return 0
}
EOF
```

3. **Make executable:**
```bash
chmod +x modules/custom/my_module/my_module.sh
```

4. **Register module:**
Add your module to the main script's module loading logic.

### Module Interface

All modules must implement these functions:

- `module_init()` - Initialize the module
- `module_check()` - Check prerequisites
- `module_execute(target, output_dir)` - Main execution
- `module_cleanup()` - Clean up resources
- `module_status()` - Return status information

### Available Helper Functions

- `module_log(level, message)` - Logging with module prefix
- `module_progress(current, total, operation)` - Progress reporting
- `module_output_file(filename)` - Get output file path
- `module_run_command(timeout, command...)` - Execute command with timeout
- `module_generate_report(file, format, title)` - Generate formatted report

## 🐛 Troubleshooting

### Common Issues

**1. "Tool not found" errors:**
```bash
# Check if tools are in PATH
which subfinder httpx nmap

# Install missing tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
```

**2. Permission denied errors:**
```bash
# Make script executable
chmod +x bug_bounty_automation.sh

# For nmap privileged scanning
sudo setcap cap_net_raw+ep $(which nmap)
```

**3. "Configuration validation failed":**
```bash
# Check configuration syntax
bash -n config/your_config.conf

# Validate target format
echo "example.com" | grep -E '^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$'
```

**4. High resource usage:**
```bash
# Reduce thread count
THREADS=5

# Enable resource monitoring
RESOURCE_MONITORING=true
MAX_CPU_USAGE=60
```

### Debug Mode

Enable debug output for troubleshooting:
```bash
./bug_bounty_automation.sh -t example.com -d
```

### Log Files

Check log files for detailed information:
```bash
# Main log
tail -f results/automation.log

# Module-specific logs
ls results/*/

# Error summary
cat results/reports/errors_*.txt
```

## 🛡️ Safety Guidelines

### Responsible Disclosure

- **Only test domains you own or have explicit permission to test**
- Follow responsible disclosure practices for vulnerabilities
- Respect bug bounty program rules and scope
- Document and report findings appropriately

### Rate Limiting and Stealth

```bash
# Use stealth configuration for passive reconnaissance
./bug_bounty_automation.sh -t example.com -c config/stealth.conf

# Configure rate limiting
RATE_LIMIT=5                    # Requests per second
MAX_REQUESTS_PER_HOST=30        # Requests per host per minute
OSINT_SAFE_MODE=true           # Passive techniques only
```

### Legal Considerations

- **Always obtain proper authorization before testing**
- Respect robots.txt and security policies
- Be aware of local laws and regulations
- Use the script ethically and responsibly

### Best Practices

1. **Start with passive reconnaissance**
2. **Use rate limiting in production environments**
3. **Monitor resource usage to avoid system overload**
4. **Keep logs for audit purposes**
5. **Regularly update tools and dependencies**

## 📊 Output and Reporting

### Directory Structure

```
results/
├── automation.log              # Main log file
├── subdomains/                # Subdomain enumeration results
│   ├── subdomains_all.txt
│   ├── subdomains_live.txt
│   └── report.md
├── ports/                     # Port scanning results
│   ├── open_ports.txt
│   └── nmap_results.xml
├── directories/               # Directory discovery results
│   ├── directories.txt
│   └── ffuf_results.json
├── technologies/              # Technology detection results
│   ├── technologies.txt
│   └── security_headers.txt
├── vulnerabilities/           # Vulnerability scan results
│   ├── nuclei_results.txt
│   └── high_severity.txt
├── secrets/                   # Secret detection results
│   ├── api_keys.txt
│   └── credentials.txt
└── reports/                   # Final reports
    ├── executive_summary.md
    ├── technical_report.html
    └── statistics.txt
```

### Report Formats

**Text Report:**
```
=== Bug Bounty Automation Results ===
Target: example.com
Date: 2025-08-29

=== Summary ===
Subdomains Found: 245
Live Subdomains: 178
Open Ports: 89
Directories: 156
Vulnerabilities: 12
```

**Markdown Report:**
```markdown
# Bug Bounty Results for example.com

## Executive Summary
- **Target**: example.com
- **Scan Date**: 2025-08-29
- **Subdomains**: 245 found, 178 live
- **Security Issues**: 12 vulnerabilities identified

## Findings
### High Severity
- SQL Injection in /admin/login.php
- XSS in /search?q=

### Medium Severity
- Missing security headers
- Outdated software versions
```

**HTML Report:**
Interactive HTML reports with charts, graphs, and detailed findings.

**JSON Report:**
```json
{
  "scan_info": {
    "target": "example.com",
    "date": "2025-08-29T10:30:00Z",
    "duration": "02:15:30"
  },
  "results": {
    "subdomains": 245,
    "live_subdomains": 178,
    "vulnerabilities": 12
  }
}
```

## 🔄 Integration

### CI/CD Integration

**GitHub Actions Example:**
```yaml
name: Bug Bounty Automation
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install tools
        run: |
          go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
          go install github.com/projectdiscovery/httpx/cmd/httpx@latest
      - name: Run scan
        run: |
          ./bug_bounty_automation.sh -t ${{ secrets.TARGET_DOMAIN }} \
            -c config/quick_scan.conf \
            --notify
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

### Database Integration

```bash
# Enable database storage
SAVE_TO_DATABASE=true
DATABASE_URL="postgresql://user:pass@localhost:5432/bounty"
```

### Cloud Storage

```bash
# Enable cloud upload
CLOUD_UPLOAD=true
CLOUD_PROVIDER="aws"
CLOUD_BUCKET="my-bounty-results"
```

## 📈 Performance Tuning

### System Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4GB
- Disk: 10GB free space
- Network: Stable internet connection

**Recommended:**
- CPU: 8+ cores
- RAM: 16GB+
- Disk: 50GB+ SSD
- Network: High-speed internet

### Optimization Tips

1. **Use SSD storage for better I/O performance**
2. **Adjust thread count based on CPU cores**
3. **Enable caching for repeated scans**
4. **Use GNU Parallel for better parallelization**
5. **Monitor resource usage and adjust accordingly**

### Thread Configuration

```bash
# Conservative (low-end systems)
THREADS=5

# Balanced (most systems)
THREADS=10

# Aggressive (high-end systems)
THREADS=20

# Auto-detect (recommended)
THREADS=$(nproc)
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style

- Follow bash best practices
- Use consistent indentation (4 spaces)
- Add comments for complex logic
- Include error handling
- Write modular, reusable code

## 📝 Changelog

### v3.0.0 (2025-08-29)
- Complete rewrite with modular architecture
- Added comprehensive configuration system
- Implemented resource monitoring
- Added notification system
- Enhanced error handling and reporting
- Added multiple output formats
- Improved parallel processing
- Added secret detection capabilities

### v2.0.0 (Previous Version)
- Initial enhanced automation features
- Basic module system
- Improved error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚖️ Disclaimer

This tool is for educational and authorized testing purposes only. Users are responsible for ensuring they have proper authorization before testing any systems. The authors are not responsible for any misuse or damage caused by this tool.

## 🙏 Acknowledgments

- [ProjectDiscovery](https://projectdiscovery.io/) for their excellent security tools
- Bug bounty community for feedback and testing
- Open source contributors and maintainers

## 📞 Support

- **Documentation**: This README and inline code comments
- **Issues**: [GitHub Issues](https://github.com/Mr-Crazy8/Write_ups/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Mr-Crazy8/Write_ups/discussions)

---

**Happy Bug Hunting! 🐛🔍**