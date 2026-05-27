from PIL import Image, ImageDraw, ImageFont

CARD_WIDTH = 832
CARD_HEIGHT = 1248
BASE_DIR = "/root/.openclaw/workspace/acanous_floor3_demo"

def composite_demon_v13(art_path, name, card_type, cost, effect, keywords):
    art = Image.open(art_path).convert("RGBA")
    frame = Image.open(f"{BASE_DIR}/assets/sprites/cards/demon_frame.png").convert("RGBA")
    
    # Art fills ENTIRE card
    art_full = art.resize((CARD_WIDTH, CARD_HEIGHT), Image.LANCZOS)
    
    # Scale frame so border reaches the edges
    scale_factor = CARD_WIDTH / (CARD_WIDTH - 140)
    new_frame_w = int(CARD_WIDTH * scale_factor)
    new_frame_h = int(CARD_HEIGHT * scale_factor)
    frame_scaled = frame.resize((new_frame_w, new_frame_h), Image.LANCZOS)
    
    # Crop back to card size
    left = (new_frame_w - CARD_WIDTH) // 2
    top = (new_frame_h - CARD_HEIGHT) // 2
    frame_cropped = frame_scaled.crop((left, top, left + CARD_WIDTH, top + CARD_HEIGHT))
    
    # Border color from the frame (muted purple-grey)
    BORDER_COLOR = (115, 106, 122, 255)
    
    # Make center transparent, fill white edges with border color
    border_size = 80
    
    frame_data = list(frame_cropped.getdata())
    new_data = []
    for y in range(CARD_HEIGHT):
        for x in range(CARD_WIDTH):
            idx = y * CARD_WIDTH + x
            r, g, b, a = frame_data[idx]
            
            # Center window - transparent
            if (border_size <= x < CARD_WIDTH - border_size and
                border_size <= y < CARD_HEIGHT - border_size):
                new_data.append((255, 255, 255, 0))
            # White/very light edge pixels - fill with border color
            elif r > 240 and g > 240 and b > 240:
                new_data.append(BORDER_COLOR)
            else:
                # Keep original frame pixel
                new_data.append((r, g, b, a))
    
    frame_cropped.putdata(new_data)
    
    # Composite: art behind, scaled frame on top
    card = Image.alpha_composite(art_full, frame_cropped)
    
    # ADD TEXT
    draw = ImageDraw.Draw(card)
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 36)
        font_type = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
        font_effect = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
        font_keywords = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
        font_cost = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
    except:
        font_title = font_type = font_effect = font_keywords = font_cost = ImageFont.load_default()
    
    # Cost badge
    cost_bg_radius = 32
    draw.ellipse([CARD_WIDTH//2 - cost_bg_radius, 20, 
                  CARD_WIDTH//2 + cost_bg_radius, 20 + cost_bg_radius*2], 
                 fill=(0, 0, 0, 180))
    draw.text((CARD_WIDTH//2, 20 + cost_bg_radius), str(cost), 
              fill=(255, 255, 255, 255), font=font_cost, anchor="mm",
              stroke_width=2, stroke_fill=(0, 0, 0, 255))
    
    # Type line
    type_text = f"Demon | {card_type}"
    draw.text((CARD_WIDTH//2, 100), type_text, 
              fill=(255, 255, 255, 255), font=font_type, anchor="mm",
              stroke_width=2, stroke_fill=(0, 0, 0, 255))
    
    # Name
    name_y = 920
    draw.text((CARD_WIDTH//2, name_y), name, 
              fill=(255, 255, 255, 255), font=font_title, anchor="mm",
              stroke_width=3, stroke_fill=(0, 0, 0, 255))
    
    # Effect
    effect_y = 980
    max_w = 650
    line_h = 28
    words = effect.split()
    lines = []
    cur = ""
    for w in words:
        test = cur + " " + w if cur else w
        bbox = draw.textbbox((0, 0), test, font=font_effect)
        if bbox[2] - bbox[0] <= max_w:
            cur = test
        else:
            if cur: lines.append(cur)
            cur = w
    if cur: lines.append(cur)
    
    if lines:
        for i, line in enumerate(lines):
            draw.text((CARD_WIDTH//2, effect_y + i * line_h), line, 
                      fill=(255, 255, 255, 255), font=font_effect, anchor="mm",
                      stroke_width=2, stroke_fill=(0, 0, 0, 255))
    
    # Keywords
    keywords_y = 1060
    if keywords:
        kw_text = " ".join(keywords)
        draw.text((CARD_WIDTH//2, keywords_y), kw_text, 
                  fill=(255, 215, 0, 255), font=font_keywords, anchor="mm",
                  stroke_width=2, stroke_fill=(0, 0, 0, 255))
    
    out = f"{BASE_DIR}/assets/sprites/cards/test_demon_v13.png"
    card.save(out)
    print(f"✓ Demon v13: {name}")
    return out

composite_demon_v13(
    f"{BASE_DIR}/assets/sprites/cards/Demon/Demon_blood_pact.png",
    "Blood Pact", "Special", 3,
    "Deal 10 damage. Heal 5 HP. Pact: Repeat next turn",
    ["Pact"]
)
