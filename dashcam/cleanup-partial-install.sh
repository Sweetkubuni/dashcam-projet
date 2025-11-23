#!/bin/bash
# cleanup-partial-install.sh - Clean up partial installation

set -e

echo "=== Dashcam Service Cleanup ==="
echo ""
echo "This will remove the partial installation so you can reinstall with the fixed script."
echo ""
echo "This will remove:"
echo "  • /etc/dashcam/"
echo "  • /etc/systemd/system/dashcam-*.service"
echo "  • /usr/local/bin/dashcam-*"
echo ""
echo "This will NOT remove:"
echo "  • Your dashcam scripts and files"
echo "  • Docker or MediaMTX containers"
echo "  • Any recordings"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Cleaning up..."

# Stop any running services
echo "Stopping services..."
systemctl stop dashcam-camera.service 2>/dev/null || true
systemctl stop dashcam-mediamtx.service 2>/dev/null || true
systemctl stop dashcam-api.service 2>/dev/null || true
echo "✓ Services stopped"

# Remove service files
echo "Removing service files..."
rm -f /etc/systemd/system/dashcam-*.service
echo "✓ Service files removed"

# Remove scripts
echo "Removing scripts..."
rm -f /usr/local/bin/dashcam-*
rm -f /usr/local/bin/dashcamctl
echo "✓ Scripts removed"

# Remove configuration
echo "Removing configuration..."
rm -rf /etc/dashcam
echo "✓ Configuration removed"

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload
echo "✓ Systemd reloaded"

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "You can now run the fixed installation script:"
echo "  sudo ./install-dashcam-service.sh"
echo ""
echo "The new script will automatically detect your username and paths."