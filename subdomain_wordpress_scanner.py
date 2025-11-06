#!/usr/bin/env python3
"""
WordPress Subdomain Scanner and Vulnerability Assessment Tool
For Bug Bounty Programs - Educational and Legal Use Only

Author: Mr-Crazy8
Purpose: Discover subdomains, identify WordPress installations, and find sensitive files/configs
Features: 403 bypass techniques, WordPress-specific enumeration, structured reporting
"""

import requests
import subprocess
import socket
import json
import sys
import argparse
import time
import threading
from urllib.parse import urljoin, urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import warnings
warnings.filterwarnings('ignore', message='Unverified HTTPS request')

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

class SubdomainScanner:
    def __init__(self, domain, threads=50, timeout=10):
        self.domain = domain
        self.threads = threads
        self.timeout = timeout
        self.subdomains = set()
        self.wordpress_sites = []
        self.findings = []
        
        # Common subdomain wordlist
        self.subdomain_wordlist = [
            'www', 'mail', 'remote', 'blog', 'webmail', 'server', 'ns1', 'ns2',
            'smtp', 'secure', 'vpn', 'admin', 'www2', 'test', 'dev', 'staging',
            'api', 'app', 'forum', 'ftp', 'shop', 'news', 'portal', 'demo',
            'old', 'backup', 'mobile', 'cdn', 'static', 'beta', 'alpha',
            'login', 'panel', 'control', 'wp', 'wordpress', 'cms', 'support',
            'help', 'assets', 'media', 'files', 'docs', 'download', 'uploads'
        ]
        
        # WordPress-specific files and directories to check
        self.wp_files = [
            'wp-admin/', 'wp-content/', 'wp-includes/', 'wp-config.php',
            'wp-login.php', 'wp-cron.php', 'wp-load.php', 'wp-blog-header.php',
            'wp-config.php.bak', 'wp-config.txt', 'wp-config.old',
            'wp-content/uploads/', 'wp-content/themes/', 'wp-content/plugins/',
            'wp-content/debug.log', 'wp-content/backup-db/', 'wp-content/cache/',
            'xmlrpc.php', 'readme.html', 'license.txt', 'wp-trackback.php',
            'wp-admin/admin-ajax.php', 'wp-admin/install.php'
        ]
        
        # Common sensitive files for any web application
        self.sensitive_files = [
            '.env', '.env.local', '.env.production', '.env.development',
            'config.php', 'configuration.php', 'settings.php', 'config.ini',
            'database.php', 'db.php', 'connect.php', 'connection.php',
            'backup.sql', 'dump.sql', 'database.sql', 'db_backup.sql',
            'robots.txt', 'sitemap.xml', 'crossdomain.xml', 'phpinfo.php',
            'info.php', 'test.php', 'debug.php', 'error_log', 'access.log',
            '.htaccess', '.htpasswd', 'web.config', 'server-status',
            'server-info', 'admin/', 'administrator/', 'manager/', 'control/',
            'cpanel/', 'plesk/', 'phpmyadmin/', 'pma/', 'mysql/',
            'adminer.php', 'sql.php', 'backup/', 'backups/', 'old/',
            'temp/', 'tmp/', 'cache/', 'logs/', 'log/', 'uploads/',
            'files/', 'documents/', 'docs/', 'downloads/', 'images/',
            'private/', 'conf/', 'config/', 'include/', 'inc/',
            'application.yml', 'application.properties', 'app.properties'
        ]
        
        # 403 bypass techniques
        self.bypass_headers = [
            {'X-Original-URL': ''},
            {'X-Rewrite-URL': ''},
            {'X-Forwarded-For': '127.0.0.1'},
            {'X-Real-IP': '127.0.0.1'},
            {'X-Originating-IP': '127.0.0.1'},
            {'X-Forwarded-Host': '127.0.0.1'},
            {'X-Remote-IP': '127.0.0.1'},
            {'X-Remote-Addr': '127.0.0.1'},
            {'X-Cluster-Client-IP': '127.0.0.1'},
            {'X-ProxyUser-Ip': '127.0.0.1'},
            {'X-Forwarded-Proto': 'http'},
            {'CF-Connecting-IP': '127.0.0.1'},
            {'User-Agent': 'GoogleBot'},
            {'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'},
            {'Referer': f'https://{domain}'},
            {'Origin': f'https://{domain}'}
        ]
        
        self.bypass_paths = [
            '/', '/?', '/..;/', '/../', '/;/', '/%2e/', '/%252e/',
            '/%2e%2e/', '/%252e%252e/', '/..%2f', '/..%252f',
            '/./', '/.//', '///', '//', '/.//../', '/..//',
            '/%20', '/%09', '/%0a', '/%0d', '/%00', '/%ff'
        ]

    def print_banner(self):
        """Print tool banner"""
        banner = f"""
{Colors.CYAN}{Colors.BOLD}
╔══════════════════════════════════════════════════════════════════════════════╗
║                    WordPress Subdomain Scanner & Recon Tool                 ║
║                        For Bug Bounty & Security Research                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
{Colors.END}
{Colors.YELLOW}Target Domain: {Colors.WHITE}{self.domain}{Colors.END}
{Colors.YELLOW}Threads: {Colors.WHITE}{self.threads}{Colors.END}
{Colors.YELLOW}Timeout: {Colors.WHITE}{self.timeout}s{Colors.END}
"""
        print(banner)

    def discover_subdomains_dns(self):
        """Discover subdomains using DNS bruteforce"""
        print(f"\n{Colors.BLUE}[+] Starting DNS subdomain enumeration...{Colors.END}")
        discovered = 0
        
        def check_subdomain(subdomain):
            try:
                full_domain = f"{subdomain}.{self.domain}"
                socket.gethostbyname(full_domain)
                self.subdomains.add(full_domain)
                print(f"{Colors.GREEN}[✓] Found: {full_domain}{Colors.END}")
                return True
            except:
                return False
        
        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = [executor.submit(check_subdomain, sub) for sub in self.subdomain_wordlist]
            for future in as_completed(futures):
                if future.result():
                    discovered += 1
        
        print(f"{Colors.CYAN}[i] DNS enumeration complete: {discovered} subdomains found{Colors.END}")

    def discover_subdomains_crt(self):
        """Discover subdomains using crt.sh certificate transparency logs"""
        print(f"\n{Colors.BLUE}[+] Checking Certificate Transparency logs...{Colors.END}")
        try:
            url = f"https://crt.sh/?q=%25.{self.domain}&output=json"
            response = requests.get(url, timeout=self.timeout)
            if response.status_code == 200:
                certificates = response.json()
                for cert in certificates:
                    name = cert.get('name_value', '')
                    if name and not name.startswith('*'):
                        names = name.split('\n')
                        for subdomain in names:
                            subdomain = subdomain.strip()
                            if subdomain.endswith(f'.{self.domain}') and subdomain not in self.subdomains:
                                self.subdomains.add(subdomain)
                                print(f"{Colors.GREEN}[✓] Found: {subdomain}{Colors.END}")
        except Exception as e:
            print(f"{Colors.RED}[!] Certificate transparency check failed: {e}{Colors.END}")

    def check_http_https(self, subdomain):
        """Check if subdomain responds to HTTP/HTTPS"""
        urls = [f"http://{subdomain}", f"https://{subdomain}"]
        working_urls = []
        
        for url in urls:
            try:
                response = requests.get(url, timeout=self.timeout, verify=False, allow_redirects=True)
                if response.status_code in [200, 301, 302, 403, 401]:
                    working_urls.append((url, response.status_code, len(response.content)))
            except:
                continue
        
        return working_urls

    def detect_wordpress(self, url):
        """Detect if a site is running WordPress"""
        wp_indicators = [
            '/wp-content/',
            '/wp-includes/',
            'wp-json',
            'WordPress',
            'wp-admin',
            'xmlrpc.php'
        ]
        
        try:
            response = requests.get(url, timeout=self.timeout, verify=False)
            content = response.text.lower()
            
            # Check for WordPress indicators in content
            wp_score = sum(1 for indicator in wp_indicators if indicator.lower() in content)
            
            # Check common WordPress files
            wp_files_found = []
            for wp_file in ['wp-login.php', 'xmlrpc.php', 'wp-admin/']:
                try:
                    file_url = urljoin(url, wp_file)
                    file_response = requests.get(file_url, timeout=5, verify=False)
                    if file_response.status_code in [200, 302, 401]:
                        wp_files_found.append(wp_file)
                        wp_score += 2
                except:
                    continue
            
            if wp_score >= 2:
                return True, wp_files_found
                
        except:
            pass
        
        return False, []

    def attempt_403_bypass(self, url, original_status):
        """Attempt various 403 bypass techniques"""
        if original_status != 403:
            return None
        
        bypassed_methods = []
        
        # Try different headers
        for header in self.bypass_headers:
            try:
                response = requests.get(url, headers=header, timeout=5, verify=False)
                if response.status_code == 200:
                    bypassed_methods.append(f"Header bypass: {header}")
                    break
            except:
                continue
        
        # Try path manipulation
        parsed_url = urlparse(url)
        base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
        
        for bypass_path in self.bypass_paths:
            try:
                test_url = urljoin(base_url, bypass_path + parsed_url.path.lstrip('/'))
                response = requests.get(test_url, timeout=5, verify=False)
                if response.status_code == 200:
                    bypassed_methods.append(f"Path bypass: {bypass_path}")
                    break
            except:
                continue
        
        return bypassed_methods if bypassed_methods else None

    def scan_wordpress_files(self, base_url):
        """Scan for WordPress-specific files and directories"""
        findings = []
        
        print(f"{Colors.YELLOW}[+] Scanning WordPress files for {base_url}...{Colors.END}")
        
        for wp_file in self.wp_files:
            try:
                file_url = urljoin(base_url, wp_file)
                response = requests.get(file_url, timeout=5, verify=False)
                
                finding = {
                    'url': file_url,
                    'status': response.status_code,
                    'size': len(response.content),
                    'type': 'wordpress_file'
                }
                
                if response.status_code == 200:
                    print(f"{Colors.GREEN}[✓] Found: {file_url} (200){Colors.END}")
                    findings.append(finding)
                elif response.status_code == 403:
                    print(f"{Colors.YELLOW}[!] Forbidden: {file_url} (403) - Attempting bypass...{Colors.END}")
                    bypass_result = self.attempt_403_bypass(file_url, 403)
                    if bypass_result:
                        finding['bypass_methods'] = bypass_result
                        print(f"{Colors.GREEN}[✓] 403 Bypassed: {file_url} - {bypass_result}{Colors.END}")
                    findings.append(finding)
                elif response.status_code in [301, 302]:
                    print(f"{Colors.CYAN}[→] Redirect: {file_url} ({response.status_code}){Colors.END}")
                    findings.append(finding)
                    
            except Exception as e:
                continue
        
        return findings

    def scan_sensitive_files(self, base_url):
        """Scan for sensitive files and configuration files"""
        findings = []
        
        print(f"{Colors.YELLOW}[+] Scanning sensitive files for {base_url}...{Colors.END}")
        
        for sensitive_file in self.sensitive_files:
            try:
                file_url = urljoin(base_url, sensitive_file)
                response = requests.get(file_url, timeout=5, verify=False)
                
                finding = {
                    'url': file_url,
                    'status': response.status_code,
                    'size': len(response.content),
                    'type': 'sensitive_file'
                }
                
                if response.status_code == 200:
                    # Check for common sensitive content indicators
                    content = response.text.lower()
                    sensitive_indicators = ['password', 'secret', 'key', 'token', 'database', 'mysql', 'postgres']
                    
                    if any(indicator in content for indicator in sensitive_indicators):
                        print(f"{Colors.RED}[!!!] SENSITIVE: {file_url} (200) - May contain credentials!{Colors.END}")
                        finding['sensitive_content'] = True
                    else:
                        print(f"{Colors.GREEN}[✓] Found: {file_url} (200){Colors.END}")
                    
                    findings.append(finding)
                    
                elif response.status_code == 403:
                    print(f"{Colors.YELLOW}[!] Forbidden: {file_url} (403) - Attempting bypass...{Colors.END}")
                    bypass_result = self.attempt_403_bypass(file_url, 403)
                    if bypass_result:
                        finding['bypass_methods'] = bypass_result
                        print(f"{Colors.GREEN}[✓] 403 Bypassed: {file_url} - {bypass_result}{Colors.END}")
                    findings.append(finding)
                    
            except Exception as e:
                continue
        
        return findings

    def scan_subdomain(self, subdomain):
        """Comprehensive scan of a single subdomain"""
        print(f"\n{Colors.PURPLE}[*] Scanning subdomain: {subdomain}{Colors.END}")
        
        # Check HTTP/HTTPS availability
        working_urls = self.check_http_https(subdomain)
        
        if not working_urls:
            print(f"{Colors.RED}[!] No HTTP/HTTPS response from {subdomain}{Colors.END}")
            return
        
        for url, status_code, content_length in working_urls:
            print(f"{Colors.CYAN}[i] {url} - Status: {status_code}, Size: {content_length} bytes{Colors.END}")
            
            # Detect WordPress
            is_wordpress, wp_files = self.detect_wordpress(url)
            
            if is_wordpress:
                print(f"{Colors.GREEN}[WordPress] Detected on {url}{Colors.END}")
                wp_site = {
                    'url': url,
                    'subdomain': subdomain,
                    'status': status_code,
                    'wp_files_detected': wp_files,
                    'findings': []
                }
                
                # Scan WordPress-specific files
                wp_findings = self.scan_wordpress_files(url)
                wp_site['findings'].extend(wp_findings)
                
                # Scan sensitive files
                sensitive_findings = self.scan_sensitive_files(url)
                wp_site['findings'].extend(sensitive_findings)
                
                self.wordpress_sites.append(wp_site)
                self.findings.extend(wp_findings + sensitive_findings)
            else:
                print(f"{Colors.YELLOW}[i] Not a WordPress site: {url}{Colors.END}")
                # Still scan for sensitive files on non-WordPress sites
                sensitive_findings = self.scan_sensitive_files(url)
                self.findings.extend(sensitive_findings)

    def run_scan(self):
        """Main scanning orchestration"""
        self.print_banner()
        
        # Subdomain discovery
        self.discover_subdomains_dns()
        self.discover_subdomains_crt()
        
        # Always include the main domain
        self.subdomains.add(self.domain)
        
        print(f"\n{Colors.CYAN}[i] Total subdomains found: {len(self.subdomains)}{Colors.END}")
        
        # Scan each subdomain
        print(f"\n{Colors.BLUE}[+] Starting comprehensive scan of all subdomains...{Colors.END}")
        
        with ThreadPoolExecutor(max_workers=min(10, len(self.subdomains))) as executor:
            futures = [executor.submit(self.scan_subdomain, subdomain) for subdomain in self.subdomains]
            for future in as_completed(futures):
                future.result()

    def generate_report(self):
        """Generate a comprehensive report of findings"""
        print(f"\n{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════════════════════════╗")
        print(f"║                              SCAN RESULTS SUMMARY                           ║")
        print(f"╚══════════════════════════════════════════════════════════════════════════════╝{Colors.END}")
        
        print(f"\n{Colors.YELLOW}Target Domain: {Colors.WHITE}{self.domain}{Colors.END}")
        print(f"{Colors.YELLOW}Subdomains Found: {Colors.WHITE}{len(self.subdomains)}{Colors.END}")
        print(f"{Colors.YELLOW}WordPress Sites: {Colors.WHITE}{len(self.wordpress_sites)}{Colors.END}")
        print(f"{Colors.YELLOW}Total Findings: {Colors.WHITE}{len(self.findings)}{Colors.END}")
        
        if self.wordpress_sites:
            print(f"\n{Colors.GREEN}[WordPress Sites Found]{Colors.END}")
            for i, site in enumerate(self.wordpress_sites, 1):
                print(f"\n{Colors.CYAN}  {i}. {site['url']}{Colors.END}")
                print(f"     Status: {site['status']}")
                print(f"     WP Files Detected: {', '.join(site['wp_files_detected']) if site['wp_files_detected'] else 'None'}")
                print(f"     Findings: {len(site['findings'])}")
        
        # Categorize findings
        sensitive_findings = [f for f in self.findings if f.get('sensitive_content')]
        bypass_findings = [f for f in self.findings if f.get('bypass_methods')]
        accessible_files = [f for f in self.findings if f.get('status') == 200]
        
        if sensitive_findings:
            print(f"\n{Colors.RED}[!!!] CRITICAL FINDINGS - Potential Sensitive Data Exposure{Colors.END}")
            for finding in sensitive_findings:
                print(f"  {Colors.RED}🚨 {finding['url']}{Colors.END}")
        
        if bypass_findings:
            print(f"\n{Colors.YELLOW}[!] 403 BYPASS SUCCESSFUL{Colors.END}")
            for finding in bypass_findings:
                print(f"  {Colors.YELLOW}🔓 {finding['url']} - {finding['bypass_methods']}{Colors.END}")
        
        if accessible_files:
            print(f"\n{Colors.GREEN}[✓] ACCESSIBLE FILES/DIRECTORIES{Colors.END}")
            for finding in accessible_files:
                if not finding.get('sensitive_content'):  # Don't duplicate sensitive findings
                    print(f"  {Colors.GREEN}📁 {finding['url']}{Colors.END}")
        
        # Save JSON report
        report_data = {
            'target_domain': self.domain,
            'scan_timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'subdomains_found': list(self.subdomains),
            'wordpress_sites': self.wordpress_sites,
            'total_findings': len(self.findings),
            'findings': self.findings
        }
        
        report_filename = f"wordpress_recon_{self.domain.replace('.', '_')}_{int(time.time())}.json"
        try:
            with open(report_filename, 'w') as f:
                json.dump(report_data, f, indent=2)
            print(f"\n{Colors.CYAN}[i] Detailed report saved to: {report_filename}{Colors.END}")
        except Exception as e:
            print(f"{Colors.RED}[!] Failed to save report: {e}{Colors.END}")
        
        print(f"\n{Colors.BOLD}{Colors.GREEN}Scan completed successfully!{Colors.END}")


def main():
    parser = argparse.ArgumentParser(
        description='WordPress Subdomain Scanner and Vulnerability Assessment Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 subdomain_wordpress_scanner.py -d example.com
  python3 subdomain_wordpress_scanner.py -d target.com -t 100 --timeout 15
  
Note: This tool is for authorized security testing only. 
Always ensure you have permission before scanning any domain.
        """
    )
    
    parser.add_argument('-d', '--domain', required=True, help='Target domain to scan')
    parser.add_argument('-t', '--threads', type=int, default=50, help='Number of threads (default: 50)')
    parser.add_argument('--timeout', type=int, default=10, help='Request timeout in seconds (default: 10)')
    
    args = parser.parse_args()
    
    # Legal disclaimer
    print(f"\n{Colors.RED}{Colors.BOLD}LEGAL DISCLAIMER:{Colors.END}")
    print(f"{Colors.YELLOW}This tool is for authorized security testing only.")
    print(f"Ensure you have explicit permission before scanning any domain.")
    print(f"Unauthorized scanning may violate laws and terms of service.{Colors.END}")
    
    response = input(f"\n{Colors.CYAN}Do you have authorization to scan {args.domain}? (y/N): {Colors.END}")
    if response.lower() != 'y':
        print(f"{Colors.RED}Scan aborted. Only scan domains you own or have explicit permission to test.{Colors.END}")
        sys.exit(1)
    
    try:
        scanner = SubdomainScanner(args.domain, args.threads, args.timeout)
        scanner.run_scan()
        scanner.generate_report()
    except KeyboardInterrupt:
        print(f"\n{Colors.RED}[!] Scan interrupted by user{Colors.END}")
    except Exception as e:
        print(f"\n{Colors.RED}[!] Scan failed: {e}{Colors.END}")


if __name__ == "__main__":
    main()