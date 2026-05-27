#!/usr/bin/env python3
"""
Upload Card Art ZIP to Shrine
Single archive upload - much faster than 240 individual requests
"""

import os
import base64
import zipfile
import io
import requests
from pathlib import Path

SHRINE_URL = "https://beckett-iritic-violette.ngrok-free.dev"
CARD_ART_PATH = Path("C:/Users/acano/Desktop/Card Art")

def create_zip_in_memory():
    """Create a zip file in memory containing all card art"""
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Walk through Card Art folder
        for faction_folder in CARD_ART_PATH.iterdir():
            if not faction_folder.is_dir():
                continue
            
            faction = faction_folder.name
            print(f"📁 Adding {faction}...")
            
            # Add all PNG files from this faction
            for png_file in faction_folder.glob("*.png"):
                # Store with path: Aberration/cardname.png
                arcname = f"{faction}/{png_file.name}"
                zipf.write(png_file, arcname)
                print(f"  + {arcname}")
    
    zip_buffer.seek(0)
    return zip_buffer.read()

def upload_zip():
    """Upload the zip archive to shrine"""
    print("Creating zip archive...")
    zip_data = create_zip_in_memory()
    
    # Base64 encode
    print(f"Encoding {len(zip_data)} bytes...")
    encoded = base64.b64encode(zip_data).decode('utf-8')
    
    # Prepare payload
    payload = {
        "category": "card_art",
        "type": "zip_archive",
        "filename": "card_art_complete.zip",
        "zip_data": encoded,
        "content_type": "application/zip",
        "file_count": 240,  # Expected count
        "folders": ["Aberration", "Construct", "Demon", "Dragon", 
                   "Elemental", "Goblin", "Overlays", "Undead", "Universal"]
    }
    
    # POST to shrine
    print("Uploading to shrine...")
    url = f"{SHRINE_URL}/memory/card_art_complete"
    response = requests.post(url, json=payload, timeout=120)
    
    if response.status_code == 200:
        print("✅ Upload successful!")
        print(f"Memory key: card_art_complete")
        print(f"Size: {len(zip_data):,} bytes")
        return True
    else:
        print(f"❌ Upload failed: {response.status_code}")
        print(response.text)
        return False

if __name__ == "__main__":
    try:
        import requests
    except ImportError:
        print("Installing requests module...")
        os.system("pip install requests")
        import requests
    
    print("=== Card Art ZIP Upload ===")
    print(f"Source: {CARD_ART_PATH}")
    print(f"Destination: {SHRINE_URL}/memory/card_art_complete")
    print()
    
    upload_zip()