#!/bin/bash
# Move Round 2 PASS assets into game, backup originals

set -e
PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

mkdir -p "$BACKUP"

PASS_LIST=(
  "floors/floor_gear_tile.png|assets/sprites/room_objects/floor_gear_tile.png"
  "floors/env_floor_hex.png|assets/sprites/ui_env/env_floor_hex.png"
)

for entry in "${PASS_LIST[@]}"; do
  IFS='|' read -r src tgt <<< "$entry"
  src_path="$TEMP/$src"
  tgt_path="$PROJECT/$tgt"
  
  if [ -f "$src_path" ]; then
    if [ -f "$tgt_path" ]; then
      backup_dir="$BACKUP/$(dirname "$tgt")"
      mkdir -p "$backup_dir"
      mv "$tgt_path" "$backup_dir/"
      echo "[BACKUP] $tgt"
    fi
    mv "$src_path" "$tgt_path"
    echo "[MOVED] $src → $tgt"
  fi
done

echo "=== Round 2 integration complete ==="
