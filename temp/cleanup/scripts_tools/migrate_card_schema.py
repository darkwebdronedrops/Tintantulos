#!/usr/bin/env python3
"""
Card Data Schema Migration — Update all .tres files to match CardData.gd
Backup created before any modifications.
"""

import shutil
from pathlib import Path
import re

BASE = Path("/root/.openclaw/workspace/acanous_floor3_demo")
FINISHED = BASE / "finished_cards"
BACKUP = BASE / "finished_cards_BACKUP_PRE_MIGRATION"

# Field mappings: old_name → new_name
FIELD_RENAMES = {
    "cast_cost": "trap_cast_cost",
    "trigger_cost": "trap_trigger_cost",
    "disarm_cost": "trap_disarm_cost",
    "trap_trigger": "trap_trigger_action",
    "trap_disarm": "trap_disarm_action",
    "field_persistent": "field_persist",
    "field_radius": "aoe_radius",
    "card_draw": None,  # Remove - quiddity_gain already exists
    "radius": None,  # Remove - aoe_radius already exists
    "line_length": None,  # Remove - no equivalent
    "target_type": None,  # Remove - no equivalent
    "ignore_defense": None,  # Remove - no equivalent
    "multi_hit": None,  # Remove - no equivalent
    "enemy_quiddity_steal": None,  # Remove - no equivalent
    "requires_line_of_sight": None,  # Remove - no equivalent
    "is_quick": None,  # Remove - no equivalent
    "is_react": None,  # Remove - no equivalent
    "prerequisite_cards": None,  # Remove - no equivalent
    "upgrade_targets": None,  # Remove - no equivalent
    "alt_version": None,  # Remove - no equivalent
    "is_alt_version": None,  # Remove - no equivalent
    "is_dragon": None,  # Remove - no equivalent
    "is_gold": None,  # Remove - no equivalent
    "is_token": None,  # Remove - no equivalent
}

# Card types to fix
CARD_TYPE_FIXES = {
    "Counterspell": "Special",
    "Dispel": "Special",
    "Suppress": "Special",
}

def create_backup():
    """Create a full backup of finished_cards directory."""
    if BACKUP.exists():
        print(f"Backup already exists at {BACKUP}")
        return True
    
    print(f"Creating backup: {BACKUP}")
    shutil.copytree(FINISHED, BACKUP)
    print("Backup complete.")
    return True

def migrate_tres_file(tres_path: Path) -> tuple[bool, list[str]]:
    """
    Migrate a single .tres file to the new schema.
    Returns (success, list of changes made)
    """
    changes = []
    
    try:
        content = tres_path.read_text()
    except Exception as e:
        return False, [f"ERROR reading: {e}"]
    
    original = content
    
    # 1. Rename fields
    for old_name, new_name in FIELD_RENAMES.items():
        if new_name is None:
            # Remove the field entirely
            # Match lines like: old_name = value
            pattern = rf'^\s*{re.escape(old_name)}\s*=\s*[^\n]*\n'
            if re.search(pattern, content, re.MULTILINE):
                content = re.sub(pattern, '', content, flags=re.MULTILINE)
                changes.append(f"Removed '{old_name}'")
        else:
            # Rename the field
            # Match: old_name = value (with optional leading whitespace)
            pattern = rf'^(\s*){re.escape(old_name)}(\s*=)'
            if re.search(pattern, content, re.MULTILINE):
                content = re.sub(pattern, rf'\g<1>{new_name}\g<2>', content, flags=re.MULTILINE)
                changes.append(f"Renamed '{old_name}' → '{new_name}'")
    
    # 2. Fix card types for specific cards
    # Extract card_name to check if we need to fix its type
    name_match = re.search(r'card_name\s*=\s*"([^"]*)"', content)
    if name_match:
        card_name = name_match.group(1)
        if card_name in CARD_TYPE_FIXES:
            old_type = re.search(r'card_type\s*=\s*"([^"]*)"', content)
            if old_type:
                old_type_val = old_type.group(1)
                new_type_val = CARD_TYPE_FIXES[card_name]
                if old_type_val != new_type_val:
                    content = content.replace(
                        f'card_type = "{old_type_val}"',
                        f'card_type = "{new_type_val}"'
                    )
                    changes.append(f"Changed card_type '{old_type_val}' → '{new_type_val}'")
    
    # 3. Remove duplicate sprite_texture_path lines (some files have it twice)
    sprite_lines = re.findall(r'sprite_texture_path\s*=\s*"[^"]*"', content)
    if len(sprite_lines) > 1:
        # Keep only the first occurrence, remove subsequent ones
        lines = content.split('\n')
        seen_sprite = False
        new_lines = []
        for line in lines:
            if 'sprite_texture_path' in line:
                if not seen_sprite:
                    seen_sprite = True
                    new_lines.append(line)
                else:
                    changes.append("Removed duplicate sprite_texture_path")
            else:
                new_lines.append(line)
        content = '\n'.join(new_lines)
    
    # 4. Clean up multiple consecutive blank lines
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    # Write back if changed
    if content != original:
        try:
            tres_path.write_text(content)
            return True, changes
        except Exception as e:
            return False, [f"ERROR writing: {e}"]
    
    return True, ["No changes needed"]

def main():
    print("=" * 60)
    print("CARD DATA SCHEMA MIGRATION")
    print("=" * 60)
    
    # Step 1: Backup
    create_backup()
    
    # Step 2: Migrate all .tres files
    print(f"\nMigrating files in {FINISHED}")
    
    total_files = 0
    changed_files = 0
    error_files = 0
    total_changes = 0
    
    for tres_path in sorted(FINISHED.rglob("*.tres")):
        total_files += 1
        success, changes = migrate_tres_file(tres_path)
        
        if success:
            if changes and changes != ["No changes needed"]:
                changed_files += 1
                total_changes += len(changes)
                if len(changes) <= 3:  # Only print for files with few changes (interesting ones)
                    print(f"  ✓ {tres_path.name}: {', '.join(changes)}")
        else:
            error_files += 1
            print(f"  ✗ {tres_path.name}: {changes[0]}")
    
    print(f"\n{'='*60}")
    print("MIGRATION COMPLETE")
    print(f"{'='*60}")
    print(f"Total files: {total_files}")
    print(f"Files changed: {changed_files}")
    print(f"Errors: {error_files}")
    print(f"Total field changes: {total_changes}")
    print(f"\nBackup location: {BACKUP}")
    print(f"To restore: rm -rf {FINISHED} && cp -r {BACKUP} {FINISHED}")

if __name__ == "__main__":
    main()
