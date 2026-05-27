#!/bin/bash
# Generate P0 sound effects + equip + burn
# API Key: sk_f6b3d5c6969ec453ebc27be5366f2221fa8445e15632dab1

API_KEY="sk_f6b3d5c6969ec453ebc27be5366f2221fa8445e15632dab1"
OUTDIR="/root/.openclaw/workspace/acanous_floor3_demo/assets/audio/sfx"

cd "$OUTDIR"

generate() {
    local filename="$1"
    local description="$2"
    local duration="${3:-1.0}"
    
    echo "Generating: $filename..."
    
    curl -s -X POST https://api.elevenlabs.io/v1/sound-generation \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"$description\",
            \"duration_seconds\": $duration,
            \"prompt_influence\": 0.7
        }" \
        -o "$filename"
    
    if [ -f "$filename" ] && [ -s "$filename" ]; then
        size=$(stat -c%s "$filename" 2>/dev/null || stat -f%z "$filename" 2>/dev/null)
        if [ "$size" -gt 1000 ]; then
            echo "  ✓ $filename ($size bytes)"
        else
            echo "  ✗ $filename too small ($size bytes)"
            rm "$filename"
        fi
    else
        echo "  ✗ $filename failed"
    fi
    
    sleep 1
}

echo "=========================================="
echo "Generating P0 + Equip + Burn Sounds"
echo "=========================================="

# P0 — Immediate gameplay feel
generate "card_whoosh.mp3" "card flying through air, paper whoosh, fast swoosh, magical card toss" 0.5
generate "miss_dodge.mp3" "missed attack swish, sword whoosh through empty air, dodge evasion" 0.5
generate "weapon_swing.mp3" "weapon swing whoosh, blade cutting air, heavy axe swing" 0.5
generate "cant_play.mp3" "error buzz, invalid action, denied beep, soft rejection" 0.5
generate "target_select.mp3" "target lock-on, reticle snap, enemy selected, sharp click" 0.5
generate "menu_hover.mp3" "menu hover tick, UI navigation soft click, subtle selection" 0.3
generate "floor_transition.mp3" "portal warp, floor transition, magical teleport, whoosh dissolve" 1.5
generate "chest_open.mp3" "treasure chest opening, loot reward, satisfying unlock, gold sparkle" 1.0

# Additional requested
generate "equip.mp3" "gear slotting into place, mechanical click, item equip, satisfying snap" 0.5
generate "burn.mp3" "card burning to ash, paper crackle, flame consume, gem transformation sparkle" 1.0

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
