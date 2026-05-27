# Room Decoration Design Document — Floor 3: The Gearworks

**Project:** acanous_floor3_demo  
**Document:** ROOM_DECORATION_DESIGN.md  
**Date:** 2026-05-03  
**Author:** Room Interior Design Sub-Agent  

---

## Table of Contents

1. [Pixel Style Analysis](#1-pixel-style-analysis)
2. [Global Color Palette Reference](#2-global-color-palette-reference)
3. [Room 1/12 — The Quench](#3-room-112--the-quench)
4. [Room 2 — The Spark](#4-room-2--the-spark)
5. [Room 3 — The Governor](#5-room-3--the-governor)
6. [Room 4 — The Draft](#6-room-4--the-draft)
7. [Room 5 — The Temper](#7-room-5--the-temper)
8. [Room 6 — The Beacon](#8-room-6--the-beacon)
9. [Room 7 — The Escapement](#9-room-7--the-escapement)
10. [Room 8 — The Bearing](#10-room-8--the-bearing)
11. [Room 9 — The Flywheel](#11-room-9--the-flywheel)
12. [Room 10 — The Counterweight](#12-room-10--the-counterweight)
13. [Room 11 — The Oiler](#13-room-11--the-oiler)
14. [Room 0 — Crown Cog Hub](#14-room-0--crown-cog-hub)
15. [Sprite Generation Script](#15-sprite-generation-script)

---

## 1. Pixel Style Analysis

### Texture Dimensions
- **Floor textures:** 256×256 px (except env_floor_hex at 400×400)
- **Wall textures:** 256×256 px
- **Game scale:** Room interior ~350 units across; textures tile at 1.2–1.5× scale
- **Pixel density:** ~0.73 px per game unit (256 texture / 350 room width)

### Art Style Characteristics
- **Pixel style:** Top-down orthogonal with subtle 2.5D shading (not pure flat)
- **Edge treatment:** Crisp 1px black or dark outlines on major structural elements
- **Shading:** Medium directional shading — top-left light source, bottom-right shadows
- **Detail density:** Medium-high; individual bolts, rivets, tiles visible at game scale
- **Color bands:** 3–4 shades per material (highlight → midtone → shadow → dark shadow)
- **Tile size:** ~32–64px per floor tile in texture space (~44–88 game units)
- **Animation readiness:** Textures have clear separation of static vs. glow layers

### Material Rendering Rules
| Material | Highlight | Midtone | Shadow | Dark Shadow | Glow |
|----------|-----------|---------|--------|-------------|------|
| Steel/Iron | #A8B0C0 | #6E7888 | #3A4454 | #1E2838 | — |
| Brass/Gold | #E8C86C | #B89440 | #8A6A20 | #5A4A10 | — |
| Copper | #D89868 | #A87040 | #784820 | #4A3010 | — |
| Rust | #C87040 | #A05030 | #703820 | #402010 | — |
| Water/Coolant | #8AB8D0 | #5A90B0 | #306888 | #184058 | #B0E0FF |
| Fire/Glow | #FFE8A0 | #F0A040 | #C06020 | #804010 | #FFCC00 |
| Steam | #D0E0E8 | #A8C0D0 | #80A0B8 | — | #FFFFFF |
| Oil/Grease | #6A6050 | #4A4030 | #2E2818 | #1A1408 | — |

---

## 2. Global Color Palette Reference

### Floor Texture Color Summary

| Room | Texture | Dominant Base | Accent 1 | Accent 2 | Glow |
|------|---------|---------------|----------|----------|------|
| Quench (1/12) | env_floor_quench.png | #3E4A5A (blue-grey steel) | #5A6A7A (rivets) | #2A3848 (dark panels) | — |
| Spark (2) | env_floor_spark.png | #4A3A3A (warm dark grey) | #E86020 (lava glow) | #B84018 (ember) | #FFCC00 |
| Governor (3) | env_floor_governor.png | #2E2E32 (near-black) | #3A5A3A (green seam) | #4A4A52 (tiles) | — |
| Draft (4) | env_floor_draft.png | #2A3A42 (dark teal) | #4A6A7A (pipes) | #1E8890 (valves) | #40C0C0 |
| Temper (5) | env_floor_temper.png | #2A2830 (charcoal) | #E85020 (heat border) | #C03010 (ember) | #FF8020 |
| Beacon (6) | env_floor_beacon.png | #3A3A4A (dark steel) | #E8B830 (light strips) | #F0D060 (lamp glow) | #FFE040 |
| Escapement (7) | env_floor_escapement.png | #3A3A42 (dark grey) | #C8A040 (brass gear) | #E8D068 (gold highlight) | #FFE8A0 |
| Bearing (8) | env_floor_bearing.png | #3A3A42 (dark grey) | #6A6A78 (silver frame) | #505058 (grime) | — |
| Flywheel (9) | env_floor_flywheel.png | #3A3048 (purple-grey) | #B87040 (copper frame) | #5A5068 (tiles) | — |
| Counterweight (10) | env_floor_counterweight.png | #2A2A38 (dark blue-black) | #C8A040 (gold circles) | #E8D068 (gold highlight) | #FFE8A0 |
| Oiler (11) | env_floor_oiler.png | #4A4038 (dark brown) | #6A6050 (oil stains) | #8A7A68 (lighter wear) | — |
| Hex (fallback) | env_floor_hex.png | #4A4A4A (dark grey) | #6A6A6A (lighter hex) | #3A3A3A (darker hex) | — |

### Wall Texture Color Summary

| Room | Texture | Dominant | Accent 1 | Accent 2 | Glow |
|------|---------|----------|----------|----------|------|
| Quench | env_wall_water.png | #3A4454 (dark blue stone) | #4A5868 (bricks) | #2A3444 (mortar) | — |
| Spark | env_wall_heat.png | #2E2020 (dark rust) | #E86020 (embers) | #F0A040 (fire) | #FFCC00 |
| Governor/Draft/Beacon | env_wall_steam.png | #2A3A42 (dark teal) | #3A5A68 (panels) | #4A7A88 (ports) | #60C0C0 |
| Temper | env_wall_heat.png | #2E2020 (dark rust) | #E86020 (embers) | #F0A040 (fire) | #FFCC00 |
| Escapement/Counterweight | env_wall_brass.png | #2A2A38 (dark blue-black) | #C8A040 (gold trim) | #E8D068 (highlights) | #FFE8A0 |
| Bearing | env_wall_oil.png | #3A2E38 (dark purple-brown) | #5A4A58 (panels) | #8A7A88 (oil sheen) | — |
| Flywheel | env_wall_iron.png | #3A3A42 (dark grey) | #E86020 (molten spots) | #6A6A78 (iron) | #FF8020 |
| Oiler | env_wall_oil.png | #3A2E38 (dark purple-brown) | #5A4A58 (panels) | #8A7A88 (oil sheen) | — |
| Fallback | env_wall_metal.png | #3A3A48 (dark steel) | #6A6A78 (panels) | #E86020 (rust spots) | — |

---

## 3. Room 1/12 — The Quench

**Floor shape:** Rounded rectangle, 350×245 game units (base_size=175, h=0.7×)  
**Floor color:** #3E4A5A (blue-grey steel)  
**Wall color:** #4A5868 (blue metal)  
**Floor texture:** env_floor_quench.png — riveted steel panels with drain grates, side rails  
**Wall texture:** env_wall_water.png — dark blue-grey stone bricks  
**Theme:** Water channels, cooling systems, condensation

### Decoration Layout (13 objects)

#### 1. Central Drain Grate
- **Type:** Floor furniture / puzzle interactable
- **Size:** 36×36 game units (26×26 px in texture)
- **Position:** Center of room (0, 0)
- **Shape:** Octagonal grate with 8 triangular cutouts
- **Colors:** #2A3848 (base), #4A5868 (grate bars), #1E2838 (holes)
- **Pixel style:** Top-down, 2.5D — grate bars raised 2px above surface with shadow beneath
- **Detail:** 8 radial bars, 2px wide each, converging at center bolt (4×4 px octagon)
- **Animation:** Subtle water ripple — every 2 seconds, a faint blue wave (#60A0C0 at 30% opacity) expands from center

#### 2. Water Channel (×6)
- **Type:** Floor furniture
- **Size:** 15×60 game units each (11×44 px)
- **Position:** Radiating from center at 60° intervals (0°, 60°, 120°, 180°, 240°, 300°)
- **Shape:** Tapered rectangle, wider at outer end (15→20 units)
- **Colors:** #306888 (water surface), #184058 (channel bottom), #8AB8D0 (water highlight)
- **Pixel style:** Top-down flat with water surface at y=0, channel walls 3px deep shadow
- **Detail:** Channel has 2px raised metal rim (#5A6A7A) on both sides. Water surface has subtle horizontal line highlights every 8px
- **Animation:** Water flows outward — 2px-wide highlight streaks move from center to edge at 8px/sec

#### 3. Cooling Coil Ring (×3)
- **Type:** Floor furniture / ambient
- **Size:** Diameters 100, 140, 180 game units
- **Position:** Concentric around center
- **Shape:** Circular pipe loop, 6px wide (4px pipe + 2px shadow)
- **Colors:** #4A6A7A (pipe), #6A90A8 (highlight), #2A3A48 (shadow side)
- **Pixel style:** Top-down, slight 2.5D — pipe appears as a tube with top highlight and bottom shadow
- **Detail:** 32 segments per ring. Each segment is a 4×6 px curved rectangle. Every 4th segment has a small valve knob (3×3 px, #8AB8D0)
- **Animation:** Subtle condensation drip — random segments spawn a 2px water droplet that falls 8px and fades

#### 4. Steam Vent (×4)
- **Type:** Wall detail / ambient
- **Size:** 12×12 game units (9×9 px)
- **Position:** (-120, -80), (120, -80), (-120, 80), (120, 80) — corners
- **Shape:** Square vent with 2×2 cross grille
- **Colors:** #5A5A5A (vent frame), #3A3A3A (grille), #A0C0D0 (steam)
- **Pixel style:** Top-down flat
- **Detail:** Frame is 2px thick. Cross grille divides vent into 4 sections. Each section has 3 diagonal slats (1px)
- **Animation:** Steam puffs — every 3–5 seconds, a 4px white cloud (#FFFFFF at 40% opacity) rises 10px and fades over 1.5 seconds

#### 5. Water Basin (Back Wall)
- **Type:** Floor furniture
- **Size:** 160×40 game units (117×29 px)
- **Position:** Along back wall at y = -100 (top of room)
- **Shape:** Trapezoid — 160 wide at wall, 140 wide at front edge
- **Colors:** #254050 (basin metal), #306888 (water surface), #8AB8D0 (water highlight)
- **Pixel style:** Top-down with 2.5D rim — front edge 3px raised, back edge flush with wall
- **Detail:** Basin rim is 4px wide (#5A6A7A). Water surface has gentle wave lines (1px horizontal lines every 6px, offset by 2px alternating). A single floating gear fragment (6×6 px, #4A5868) drifts on surface
- **Animation:** Water surface shimmer — horizontal highlight lines shift position 2px every 1.5 seconds

#### 6. Condensation Puddle (×3)
- **Type:** Ambient object
- **Size:** 20×14 game units (15×10 px) each, irregular blob shape
- **Position:** Random near channels: (-40, 55), (35, -45), (70, 60)
- **Shape:** Amorphous organic blob with 8–10 vertices
- **Colors:** #406880 (puddle surface), #6088A0 (highlight edge), #204058 (deep center)
- **Pixel style:** Top-down flat with edge highlight only (no 2.5D — puddles are surface-level)
- **Detail:** Edge is 1px lighter (#6088A0). Center has 2–3 small bubble dots (2px, #80B0C8). Surface has faint gear-oil rainbow sheen (1px dithered #8090A0/#7080B0)
- **Animation:** Bubbles pop — small 2px bubbles appear at random, expand to 4px over 0.8s, then pop and fade

#### 7. Pipe Junction (×2)
- **Type:** Wall detail
- **Size:** 18×18 game units (13×13 px)
- **Position:** (-90, -95), (90, -95) — wall-mounted
- **Shape:** Cross-shaped pipe fitting with 4 arms
- **Colors:** #5A6A7A (pipe), #4A5868 (shadow), #8AB8D0 (coolant in transparent section)
- **Pixel style:** Top-down, slight 2.5D — arms have 1px highlight on top edge
- **Detail:** Central hub is 6×6 px octagon. Each arm is 4×12 px. One arm has a small pressure gauge (5×5 px circular, #8AB8D0 face, #E86020 needle pointing to "COOL")
- **Animation:** Gauge needle twitch — needle wobbles ±2px every 2–4 seconds (pressure fluctuation)

#### 8. Tool Rack (Left Wall)
- **Type:** Wall detail
- **Size:** 60×16 game units (44×12 px)
- **Position:** (-130, 40) — mounted on left wall
- **Shape:** Horizontal bar with 3 tool hooks
- **Colors:** #4A5868 (rack), #6A7A8A (hooks), #3A4858 (shadow)
- **Pixel style:** Top-down flat, wall-mounted
- **Detail:** Rack is 4px thick horizontal bar. Three U-shaped hooks (3px deep, 4px wide) hold tools: wrench (8×3 px, #8A9AA8), pipe cutter (6×3 px, #B8C8D0), and a hanging chain (2×12 px, #6A7A8A with alternating light/dark links)
- **Animation:** Chain sways — slight 1px left-right oscillation every 3 seconds (subtle ambient motion)

#### 9. Cooling Tank (Right Wall)
- **Type:** Floor furniture / puzzle container
- **Size:** 50×70 game units (37×51 px)
- **Position:** (110, 20) — right side
- **Shape:** Vertical cylinder (seen from top as oval: 50 wide × 40 tall due to perspective)
- **Colors:** #3A4858 (tank body), #506070 (highlight rim), #204058 (shadow), #8AB8D0 (coolant visible through sight glass)
- **Pixel style:** Top-down with strong 2.5D — front half is visible curved surface, back half is top cap
- **Detail:** Top cap is 50×20 px oval. Front curved surface shows 3 horizontal bands (rivet lines, 2px, #4A5868). Sight glass is 8×20 px vertical strip, shows blue coolant level at 60% with faint bubble animation inside. Top has 4 bolt heads (3×3 px, #6A7A8A) around rim
- **Animation:** Coolant bubbles rise inside sight glass — 1px bubbles move upward at 2px/sec, pop at surface
- **Puzzle note:** Contains Gear Devil Token — visible only after draining (sight glass goes empty, token revealed at bottom)

#### 10. Drip Pan (×2)
- **Type:** Ambient object
- **Size:** 24×18 game units (18×13 px)
- **Position:** (-60, 90), (60, 90) — near front of room
- **Shape:** Shallow rectangle with 1px raised lip
- **Colors:** #4A5868 (pan), #6080A0 (collected water), #3A4858 (lip shadow)
- **Pixel style:** Top-down flat
- **Detail:** 1px lip all around. Center has thin water film (1–2 px, #6080A0). A single gear tooth fragment (4×3 px, #5A6A7A with #8AB8D0 edge corrosion) sits in one pan
- **Animation:** Drip from above — every 4 seconds, a 2px water drop falls from off-screen into pan, creating 1px ripple ring that expands 3px and fades

#### 11. Pressure Relief Valve (×1)
- **Type:** Floor furniture / puzzle interactable
- **Size:** 16×16 game units (12×12 px)
- **Position:** (0, -60) — center-back
- **Shape:** Circular wheel with 8 spokes
- **Colors:** #6A7A8A (wheel), #8A9AA8 (spokes), #4A5868 (center hub), #E8C040 ("HOT" warning label)
- **Pixel style:** Top-down, 2.5D — wheel appears as a flat disc with 1px edge highlight
- **Detail:** 12px diameter circle. 8 radial spokes (2px wide, extend from 3px center to 10px edge). Center hub is 4×4 px. Small rectangular label (3×5 px) on one spoke reads "HOT" in 1px #E86020 text
- **Animation:** Wheel rotates — when puzzle active, wheel turns 45° over 2 seconds (puzzle completion animation)

#### 12. Wet Floor Sign
- **Type:** Ambient object
- **Size:** 14×10 game units (10×7 px)
- **Position:** (-30, 75) — near front
- **Shape:** A-frame sign seen from top as two triangles
- **Colors:** #E8C040 (yellow caution), #1E2838 (base), #E86020 (warning stripe)
- **Pixel style:** Top-down flat
- **Detail:** Two 6×4 px triangles in A-shape. Two diagonal #E86020 stripes (1px) across each face. Base is 10×3 px rectangle
- **Animation:** Static

#### 13. Save Terminal (Room 12 ONLY)
- **Type:** Puzzle / save point
- **Size:** Crystal: 36×50 game units (26×37 px); Platform: 48×28 game units (35×20 px)
- **Position:** (100, -10) — offset from center-right
- **Shape:** Platform = hexagon (flat); Crystal = tall pointed obelisk with angled facets
- **Colors:** Platform: #263038 (dark base). Crystal: #40D878 (bright green), #60F098 (core glow), #A0FFC0 (brightest highlight)
- **Pixel style:** Platform = flat top-down. Crystal = 2.5D with 3 visible facets
- **Detail:** Platform is HexGrid hex scaled to 1.2×. Crystal: 26px tall, 8px wide at base, tapering to 2px point. Three facets visible — left facet #40D878, right facet #30B860, center front facet #50E888. Core is 6×18 px inner glow strip (#60F098). Floating ring around crystal: 44×12 px hexagonal band, #40D878 at 50% opacity, rotates ±10°
- **Animation:** 
  - Crystal pulsing: Modulates between #40D878 and #50E888 over 2 seconds (breathing glow)
  - Core brighter pulse: #60F098 ↔ #A0FFC0 over 1 second, offset 0.5s from crystal
  - Ring: Rotates -10° ↔ +10° over 4 seconds, loops
  - Floating particles: 2px green sparkles (#A0FFC0) drift upward from crystal, fade over 1.5 seconds, spawn every 0.3 seconds
- **Interaction:** Label "[S] Save" below platform, 10px font, #40D878 color

---

## 4. Room 2 — The Spark

**Floor shape:** Hexagon, radius 175 game units  
**Floor color:** #4A3A3A (warm dark grey)  
**Wall color:** #6A3020 (rust red)  
**Floor texture:** env_floor_spark.png — dark warm tiles with lava channels, ember spots, brick border  
**Wall texture:** env_wall_heat.png — dark vertical beams with orange embers and fire  
**Theme:** Ignition, furnace, boiler pipes, sparks, ash

### Decoration Layout (12 objects)

#### 1. Central Furnace
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 80×80 game units (59×59 px)
- **Position:** Center (0, 0)
- **Shape:** Hexagonal body with beveled edges, seen from top as hexagon
- **Colors:** Body: #A83018 (rust red), #E86020 (hot surface). Inner glow: #F0A040 (orange), #FFE8A0 (yellow core)
- **Pixel style:** Top-down with strong 2.5D — edges appear raised 4px, creating a "box" effect
- **Detail:** Outer hexagon: 59px diameter, 6 sides. Edge bevel: 3px wide, #C84020. Top surface: #A83018 with heat cracks (1px #E86020 branching lines, 3–5 cracks). Inner glow hexagon: 30px diameter, #F0A040 center fading to #E86020 edge. Core: 12×12 px, #FFE8A0 with subtle 2px flicker animation
- **Animation:** 
  - Core flicker: Core color oscillates #FFE8A0 ↔ #FFC060 over 0.2–0.5 seconds (random intervals, fire flicker)
  - Heat waves: 2px horizontal wavy lines (#F0A040 at 20% opacity) rise from furnace, move up 20px over 2 seconds and fade
  - Spark ejection: Every 1–3 seconds, 2–3 px orange particles (#FFE8A0) shoot outward in random directions at 40px/sec, fade after 0.8 seconds

#### 2. Inner Glow Core
- **Type:** Ambient / puzzle indicator
- **Size:** 44×44 game units (32×32 px)
- **Position:** Centered within furnace
- **Shape:** Hexagonal glow pool
- **Colors:** #FFE8A0 (brightest center), #F0A040 (mid glow), #E86020 (edge)
- **Pixel style:** Flat glow — no 3D, pure light emission
- **Detail:** Radial gradient from center to edge. 3 concentric hexagon bands: inner 10px #FFE8A0, middle 20px #F0A040, outer 32px #E86020. Each band has 1px noise dither for fire texture
- **Animation:** Pulsing brightness — all three bands modulate intensity ±15% over 0.3 seconds (irregular fire flicker)

#### 3. Radiating Boiler Pipe (×6)
- **Type:** Floor furniture / puzzle element
- **Size:** 6×100 game units each (4×74 px)
- **Position:** Radiating from furnace at 60° intervals, extending to radius 100
- **Shape:** Cylindrical pipe, seen from top as 4px-wide line with 1px highlight/shadow
- **Colors:** #C86030 (hot pipe), #E88040 (highlight), #A04020 (shadow side), #F0A040 (glow reflection)
- **Pixel style:** Top-down, 2.5D — pipe appears as a rounded tube with top highlight strip
- **Detail:** 4px wide. Center 2px are #C86030. Top 1px edge is #E88040 (highlight from furnace glow). Bottom 1px edge is #A04020 (shadow). Every 20px along pipe: small rivet band (4×4 px, 2 rivets, #8A6A40). Pipe end has a flange (6×6 px octagon, #A04020)
- **Animation:** Heat shimmer — pipes appear to warp slightly (1px vertical oscillation of highlight edge, 2px amplitude, 3 second cycle)

#### 4. Boiler Tank (×6)
- **Type:** Floor furniture
- **Size:** 24×24 game units (18×18 px) each
- **Position:** At end of each pipe, radius 105 from center
- **Shape:** Small hexagonal tank, top-down as hexagon with 2.5D shading
- **Colors:** #8A8A8A (tank body), #A0A0A0 (highlight), #6A6A6A (shadow), #E86020 (heat glow from connection)
- **Pixel style:** Top-down, 2.5D — small cylinder
- **Detail:** 18px hexagon. Edge bevel 2px. Top surface #8A8A8A. Center has small pressure gauge (6×6 px circle, #C0C0C0 face, #E86020 needle). One side glows orange (#E86020 at 30% overlay) from pipe heat
- **Animation:** Gauge needle wobble — needle oscillates ±5° every 1.5 seconds. Heat glow pulses 30% ↔ 45% opacity every 2 seconds

#### 5. Spark Particle (×12)
- **Type:** Ambient object / particle
- **Size:** 6×6 game units (4×4 px) each
- **Position:** Scattered around furnace, radius 55–105
- **Shape:** Small square with glow halo
- **Colors:** Core: #FFE8A0. Halo: #F0A040 at 40% opacity
- **Pixel style:** Flat glow particle
- **Detail:** 4×4 px core with 6×6 px glow halo (2px border, fading opacity). Each spark has slightly different hue: #FFE8A0 to #FFCC00 to #FF9030
- **Animation:** 
  - Floating: Each spark drifts randomly at 5–15 px/sec
  - Flicker: Core size oscillates 3×3 ↔ 5×5 px over 0.2–0.6 seconds
  - Fade: Sparks fade to transparent over 2–3 seconds, then respawn elsewhere
  - Spawn: New sparks appear near furnace or hot pipes, 2–3 per second

#### 6. Ash Pile (×4)
- **Type:** Ambient object
- **Size:** 24×16 game units (18×12 px) each
- **Position:** (-100, -80), (100, -80), (-100, 80), (100, 80) — corners
- **Shape:** Irregular mound, wider at base
- **Colors:** #3A3028 (ash grey), #4A4038 (lighter ash), #2A2018 (dark base)
- **Pixel style:** Top-down with 2.5D — mounds have 2px "height" shadow on bottom-right
- **Detail:** Amorphous blob shape, 14–18 px wide at base, 8–10 px tall. Surface has 3–5 small darker specks (2px, #2A2018) and 1–2 small ember remnants (2px, #E86020 at 60% opacity). One ash pile near furnace has a larger hot center (4×4 px, #E86020 glow)
- **Animation:** Ember remnants pulse — #E86020 ↔ #F0A040 over 3 seconds (slow breathing ember). Hot center flickers faster (0.5 second cycle)

#### 7. Coal Scuttle (×1)
- **Type:** Floor furniture
- **Size:** 28×20 game units (20×15 px)
- **Position:** (-50, 110) — front-left
- **Shape:** Open-top box with sloped sides, seen from top as trapezoid
- **Colors:** #6A6050 (scuttle), #4A4030 (shadow), #2A2018 (coal pile), #E86020 (ember spots in coal)
- **Pixel style:** Top-down, 2.5D — open top shows coal pile at surface level
- **Detail:** Trapezoid: 20px wide at top, 14px at base, 15px tall. Sides 2px thick. Coal pile fills top 8px, #2A2018 with 3–4 #E86020 ember specks (2px). Handle on back side: 8×2 px, #8A7A68, with 2px rivet
- **Animation:** Ember specks flicker — random 2px dots brighten #E86020 ↔ #F0A040 over 1–2 seconds

#### 8. Fire Poker Rack (×1)
- **Type:** Wall detail
- **Size:** 30×14 game units (22×10 px)
- **Position:** (50, 110) — front-right wall
- **Shape:** Horizontal rack with 2 tools
- **Colors:** #6A6050 (rack), #8A7A68 (tools), #E86020 (heated tool tip)
- **Pixel style:** Top-down flat
- **Detail:** Rack: 22×4 px horizontal bar, #6A6050, 2 mounting brackets (3×3 px, #5A5040). Tool 1 (poker): 18×2 px, #8A7A68, tip glows #E86020 at 2px. Tool 2 (shovel): 14×4 px flat blade, #8A7A68, wooden handle #5A4030 at end
- **Animation:** Heated tip glow pulse — #E86020 ↔ #F0A040 over 2 seconds

#### 9. Furnace Door (Back Wall)
- **Type:** Wall detail / puzzle interactable
- **Size:** 70×30 game units (51×22 px)
- **Position:** (0, -120) — centered on back wall
- **Shape:** Rectangular door with arched top, seen from top
- **Colors:** #8A3020 (door), #A04030 (frame), #E86020 (glow around edges), #2A2018 (interior darkness)
- **Pixel style:** Top-down, slight 2.5D — door appears inset into wall
- **Detail:** Frame: 51×22 px rectangle, 3px thick #A04030. Door: 45×16 px, #8A3020 with 2 diagonal #A04030 braces (2px). Small circular handle: 5×5 px, #C8A040, on right side. Gap under door: 2px strip showing #E86020 glow and #2A2018 interior
- **Animation:** 
  - Idle: Glow seeps from gap — 1px #E86020 flicker line at bottom edge
  - Puzzle active: Door shakes — 1px left-right jitter, 0.1 second bursts every 3 seconds
  - Puzzle solved: Door slides open 8px, revealing bright #F0A040 interior

#### 10. Pressure Gauge Bank (×3)
- **Type:** Wall detail / puzzle indicator
- **Size:** 16×16 game units (12×12 px) each
- **Position:** (-60, -110), (0, -110), (60, -110) — above furnace door
- **Shape:** Circular gauge with needle
- **Colors:** #C0C0C0 (face), #2A2A2A (rim), #E86020 (needle), #40D878 (green zone), #E8C040 (yellow zone), #E86020 (red zone)
- **Pixel style:** Top-down flat, face-up
- **Detail:** 12px diameter circle. Rim 1px #2A2A2A. Face: #C0C0C0 with 3 colored zone arcs (4px each): green left, yellow middle, red right. Tick marks: 8 small 1px lines around rim. Needle: 1×6 px line from center, #E86020 with 2×2 px center pivot
- **Animation:** Needles sweep — each gauge needle moves independently based on puzzle state. Idle: gentle oscillation ±3° at 1.5 second cycle. Puzzle active: rapid sweep to target zone over 2 seconds

#### 11. Brick Debris (×5)
- **Type:** Ambient object
- **Size:** 8×6 to 12×8 game units (6×4 to 9×6 px) each
- **Position:** Scattered near walls: (-80, 60), (90, 70), (-110, -40), (110, -60), (0, 130)
- **Shape:** Small irregular rectangles (broken bricks)
- **Colors:** #5A4030 (brick), #4A3020 (shadow side), #E86020 (scorched edge on some)
- **Pixel style:** Top-down, slight 2.5D — 1px shadow on bottom-right
- **Detail:** Each brick is 6×4 to 9×6 px rectangle with 1–2 chips missing (irregular corners). Some have 1px #E86020 scorch mark on one edge. One larger brick (9×6 px) has a half-visible gear tooth impression (3×2 px indent)
- **Animation:** Static

#### 12. Heat Distortion Zone
- **Type:** Ambient overlay
- **Size:** 120×120 game units (88×88 px)
- **Position:** Centered on furnace
- **Shape:** Circular area
- **Colors:** #F0A040 at 8% opacity overlay
- **Pixel style:** Screen-space effect layer
- **Detail:** Not a discrete sprite — atmospheric heat haze. 2px horizontal sine-wave distortion lines, #F0A040 at 8%, period 12px, amplitude 2px
- **Animation:** Wave lines drift upward at 3px/sec, fade at top of zone, respawn at bottom

---

## 5. Room 3 — The Governor

**Floor shape:** Wide rectangle, 385×210 game units (base_size=175, w=1.1×, h=0.6×)  
**Floor color:** #2E2E32 (near-black)  
**Wall color:** #505055 (steel)  
**Floor texture:** env_floor_governor.png — very dark grid tiles, subtle green seam, clean inspection grid  
**Wall texture:** env_wall_steam.png — dark teal metal panels with circular ports  
**Theme:** Speed regulation, control panels, levers, gauges, precision machinery

### Decoration Layout (14 objects)

#### 1. Central Control Pillar
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 30×160 game units (22×117 px)
- **Position:** Center (0, 0), vertical span from y=-80 to y=80
- **Shape:** Tall rectangular column with rounded corners
- **Colors:** #4A4A52 (body), #6A6A78 (highlight edge), #2E2E32 (shadow face), #40D878 (status LED strip)
- **Pixel style:** Top-down, 2.5D — front face is lighter, left/right faces are darker
- **Detail:** 22px wide × 117px tall. Front face (center 14px): #4A4A52 with 3 vertical grooves (1px, #2E2E32) simulating panel seams. Left/right faces (4px each): #2E2E32. Highlight on front-left edge: 1px #6A6A78. LED strip: 2×100 px vertical, #40D878 at 60%, with 6 small 2×2 px LED indicators spaced every 16px — when active, LEDs glow #60F098 and blink
- **Animation:** LED indicators blink in sequence top→bottom, 0.3 seconds per LED, looping. When puzzle solved: all LEDs steady green

#### 2. Left Control Bank
- **Type:** Floor furniture / puzzle interactable
- **Size:** 80×120 game units (59×88 px)
- **Position:** (-70, 0) — left of pillar
- **Shape:** Large rectangular console with sloped front panel
- **Colors:** #3A3A42 (console), #4A4A52 (front panel), #6A6A78 (highlight), #2E2E32 (shadow), #C8A040 (brass trim)
- **Pixel style:** Top-down, 2.5D — sloped front creates a trapezoid visible area
- **Detail:** 59×88 px. Top surface: #3A3A42, 40×88 px. Front panel (sloped): visible as 19×88 px trapezoid, #4A4A52. Brass trim: 2px border, #C8A040. Panel contains 4 horizontal slots (see Lever Slots below) and 1 large RPM display (see Center Gauge below)
- **Animation:** Panel lights flicker — 2px indicator dots (#40D878) pulse when levers are moved

#### 3. Right Control Bank
- **Type:** Floor furniture / puzzle interactable
- **Size:** 80×120 game units (59×88 px)
- **Position:** (70, 0) — right of pillar, mirror of left
- **Shape:** Mirror of left control bank
- **Colors:** Same as left bank
- **Pixel style:** Same as left bank
- **Detail:** Same layout, mirrored. 4 lever slots + gauge
- **Animation:** Same as left bank

#### 4. Lever Slot (×8, 4 per side)
- **Type:** Puzzle interactable
- **Size:** 50×4 game units (37×3 px) each
- **Position:** Left: (-95, -40), (-95, -10), (-95, 20), (-95, 50). Right: (45, -40), (45, -10), (45, 20), (45, 50)
- **Shape:** Horizontal track groove
- **Colors:** #2E2E32 (track), #4A4A52 (highlight rim), #1E1E22 (deep groove)
- **Pixel style:** Top-down, 2.5D — groove appears recessed 2px
- **Detail:** 37×3 px. Track is 1px deep groove (center 1px #1E1E22). Rim highlight: 1px #4A4A52 top edge. Small tick marks at 25%, 50%, 75%: 1px vertical lines, #6A6A78
- **Animation:** When lever moves, track glows faintly #40D878 at 20% along the moved section

#### 5. Lever Handle (×8)
- **Type:** Puzzle interactable
- **Size:** 10×8 game units (7×6 px) each
- **Position:** Sliding within each lever slot, default at 50% position
- **Shape:** Small rectangular handle with grip texture
- **Colors:** #B89440 (brass), #E8C86C (highlight), #8A6A20 (shadow), #C8A040 (grip ridges)
- **Pixel style:** Top-down, 2.5D — handle stands 3px proud of surface
- **Detail:** 7×6 px rectangle. Top: #B89440 with 2 vertical 1px grip ridges (#C8A040). Left edge highlight: 1px #E8C86C. Right edge shadow: 1px #8A6A20. Center dot: 2×2 px, #E8C86C, indicating grab point
- **Animation:** 
  - Idle: Subtle 1px vertical bob (±1px, 2 second cycle)
  - Dragged: Handle slides along track, leaves 2px trail #40D878 at 15% opacity that fades over 0.5 seconds
  - Correct position: Handle glows #40D878 aura (4×4 px halo, 30% opacity)

#### 6. Center Gauge (Main RPM Dial)
- **Type:** Puzzle centerpiece / indicator
- **Size:** 56×56 game units (41×41 px)
- **Position:** (0, 0) — center, mounted on pillar face
- **Shape:** Circular dial with concentric rings
- **Colors:** #3A5A5A (face), #2E4A4A (rim), #E86020 (needle), #40D878 (green zone), #E8C040 (yellow zone), #E86020 (red zone), #C0C0C0 (tick marks)
- **Pixel style:** Top-down flat, face-up
- **Detail:** 41px diameter. Outer rim: 2px #2E4A4A. Face: #3A5A5A. Zone arcs: 3 colored bands, each ~12px wide (green 0–90°, yellow 90–180°, red 180–270°). Tick marks: 16 small 1px lines, #C0C0C0. Major ticks (every 45°): 2px lines. Needle: 1×18 px from center, #E86020 with 2×2 px #C0C0C0 pivot cap. Center bolt: 4×4 px, #E8C86C
- **Animation:** 
  - Idle: Needle hunts gently ±5° around rest position, 1 second cycle
  - Puzzle active: Needle sweeps to target RPM zone over 2 seconds, overshoots 3°, settles back
  - Aligned: Needle holds steady in green zone, small #40D878 pulse at pivot

#### 7. Calibration Marks (×8)
- **Type:** Ambient detail
- **Size:** Each mark: 6×2 game units (4×1 px)
- **Position:** Around gauge at 45° intervals, radius 64 from center
- **Shape:** Short radial lines
- **Colors:** #6A6A6A (marks), #8A8A8A (major marks)
- **Pixel style:** Top-down flat
- **Detail:** 4×1 px lines pointing toward gauge center. Every other mark is 5×2 px (major). Minor: #6A6A6A. Major: #8A8A8A with 1px dot at outer end
- **Animation:** Static

#### 8. Gear Ratio Display (×2)
- **Type:** Wall detail / puzzle indicator
- **Size:** 40×24 game units (29×18 px) each
- **Position:** (-110, -80) left wall, (110, -80) right wall
- **Shape:** Rectangular display panel with digital readout
- **Colors:** #2E2E32 (panel), #3A3A42 (bezel), #40D878 (display digits), #1E1E22 (display background)
- **Pixel style:** Top-down, 2.5D — panel inset 2px into wall
- **Detail:** 29×18 px. Bezel: 2px #3A3A42. Display area: 25×14 px, #1E1E22. Three 5×8 px digit segments (7-segment style), #40D878. Each digit composed of 1px lines. Current reading shows "1:1" in idle state. Small label above: "RATIO" in 3×5 px pixel font, #6A6A78
- **Animation:** Digits change when levers adjusted — 7-segment segments flicker during transition (0.1 second scramble), then settle to new value. When correct: digits glow brighter #60F098

#### 9. Pipe Bundle (×4)
- **Type:** Wall detail
- **Size:** 16×100 game units (12×74 px) each bundle
- **Position:** Vertical runs on walls: (-140, 0), (140, 0), and horizontal: (0, -110), (0, 110)
- **Shape:** 3 parallel pipes seen from top as 3 thin lines
- **Colors:** #4A4A52 (pipes), #6A6A78 (highlight), #2E2E32 (shadow), #40D878 (coolant in one pipe)
- **Pixel style:** Top-down, 2.5D — each pipe is 3px wide tube
- **Detail:** Bundle of 3 pipes, each 3px wide, 2px spacing. Pipes 1 & 2: #4A4A52 with 1px #6A6A78 highlight. Pipe 3 (coolant): #3A5A5A with 1px #40D878 glow center. Horizontal bundles have small 4×4 px flange joints every 30px. Vertical bundles have wall brackets (4×3 px, #5A5A60) every 40px
- **Animation:** Coolant pipe has flowing light — 2px #40D878 dot moves through pipe at 10px/sec. Flange joints: small 1px #40D878 blink when coolant passes

#### 10. Warning Sticker (×2)
- **Type:** Ambient object
- **Size:** 12×8 game units (9×6 px) each
- **Position:** (-130, -60), (130, 60) — on console sides
- **Shape:** Small rectangular label
- **Colors:** #E8C040 (yellow background), #1E1E22 (border), #E86020 (warning triangle)
- **Pixel style:** Top-down flat
- **Detail:** 9×6 px rectangle. Yellow fill. 1px black border. Center: 4×4 px warning triangle, #E86020 with 1px #1E1E22 exclamation mark. Text too small to read (1px dots suggesting "CAUTION")
- **Animation:** Static

#### 11. Oil Can (×1)
- **Type:** Ambient object
- **Size:** 14×10 game units (10×7 px)
- **Position:** (80, 70) — on right console surface
- **Shape:** Small cylindrical can with spout
- **Colors:** #8A6A20 (brass), #E8C86C (highlight), #6A5018 (shadow), #2E2E32 (cap)
- **Pixel style:** Top-down, 2.5D — small cylinder 2px tall
- **Detail:** 10×7 px oval (cylinder top). Body #8A6A20. 1px highlight on top-left edge. Cap: 4×3 px rectangle, #2E2E32, offset to one side. Spout: 3×2 px, #6A5018, pointing diagonally. Small oil drip: 1px #4A3A20 dot at spout tip
- **Animation:** Oil drip forms — 1px dot grows to 2px over 3 seconds, then falls 4px and leaves a 2px #4A3A20 spot on console surface, then cycle repeats

#### 12. Scattered Screws (×6)
- **Type:** Ambient object
- **Size:** 3×3 game units (2×2 px) each
- **Position:** Random on console surfaces: (-75, 35), (-65, 55), (72, -35), (85, -15), (78, 45), (-82, -25)
- **Shape:** Tiny circles (2×2 px octagons)
- **Colors:** #8A8A8A (screw head), #6A6A6A (shadow), #C0C0C0 (highlight)
- **Pixel style:** Top-down flat
- **Detail:** 2×2 px. One px is #C0C0C0 (highlight from above-left). Other 3 px are #8A8A8A with 1px #6A6A6A shadow
- **Animation:** Static

#### 13. Floor Inspection Hatch
- **Type:** Floor furniture
- **Size:** 40×40 game units (29×29 px)
- **Position:** (0, 80) — front center
- **Shape:** Square with rounded corners, recessed
- **Colors:** #3A3A42 (hatch), #2E2E32 (recess), #6A6A78 (rim), #C8A040 (hinge)
- **Pixel style:** Top-down, 2.5D — hatch is inset 3px below floor level
- **Detail:** 29×29 px square with 3px rounded corners. Rim: 2px #6A6A78. Recessed area: #2E2E32 with grid pattern (4×4 px squares, #3A3A42). Center has small 6×6 px warning symbol: #E8C040 triangle with #E86020 center dot. Hinge on back edge: 8×3 px, #C8A040 with 2 rivets
- **Animation:** Subtle vibration — hatch shifts 1px in random direction every 5 seconds (machinery hum), returns to center after 0.2 seconds

#### 14. Steam Vent (×2)
- **Type:** Ambient / atmospheric
- **Size:** 20×8 game units (15×6 px) each
- **Position:** (-100, -100), (100, -100) — top wall corners
- **Shape:** Rectangular floor grate
- **Colors:** #4A4A52 (grate), #2E2E32 (holes), #A0C0D0 (steam)
- **Pixel style:** Top-down flat
- **Detail:** 15×6 px. Grate bars: 3 vertical 1px lines, #4A4A52, 4px spacing. Holes: #2E2E32. Small steam wisps: 2px #A0C0D0 at 30% opacity drifting upward from grate
- **Animation:** Steam wisps drift up 10px over 2 seconds, fade out, respawn every 1–3 seconds

---

## 6. Room 4 — The Draft

**Floor shape:** Elongated rectangle, 420×175 game units (base_size=175, w=1.2×, h=0.5×)  
**Floor color:** #2A3A42 (dark teal)  
**Wall color:** #455055 (steam blue)  
**Floor texture:** env_floor_draft.png — dark teal tiles, pipe columns, circular valve details, stone brick borders  
**Wall texture:** env_wall_steam.png — dark teal metal panels with circular ports  
**Theme:** Airflow, wind tunnel, steam vents, turbine, pressure

### Decoration Layout (11 objects)

#### 1. Top Wall Vent (×5)
- **Type:** Wall detail / puzzle element
- **Size:** 16×10 game units (12×7 px) each
- **Position:** (-100, -55), (-50, -55), (0, -55), (50, -55), (100, -55)
- **Shape:** Rectangular vent with horizontal slats
- **Colors:** #1E2A30 (vent interior), #3A5A68 (slats), #2A3A42 (frame), #40C0C0 (steam hint)
- **Pixel style:** Top-down flat
- **Detail:** 12×7 px. Frame: 1px #2A3A42. Interior: #1E2A30. 3 horizontal slats: 1px #3A5A68, spaced 2px. Steam wisps: 1px #40C0C0 at 20% opacity drift from slats when open
- **Animation:** 
  - Closed: Static, no steam
  - Open: Steam wisps drift down from vent at 4px/sec, fade over 1.5 seconds
  - Puzzle active: Slats rotate 45° (appear as diagonal lines) over 0.5 seconds

#### 2. Bottom Wall Vent (×5)
- **Type:** Wall detail / puzzle element
- **Size:** 16×10 game units (12×7 px) each
- **Position:** (-100, 55), (-50, 55), (0, 55), (50, 55), (100, 55)
- **Shape:** Same as top vents
- **Colors:** Same as top vents
- **Pixel style:** Same as top vents
- **Detail:** Same as top vents
- **Animation:** Same as top vents, but steam drifts upward when open

#### 3. Turbine Fan (Left End)
- **Type:** Floor furniture / puzzle centerpiece
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 44×44 game units (32×32 px)
- **Position:** (-130, 0) — left end of room
- **Shape:** Octagonal hub with 3 radiating blades
- **Colors:** #5A5A5A (hub), #8A8A8A (blades), #A0A0A0 (highlight), #4A4A4A (shadow), #40C0C0 (steam trail)
- **Pixel style:** Top-down, 2.5D — hub is 4px thick, blades sweep 2px above floor
- **Detail:** 32px octagonal hub. Center: 8×8 px #5A5A5A. Hub ring: 16px diameter, 3px thick, #4A4A4A with 1px #8A8A8A highlight. Three blades: each is a 3×20 px tapered rectangle, #8A8A8A with 1px #A0A0A0 leading edge and 1px #4A4A4A trailing edge. Blades spaced at 120°. Blade tips have small 3×3 px #40C0C0 steam condensation dots
- **Animation:** 
  - Idle: Blades stationary
  - Active: Rotation at 90°/second, continuous. Motion blur: 1px #8A8A8A ghost blades at 30° offset
  - Steam trail: 2px #40C0C0 wisps spiral outward from spinning blades

#### 4. Airflow Arrow (×4)
- **Type:** Ambient indicator
- **Size:** 12×10 game units (9×7 px) each
- **Position:** (-80, 0), (-20, 0), (40, 0), (100, 0) — along center axis
- **Shape:** Right-pointing arrow (direction of airflow)
- **Colors:** #60A0B0 (arrow body), #80C0D0 (highlight), #40C0C0 (glow)
- **Pixel style:** Top-down flat with glow halo
- **Detail:** 9×7 px triangle + 2×4 px tail. Triangle: #60A0B0. 1px #80C0D0 highlight on leading edge. Glow halo: 11×9 px, #40C0C0 at 20% opacity. Arrows spaced to show flow direction left→right
- **Animation:** 
  - Static pulse: All arrows pulse opacity 40% ↔ 70% in sequence left→right, 0.5 second stagger, 2 second cycle
  - Active flow: Arrows drift right 8px over 1 second, fade, respawn at left

#### 5. Steam Wisp (×5)
- **Type:** Ambient particle
- **Size:** 8×8 game units (6×6 px) each
- **Position:** Floating: (-60, -20), (-30, 25), (10, -35), (50, 30), (80, -15)
- **Shape:** Amorphous cloud blob
- **Colors:** #80C0D0 (core), #A0D0E0 (highlight), #60A0B0 (shadow edge), #40C0C0 (glow)
- **Pixel style:** Flat translucent particle
- **Detail:** 6×6 px core with 8×8 px glow halo (2px border, fading opacity). Core is irregular — 4–6 px blob, not geometric. Surface has 1–2 small brighter #A0D0E0 highlights
- **Animation:** 
  - Drift: Each wisp moves in lazy sine wave pattern (amplitude 10px, period 3–5 seconds)
  - Fade: Core opacity oscillates 60% ↔ 85% over 2–4 seconds
  - Merge: When two wisps come within 15px, they merge into larger 10×10 px wisp, then split after 2 seconds

#### 6. Pressure Tank (×2)
- **Type:** Floor furniture
- **Size:** 30×50 game units (22×37 px) each
- **Position:** (-110, -40), (110, 40) — corners
- **Shape:** Vertical cylinder (oval from top)
- **Colors:** #3A5A68 (tank), #4A7A88 (highlight), #2A3A42 (shadow), #E8C040 (pressure gauge)
- **Pixel style:** Top-down, 2.5D — strong cylindrical shading
- **Detail:** 22×37 px oval. Top cap: 22×12 px ellipse, #3A5A68. Front curved surface: 22×25 px, #4A7A88 with 2 vertical #2A3A42 shadow bands (3px wide, on left/right edges). Center: vertical sight glass strip, 4×20 px, shows #60C0C0 steam level at varying heights. Bottom rim: 2px #2A3A42. Top valve: 6×4 px, #8A8A8A with 2×2 px #E8C040 handle
- **Animation:** Steam level rises/falls — sight glass fill moves 2–4 px up/down every 2 seconds. Pressure gauge needle on top wobbles ±3°. Valve handle rotates 20° when pressure releases

#### 7. Pipe Junction Manifold
- **Type:** Floor furniture / puzzle element
- **Size:** 50×30 game units (37×22 px)
- **Position:** (0, 0) — center of room
- **Shape:** Cross-shaped pipe intersection with valves
- **Colors:** #3A5A68 (pipes), #4A7A88 (highlight), #2A3A42 (shadow), #E8C040 (valve handles), #E86020 (hot pipe section)
- **Pixel style:** Top-down, 2.5D — pipes are 5px diameter cylinders
- **Detail:** Horizontal pipe: 37×5 px, #3A5A68. Vertical pipe: 5×22 px, #3A5A68. Intersection: 8×8 px, #4A7A88. Four valve handles: 4×4 px crosses, #E8C040, one on each pipe arm. One pipe section (right arm) is #E86020 at 40% overlay — hot steam pipe. Small 2×2 px #40C0C0 leak dots where hot pipe meets manifold
- **Animation:** 
  - Valve handles rotate when adjusted — 90° turn over 0.5 seconds
  - Leak dots pulse: 2px #40C0C0 dots grow/shrink 1px ↔ 3px, 1 second cycle
  - Hot pipe glow: #E86020 overlay pulses 40% ↔ 55% opacity

#### 8. Draft Prism (Puzzle Object)
- **Type:** Puzzle interactable / key object
- **Size:** 32×32 game units (24×24 px)
- **Position:** (80, 0) — right side, target position when solved
- **Shape:** Hexagonal crystal prism on brass mount
- **Colors:** #60C0C0 (crystal), #80E0E8 (core glow), #A0F0F8 (brightest facet), #C8A040 (brass mount), #3A2A18 (base)
- **Pixel style:** 2.5D isometric-ish — prism shows 3 visible facets
- **Detail:** 24×24 px. Brass mount: 16×8 px at base, #C8A040 with 2px #E8D068 highlight. Prism: 16×18 px hexagonal body, 3 visible facets — left #60C0C0, right #40A0A0, front #80E0E8. Core glow: 6×12 px vertical strip, #A0F0F8, visible through front facet. Steam wisps: 2–3 px #80C0D0 curls at base
- **Animation:** 
  - Dormant: Dim, core glow #60C0C0 at 40%
  - Active: Core brightens #80E0E8 at 80%, small light beam (2×20 px, #A0F0F8) shoots right
  - Steam wisps: 2px wisps curl around prism, 3 second cycle

#### 9. Grate Floor Section (×3)
- **Type:** Floor furniture
- **Size:** 40×30 game units (29×22 px) each
- **Position:** (-80, 40), (0, 40), (80, 40) — front area
- **Shape:** Rectangular grated section
- **Colors:** #2A3A42 (grate), #1E2A30 (holes), #4A5A68 (rim), #60C0C0 (steam from below)
- **Pixel style:** Top-down flat
- **Detail:** 29×22 px. Rim: 1px #4A5A68. Grate: 1px #2A3A42 bars in grid pattern, 4px spacing. Holes: #1E2A30. Steam wisps rise through holes: 2px #60C0C0 at 15% opacity, drift up 6px and fade
- **Animation:** Steam wisps continuously rise — new wisps spawn at random grate holes every 0.5 seconds, rise 8px over 1.5 seconds, fade

#### 10. Wind Sock (×2)
- **Type:** Wall detail / ambient indicator
- **Size:** 16×20 game units (12×15 px) each
- **Position:** (-130, -60), (130, 60) — near turbine
- **Shape:** Tapered cone pointing in airflow direction
- **Colors:** #E8C040 (sock body), #E86020 (stripes), #C8A040 (rim), #8A7A68 (mount)
- **Pixel style:** Top-down flat
- **Detail:** 12×15 px tapered shape: 8px wide at mount end, 3px wide at tip. 2 horizontal #E86020 stripes (2px wide). Mount: 4×4 px square, #8A7A68, with 2px rivet
- **Animation:** Sock ripples in "wind" — tip oscillates ±4px perpendicular to flow direction, 0.8 second cycle. When airflow reverses (puzzle state), sock flips to point opposite direction over 0.5 seconds

#### 11. Condensation Droplets (×8)
- **Type:** Ambient object
- **Size:** 4×4 game units (3×3 px) each
- **Position:** On walls and pipes: (-120, -50), (-60, -50), (20, -50), (90, -50), (-120, 50), (-60, 50), (20, 50), (90, 50)
- **Shape:** Small circular droplet
- **Colors:** #80C0D0 (droplet), #A0D0E0 (highlight), #60A0B0 (shadow)
- **Pixel style:** Top-down, 2.5D — droplet is a 1px-high dome
- **Detail:** 3×3 px. Center: #80C0D0. Top-left highlight: 1px #A0D0E0. Bottom-right shadow: 1px #60A0B0
- **Animation:** 
  - Grow: Droplet forms over 3–5 seconds, growing from 1×1 to 3×3 px
  - Fall: When full size, drops 10px onto floor, leaves 3×2 px #60A0B0 wet spot
  - Cycle: New droplet starts forming at same spot after 2 second delay

---

## 7. Room 5 — The Temper

**Floor shape:** Square with slight curve, 350×315 game units (base_size=175, h=0.8×/0.9×)  
**Floor color:** #2A2830 (charcoal)  
**Wall color:** #553525 (forge brown)  
**Floor texture:** env_floor_temper.png — dark charcoal-black tiles, orange-red ember/glow borders, brick frame, heat damage  
**Wall texture:** env_wall_heat.png — dark vertical beams with orange embers  
**Theme:** Heat treatment, forge, furnace, anvil, quenching, thermal expansion

### Decoration Layout (13 objects)

#### 1. Back Wall Furnace
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 140×60 game units (103×44 px)
- **Position:** (0, -100) — back wall
- **Shape:** Wide trapezoid, wider at wall, tapering forward
- **Colors:** #A03018 (furnace body), #C04020 (highlight), #802818 (shadow), #E86020 (heat glow), #F0A040 (inner fire)
- **Pixel style:** Top-down, 2.5D — furnace front face is a sloped wall visible from top
- **Detail:** 103×44 px. Base at wall: 103px wide. Front edge: 83px wide. Height (depth): 44px. Body: #A03018 with 2px #802818 shadow on right/bottom edges. 4 vertical heat cracks (1px, #E86020) on surface. Top lip: 2px #C04020. Furnace interior glow seeps from opening
- **Animation:** 
  - Heat pulse: Body color shifts #A03018 ↔ #B03820 over 2 seconds (breathing heat)
  - Crack glow: Heat cracks pulse #E86020 ↔ #F0A040 over 1 second, brighter during puzzle active
  - Ember spit: Random 2px #F0A040 sparks fly from cracks every 2–4 seconds, arc 10px, fade

#### 2. Furnace Opening (Glow)
- **Type:** Puzzle indicator / ambient
- **Size:** 70×40 game units (51×29 px)
- **Position:** Centered in furnace body at (0, -90)
- **Shape:** Trapezoid opening, glowing interior
- **Colors:** #F0A040 (bright interior), #E86020 (opening rim), #C06020 (inner shadow), #FFE8A0 (fire core)
- **Pixel style:** Flat glow — no 3D, pure light emission
- **Detail:** 51×29 px. Opening rim: 2px #E86020. Interior: radial gradient from #FFE8A0 center to #F0A040 edges. Fire texture: 3–4 small 2×3 px #FFE8A0 flickering spots. Bottom of opening has 3px "ember bed" #C06020 with 1px #F0A040 highlights
- **Animation:** 
  - Fire flicker: Interior spots flicker #FFE8A0 ↔ #FFC060 over 0.2–0.5 seconds (irregular)
  - Heat waves: 2px horizontal wavy lines (#F0A040 at 15%) rise from opening, drift up 15px over 2 seconds
  - Intensity: When puzzle active (furnace heating), overall glow increases 20%. When too hot: #E86020 warning overlay pulses

#### 3. Anvil (Center)
- **Type:** Floor furniture / puzzle element
- **Size:** 44×20 game units (32×15 px) body + 56×10 game units (41×7 px) top
- **Position:** (0, 25) — center-forward
- **Shape:** Wide flat top + narrower base body
- **Colors:** Body: #3A3A42 (dark steel). Top: #5A5A60 (polished steel). Highlight: #8A8A90. Shadow: #2A2A30
- **Pixel style:** Top-down, 2.5D — top is at "working height", body below
- **Detail:** Top surface: 41×7 px rectangle, #5A5A60. Beveled edges: 1px #8A8A90 highlight on front-left, 1px #2A2A30 shadow on back-right. Base body: 32×15 px, #3A3A42, narrower than top (trapezoid shape). Horn: 8×5 px pointed extension on left side, #5A5A60. Bottom shadow: 2px #1E1E20 on floor beneath body
- **Animation:** 
  - Idle: Static
  - Puzzle active: Subtle 1px vertical vibration when forge is at correct temperature (resonance)
  - Heat glow: When hot, top edge has 1px #E86020 overlay at 20% opacity

#### 4. Anvil Top Surface Detail
- **Type:** Ambient detail
- **Size:** 56×10 game units (41×7 px)
- **Position:** On top of anvil
- **Shape:** Flat working surface with tool marks
- **Colors:** #5A5A60 (steel), #6A6A70 (lighter marks), #4A4A52 (darker marks), #E86020 (heat discoloration spots)
- **Pixel style:** Top-down flat
- **Detail:** Surface has 2–3 small irregular darker patches (2–3 px, #4A4A52) from hammer strikes. One 3×2 px #E86020 heat discoloration at center. 1px scratch line (3 px long, #4A4A52) near right edge. Very subtle: tiny 1px #8A8A90 spark remnants near center
- **Animation:** Spark remnants fade in/out — #8A8A90 at 20% ↔ 50% over 2 seconds

#### 5. Workbench (×2)
- **Type:** Floor furniture
- **Size:** 44×30 game units (32×22 px) each
- **Position:** (-90, 60), (90, 60) — left and right sides
- **Shape:** Rectangular table with 4 leg shadows
- **Colors:** #4A3A30 (wood top), #5A4A40 (lighter grain), #3A2E28 (shadow), #6A6050 (legs)
- **Pixel style:** Top-down, 2.5D — tabletop 4px thick, legs visible as 2px floor shadows
- **Detail:** 32×22 px tabletop. Wood grain: 2–3 vertical 1px lines, #5A4A40, slightly wavy. Edge bevel: 1px #5A4A40. Four leg shadows: 3×2 px each at corners, #3A2E28, offset 2px bottom-right. Left bench has scattered tools: 4×2 px tongs (#8A8A8A), 3×3 px small hammer (#6A6050). Right bench has 6×4 px leather apron (#6A4030) and 2×2 px nail box (#4A3A30)
- **Animation:** Static

#### 6. Quenching Barrel (×2)
- **Type:** Floor furniture / puzzle element
- **Size:** 28×34 game units (21×25 px) each
- **Position:** (-70, 65), (70, 65) — near workbenches
- **Shape:** Vertical cylinder (oval from top)
- **Colors:** #3A2E28 (barrel), #4A4038 (highlight), #2A2018 (shadow), #306888 (water surface), #8AB8D0 (water highlight)
- **Pixel style:** Top-down, 2.5D — barrel body visible as curved surface
- **Detail:** 21×25 px oval. Body: #3A2E28 with 2 vertical #4A4038 highlight bands (4px wide). Horizontal barrel bands: 2px #2A2018 rings at 30% and 70% height. Top opening: 15×8 px ellipse showing water surface #306888 with 1px #8AB8D0 wave lines. Metal hoops: 3px wide, #5A5048. One barrel has a 4×3 px ladle handle protruding (#6A6050)
- **Animation:** 
  - Water surface: 1px wave lines shift 2px horizontally every 1.5 seconds
  - Steam: When hot object enters (puzzle interaction), 3–4 px white steam (#FFFFFF at 40%) rises, expands, fades over 2 seconds
  - Ladle drip: If ladle present, 1px water drop falls every 4 seconds

#### 7. Heat Haze Lines (Above Furnace)
- **Type:** Ambient overlay
- **Size:** 120×10 game units (88×7 px)
- **Position:** (0, -115) — above furnace
- **Shape:** Horizontal wavy lines
- **Colors:** #F0A040 at 30% opacity, #E86020 at 15% opacity
- **Pixel style:** Screen-space translucent overlay
- **Detail:** 8 horizontal 1px wavy lines, spaced 1px apart. Each line is a sine wave with 4px amplitude, 12px period. Lines drift upward at 2px/sec
- **Animation:** Continuous drift upward — lines spawn at bottom of zone, drift 10px up over 2 seconds, fade out. New lines spawn continuously. During puzzle "too hot" state: lines increase to 12, opacity doubles to 60%

#### 8. Hammer (On Anvil)
- **Type:** Puzzle tool / ambient
- **Size:** 26×7 game units (19×5 px)
- **Position:** (12, 10) — on anvil top, slightly right of center
- **Shape:** T-headed hammer
- **Colors:** #5A5A5A (head), #6A6A78 (highlight), #4A4A4A (shadow), #6A5030 (wood handle)
- **Pixel style:** Top-down, 2.5D — head 3px thick, handle 2px
- **Detail:** Head: 13×5 px T-shape. Top bar: 13×3 px, #5A5A5A with 1px #6A6A78 highlight. Face: 3×5 px, #4A4A4A (striking surface). Handle: 6×2 px, #6A5030, extends diagonally down-right. Shadow: 1px #2A2A2A offset
- **Animation:** 
  - Idle: Static
  - Puzzle active (player interaction): Hammer lifts 4px, slams down (0.2 seconds), 1px #FFE8A0 spark at impact point, then returns to rest

#### 9. Tongs (×1)
- **Type:** Floor furniture
- **Size:** 18×4 game units (13×3 px)
- **Position:** (-80, 75) — on left workbench
- **Shape:** Two parallel arms with gripping end
- **Colors:** #6A6A78 (metal), #8A8A90 (highlight), #5A5A60 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 13×3 px. Two 1px parallel lines (#6A6A78), 2px apart. Gripping end: 3×3 px U-shape, #5A5A60. Handle ends: 2×2 px loops, #8A8A90. One arm has 1px #E86020 heat glow near gripping end (recently used)
- **Animation:** Heat glow fades — #E86020 at 60% → 0% over 10 seconds after use

#### 10. Gear Blank (×2)
- **Type:** Puzzle object / ambient
- **Size:** 24×24 game units (18×18 px) each
- **Position:** (-40, 70), (40, 70) — near front
- **Shape:** Flat gear disc with 8 teeth
- **Colors:** #4A4A52 (gear), #6A6A78 (highlight), #2A2A30 (shadow), #E86020 (hot spots)
- **Pixel style:** Top-down, 2.5D — 3px thick disc
- **Detail:** 18×18 px. 8 teeth, each 3×4 px. Body: #4A4A52. Teeth highlights: 1px #6A6A78 on leading edges. Center hole: 4×4 px, #2A2A30. Some teeth have 1px #E86020 hot spots (puzzle state: heating). One gear blank is partially forged — 2 teeth are shorter, rough edges
- **Animation:** 
  - Heating: Hot spots spread — 1px #E86020 spreads from center to teeth over puzzle duration
  - Quench: When dropped in barrel, rapid steam burst (see barrel animation)

#### 11. Charcoal Bin
- **Type:** Floor furniture
- **Size:** 40×30 game units (29×22 px)
- **Position:** (-110, -60) — left back corner
- **Shape:** Open-top box with sloped heap inside
- **Colors:** #3A2E28 (bin), #4A4038 (highlight), #2A2018 (charcoal), #E86020 (ember dots)
- **Pixel style:** Top-down, 2.5D — heap rises 3px above bin rim
- **Detail:** 29×22 px bin, 2px walls #3A2E28. Heap: irregular 22×14 px mound, #2A2018 with 4–5 #E86020 ember specks (2px). Some charcoal pieces visible as 2–3 px darker #1E1810 chunks. Handle on side: 6×2 px, #6A6050
- **Animation:** Ember specks pulse — #E86020 ↔ #F0A040 over 2–4 seconds, random intervals

#### 12. Thermal Lens (Puzzle Object)
- **Type:** Puzzle interactable
- **Size:** 32×32 game units (24×24 px)
- **Position:** (0, -30) — in front of furnace
- **Shape:** Circular glass disc in brass mounting ring
- **Colors:** #80C0D0 (glass), #A0E0F0 (highlight), #60A0B0 (shadow), #C8A040 (brass ring), #E8D068 (ring highlight)
- **Pixel style:** Top-down, 2.5D — glass is flat, ring is 2px raised
- **Detail:** 24×24 px. Brass ring: 4px wide, #C8A040 with 1px #E8D068 highlight on outer edge. Glass: 16×16 px inner circle. Glass has 2px #A0E0F0 reflection crescent on top-left. Heat distortion: 1px wavy lines inside glass (#80C0D0 at 50%). Mounting screws: 4× 2×2 px, #E8D068, at 45° intervals on ring
- **Animation:** 
  - Heat expansion: When furnace heats, lens grows 1px in diameter over 3 seconds (thermal expansion puzzle mechanic)
  - Light focus: When aligned, thin 2×40 px #FFE8A0 beam shoots from lens toward target
  - Glow pulse: Ring #C8A040 brightens #E8D068 when lens is at correct temperature

#### 13. Slag Heap
- **Type:** Ambient object
- **Size:** 30×20 game units (22×15 px)
- **Position:** (110, -70) — right back corner
- **Shape:** Irregular mound of waste material
- **Colors:** #3A3028 (slag), #4A4038 (lighter), #2A2818 (dark), #E86020 (hot core)
- **Pixel style:** Top-down, 2.5D — mound rises 2px
- **Detail:** 22×15 px irregular blob. Surface has glassy #4A4038 patches (cooled slag) mixed with rough #3A3028 texture. One 4×3 px #E86020 hot spot at center — still cooling. Small 2px #6A6050 metal fragments embedded in slag
- **Animation:** Hot spot slowly cools — #E86020 → #C06020 → #A04020 → gone, over 30 seconds cycle, then reheats to #E86020 and repeats (perpetual forge waste)

---

## 8. Room 6 — The Beacon

**Floor shape:** Tall rectangle, 175×385 game units (base_size=175, w=0.5×, h=1.1×)  
**Floor color:** #3A3A4A (dark steel)  
**Wall color:** #505045 (tower stone)  
**Floor texture:** env_floor_beacon.png — dark steel with glowing yellow light strips, cylindrical pillars with warm lamps, riveted panels  
**Wall texture:** env_wall_steam.png — dark teal metal panels (reused for Beacon due to similar industrial feel)  
**Theme:** Height, illumination, vertical ascent, light crystal, warning systems

### Decoration Layout (12 objects)

#### 1. Central Shaft
- **Type:** Floor furniture / structural
- **Size:** 36×280 game units (26×206 px)
- **Position:** (0, 0) — vertical center, from y=-140 to y=110
- **Shape:** Tall vertical rectangular column with rounded corners
- **Colors:** #4A4A5A (body), #6A6A78 (highlight), #2E2E38 (shadow), #E8B830 (light strip)
- **Pixel style:** Top-down, 2.5D — strong vertical shading
- **Detail:** 26×206 px. Front face: 18px wide, #4A4A5A. Left/right faces: 4px each, #2E2E38. Highlight: 1px #6A6A78 on front-left edge. Two vertical light strips: 2×180 px each, #E8B830 at 60%, positioned on front face at ±6px from center. Rivets: 2×2 px, #8A8A90, spaced every 20px along both edges
- **Animation:** 
  - Light strips pulse: #E8B830 ↔ #F0D060 over 2 seconds (breathing light)
  - Sparkle: 1px #FFFFFF dots appear randomly on light strips, fade over 0.5 seconds

#### 2. Platform (×5)
- **Type:** Floor furniture / navigation
- **Size:** 100×16 game units each (74×12 px), varying width
- **Position:** y = -100, -60, -20, 20, 60 — at different heights
- **Shape:** Horizontal rectangular platform with gear-tooth edges
- **Colors:** #5A5A50 (platform), #6A6A60 (highlight), #4A4A40 (shadow), #E8B830 (safety edge)
- **Pixel style:** Top-down, 2.5D — platform is a "step" 4px above floor
- **Detail:** Width varies: 74px at y=-100, 80px at y=-60, 86px at y=-20, 92px at y=20, 98px at y=60 (wider at bottom). Platform top: #5A5A50, 74–98×8 px. Edge bevel: 2px #6A6A60 on front. Gear-tooth edges: alternating 3px indentations along sides, #4A4A40. Safety stripe: 1px #E8B830 along front edge. Railing: 1px #8A8A90 line along front edge, 2px above platform surface
- **Animation:** 
  - Ambient: Subtle 1px vertical vibration (machinery hum) every 4 seconds
  - Elevator: When player activates lift, platform moves vertically at 20px/sec to next level, 1px shadow trail during movement

#### 3. Light Crystal (Top)
- **Type:** Puzzle centerpiece / key object
- **Size:** 32×50 game units (24×37 px)
- **Position:** (0, -165) — at very top of shaft
- **Shape:** Tall pointed crystal prism with angled facets
- **Colors:** #E8E090 (crystal), #FFF8C0 (brightest facet), #C8B860 (shadow facet), #E8B830 (base mount), #F0D060 (glow)
- **Pixel style:** 2.5D with strong glow — crystal shows 3 visible facets plus intense light emission
- **Detail:** 24×37 px. Base mount: 16×6 px, #E8B830 with 2px #F0D060 highlight. Crystal body: 16×31 px, 3 visible facets — left #C8B860, right #E8E090, front #FFF8C0. Tip: 2×2 px, #FFFFFF. Core glow: 6×24 px inner strip, #FFFFFF at 80%, visible through front facet. Light beams: 3 thin 2×60 px lines radiating from crystal at -30°, 0°, +30°, #FFF8C0 at 30% opacity
- **Animation:** 
  - Core pulse: #FFFFFF ↔ #FFF8C0 over 1 second (heartbeat glow)
  - Beams: Opacity oscillates 30% ↔ 50% in sync with core, beam tips flicker
  - Sparkle: 1px #FFFFFF particles drift upward from crystal, fade over 1 second, spawn every 0.2 seconds
  - Rotation: When activated, crystal rotates slowly 360° over 10 seconds, beams sweep room

#### 4. Ladder Rungs (×16)
- **Type:** Floor furniture / navigation
- **Size:** 32×4 game units each (24×3 px)
- **Position:** Vertical range y=-130 to y=105, spaced 15 units apart
- **Shape:** Horizontal rung bars
- **Colors:** #6A6A6A (rung), #8A8A8A (highlight), #4A4A4A (shadow)
- **Pixel style:** Top-down, 2.5D — each rung is a 2px-thick bar
- **Detail:** 24×3 px. Center 18px: #6A6A6A. Left end: 3px #8A8A8A (highlight). Right end: 3px #4A4A4A (shadow). Mounting brackets: 2×3 px at both ends, #5A5A5A, attaching to shaft. Some rungs have 1px #E8B830 wear marks
- **Animation:** Static

#### 5. Light Beam (×3)
- **Type:** Ambient / puzzle element
- **Size:** 2×120 game units each (2×88 px)
- **Position:** Radiating from crystal at angles -30°, 0°, +30°
- **Shape:** Thin diagonal lines
- **Colors:** #FFF8C0 (beam core), #E8E090 (beam edge), #F0D060 (glow halo)
- **Pixel style:** Screen-space translucent beam
- **Detail:** 2px wide core line. 4px wide glow halo (#F0D060 at 15% opacity). Beams extend from crystal to walls. Where beam hits wall: 4×4 px #FFF8C0 splash spot with 6×6 px #F0D060 halo
- **Animation:** 
  - Sweep: Beams rotate with crystal when activated
  - Pulse: Core intensity 60% ↔ 90% over 2 seconds
  - Wall splash: Splash spots brighten when beam hits, 50% ↔ 80% over 0.5 seconds

#### 6. Warning Stripe (×4)
- **Type:** Wall detail
- **Size:** 32×6 game units (24×4 px) each
- **Position:** On shaft at y=-100, -40, 20, 80
- **Shape:** Diagonal striped band around shaft
- **Colors:** #E8B830 (yellow), #1E1E28 (black), #F0D060 (highlight)
- **Pixel style:** Top-down flat wrap-around
- **Detail:** 24×4 px band. 3 diagonal stripes, each 4px wide, alternating #E8B830 and #1E1E28. Stripes angle 45°. 1px #F0D060 highlight on top edge of yellow stripes
- **Animation:** Yellow stripes pulse: #E8B830 ↔ #F0D060 over 3 seconds (slow caution blink)

#### 7. Lamp Post (×4)
- **Type:** Floor furniture / ambient light source
- **Size:** 20×20 game units (15×15 px) each base, lamp extends 40 units tall
- **Position:** (-120, -120), (120, -120), (-120, 120), (120, 120) — corners
- **Shape:** Cylindrical post with dome lamp top
- **Colors:** #4A4A5A (post), #6A6A78 (highlight), #E8B830 (lamp dome), #F0D060 (lamp glow), #FFF8C0 (bright center)
- **Pixel style:** Top-down, 2.5D — post is 4px thick cylinder
- **Detail:** Base: 15×15 px octagonal foot, #4A4A5A. Post shaft: 6×6 px, #4A4A5A, extends 30px upward (only base visible in top-down). Lamp dome: 10×10 px circle on top, #E8B830 with 2px #FFF8C0 center. Light pool on floor: 30×30 px circle, #F0D060 at 15% opacity, centered on base
- **Animation:** 
  - Lamp flicker: Dome #E8B830 ↔ #F0D060 over 0.1–0.3 seconds (old industrial lamp flicker), occasional 0.5 second dim to #C8A830
  - Light pool: Opacity follows dome brightness 15% ↔ 25%

#### 8. Cable Spool (×2)
- **Type:** Ambient object
- **Size:** 24×24 game units (18×18 px) each
- **Position:** (-100, 60), (100, 60)
- **Shape:** Flat cylinder with coiled cable texture
- **Colors:** #5A5040 (wood spool), #4A4038 (shadow), #6A6050 (highlight), #E8B830 (cable — yellow power line)
- **Pixel style:** Top-down, 2.5D — spool is 4px thick
- **Detail:** 18×18 px. Outer rim: 2px #5A5040. Inner hub: 6×6 px, #4A4038. Coiled cable: spiral pattern of 1px #E8B830 lines, 2px spacing, filling between rim and hub. Loose cable end: 8×2 px, #E8B830, trailing from spool to floor
- **Animation:** Static

#### 9. Control Panel (Right Wall)
- **Type:** Wall detail / puzzle interactable
- **Size:** 40×30 game units (29×22 px)
- **Position:** (130, -20) — mounted on right wall
- **Shape:** Rectangular panel with buttons and lever
- **Colors:** #4A4A5A (panel), #6A6A78 (highlight), #E8B830 (buttons), #E86020 (warning button), #40D878 (go button)
- **Pixel style:** Top-down, 2.5D — panel inset 2px into wall
- **Detail:** 29×22 px. Bezel: 2px #6A6A78. Panel face: #4A4A5A. Three 4×4 px square buttons: top #E8B830 (UP), middle #E86020 (STOP), bottom #40D878 (DOWN). Small label text: 3×5 px pixel font, #8A8A90. Lever: 3×8 px, #C8A040, on right side of panel
- **Animation:** 
  - Button press: Button depresses 1px, color darkens 10%, springs back over 0.2 seconds
  - Lever: Rotates 30° when activated, #C8A040 → #E8D068 highlight on active side
  - Status light: Small 2×2 px LED above panel, #40D878 when lift operational, #E86020 when broken

#### 10. Safety Net (×2)
- **Type:** Floor furniture / safety
- **Size:** 80×8 game units (59×6 px) each
- **Position:** Below platforms at y=-75 and y=35
- **Shape:** Horizontal mesh strip
- **Colors:** #6A6A78 (net), #8A8A90 (highlight), #4A4A5A (shadow), #E8B830 (frame)
- **Pixel style:** Top-down flat
- **Detail:** 59×6 px. Frame: 1px #E8B830 border. Net: diagonal crosshatch pattern, 1px #6A6A78 lines, 3px grid. Some broken sections: 2–3 missing crosshatch squares, showing #2E2E38 floor through gap
- **Animation:** Subtle sway — net shifts 1px left-right, 3 second cycle (air movement from lift)

#### 11. Tool Belt (On Lower Platform)
- **Type:** Ambient object
- **Size:** 20×8 game units (15×6 px)
- **Position:** (-30, 65) — on lowest platform
- **Shape:** Curved belt with hanging tools
- **Colors:** #6A5030 (leather), #8A7A68 (highlight), #8A8A8A (metal tools)
- **Pixel style:** Top-down flat
- **Detail:** 15×6 px curved strip. Belt: #6A5030, 2px thick, slight curve. Tool 1: 3×2 px wrench, #8A8A8A, hanging below belt. Tool 2: 2×4 px screwdriver, #6A6050, hanging. Tool 3: 2×2 px bolt pouch, #6A5030, bulging
- **Animation:** Static

#### 12. Escape Hatch (Floor)
- **Type:** Floor furniture / potential shortcut
- **Size:** 40×40 game units (29×29 px)
- **Position:** (0, 100) — at very bottom/front
- **Shape:** Square hatch with 4 bolts and pull ring
- **Colors:** #4A4A5A (hatch), #6A6A78 (highlight), #2E2E38 (shadow), #E86020 (warning border)
- **Pixel style:** Top-down, 2.5D — hatch is 2px thick, slightly recessed
- **Detail:** 29×29 px square with 2px rounded corners. Border: 2px #E86020 (warning). Surface: #4A4A5A with 2px X-brace pattern, #3A3A42. 4 bolts: 2×2 px, #8A8A90, at corners. Center pull ring: 4×4 px circle, #C8A040, with 2×6 px handle, #6A6A78. Stencil text "EMERGENCY" in 1px #E86020 (illegible at game scale, just color dots)
- **Animation:** 
  - Subtle vibration: 1px jitter every 5 seconds
  - Open state: Hatch rotates 20°, reveals dark #1E1E28 pit below with 1px #E8B830 distant light at bottom

---

## 9. Room 7 — The Escapement

**Floor shape:** Octagon, radius 175 game units  
**Floor color:** #3A3A42 (dark grey)  
**Wall color:** #554A35 (brass)  
**Floor texture:** env_floor_escapement.png — dark grey with ornate brass/gold clockwork center piece, gear motif, stone brick borders, gold accents  
**Wall texture:** env_wall_brass.png — dark blue-black with ornate gold/brass decorative borders and circular motifs  
**Theme:** Timekeeping, clockwork, pendulum, gear teeth, precision, regulation

### Decoration Layout (13 objects)

#### 1. Central Escapement Wheel
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 110×110 game units (81×81 px)
- **Position:** Center (0, 0)
- **Shape:** 12-pointed gear wheel with alternating deep/shallow teeth
- **Colors:** #A08840 (brass body), #C8A040 (highlight), #8A6A30 (shadow), #E8D068 (bright edge), #5A4A30 (dark tooth valley)
- **Pixel style:** Top-down, 2.5D — wheel is 4px thick, teeth project 3px above body
- **Detail:** 81px diameter. 12 teeth alternating: 6 long teeth (8px deep, #A08840 with #C8A040 top edge) and 6 short teeth (5px deep, #8A6A30). Tooth valleys: #5A4A30. Central axle: 12×12 px octagon, #E8D068 with 4×4 px #FFF8C0 bolt head. Inner ring: 50px diameter, 3px thick, #C8A040 with 8 small 2×2 px #E8D068 decorative studs. Spokes: 6 thin 2px lines radiating from center to inner ring, #8A6A30
- **Animation:** 
  - Idle: Slow rotation 6°/second (clock tick rate)
  - Puzzle active: Faster rotation 30°/second, then stops for "tick" moment
  - Tick: When tooth engages, 1px #E8D068 flash at contact point, 0.1 second

#### 2. Tick Marks (×12)
- **Type:** Ambient detail / puzzle reference
- **Size:** Each mark: 12×3 game units (9×2 px)
- **Position:** Around wheel at 30° intervals, radius 120 from center
- **Shape:** Short radial lines pointing inward
- **Colors:** #C8A040 (marks), #E8D068 (major marks), #8A6A30 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 9×2 px lines. Every 3rd mark (90° intervals) is longer: 12×3 px, #E8D068 with 1px dot at outer end. Other marks: 9×2 px, #C8A040. All marks point toward center
- **Animation:** 
  - Major marks glow when wheel tooth approaches: #E8D068 → #FFF8C0 over 0.3 seconds as tooth passes, then fade

#### 3. Pendulum Anchor (Top)
- **Type:** Floor furniture / puzzle element
- **Size:** 16×40 game units (12×29 px)
- **Position:** (0, -110) — above wheel
- **Shape:** Vertical anchor with forked end
- **Colors:** #6A6A6A (anchor), #8A8A8A (highlight), #4A4A4A (shadow), #E8D068 (brass tip)
- **Pixel style:** Top-down, 2.5D — anchor seen from top as thin vertical bar
- **Detail:** 12×29 px. Shaft: 6×20 px, #6A6A6A with 1px #8A8A8A highlight. Fork at bottom: 12×9 px, two prongs 4px apart, #4A4A4A with #E8D068 tips. Top mount: 8×4 px, #5A5A5A, with 2×2 px #8A8A8A bolt
- **Animation:** 
  - Swings with pendulum: Anchor shifts ±4px horizontally, 1.5 second cycle (pendulum period)
  - Engagement: When fork catches wheel tooth, 1px #E8D068 flash at contact, wheel rotation pauses 0.2 seconds

#### 4. Pendulum Rod
- **Type:** Floor furniture / visual connector
- **Size:** 6×155 game units (4×114 px)
- **Position:** (0, -70) to (0, 85) — vertical line from anchor to bob
- **Shape:** Thin vertical rod
- **Colors:** #6A6A6A (rod), #8A8A8A (highlight), #4A4A4A (shadow)
- **Pixel style:** Top-down, 2.5D — rod is 2px thick cylinder
- **Detail:** 4×114 px. Center 2px: #6A6A6A. Left edge: 1px #8A8A8A highlight. Right edge: 1px #4A4A4A shadow. Mounting collar at top: 6×4 px, #5A5A5A, with 2×2 px bolt
- **Animation:** 
  - Swings with pendulum: Rod pivots from top, bottom swings ±8px horizontally, 1.5 second cycle
  - Motion blur: During swing, 1px ghost rod at 30% opacity trails behind

#### 5. Pendulum Bob
- **Type:** Floor furniture / weight
- **Size:** 36×36 game units (26×26 px)
- **Position:** (0, 90) — bottom of pendulum
- **Shape:** Heavy circular disc with decorative rim
- **Colors:** #8A8A80 (bob), #A0A090 (highlight), #6A6A60 (shadow), #C8A040 (brass rim), #E8D068 (rim highlight)
- **Pixel style:** Top-down, 2.5D — bob is 5px thick disc
- **Detail:** 26×26 px. Outer rim: 3px #C8A040 with 1px #E8D068 highlight. Body: 20×20 px, #8A8A80. Center cap: 8×8 px, #6A6A60 with 2×2 px #E8D068 bolt. Decorative ring: 14px diameter, 1px #A0A090 line, with 4 small 2×2 px #C8A040 studs. Bottom weight indicator: 2×4 px, #E86020, showing mass level
- **Animation:** 
  - Swings with rod: Bob traces arc ±8px horizontally, 1.5 second cycle
  - Secondary oscillation: Bob rotates ±5° around its own center during swing (physics detail)
  - Weight shift: When puzzle adjusted, #E86020 indicator moves to new position over 2 seconds

#### 6. Gear Teeth (Outer Ring)
- **Type:** Ambient detail
- **Size:** 24 teeth, each 10×8 game units (7×6 px)
- **Position:** Around wheel at 15° intervals, radius 116 from center
- **Shape:** Small triangular teeth pointing inward
- **Colors:** #8A6A40 (teeth), #A08840 (highlight), #6A5030 (shadow)
- **Pixel style:** Top-down, 2.5D — teeth are 2px high projections
- **Detail:** 7×6 px each. Triangle shape: 3px wide at base, 7px long. Top surface: #A08840 with 1px #C8A040 highlight. Side: #6A5030 shadow. These are fixed outer ring teeth that engage with the rotating wheel
- **Animation:** 
  - Contact flash: When wheel tooth passes, engaged tooth flashes #E8D068 for 0.1 second
  - Static otherwise

#### 7. Clock Numbers (×4)
- **Type:** Wall detail / thematic
- **Size:** 10×10 game units (7×7 px) each
- **Position:** At 90° intervals around wheel, radius 156: (0, -156), (156, 0), (0, 156), (-156, 0)
- **Shape:** Small square plaques with Roman numeral-like marks
- **Colors:** #C8A040 (plaque), #E8D068 (numeral), #8A6A30 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 7×7 px square. Background: #C8A040. Center symbol: 3×5 px pixel font — I (one vertical line), X (cross), II (two lines), IX (abstract dots at this scale). Border: 1px #E8D068
- **Animation:** 
  - Roman numeral "I" at 12 o'clock glows brighter when pendulum is in correct position: #E8D068 → #FFF8C0 over 0.5 seconds

#### 8. Mainspring Barrel (×2)
- **Type:** Floor furniture / power source
- **Size:** 30×30 game units (22×22 px) each
- **Position:** (-120, 80), (120, 80) — lower corners
- **Shape:** Circular barrel with spiral lid pattern
- **Colors:** #6A6A60 (barrel), #8A8A80 (highlight), #4A4A40 (shadow), #C8A040 (winding keyhole)
- **Pixel style:** Top-down, 2.5D — barrel 3px thick
- **Detail:** 22×22 px. Body: 18px diameter circle, #6A6A60. Spiral pattern on lid: 1px #4A4A40 line spiraling from center to edge, 2px spacing. Winding keyhole: 4×4 px, #2A2A20 center with #C8A040 rim. Side: 2px #4A4A40 shadow band
- **Animation:** 
  - Spring unwinding: Spiral pattern rotates slowly 2°/second (perpetual clock winding down)
  - Keyhole glow: #C8A040 pulses #E8D068 over 3 seconds

#### 9. Jeweled Bearing (×4)
- **Type:** Ambient detail / precision motif
- **Size:** 8×8 game units (6×6 px) each
- **Position:** At axle points: center of wheel, top of pendulum anchor, and two on back wall
- **Shape:** Small circular jewel inset
- **Colors:** #A04080 (ruby jewel), #C060A0 (highlight), #802060 (shadow), #C8A040 (gold setting)
- **Pixel style:** Top-down, 2.5D — jewel is a 1px dome
- **Detail:** 6×6 px. Gold setting: 1px #C8A040 ring. Jewel: 4×4 px, #A04080 with 1px #C060A0 highlight. Some have 1px #E8D068 reflection dot
- **Animation:** 
  - Ruby glow: #A04080 pulses #C060A0 over 2 seconds (internal clock light)
  - Reflection: 1px #E8D068 dot shifts 1px as if light source moves

#### 10. Regulation Screw (×2)
- **Type:** Puzzle interactable
- **Size:** 12×12 game units (9×9 px) each
- **Position:** (-60, -100), (60, -100) — near top
- **Shape:** Small screw head with slot
- **Colors:** #C8A040 (head), #E8D068 (highlight), #8A6A30 (shadow), #2A2A20 (slot)
- **Pixel style:** Top-down, 2.5D — screw head is 2px thick hexagon
- **Detail:** 9×9 px hexagonal head. Top: #C8A040 with 1px #E8D068 highlight on top-left. Slot: 4×1 px, #2A2A20, diagonal. Washer: 11×11 px ring, #8A6A30, visible around head
- **Animation:** 
  - Idle: Static
  - Adjusted: Slot rotates in 45° increments, 0.3 second turn animation. Each turn changes pendulum swing speed slightly
  - Correct: Screw head glows #E8D068 aura (11×11 px halo, 25% opacity)

#### 11. Chain Drive (×1)
- **Type:** Floor furniture / power transmission
- **Size:** 160×8 game units (118×6 px)
- **Position:** Arc from (-80, 120) to (80, 120), curving around bottom
- **Shape:** Curved chain with visible links
- **Colors:** #6A6A60 (chain), #8A8A80 (link highlights), #4A4A40 (shadow), #C8A040 (connectors)
- **Pixel style:** Top-down flat
- **Detail:** 118×6 px curved line. Chain links: 3×2 px alternating pattern — horizontal bar (#6A6A60), vertical connector (#4A4A40), repeated every 4px. 4 connector studs: 2×2 px, #C8A040, at quarter points along chain
- **Animation:** 
  - Chain moves: Links shift 2px along curve, 4 second cycle (power transmission motion)
  - Stud flash: Each connector stud flashes #E8D068 briefly as chain link passes

#### 12. Escapement Palette (×2)
- **Type:** Puzzle detail / mechanism
- **Size:** 12×8 game units (9×6 px) each
- **Position:** On pendulum anchor fork prongs
- **Shape:** Small semicircular pads on fork tips
- **Colors:** #8A8A80 (palette), #A0A090 (highlight), #6A6A60 (shadow), #E8D068 (tooth contact face)
- **Pixel style:** Top-down, 2.5D — 1px thick pads
- **Detail:** 9×6 px. Curved face: #E8D068 (where wheel tooth contacts). Body: #8A8A80. Back: #6A6A60 shadow. When wheel tooth engages, contact face shows 2px #FFF8C0 flash
- **Animation:** 
  - Contact flash: #E8D068 → #FFF8C0 over 0.1 seconds when tooth hits, then fade
  - Wear marks: After many ticks, 1px #6A6A60 wear line appears on contact face (progressive, subtle)

#### 13. Timepiece Dial (Back Wall)
- **Type:** Wall detail / thematic centerpiece
- **Size:** 100×20 game units (74×15 px)
- **Position:** (0, -130) — back wall
- **Shape:** Wide rectangular clock face
- **Colors:** #3A3A42 (face), #C8A040 (rim), #E8D068 (ticks), #E86020 (hour hand), #8A8A90 (minute hand)
- **Pixel style:** Top-down flat
- **Detail:** 74×15 px. Rim: 2px #C8A040. Face: #3A3A42 with 12 small 1×2 px #E8D068 tick marks. No numerals (abstract). Center pivot: 3×3 px, #C8A040. Hands: hour 1×8 px #E86020 pointing to 3 o'clock, minute 1×12 px #8A8A90 pointing to 12. Small 2×2 px #E8D068 gear icon at center
- **Animation:** 
  - Hands move: Real-time clock hands, minute hand advances 1 tick every 2 seconds (compressed time)
  - Puzzle solved: Both hands align at 12 o'clock, flash #FFF8C0, then spin 360° celebration over 1 second

---

## 10. Room 8 — The Bearing

**Floor shape:** Circle (16-sided), radius 175 game units  
**Floor color:** #3A3A42 (dark grey)  
**Wall color:** #555555 (silver)  
**Floor texture:** env_floor_bearing.png — dark grey tiles in 4×4 grid with silver-grey metal frame, clean industrial, grime spots  
**Wall texture:** env_wall_oil.png — dark purple-brown with oil-slick panels and bolt heads  
**Theme:** Friction reduction, smooth motion, ball bearings, lubrication, precision rotation

### Decoration Layout (11 objects)

#### 1. Outer Bearing Ring
- **Type:** Floor furniture / structural
- **Size:** 190×190 game units (140×140 px outer diameter), ring width 12 units (9 px)
- **Position:** Centered, radius 95 from center
- **Shape:** 32-sided circular ring
- **Colors:** #6A6A6A (ring), #8A8A8A (highlight), #4A4A4A (shadow), #A0A0A0 (polished face)
- **Pixel style:** Top-down, 2.5D — ring is 4px thick cylinder wall
- **Detail:** 140px outer diameter, 122px inner diameter. Outer edge: 2px #8A8A8A highlight. Body: #6A6A6A. Inner edge: 2px #4A4A4A shadow. Surface: #A0A0A0 with 8 small 2×2 px #C0C0C0 bolt heads evenly spaced. One section has 1px #E86020 rust spot (age)
- **Animation:** 
  - Subtle vibration: Ring oscillates 1px radius ±0.5px, 5 second cycle (machinery hum)
  - Rust spread: #E86020 spot grows 1px every 10 seconds, then resets (aberration hint)

#### 2. Inner Bearing Ring (Bearing Race)
- **Type:** Floor furniture / structural
- **Size:** 130×130 game units (96×96 px outer diameter), ring width 8 units (6 px)
- **Position:** Centered, radius 65 from center
- **Shape:** 32-sided circular ring
- **Colors:** #7A7A7A (ring), #9A9A9A (highlight), #5A5A5A (shadow), #B0B0B0 (polished face)
- **Pixel style:** Top-down, 2.5D — ring is 3px thick
- **Detail:** 96px outer diameter, 84px inner diameter. Outer edge: 1px #9A9A9A. Body: #7A7A7A. Inner edge: 1px #5A5A5A. Surface: #B0B0B0 with 6 small 2×2 px #D0D0D0 lubrication ports evenly spaced. These ports have 1px #8A7A68 oil stain around them
- **Animation:** 
  - Rotation: Inner ring rotates slowly 3°/second when bearing is "active"
  - Lubrication: Oil spreads — 1px #8A7A68 ring around ports expands 2px, contracts, 4 second cycle

#### 3. Ball Bearing (×8)
- **Type:** Floor furniture / puzzle elements
- **Size:** 14×14 game units (10×10 px) each
- **Position:** In bearing track at 45° intervals, radius 80 from center
- **Shape:** Perfect sphere seen from top as circle
- **Colors:** #A0A0A0 (ball), #C0C0C0 (highlight), #808080 (shadow), #D0D0D0 (reflection)
- **Pixel style:** Top-down, 2.5D — spheres appear as 3px tall domes
- **Detail:** 10×10 px. Highlight crescent: 3×4 px, #D0D0D0, top-left. Body: #A0A0A0. Shadow crescent: 3×4 px, #808080, bottom-right. Anti-friction groove: 1px #B0B0B0 ring around equator
- **Animation:** 
  - Orbit: Balls move in circular track at 10px/second when bearing active, spaced evenly
  - Individual spin: Each ball rotates in place — highlight crescent shifts 45° every 0.5 seconds
  - Lubricated: When oil applied (puzzle), balls gain 1px #8A7A68 oil sheen overlay, move 50% faster

#### 4. Central Pivot
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 44×44 game units (32×32 px)
- **Position:** Center (0, 0)
- **Shape:** Octagonal hub with central hole
- **Colors:** #5A5A5A (hub), #7A7A7A (highlight), #3A3A3A (shadow), #E8D068 (brass center cap)
- **Pixel style:** Top-down, 2.5D — hub is 5px thick
- **Detail:** 32×32 px. 8 sides, each 12px long. Edge: 2px #7A7A7A highlight. Body: #5A5A5A. Central hole: 12×12 px, #2A2A2A (dark pit). Center cap: 8×8 px octagon, #E8D068, sits in hole. 4 mounting bolts: 2×2 px, #C0C0C0, at 45° intervals. Grease fitting: 3×3 px, #C8A040, on one face
- **Animation:** 
  - Hub rotation: When bearing active, hub rotates 5°/second (drives inner ring)
  - Cap flash: #E8D068 pulses #FFF8C0 over 2 seconds
  - Grease squeeze: When lubricated, 1px #8A7A68 grease bead appears at fitting, spreads on surface

#### 5. Pivot Pin
- **Type:** Ambient detail
- **Size:** 18×18 game units (13×13 px)
- **Position:** Centered in hub hole
- **Shape:** Small hexagonal pin protruding from center cap
- **Colors:** #4A4A4A (pin), #6A6A6A (highlight), #2A2A2A (shadow), #C0C0C0 (top face)
- **Pixel style:** Top-down, 2.5D — pin is 4px tall
- **Detail:** 13×13 px hexagon. Top face: 8×8 px, #C0C0C0. Sides: 2px, #4A4A4A with 1px #6A6A6A highlight. Center dimple: 2×2 px, #2A2A2A. Machining marks: 1px #808080 spiral scratch on top face
- **Animation:** 
  - Spin: When hub rotates, pin rotates with it, machining marks create moiré effect
  - Heat: During friction puzzle (unlubricated), pin top gains 1px #E86020 heat glow overlay at 30%, growing to 60% over time

#### 6. Lubrication Channel (×4)
- **Type:** Floor furniture / puzzle element
- **Size:** Each channel: 8×60 game units (6×44 px)
- **Position:** Radial from center at 45° intervals, from radius 28 to radius 58
- **Shape:** Narrow grooves radiating from pivot
- **Colors:** #3A3A3A (channel), #2A2A2A (deep groove), #8A7A68 (oil when filled), #6A6050 (dry)
- **Pixel style:** Top-down, 2.5D — channels are 2px deep grooves
- **Detail:** 6×44 px. Channel width: 4px. Floor: #3A3A3A. Groove: 2px #2A2A2A (recessed). When dry: groove has 1px #6A6050 dust/rust. When lubricated: groove fills with 2px #8A7A68 oil, slight 1px #A09080 highlight on surface
- **Animation:** 
  - Oil flow: When oil can applied, oil spreads from center outward along channel at 5px/second, 1px leading edge brighter #A09080
  - Dry up: Oil slowly recedes 1px every 5 seconds if not maintained

#### 7. Wear Mark / Scratch (×5)
- **Type:** Ambient detail / puzzle indicator
- **Size:** 10×3 to 16×4 game units (7×2 to 12×3 px) each
- **Position:** Random in bearing track: radius 70–90 at various angles
- **Shape:** Thin curved lines (arc segments)
- **Colors:** #808080 (scratch), #A0A0A0 (fresh scratch), #6A6A6A (old scratch)
- **Pixel style:** Top-down flat
- **Detail:** 7×2 to 12×3 px. Curved to match bearing track arc. Fresh scratches: 1px #A0A0A0, bright. Old scratches: 1px #6A6A6A, faint. Some scratches have 1px #E86020 heat discoloration at one end (friction point)
- **Animation:** 
  - Fresh scratches appear: When bearing runs unlubricated, new 1px #A0A0A0 scratches spawn every 3 seconds, fade to #808080 over 5 seconds, then to #6A6A6A
  - Heat discoloration: #E86020 at scratch end pulses when friction high

#### 8. Oil Can (Puzzle Tool)
- **Type:** Puzzle interactable
- **Size:** 16×12 game units (12×9 px)
- **Position:** (120, 0) — on right side, near wall
- **Shape:** Small cylindrical can with long spout
- **Colors:** #C8A040 (can), #E8D068 (highlight), #8A6A30 (shadow), #6A6050 (spout), #8A7A68 (oil)
- **Pixel style:** Top-down, 2.5D — can 3px tall
- **Detail:** 12×9 px oval. Body: #C8A040 with 1px #E8D068 highlight. Spout: 6×2 px, #6A6050, extends diagonally. Cap: 4×3 px, #8A6A30. Oil drop forming at spout tip: 1–2 px, #8A7A68, grows over 2 seconds
- **Animation:** 
  - Oil drop: 1px → 2px over 2 seconds, falls 8px, leaves 2px #8A7A68 spot on floor
  - Can tilt: When player uses, can tilts 15°, oil streams from spout as 2×8 px #8A7A68 line
  - Empty indicator: When oil depleted, can color shifts #C8A040 → #A08840 (dull)

#### 9. Friction Gauge (×1)
- **Type:** Wall detail / puzzle indicator
- **Size:** 30×30 game units (22×22 px)
- **Position:** (-120, -80) — left wall
- **Shape:** Circular dial showing friction level
- **Colors:** #4A4A4A (face), #6A6A6A (rim), #E86020 (needle — high friction), #40D878 (needle — low friction), #E8C040 (mid), #C0C0C0 (ticks)
- **Pixel style:** Top-down flat
- **Detail:** 22×22 px. Rim: 2px #6A6A6A. Face: #4A4A4A. Ticks: 8 small 1px lines, #C0C0C0. Zones: red (high friction) 0–90°, yellow 90–180°, green 180–270°. Needle: 1×10 px, color changes #E86020→#E8C040→#40D878 based on friction. Center: 3×3 px, #C0C0C0
- **Animation:** 
  - Real-time: Needle follows bearing friction state, moves ±2° per second
  - Alarm: When in red zone, rim flashes #E86020 at 1Hz
  - Settled: When in green zone, small #40D878 dot appears at center

#### 10. Bearing Cage Fragment (×1)
- **Type:** Ambient object / lore
- **Size:** 20×16 game units (15×12 px)
- **Position:** (100, 80) — near wall
- **Shape:** Broken semicircular cage piece
- **Colors:** #6A6A6A (cage), #8A8A8A (highlight), #4A4A4A (broken edge), #E86020 (friction heat at break)
- **Pixel style:** Top-down, 2.5D — 2px thick
- **Detail:** 15×12 px. Curved frame: 2px #6A6A6A. Lattice pattern: 1px #8A8A8A crosshatch inside frame. Broken edge: jagged 1px #4A4A4A with 2px #E86020 heat discoloration. One ball still trapped in fragment: 4×4 px, #A0A0A0
- **Animation:** 
  - Trapped ball: Ball rolls back and forth within cage fragment, 2px movement, 1 second cycle
  - Heat glow: #E86020 at broken edge pulses 40% ↔ 60% over 2 seconds

#### 11. Shim Stock (×3)
- **Type:** Ambient object / precision detail
- **Size:** 12×4 game units (9×3 px) each
- **Position:** (-80, 60), (-70, 65), (80, -50)
- **Shape:** Thin rectangular metal strips
- **Colors:** #B0B0B0 (shim), #D0D0D0 (highlight), #909090 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 9×3 px. Very thin: 1px #B0B0B0 body with 1px #D0D0D0 top edge (paper-thin metal). Some curled at ends: 2px corner lifts 1px. One shim has 1px #8A7A68 oil stain
- **Animation:** Static

---

## 11. Room 9 — The Flywheel

**Floor shape:** Circle (16-sided), radius 184 game units (base_size=175 × 1.05)  
**Floor color:** #3A3048 (purple-grey)  
**Wall color:** #505050 (iron)  
**Floor texture:** env_floor_flywheel.png — dark purple-grey tiles, copper/orange frame, grid pattern, diagonal wear marks, brick border  
**Wall texture:** env_wall_iron.png — dark grey with molten spot accents  
**Theme:** Momentum, stored energy, spinning, kinetic force, rotational inertia

### Decoration Layout (12 objects)

#### 1. Outer Track
- **Type:** Floor furniture / structural
- **Size:** 210×210 game units (155×155 px outer diameter), track width 16 units (12 px)
- **Position:** Centered, radius 105 from center
- **Shape:** 48-sided circular track
- **Colors:** #4A4A4A (track), #6A6A6A (highlight), #2E2E2E (shadow), #E86020 (heat spots)
- **Pixel style:** Top-down, 2.5D — track is 6px thick cylinder wall
- **Detail:** 155px outer diameter. Outer edge: 2px #6A6A6A. Body: 8px #4A4A4A. Inner edge: 2px #2E2E2E. Track surface: #5A5A5A with 12 small 2×2 px #808080 wear dimples (evenly spaced). Heat spots: 3×3 px #E86020 at 20% opacity, 4 spots from friction
- **Animation:** 
  - Subtle pulse: Track thickness oscillates ±1px, 4 second cycle (stored energy vibration)
  - Heat spots: #E86020 opacity pulses 20% ↔ 40% over 3 seconds

#### 2. Inner Track
- **Type:** Floor furniture / structural
- **Size:** 164×164 game units (121×121 px outer diameter), track width 8 units (6 px)
- **Position:** Centered, radius 82 from center
- **Shape:** 48-sided circular track
- **Colors:** #5A5A5A (track), #7A7A7A (highlight), #3A3A3A (shadow)
- **Pixel style:** Top-down, 2.5D — track is 4px thick
- **Detail:** 121px outer diameter. Outer edge: 1px #7A7A7A. Body: 4px #5A5A5A. Inner edge: 1px #3A3A3A. Track surface: #6A6A6A. Small 1×2 px #808080 lubrication marks along inner surface
- **Animation:** 
  - Rotation: When flywheel active, inner track rotates at variable speed (0–60°/second based on puzzle momentum)
  - Speed lines: At high speed, 2px #808080 motion blur lines appear tangent to track

#### 3. Central Hub
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 56×56 game units (41×41 px)
- **Position:** Center (0, 0)
- **Shape:** Octagonal hub with central axle hole
- **Colors:** #5A5A50 (hub), #7A7A68 (highlight), #3A3A30 (shadow), #B87040 (copper accent), #E8C040 (gold center)
- **Pixel style:** Top-down, 2.5D — hub is 6px thick
- **Detail:** 41×41 px. 8 sides, each 16px long. Edge: 2px #7A7A68 highlight. Body: #5A5A50. Copper accent ring: 30px diameter, 2px thick, #B87040. Central axle: 16×16 px, #3A3A30 (dark hole). Axle cap: 10×10 px octagon, #E8C040 with 2×2 px #FFF8C0 bolt. 4 mounting plates: 6×6 px, #6A6A60, at 45° intervals
- **Animation:** 
  - Hub spin: Rotates with flywheel, 0–60°/second
  - Axle cap flash: #E8C040 → #FFF8C0 over 1 second when at maximum speed
  - Copper ring: #B87040 brightens #D89050 at high speed (friction heat)

#### 4. Spoke (×6)
- **Type:** Floor furniture / structural
- **Size:** Each spoke: 8×96 game units (6×71 px)
- **Position:** Radiating from center at 60° intervals, from radius 32 to radius 78
- **Shape:** Tapered rectangular bars
- **Colors:** #6A6A60 (spoke), #8A8A80 (highlight), #4A4A40 (shadow), #B87040 (copper collar at hub)
- **Pixel style:** Top-down, 2.5D — spokes are 4px thick beams
- **Detail:** 6×71 px. Hub end: 6px wide with 8×8 px #B87040 copper collar. Tapers to 4px wide at track end. Body: #6A6A60. Highlight: 1px #8A8A80 on leading edge (determined by rotation direction). Shadow: 1px #4A4A40 on trailing edge. Track connection: 4×6 px flange, #5A5A50, with 2×2 px bolt
- **Animation:** 
  - Rotate with hub: All spokes rotate at flywheel speed
  - Flex: At high speed, spokes bend outward 1–2px (centrifugal force, subtle)
  - Stress marks: At extreme speed, 1px #E86020 stress line appears on spoke surface

#### 5. Weight Indicator (×8)
- **Type:** Floor furniture / puzzle element
- **Size:** 10×10 game units (7×7 px) each
- **Position:** On outer track at 45° intervals
- **Shape:** Small square masses
- **Colors:** #8A8A80 (weight), #A0A090 (highlight), #6A6A60 (shadow), #E86020 (hot when moving fast)
- **Pixel style:** Top-down, 2.5D — 3px thick blocks
- **Detail:** 7×7 px. Body: #8A8A80. Highlight: 1px #A0A090 on top-left. Shadow: 1px #6A6A60 on bottom-right. Mounting bolt: 2×2 px, #C0C0C0, at center. Number stamp: 1px dots suggesting "1"–"8", #4A4A40
- **Animation:** 
  - Orbit: Weights move with outer track rotation
  - Heat: When flywheel at high speed, weights glow #E86020 at 10–30% opacity (kinetic heating)
  - Adjust: During puzzle, one weight can be removed — lifts 4px and fades out over 0.5 seconds

#### 6. Motion Blur Arc (×3)
- **Type:** Ambient overlay
- **Size:** Each arc: 220×220 game units (162×162 px) at outer edge
- **Position:** At outer track, 3 overlapping arc segments
- **Shape:** Curved translucent arcs following track
- **Colors:** #6A6A6A at 15% opacity, #8A8A8A at 10%
- **Pixel style:** Screen-space translucent overlay
- **Detail:** 3 arcs, each covering ~90° of track. 4px wide. Arc 1: 0–90°. Arc 2: 120–210°. Arc 3: 240–330°. Overlapping creates denser blur at some sections
- **Animation:** 
  - Speed dependent: Opacity increases with flywheel speed: 0% at rest → 30% at max speed
  - Rotation: Arcs rotate with flywheel, creating continuous motion blur ring at high speed

#### 7. Axle Cap
- **Type:** Ambient detail
- **Size:** 20×20 game units (15×15 px)
- **Position:** Center of hub axle
- **Shape:** Small hexagonal cap
- **Colors:** #6A6A6A (cap), #8A8A8A (highlight), #4A4A4A (shadow), #E8C040 (gold pin)
- **Pixel style:** Top-down, 2.5D — cap is 3px tall
- **Detail:** 15×15 px hexagon. Top face: 10×10 px, #6A6A6A. Sides: 2px, #4A4A4A with 1px #8A8A8A highlight. Center gold pin: 3×3 px, #E8C040 with 1px #FFF8C0 highlight. 6 small 1×1 px #C0C0C0 screws around edge
- **Animation:** 
  - Spin: Rotates with hub
  - Pin glow: #E8C040 → #FFF8C0 when flywheel at max speed

#### 8. Brake Pad (×2)
- **Type:** Floor furniture / puzzle element
- **Size:** 16×24 game units (12×18 px) each
- **Position:** (-100, 0), (100, 0) — left and right of track
- **Shape:** Curved pads matching track outer edge
- **Colors:** #4A4038 (pad), #6A6050 (highlight), #2E2818 (shadow), #E86020 (heat when engaged)
- **Pixel style:** Top-down, 2.5D — pads are 3px thick
- **Detail:** 12×18 px. Curved to match 30° arc of outer track. Body: #4A4038. Wear surface: 1px #6A6050 line along track-contact edge. Mounting bracket: 4×4 px, #5A5A5A, with 2×2 px bolt. When engaged: pad presses against track, 1px #E86020 heat glow appears at contact line
- **Animation:** 
  - Engage: Pad moves 2px toward track over 0.3 seconds, heat glow appears
  - Friction: When engaged during spin, pad vibrates 1px, heat glow intensifies #E86020 20%→50%
  - Release: Springs back 2px, heat glow fades over 2 seconds

#### 9. Momentum Arrow Display
- **Type:** Wall detail / puzzle indicator
- **Size:** 50×20 game units (37×15 px)
- **Position:** (0, -140) — back wall
- **Shape:** Horizontal bar with arrow
- **Colors:** #4A4A4A (bar), #E8C040 (arrow), #40D878 (green zone), #E86020 (red zone)
- **Pixel style:** Top-down flat
- **Detail:** 37×15 px. Background bar: #4A4A4A, 37×6 px. Arrow indicator: 6×8 px triangle, #E8C040, slides along bar. Green zone: left 12px, #40D878 at 20% overlay. Red zone: right 12px, #E86020 at 20% overlay. Target zone marker: 2px vertical #FFF8C0 line at center
- **Animation:** 
  - Arrow slides: Follows flywheel momentum, moves left→right as speed increases, 2px/second at base rate
  - In zone: When arrow in green zone, bar glows #40D878 at 30%. In red zone, flashes #E86020 at 1Hz
  - Settle: When at target, arrow pulses #E8C040 → #FFF8C0 and locks

#### 10. Debris Field (×6)
- **Type:** Ambient object
- **Size:** 4×4 to 8×6 game units (3×3 to 6×4 px) each
- **Position:** Scattered outside outer track: (-130, -40), (140, 50), (-120, 90), (110, -80), (-150, 20), (160, -30)
- **Shape:** Small irregular metal fragments
- **Colors:** #5A5A5A (debris), #7A7A7A (highlight), #3A3A3A (shadow), #E86020 (sharp edge)
- **Pixel style:** Top-down flat
- **Detail:** 3×3 to 6×4 px irregular shapes. Some triangular, some rectangular. One larger fragment (6×4 px) has a 2px #B87040 copper inlay. Sharp edges have 1px #E86020 (dangerous, from shearing)
- **Animation:** Static

#### 11. Spin Indicator (Floor)
- **Type:** Ambient detail
- **Size:** 60×12 game units (44×9 px)
- **Position:** (0, 130) — front of room
- **Shape:** Curved arrow showing spin direction
- **Colors:** #6A6A60 (arrow), #E8C040 (highlight), #4A4A40 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 44×9 px curved arrow, following arc of outer track. Arrow head: 8×6 px, #6A6A60. Body: 36×3 px curve, #4A4A40 with 1px #E8C040 leading edge. Spin direction: clockwise (rightward arrow head)
- **Animation:** 
  - When flywheel spins, arrow "flows" — 1px highlight moves along arrow body at speed matching flywheel, 2 second cycle
  - Reverse: If flywheel reverses, arrow flips direction over 0.5 seconds

#### 12. Kinetic Storage Gauge
- **Type:** Wall detail
- **Size:** 24×60 game units (18×44 px)
- **Position:** (-140, -60) — left wall
- **Shape:** Vertical bar gauge
- **Colors:** #4A4A4A (housing), #6A6A6A (frame), #E8C040 (fill), #E86020 (overload warning)
- **Pixel style:** Top-down flat
- **Detail:** 18×44 px. Housing: 18×44 px, #4A4A4A. Frame: 1px #6A6A6A. Fill bar: 12×40 px, #E8C040 fill from bottom. Max marker: 2px horizontal #E86020 line at 80% height. Current level: height changes with flywheel speed
- **Animation:** 
  - Fill rises: Bar height increases with flywheel speed, 2px/second
  - Decay: When not maintained, bar drops 1px/second
  - Overload: Above 80%, frame flashes #E86020 at 2Hz
  - Target: When at correct momentum, fill stops at 60% height, glows #E8C040 → #FFF8C0

---

## 12. Room 10 — The Counterweight

**Floor shape:** Wide rectangle, 385×175 game units (base_size=175, w=1.1×, h=0.5×)  
**Floor color:** #2A2A38 (dark blue-black)  
**Wall color:** #554A40 (bronze)  
**Floor texture:** env_floor_counterweight.png — dark blue-black with elaborate gold/brass compass-rose center, decorative frame, rivets, gold circles  
**Wall texture:** env_wall_brass.png — dark blue-black with ornate gold/brass decorative borders  
**Theme:** Balance, equilibrium, scale, symmetry, mass comparison, precision weighing

### Decoration Layout (12 objects)

#### 1. Central Fulcrum
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 24×45 game units (18×33 px)
- **Position:** (0, 25) — center-bottom
- **Shape:** Triangular pyramid base
- **Colors:** #6A6A6A (fulcrum), #8A8A8A (highlight), #4A4A4A (shadow), #C8A040 (brass pivot point), #E8D068 (gold tip)
- **Pixel style:** Top-down, 2.5D — pyramid appears as triangle from top
- **Detail:** 18×33 px. Base: 18px wide. Apex: 4px wide at top (pivot point). Body: #6A6A6A with 1px #8A8A8A left highlight and 1px #4A4A4A right shadow. Pivot: 4×4 px, #C8A040 with 1px #E8D068 highlight. Decorative base plate: 22×6 px, #4A4A4A, with 2px #C8A040 border
- **Animation:** 
  - When unbalanced: Fulcrum tilts ±3° toward heavier side, 0.5 second settle
  - At balance: Steady vertical, small #E8D068 pulse at pivot over 2 seconds
  - Overload: If too heavy, fulcrum compresses 2px, springs back when weight removed

#### 2. Balance Beam
- **Type:** Floor furniture / puzzle centerpiece
- **Size:** 200×6 game units (147×4 px)
- **Position:** (0, -25) — horizontal across center
- **Shape:** Long horizontal bar with decorative ends
- **Colors:** #8A7A50 (brass beam), #A09060 (highlight), #6A5A30 (shadow), #C8A040 (ornamental knobs at ends)
- **Pixel style:** Top-down, 2.5D — beam is 3px thick
- **Detail:** 147×4 px. Body: #8A7A50. Highlight: 1px #A09060 on top edge. Shadow: 1px #6A5A30 on bottom edge. Center pivot hole: 4×4 px, #2A2A20, with 2px #C8A040 rim. End knobs: 6×6 px circles, #C8A040 with 2px #E8D068 highlight. Calibration marks: 1px dots every 10px, #6A5A30
- **Animation:** 
  - Tilt: Beam rotates ±8° around center pivot when pans are unbalanced, 1 second settle time
  - Balance: When equal, beam levels to 0°, small #E8D068 flash at center
  - Oscillation: Just before settling, beam oscillates ±2° with decreasing amplitude over 2 seconds

#### 3. Left Pan
- **Type:** Floor furniture / puzzle element
- **Size:** 40×26 game units (29×19 px)
- **Position:** (-95, -18) — left end of beam
- **Shape:** Shallow trapezoidal bowl
- **Colors:** #6A6A6A (pan), #8A8A8A (highlight), #4A4A4A (shadow), #C8A040 (rim)
- **Pixel style:** Top-down, 2.5D — bowl is 3px deep
- **Detail:** 29×19 px. Top rim: 29×3 px, #C8A040 with 1px #E8D068 highlight. Bowl interior: 23×13 px, #4A4A4A with 1px #6A6A6A floor. Sides: visible as 3px #6A6A6A trapezoid. Chain attachment: 2×2 px loops, #8A8A8A, at rim corners
- **Animation:** 
  - Follows beam: Pan tilts with beam, maintaining relative orientation
  - Weight added: When weight placed, pan drops 2px, settles with beam tilt
  - Weight removed: Springs up 2px

#### 4. Right Pan
- **Type:** Floor furniture / puzzle element
- **Size:** 40×26 game units (29×19 px)
- **Position:** (95, -18) — right end of beam
- **Shape:** Mirror of left pan
- **Colors:** Same as left pan
- **Pixel style:** Same as left pan
- **Detail:** Same as left pan, mirrored
- **Animation:** Same as left pan

#### 5. Hanging Chain (×2)
- **Type:** Visual connector
- **Size:** Each chain: 4×18 game units (3×13 px)
- **Position:** (-95, -25) to (-95, -18) left; (95, -25) to (95, -18) right
- **Shape:** Vertical chain links
- **Colors:** #6A6A6A (chain), #8A8A8A (highlight link), #4A4A4A (shadow link)
- **Pixel style:** Top-down, 2.5D — chain hangs 2px below beam
- **Detail:** 3×13 px. 4 visible links, each 3×3 px, alternating #8A8A8A and #4A4A4A. Links are oval shapes. Top link connects to beam. Bottom link connects to pan
- **Animation:** 
  - Chain flex: When beam tilts, chain curves slightly, links compress on high side, stretch on low side (1px change)
  - Swing: If pan disturbed, chain sways 1px left-right, 2 second damped oscillation

#### 6. Weight Slot (×6)
- **Type:** Floor furniture / puzzle receptacle
- **Size:** 14×13 game units (10×10 px) each
- **Position:** (-80, 55), (-60, 55), (-40, 55), (40, 55), (60, 55), (80, 55) — on floor
- **Shape:** Small rectangular indentations
- **Colors:** #3A3A42 (slot), #2A2A2E (deep shadow), #4A4A52 (rim), #E8D068 (label)
- **Pixel style:** Top-down, 2.5D — slots are 2px recessed
- **Detail:** 10×10 px. Rim: 1px #4A4A52. Interior: #3A3A42. Depth: 1px #2A2A2E center. Small label: 1px dots indicating weight value ("1", "2", "3"), #E8D068
- **Animation:** 
  - Weight placed: Slot rim glows #E8D068 briefly (0.3 seconds) when correct weight inserted
  - Eject: Wrong weight ejected — weight lifts 4px and slides 5px away over 0.5 seconds

#### 7. Decorative Weight (×4)
- **Type:** Ambient object / puzzle candidates
- **Size:** 18×18 game units (13×13 px) each
- **Position:** (-50, 80), (50, 80), (-70, 70), (70, 70) — on floor near slots
- **Shape:** Octagonal metal weights
- **Colors:** #4A4A52 (weight), #6A6A78 (highlight), #2A2A30 (shadow), #C8A040 (stamp), #E86020 (heavy indicator on one)
- **Pixel style:** Top-down, 2.5D — 3px thick octagonal prisms
- **Detail:** 13×13 px octagon. Body: #4A4A52. Highlight: 1px #6A6A78 on top-left. Shadow: 1px #2A2A30 on bottom-right. Top stamp: 4×4 px, #C8A040, with 1px dot pattern (weight value). One weight has 2px #E86020 "HEAVY" marker on side
- **Animation:** 
  - Drag: When player grabs, weight lifts 3px, follows cursor
  - Drop: Falls 3px onto slot/floor, 1px #E8D068 impact ring
  - Slot fit: When dropped in correct slot, weight settles with 0.2 second vibration, stamp aligns

#### 8. Center Pointer
- **Type:** Puzzle indicator
- **Size:** 10×26 game units (7×19 px)
- **Position:** (0, -48) — above center, pointing to beam
- **Shape:** Triangular arrow pointing down
- **Colors:** #E8C040 (pointer), #FFF8C0 (highlight), #C8A040 (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 7×19 px. Triangle: 7px wide at base, 14px tall, #E8C040. Highlight: 1px #FFF8C0 on left edge. Shaft: 3×5 px, #C8A040, extends up from triangle base. Mount: 6×4 px, #4A4A4A, at top
- **Animation:** 
  - At balance: Pointer glows #FFF8C0, small 2px halo appears
  - Unbalanced: Pointer tilts toward high side (beam rises = that side heavier) by 2–5°
  - Settle: When balancing, pointer oscillates and settles vertical over 2 seconds

#### 9. Calibration Lines (Arc)
- **Type:** Ambient detail / precision reference
- **Size:** Arc radius 30 from center, 5 marks
- **Position:** Around center pointer base at angles -20°, -10°, 0°, 10°, 20°
- **Shape:** Short radial lines
- **Colors:** #6A6A6A (lines), #8A8A8A (center line), #E8D068 (tick marks)
- **Pixel style:** Top-down flat
- **Detail:** Each line: 5×2 px. Center line (0°): 6×3 px, #8A8A8A with 1px #E8D068 dot at outer end. Other lines: 5×2 px, #6A6A6A. Small degree labels: 1px dots, unreadable at scale
- **Animation:** 
  - Center line glows: #8A8A8A → #E8D068 when beam is perfectly level

#### 10. Precision Weight Set (×5)
- **Type:** Puzzle objects / inventory
- **Size:** 10×10, 12×12, 14×14, 16×16, 18×18 game units (various)
- **Position:** In player's inventory / on floor near puzzle
- **Shape:** Nested octagonal weights, different sizes
- **Colors:** #5A5A60 (smallest), #6A6A70, #7A7A80, #8A8A90, #9A9AA0 (largest), all with #C8A040 stamp
- **Pixel style:** Top-down, 2.5D
- **Detail:** Progressive sizes. Each has stamped value on top (1–5 dots). Smallest: 7×7 px. Largest: 13×13 px. All share same octagonal shape, proportional bevel
- **Animation:** 
  - Stack: Weights can stack — smaller sits on larger, 2px vertical offset per layer
  - Combine: When stacked, total value shown as combined stamp glow

#### 11. Balance Scale Wall Art
- **Type:** Wall detail / thematic
- **Size:** 80×40 game units (59×29 px)
- **Position:** (0, -120) — back wall
- **Shape:** Large decorative scale emblem
- **Colors:** #C8A040 (emblem), #E8D068 (highlight), #8A6A30 (shadow), #2A2A2E (background)
- **Pixel style:** Top-down flat, wall-mounted relief
- **Detail:** 59×29 px. Decorative frame: 2px #C8A040 border with corner curls. Central scale icon: 30×20 px, #C8A040 — horizontal beam with two pans, stylized. Background: #2A2A2E. Motto below: 1px dots suggesting "Aequilibrium" (illegible, decorative)
- **Animation:** 
  - Emblem glow: #C8A040 pulses #E8D068 over 3 seconds
  - When puzzle solved: Emblem brightens to #FFF8C0, stays steady

#### 12. Dust Motes in Light Beam
- **Type:** Ambient particle
- **Size:** 2×2 game units (1×1 px) each, 8 motes
- **Position:** Floating in diagonal light beam from ceiling window: random positions along beam path
- **Shape:** Tiny single pixels
- **Colors:** #E8D068 (mote), #FFF8C0 (bright mote)
- **Pixel style:** Flat particle
- **Detail:** 1×1 px dots. Some 2×2 px with 50% opacity core
- **Animation:** 
  - Float: Motes drift slowly downward at 1–2 px/sec (air currents)
  - Sparkle: Random motes brighten #E8D068 → #FFF8C0 over 0.5 seconds, then fade
  - Beam cut: If beam blocked (puzzle interaction), motes in shadow dim to 30% opacity

---

## 13. Room 11 — The Oiler

**Floor shape:** Square, 280×280 game units (base_size=175, w=0.8×, h=0.8×)  
**Floor color:** #4A4038 (dark brown)  
**Wall color:** #454035 (oiled metal)  
**Floor texture:** env_floor_oiler.png — dark brown-grey oil-stained tiles, gear wear patterns in tiles, oil stains, stone brick borders with bolted corners  
**Wall texture:** env_wall_oil.png — dark purple-brown with oil-slick panels and bolt heads  
**Theme:** Maintenance, lubrication, grease, tools, workshop, pipe systems

### Decoration Layout (13 objects)

#### 1. Main Workbench
- **Type:** Floor furniture / centerpiece
- **Size:** 120×35 game units (88×26 px)
- **Position:** (0, -70) — back wall
- **Shape:** Large rectangular bench with tool clutter
- **Colors:** #4A3A30 (bench top), #5A4A40 (highlight grain), #3A2E28 (shadow), #6A6050 (legs)
- **Pixel style:** Top-down, 2.5D — bench 4px thick
- **Detail:** 88×26 px. Top: #4A3A30 with 3 vertical wood grain lines, #5A4A40, slightly wavy. Edge bevel: 2px #5A4A40. Front face: visible as 6×88 px, #3A2E28. Leg shadows: 4×3 px each at corners, #2A2018. Tool clutter on top: wrench (12×3 px, #8A8A8A), oil rag (8×6 px, #6A6050, crumpled), small gear (6×6 px, #6A6A60), open oil can (7×5 px, #C8A040 with #8A7A68 oil pool inside)
- **Animation:** 
  - Oil can pool: #8A7A68 surface shifts 1px every 2 seconds (viscous movement)
  - Rag: Slight 1px twitch every 5 seconds (draft from vents)

#### 2. Tool Rack (Above Workbench)
- **Type:** Wall detail
- **Size:** 110×20 game units (81×15 px)
- **Position:** (0, -95) — on wall above workbench
- **Shape:** Horizontal bar with hanging tools
- **Colors:** #5A5A5A (rack), #7A7A7A (highlight), #3A3A3A (shadow), #C8A040 (tool accents)
- **Pixel style:** Top-down flat, wall-mounted
- **Detail:** 81×15 px. Bar: 81×4 px, #5A5A5A with 1px #7A7A7A highlight. Mounting brackets: 4×4 px, #3A3A3A, every 20px. Tools hanging: 
  - Large wrench: 10×3 px, #8A8A8A, hangs from bracket 1
  - Oil can: 6×5 px, #C8A040, hangs from bracket 2  
  - Screwdriver set: 3×2 px each, #6A6050, 3 in a row on bracket 3
  - Wire brush: 5×3 px, #6A6A60 with #8A8A8A bristles, bracket 4
- **Animation:** 
  - Tools sway: All tools sway 1px in unison when player walks nearby, 2 second damped oscillation
  - Brush bristles: Slight 1px flutter every 3 seconds

#### 3. Oil Barrel (×4)
- **Type:** Floor furniture / puzzle element
- **Size:** 28×34 game units (21×25 px) each
- **Position:** (-100, -45), (100, -45), (-100, 50), (100, 50) — corners
- **Shape:** Vertical cylinder (oval from top)
- **Colors:** #3A3A42 (barrel), #4A4A52 (highlight), #2A2A30 (shadow), #6A6050 (hoop), #2E2818 (oil surface)
- **Pixel style:** Top-down, 2.5D — barrel 4px thick
- **Detail:** 21×25 px oval. Body: #3A3A42 with 2 vertical #4A4A52 highlight bands (4px). Metal hoops: 2px #6A6050 rings at 25%, 50%, 75% height. Top opening: 15×8 px ellipse showing oil surface #2E2818 with 1px #4A4030 highlight (oil sheen). One barrel has spigot: 4×3 px, #6A6050, with 1px #2E2818 drip
- **Animation:** 
  - Oil sheen: Surface highlight shifts 2px every 1.5 seconds
  - Spigot drip: 1px oil drop forms, grows, falls every 4 seconds, leaves 2px #2E2818 spot
  - When used: Oil level drops 1px visible depth

#### 4. Oil Surface (Inside Barrels)
- **Type:** Ambient detail
- **Size:** 15×8 game units (11×6 px) each (visible through barrel top)
- **Position:** Inside each barrel top opening
- **Shape:** Elliptical oil pool
- **Colors:** #2E2818 (oil), #4A4030 (sheen highlight), #1E1810 (deep shadow)
- **Pixel style:** Top-down flat
- **Detail:** 11×6 px ellipse. Oil: #2E2818. Sheen: 2px #4A4030 crescent on side facing light. Some have small 1px #6A6050 bubble or dust fleck
- **Animation:** 
  - Sheen drift: #4A4030 highlight shifts 1px, 2 second cycle
  - Bubbles: 1px #4A4030 dots appear, rise 2px, pop every 3–5 seconds

#### 5. Oil Puddle (×3)
- **Type:** Ambient object
- **Size:** 20×16 game units (15×12 px) each, irregular
- **Position:** Random on floor: (-40, 55), (35, -45), (70, 60)
- **Shape:** Amorphous organic blobs with 8–10 vertices
- **Colors:** #2E2818 (puddle), #4A4030 (sheen edge), #1E1810 (deep center), #6A6050 (mud mixed at edge)
- **Pixel style:** Top-down flat — oil is surface-level
- **Detail:** 15×12 px irregular blob. Edge: 1px #4A4030 sheen ring (iridescent, slightly lighter). Center: #2E2818. Some have 2px #1E1810 deeper spot. Mixed with floor grime: 2–3 px #6A6050 at edges where oil meets dirt
- **Animation:** 
  - Sheen ripple: Edge sheen shifts 1px in slow wave pattern, 4 second cycle
  - Footprint: If player walks through, 3–4 px disturbance ripples expand 5px and fade over 2 seconds

#### 6. Grease Gun (On Workbench)
- **Type:** Puzzle tool / ambient
- **Size:** 24×13 game units (18×10 px)
- **Position:** (-12, -55) — on workbench
- **Shape:** Cylindrical body with pistol grip
- **Colors:** #5A5A5A (body), #7A7A7A (highlight), #3A3A3A (shadow), #C8A040 (nozzle), #8A7A68 (grease at tip)
- **Pixel style:** Top-down, 2.5D — 3px thick
- **Detail:** 18×10 px. Body: 14×8 px oval, #5A5A5A. Nozzle: 4×3 px, #C8A040, extends from body. Grip: 4×6 px, #3A3A3A, offset below body. Grease at nozzle tip: 2px #8A7A68 blob. Trigger: 2×3 px, #6A6A6A, inside grip guard
- **Animation:** 
  - Idle: Static
  - Used: Trigger depresses 1px, grease ejects as 2×4 px #8A7A68 stream from nozzle, then retracts
  - Drip: 1px #8A7A68 forms at tip every 3 seconds, falls, leaves spot

#### 7. Pipe System (Wall-Mounted)
- **Type:** Wall detail
- **Size:** 220×12 game units (162×9 px) total (3 parallel pipes)
- **Position:** Horizontal at y = -15, 5, 25 — across room
- **Shape:** 3 parallel horizontal pipes
- **Colors:** #4A4A52 (pipes), #6A6A78 (highlight), #2A2A30 (shadow), #8A7A68 (oil stain on one)
- **Pixel style:** Top-down, 2.5D — each pipe 4px diameter
- **Detail:** 3 pipes, each 4px wide, 2px spacing. Pipe 1 (top): #4A4A52 with 1px #6A6A78 highlight, clean. Pipe 2 (middle): #4A4A52 with 2px #8A7A68 oil drip streak along bottom. Pipe 3 (bottom): #4A4A52 with 1px #2A2A30 shadow. Small 2×2 px flanges every 30px. Oil drip from pipe 2: 1px #8A7A68 bead at one flange, grows, falls
- **Animation:** 
  - Oil drip: 1px bead grows, falls every 3 seconds, leaves 2px #8A7A68 spot on floor
  - Pipe vibration: All pipes shift 1px vertically every 4 seconds (pump pressure)

#### 8. Pipe Joint (×8)
- **Type:** Wall detail
- **Size:** 8×8 game units (6×6 px) each
- **Position:** At pipe intersections: (-80, -15), (-30, -15), (30, -15), (80, -15), and same x at y=5, y=25
- **Shape:** Square flanges at pipe connections
- **Colors:** #5A5A5A (joint), #7A7A7A (highlight), #3A3A3A (shadow), #C8A040 (bolt), #E86020 (leak indicator on one)
- **Pixel style:** Top-down, 2.5D — 2px thick square caps
- **Detail:** 6×6 px. Body: #5A5A5A. 4 bolts: 1×1 px, #C8A040, at corners. Cross pattern: 1px #3A3A3A X on top. One joint has 1px #E86020 leak stain at bottom edge
- **Animation:** 
  - Leak joint: 1px #E86020 stain grows 1px every 5 seconds, then resets
  - Bolt glint: Random bolts flash #E8D068 for 0.1 second when light hits

#### 9. Rag/Cloth (On Floor)
- **Type:** Ambient object
- **Size:** 20×20 game units (15×15 px)
- **Position:** (30, 65) — near front
- **Shape:** Crumpled irregular cloth blob
- **Colors:** #5A4A40 (rag), #6A6050 (highlight fold), #4A4038 (shadow fold), #8A7A68 (oil stain)
- **Pixel style:** Top-down flat with fold shadows
- **Detail:** 15×15 px irregular blob. Folds create 2–3 darker #4A4038 lines (2px, curved). Oil stain: 4×5 px, #8A7A68, at one corner. Some cleaner areas: #6A6050. A 2×2 px #C8A040 brass button or snap visible
- **Animation:** 
  - Slight flutter: 1px shift every 5 seconds (ventilation draft)
  - Oil spread: Stain grows 1px every 10 seconds (capillary action), then resets

#### 10. Maintenance Checklist (On Wall)
- **Type:** Wall detail / lore
- **Size:** 24×30 game units (18×22 px)
- **Position:** (-110, -80) — left wall
- **Shape:** Rectangular clipboard with paper
- **Colors:** #6A6050 (board), #8A7A68 (clip), #E8E0D0 (paper), #3A3A3A (text dots), #E86020 (unchecked item), #40D878 (checked item)
- **Pixel style:** Top-down flat
- **Detail:** 18×22 px. Board: #6A6050, 18×22 px. Metal clip: 10×4 px, #8A7A68, at top. Paper: 14×16 px, #E8E0D0. 4 lines of "text": 1px #3A3A3A dots, 8px long. Checkboxes: 2×2 px squares. Box 1: #40D878 (checked). Box 2: #40D878 (checked). Box 3: #E86020 (unchecked — puzzle hint). Box 4: #E86020 (unchecked)
- **Animation:** 
  - Paper flutter: 1px shift every 3 seconds (draft)
  - When puzzle item oiled: Corresponding checkbox flashes #40D878, gets checked mark

#### 11. Oil Filter (×2)
- **Type:** Floor furniture
- **Size:** 20×24 game units (15×18 px) each
- **Position:** (-60, -35), (60, -35) — near workbench
- **Shape:** Short vertical cylinder with top cap
- **Colors:** #4A4A4A (filter), #6A6A6A (highlight), #2A2A2A (shadow), #C8A040 (cap), #8A7A68 (oil level window)
- **Pixel style:** Top-down, 2.5D — 3px thick
- **Detail:** 15×18 px oval. Body: #4A4A4A with 1px #6A6A6A highlight. Top cap: 10×6 px, #C8A040 with 1px #E8D068 highlight. Side window: 3×8 px vertical strip, shows #8A7A68 oil level at 40% with 1px #A09080 highlight on surface. Bottom: 2px #2A2A2A shadow ring
- **Animation:** 
  - Oil level: Surface shifts 1px every 2 seconds
  - When filter changed (puzzle interaction): Oil level jumps to 100%, then drains to 80% over 1 second

#### 12. Spilled Screws (×8)
- **Type:** Ambient object
- **Size:** 3×3 game units (2×2 px) each
- **Position:** Scattered near workbench: (-45, -50), (-35, -55), (40, -48), (55, -52), (-50, -60), (48, -58), (-30, -48), (60, -55)
- **Shape:** Tiny 2×2 px shapes
- **Colors:** #8A8A8A (screw), #A0A0A0 (head), #6A6A6A (shadow)
- **Pixel style:** Top-down flat
- **Detail:** 2×2 px. One px #A0A0A0 (head, top-left). Other px #8A8A8A (body). Some have 1px #6A6A6A shadow offset
- **Animation:** Static

#### 13. Workshop Stool
- **Type:** Ambient object
- **Size:** 24×24 game units (18×18 px)
- **Position:** (80, -20) — near workbench
- **Shape:** Three-legged stool seen from top
- **Colors:** #6A5030 (wood seat), #5A4030 (legs), #4A3028 (shadow), #8A7A68 (worn spot)
- **Pixel style:** Top-down, 2.5D — seat 3px thick, legs as floor shadows
- **Detail:** 18×18 px. Seat: 14×14 px circle, #6A5030 with 1px #8A7A68 worn spot. Three leg shadows: 3×2 px each, #4A3028, at 120° intervals, extending 6px from seat. One leg shadow has 1px #8A7A68 oil stain where mechanic sat
- **Animation:** 
  - Subtle wobble: When player interacts, stool shifts 1px, 0.3 second settle

---

## 14. Room 0 — Crown Cog Hub

**Floor shape:** Circular hub, radius ~200 game units  
**Floor color:** #3A3A4A (dark steel)  
**Wall color:** #4A4A5A (dark hub metal)  
**Floor texture:** env_floor_hex.png — dark grey hexagonal tile pattern (fallback/central hub)  
**Wall texture:** env_wall_metal.png — riveted dark steel panels  
**Theme:** Central control, save point, shop, rotation mechanism, safe zone

### Decoration Layout (10 objects)

#### 1. Crown Cog (Central)
- **Type:** Floor furniture / structural centerpiece
- **Size:** 160×160 game units (118×118 px)
- **Position:** Center (0, 0)
- **Shape:** Massive 12-toothed gear
- **Colors:** #5A5A6A (cog body), #7A7A8A (highlight), #3A3A4A (shadow), #E8C040 (gold center), #C8A040 (teeth accent)
- **Pixel style:** Top-down, 2.5D — cog is 6px thick, teeth project 4px
- **Detail:** 118px diameter. 12 teeth, each 16×10 px. Body: #5A5A6A with 2px #7A7A8A highlight on top-left edges. Teeth: #5A5A6A with 1px #C8A040 accent on leading edges. Center: 30×30 px, #E8C040 with 6×6 px #FFF8C0 bolt pattern. Inner ring: 70px diameter, 3px #3A3A4A. Rivets: 3×3 px, #8A8A90, 12 evenly spaced on inner ring
- **Animation:** 
  - Slow rotation: Cog turns 3°/second continuously (ambient machinery)
  - Rotation trigger: When player activates dial, cog accelerates to 30°/second for 1 second, then settles to new position
  - Center glow: #E8C040 pulses #FFF8C0 over 2 seconds

#### 2. Dial Control Console
- **Type:** Floor furniture / puzzle interactable
- **Size:** 80×40 game units (59×29 px)
- **Position:** (0, 120) — front of hub
- **Shape:** Wide curved console with dial
- **Colors:** #4A4A5A (console), #6A6A78 (highlight), #E8C040 (dial), #E86020 (rotate button), #40D878 (status)
- **Pixel style:** Top-down, 2.5D — console curves around front of hub
- **Detail:** 59×29 px. Curved front edge follows hub arc. Body: #4A4A5A. Large dial: 20×20 px circle, #E8C040 with 1×10 px #E86020 needle. Dial markings: 1px dots at 30° intervals. "ROTATE" button: 12×8 px, #E86020, below dial. Status light: 4×4 px, #40D878 (ready). Small display: 16×6 px, #2A2A3A, showing current room number as 3×5 px pixel digits
- **Animation:** 
  - Dial needle: Sweeps to next position when rotated, 0.5 second smooth motion
  - Button press: #E86020 → #F0A040 on press, springs back
  - Status: #40D878 pulses when rotation complete, #E86020 if rotation blocked

#### 3. Save Crystal (×1)
- **Type:** Puzzle / save point
- **Size:** Crystal: 36×50 game units (26×37 px); Platform: 48×28 game units (35×20 px)
- **Position:** (-80, 0) — left side of hub
- **Shape:** Same as Room 12 save crystal
- **Colors:** Platform: #263038 (dark base). Crystal: #40D878 (bright green), #60F098 (core), #A0FFC0 (highlight)
- **Pixel style:** Same as Room 12
- **Detail:** Same detailed spec as Room 12 save crystal
- **Animation:** Same as Room 12 — continuous breathing glow, rotating ring, floating particles
- **Interaction:** Label "[S] Save" below

#### 4. Machinist Shop Counter
- **Type:** Floor furniture / shop interactable
- **Size:** 100×30 game units (74×22 px)
- **Position:** (80, 0) — right side of hub
- **Shape:** Curved shop counter with display shelves
- **Colors:** #5A5040 (wood counter), #6A6050 (highlight), #C8A040 (brass trim), #E8D068 (item glows)
- **Pixel style:** Top-down, 2.5D — counter 4px thick
- **Detail:** 74×22 px. Curved front. Counter top: #5A5040 with 2px #C8A040 brass edge. Display shelves: 3 recessed 12×6 px areas showing items — healing potion (4×6 px, #E86020 vial), map scroll (8×3 px, #E8E0D0), gear token (5×5 px, #C8A040). Price tags: 1px #E8C040 dots below each item
- **Animation:** 
  - Item glow: When player has enough gems, item glows #E8D068 at 30%, pulsing
  - Sold out: Item dims to #4A4A4A, "SOLD" stamp appears (1px dots)

#### 5. Kami Shrine Niche (×2)
- **Type:** Wall detail / offering interactable
- **Size:** 30×40 game units (22×29 px) each
- **Position:** (-120, -60), (120, 60) — on outer walls
- **Shape:** Small alcove with altar shelf
- **Colors:** #3A3A42 (niche), #5A5A5A (shelf), #E8C040 (trim), #40D878 (offering glow when active)
- **Pixel style:** Top-down, 2.5D — niche recessed 3px into wall
- **Detail:** 22×29 px. Alcove: 18×25 px, #3A3A42. Shelf: 18×4 px, #5A5A5A, at 60% height. Trim: 1px #E8C040 border. Empty: shows #2A2A2E dark interior. When offering placed: item glows #40D878 at 40%, small 2px particle rise from shelf
- **Animation:** 
  - Empty: Subtle #3A3A42 pulse
  - With offering: #40D878 glow, 2px particles rise and fade over 1.5 seconds
  - Boon granted: Bright #60F098 flash, particles burst outward

#### 6. Light Beam Emitter Socket (×12)
- **Type:** Wall detail / puzzle element
- **Size:** 16×16 game units (12×12 px) each
- **Position:** Around outer perimeter at 30° intervals
- **Shape:** Small hexagonal socket
- **Colors:** #4A4A5A (socket), #6A6A78 (highlight), #2A2A2E (interior), #E8C040 (dormant crystal), #FFF8C0 (active beam)
- **Pixel style:** Top-down, 2.5D — socket inset 2px
- **Detail:** 12×12 px hexagon. Rim: 2px #6A6A78. Interior: #2A2A2E. Crystal: 6×6 px, #E8C040 when dormant. When room puzzle solved: crystal brightens #FFF8C0, thin 2×80 px beam shoots inward toward center
- **Animation:** 
  - Dormant: #E8C040 crystal dim, 20% opacity flicker
  - Active: #FFF8C0 beam shoots from socket to center, 2px wide, 60% opacity, steady
  - Beam pulse: When all 12 active, beams brighten in wave pattern around circle, 0.3 second stagger

#### 7. Gear Devil Token Altar (×11)
- **Type:** Floor furniture / progression
- **Size:** 20×20 game units (15×15 px) each
- **Position:** Arranged in arc around back half of hub
- **Shape:** Small pedestals for token collection
- **Colors:** #4A4A4A (pedestal), #6A6A6A (highlight), #E86020 (empty), #C8A040 (token present)
- **Pixel style:** Top-down, 2.5D — 3px thick square column
- **Detail:** 15×15 px. Base: 15×15 px, #4A4A4A. Top: 11×11 px, #6A6A6A. Empty: #2A2A2E center. With token: 7×7 px cog coin, #C8A040 with 1px #E86020 center glow. Label below: 1px dots, unreadable
- **Animation:** 
  - Empty: #2A2A2E pulse
  - Token placed: Coin spins 360° over 0.5 seconds, lands flat, glows #E8C040
  - All 11 collected: All tokens pulse #FFF8C0 in sequence, boss unlock effect

#### 8. Floor Compass Rose
- **Type:** Floor detail / navigation aid
- **Size:** 120×120 game units (88×88 px)
- **Position:** Centered on hub floor, around Crown Cog
- **Shape:** 12-pointed compass/star pattern
- **Colors:** #4A4A5A (lines), #6A6A78 (highlight), #E8C040 (12 o'clock marker), #3A3A42 (background)
- **Pixel style:** Top-down flat
- **Detail:** 88×88 px. 12 radial lines from center, each 44px long, 1px #4A4A5A. 12 o'clock line: 2px #E8C040 (start position). Circle at radius 40px: 1px #4A4A5A. Small 2×2 px #6A6A78 dots at line ends. Room numbers: 1px dots at each position (illegible, decorative)
- **Animation:** 
  - 12 o'clock marker: #E8C040 pulses #FFF8C0 (save room indicator)
  - Current room: Line toward active room brightens #6A6A78 → #E8C040 over 0.5 seconds

#### 9. Safety Rail (×2)
- **Type:** Floor furniture
- **Size:** 200×4 game units (147×3 px) each
- **Position:** Arcs at (-60, 140) to (60, 140) and (-100, -100) to (100, -100)
- **Shape:** Curved safety bars
- **Colors:** #6A6A78 (rail), #8A8A90 (highlight), #4A4A5A (shadow), #E86020 (warning stripe every 20px)
- **Pixel style:** Top-down, 2.5D — rail 2px thick, 2px above floor
- **Detail:** 147×3 px curved bar. Body: 1px #6A6A78. Highlight: 1px #8A8A90 on inner edge. Support posts: 2×4 px, #4A4A5A, every 25px. Warning stripes: 3×3 px, #E86020, every 20px on rail
- **Animation:** Static

#### 10. Ambient Gear Rotation (Background)
- **Type:** Ambient / atmospheric
- **Size:** Various small gears, 20×20 to 40×40 game units
- **Position:** Scattered around hub perimeter, 8 small gears
- **Shape:** Various 6–8 toothed gears
- **Colors:** #4A4A5A (gears), #6A6A78 (highlight), #3A3A42 (shadow)
- **Pixel style:** Top-down, 2.5D
- **Detail:** 8 small gears of varying sizes. Each has 6–8 teeth, 2.5D shading. Connected by implied (not visible) axles
- **Animation:** 
  - All gears rotate at different speeds (2–8°/second), creating living machinery feel
  - Meshed gears rotate in opposite directions
  - Subtle 1px vibration on all gears (machinery hum)

---

## 15. Sprite Generation Script

The batch generation script at `/tmp/generate_room_objects.py` calls PixelLab API to create all needed sprites. See the separate script file for the complete implementation.

### Sprite Summary by Category

| Category | Count | Size Range | Key Examples |
|----------|-------|------------|--------------|
| Floor furniture | ~35 | 20×20 to 160×160 | Workbenches, furnaces, gears, barrels, platforms |
| Wall details | ~28 | 8×8 to 110×20 | Tool racks, gauges, pipes, vents, clocks |
| Ambient objects | ~45 | 2×2 to 30×20 | Debris, sparks, puddles, rags, screws |
| Puzzle interactables | ~20 | 12×12 to 80×80 | Valves, levers, prisms, lenses, weights |
| Animated elements | ~25 | 2×2 to 200×6 | Steam, light beams, heat waves, motion blur |

### PixelLab Prompt Templates Used

**Furniture Prompt:**
```
Pixel art sprite, [SIZE], transparent background. Industrial steampunk [OBJECT] for a dark factory interior. [DESCRIPTION]. Dark metal palette with [ACCENT COLOR] highlights. Top-down or isometric view, centered, clear readable silhouette. Medium shading, crisp pixel edges.
```

**Ambient Prompt:**
```
Pixel art sprite, [SIZE], transparent background. Small steampunk [OBJECT] detail. [DESCRIPTION]. Dark industrial palette with [ACCENT COLOR]. Top-down view, flat or subtle 2.5D. Pixel art style.
```

**Animation-ready Prompt:**
```
Pixel art sprite sheet or single frame, [SIZE], transparent background. Steampunk [OBJECT] with glowing/animated elements. [DESCRIPTION]. Dark metal base with bright [GLOW COLOR] accents. Top-down view, centered. Pixel art, clean silhouette.
```

---

*End of Room Decoration Design Document*
