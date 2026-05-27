# Demon Card Compositor Approach

## The Breakthrough

After 13 iterations, the correct approach for Demon cards was found:

### The Problem
- Demon frame has decorative border that is INSET from the image edges
- White background fills the gap between border and image edge
- Simple transparency (making white transparent) left ugly white gaps

### The Solution
1. **Scale the frame UP** by ~20% so the decorative border reaches the absolute edges
2. **Crop back** to card size (centered)
3. **Make center transparent** using geometric mask
4. **Fill white edge pixels** with matching border color (RGB 115, 106, 122)

### Result
- Art fills ENTIRE card edge-to-edge
- Decorative border (black drips) overlays the art edges
- No white gaps — seamless purple-grey border
- Text sits directly on the art

### Configuration
```python
"Demon": {
    "mode": "full_bleed",
    "scale_factor": 1.20,
    "border_size": 80,
    "border_color": (115, 106, 122, 255),
    "name_y": 920,
    "effect_y": 980,
    "keywords_y": 1060,
}
```

### Key Insight
The frame was designed with the border inset from edges. To make it edge-to-edge,
scale the entire frame up, then crop. Fill any remaining white gaps with the 
border's base color.
