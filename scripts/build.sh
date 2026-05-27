#!/bin/bash
# ===================================================================
# BUILD SCRIPT — Export Godot project for Steam
# ===================================================================
# Usage: ./scripts/build.sh [windows|linux|both]
# Requires: Godot 4.x installed and in PATH as 'godot'
# ===================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/builds"
PRESET=""

# Parse args
TARGET="${1:-both}"

case "$TARGET" in
    windows|win)
        PRESET="Windows Desktop"
        ;;
    linux|lin)
        PRESET="Linux/X11"
        ;;
    both|all)
        PRESET="both"
        ;;
    *)
        echo "Usage: $0 [windows|linux|both]"
        exit 1
        ;;
esac

# Check Godot
if ! command -v godot &> /dev/null; then
    echo "ERROR: Godot not found in PATH"
    echo "Install Godot 4.x and ensure 'godot' is available"
    exit 1
fi

# Check export templates
if [ ! -d "$HOME/.local/share/godot/export_templates" ] && [ ! -d "$HOME/.godot/export_templates" ]; then
    echo "WARNING: Export templates may not be installed"
    echo "Download from: https://godotengine.org/download"
fi

# Clean old builds
echo "=== Cleaning old builds ==="
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/windows" "$BUILD_DIR/linux"

# Export Windows
if [ "$PRESET" = "Windows Desktop" ] || [ "$PRESET" = "both" ]; then
    echo "=== Exporting Windows build ==="
    godot --headless --path "$PROJECT_DIR" --export-release "Windows Desktop" "$BUILD_DIR/windows/Acanous.exe"
    echo "✓ Windows build: $BUILD_DIR/windows/Acanous.exe"
fi

# Export Linux
if [ "$PRESET" = "Linux/X11" ] || [ "$PRESET" = "both" ]; then
    echo "=== Exporting Linux build ==="
    godot --headless --path "$PROJECT_DIR" --export-release "Linux/X11" "$BUILD_DIR/linux/Acanous.x86_64"
    chmod +x "$BUILD_DIR/linux/Acanous.x86_64"
    echo "✓ Linux build: $BUILD_DIR/linux/Acanous.x86_64"
fi

# Create version file
VERSION="$(date +%Y%m%d)-$(git rev-parse --short HEAD 2>/dev/null || echo 'alpha')"
echo "$VERSION" > "$BUILD_DIR/version.txt"

echo ""
echo "=== BUILD COMPLETE ==="
echo "Version: $VERSION"
echo "Output: $BUILD_DIR/"
echo ""
echo "Next steps:"
echo "  1. Test the build locally"
echo "  2. Run steamcmd upload: ./scripts/upload_to_steam.sh"
