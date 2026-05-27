#!/bin/bash
# Regenerate all silent WAV files with real ElevenLabs audio
# API Key: sk_f6b3d5c6969ec453ebc27be5366f2221fa8445e15632dab1

API_KEY="sk_f6b3d5c6969ec453ebc27be5366f2221fa8445e15632dab1"
OUTDIR="/root/.openclaw/workspace/acanous_floor3_demo/assets/audio/sfx"

cd "$OUTDIR"

# Function to generate a sound
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
    
    sleep 1  # Rate limit
}

echo "=========================================="
echo "Regenerating Silent WAV Files"
echo "=========================================="

# === COMBAT SOUNDS ===
echo ""
echo "--- COMBAT ---"
generate "damage.wav" "sword slash impact, quick metal slice, combat hit sound" 0.5
generate "damage_bone.wav" "bone crunch, skeletal impact, sharp crack" 0.5
generate "damage_critical.wav" "critical strike, heavy impact, deep bass thud, devastating hit" 0.5
generate "damage_demon.wav" "demonic claw slash, hellfire impact, dark energy strike" 0.5
generate "damage_fire.wav" "fire burst impact, flame explosion, burning hit" 0.5
generate "damage_flesh.wav" "flesh slash, meaty impact, wet thud" 0.5
generate "damage_heavy.wav" "heavy mace impact, crushing blow, deep bass thud" 0.5
generate "damage_metal.wav" "metal clang, armor hit, sharp tinny impact" 0.5
generate "damage_void.wav" "void energy disintegration, dark matter impact, ethereal suction" 0.5
generate "enemy_attack.wav" "enemy swing, monster claw swipe, aggressive slash" 0.5
generate "enemy_hurt.wav" "monster pain grunt, creature yelp, guttural hurt" 0.5
generate "enemy_death.wav" "monster death scream, creature collapsing, final groan" 0.5
generate "shield_block.wav" "shield bash, metal clang deflect, parry sound" 0.5
generate "shield_break.wav" "shield shattering, glass breaking, barrier collapse" 0.5
generate "heal.wav" "magical healing chime, soft glow, restorative sparkle" 0.5

# === CARD SOUNDS ===
echo ""
echo "--- CARDS ---"
generate "card_draw.wav" "card sliding from deck, paper whoosh, quick flip" 0.5
generate "card_discard.wav" "card thrown away, paper flutter, dismissive flick" 0.5
generate "card_hover.wav" "card lift, soft paper rustle, gentle hover" 0.3
generate "card_shuffle.wav" "deck shuffling, cards riffling, casino shuffle" 0.5
generate "card_play.wav" "card slam on table, paper thud, decisive play" 0.5
generate "card_play_aberration.wav" "eldritch card play, void energy hum, aberrant whisper" 0.5
generate "card_play_construct.wav" "mechanical card play, gear click, steam hiss" 0.5
generate "card_play_demon.wav" "demonic card play, hellfire burst, infernal chime" 0.5
generate "card_play_elemental.wav" "elemental card play, fire crackle, water splash" 0.5
generate "card_play_goblin.wav" "goblin card play, crude horn, chaotic jingle" 0.5
generate "card_play_undead.wav" "undead card play, bone rattle, spectral moan" 0.5

# === SUMMON SOUNDS ===
echo ""
echo "--- SUMMONS ---"
generate "summon.wav" "magical summoning, portal opening, creature arrival" 0.8
generate "summon_aberration.wav" "eldritch summon, void portal, tentacle emergence" 0.8
generate "summon_construct.wav" "mechanical summon, gears assembling, steam piston" 0.8
generate "summon_demon.wav" "demonic summon, hell portal, lava burst" 0.8
generate "summon_elemental.wav" "elemental summon, fire burst, water geyser" 0.8
generate "summon_goblin.wav" "goblin summon, crude horn, chaotic squeal" 0.8
generate "summon_undead.wav" "undead summon, grave dirt, spectral emergence" 0.8
generate "summon_attack.wav" "minion attack, pet strike, companion hit" 0.5
generate "summon_death.wav" "minion death, pet collapse, companion vanish" 0.5
generate "summon_grow.wav" "creature evolving, power-up surge, growth burst" 0.5

# === DEATH SOUNDS ===
echo ""
echo "--- DEATHS ---"
generate "death_aberration.wav" "aberration death, void collapse, tentacle dissolve" 0.5
generate "death_demon.wav" "demon death, hellfire extinguish, sulfur hiss" 0.5
generate "death_elemental.wav" "elemental death, fire snuff, water evaporate" 0.5
generate "death_goblin.wav" "goblin death, high-pitched squeal, body drop" 0.5
generate "death_metal.wav" "mechanical death, gear jam, steam vent" 0.5
generate "death_undead.wav" "undead death, bone collapse, spirit release" 0.5

# === BOSS SOUNDS ===
echo ""
echo "--- BOSS ---"
generate "boss_entrance.wav" "boss dramatic entrance, heavy footsteps, intimidating presence, deep bass" 1.5
generate "boss_reveal.wav" "boss reveal, dramatic sting, tension buildup" 1.0
generate "boss_phase_change.wav" "boss transformation, power surge, phase shift, intense build-up" 1.2

# === TRAP SOUNDS ===
echo ""
echo "--- TRAPS ---"
generate "trap_cast.wav" "trap activation, mechanism spring, trigger snap" 0.5
generate "trap_disarm.wav" "trap defused, wire cut, safe click" 0.5
generate "trap_trigger.wav" "trap triggered, explosion, spike spring" 0.5

# === TURN SOUNDS ===
echo ""
echo "--- TURNS ---"
generate "turn_start.wav" "turn start bell, combat initiative, ready chime" 0.5
generate "turn_end.wav" "turn end click, pass token, transition click" 0.5

# === STEAM / GEAR ===
echo ""
echo "--- STEAM/GEAR ---"
generate "steam_release.wav" "steam vent burst, pressure release, pipe hiss" 0.8
generate "gear_rotate.wav" "large gear turning, mechanical rotation, cog wheel" 1.0

# === FEEDBACK ===
echo ""
echo "--- FEEDBACK ---"
generate "defeat.wav" "defeat fanfare, sad trombone, game over sting" 2.0
generate "victory.wav" "victory fanfare, triumphant horns, success chime" 2.0
generate "puzzle_solve.wav" "puzzle solved, success chime, mechanism unlock" 1.5

echo ""
echo "=========================================="
echo "Done! Check files above for failures."
echo "=========================================="
