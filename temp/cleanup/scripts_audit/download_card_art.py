#!/usr/bin/env python3
"""
Download Card Art from Shrine and Extract to Godot Project
Run this on the server/workspace side
"""

import os
import base64
import zipfile
import io
import requests
from pathlib import Path

SHRINE_URL = "https://beckett-iritic-violette.ngrok-free.dev"
PROJECT_PATH = Path("/root/.openclaw/workspace/acanous_floor3_demo")
CARDS_PATH = PROJECT_PATH / "assets/sprites/cards"

def download_and_extract():
    """Download zip from shrine and extract to project"""
    print("Downloading card art from shrine...")
    
    url = f"{SHRINE_URL}/memory/card_art_complete"
    response = requests.get(url, timeout=60)
    
    if response.status_code != 200:
        print(f"❌ Download failed: {response.status_code}")
        return False
    
    data = response.json()
    
    # Decode base64 zip
    print("Decoding zip archive...")
    zip_data = base64.b64decode(data["zip_data"])
    
    # Extract
    print(f"Extracting {len(zip_data):,} bytes to {CARDS_PATH}...")
    zip_buffer = io.BytesIO(zip_data)
    
    with zipfile.ZipFile(zip_buffer, 'r') as zipf:
        for member in zipf.namelist():
            # Extract to assets/sprites/cards/
            zipf.extract(member, CARDS_PATH)
            print(f"  ✓ {member}")
    
    print("\n✅ All card art extracted!")
    return True

if __name__ == "__main__":
    download_and_extract()
