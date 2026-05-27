#!/usr/bin/env python3
"""
Update Overlay Cards — Rename .tres files, update references, swap art.
Run after new overlay art images are placed in assets/sprites/cards/Overlays/
"""

import os
import re
import shutil
from pathlib import Path

BASE_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo")
OVERLAY_TRES_DIR = BASE_DIR / "finished_cards/Overlays"
ART_DIR = BASE_DIR / "assets/sprites/cards/Overlays"

# Mapping: (old_tres_name, old_art_prefix, new_card_name, new_art_filename)
ARCANE_MAP = [
    ("Overlay_cache", "cache", "Arcane Infusion", "01_arcane_infusion.png"),
    ("Overlay_collapse", "collapse", "Arcane Surge", "02_arcane_surge.png"),
    ("Overlay_divination", "divination", "Arcane Weave", "03_arcane_weave.png"),
    ("Overlay_excavate", "excavate", "Arcane Shield", "04_arcane_shield.png"),
    ("Overlay_foresight", "foresight", "Arcane Bolt", "05_arcane_bolt.png"),
    ("Overlay_recall", "recall", "Arcane Mastery", "06_arcane_mastery.png"),
    ("Overlay_reshape", "reshape", "Arcane Resonance", "07_arcane_resonance.png"),
    ("Overlay_reverberate", "reverberate", "Arcane Overload", "08_arcane_overload.png"),
    ("Overlay_sift", "sift", "Arcane Echo", "09_arcane_echo.png"),
    ("Overlay_weave", "weave", "Arcane Catalyst", "10_arcane_catalyst.png"),
]

DIVINE_MAP = [
    ("Overlay_aegis", "aegis", "Divine Blessing", "01_divine_blessing.png"),
    ("Overlay_blessed", "blessed", "Divine Favor", "02_divine_favor.png"),
    ("Overlay_consecrated", "consecrated", "Divine Smite", "03_divine_smite.png"),
    ("Overlay_divine_favor", "divine_favor", "Divine Shield", "04_divine_shield.png"),
    ("Overlay_hallowed", "hallowed", "Divine Bolt", "05_divine_bolt.png"),
    ("Overlay_martyrdom", "martyrdom", "Divine Mastery", "06_divine_mastery.png"),
    ("Overlay_penance", "penance", "Divine Resonance", "07_divine_resonance.png"),
    ("Overlay_redemption", "redemption", "Divine Overload", "08_divine_overload.png"),
    ("Overlay_revelation", "revelation", "Divine Echo", "09_divine_echo.png"),
    ("Overlay_sanctified", "sanctified", "Divine Catalyst", "10_divine_catalyst.png"),
]

INFERNAL_MAP = [
    ("Overlay_bloodfiend", "bloodfiend", "Infernal Pact", "01_infernal_pact.png"),
    ("Overlay_corrupting_snare", "corrupting_snare", "Infernal Surge", "02_infernal_surge.png"),
    ("Overlay_dark_avatar", "dark_avatar", "Infernal Wrath", "03_infernal_wrath.png"),
    ("Overlay_festerspring", "festerspring", "Infernal Shield", "04_infernal_shield.png"),
    ("Overlay_masochists_trap", "masochists_trap", "Infernal Bolt", "05_infernal_bolt.png"),
    ("Overlay_painwrought", "painwrought", "Infernal Mastery", "06_infernal_mastery.png"),
    ("Overlay_soulhoarder", "soulhoarder", "Infernal Resonance", "07_infernal_resonance.png"),
    ("Overlay_soul_siphon_trap", "soul_siphon_trap", "Infernal Overload", "08_infernal_overload.png"),
    ("Overlay_tainted_blade", "tainted_blade", "Infernal Echo", "09_infernal_echo.png"),
    ("Overlay_void_pact", "void_pact", "Infernal Catalyst", "10_infernal_catalyst.png"),
]

ALL_MAPS = [
    (ARCANE_MAP, "Arcane", OVERLAY_TRES_DIR / "Arcane", ART_DIR / "Arcane"),
    (DIVINE_MAP, "Divine", OVERLAY_TRES_DIR / "Divine", ART_DIR / "Divine"),
    (INFERNAL_MAP, "Infernal", OVERLAY_TRES_DIR / "Infernal", ART_DIR / "Infernal"),
]


def update_tres_file(tres_path: Path, new_name: str, new_art_path: str) -> bool:
    """Update card_name and sprite_texture_path inside a .tres file."""
    try:
        content = tres_path.read_text()
    except Exception as e:
        print(f"  ✗ Cannot read {tres_path}: {e}")
        return False

    # Update card_name
    content = re.sub(
        r'card_name = ".*?"',
        f'card_name = "{new_name}"',
        content
    )

    # Update sprite_texture_path
    content = re.sub(
        r'sprite_texture_path = ".*?"',
        f'sprite_texture_path = "{new_art_path}"',
        content
    )

    try:
        tres_path.write_text(content)
        print(f"  ✓ Updated {tres_path.name} → {new_name}")
        return True
    except Exception as e:
        print(f"  ✗ Cannot write {tres_path}: {e}")
        return False


def rename_tres(tres_dir: Path, old_name: str, new_name: str) -> Path:
    """Rename .tres file from old name to new name."""
    old_path = tres_dir / f"{old_name}.tres"
    new_path = tres_dir / f"Overlay_{new_name.lower().replace(' ', '_')}.tres"

    if not old_path.exists():
        print(f"  ✗ Missing: {old_path}")
        return None

    try:
        old_path.rename(new_path)
        print(f"  ✓ Renamed {old_path.name} → {new_path.name}")
        return new_path
    except Exception as e:
        print(f"  ✗ Cannot rename {old_path}: {e}")
        return None


def clean_old_art(art_dir: Path, old_prefix: str):
    """Delete old art files matching the old prefix."""
    for f in art_dir.iterdir():
        if f.is_file() and f.stem.startswith(old_prefix):
            try:
                f.unlink()
                print(f"  ✓ Deleted old art: {f.name}")
            except Exception as e:
                print(f"  ✗ Cannot delete {f}: {e}")


def main():
    print("=== Overlay Card Update ===\n")

    total_updated = 0
    total_renamed = 0

    for mapping, faction_name, tres_dir, art_dir in ALL_MAPS:
        print(f"\n--- {faction_name} ({len(mapping)} cards) ---")

        for old_tres, old_art_prefix, new_name, new_art_file in mapping:
            # 1. Rename .tres file
            new_tres_path = rename_tres(tres_dir, old_tres, new_name)
            if new_tres_path:
                total_renamed += 1

                # 2. Update contents
                new_art_full_path = f"res://assets/sprites/cards/Overlays/{faction_name}/{new_art_file}"
                if update_tres_file(new_tres_path, new_name, new_art_full_path):
                    total_updated += 1

            # 3. Clean old art (only if new art exists)
            new_art_path = art_dir / new_art_file
            if new_art_path.exists():
                clean_old_art(art_dir, old_art_prefix)
            else:
                print(f"  ⚠ New art not found yet: {new_art_path}")

    print(f"\n=== Summary ===")
    print(f"Renamed: {total_renamed}/30")
    print(f"Updated: {total_updated}/30")
    print(f"\nNext: Generate missing art, then re-run to clean old files.")


if __name__ == "__main__":
    main()
