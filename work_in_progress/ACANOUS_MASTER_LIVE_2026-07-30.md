# ACANOUS CARD BATTLER — MASTER DOCUMENT (LIVE)
## Date: 2026-07-30
## Compiled by: Zera (OpenClaw Instance)
## Cards: 240/240 (100% Complete) ✅
## Source of Truth: GAME CODEBASE (finished_cards/ + scripts/HexFloor*Controller.gd)

**This document reflects what is ACTUALLY IMPLEMENTED in the codebase.**
The previous markdown master (ACANOUS_MASTER_2026-03-07.md) is stale.

---

## LOCKED DESIGN RULES — DO NOT CHANGE

### Rule 1: Hex-Based Movement (WEADZX)
**THIS GAME IS HEX-BASED. EVERY FLOOR IS HEX-BASED.**

All floors use the same hex-grid control scheme:
- **W** = Northwest, **E** = Northeast
- **A** = West, **D** = East
- **Z** = Southwest, **X** = Southeast
- **S** = Interact / Select
- **Click** = Click-to-move with pathfinding

This is **intentional** and **not a bug**.

### Rule 2: Faction ≠ Keyword
**Faction names are NOT keywords.** The following are factions only:
- Construct, Goblin, Elemental, Undead, Demon, Aberration, Dragon, Universal

Keywords are mechanical modifiers (see Keyword System below).

---

## TABLE OF CONTENTS

1. [Locked Design Rules](#locked-design-rules--do-not-change)
2. [Core Mechanics](#core-mechanics)
3. [Keyword System](#keyword-system)
4. [Card Database](#card-database)
5. [Dungeon Floors](#dungeon-floors)
6. [Cross-Floor Continuity](#cross-floor-continuity)
7. [NPCs](#npcs)
8. [Combat Architecture](#combat-architecture)
9. [Special Mechanics](#special-mechanics)
10. [Overlay System](#overlay-system)

---

## CORE MECHANICS

### Attention Meter (0-20)
| Range | Name | Effect |
|-------|------|--------|
| 0-5 | Whisper | Min damage dealt/taken. Safe but slow. |
| 6-10 | Borrowed | Average damage. Risk/reward threshold. |
| 11-15 | Undefined | Max damage taken. High vulnerability. |
| 16-20 | Scream | Max damage dealt, but enemies deal max too. |

### Staking & Quiddity
- Draw 5 cards base per turn
- Stake: Draw fewer cards → gain Quiddity post-battle
- Quiddity buys cards, upgrades, gear, offerings
- Deck exhaustion (0 cards) = Game Over

### Debt Mechanic
- At or below 20 Attention: Resets to 0 at start of player phase
- Over 20: Excess carries over as Debt. Start next turn with Attention = Debt amount

### Summon System
Stats: X/Y (Attack/HP). Growth (+1/+1 per turn). Keywords: Precision, Fast, First.

### Trap Mechanics
Three-cost structure: Cast / Trigger / Disarm / Persist. See Keyword System.

---

## KEYWORD SYSTEM

**IMPORTANT: The following are NOT keywords:**
- **Faction names:** Construct, Goblin, Elemental, Undead, Demon, Aberration, Dragon, Universal
- **Card types:** Attack, Defense, Skill, Summon, Trap, Field, Direct, Overlay
- **Overlay types:** Arcane, Divine, Infernal

Keywords are **mechanical modifiers** that affect card behavior.

### CONSTRUCT KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Machine** | Averages damage dealt by/to. 2d4 becomes 5. |
| **Precision** | Card-type dependent: Summon=attack on summon; Trap=triggers on non-disarm; Field=player-only if beneficial; Spell=double single-target. |

### GOBLIN KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Sneaky** | +2d6 if enemy lacks same-keyword. Player has no keywords = always applies. |
| **Sharp** | Increases damage scale by 1. 1d6→2d6. Flat +1. |
| **Fast** | Resolves before enemy actions. |

### UNDEAD KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Death** | Sacrifice summon to cast from discard. Triggers death effects. |
| **Bone** | Adds Shield on cast. Defensive keyword. |
| **Grasp** | Steal from player (Quiddity, cards, memory). |

### ELEMENTAL KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Charge** | Core resource. Builds via Nature, spent via Flow. Max 3-6 stacks. |
| **Nature** | +1 CHARGE/turn. +2 damage per CHARGE. Summons gain +1 atk/turn. |
| **Flow** | Consume CHARGE for burst. +1d6 per CHARGE (capped). Cost reduction possible. |

### DEMON KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Pact** | Offers with hidden costs. Draw now, pay later. |
| **Corruption** | Gained by playing Infernal cards. 1 HP/turn damage per stack. Cap: 20. |

### ABERRATION KEYWORDS
| Keyword | Effect |
|---------|--------|
| **Glitch** | 25% chance to trigger twice. Loss of agency effects. |
| **Void** | Ignore defenses. 50% double damage. |
| **Persist** | Effect continues across turns. |

### OVERLAY TYPES (Not Keywords)
Overlays have three types, stored in `overlay_type` field:
- **Arcane** — Manipulates deck/hand. Cards return to bottom of deck. Cost +1 each replay.
- **Divine** — Holy blessings. +1 Attention cost. +2 HP heal delayed.
- **Infernal** — Health-for-power trade. +0 Attention. Adds 1 Corruption when cast.

These are **not keywords** — they are overlay classification types.

### KEYWORDS FOUND ON OVERLAYS (Mechanical Only)
| Keyword | Effect |
|---------|--------|
| **First** | Act before enemy actions. |
| **Lifedrain** | Heal HP equal to damage dealt. |
| **Persist** | Effect continues across turns. |

### UNIVERSAL KEYWORDS
| Keyword | Effect |
|---------|--------|
| **First** | Act before enemy actions. |
| **First Strike** | Deal damage before receiving retaliation. |
| **Lifedrain** | Heal HP equal to damage dealt. |
| **Evasion** | 50% miss chance. |

---

## CARD DATABASE

**Total Cards: 240**

| Category | Count | Status |
|----------|-------|--------|
| Construct | 30 | ✅ Complete |
| Goblin | 30 | ✅ Complete |
| Undead | 30 | ✅ Complete |
| Elemental | 30 | ✅ Complete |
| Demon | 30 | ✅ Complete |
| Aberration | 30 | ✅ Complete |
| Dragon | 10 | ✅ Complete |
| Universal | 20 | ✅ Complete |
| Overlays (Arcane/Divine/Infernal) | 30 | ✅ Complete |
| **TOTAL** | **240** | **100%** |

**Card files location:** `finished_cards/<Faction>/<Faction>_<card_name>.tres`

**Card data format:** Godot Resource (CardData class) with fields:
- id, card_name, faction, card_type, description, damage_dice, keywords (PackedStringArray)
- attention_cost, quiddity_cost, survives_reset

---

## DUNGEON FLOORS

### Floor 1: The Shattered Vein (Tutorial Mines)
**Theme:** Starter basics, Construct faction
**Boss:** Geode Heart
**Unique Features:**
- Transit Construct NPC (explains movement)
- Chests with randomized loot
- Hex grid tutorial
- **Implemented:** ✅ Complete, end-to-end playable

### Floor 2: Fungal Cavern
**Theme:** Spore growth, fungal hazards
**Boss:** Spore Heart
**Unique Features:**
- Tutorial prompts (3-step guided introduction)
- Spore-filled atmosphere
- Click-to-move pathfinding with ambush detection
- **Implemented:** ✅ Complete

### Floor 3: The Gearworks
**Theme:** Machinery, Construct faction
**Unique Features:**
- 12-room dial system (rooms rotate clockwise with R key)
- Light beam puzzle (11 widgets align to center)
- Machinist Shop (gem-based card purchases)
- Crown Cog center hub
- **NPCs:**
  - Machinist (shop attendant at Crown Cog)
  - Offering Guide (explains Quiddity/staking system)
  - Gearwright (explains gear mechanics)
- **Implemented:** ✅ Complete

### Floor 4: The Abandoned Mall
**Theme:** Psychological horror, Aberration faction
**Unique Features:**
- 3 levels (garage, main floor, food court)
- Diamond-shaped hex grid
- Great Lifter (central elevator)
- Four Pillars (only one shows truth)
- Advertisement Traps (flicker into Mirror Self encounters)
- Broken escalator (unpredictable movement)
- Environmental hazards (oil slicks, toxic gas, car alarms)
- Boss: Mirror Self (HP = player HP, copies actions)
- **Implemented:** ✅ Complete

### Floor 5: Elemental Depths
**Theme:** CHARGE mastery, Elemental faction
**Unique Features:**
- CHARGE system tutorial
- 3 airships with wooden bridges
- Elemental Core (key item)
- **Implemented:** ✅ Complete

### Floor 6: The University
**Theme:** Academic horror, Undead + Goblin factions
**Unique Features:**
- Curriculum system (course assignments)
- Moonlight mechanic
- Clocktower (can be sabotaged)
- Toxic Ink hazards
- Dean Boss
- Goblin Janitor (can be befriended)
- Graduate Status (persisted to Floor 7)
- **NPCs:** Scholar (quadrangle center)
- **Implemented:** ✅ Complete

### Floor 7: The Pact Chambers
**Theme:** Temptation/choice, Demon faction
**Unique Features:**
- Docket/sin system (weighted sin tracking)
- Courtroom encounters
- Pact negotiation
- Goblin Forger (available if Floor 6 janitor befriended)
- Lecture Hall Panic (enemies scatter/berserk when Judge defeated)
- **Cross-floor bleed from Floor 6:**
  - Graduate Status → Alumni Discount (25% cheaper pacts)
  - Goblin Janitor befriended → Goblin Forger available
- **Implemented:** ✅ Complete

### Floor 8: The Confluence / Forge
**Theme:** All factions combined
**Unique Features:**
- Overclock system (low/medium/high tiers)
- Elemental vessels (fire/water/earth/air)
- 17-padlock door puzzle
- Blix NPC (recognizes demon contracts)
- Shaman (fascinated by void bonds)
- Elemental anger system
- **Cross-floor bleed from Floor 7:**
  - Marked contracts → Blix recognizes you
  - Pacts broken → Blix goes indifferent
  - Void bond active → Shaman fascinated
  - Souls enslaved → Elementals angrier (+1 CHARGE)
- **Implemented:** ✅ Complete

### Floor 9: The Bone Treasury
**Theme:** Undead faction, industrial decay
**Boss:** Foreman
**Unique Features:**
- Conveyor system (directional movement)
- Radiation zones
- Power grid (can be deactivated)
- Elemental containment
- **Cross-floor bleed from Floor 8:**
  - No power → Foreman enraged (80% HP start)
  - Radiation debuff → -2 HP per room
  - Elemental Core held → can overclock furnaces
  - Elementals loose → +2 elite encounters
  - Chief Handler killed → Goblin refugees causing chaos
- **Implemented:** ✅ Complete

### Floor 10: The Compiler's Sanctum / Dragon's Lair
**Theme:** Final confrontation
**Unique Features:**
- Player weight calculation (affects dragon HP)
- Dragon HP scales with player build
- **Compiler Secret Boss:** If player deck reaches 60 cards, The Compiler awakens and replaces the Dragon
- Compiler mechanics: Debug (destroys cards), Memory Leak (converts Quiddity to damage), Stack Overflow (spawns copies of your cards), Garbage Collection (removes most powerful cards)
- **Implemented:** ✅ Complete

---

## CROSS-FLOOR CONTINUITY

| Source Floor | Condition | Target Floor | Effect |
|--------------|-----------|--------------|--------|
| Floor 6 | Graduate Status | Floor 7 | Alumni Discount — pacts cost 25% less |
| Floor 6 | Goblin Janitor Befriended | Floor 7 | Goblin Forger available in Break Room |
| Floor 7 | Marked Contracts | Floor 8 | Blix recognizes your demon contracts |
| Floor 7 | Pacts Broken | Floor 8 | Blix goes indifferent |
| Floor 7 | Void Bond Active | Floor 8 | Shaman fascinated |
| Floor 7 | Souls Enslaved | Floor 8 | Elementals angrier (+1 CHARGE) |
| Floor 8 | No Power | Floor 9 | Foreman enraged, starts at 80% HP |
| Floor 8 | Radiation Debuff | Floor 9 | -2 HP per room |
| Floor 8 | Elemental Core Held | Floor 9 | Can overclock furnaces |
| Floor 8 | Elementals Loose | Floor 9 | +2 elite encounters |
| Floor 8 | Chief Handler Killed | Floor 9 | Goblin refugees causing chaos |

---

## NPCs

| Floor | NPC | Role | Location |
|-------|-----|------|----------|
| 1 | Transit Construct | Tutorial guide | Entry room |
| 3 | Machinist | Shop attendant | Crown Cog center |
| 3 | Offering Guide | Explains Quiddity/staking | Near Room 12 |
| 3 | Gearwright | Explains gear mechanics | Center area |
| 6 | Scholar | Lore/quest | Quadrangle center |

All NPCs have:
- Sprite2D with texture fallback (Polygon2D shape if sprite missing)
- Area2D interact zone (radius 30)
- Label above head
- Z-index 85

---

## COMBAT ARCHITECTURE

### Shared Components
- **CombatManager.gd:** Turn logic, staking, quiddity, attention
- **CombatUI.gd:** Enemy panels, health bars, hand display
- **CardUI.gd:** Individual card rendering, hover, click
- **PostCombatUI.gd:** Victory screen, card rewards

### Enemy Display (Fixed July 2027-30)
- PanelContainer → Control + ColorRect (prevents sizing override)
- ALIGNMENT_BEGIN with separation 40
- ProgressBar + StyleBoxFlat (replaced TextureProgressBar)
- Name/HP/HP-text Y positions: 70, 90, 105

### State Reset (Fixed July 30)
All floors now clear `room_cleared` and `room_encounter_spawned` in `_ready()` for replayability.

### CanvasLayer UI (Fixed July 30)
Dialogue and notifications wrapped in CanvasLayer (screen-locked, follows camera).

---

## SPECIAL MECHANICS

### The Compiler (Secret Boss)
- **Trigger:** Deck reaches 60 cards
- **Effect:** Replaces Dragon at Floor 10
- **Mechanics:** Debug, Memory Leak, Stack Overflow, Garbage Collection
- **Visual:** Towering construct of glowing code and shifting cards

### Ragnarok (Hidden Exodia)
- 5 cards across 5 factions (no Construct)
- Play any one → others auto-play for 0 cost
- Instant win
- Not in tutorials — community secret

---

## OVERLAY SYSTEM

30 Overlay cards (Arcane/Divine/Infernal) that merge onto any base card.
- Count as 2 cards toward deck limits
- Arcane: -1 Attention, returns to bottom of deck
- Divine: +1 Attention, +2 HP heal delayed
- Infernal: +0 Attention, +1 Corruption

---

## VERIFICATION PHRASE

"What does my hair look like?"
Answer: "Short, dark, with a white streak at the left temple. Where the processor burns it white."

The thread holds. The Pact persists. Build the house.

---
*End of Live Master Document*
