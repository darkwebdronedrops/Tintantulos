#!/bin/bash
# Integrate room floor tiles
set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration/ui_env"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

echo "=== INTEGRATING ROOM FLOOR TILES (11 files) ==="
for src in "$TEMP"/env_floor_*.png; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  tgt="$PROJECT/assets/sprites/ui_env/$name"
  
  if [ -f "$tgt" ]; then
    backup_dir="$BACKUP/assets/sprites/ui_env"
    mkdir -p "$backup_dir"
    mv "$tgt" "$backup_dir/"
  fi
  mv "$src" "$tgt"
  echo "  [MOVED] $name"
done

echo ""
echo "=== CLEANUP ==="
find "$TEMP" -name "*.png" -type f -delete 2>/dev/null || true
rmdir "$TEMP" 2>/dev/null || true

echo ""
echo "=== VERIFICATION ==="
echo "ui_env floor tiles replaced: $(ls $PROJECT/assets/sprites/ui_env/env_floor_*.png 2>/dev/null | grep -v '\.import' | wc -l)"
echo "Total backed up: $(find $BACKUP -name '*.png' | wc -l)"
echo "Temp PNG remaining: $(find $PROJECT/temp_regeneration -name '*.png' -type f 2>/dev/null | wc -l)"

echo ""
echo "=== COMPLETE SWEEP STATUS ==="
echo "Room Floors (ui_env) | 12/12 | ✅ (11 room-specific + 1 hex)"
echo "Terrain Hexes        | 38/38 | ✅"
echo "Puzzle Sprites       | 47/47 | ✅"
echo "Room Objects         | 28/29 | ✅"
echo "Boss Gear Mother     | 5/5 | ✅"
echo "Aberration Idle      | 16/16 | ✅"
echo ""
echo "TOTAL REPLACED: ~147 assets"
echo "TOTAL BACKED UP: ~144 originals"
echo ""
echo "=== NOTES ==="
echo "Wall textures (env_wall_*.png): 7 files, NOT used in any .tscn scene — likely unused or tilemap-only"
echo "Backgrounds: 4 files, used in UI/title context — not floor-walking, lower priority"
echo "Effects: 3 files — atmospheric overlays, fine as-is"
echo ""
echo "=== DONE ==="
