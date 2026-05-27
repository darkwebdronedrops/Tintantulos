# Card Compositor V8 — Final Implementation

## Status: COMPLETE (240/240 cards generated)

## Faction Modes

### INSET Mode (Construct, Goblin)
- Art sits inside a window within the frame
- Frame border stays fully opaque
- Text panel at bottom is opaque
- Art is cropped to fit the window

### FULL BLEED Mode (Aberration, Demon, Dragon, Elemental, Undead, Universal)
- Art fills ENTIRE card edge-to-edge
- Frame border overlays the art
- Frame center is made transparent (geometric mask)
- Text sits directly on the art with outlines for readability

### SCALED FULL BLEED (Demon, Dragon)
- Frame border is INSET from edges by design
- Scale frame UP by 15-20% to make border reach edges
- Crop back to card size
- Fill white edge pixels with matching border color

## Per-Faction Configuration

```python
FACTION_CONFIGS = {
    "Aberration": {
        "mode": "full_bleed",  # Transparent center, border overlays
    },
    "Construct": {
        "mode": "inset",  # Art in window, opaque frame
        "window": {"left": 70, "top": 90, "right": 70, "bottom": 328},
    },
    "Demon": {
        "mode": "full_bleed",
        "scale_factor": 1.20,  # Scale up to reach edges
        "border_size": 80,
        "border_color": (115, 106, 122, 255),  # Purple-grey
    },
    "Dragon": {
        "mode": "full_bleed",
        "scale_factor": 1.15,
        "border_size": 70,
        "border_color": (220, 200, 180, 255),  # Gold/cream
    },
    "Goblin": {
        "mode": "inset",
        "window": {"left": 70, "top": 100, "right": 70, "bottom": 628},
    },
}
```

## Key Technical Learnings

1. **Demon/Dragon frames** are designed with border INSET from edges
   - Must scale frame UP, then crop back
   - Fill remaining white pixels with border color

2. **Goblin frame** is 76.6% cream-colored with ZERO pure white
   - Color-based transparency fails completely
   - Must use geometric mask (window coordinates)

3. **Text positioning** varies per faction
   - INSET factions: text sits in opaque panel at bottom
   - FULL BLEED factions: text sits on art with outlines

## Generated Files

- `assets/sprites/cards/printable/*.png` — 240 printable card images
- `scripts/compositor_demon.py` — Demon-specific compositor
- `docs/DEMON_COMPOSITOR_APPROACH.md` — Detailed approach doc
- `docs/CARD_COMPOSITOR_SPEC.md` — Technical specification
