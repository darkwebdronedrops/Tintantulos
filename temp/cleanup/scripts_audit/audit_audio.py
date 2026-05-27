#!/usr/bin/env python3
"""Comprehensive Audio Audit for Tower of Tintantulos"""
import os, re
from pathlib import Path

BASE = Path("/root/.openclaw/workspace/acanous_floor3_demo")

# Find all audio files
AUDIO_DIRS = {
    "music": BASE / "assets/audio/music",
    "sfx": BASE / "assets/audio/sfx",
    "ambient": BASE / "assets/audio/ambient",
    "ui": BASE / "assets/audio/ui",
}

def get_audio_files():
    files = {}
    for category, dir_path in AUDIO_DIRS.items():
        if not dir_path.exists():
            files[category] = []
            continue
        files[category] = [f for f in dir_path.iterdir() if f.suffix in ('.mp3', '.wav', '.ogg')]
    return files

def find_audio_references():
    """Find all res://assets/audio/... references in .tscn, .gd, .tres files"""
    refs = {}
    for ext in ('.tscn', '.gd', '.tres'):
        for f in BASE.rglob(f'*{ext}'):
            try:
                with open(f, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                matches = re.findall(r'res://assets/audio/[^"\'\s]+', content)
                for m in matches:
                    path = m.replace('res://', '')
                    if path not in refs:
                        refs[path] = []
                    refs[path].append(str(f.relative_to(BASE)))
            except:
                pass
    return refs

def is_placeholder_audio(file_path):
    """Heuristic: tiny files or files with placeholder-like names"""
    size = file_path.stat().st_size
    name = file_path.name.lower()
    
    # WAV files from March that are suspiciously small
    if size < 10000 and file_path.suffix == '.wav':
        return True
    
    # Files with placeholder names
    placeholder_names = ['placeholder', 'temp', 'test', 'dummy']
    if any(p in name for p in placeholder_names):
        return True
    
    return False

if __name__ == "__main__":
    audio_files = get_audio_files()
    refs = find_audio_references()
    
    print("=" * 60)
    print("AUDIO ASSET AUDIT — Tower of Tintantulos")
    print("=" * 60)
    
    total_files = 0
    total_used = 0
    total_placeholder = 0
    
    for category, files in audio_files.items():
        print(f"\n{'='*40}")
        print(f"CATEGORY: {category.upper()}")
        print(f"{'='*40}")
        
        if not files:
            print("  Directory does not exist or is empty")
            continue
        
        used = 0
        unused = 0
        placeholder = 0
        real = 0
        
        for f in sorted(files):
            rel = str(f.relative_to(BASE))
            is_used = rel in refs
            is_ph = is_placeholder_audio(f)
            size = f.stat().st_size
            
            total_files += 1
            if is_used:
                total_used += 1
                used += 1
            else:
                unused += 1
            
            if is_ph:
                total_placeholder += 1
                placeholder += 1
            else:
                real += 1
            
            status = "✅ USED" if is_used else "❌ UNUSED"
            ph_mark = " [PH]" if is_ph else ""
            print(f"  {f.name} ({size//1024}KB) {status}{ph_mark}")
            
            if is_used and rel in refs:
                for src in refs[rel][:3]:
                    print(f"    → {src}")
                if len(refs[rel]) > 3:
                    print(f"    → ... and {len(refs[rel])-3} more refs")
        
        print(f"\n  Summary: {len(files)} files | {used} used | {unused} unused | {placeholder} placeholder | {real} real")
    
    print(f"\n{'='*60}")
    print("GRAND TOTAL")
    print(f"{'='*60}")
    print(f"  Total audio files: {total_files}")
    print(f"  Referenced by project: {total_used}")
    print(f"  Unreferenced: {total_files - total_used}")
    print(f"  Placeholder files: {total_placeholder}")
    print(f"  Real files: {total_files - total_placeholder}")
    
    # Check for .import files
    print(f"\n{'='*60}")
    print("GODOT IMPORT STATUS")
    print(f"{'='*60}")
    for category, files in audio_files.items():
        if not files:
            continue
        imported = 0
        not_imported = 0
        for f in files:
            import_file = f.with_suffix(f.suffix + '.import')
            if import_file.exists():
                imported += 1
            else:
                not_imported += 1
        print(f"  {category}: {imported} with .import | {not_imported} missing .import")
    
    print(f"\n{'='*60}")
    print("RECOMMENDATIONS")
    print(f"{'='*60}")
    print("  1. Unused real files: Consider deleting or wiring into scenes")
    print("  2. Placeholder files: Replace with generated assets or delete")
    print("  3. Missing .import: Open project in Godot to auto-generate")
    print("  4. Categories: Can eliminate if empty, but keep structure for future")
