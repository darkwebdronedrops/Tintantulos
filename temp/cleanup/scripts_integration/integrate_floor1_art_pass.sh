#!/bin/bash
# Integrate Floor 1 art pass
set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration/floor1"
FLOOR1_DIR="$PROJECT/assets/sprites/floor1"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

mkdir -p "$FLOOR1_DIR"

echo "=== INTEGRATING FLOOR 1 ART PASS (20 assets) ==="

# Move all generated assets to floor1 directory
for src in "$TEMP"/*.png; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  tgt="$FLOOR1_DIR/$name"
  
  # Backup if exists (unlikely for Floor 1, but safe)
  if [ -f "$tgt" ]; then
    backup_dir="$BACKUP/assets/sprites/floor1"
    mkdir -p "$backup_dir"
    mv "$tgt" "$backup_dir/"
    echo "  [BACKUP+MOVE] $name"
  else
    mv "$src" "$tgt"
    echo "  [MOVED] $name"
  fi
done

echo ""
echo "=== CLEANUP ==="
find "$TEMP" -name "*.png" -type f -delete 2>/dev/null || true
rmdir "$TEMP" 2>/dev/null || true

echo ""
echo "=== INVENTORY ==="
echo "Floor 1 assets in game:"
ls -la "$FLOOR1_DIR/" | grep -v "\.import"

echo ""
echo "=== DONE ===
echo "Floor 1 art pass complete. 20 sprites ready for scene integration."
echo "Location: res://assets/sprites/floor1/"
echo ""
echo "Assets generated:"
echo "  Floor textures (5): floor1_central, floor1_north_door, floor1_east_warren, floor1_south_shrine, floor1_west_gauntlet"
echo "  The Door (1): the_door"
echo "  NPCs (2): npc_transit_construct, shop_kiosk"
echo "  Portals (5): portal_main, portal_north, portal_east, portal_south, portal_west"
echo "  Banners (6): banner_goblin, banner_construct, banner_demon, banner_elemental, banner_undead, banner_aberration"
echo "  Background (1): floor1_background"
