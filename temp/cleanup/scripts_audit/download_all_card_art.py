#!/usr/bin/env python3
"""
Download ALL Card Art from Shrine
Queries all card_art_* keys and downloads them to the project
"""

import os
import base64
import json
import requests
from pathlib import Path

SHRINE_URL = "https://beckett-iritic-violette.ngrok-free.dev"
PROJECT_PATH = Path("/root/.openclaw/workspace/acanous_floor3_demo")
CARDS_PATH = PROJECT_PATH / "assets/sprites/cards"

# Ensure all faction folders exist
FACTIONS = ["Aberration", "Construct", "Demon", "Dragon", 
            "Elemental", "Goblin", "Overlays", "Undead", "Universal"]

def ensure_folders():
    """Create faction folders if they don't exist"""
    for faction in FACTIONS:
        folder = CARDS_PATH / faction
        folder.mkdir(parents=True, exist_ok=True)
        print(f"  📁 {faction}/")

def list_card_art_keys():
    """Query shrine for all card_art keys"""
    # Try to get a list or search for card_art keys
    # For now, we'll iterate through expected factions and query each
    keys = []
    
    # Get memory index if available
    try:
        response = requests.get(f"{SHRINE_URL}/memory", timeout=30)
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, dict) and "keys" in data:
                all_keys = data["keys"]
                keys = [k for k in all_keys if k.startswith("card_art_")]
                print(f"Found {len(keys)} card_art entries in shrine")
    except Exception as e:
        print(f"Could not list keys: {e}")
        print("Will try direct faction queries...")
    
    return keys

def download_card(key: str):
    """Download a single card from shrine"""
    url = f"{SHRINE_URL}/memory/{key}"
    
    try:
        response = requests.get(url, timeout=30)
        if response.status_code != 200:
            return False
        
        data = response.json()
        
        # Extract metadata
        faction = data.get("faction", "Unknown")
        filename = data.get("filename", f"{key}.png")
        image_b64 = data.get("image_data", "")
        
        if not image_b64:
            print(f"  ⚠ No image data for {key}")
            return False
        
        # Decode and save
        image_bytes = base64.b64decode(image_b64)
        faction_folder = CARDS_PATH / faction
        faction_folder.mkdir(parents=True, exist_ok=True)
        
        output_path = faction_folder / filename
        with open(output_path, "wb") as f:
            f.write(image_bytes)
        
        print(f"  ✓ {faction}/{filename} ({len(image_bytes):,} bytes)")
        return True
        
    except Exception as e:
        print(f"  ✗ Error downloading {key}: {e}")
        return False

def download_all_by_pattern():
    """Download cards by trying all expected patterns"""
    total = 0
    success = 0
    
    # Card counts per faction
    card_counts = {
        "Aberration": 30,
        "Construct": 30,
        "Demon": 30,
        "Dragon": 10,
        "Elemental": 30,
        "Goblin": 30,
        "Overlays": 30,
        "Undead": 30,
        "Universal": 25
    }
    
    print("Downloading cards from Shrine...")
    print(f"Destination: {CARDS_PATH}\n")
    
    # Ensure folders exist
    ensure_folders()
    print()
    
    # Try to list all keys first
    keys = list_card_art_keys()
    
    if keys:
        # We got a list, download each
        print(f"\nDownloading {len(keys)} cards...")
        for key in keys:
            total += 1
            if download_card(key):
                success += 1
    else:
        # Try direct queries for each faction
        print("\nTrying faction-by-faction download...")
        
        for faction, count in card_counts.items():
            print(f"\n📁 {faction} (expecting {count} cards)...")
            
            # Try to get cards 01-30 (or however many)
            for i in range(1, count + 1):
                # Try different key patterns
                key_patterns = [
                    f"card_art_{faction.lower()}_{i:02d}",
                    f"card_art_{faction.lower()}_{i}",
                ]
                
                for key in key_patterns:
                    url = f"{SHRINE_URL}/memory/{key}"
                    try:
                        response = requests.get(url, timeout=10)
                        if response.status_code == 200:
                            total += 1
                            if download_card(key):
                                success += 1
                            break  # Found it, move to next card
                    except:
                        pass
    
    print(f"\n{'='*50}")
    print(f"DOWNLOAD COMPLETE")
    print(f"{'='*50}")
    print(f"Total attempts: {total}")
    print(f"Successful: {success}")
    print(f"Failed: {total - success}")
    
    return success

if __name__ == "__main__":
    try:
        import requests
    except ImportError:
        print("Installing requests...")
        os.system("pip install requests --break-system-packages")
        import requests
    
    download_all_by_pattern()
