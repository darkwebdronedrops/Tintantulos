#!/bin/bash
# ===================================================================
# STEAM UPLOAD SCRIPT — SteamPipe via steamcmd
# ===================================================================
# Usage: ./scripts/upload_to_steam.sh [windows|linux|both]
# 
# PREREQUISITES:
#   1. Install steamcmd: https://developer.valvesoftware.com/wiki/SteamCMD
#   2. Download Steam SDK: https://partner.steamgames.com/doc/sdk
#   3. Replace APP_ID below with your real Steam App ID
#   4. Replace STEAM_USERNAME with your Steamworks partner account
#   5. Create a Steam build config at scripts/steam_app_build.vdf
# ===================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/builds"
APP_ID=480  # REPLACE WITH YOUR APP ID
STEAM_USERNAME="your_steam_username"  # REPLACE
STEAMCMD="steamcmd"

# Parse args
TARGET="${1:-both}"

# Check steamcmd
if ! command -v "$STEAMCMD" &> /dev/null; then
    echo "ERROR: steamcmd not found"
    echo "Install from: https://developer.valvesoftware.com/wiki/SteamCMD"
    exit 1
fi

# Check build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: No build found at $BUILD_DIR"
    echo "Run ./scripts/build.sh first"
    exit 1
fi

# Check config exists
if [ ! -f "$PROJECT_DIR/scripts/steam_app_build.vdf" ]; then
    echo "ERROR: Steam build config not found"
    echo "Create: scripts/steam_app_build.vdf"
    exit 1
fi

echo "=== Uploading to Steam ==="
echo "App ID: $APP_ID"
echo "Target: $TARGET"
echo ""

# Upload via steamcmd
$STEAMCMD \
    +login "$STEAM_USERNAME" \
    +run_app_build "$PROJECT_DIR/scripts/steam_app_build.vdf" \
    +quit

echo ""
echo "=== UPLOAD COMPLETE ==="
echo "Check Steamworks partner dashboard for build status"
