#!/bin/bash
# Run script for Acanous Card Battler Floor 3 Demo
# Usage: ./run.sh [godot_path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================"
echo "  Acanous Card Battler - Floor 3"
echo "  The Gearworks Demo"
echo "================================"
echo ""

# Check for Godot
GODOT_PATH="${1:-godot}"

if ! command -v "$GODOT_PATH" &> /dev/null; then
    echo -e "${RED}Error: Godot not found at '$GODOT_PATH'${NC}"
    echo ""
    echo "Please install Godot 4.x or provide the path to the Godot executable:"
    echo "  ./run.sh /path/to/godot"
    echo ""
    echo "Download Godot from: https://godotengine.org/download"
    exit 1
fi

# Check Godot version
echo "Checking Godot version..."
VERSION=$($GODOT_PATH --version 2>/dev/null | head -1 || echo "unknown")
echo "Found: $VERSION"

# Verify project structure
echo ""
echo "Verifying project structure..."

REQUIRED_FILES=(
    "project.godot"
    "scripts/AudioManager.gd"
    "scripts/Floor3Demo.gd"
    "scripts/GearPuzzle.gd"
    "scripts/CombatManager.gd"
    "scripts/GameState.gd"
    "scripts/CardDB.gd"
    "scripts/CardData.gd"
    "scripts/SummonManager.gd"
    "scripts/TrapManager.gd"
    "scripts/FieldManager.gd"
    "scripts/ShieldSystem.gd"
    "scripts/Hand.gd"
    "scripts/enemies/Enemy.gd"
    "scripts/enemies/Floor3Encounter.gd"
    "scenes/Floor3Demo.tscn"
    "scenes/AudioManager.tscn"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}  ✗ Missing: $file${NC}"
        MISSING=$((MISSING + 1))
    else
        echo -e "${GREEN}  ✓ Found: $file${NC}"
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${RED}Error: $MISSING required file(s) missing!${NC}"
    exit 1
fi

# Check audio files
echo ""
echo "Checking audio assets..."
AUDIO_COUNT=$(find assets/audio -name "*.wav" 2>/dev/null | wc -l)
echo "  Found $AUDIO_COUNT audio files"

if [ $AUDIO_COUNT -lt 10 ]; then
    echo -e "${YELLOW}  ⚠ Warning: Few audio files found. Run scripts/generate_audio_placeholders.py${NC}"
fi

# Check for import files
echo ""
echo "Checking Godot import cache..."
if [ ! -d ".godot" ]; then
    echo "  Creating initial import cache..."
    $GODOT_PATH --headless --import 2>/dev/null || true
fi

# Launch the game
echo ""
echo "================================"
echo -e "${GREEN}Launching Floor 3 Demo...${NC}"
echo "================================"
echo ""
echo "Controls:"
echo "  - Click cards to play"
echo "  - Space or E to end turn"
echo "  - Keys 1-5 + QWERT to rotate gears (in puzzle)"
echo "  - H for puzzle hint"
echo ""

# Run Godot
exec $GODOT_PATH --path "$SCRIPT_DIR"
