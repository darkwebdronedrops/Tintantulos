#!/bin/bash
# Integrate Floor 1 flat floor textures
set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
FLOOR1_DIR="$PROJECT/assets/sprites/floor1"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

echo "=== INTEGRATING FLAT FLOOR TEXTURES ==="

# Copy best versions from retry folders to floor1 directory
# Central v2
if [ -f "$PROJECT/temp_regeneration/floor1_retry/floor1_central_v2.png" ]; then
  cp "$PROJECT/temp_regeneration/floor1_retry/floor1_central_v2.png" "$FLOOR1_DIR/floor1_central.png"
  echo "  [INTEGRATED] floor1_central.png (v2 - flat)"
fi

# North Door v4
if [ -f "$PROJECT/temp_regeneration/floor1_retry3/floor1_north_door_v4.png" ]; then
  cp "$PROJECT/temp_regeneration/floor1_retry3/floor1_north_door_v4.png" "$FLOOR1_DIR/floor1_north_door.png"
  echo "  [INTEGRATED] floor1_north_door.png (v4 - simple language flat)"
fi

# East Warren v3
if [ -f "$PROJECT/temp_regeneration/floor1_retry2/floor1_east_warren_v3.png" ]; then
  cp "$PROJECT/temp_regeneration/floor1_retry2/floor1_east_warren_v3.png" "$FLOOR1_DIR/floor1_east_warren.png"
  echo "  [INTEGRATED] floor1_east_warren.png (v3 - flat)"
fi

# West Gauntlet v3
if [ -f "$PROJECT/temp_regeneration/floor1_retry2/floor1_west_gauntlet_v3.png" ]; then
  cp "$PROJECT/temp_regeneration/floor1_retry2/floor1_west_gauntlet_v3.png" "$FLOOR1_DIR/floor1_west_gauntlet.png"
  echo "  [INTEGRATED] floor1_west_gauntlet.png (v3 - flat)"
fi

# South Shrine v6 (Caleb's bathroom tile)
if [ -f "$PROJECT/temp_regeneration/floor1_retry3/floor1_south_shrine_v6.png" ]; then
  cp "$PROJECT/temp_regeneration/floor1_retry3/floor1_south_shrine_v6.png" "$FLOOR1_DIR/floor1_south_shrine.png"
  echo "  [INTEGRATED] floor1_south_shrine.png (v6 - Caleb's bathroom tile)"
fi

echo ""
echo "=== CLEANUP TEMP FOLDERS ==="
rm -rf "$PROJECT/temp_regeneration/floor1_retry" 2>/dev/null || true
rm -rf "$PROJECT/temp_regeneration/floor1_retry2" 2>/dev/null || true
rm -rf "$PROJECT/temp_regeneration/floor1_retry3" 2>/dev/null || true

echo ""
echo "=== FINAL FLOOR 1 ASSET INVENTORY ==="
echo "Floor textures (5):"
ls "$FLOOR1_DIR"/floor1_*.png | grep -v "\.import" | while read f; do
  echo "  $(basename $f)"
done

echo ""
echo "Other assets:"
ls "$FLOOR1_DIR"/ | grep -v "floor1_" | grep -v "\.import"

echo ""
echo "=== DONE ===
echo "All Floor 1 art assets integrated."
echo "Location: res://assets/sprites/floor1/"
echo ""
echo "Prompt discoveries to remember:"
echo "  'flat stone floor tiles suitable for an adventure game' = flat surfaces"
echo "  'Golden framed white tile suitable for bathroom' = flat, no architecture"
echo "  Elaborate negative constraints confuse the model"
echo "  Simple domestic language avoids room-generation bias"
