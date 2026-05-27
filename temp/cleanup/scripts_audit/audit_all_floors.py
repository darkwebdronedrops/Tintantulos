#!/usr/bin/env python3
"""Comprehensive floor asset audit — primitives vs real art, with .tscn cross-reference"""
import os, re
from pathlib import Path
from PIL import Image

BASE = Path("/root/.openclaw/workspace/acanous_floor3_demo")

# Find all .tscn files and extract texture references
def get_used_textures():
    used = set()
    tscn_files = list(BASE.rglob("*.tscn"))
    for tscn in tscn_files:
        with open(tscn) as f:
            content = f.read()
        # Match res://assets/sprites/floorX/...png
        matches = re.findall(r'res://assets/sprites/[^"\']+\.png', content)
        for m in matches:
            # Convert to filesystem path
            path = m.replace('res://', '')
            used.add(path)
    return used

def audit_floor(floor_num, used_textures):
    d = BASE / f"assets/sprites/floor{floor_num}"
    if not d.exists():
        return None
    
    results = []
    for f in sorted(d.glob("*.png")):
        if f.name.endswith('.import'):
            continue
        size_bytes = f.stat().st_size
        rel_path = str(f.relative_to(BASE))
        is_used = rel_path in used_textures
        
        # Quick primitive check: tiny files or text-heavy
        is_suspect = size_bytes < 3000
        
        results.append({
            'name': f.name,
            'size': size_bytes,
            'used': is_used,
            'suspect': is_suspect,
            'path': rel_path,
        })
    
    return results

if __name__ == "__main__":
    used = get_used_textures()
    print(f"Found {len(used)} textures referenced in .tscn files\n")
    
    for floor in range(1, 11):
        results = audit_floor(floor, used)
        if not results:
            print(f"=== FLOOR {floor}: NO SPRITES ===\n")
            continue
        
        total = len(results)
        suspects = [r for r in results if r['suspect']]
        used_suspects = [r for r in suspects if r['used']]
        unused_suspects = [r for r in suspects if not r['used']]
        
        print(f"=== FLOOR {floor}: {total} files ===")
        print(f"  Suspects (<3KB): {len(suspects)}")
        print(f"    - Used in scenes: {len(used_suspects)}")
        print(f"    - Unused: {len(unused_suspects)}")
        
        if used_suspects:
            print(f"  ⚠️ USED PRIMITIVES (need replacement):")
            for r in used_suspects:
                print(f"    {r['name']}: {r['size']} bytes")
        
        if unused_suspects:
            print(f"  ℹ️  Unused suspects (can ignore or clean):")
            for r in unused_suspects[:5]:
                print(f"    {r['name']}: {r['size']} bytes")
            if len(unused_suspects) > 5:
                print(f"    ... and {len(unused_suspects)-5} more")
        
        print()
