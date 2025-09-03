# WordPress Subdomain Scanner & Vulnerability Assessment Tool

A comprehensive Python script designed for bug bounty hunters and security researchers to discover subdomains, identify WordPress installations, and find sensitive files or misconfigurations.

## 🎯 Features

### Subdomain Discovery
- **DNS Brute Force**: Uses a curated wordlist of common subdomains
- **Certificate Transparency**: Queries crt.sh for historical SSL certificate data
- **Multi-threaded**: Fast concurrent scanning with configurable thread count

### WordPress Detection
- **Intelligent Detection**: Identifies WordPress installations using multiple indicators
- **File Enumeration**: Scans for common WordPress files and directories
- **Version Detection**: Attempts to identify WordPress versions from standard files

### 403 Bypass Techniques
- **Header Manipulation**: Tests various HTTP headers to bypass access restrictions
- **Path Manipulation**: Uses URL encoding and path traversal techniques
- **User-Agent Spoofing**: Mimics legitimate bots and browsers

### Sensitive File Discovery
- **Configuration Files**: Searches for exposed config files (.env, config.php, etc.)
- **Backup Files**: Identifies backup databases and configuration backups
- **Debug Files**: Finds debug logs and information disclosure files
- **Admin Panels**: Locates administrative interfaces and control panels

### Comprehensive Reporting
- **Color-coded Output**: Easy-to-read terminal output with status indicators
- **JSON Reports**: Detailed machine-readable reports for further analysis
- **Categorized Findings**: Organized by risk level and file type

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/Mr-Crazy8/Write_ups.git
cd Write_ups

# Install dependencies
pip3 install -r requirements.txt

# Make the script executable
chmod +x subdomain_wordpress_scanner.py
```

### Basic Usage

```bash
# Scan a domain with default settings
python3 subdomain_wordpress_scanner.py -d example.com

# Scan with custom thread count and timeout
python3 subdomain_wordpress_scanner.py -d target.com -t 100 --timeout 15
```

### Command Line Options

```
-d, --domain     Target domain to scan (required)
-t, --threads    Number of concurrent threads (default: 50)
--timeout        Request timeout in seconds (default: 10)
```

## 📊 Sample Output

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    WordPress Subdomain Scanner & Recon Tool                 ║
║                        For Bug Bounty & Security Research                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

Target Domain: example.com
Threads: 50
Timeout: 10s

[+] Starting DNS subdomain enumeration...
[✓] Found: www.example.com
[✓] Found: blog.example.com
[✓] Found: admin.example.com

[+] Checking Certificate Transparency logs...
[✓] Found: api.example.com
[✓] Found: staging.example.com

[*] Scanning subdomain: blog.example.com
[WordPress] Detected on https://blog.example.com
[✓] Found: https://blog.example.com/wp-admin/ (200)
[!] Forbidden: https://blog.example.com/wp-config.php (403) - Attempting bypass...
[✓] 403 Bypassed: https://blog.example.com/wp-config.php - ['Header bypass: {X-Forwarded-For: 127.0.0.1}']

[!!!] CRITICAL FINDINGS - Potential Sensitive Data Exposure
🚨 https://blog.example.com/.env
🚨 https://staging.example.com/config.php

[!] 403 BYPASS SUCCESSFUL
🔓 https://blog.example.com/wp-config.php - ['Header bypass: {X-Forwarded-For: 127.0.0.1}']
```

## 🔍 What the Script Searches For

### WordPress-Specific Files
- `wp-config.php` and backup variants
- `wp-admin/`, `wp-content/`, `wp-includes/`
- `xmlrpc.php`, `wp-login.php`
- WordPress debug logs and cache files
- Theme and plugin directories

### Sensitive Files & Directories
- Environment files (`.env`, `.env.local`, etc.)
- Configuration files (`config.php`, `database.php`)
- Backup files (`backup.sql`, `dump.sql`)
- Administrative interfaces (`admin/`, `cpanel/`)
- Server information endpoints (`phpinfo.php`, `server-status`)
- Version control files (`.git/`, `.svn/`)

### 403 Bypass Techniques
- **IP Header Spoofing**: `X-Forwarded-For`, `X-Real-IP`, `X-Originating-IP`
- **Host Header Manipulation**: `X-Forwarded-Host`, `X-Remote-Addr`
- **User-Agent Spoofing**: GoogleBot, legitimate browser agents
- **URL Encoding**: `%2e`, `%252e`, double encoding
- **Path Traversal**: `../`, `./`, `//`, null bytes

## 📋 Sample Report Structure

The tool generates detailed JSON reports containing:

```json
{
  "target_domain": "example.com",
  "scan_timestamp": "2024-01-15 14:30:22",
  "subdomains_found": ["www.example.com", "blog.example.com"],
  "wordpress_sites": [
    {
      "url": "https://blog.example.com",
      "subdomain": "blog.example.com",
      "status": 200,
      "wp_files_detected": ["wp-admin/", "xmlrpc.php"],
      "findings": [...]
    }
  ],
  "total_findings": 15,
  "findings": [
    {
      "url": "https://blog.example.com/wp-config.php",
      "status": 403,
      "type": "wordpress_file",
      "bypass_methods": ["Header bypass: {X-Forwarded-For: 127.0.0.1}"]
    }
  ]
}
```

## ⚖️ Legal Disclaimer

**IMPORTANT**: This tool is designed for authorized security testing only.

- ✅ **Authorized Use**: Testing your own domains or with explicit written permission
- ✅ **Bug Bounty Programs**: Following responsible disclosure guidelines
- ✅ **Educational Purposes**: Learning about web security in controlled environments
- ❌ **Unauthorized Scanning**: Testing domains without permission
- ❌ **Malicious Intent**: Using findings for harmful purposes

Always ensure you have proper authorization before scanning any domain. Unauthorized scanning may violate:
- Computer Fraud and Abuse Act (CFAA)
- Terms of Service agreements
- Local and international laws

## 🛡️ Responsible Disclosure

When using this tool for bug bounty programs:

1. **Follow Program Guidelines**: Respect scope and testing limitations
2. **Document Findings**: Take screenshots and detailed notes
3. **Report Responsibly**: Use designated channels for vulnerability reports
4. **Avoid Data Access**: Don't download or access sensitive data
5. **Minimize Impact**: Use reasonable request rates and timeouts

## 🔧 Customization

### Adding Custom Wordlists

Modify the `subdomain_wordlist` in the script to include domain-specific subdomains:

```python
self.subdomain_wordlist = [
    'www', 'api', 'admin', 'blog',
    # Add your custom subdomains here
    'internal', 'test', 'dev'
]
```

### Custom File Lists

Add specific files to check by modifying `wp_files` or `sensitive_files`:

```python
self.sensitive_files.extend([
    'custom-config.php',
    'application.properties',
    'local-settings.php'
])
```

### Custom Bypass Techniques

Add new bypass methods by extending the headers or paths:

```python
self.bypass_headers.append({'X-Custom-Header': 'bypass-value'})
self.bypass_paths.append('/custom/../bypass/')
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Follow Python best practices
5. Submit a pull request with clear description

## 📝 Changelog

### v1.0.0 (2024-01-15)
- Initial release
- Subdomain discovery via DNS and Certificate Transparency
- WordPress detection and file enumeration
- 403 bypass techniques implementation
- Comprehensive reporting system
- Multi-threaded scanning capabilities

## 📚 Resources

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [Bug Bounty Methodology](https://github.com/jhaddix/tbhm)
- [WordPress Security Documentation](https://wordpress.org/support/article/hardening-wordpress/)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

## 🔗 Related Tools

Consider combining this tool with:
- **Subfinder**: Advanced subdomain discovery
- **httpx**: Fast HTTP probing
- **Nuclei**: Vulnerability scanning templates
- **Dirsearch**: Directory brute forcing
- **WPScan**: WordPress-specific vulnerability scanner

---

**Remember**: With great power comes great responsibility. Use this tool ethically and legally.