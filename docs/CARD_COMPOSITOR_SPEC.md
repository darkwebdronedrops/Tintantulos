# Card Compositor Specification
## For Godot Integration — Acanous Card Battler

### Overview
This document describes exactly how the Python/Pillow card compositor works, so you can implement the same rendering in Godot for dynamic card display during gameplay.

### Card Dimensions
- **Canvas:** 832 × 1248 pixels (2:3 ratio)
- **Target in-game:** 256 × 384 pixels (scaled down 3.25x)

### Layer Stack (bottom to top)
1. **Card Art** — Full bleed, 832×1248
2. **Frame Overlay** — PNG with transparent center, opaque decorative border
3. **Text Overlays** — Rendered on top of frame

### Text Positioning (Magic Numbers)
All positions are relative to top-left of the 832×1248 canvas:

| Element | Position | Font Size | Color | Notes |
|---------|----------|-----------|-------|-------|
| **Cost Badge** | Center (416, 30) | 52 | White | Circle background (20,20,20,180) radius 30 |
| **Faction/Type** | Center (416, 80) | 20 | White | e.g. "Aberration \| Attack" |
| **Card Name** | Center (416, 897) | 34 | White | Black rect behind, padding 10px |
| **Effect Text** | Center (416, 942) | 22 | #E6E6E6 | Max width 400px, wraps to 3-5 lines |
| **Keywords** | Center (416, 1032) | 20 | #FFC864 | Golden, comma-separated |

### Text Outline Technique
Every text element gets a black outline for readability over any art:
- Draw text 8 times in a 3×3 grid (skip center), offset ±2px
- Draw actual text on top in the target color
- This creates a 2px black outline

### Frame Transparency
The frame PNG has a solid white center (not transparent). Make white pixels transparent:
```gdscript
# Godot equivalent
for pixel in frame_image.get_data():
    if pixel.r > 240 and pixel.g > 240 and pixel.b > 240:
        pixel.a = 0
```

### Dark Backgrounds for Text
Behind name: `(0, 0, 0, 180)` — solid dark, 70% opacity
Behind effect: `(0, 0, 0, 140)` — slightly lighter, 55% opacity

### Font Stack
- **Cost:** NimbusSansNarrow-BoldOblique, 52pt
- **Name:** NimbusSansNarrow-BoldOblique, 34pt
- **Effect:** LiberationSansNarrow-Regular, 22pt
- **Keywords:** LiberationSansNarrow-Bold, 20pt
- **Faction:** LiberationSansNarrow-Regular, 20pt

### Godot Implementation Notes

1. **Use TextureRect nodes in a Control:**
   - Bottom: Art TextureRect (expand)
   - Middle: Frame TextureRect (expand, blend mode)
   - Top: Multiple Label nodes for text

2. **Label settings:**
   - `horizontal_alignment = CENTER`
   - `vertical_alignment = CENTER`
   - `autowrap_mode = WORD_SMART` (for effect text)
   - Custom font with outline: `outline_size = 2`, `outline_color = black`

3. **For in-hand cards:**
   - Scale the 832×1248 composition down to 256×384
   - Or render directly at 256×384 if performance matters

### Python Script Reference
- **Full batch compositor:** `/tmp/batch_compositor.py`
- **Single card compositor:** `/tmp/card_compositor_v5.py`
- **Output directory:** `assets/sprites/cards/printable/`

### File Naming
Output: `{Faction}_{safe_card_name}.png`
- Spaces → underscores
- Apostrophes removed
- Lowercase

---

## Integration Steps for Godot

1. Create a `CardVisual.tscn` scene:
   - Root: Control (832×1248, or scaled)
   - Child 1: TextureRect (art)
   - Child 2: TextureRect (frame)
   - Child 3: Label (cost, centered, top)
   - Child 4: Label (faction/type, centered)
   - Child 5: Label (name, centered, with dark bg panel)
   - Child 6: Label (effect, centered, autowrap, with dark bg panel)
   - Child 7: Label (keywords, centered, golden)

2. Script the CardVisual:
   - `set_card_data(card: CardData)` — populates all labels
   - `load_art(path: String)` — sets art texture
   - `load_frame(path: String)` — sets frame texture

3. For performance, pre-render all 240 cards as PNGs (done ✓) and use those as textures.
   - Only use dynamic compositing if you need runtime text changes.

## Faction-Specific Configs (LOCKED)

### Undead (FINAL — 2026-04-27)
- **Mode:** Full bleed + color-based transparency
- **Transparency:** `center_threshold = (215, 205, 190, 25)` — cream/beige center transparent, skulls/bones stay opaque
- **Text positions (shifted UP for Undead):**
  - Name: y=960 (was 1050, moved up 90)
  - Effect: y=1000 (was 1090, moved up 90)
  - Keywords: y=1050 (was 1140, moved up 90)
- **Frame:** `undead_frame.png` — skulls overlap art edges

### Dragon (LOCKED — 2026-04-29)
- **Mode:** Full bleed + color-based transparency
- **Scale factor:** 1.0x (natural frame size — NO zoom)
- **Transparency:** `center_threshold = (248, 248, 248, 10)` — strict white threshold
- **Text positions:** y=55/1120/1170
- **Text on white:** True
- **Frame:** `dragon_frame.png`

**Design rationale:** Strict white threshold (248, 248, 248, 10) makes the center fully transparent while preserving all gold scrollwork and decorative elements. Text sits in the cream text boxes — name at top (y=55), effects at bottom (y=1120), keywords at y=1170.

**Evolution:**
- Started with 1.15x zoom — user said frame was "too big"
- Switched to 1.0x natural size
- Text centering bug fixed (proper bbox handling)
- Final positions refined: name y=55, effect y=1120, keywords y=1170
- User confirmed: "perfect card position! Save it"

### Demon (FINAL — 2026-04-27)
- **Mode:** Full bleed + color-based transparency
- **Transparency:** `center_threshold = (200, 190, 180, 20)` — cream center transparent, decorative border stays opaque
- **Text positions:** y=1050/1090/1140
- **Frame:** `demon_frame.png` — ornate gothic border with gold accents

### Aberration (LOCKED — 2026-04-29)
- **Mode:** Full bleed + color-based transparency
- **Transparency:** `center_threshold = (240, 240, 240, 15)` — white center transparent, tentacle/glitch border stays opaque
- **Scale factor:** 1.0x (no zoom)
- **Text positions:** y=1050/1090/1140
- **Frame:** `aberration_frame.png` — tentacles and digital glitch border in cyan/green/purple

**Key insight:** The Aberration frame is mostly white center with colorful tentacles and glitch artifacts around the edges. Color-based transparency correctly keeps all decorative elements (tentacles, digital glitches) on top of the art.

**Discovery process:**
- Initially used `window` (geometric) with inset art — window was cutting off tentacles
- User sent reference showing art should be FULL BLEED with tentacles ON TOP
- Switched to `center_threshold` (color-based) — white center transparent, decorative border stays opaque
- Only 0.6% of center area is non-white, so threshold works cleanly

### Construct (LOCKED — 2026-04-29)
- **Mode:** Full bleed + color-based transparency (NOT inset!)
- **Scale factor:** 1.2x (frame expanded to cover edges)
- **Transparency:** `center_threshold = (240, 240, 240, 15)` — white center transparent, brass/steel border stays opaque
- **Text positions (final — LOCKED):**
  - Name: y=1040 (40px above effect)
  - Effect: y=1080
  - Keywords: y=1150
- **Frame:** `construct_frame.png` — brass gears and steel border
- **Key insight:** Construct frame is almost entirely white center with thin brass border. Geometric window cuts too much. Color-based keeps the decorative border.

**Evolution:**
- Text centering bug fixed (proper bbox handling)
- Name moved from y=200 to y=1040 (user requested 40px above effect text)
- User confirmed: "Perfect! That is how Construct cards should look!"

**Status: LOCKED. Do not change text positions without user approval.**

### Elemental (FINAL — 2026-04-27)
- **Mode:** Full bleed + geometric mask
- **Window:** `{"left": 180, "top": 180, "right": 180, "bottom": 280}`
- **Inset art:** 30px overlap padding so flowing border overlaps art edges
- **Text positions:** y=1050/1090/1140
- **Frame:** `elemental_frame.png`

### Goblin (FINAL — 2026-04-29)
- **Mode:** Full bleed + color-based transparency (NOT inset!)
- **Transparency:** `center_threshold = (220, 210, 195, 20)` — cream center transparent, jagged border stays opaque
- **Text positions:** y=140/940/1010
- **Frame:** `goblin_frame.png` — jagged metal border with blue accents
- **Key insight:** Goblin frame has cream center and dark jagged border, same pattern as Construct. Color-based works better than geometric window.

### Universal (LOCKED — 2026-04-29)
- **Mode:** INSET (three-panel layout)
- **Window:** `{"left": 151, "top": 245, "right": 153, "bottom": 301}` — EXACT center art panel dimensions from user-marked blue rectangle
- **Art panel size:** 528×702 pixels
- **Top name panel:** Opaque cream
- **Center art window:** Transparent (art shows through, sized to fit)
- **Bottom effect panel:** Opaque cream
- **Text positions:** y=150/1070/1140
- **Overlap:** 0 (art fits exactly inside cream panel, no border overlap)
- **Frame:** `untyped_frame.png` — brown/gold border with three cream panels

**Key measurements:**
- Center art panel: x=151, y=245, w=528, h=702
- Brown border: ~50px thick all sides
- Art sits ON TOP of frame, visible through center panel

---

*Generated: 2026-04-25*
*Updated: 2026-04-29 (Universal locked with exact measurements)*
*Compositor version: v8 (Universal window-based with scaled coordinates)*
