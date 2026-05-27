# PixelLab Asset Generation Spec — Floor 3: The Gearworks

**Project:** acanous_floor3_demo  
**Style:** Pixel art, 128×128 for puzzle objects, 64×64 for kami/kami, dark industrial/steampunk palette  
**Format:** PNG, transparent background (RGBA), non-interlaced  
**Palette:** Dark steel, brass, copper, glowing accents (blue for water/coolant, orange for fire/heat, green for steam, yellow for light)

---

## 🎨 PRIORITY 1 — Missing Kami Sprites (11 total)

**Size:** 64×64 pixels  
**Style:** Small spirit/deity figures, ethereal, semi-transparent glow, industrial motifs  
**Scale in game:** 1.5× (96×96 display)

| Filename | Theme | Description |
|----------|-------|-------------|
| `kami_water.png` | Water spirit | Blue translucent figure, dripping water, cooling coil motifs, sad posture |
| `kami_heat.png` | Fire spirit | Orange/red figure wreathed in flame, furnace background, aggressive stance |
| `kami_maintenance.png` | Grease spirit | Oily brown-green figure, tool belt, wrench in hand, calm mechanical pose |
| `kami_regulation.png` | Gauge spirit | Grey figure with dial-face head, needle hands, balanced stance, ticking motif |
| `kami_steam.png` | Steam spirit | White/pale blue figure, pipe-like body, pressure valve head, hissing posture |
| `kami_heat_treatment.png` | Forge spirit | Deep orange figure, anvil-shaped base, hammer arm, tempered metal skin |
| `kami_light.png` | Light spirit | Bright yellow/white figure, prism body, radiating beams, upward pose |
| `kami_time.png` | Clock spirit | Brass figure, clock-face chest, pendulum legs, precise geometric form |
| `kami_friction.png` | Oil spirit | Sleek silver figure, oil-slick sheen, smooth flowing hair, lubricated joints |
| `kami_momentum.png` | Wheel spirit | Circular body, spinning blur effect, spoke-like limbs, dynamic pose |
| `kami_balance.png` | Scale spirit | Symmetrical figure, balance beam arms, equal weights hanging, centered stance |

**Existing (keep):** `kami_friction.png`, `kami_heat.png`, `kami_maintenance.png` — these 3 are good but will be duplicated as unique files for the new names.

---

## 🎨 PRIORITY 2 — Missing Puzzle Object Sprites

**Size:** 128×128 pixels  
**Style:** Isometric or flat-top-down, industrial machinery, clear readable shapes at 0.5×–0.8× scale  
**Palette:** Dark metal with colored accents per room theme

### New Sprites Needed

| Filename | Room | Description |
|----------|------|-------------|
| `puzzle_draft_prism.png` | 4 Draft | Crystal prism, hexagonal, pale blue glow, steam wisps around it |
| `puzzle_temper_bucket.png` | 5 Temper | Quench bucket, dark metal, water inside, steam rising, riveted seams |
| `puzzle_temper_lens.png` | 5 Temper | Thermal lens, glass disc, heat distortion effect, brass mounting ring |
| `puzzle_beacon_platform.png` | 6 Beacon | Elevator platform, grated metal floor, gear edges, safety rail |
| `puzzle_beacon_crystal.png` | 6 Beacon | Light crystal, tall prism, bright white glow, metallic base mount |
| `puzzle_escapement_wheel.png` | 7 Escapement | Escapement wheel, brass, 6 teeth visible, central axle hole, gear spokes |
| `puzzle_bearing_ball.png` | 8 Bearing | Single ball bearing, steel sphere, slight reflection highlight, 16px usable |
| `puzzle_flyweight.png` | 9 Flywheel | Counterweight mass, iron block, bolt holes, hanging mount point |
| `puzzle_counterweight_pan.png` | 10 Counterweight | Balance pan, brass bowl, chain attachment points, ornate rim |

### Existing Puzzle Sprites (Verified — Keep)
All existing puzzle sprites are good quality and properly wired. No changes needed.

---

## 🎨 PRIORITY 3 — Core Game Sprites

| Filename | Size | Description |
|----------|------|-------------|
| `token_gear_devil.png` | 64×64 | Gear Devil Token — cog-shaped coin, infernal red glow, stamped seal in center, brass base |
| `light_emitter.png` | 64×64 | Light Emitter — small crystal socket, dormant = dim grey, active = bright beam shooting upward |
| `trap_grasping_cog.png` | 128×128 | Trap: Grasping Cog — giant gear with teeth as claws, spring-loaded, rusted metal |
| `trap_compression.png` | 128×128 | Trap: Compression — piston/plate descending from ceiling, hydraulic lines, pressure gauge |
| `trap_recalibration.png` | 128×128 | Trap: Recalibration — rotating lever arms, calibration dials, sparks flying |
| `trap_warning_sermon.png` | 64×64 | Trap: Warning Sermon — Gear Devil face hologram, red glowing eyes, broadcast antenna |

---

## 🎨 PRIORITY 4 — Room Interior Tile Sprites (Optional Polish)

Currently all room interiors are procedural Polygon2D. These would be nice-to-have but not critical:

| Filename | Size | Description |
|----------|------|-------------|
| `floor_quench.png` | 256×256 | Water-stained concrete, drain grates, blue-grey tint |
| `floor_spark.png` | 256×256 | Scorched metal floor, ash patches, heat cracks |
| `floor_governor.png` | 256×256 | Clean steel grid, inspection markings, oil stains |
| `wall_generic.png` | 256×256 | Riveted steel panels, pipes, industrial wall texture |

---

## 📋 Generation Checklist

### Batch 1 — Kami (11 files, 64×64)
- [ ] kami_water.png
- [ ] kami_heat.png
- [ ] kami_maintenance.png
- [ ] kami_regulation.png
- [ ] kami_steam.png
- [ ] kami_heat_treatment.png
- [ ] kami_light.png
- [ ] kami_time.png
- [ ] kami_friction.png
- [ ] kami_momentum.png
- [ ] kami_balance.png

### Batch 2 — Puzzle Objects (9 files, 128×128)
- [ ] puzzle_draft_prism.png
- [ ] puzzle_temper_bucket.png
- [ ] puzzle_temper_lens.png
- [ ] puzzle_beacon_platform.png
- [ ] puzzle_beacon_crystal.png
- [ ] puzzle_escapement_wheel.png
- [ ] puzzle_bearing_ball.png
- [ ] puzzle_flyweight.png
- [ ] puzzle_counterweight_pan.png

### Batch 3 — Core Game (6 files)
- [ ] token_gear_devil.png (64×64)
- [ ] light_emitter.png (64×64)
- [ ] trap_grasping_cog.png (128×128)
- [ ] trap_compression.png (128×128)
- [ ] trap_recalibration.png (128×128)
- [ ] trap_warning_sermon.png (64×64)

---

## 🎨 PixelLab Prompt Templates

### Kami Prompt Template
```
Pixel art sprite, 64x64, transparent background.
A small [ELEMENT] spirit deity, ethereal glowing body, industrial steampunk motifs.
[DESCRIPTION].
Dark palette with [COLOR] accents.
Single character, centered, top-down view.
```

**Example (Water Kami):**
```
Pixel art sprite, 64x64, transparent background.
A small water spirit deity, ethereal dripping body, cooling coil motifs wrapping around limbs.
Sad hunched posture, water droplets falling from fingertips.
Dark blue-grey palette with cyan glow accents.
Single character, centered, top-down view.
```

### Puzzle Object Prompt Template
```
Pixel art sprite, 128x128, transparent background.
Industrial machinery [OBJECT], steampunk factory style.
[DESCRIPTION].
Dark metal with [ACCENT COLOR] highlights.
Isometric view, centered, clear readable silhouette.
```

**Example (Draft Prism):**
```
Pixel art sprite, 128x128, transparent background.
Industrial crystal prism, hexagonal shape, pale blue glow emanating from core.
Steam wisps curling around base, brass mounting clamp.
Dark metal with cyan glow accents.
Isometric view, centered, clear readable silhouette.
```

---

## 📁 Output Directory
All generated sprites go to:
```
acanous_floor3_demo/assets/sprites/puzzles/
```

Godot will auto-generate `.import` files on first load. No manual import config needed.

---

*Spec created: April 30, 2026*
*For: Acanous Floor 3 Demo polish pass*
