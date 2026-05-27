import requests
import json
import os
import base64

# PixelLab API focused batch — environmental/UI chrome
# 5 high-impact sprites that will make the game look shippable

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUTPUT_DIR = "assets/sprites/ui_env/"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Specs — be selective, maximum impact per sprite
BATCH = [
    {
        "id": "ui_hud_panel",
        "filename": "ui_hud_panel.png",
        "description": "A decorative brass and copper metal panel with gear motifs, rivets, and ornate industrial borders. Steampunk factory aesthetic. Flat 2D UI element, no perspective. Dark patina with warm gold highlights. Pixel art style.",
        "width": 256,
        "height": 128,
        "view": "side"
    },
    {
        "id": "ui_bar_frame",
        "filename": "ui_bar_frame.png",
        "description": "A thin ornate metal bar frame with rivets and brass trim. Industrial steampunk aesthetic. Horizontal rectangular border for a progress bar. Dark iron with gold accents. Pixel art style.",
        "width": 256,
        "height": 32,
        "view": "side"
    },
    {
        "id": "env_wall_metal",
        "filename": "env_wall_metal.png",
        "description": "A riveted metal wall texture with industrial plating, bolts, and seams. Factory interior wall. Dark steel with rust patches and oil stains. Somewhat flat lighting for tiling. Pixel art style.",
        "width": 400,
        "height": 400,
        "view": "side"
    },
    {
        "id": "env_floor_hex",
        "filename": "env_floor_hex.png",
        "description": "A hexagonal tile floor pattern with metal grating, industrial factory flooring. Dark iron with some worn brass inlay between hex tiles. Top-down view for tiling. Pixel art style.",
        "width": 400,
        "height": 400,
        "view": "high top-down"
    },
    {
        "id": "bg_title_gearworks",
        "filename": "bg_title_gearworks.png",
        "description": "A dramatic dark industrial landscape showing a massive underground gearworks factory. Towering gears, steam pipes, glowing furnaces in the distance. Atmospheric lighting with warm orange glows against cold blue shadows. Cinematic wide-angle view. Pixel art style.",
        "width": 400,
        "height": 225,
        "view": "side"
    }
]

def generate_sprite(item):
    """Generate a single sprite via PixelLab API"""
    print(f"\nGenerating: {item['id']} ({item['width']}x{item['height']})")
    print(f"Prompt: {item['description'][:80]}...")
    
    payload = {
        "description": item["description"],
        "image_size": {
            "width": item["width"],
            "height": item["height"]
        },
        "no_background": False,  # These need backgrounds
        "text_guidance_scale": 8.0,
        "view": item.get("view", "straight-on")
    }
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(BASE_URL, json=payload, headers=headers, timeout=120)
        
        if response.status_code != 200:
            print(f"  ❌ HTTP {response.status_code}: {response.text[:200]}")
            return False
        
        data = response.json()
        
        if "image_base64" in data:
            image_data = base64.b64decode(data["image_base64"])
            filepath = os.path.join(OUTPUT_DIR, item["filename"])
            with open(filepath, "wb") as f:
                f.write(image_data)
            print(f"  ✅ Saved to {filepath} ({len(image_data)} bytes)")
            return True
        elif "image" in data and isinstance(data["image"], dict) and "base64" in data["image"]:
            image_data = base64.b64decode(data["image"]["base64"])
            filepath = os.path.join(OUTPUT_DIR, item["filename"])
            with open(filepath, "wb") as f:
                f.write(image_data)
            print(f"  ✅ Saved to {filepath} ({len(image_data)} bytes)")
            return True
        elif "image_url" in data:
            img_response = requests.get(data["image_url"], timeout=60)
            if img_response.status_code == 200:
                filepath = os.path.join(OUTPUT_DIR, item["filename"])
                with open(filepath, "wb") as f:
                    f.write(img_response.content)
                print(f"  ✅ Saved from URL: {filepath} ({len(img_response.content)} bytes)")
                return True
            else:
                print(f"  ❌ Failed to download image from URL")
                return False
        else:
            print(f"  ❌ No image in response: {json.dumps(data, indent=2)[:200]}")
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return False

# Main
print("=" * 60)
print("PIXELLAB ENV/UI BATCH — 5 High-Impact Sprites")
print("=" * 60)

results = {}
for item in BATCH:
    success = generate_sprite(item)
    results[item["id"]] = success

print("\n" + "=" * 60)
print("BATCH COMPLETE")
print("=" * 60)
for id, success in results.items():
    status = "✅" if success else "❌"
    print(f"  {status} {id}")

success_count = sum(1 for v in results.values() if v)
print(f"\nSuccess: {success_count}/{len(BATCH)}")
