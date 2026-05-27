#!/usr/bin/env python3
"""
Floor 1 South Shrine — One more simple try
"""

import requests
import base64
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/floor1_retry3")

name = "floor1_south_shrine_v5"
desc = "pixel art flat tile, golden metal ground surface, top down view, no walls, adventure game"

try:
    resp = requests.post(
        f"{BASE_URL}/generate-image-pixflux",
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        json={"description": desc, "image_size": {"width": 256, "height": 256}, "no_background": True, "seed": 1100},
        timeout=120,
    )
    if resp.status_code == 200:
        data = resp.json()
        img_data = data.get("image")
        img_b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
        if img_b64:
            out = OUTPUT_DIR / f"{name}.png"
            out.write_bytes(base64.b64decode(img_b64))
            print(f"[OK] {name}.png")
        else:
            print("[FAIL] No image data")
    else:
        print(f"[FAIL] HTTP {resp.status_code}")
except Exception as e:
    print(f"[ERROR] {e}")
