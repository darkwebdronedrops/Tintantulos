#!/usr/bin/env python3
"""
Floor 3 Background Replacement — The Understructure
Replaces bg_crown_cog_hub.png (tower viewed from below) with the mechanical "beneath"
"""

import requests
import base64
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/backgrounds/bg_crown_cog_hub.png")
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

prompt = (
    "pixel art background, 1920x1080, dark industrial steampunk, "
    "viewed from 60 degrees above, looking down onto massive mechanical understructure, "
    "the beneath of a clocktower, enormous brass gears and cogs interlocking, "
    "piston arrays, steam pipes, conduits, drive shafts, flywheels, bearing housings, "
    "oil reservoirs, pressure gauges, riveted iron plates, dark bronze and copper tones, "
    "the machinery that rotates hexagonal rooms, parallel projection, no vanishing points, "
    "muted metallic colors, grimy industrial, deepest level of a machine tower"
)

try:
    resp = requests.post(
        f"{BASE_URL}/generate-image-pixflux",
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        json={"description": prompt, "image_size": {"width": 256, "height": 256}, "seed": 500},
        timeout=180,
    )
    if resp.status_code == 200:
        data = resp.json()
        img_data = data.get("image")
        img_b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
        if img_b64:
            OUTPUT.write_bytes(base64.b64decode(img_b64))
            print(f"[OK] bg_crown_cog_hub.png ({len(base64.b64decode(img_b64))} bytes)")
        else:
            print("[FAIL] No image data")
    else:
        print(f"[FAIL] HTTP {resp.status_code}")
except Exception as e:
    print(f"[ERROR] {e}")
