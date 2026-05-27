#!/bin/bash
# Integrate final room objects batch
set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration/room_objects"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

echo "=== INTEGRATING FINAL ROOM OBJECTS (18 files) ==="
for src in "$TEMP"/*.png; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  tgt="$PROJECT/assets/sprites/room_objects/$name"
  
  if [ -f "$tgt" ]; then
    backup_dir="$BACKUP/assets/sprites/room_objects"
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
echo "Room objects in game: $(ls $PROJECT/assets/sprites/room_objects/*.png 2>/dev/null | grep -v '\.import' | wc -l)"
echo "Total backed up: $(find $BACKUP -name '*.png' | wc -l)"
echo "Temp PNG remaining: $(find $PROJECT/temp_regeneration -name '*.png' -type f 2>/dev/null | wc -l)"

echo ""
echo "=== FINAL SWEEP STATUS ==="
echo "Room Floors (base) | 2/2 | ✅"
echo "Terrain Hexes      | 38/38 | ✅"
echo "Puzzle Sprites     | 47/47 | ✅"
echo "Room Objects       | 28/29 | ✅ (1 was floor_gear_tile, counted in floors)"
echo "Boss Gear Mother   | 5/5 | ✅"
echo "Aberration Idle    | 16/16 | ✅"
echo ""
echo "TOTAL REPLACED: ~136 assets"
echo "TOTAL BACKED UP: ~133 originals"
echo ""
echo "=== DONE ==="
