#!/usr/bin/env python3
"""
Upload Card Art to Shrine
Run this on your local machine where the Card Art folder exists
"""

import os
import base64
import json
import requests
from pathlib import Path

SHRINE_URL = "https://beckett-iritic-violette.ngrok-free.dev"
CARD_ART_PATH = Path("C:/Users/acano/Desktop/Card Art")

def upload_image(faction: str, filename: str, image_data: bytes):
    """Upload a single image to the shrine"""
    # Create memory key: card_art_undead_01_skeleton_warrior
    card_name = Path(filename).stem
    key = f"card_art_{faction.lower()}_{card_name.lower()}"
    
    # Base64 encode the image
    encoded = base64.b64encode(image_data).decode('utf-8')
    
    # Prepare payload
    payload = {
        "category": "card_art",
        "faction": faction,
        "filename": filename,
        "image_data": encoded,
        "content_type": "image/png"
    }
    
    # POST to shrine
    url = f"{SHRINE_URL}/memory/{key}"
    response = requests.post(url, json=payload, timeout=30)
    
    if response.status_code == 200:
        print(f"  ✓ Uploaded: {faction}/{filename}")
        return True
    else:
        print(f"  ✗ Failed: {faction}/{filename} - {response.status_code}")
        return False

def upload_all():
    """Walk Card Art folder and upload all images"""
    total = 0
    success = 0
    
    # Expected factions
    factions = ["Aberration", "Construct", "Demon", "Dragon", 
                "Elemental", "Goblin", "Overlays", "Undead", "Universal"]
    
    for faction in factions:
        faction_path = CARD_ART_PATH / faction
        if not faction_path.exists():
            print(f"⚠ Folder not found: {faction_path}")
            continue
        
        print(f"\n📁 Processing {faction}...")
        
        # Get all PNG files
        png_files = sorted(faction_path.glob("*.png"))
        
        for png_file in png_files:
            total += 1
            try:
                with open(png_file, "rb") as f:
                    image_data = f.read()
                
                if upload_image(faction, png_file.name, image_data):
                    success += 1
                    
            except Exception as e:
                print(f"  ✗ Error with {png_file}: {e}")
    
    print(f"\n=== UPLOAD COMPLETE ===")
    print(f"Total: {total}")
    print(f"Success: {success}")
    print(f"Failed: {total - success}")

if __name__ == "__main__":
    # Check if requests is installed
    try:
        import requests
    except ImportError:
        print("Installing requests module...")
        os.system("pip install requests")
        import requests
    
    print("Uploading Card Art to Shrine...")
    print(f"Source: {CARD_ART_PATH}")
    print(f"Destination: {SHRINE_URL}")
    print()
    
    upload_all()