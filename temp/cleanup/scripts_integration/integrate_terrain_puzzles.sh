#!/bin/bash
# Bulk integration — Terrain + Puzzles
# Backs up originals, moves new assets into place

set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

mkdir -p "$BACKUP"

echo "=== INTEGRATING TERRAIN HEXES (38 files) ==="
for src in "$TEMP"/terrain/*.png; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  tgt="$PROJECT/assets/sprites/terrain/$name"
  
  if [ -f "$tgt" ]; then
    backup_dir="$BACKUP/assets/sprites/terrain"
    mkdir -p "$backup_dir"
    mv "$tgt" "$backup_dir/"
  fi
  mv "$src" "$tgt"
  echo "  [MOVED] terrain/$name"
done

echo ""
echo "=== INTEGRATING PUZZLE SPRITES (47 files) ==="
for src in "$TEMP"/puzzles/*.png; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  tgt="$PROJECT/assets/sprites/puzzles/$name"
  
  if [ -f "$tgt" ]; then
    backup_dir="$BACKUP/assets/sprites/puzzles"
    mkdir -p "$backup_dir"
    mv "$tgt" "$backup_dir/"
  fi
  mv "$src" "$tgt"
  echo "  [MOVED] puzzles/$name"
done

echo ""
echo "=== CLEANUP ==="
find "$TEMP" -name "*.png" -type f -delete 2>/dev/null || true

echo ""
echo "=== VERIFICATION ==="
echo "Terrain files now in game: $(ls $PROJECT/assets/sprites/terrain/*.png 2>/dev/null | grep -v '\.import' | wc -l)"
echo "Puzzle files now in game: $(ls $PROJECT/assets/sprites/puzzles/*.png 2>/dev/null | grep -v '\.import' | wc -l)"
echo "Total backed up: $(find $BACKUP -name '*.png' | wc -l)"
echo "PNG remaining in temp: $(find $TEMP -name '*.png' -type f | wc -l)"

echo ""
echo "=== DONE ==="
