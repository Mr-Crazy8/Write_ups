#!/usr/bin/env python3
"""
Test script for WordPress Subdomain Scanner
This script performs basic validation of the scanner functionality
"""

import sys
import socket
import requests
from subdomain_wordpress_scanner import SubdomainScanner, Colors

def test_dns_resolution():
    """Test DNS resolution functionality"""
    print(f"{Colors.BLUE}[TEST] Testing DNS resolution...{Colors.END}")
    try:
        socket.gethostbyname('google.com')
        print(f"{Colors.GREEN}[✓] DNS resolution working{Colors.END}")
        return True
    except:
        print(f"{Colors.RED}[✗] DNS resolution failed{Colors.END}")
        return False

def test_http_requests():
    """Test HTTP request functionality"""
    print(f"{Colors.BLUE}[TEST] Testing HTTP requests...{Colors.END}")
    try:
        response = requests.get('https://httpbin.org/status/200', timeout=10)
        if response.status_code == 200:
            print(f"{Colors.GREEN}[✓] HTTP requests working{Colors.END}")
            return True
        else:
            print(f"{Colors.RED}[✗] HTTP request returned {response.status_code}{Colors.END}")
            return False
    except Exception as e:
        print(f"{Colors.RED}[✗] HTTP request failed: {e}{Colors.END}")
        return False

def test_scanner_initialization():
    """Test scanner class initialization"""
    print(f"{Colors.BLUE}[TEST] Testing scanner initialization...{Colors.END}")
    try:
        scanner = SubdomainScanner('example.com', threads=10, timeout=5)
        print(f"{Colors.GREEN}[✓] Scanner initialized successfully{Colors.END}")
        print(f"  - Domain: {scanner.domain}")
        print(f"  - Threads: {scanner.threads}")
        print(f"  - Timeout: {scanner.timeout}")
        print(f"  - Subdomain wordlist size: {len(scanner.subdomain_wordlist)}")
        print(f"  - WordPress files to check: {len(scanner.wp_files)}")
        print(f"  - Sensitive files to check: {len(scanner.sensitive_files)}")
        print(f"  - Bypass headers: {len(scanner.bypass_headers)}")
        return True
    except Exception as e:
        print(f"{Colors.RED}[✗] Scanner initialization failed: {e}{Colors.END}")
        return False

def test_wordpress_detection():
    """Test WordPress detection on a known WordPress site"""
    print(f"{Colors.BLUE}[TEST] Testing WordPress detection...{Colors.END}")
    try:
        scanner = SubdomainScanner('wordpress.com', threads=1, timeout=10)
        # Test on WordPress.com (should be detected as WordPress)
        is_wp, wp_files = scanner.detect_wordpress('https://wordpress.com')
        if is_wp:
            print(f"{Colors.GREEN}[✓] WordPress detection working{Colors.END}")
            print(f"  - WordPress files found: {wp_files}")
            return True
        else:
            print(f"{Colors.YELLOW}[!] WordPress detection may need tuning{Colors.END}")
            return False
    except Exception as e:
        print(f"{Colors.RED}[✗] WordPress detection test failed: {e}{Colors.END}")
        return False

def test_certificate_transparency():
    """Test certificate transparency lookup"""
    print(f"{Colors.BLUE}[TEST] Testing certificate transparency lookup...{Colors.END}")
    try:
        scanner = SubdomainScanner('google.com', threads=1, timeout=10)
        initial_subdomains = len(scanner.subdomains)
        scanner.discover_subdomains_crt()
        final_subdomains = len(scanner.subdomains)
        
        if final_subdomains > initial_subdomains:
            print(f"{Colors.GREEN}[✓] Certificate transparency working{Colors.END}")
            print(f"  - Found {final_subdomains - initial_subdomains} subdomains")
            return True
        else:
            print(f"{Colors.YELLOW}[!] No subdomains found via CT (may be normal){Colors.END}")
            return True  # This is not necessarily a failure
    except Exception as e:
        print(f"{Colors.RED}[✗] Certificate transparency test failed: {e}{Colors.END}")
        return False

def run_all_tests():
    """Run all tests and provide summary"""
    print(f"\n{Colors.CYAN}{Colors.BOLD}WordPress Scanner Test Suite{Colors.END}")
    print(f"{Colors.CYAN}{'='*50}{Colors.END}\n")
    
    tests = [
        test_dns_resolution,
        test_http_requests,
        test_scanner_initialization,
        test_wordpress_detection,
        test_certificate_transparency
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"{Colors.RED}[✗] Test failed with exception: {e}{Colors.END}")
        print()  # Add spacing between tests
    
    print(f"{Colors.CYAN}{'='*50}{Colors.END}")
    print(f"{Colors.BOLD}Test Results: {passed}/{total} passed{Colors.END}")
    
    if passed == total:
        print(f"{Colors.GREEN}[✓] All tests passed! Scanner is ready to use.{Colors.END}")
        return True
    else:
        print(f"{Colors.YELLOW}[!] Some tests failed. Scanner may have limited functionality.{Colors.END}")
        return False

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)