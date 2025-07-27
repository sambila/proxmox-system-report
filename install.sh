#!/bin/bash
# Quick Install Script for Proxmox System Report Generator
# This script installs the Markdown version with CSS styling

set -e

echo "==================================="
echo "Proxmox System Report Installer"
echo "==================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (use sudo)"
  exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p /usr/local/bin
mkdir -p /usr/local/share/proxmox-report

# Download files
echo "Downloading scripts..."
wget -q https://raw.githubusercontent.com/sambila/proxmox-system-report/main/proxmox-report-md.sh -O /usr/local/bin/proxmox-report
wget -q https://raw.githubusercontent.com/sambila/proxmox-system-report/main/report.css -O /usr/local/share/proxmox-report/report.css

# Make executable
chmod +x /usr/local/bin/proxmox-report

# Check for optional dependencies
echo ""
echo "Checking dependencies..."
if command -v bc >/dev/null 2>&1; then
  echo "✓ bc is installed"
else
  echo "⚠ bc is not installed (required for calculations)"
  echo "  Install with: apt-get install bc"
fi

if command -v pandoc >/dev/null 2>&1; then
  echo "✓ pandoc is installed (HTML export available)"
else
  echo "ℹ pandoc is not installed (optional for HTML export)"
  echo "  Install with: apt-get install pandoc"
fi

echo ""
echo "==================================="
echo "Installation complete!"
echo "==================================="
echo ""
echo "Usage: proxmox-report"
echo ""
echo "The report will be saved in the current directory as:"
echo "  - proxmox_report_hostname_YYYYMMDD_HHMMSS.md"
echo "  - proxmox_report_hostname_YYYYMMDD_HHMMSS.html (if pandoc is installed)"
echo ""
echo "To set up automatic reports, add to crontab:"
echo "  0 2 * * * /usr/local/bin/proxmox-report"
echo ""