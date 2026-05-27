from PIL import Image, ImageDraw, ImageFont, ImageChops
import os

# Card dimensions
CARD_WIDTH = 832
CARD_HEIGHT = 1248

# Base directory
BASE_DIR = "/root/.openclaw/workspace/acanous_floor3_demo"

def load_font(size):
    """Load a font. Try multiple options."""
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSans-Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans-Bold.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def create_border_layer(width, height, border_size, color):
    """Create a border layer extending from each edge by border_size pixels."""
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    # Left strip
    draw.rectangle([0, 0, border_size - 1, height - 1], fill=color)
    # Right strip
    draw.rectangle([width - border_size, 0, width - 1, height - 1], fill=color)
    # Top strip
    draw.rectangle([border_size, 0, width - border_size - 1, border_size - 1], fill=color)
    # Bottom strip
    draw.rectangle([border_size, height - border_size, width - border_size - 1, height - 1], fill=color)
    return layer

def recolor_frame_edges(frame, target, replacement, border_size):
    """Recolor pixels in edge/border regions that match target color."""
    frame_data = list(frame.getdata())
    new_data = []
    fw, fh = frame.size
    for y in range(fh):
        for x in range(fw):
            idx = y * fw + x
            r, g, b, a = frame_data[idx]
            # Check if in edge regions (border_size from any edge)
            in_edge = (
                x < border_size or x >= fw - border_size or
                y < border_size or y >= fh - border_size
            )
            if in_edge and abs(r - target[0]) < 30 and abs(g - target[1]) < 30 and abs(b - target[2]) < 30:
                new_data.append((replacement[0], replacement[1], replacement[2], a))
            else:
                new_data.append((r, g, b, a))
    frame.putdata(new_data)
    return frame

# Faction-specific frame configs
FACTION_CONFIGS = {
    "Aberration": {
        "name_y": 940,
        "effect_y": 980,
        "keywords_y": 1030,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "center_threshold": (240, 240, 240, 15),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
        "merged_frame_center_color": {
            "target": (240, 230, 185),
            "tolerance": (20, 30, 40),
            "protect_regions": []
        },
        "overlay_adjustments": {
            "Arcane": {"swap_name_type": True, "type_offset": -5, "name_offset": 25, "effect_below_keywords": 80, "merged_frame_center_color": {"target": (200, 210, 230), "tolerance": (60, 50, 30), "alpha": 100}},
            "Divine": {"name_y": -780, "effect_y": 35, "keywords_y": 70},
            "Infernal": {"name_y": -780, "keywords_y": 25},
        },
    },
    "Construct": {
        "name_y": 1010,
        "effect_y": 1080,
        "keywords_y": 1150,
        "max_effect_width": 520,
        "effect_line_height": 26,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.2,
        "center_threshold": (240, 240, 240, 15),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
        "overlay_adjustments": {
            "Infernal": {"name_y": -70, "effect_y": 50, "keywords_y": 60},
        },
    },
    "Demon": {
        "name_y": 1040,
        "effect_y": 1080,
        "keywords_y": 1130,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.2,
        "purple_threshold": {
            "r_range": (50, 75),
            "g_range": (35, 55),
            "b_range": (55, 80)
        },
        "recolor_white_to": (100, 90, 110),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
        "overlay_adjustments": {
            "Arcane": {"name_y": -1010, "effect_y": 65, "keywords_y": 0, "pip_y": 130},
            "Divine": {"name_y": -1030, "effect_y": -55, "keywords_y": 40, "pip_y": 920},
            "Infernal": {"name_y": -850, "effect_y": -95, "keywords_y": 40, "pip_y": 115, "type_header_y": -60, "scale_factor": 1.3},
        },
    },
    "Dragon": {
        "name_y": 55,
        "effect_y": 1120,
        "keywords_y": 1170,
        "max_effect_width": 520,
        "effect_line_height": 24,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "center_threshold": (248, 248, 248, 10),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
    },
    "Elemental": {
        "name_y": 985,
        "effect_y": 1025,
        "keywords_y": 1075,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "text_on_white": True,
        "border_color": (30, 30, 30, 255),
        "merged_frame_center_color": {
            "target": (218, 209, 195),
            "tolerance": (15, 15, 15),
            "protect_regions": [
                {"x1": 0, "y1": 0, "x2": 150, "y2": 1248},
                {"x1": 650, "y1": 0, "x2": 832, "y2": 1248}
            ]
        },
        "overlay_adjustments": {
            "Arcane": {"scale_factor": 1.2, "merged_frame_center_color": {"target": (245, 240, 230), "tolerance": (50, 50, 50), "alpha": 0}, "swap_name_type": True, "type_offset": 70, "name_offset": 30, "pip_offset": 260, "effect_y": 170, "keywords_offset": 1220},
            "Divine": {"scale_factor": 1.2, "merged_frame_center_color": {"target": (245, 240, 230), "tolerance": (50, 50, 50), "alpha": 0}},
            "Infernal": {"scale_factor": 1.2, "merged_frame_center_color": {"target": (245, 240, 230), "tolerance": (50, 50, 50), "alpha": 0}, "swap_name_type": True, "type_offset": 90, "name_offset": 30, "pip_offset": 260, "effect_y": 230, "keywords_offset": 1220},
        },
    },
    "Arcane": {
        "name_y": 150,
        "effect_y": 980,
        "keywords_y": 1090,
        "keywords_color": (180, 150, 210, 255),
        "hide_type_header": True,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "center_threshold": (240, 240, 240, 20),
        "border_color": (215, 230, 255, 255),
        "text_on_white": True,
    },
    "Divine": {
        "name_y": 150,
        "effect_y": 980,
        "keywords_y": 1090,
        "keywords_color": (184, 134, 11, 255),
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "center_threshold": (240, 240, 240, 20),
        "protected_regions": [
            {"x1": 0, "y1": 0, "x2": 150, "y2": 150},
            {"x1": 680, "y1": 0, "x2": 832, "y2": 150},
            {"x1": 0, "y1": 1100, "x2": 150, "y2": 1248},
            {"x1": 680, "y1": 1100, "x2": 832, "y2": 1248}
        ],
        "border_color": (184, 134, 11, 255),
        "text_on_white": True,
    },
    "Infernal": {
        "name_y": 170,
        "effect_y": 1050,
        "keywords_y": 1110,
        "keywords_color": (200, 80, 60, 255),
        "type_header_y": 95,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.2,
        "infernal_transparency": True,
        "border_color": (80, 30, 20, 255),
        "text_on_white": True,
    },
    "Goblin": {
        "name_y": 140,
        "effect_y": 940,
        "keywords_y": 1060,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.15,
        "center_threshold": (220, 210, 195, 20),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
        "overlay_adjustments": {
            "Divine": {"name_y": 80, "effect_y": 20, "keywords_y": -15},
            "Infernal": {"name_y": 60, "effect_y": 45},
            "Arcane": {"name_y": 80, "effect_y": 30, "scale_factor": 1.185},
        },
        "merged_frame_center_color": {
            "target": (74, 103, 133),
            "tolerance": (8, 12, 12),
            "protect_regions": [
                {"x1": 0, "y1": 0, "x2": 250, "y2": 300},
                {"x1": 582, "y1": 0, "x2": 832, "y2": 300},
                {"x1": 0, "y1": 948, "x2": 250, "y2": 1248},
                {"x1": 582, "y1": 948, "x2": 832, "y2": 1248}
            ]
        },
    },
    "Undead": {
        "name_y": 170,
        "effect_y": 950,
        "keywords_y": 1000,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "full_bleed",
        "scale_factor": 1.0,
        "center_threshold": (215, 205, 190, 25),
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
        "recolor_white_to": (181, 166, 66),
        "merged_frame_center_color": {
            "target": (255, 255, 255),
            "tolerance": (10, 10, 10),
            "art_window": {"left": 140, "top": 240, "right": 140, "bottom": 240},
            "outer_margin": 120
        },
        "overlay_adjustments": {
            "Arcane": {"merged_frame_center_color": {"target": (210, 200, 187), "tolerance": (50, 50, 50)}, "name_y": -20, "effect_y": 70, "keywords_y": 80},
            "Divine": {"merged_frame_center_color": {"target": (255, 255, 255), "tolerance": (10, 10, 10), "art_window": {"left": 100, "top": 160, "right": 100, "bottom": 160}, "outer_margin": 100}, "scale_factor": 1.3, "name_y": -20},
            "Infernal": {"merged_frame_center_color": {"target": (175, 160, 135), "tolerance": (65, 65, 65)}, "name_y": -55, "effect_y": 60, "keywords_y": 70},
        },
    },
    "Universal": {
        "name_y": 110,
        "effect_y": 1070,
        "keywords_y": 1140,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "inset",
        "window": {"left": 151, "top": 245, "right": 153, "bottom": 301},
        "overlap": 0,
        "border_color": (30, 30, 30, 255),
        "text_on_white": True,
    },
    "Gold": {
        "name_y": 150,
        "effect_y": 1070,
        "keywords_y": 1140,
        "max_effect_width": 520,
        "effect_line_height": 22,
        "name_has_top_plate": False,
        "mode": "inset",
        "window": {"left": 151, "top": 245, "right": 153, "bottom": 301},
        "overlap": 0,
        "border_color": (212, 175, 55, 255),
        "text_on_white": True,
    },
}

# Frame mapping for pip lookups
PIP_FACTIONS = {
    "Aberration": "aberration",
    "Construct": "construct",
    "Demon": "demon",
    "Dragon": "dragon",
    "Elemental": "elemental",
    "Goblin": "goblin",
    "Undead": "undead",
    "Universal": "universal",
    "Arcane": "universal",  # Use universal pip for Arcane (until arcane pip exists)
    "Divine": "universal",
    "Infernal": "universal",
}

def composite_card(art_path, frame_path, faction, card_name, card_type, attention_cost, effect_text, keywords, overlay=None):
    """Composite a single card."""
    
    # Load images
    art = Image.open(art_path).convert("RGBA")
    
    # If overlay is specified, look for merged frame
    # If overlay is specified, look for merged frame (only if base frame passed)
    using_merged_frame = False
    if overlay:
        # Check if frame_path already contains the overlay name
        if f"_{overlay.lower()}_" in frame_path:
            using_merged_frame = True
        else:
            overlay_frame_path = frame_path.replace("_frame.png", f"_{overlay.lower()}_frame.png")
            if os.path.exists(overlay_frame_path):
                frame_path = overlay_frame_path
                using_merged_frame = True
            else:
                print(f"Warning: Overlay frame not found: {overlay_frame_path}, using base frame")
    
    frame = Image.open(frame_path).convert("RGBA")
    
    # Resize art to card size if needed
    if art.size != (CARD_WIDTH, CARD_HEIGHT):
        art = art.resize((CARD_WIDTH, CARD_HEIGHT), Image.LANCZOS)
    
    config = FACTION_CONFIGS.get(faction, FACTION_CONFIGS["Universal"])
    
    # Recolor frame edges if configured (before transparency)
    if "edge_recolor" in config:
        edge_cfg = config["edge_recolor"]
        frame = recolor_frame_edges(
            frame,
            edge_cfg["target"],
            edge_cfg["replacement"],
            edge_cfg.get("border_size", 120)
        )
    
    # Get border color from config (default: pale blue-white)
    border_color = config.get("border_color", (215, 230, 255, 255))
    
    # For merged frames, use the overlay's border color
    if using_merged_frame and overlay:
        overlay_config = FACTION_CONFIGS.get(overlay, {})
        border_color = overlay_config.get("border_color", border_color)
    
    # Check if faction needs frame scaling (or overlay adjustment)
    scale = config.get("scale_factor", 1.0)
    if overlay and "overlay_adjustments" in config:
        adjustments = config["overlay_adjustments"].get(overlay, {})
        if "scale_factor" in adjustments:
            scale = adjustments["scale_factor"]
    
    # Make transparent based on mode (BEFORE scaling for merged_frame_center_color)
    if "border_size" in config:
        # Geometric transparency - border becomes transparent
        border = config["border_size"]
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                # Check if pixel is in border area
                if x < border or x >= fw - border or y < border or y >= fh - border:
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    elif not using_merged_frame and config.get("merged_frame_center_color"):
        # Base config with merged_frame_center_color (no overlay)
        # Apply color-based transparency to base frame
        center_config = config["merged_frame_center_color"].copy()
        target = center_config["target"]
        tolerance = center_config["tolerance"]
        protect_regions = center_config.get("protect_regions", [])
        
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                
                # Check if pixel is in a protected region
                in_protected = False
                for region in protect_regions:
                    if region["x1"] <= x <= region["x2"] and region["y1"] <= y <= region["y2"]:
                        in_protected = True
                        break
                
                # If in protected region, keep original
                if in_protected:
                    new_data.append((r, g, b, a))
                # If matches target color, make transparent
                elif (abs(r - target[0]) <= tolerance[0] and
                      abs(g - target[1]) <= tolerance[1] and
                      abs(b - target[2]) <= tolerance[2]):
                    alpha = center_config.get("alpha", 0)
                    new_data.append((r, g, b, alpha))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    elif using_merged_frame and config.get("merged_frame_center_color"):
        # Merged frame with opaque center - use color-based transparency
        # Apply on ORIGINAL frame, then scale with NEAREST to preserve hard edges
        base_config = config["merged_frame_center_color"]
        center_config = base_config.copy()
        
        # Store base target/tolerance for outer margin (white border gaps)
        base_target = base_config["target"]
        base_tolerance = base_config["tolerance"]
        
        # Check for overlay-specific center color override (for art window parchment)
        if overlay and "overlay_adjustments" in config:
            adjustments = config["overlay_adjustments"].get(overlay, {})
            if "merged_frame_center_color" in adjustments:
                center_config.update(adjustments["merged_frame_center_color"])
        
        target = center_config["target"]
        tolerance = center_config["tolerance"]
        protect_regions = center_config.get("protect_regions", [])
        
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                
                # Check if pixel is in a protected region (decorations)
                in_protected = False
                for region in protect_regions:
                    if region["x1"] <= x <= region["x2"] and region["y1"] <= y <= region["y2"]:
                        in_protected = True
                        break
                
                # Check if pixel is in art window (overlay-specific color)
                in_art_window = False
                art_window = center_config.get("art_window")
                if art_window:
                    wx1 = art_window.get("left", 0)
                    wy1 = art_window.get("top", 0)
                    wx2 = fw - art_window.get("right", 0)
                    wy2 = fh - art_window.get("bottom", 0)
                    in_art_window = (wx1 <= x <= wx2 and wy1 <= y <= wy2)
                
                # Check if pixel is in outer margin (base white color)
                in_outer_margin = False
                outer_margin = center_config.get("outer_margin", 0)
                if outer_margin:
                    near_edge = (x < outer_margin or x >= fw - outer_margin or 
                                y < outer_margin or y >= fh - outer_margin)
                    if near_edge:
                        in_outer_margin = True
                
                # Art window: use overlay-specific target (parchment/tan)
                if in_art_window and (
                    abs(r - target[0]) <= tolerance[0] and
                    abs(g - target[1]) <= tolerance[1] and
                    abs(b - target[2]) <= tolerance[2]
                ):
                    # Check if this is blue-dominant mist (B significantly higher than R)
                    # or just white/cream background (all channels similar)
                    if b > r + 20 and b > g + 10:
                        # Blue mist -> semi-transparent
                        alpha = center_config.get("alpha", 80)
                    else:
                        # White/cream background -> fully transparent
                        alpha = 0
                    new_data.append((r, g, b, alpha))
                # Outer margin: use base target (white)
                elif in_outer_margin and (
                    abs(r - base_target[0]) <= base_tolerance[0] and
                    abs(g - base_target[1]) <= base_tolerance[1] and
                    abs(b - base_target[2]) <= base_tolerance[2]
                ):
                    alpha = center_config.get("alpha", 0)
                    new_data.append((r, g, b, alpha))
                # No art_window or outer_margin defined: match color everywhere
                elif not art_window and not outer_margin and (
                    abs(r - target[0]) <= tolerance[0] and
                    abs(g - target[1]) <= tolerance[1] and
                    abs(b - target[2]) <= tolerance[2]
                ):
                    # Check if this is blue-dominant mist (B significantly higher than R)
                    if b > r + 20 and b > g + 10:
                        # Blue mist -> semi-transparent
                        alpha = center_config.get("alpha", 80)
                    else:
                        # White/cream background -> fully transparent
                        alpha = 0
                    new_data.append((r, g, b, alpha))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
        
        # Mask art to art_window so it doesn't bleed through transparent outer areas
        if art_window:
            wx1 = art_window.get("left", 0)
            wy1 = art_window.get("top", 0)
            wx2 = CARD_WIDTH - art_window.get("right", 0)
            wy2 = CARD_HEIGHT - art_window.get("bottom", 0)
            # Create mask for art window
            art_mask = Image.new("L", (CARD_WIDTH, CARD_HEIGHT), 0)
            draw = ImageDraw.Draw(art_mask)
            draw.rectangle([wx1, wy1, wx2, wy2], fill=255)
            # Apply mask to art alpha channel
            art_rgba = art.convert("RGBA")
            art_alpha = art_rgba.getchannel("A")
            masked_alpha = ImageChops.multiply(art_alpha, art_mask)
            art.putalpha(masked_alpha)
        
        # Scale AFTER transparency with NEAREST to preserve hard alpha edges
        # Support per-axis scaling from overlay adjustments
        scale_w = scale_h = scale
        if overlay and "overlay_adjustments" in config:
            adjustments = config["overlay_adjustments"].get(overlay, {})
            if "scale_width" in adjustments:
                scale_w = adjustments["scale_width"]
            if "scale_height" in adjustments:
                scale_h = adjustments["scale_height"]
        
        if scale_w != 1.0 or scale_h != 1.0:
            new_w = int(CARD_WIDTH * scale_w)
            new_h = int(CARD_HEIGHT * scale_h)
            frame = frame.resize((new_w, new_h), Image.NEAREST)
        # Skip the scaling step below
        scale = 1.0
    elif using_merged_frame:
        # Merged frames (base+overlay) have white center area + white corner crystals
        # Use center_threshold with protected corners (same as Divine)
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        thresh_r, thresh_g, thresh_b, thresh_diff = 240, 240, 240, 20
        
        # Corner crystal protection (same regions as Divine)
        protected_regions = [
            {"x1": 0, "y1": 0, "x2": 150, "y2": 150},
            {"x1": 680, "y1": 0, "x2": 832, "y2": 150},
            {"x1": 0, "y1": 1100, "x2": 150, "y2": 1248},
            {"x1": 680, "y1": 1100, "x2": 832, "y2": 1248}
        ]
        
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                
                # Check if pixel is in a protected region (corner crystals)
                in_protected = False
                for region in protected_regions:
                    if region["x1"] <= x <= region["x2"] and region["y1"] <= y <= region["y2"]:
                        in_protected = True
                        break
                
                # Make near-white center area transparent (but protect corners)
                if not in_protected and (r > thresh_r and g > thresh_g and b > thresh_b and
                    abs(r - g) < thresh_diff and abs(g - b) < thresh_diff):
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    elif "center_threshold" in config:
        # Color-based transparency with custom threshold
        thresh = config["center_threshold"]
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        
        # Get protected regions (scaled if frame was scaled)
        protected_regions = config.get("protected_regions", [])
        scale = config.get("scale_factor", 1.0)
        scaled_regions = []
        for region in protected_regions:
            scaled_regions.append({
                "x1": int(region["x1"] * scale),
                "y1": int(region["y1"] * scale),
                "x2": int(region["x2"] * scale),
                "y2": int(region["y2"] * scale)
            })
        
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                
                # Check if pixel is in a protected region
                in_protected = False
                for region in scaled_regions:
                    if region["x1"] <= x <= region["x2"] and region["y1"] <= y <= region["y2"]:
                        in_protected = True
                        break
                
                if not in_protected and (r > thresh[0] and g > thresh[1] and b > thresh[2] and
                    abs(r - g) < thresh[3] and abs(g - b) < thresh[3]):
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    elif "purple_threshold" in config:
        # Target specific purple color range (Demon frame)
        thresh = config["purple_threshold"]
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                # Check if pixel matches flat purple color
                r_min, r_max = thresh.get("r_range", (55, 75))
                g_min, g_max = thresh.get("g_range", (35, 55))
                b_min, b_max = thresh.get("b_range", (55, 80))
                
                if (r_min <= r <= r_max and 
                    g_min <= g <= g_max and 
                    b_min <= b <= b_max and
                    r > g + 5 and b > g + 5):  # Purple characteristics
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    elif "infernal_transparency" in config:
        # Infernal frame: dark grey -> transparent, fire inside window -> semi-transparent
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        
        # Define inner art window for fire semi-transparency
        # All grey (inside and outside window) -> fully transparent
        # Fire inside window -> semi-transparent (alpha ~120)
        # Fire outside window + border elements -> opaque
        win_left = 140
        win_top = 200
        win_right = fw - 132
        win_bottom = fh - 198
        
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                
                # Check if pixel is uniform dark grey (all channels low and close)
                is_grey = r < 80 and g < 80 and b < 80 and abs(int(r) - int(g)) < 20 and abs(int(g) - int(b)) < 20
                
                # Check if pixel is fire/orange (high red, lower green, lower blue)
                is_fire = r > 90 and g < 130 and b < 90 and int(r) > int(g) + 20
                
                # Check if inside the inner art window
                in_window = win_left <= x <= win_right and win_top <= y <= win_bottom
                
                if is_grey:
                    # All grey areas -> fully transparent (both inside and outside window)
                    new_data.append((255, 255, 255, 0))
                elif is_fire and in_window:
                    # Fire inside window -> semi-transparent so art shows through with glow
                    new_data.append((r, g, b, 120))
                else:
                    # Everything else (border fire, rock, crystals) -> keep opaque
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
    else:
        # Standard transparency (pure white)
        frame_data = list(frame.getdata())
        new_data = []
        for item in frame_data:
            r, g, b, a = item
            if r > 240 and g > 240 and b > 240:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append((r, g, b, a))
        frame.putdata(new_data)
    
    # Recolor white edges if configured
    if "recolor_white_to" in config:
        target_color = config["recolor_white_to"]
        frame_data = list(frame.getdata())
        new_data = []
        for item in frame_data:
            r, g, b, a = item
            if r > 240 and g > 240 and b > 240:
                new_data.append((target_color[0], target_color[1], target_color[2], a))
            else:
                new_data.append((r, g, b, a))
        frame.putdata(new_data)
    
    # Scale frame if needed (for modes that didn't already scale in their transparency block)
    if scale != 1.0:
        new_w = int(CARD_WIDTH * scale)
        new_h = int(CARD_HEIGHT * scale)
        # Use NEAREST for merged frames with color-based transparency to preserve hard edges
        if using_merged_frame and config.get("merged_frame_center_color"):
            frame = frame.resize((new_w, new_h), Image.NEAREST)
        else:
            frame = frame.resize((new_w, new_h), Image.LANCZOS)
    
    # Check if we need inset art positioning (window with overlap)
    if "window" in config and config["mode"] == "inset":
        # Art is inset within window so frame border overlaps art edges
        window = config["window"]
        w_left = window["left"]
        w_top = window["top"]
        w_right = window["right"]
        w_bottom = window["bottom"]
        
        # Calculate window dimensions
        win_x = w_left
        win_y = w_top
        win_w = CARD_WIDTH - w_left - w_right
        win_h = CARD_HEIGHT - w_top - w_bottom
        
        # Scale art to fit inside window with padding for overlap
        overlap = config.get("overlap", 30)  # Default 30px, configurable per faction
        art_w = win_w - overlap * 2
        art_h = win_h - overlap * 2
        art = art.resize((art_w, art_h), Image.LANCZOS)
        
        # Create canvas
        canvas = Image.new("RGBA", (CARD_WIDTH, CARD_HEIGHT), (0, 0, 0, 255))
        
        # Paste art centered in window (with overlap margin)
        art_x = win_x + overlap
        art_y = win_y + overlap
        canvas.paste(art, (art_x, art_y))
        
        # Make frame transparent in window area (geometric mask)
        frame_data = list(frame.getdata())
        new_data = []
        fw, fh = frame.size
        for y in range(fh):
            for x in range(fw):
                idx = y * fw + x
                r, g, b, a = frame_data[idx]
                # Check if pixel is inside the window area
                if win_x <= x < win_x + win_w and win_y <= y < win_y + win_h:
                    new_data.append((255, 255, 255, 0))
                else:
                    new_data.append((r, g, b, a))
        frame.putdata(new_data)
        
        # Middle border layer (30px from each edge)
        border_layer = create_border_layer(canvas.size[0], canvas.size[1], 30, border_color)
        canvas = Image.alpha_composite(canvas, border_layer)
        
        # Frame on top (border overlaps art edges)
        card = Image.alpha_composite(canvas, frame)
        
        # No text offset needed
        text_offset_x = 0
        text_offset_y = 0
    elif "window" in config and config["mode"] == "full_bleed":
        # Full bleed art with only window area transparent
        # Art fills entire card, frame on top with center window transparent
        window = config["window"]
        
        # Get scale factor (already applied to frame)
        scale = config.get("scale_factor", 1.0)
        
        # Scale window coordinates to match scaled frame
        w_left = int(window["left"] * scale)
        w_top = int(window["top"] * scale)
        w_right = int(window["right"] * scale)
        w_bottom = int(window["bottom"] * scale)
        
        # Frame was already scaled in step 2, use current size
        canvas_w, canvas_h = frame.size
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 255))
        # Place art at center of canvas (keep art at normal size, centered)
        art_x = (canvas_w - CARD_WIDTH) // 2
        art_y = (canvas_h - CARD_HEIGHT) // 2
        canvas.paste(art, (art_x, art_y))
        
        # Middle border layer (30px from each edge)
        border_layer = create_border_layer(canvas.size[0], canvas.size[1], 30, border_color)
        canvas = Image.alpha_composite(canvas, border_layer)
        
        # Composite frame on top
        card = Image.alpha_composite(canvas, frame)
        
        # If frame was scaled, crop back to card size
        if scale != 1.0:
            left = (canvas_w - CARD_WIDTH) // 2
            top = (canvas_h - CARD_HEIGHT) // 2
            card = card.crop((left, top, left + CARD_WIDTH, top + CARD_HEIGHT))
            text_offset_x = art_x - left
            text_offset_y = art_y - top
        else:
            text_offset_x = 0
            text_offset_y = 0
    else:
        # Standard full bleed - art fills entire card
        canvas_w, canvas_h = frame.size
        art_x = (canvas_w - CARD_WIDTH) // 2
        art_y = (canvas_h - CARD_HEIGHT) // 2
        
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 255))
        canvas.paste(art, (art_x, art_y))
        
        # Middle border layer (30px from each edge)
        border_layer = create_border_layer(canvas.size[0], canvas.size[1], 30, border_color)
        canvas = Image.alpha_composite(canvas, border_layer)
        
        card = Image.alpha_composite(canvas, frame)
        
        if canvas_w != CARD_WIDTH or canvas_h != CARD_HEIGHT:
            # Crop back to card size, centered
            left = (canvas_w - CARD_WIDTH) // 2
            top = (canvas_h - CARD_HEIGHT) // 2
            card = card.crop((left, top, left + CARD_WIDTH, top + CARD_HEIGHT))
            text_offset_x = art_x - left
            text_offset_y = art_y - top
        else:
            text_offset_x = art_x
            text_offset_y = art_y
    
    draw = ImageDraw.Draw(card)
    
    # Attention Cost (TOP-CENTER)
    if attention_cost > 0:
        cx = CARD_WIDTH // 2
        cy = 30
        
        # Apply pip_y overlay adjustment if present
        if overlay and "overlay_adjustments" in config:
            adjustments = config["overlay_adjustments"].get(overlay, {})
            if "pip_y" in adjustments:
                cy += adjustments["pip_y"]
        
        cost_text = str(attention_cost)
        
        # Check for faction-specific pip
        pip_faction = PIP_FACTIONS.get(faction, faction.lower())
        pip_path = f"{BASE_DIR}/assets/sprites/cards/pips/{pip_faction}_pip.png"
        if os.path.exists(pip_path):
            # Use faction pip
            pip = Image.open(pip_path).convert("RGBA")
            # Resize to appropriate size (120x120 for better visibility)
            pip_size = 120
            pip = pip.resize((pip_size, pip_size), Image.LANCZOS)
            # Center the pip at (cx, cy)
            pip_x = cx - pip_size // 2
            pip_y = cy - pip_size // 2
            # Paste pip onto card
            card.paste(pip, (pip_x, pip_y), pip)
        else:
            # Fallback: dark circle
            radius = 30
            draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(20, 20, 20, 180))
        
        # White text ON TOP of pip/circle
        try:
            cost_font = load_font(36)
        except:
            cost_font = ImageFont.load_default()
        bbox = draw.textbbox((0, 0), cost_text, font=cost_font)
        left, top, right, bottom = bbox
        text_w = right - left
        text_h = bottom - top
        # Account for font bearings - center the visual text
        nx = cx - left - text_w / 2
        ny = cy - top - text_h / 2
        draw.text((nx, ny), cost_text, fill=(255, 255, 255, 255), font=cost_font)
    
    # Calculate all text positions first (before any drawing)
    type_text = f"{faction} | {card_type}"
    type_y = config.get("type_header_y", 65)
    name_y = config["name_y"]
    effect_y = config["effect_y"]
    keywords_y = config["keywords_y"]
    
    # Apply overlay adjustments
    if overlay and "overlay_adjustments" in config:
        adjustments = config["overlay_adjustments"].get(overlay, {})
        if "type_header_y" in adjustments:
            type_y += adjustments["type_header_y"]
        if "name_y" in adjustments:
            name_y += adjustments["name_y"]
        if "effect_y" in adjustments:
            effect_y += adjustments["effect_y"]
        if "keywords_y" in adjustments:
            keywords_y += adjustments["keywords_y"]
        
        # Layout overrides
        if adjustments.get("swap_name_type", False):
            # Swap: name goes to type position, type goes to name position
            type_y, name_y = name_y, type_y
            # Fine-tune type position relative to swapped name
            if "type_offset" in adjustments:
                type_y = name_y + adjustments["type_offset"]
            # Fine-tune name position relative to swapped position
            if "name_offset" in adjustments:
                name_y += adjustments["name_offset"]
        if "effect_below_keywords" in adjustments:
            effect_y = keywords_y + adjustments["effect_below_keywords"]
            keywords_y = effect_y - adjustments.get("keywords_height", 35)
    
    # Card Type + Faction (under cost)
    try:
        small_font = load_font(22)
    except:
        small_font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), type_text, font=small_font)
    text_w = bbox[2] - bbox[0]
    if not config.get("hide_type_header", False):
        draw.text(((CARD_WIDTH - text_w) // 2, type_y), type_text, fill=(255, 255, 255, 255), font=small_font)
    
    # Card Name
    else:
        effect_y = config["effect_y"]
        keywords_y = config["keywords_y"]
    
    if config.get("name_has_top_plate", False):
        # Draw semi-transparent plate behind name
        plate_height = 60
        draw.rectangle([50, name_y - 20, CARD_WIDTH - 50, name_y + plate_height], 
                      fill=config.get("top_plate_bg", (40, 40, 40, 160)))
    
    try:
        name_font = load_font(38)
    except:
        name_font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), card_name, font=name_font)
    text_w = bbox[2] - bbox[0]
    nx = (CARD_WIDTH - text_w) // 2
    
    # Add text shadow/outline
    for dx, dy in [(-2, -2), (-2, 2), (2, -2), (2, 2), (0, 0)]:
        color = (0, 0, 0, 255) if (dx, dy) != (0, 0) else (255, 255, 255, 255)
        draw.text((nx + dx, name_y + dy), card_name, fill=color, font=name_font)
    
    # Effect Text (with wrapping)
    max_width = config.get("max_effect_width", 520)
    line_height = config.get("effect_line_height", 28)
    
    try:
        effect_font = load_font(24)
    except:
        effect_font = ImageFont.load_default()
    
    words = effect_text.split()
    lines = []
    current_line = ""
    for word in words:
        test = current_line + " " + word if current_line else word
        bbox = draw.textbbox((0, 0), test, font=effect_font)
        if bbox[2] - bbox[0] <= max_width:
            current_line = test
        else:
            if current_line:
                lines.append(current_line)
            current_line = word
    if current_line:
        lines.append(current_line)
    
    for i, line in enumerate(lines):
        y = effect_y + i * line_height
        bbox = draw.textbbox((0, 0), line, font=effect_font)
        text_w = bbox[2] - bbox[0]
        x = (CARD_WIDTH - text_w) // 2
        
        # Text shadow/outline
        for dx, dy in [(-1, -1), (-1, 1), (1, -1), (1, 1), (0, 0)]:
            color = (0, 0, 0, 255) if (dx, dy) != (0, 0) else (255, 255, 255, 255)
            draw.text((x + dx, y + dy), line, fill=color, font=effect_font)
    
    # Keywords
    if keywords:
        if isinstance(keywords, str):
            kw_text = keywords
        else:
            kw_text = " | ".join(keywords)
        try:
            kw_font = load_font(20)
        except:
            kw_font = ImageFont.load_default()
        bbox = draw.textbbox((0, 0), kw_text, font=kw_font)
        text_w = bbox[2] - bbox[0]
        x = (CARD_WIDTH - text_w) // 2
        
        kw_color = config.get("keywords_color", (200, 200, 200, 255))
        for dx, dy in [(-1, -1), (-1, 1), (1, -1), (1, 1), (0, 0)]:
            color = (0, 0, 0, 255) if (dx, dy) != (0, 0) else kw_color
            draw.text((x + dx, keywords_y + dy), kw_text, fill=color, font=kw_font)
    
    return card

# Test cards
TEST_CARDS = [
    ("Aberration", f"{BASE_DIR}/assets/sprites/cards/Aberration/Aberration_consume_sanity.png", "Consume Sanity", "Attack", 3, "Deal 12 damage. Draw 1 card.", ["Madness", "Draw"]),
    ("Construct", f"{BASE_DIR}/assets/sprites/cards/Construct/Construct_assembly_line.png", "Assembly Line", "Attack", 2, "Deal 8 damage. Draw 1 card.", ["Construct", "Draw"]),
    ("Demon", f"{BASE_DIR}/assets/sprites/cards/Demon/Demon_blood_pact.png", "Blood Pact", "Special", 2, "Lose 3 HP. Gain 6 attention. Draw 2 cards.", ["Demon", "Blood"]),
    ("Dragon", f"{BASE_DIR}/assets/sprites/cards/Dragon/Dragon_dragonfire.png", "Dragonfire", "Attack", 4, "Deal 16 damage. Burn: Target loses 2 HP per turn for 3 turns.", ["Burn", "Fire"]),
    ("Elemental", f"{BASE_DIR}/assets/sprites/cards/Elemental/Elemental_cyclone.png", "Cyclone", "Attack", 3, "Deal 10 damage to all enemies. Wind: Push 1 enemy to back row.", ["Wind", "AoE"]),
    ("Goblin", f"{BASE_DIR}/assets/sprites/cards/Goblin/Goblin_ambush.png", "Ambush", "Attack", 2, "Deal 6 damage. Goblin: Steal 1 attention from target.", ["Goblin", "Steal"]),
    ("Undead", f"{BASE_DIR}/assets/sprites/cards/Undead/Undead_bone_armor.png", "Bone Armor", "Defend", 2, "Gain 8 Block. Bone: Heal 4 HP", ["Bone", "Armor"]),
    ("Universal", f"{BASE_DIR}/assets/sprites/cards/Universal/Universal_bandage.png", "Bandage", "Special", 1, "Heal 5 HP. Remove Bleed.", ["Heal"]),
]

if __name__ == "__main__":
    print("Generating test cards...")
    for faction, art_path, card_name, card_type, cost, effect, keywords in TEST_CARDS:
        frame_path = f"{BASE_DIR}/assets/sprites/cards/{faction.lower()}_frame.png"
        if faction == "Universal":
            frame_path = f"{BASE_DIR}/assets/sprites/cards/untyped_frame.png"
        
        if not os.path.exists(art_path):
            print(f"✗ Missing: {art_path}")
            continue
        if not os.path.exists(frame_path):
            print(f"✗ Missing frame: {frame_path}")
            continue
        
        card = composite_card(art_path, frame_path, faction, card_name, card_type, cost, effect, keywords)
        output_path = f"{BASE_DIR}/assets/sprites/cards/test_v7_{faction.lower()}_{card_name.lower().replace(' ', '_')}.png"
        card.save(output_path)
        print(f"✓ {faction}: {card_name}")
    
    print("Done! Test cards saved.")
    
    # Test merged overlay frames
    print("\nGenerating overlay test cards...")
    OVERLAY_TESTS = [
        ("Elemental", "Arcane", f"{BASE_DIR}/assets/sprites/cards/Elemental/Elemental_cyclone.png", "Cyclone Arcane", "Attack", 3, "Deal 10 damage to all enemies. Wind: Push 1 enemy to back row.", ["Wind", "AoE"]),
        ("Elemental", "Divine", f"{BASE_DIR}/assets/sprites/cards/Elemental/Elemental_cyclone.png", "Cyclone Divine", "Attack", 3, "Deal 10 damage to all enemies. Wind: Push 1 enemy to back row.", ["Wind", "AoE"]),
        ("Elemental", "Infernal", f"{BASE_DIR}/assets/sprites/cards/Elemental/Elemental_cyclone.png", "Cyclone Infernal", "Attack", 3, "Deal 10 damage to all enemies. Wind: Push 1 enemy to back row.", ["Wind", "AoE"]),
    ]
    
    for faction, overlay, art_path, card_name, card_type, cost, effect, keywords in OVERLAY_TESTS:
        frame_path = f"{BASE_DIR}/assets/sprites/cards/{faction.lower()}_{overlay.lower()}_frame.png"
        if not os.path.exists(frame_path):
            print(f"✗ Missing overlay frame: {frame_path}")
            continue
        
        card = composite_card(art_path, frame_path, faction, card_name, card_type, cost, effect, keywords, overlay=overlay)
        output_path = f"{BASE_DIR}/assets/sprites/cards/test_v7_{faction.lower()}_{overlay.lower()}_{card_name.lower().replace(' ', '_')}.png"
        card.save(output_path)
        print(f"✓ {faction}+{overlay}: {card_name}")
