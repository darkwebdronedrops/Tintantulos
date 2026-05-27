# Floor 3 Room Puzzle System - Implementation Summary

## Date: 2026-04-29
## Status: ALL 11 ROOMS COMPLETE

---

## New Files Created

### Core Framework
1. **scripts/RoomPuzzle.gd** — Base class for all room puzzles
   - Puzzle state machine (LOCKED → ACTIVE → SOLVED)
   - Gear Devil Token system (hidden → revealed → collected)
   - Kami Shrine integration (database-driven via `_create_shrine_from_db()`)
   - Interaction system (E key, proximity-based)
   - Sprite loading with fallback (`_load_sprite_or_fallback()`)
   - Save/load support

2. **scripts/KamiShrine.gd** — Offering and boon system
   - Accepts/rejects offerings based on kami preferences
   - Minor/Major/Epic boon tiers
   - Visual feedback (glow, dialogue)
   - Save/load support

### Core Framework
1. **scripts/Trap.gd** — Base class for all environmental traps
   - Trap state machine (IDLE → ACTIVE → TRIGGERED → DISABLED)
   - Damage system (dice rolls, flat damage, types: physical/fire/fall/psychic)
   - Terrain modification (hex passable/impassable)
   - Combat push (force combat encounter)
   - Visual feedback, save/load

2. **scripts/GraspingCogTrap.gd** — 2d6 physical damage + knockback + 3s hex block
3. **scripts/CompressionTrap.gd** — 1d4 damage per 5s (DOT) + descending ceiling visual
4. **scripts/RecalibrationTrap.gd** — 3d6 fall damage + floor spin + shortcut option
5. **scripts/WarningSermonTrap.gd** — +1 Attention cost to all combat cards (60s debuff)

### Room Implementations (ALL 11)
| Room | File | Status | Mechanic |
|------|------|--------|----------|
| 1 Quench | `QuenchPuzzle.gd` | ✅ Done | 3 rotatable pipe valves → redirect water flow |
| 2 Spark | `SparkPuzzle.gd` | ✅ Done | Memory/observation — 6 boiler valves, spark trail sequence |
| 3 Governor | `GovernorPuzzle.gd` | ✅ Done | Logic/systems — 8 levers, 4 gauges, green zone targeting |
| 4 Draft | `DraftPuzzle.gd` | ✅ Done | Airflow — 4 directional vents, steam pressure, prism push |
| 5 Temper | `TemperPuzzle.gd` | ✅ Done | Heat management — furnace fuel (LOW/MED/HIGH), thermal lens expansion |
| 6 Beacon | `BeaconPuzzle.gd` | ✅ Done | Height/climbing — 3 gear levers power lift, ride to peak crystal |
| 7 Escapement | `EscapementPuzzle.gd` | ✅ Done | Timing/rhythm — 6-tooth wheel, pull trigger in shrinking green window |
| 8 Bearing | `BearingPuzzle.gd` | ✅ Done | Friction — oil 5 seized bearings of 8, housing auto-rotates to align |
| 9 Flywheel | `FlywheelPuzzle.gd` | ✅ Done | Momentum — push to build speed, release at 85-95% perfect window |
| 10 Counterweight | `CounterweightPuzzle.gd` | ✅ Done | Balance — add weights to scale, use ≥3 different values, difference = 0 |
| 11 Oiler | `OilerPuzzle.gd` | ✅ Done | Maintenance — oil 5 spots, clean sight glass |

### Database
- **GameState.OFFERING_DATABASE**: 10 offerings with quality, gem value, sprites
- **GameState.KAMI_DATABASE**: 8 kami with preferences, boons, dialogue, sprites
- **GameState.BOON_DATABASE**: 6 boons with durations and effects

### Updated Files
- **scripts/Floor3Controller.gd** — Integrated all 11 puzzles + wall collision
- **scripts/GameState.gd** — Economy, progress, offering/kami/boon databases
- **scripts/RoomInteriorBuilder.gd** — 11 unique interior layouts

---

## Wall Collision System

**Added to Floor3Controller:**
- `blocked_hexes: Array[Vector2i]` — tracks hex positions blocked by room walls
- `_generate_room_wall_hexes(room)` — marks outer ring hexes (distance 2-3 from room center) as blocked, except inward path toward Crown Cog
- `_is_hex_blocked(hex)` — checks if target hex is in blocked list
- Modified `_try_move()` and mouse click movement to reject blocked hexes
- Crown Cog center (0,0) always walkable

**This ensures:**
- Player cannot walk through room walls from outside
- Each room has a clear inward path (toward center) for entry
- ESC exits puzzle back to overworld

---

## Light Beam Puzzle Integration

**File:** `scripts/LightBeamPuzzle.gd` — Fully rewritten

### Core Design
11 rooms, each with a light widget. When a room's puzzle is solved, its widget powers on. Player can rotate widgets (hex directions 0-5) from the overworld. When a powered widget faces center (0,0), it emits a beam toward center.

**Two-tier completion:**
- **Optimal:** All 11 beams hitting center simultaneously
- **Suboptimal:** Any beams hitting center = boss unlocks (but with penalty)

### Widget States
| State | Powered | Aligned | Visual |
|-------|---------|---------|--------|
| Inactive | ❌ | ❌ | Cold metal socket, dim |
| Active | ✅ | ❌ | Warm glow socket, prism rotates, no beam |
| Aligned | ✅ | ✅ | Bright prism, golden beam to center, halo glow |

### Integration Flow
1. **Room solved** → `_on_room_puzzle_solved()` calls `power_widget(room_id)` → widget auto-rotates to face center → beam activates
2. **Dial rotation** → `_rotate_dial()` calls `update_all_widget_visuals()` → beams recalculate alignment (may deactivate if room moved)
3. **Player stands on cleared room** → presses E → rotates widget → beam may reactivate
4. **All aligned** → `puzzle_complete` emitted → `GameState.crown_cog_unlocked = true`

### Global Beam Lines
Beams are `Line2D` nodes, children of `LightBeamPuzzle` (not room nodes). This ensures:
- Beams stay visually connected to center even when rooms rotate
- Beam endpoints: `[room_world_pos, Vector2.ZERO]`
- Beam color/width varies by alignment quality

### Overworld Interaction
- `_update_overworld_interact_prompt()` in `_process()` shows context-aware prompts
- Crown Cog: "Crown Cog locked (3/11 beams)" or "[E] Enter Crown Cog"
- Cleared room: "[E] Rotate Widget (aligned)" or "[E] Rotate Widget"
- Uncleared room: Auto-enters on step, no prompt needed

### Save/Load
- Widget rotations, powered state, aligned state all persisted
- Collector glow intensity restored
- Puzzle completion state preserved

---

## Trap System Integration

**Files:** `Trap.gd`, `GraspingCogTrap.gd`, `CompressionTrap.gd`, `RecalibrationTrap.gd`, `WarningSermonTrap.gd`

**Trigger:** 25% chance to spawn trap after each dial rotation. Traps spawn in uncleared rooms.

**Placement:** Hex adjacent to room center (not on entry path, not already trapped).

**Trap-Player Interaction:**
- `_check_trap_triggers()` called after every player move (keyboard + mouse)
- Trap checks if player hex matches trap's affected_hexes
- If match and trap not DISABLED → `trigger_trap()`

**Effects:**
| Trap | Damage | Terrain | Combat | Duration |
|------|--------|---------|--------|----------|
| Grasping Cog | 2d6 physical | Blocks hex 3s | — | Permanent |
| Compression | 1d4/5s physical | Blocks hex | — | 30s |
| Recalibration | 3d6 fall | Blocks hex | — | Permanent, shortcut |
| Warning Sermon | — | — | +1 Attention | 60s |

**Save/Load:** Trap states persisted in floor state. Restored with position, lifetime, and state.

---

## Room Rotation

**Verified:** All non-stationary rooms (1-11) rotate when dial is triggered.
- Room 12 (The Quench start) is stationary (`is_stationary = true`)
- Rotation updates `room.current_angle = room.base_angle + rotation_angle`
- Position recalculated at `OUTER_RADIUS` from center
- Tween animation moves room node to new position over 0.5s
- Puzzle objects move with room since they're child nodes

---

## Testing Checklist

### Manual Test Flow
1. Start game → Room 12 (The Quench start)
2. Walk around — verify walls block movement
3. Enter Room 1 — solve puzzle
4. ESC to exit — verify return to overworld
5. Rotate dial (R) — verify rooms move
6. Walk to Room 2-11 — verify each puzzle activates
7. Solve a few, collect tokens
8. Save game → verify state persists
9. Load game → verify state restores

### Known Issues
- Counterweight auto-placement logic is simplified (auto-places on lighter side)
- Bearing sprite loading uses single sprite for all bearings (tinted by state)
- Flywheel jam recovery is 3s hard wait

---

## Combat Integration

**File:** `scripts/RoomEnemyDatabase.gd` + `scripts/Floor3Controller.gd`

### RoomEnemyDatabase
Central database mapping each room to thematic enemy compositions. "The things in the room ARE the things in the room."

| Room | Theme | Standard Enemies | Ambush | Trap |
|------|-------|-----------------|--------|------|
| 1 Quench | Water/cooling | Piston Assembly ×2 | Piston ×3 + Bug | Piston + Lag |
| 2 Spark | Fire/heat | The Caldera + Eye | Caldera + Eye + Gear Pair | Caldera + Collar |
| 3 Governor | Regulation | Diagnostic Eye + Gear Pair | Eye + Default + Gear Pair | Eye + Cursor |
| 4 Draft | Airflow/steam | Piston + Hound | Piston + Echo + Hound | Piston + Echo ×2 |
| 5 Temper | Heat treatment | Gear Pair + Caldera | Gear Pair + Caldera + Eye | Caldera + Collar + Gear Pair |
| 6 Beacon | Height/light | Diagnostic Eye ×2 | Eye + Whisper + Eye | Eye + Whisper |
| 7 Escapement | Time/rhythm | Clockwork Hound + Loop | Hound + Loop + Lag | Loop + Lag + Hound |
| 8 Bearing | Friction/oil | Gear Pair + Piston | Gear Pair + Hollow + Piston | Gear Pair + Hollow + Forgotten |
| 9 Flywheel | Momentum | Gear Pair + Hound | Gear Pair + Contagion + Hound | Gear Pair + Contagion ×2 |
| 10 Counterweight | Balance | Mirror + Duplicate | Mirror + Duplicate + Default | Mirror + Duplicate + Mirror |
| 11 Oiler | Maintenance | Piston + Forgotten | Piston + Forgotten + Hound | Forgotten ×2 + Hollow |

### Enemy Templates (19 types)
All enemies have unique sprites, HP, attack, defense, and action patterns:
- **Constructs:** Piston Assembly, Clockwork Hound, Diagnostic Eye, Gear Pair
- **Elemental:** The Caldera
- **Software Aberrations:** The Bug, The Lag, The Echo, The Loop, The Cursor, The Default, The Collar, The Contagion, The Hollow, The Forgotten, The Whisper, The Mirror, The Duplicate, The Refrain

### Boss Compositions
- **TheCaldera** — Living furnace core (25 HP, 6 ATK)
- **GearMother** — Progenitor of gears (boss sprite set)
- **GoblinKingGrimgut** — Goblin King (boss sprite set)

### Integration Flow
1. **Puzzle ambush** → `_on_room_combat_triggered()` → `_enter_combat_in_room(room_id, "ambush")` → RoomEnemyDatabase ambush composition
2. **Trap combat push** → `_on_trap_combat_forced()` → RoomEnemyDatabase trap composition + `GameState.add_temp_effect("trap_debuff", 60, {attention_cost: 1})` → player starts with +1 attention cost
3. **Boss room** → `_enter_combat_in_room(room_id, "boss")` → RoomEnemyDatabase boss composition + support minions
4. **Standard room entry (no puzzle)** → `_enter_combat_in_room(room_id, "enemies")` → RoomEnemyDatabase standard composition

### Trap Combat Push
| Trap | pushes_to_combat | Enemy Composition |
|------|-----------------|-------------------|
| Grasping Cog | ✅ Yes | Gear Pair + Piston Assembly |
| Compression | ❌ No | DOT only |
| Recalibration | ✅ Yes (if not shortcut) | Diagnostic Eye + The Default + The Cursor |
| Warning Sermon | ❌ No | Debuff only |

### Visual Polish
- Enemy spawn-in animation (`EnemySpawner.show_spawn_animation`) — scale from 0 to 1 with back ease
- Damage flash on hit — enemy flashes red, HP bar changes color (green→yellow→orange→red)
- Death animation — enemy greys out, sprite rotates 90° (falls over)
- Encounter banner — "⚔ Steam Constructs" with flavor text

---

## Remaining Systems
- **Offering inventory UI** — Frontend for GameState.inventory_offerings
- **Crown Cog Shop** — "The Machinist" merchant (Gems economy)
- **Card game card compositor** — 189/240 cards done

---

*Built by: Kimi (main session)*
*For: Acanous Floor 3 Demo*
*Date: April 30, 2026*
