#!/bin/bash
# P0 Asset Integration Script — Move PASS assets into game, backup originals, delete FAILs from temp

set -e

PROJECT="/root/.openclaw/workspace/acanous_floor3_demo"
TEMP="$PROJECT/temp_regeneration"
BACKUP="$PROJECT/assets/sprites/_backup_may11"

mkdir -p "$BACKUP"

# ============================================================================
# PASS ASSETS — Move into game, backup originals
# ============================================================================

PASS_LIST=(
  # Bosses (2 pass)
  "bosses/boss_gear_mother_attack.png|assets/sprites/enemies/boss_gear_mother_attack.png"
  "bosses/boss_gear_mother_death.png|assets/sprites/enemies/boss_gear_mother_death.png"
  # Room objects (10 pass)
  "room_objects/flywheel_massive_gear.png|assets/sprites/room_objects/flywheel_massive_gear.png"
  "room_objects/oiler_barrel.png|assets/sprites/room_objects/oiler_barrel.png"
  "room_objects/warning_sign.png|assets/sprites/room_objects/warning_sign.png"
  "room_objects/tool_rack.png|assets/sprites/room_objects/tool_rack.png"
  "room_objects/bearing_housing.png|assets/sprites/room_objects/bearing_housing.png"
  "room_objects/spark_furnace.png|assets/sprites/room_objects/spark_furnace.png"
  "room_objects/temper_forge.png|assets/sprites/room_objects/temper_forge.png"
  "room_objects/quench_cooling_tank.png|assets/sprites/room_objects/quench_cooling_tank.png"
  "room_objects/governor_control_panel.png|assets/sprites/room_objects/governor_control_panel.png"
  "room_objects/counterweight_scale.png|assets/sprites/room_objects/counterweight_scale.png"
  # Enemies — all 16 pass (aberration idle frames)
  "enemies/enemy_the_bug_idle.png|assets/sprites/enemies/enemy_the_bug_idle.png"
  "enemies/enemy_the_lag_idle.png|assets/sprites/enemies/enemy_the_lag_idle.png"
  "enemies/enemy_the_echo_idle.png|assets/sprites/enemies/enemy_the_echo_idle.png"
  "enemies/enemy_the_loop_idle.png|assets/sprites/enemies/enemy_the_loop_idle.png"
  "enemies/enemy_the_cursor_idle.png|assets/sprites/enemies/enemy_the_cursor_idle.png"
  "enemies/enemy_the_default_idle.png|assets/sprites/enemies/enemy_the_default_idle.png"
  "enemies/enemy_the_collar_idle.png|assets/sprites/enemies/enemy_the_collar_idle.png"
  "enemies/enemy_the_contagion_idle.png|assets/sprites/enemies/enemy_the_contagion_idle.png"
  "enemies/enemy_the_hollow_idle.png|assets/sprites/enemies/enemy_the_hollow_idle.png"
  "enemies/enemy_the_forgotten_idle.png|assets/sprites/enemies/enemy_the_forgotten_idle.png"
  "enemies/enemy_the_whisper_idle.png|assets/sprites/enemies/enemy_the_whisper_idle.png"
  "enemies/enemy_the_mirror_idle.png|assets/sprites/enemies/enemy_the_mirror_idle.png"
  "enemies/enemy_the_duplicate_idle.png|assets/sprites/enemies/enemy_the_duplicate_idle.png"
  "enemies/enemy_the_refrain_idle.png|assets/sprites/enemies/enemy_the_refrain_idle.png"
  "enemies/enemy_the_eidolon_idle.png|assets/sprites/enemies/enemy_the_eidolon_idle.png"
  "enemies/enemy_the_interview_idle.png|assets/sprites/enemies/enemy_the_interview_idle.png"
)

for entry in "${PASS_LIST[@]}"; do
  IFS='|' read -r src tgt <<< "$entry"
  src_path="$TEMP/$src"
  tgt_path="$PROJECT/$tgt"
  
  if [ -f "$src_path" ]; then
    if [ -f "$tgt_path" ]; then
      # Backup original
      backup_dir="$BACKUP/$(dirname "$tgt")"
      mkdir -p "$backup_dir"
      mv "$tgt_path" "$backup_dir/"
      echo "[BACKUP] $tgt → $backup_dir/"
    fi
    # Move new asset into place
    mv "$src_path" "$tgt_path"
    echo "[MOVED] $src → $tgt"
  else
    echo "[MISSING] $src_path not found"
  fi
done

# ============================================================================
# FAIL ASSETS — Delete from temp (do NOT touch game originals)
# ============================================================================

FAIL_LIST=(
  "floors/floor_gear_tile.png"
  "floors/env_floor_hex.png"
  "bosses/boss_gear_mother_idle.png"
  "bosses/boss_gear_mother_damage.png"
  "bosses/boss_gear_mother_special.png"
)

for f in "${FAIL_LIST[@]}"; do
  fpath="$TEMP/$f"
  if [ -f "$fpath" ]; then
    rm "$fpath"
    echo "[DELETED] $f (fail, not matching)"
  fi
done

# ============================================================================
# CLEANUP — Delete any remaining .png in temp (should be none if logic correct)
# ============================================================================

find "$TEMP" -name "*.png" -type f -delete 2>/dev/null || true

echo ""
echo "=== INTEGRATION COMPLETE ==="
echo "Backup dir: $BACKUP"
echo "Temp folder cleaned."
