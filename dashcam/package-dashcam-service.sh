#!/bin/bash
# package-dashcam-service.sh - Package all service files for deployment

set -e

echo "=== Dashcam Service Packager ==="
echo ""

# Check if all required files exist
REQUIRED_FILES=(
    "install-dashcam-service.sh"
    "dashcamctl"
    "dashcam-api.py"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "✗ Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    else
        echo "✓ Found: $file"
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "Error: Missing $MISSING_FILES required file(s)"
    exit 1
fi

echo ""
echo "Creating package..."

# Create package directory
PACKAGE_NAME="dashcam-service-$(date +%Y%m%d)"
mkdir -p "$PACKAGE_NAME"

# Copy files
cp install-dashcam-service.sh "$PACKAGE_NAME/"
cp dashcamctl "$PACKAGE_NAME/"
cp dashcam-api.py "$PACKAGE_NAME/"
cp DASHCAM_SERVICE_DOCS.md "$PACKAGE_NAME/README.md" 2>/dev/null || echo "Note: Documentation not included"

# Make scripts executable
chmod +x "$PACKAGE_NAME/install-dashcam-service.sh"
chmod +x "$PACKAGE_NAME/dashcamctl"
chmod +x "$PACKAGE_NAME/dashcam-api.py"

# Create tarball
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

echo ""
echo "✓ Package created: ${PACKAGE_NAME}.tar.gz"
echo ""
echo "To deploy to Raspberry Pi:"
echo "  1. scp ${PACKAGE_NAME}.tar.gz pi@dashcam.local:~/"
echo "  2. ssh pi@dashcam.local"
echo "  3. tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "  4. cd ${PACKAGE_NAME}"
echo "  5. sudo ./install-dashcam-service.sh"
echo ""
echo "Alternatively, extract in your existing dashcam directory:"
echo "  tar -xzf ${PACKAGE_NAME}.tar.gz --strip-components=1 -C ~/dashcam"