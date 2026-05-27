#!/usr/bin/env python3
"""
Upload existing Card Art.zip to Shrine
"""

import os
import base64
import requests
from pathlib import Path

SHRINE_URL = "https://beckett-iritic-violette.ngrok-free.dev"
ZIP_PATH = Path("C:/Users/acano/Desktop/Card Art.zip")

def upload_zip():
    """Upload the zip file to shrine"""
    if not ZIP_PATH.exists():
        print(f"❌ Zip not found: {ZIP_PATH}")
        return False
    
    # Read zip file
    print(f"Reading {ZIP_PATH.name}...")
    with open(ZIP_PATH, "rb") as f:
        zip_data = f.read()
    
    print(f"Size: {len(zip_data):,} bytes ({len(zip_data)/1024/1024:.1f} MB)")
    
    # Base64 encode
    print("Encoding...")
    encoded = base64.b64encode(zip_data).decode('utf-8')
    
    # Prepare payload
    payload = {
        "category": "card_art",
        "type": "zip_archive",
        "filename": "card_art_complete.zip",
        "zip_data": encoded,
        "content_type": "application/zip"
    }
    
    # POST to shrine
    print("Uploading to shrine (this may take a minute)...")
    url = f"{SHRINE_URL}/memory/card_art_complete"
    response = requests.post(url, json=payload, timeout=300)  # 5 min timeout for big zip
    
    if response.status_code == 200:
        print("✅ Upload successful!")
        print(f"Memory key: card_art_complete")
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
    
    print("=== Upload Card Art.zip to Shrine ===")
    upload_zip()