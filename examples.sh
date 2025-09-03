#!/bin/bash

# WordPress Subdomain Scanner - Example Usage Demonstrations
# This script shows various ways to use the scanner for different scenarios

echo "==================================================================="
echo "WordPress Subdomain Scanner - Example Usage"
echo "==================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Available usage examples:${NC}\n"

echo "1. Basic scan of a domain:"
echo -e "${GREEN}python3 subdomain_wordpress_scanner.py -d example.com${NC}"
echo

echo "2. High-speed scan with more threads:"
echo -e "${GREEN}python3 subdomain_wordpress_scanner.py -d target.com -t 100${NC}"
echo

echo "3. Conservative scan with longer timeouts:"
echo -e "${GREEN}python3 subdomain_wordpress_scanner.py -d target.com --timeout 20${NC}"
echo

echo "4. Comprehensive scan for bug bounty:"
echo -e "${GREEN}python3 subdomain_wordpress_scanner.py -d bugcrowd-target.com -t 75 --timeout 15${NC}"
echo

echo -e "${YELLOW}=== Key Features Demonstrated ===${NC}"
echo "✓ Subdomain Discovery (DNS + Certificate Transparency)"
echo "✓ WordPress Detection and Enumeration"
echo "✓ Sensitive File Discovery"
echo "✓ 403 Bypass Techniques"
echo "✓ Comprehensive JSON Reporting"
echo

echo -e "${YELLOW}=== Files and Directories Scanned ===${NC}"
echo "WordPress Files:"
echo "  • wp-config.php, wp-admin/, wp-content/"
echo "  • xmlrpc.php, wp-login.php"
echo "  • WordPress debug logs and backups"
echo

echo "Sensitive Files:"
echo "  • .env, config.php, database.php"
echo "  • backup.sql, phpinfo.php"
echo "  • admin panels, server-status"
echo

echo -e "${YELLOW}=== 403 Bypass Techniques ===${NC}"
echo "  • IP Header Spoofing (X-Forwarded-For, X-Real-IP)"
echo "  • User-Agent Manipulation (GoogleBot spoofing)"
echo "  • URL Encoding and Path Traversal"
echo "  • Host Header Manipulation"
echo

echo -e "${RED}=== LEGAL REMINDER ===${NC}"
echo -e "${RED}Always ensure you have proper authorization before scanning!${NC}"
echo "✓ Own the domain"
echo "✓ Have written permission"
echo "✓ Part of authorized bug bounty program"
echo

echo -e "${BLUE}For detailed documentation, see: WordPress_Scanner_README.md${NC}"