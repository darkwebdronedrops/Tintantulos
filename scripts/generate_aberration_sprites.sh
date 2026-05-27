#!/bin/bash
# Pixel Lab API Sprite Generation for Aberration Faction
# Generate enemy sprites with transparency

API_KEY="${PIXELLAB_API_KEY}"
BASE_URL="https://api.pixellab.ai/v1"
OUTPUT_DIR="/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies"

mkdir -p "$OUTPUT_DIR"

generate_sprite() {
    local name=$1
    local state=$2
    local prompt=$3
    local size=$4
    
    echo "Generating: ${name}_${state}..."
    
    curl -s -X POST "$BASE_URL/generate-image-pixflux" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"description\": \"$prompt\",
            \"image_size\": {\"width\": $size, \"height\": $size},
            \"no_background\": true,
            \"seed\": 42
        }" | jq -r '.image' | base64 -d > "$OUTPUT_DIR/${name}_${state}.png" 2>/dev/null
    
    if [ -f "$OUTPUT_DIR/${name}_${state}.png" ]; then
        echo "✓ ${name}_${state}.png created"
    else
        echo "✗ ${name}_${state}.png failed"
    fi
}

# The Bug - glitch insectoid aberration
generate_sprite "enemy_the_bug" "idle" "pixel art, glitch insectoid creature, corrupted data bug, crawling code, static interference, distorted limbs, retro game sprite, 32x32" 64
generate_sprite "enemy_the_bug" "glitch" "pixel art, glitch insect exploding into static, corrupted data scattering, screen tearing effect, retro game sprite, 32x32" 64
generate_sprite "enemy_the_bug" "damage" "pixel art, glitch bug hit, corruption spreading, static burst, retro game sprite, 32x32" 64
generate_sprite "enemy_the_bug" "death" "pixel art, glitch bug dissolving into pixels, data corruption consuming, static fade, retro game sprite, 32x32" 64

# The Contagion - spreading corruption
generate_sprite "enemy_the_contagion" "idle" "pixel art, amorphous blob of corruption, spreading tentacles of static, viral infection, glitch flesh, retro game sprite, 32x32" 64
generate_sprite "enemy_the_contagion" "spread" "pixel art, corruption expanding, tendrils reaching, glitch virus spreading, static waves, retro game sprite, 32x32" 64

# The Hollow - empty void creature
generate_sprite "enemy_the_hollow" "idle" "pixel art, humanoid silhouette filled with void, empty darkness inside, outline only, abyss personified, retro game sprite, 32x32" 64
generate_sprite "enemy_the_hollow" "consume" "pixel art, hollow figure opening void mouth, consuming light, darkness expanding, retro game sprite, 32x32" 64

echo "Batch 1 complete"