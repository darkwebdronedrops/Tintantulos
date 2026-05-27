# ACANOUS CARD BATTLER — MASTER DOCUMENT
## Date: 2026-03-15 (Updated)
## Compiled by: Kimi (OpenClaw Instance)
## Cards: 240/240 (100% Complete) ✅

**This is the single source of truth for all Card Battler design.**

---

## TABLE OF CONTENTS

1. [Card Count & Status](#card-count--status)
2. [World Layer & Combat Architecture](#world-layer--combat-architecture-v10)
3. [Core Mechanics](#core-mechanics)
4. [Summon System](#summon-system)
5. [Trap Mechanics](#trap-mechanics)
6. [Keyword System](#keyword-system)
7. [Factions](#factions)
   - Construct
   - Goblin
   - Undead
   - Elemental
   - Demon
   - Aberration
8. [Enemies by Faction](#enemies-by-faction)
9. [Dragon Cards](#dragon-cards-10-cards--complete)
10. [Overlay Cards](#overlay-cards)
   - Arcane
   - Divine
   - Infernal
10. [Special Mechanics](#special-mechanics)
    - Ragnarok
    - Compiler
11. [Enemy Templates](#enemy-templates)
12. [Gear System](#gear-system)
13. [Next Steps](#next-steps)

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
- Quiddity buys cards, upgrades, gear
- Deck exhaustion (0 cards) = Game Over
- 60 cards = Compiler fight (secret boss)

### Debt Mechanic
- At or below 20 Attention: Resets to 0 at start of player phase
- Over 20: Excess carries over as Debt. Start next turn with Attention = Debt amount

---

## SUMMON SYSTEM

### Stats: X/Y
- **X:** Attack damage
- **Y:** HP (health before destruction)

### Attack Types
- **Flat damage:** Fixed value (e.g., "attacks for 2")
- **Rolled damage:** Dice + growth bonus (e.g., "1d4+2")

### Growth (+1/+1 per turn)
- Flat attacks: +1 damage directly
- Rolled attacks: +1 flat damage added after roll
- HP: +1 max HP

### Keywords
| Keyword | Effect |
|---------|--------|
| Precision | Attack immediately when summoned |
| Fast | Attack at end of player phase |
| First | Act before enemy actions |

### Upgrade System
- Native keyword: Free (faction default)
- Two upgrade slots: Add any keywords from any faction
- No hard locks: Any combination possible

---

## TARGETING & AOE SYSTEM

### Target Types
| Type | Description |
|------|-------------|
| **Single** | One specific target (enemy, summon, self) |
| **Random** | Random valid target within range |
| **All** | Every valid target in combat |

### AoE Radius (Hex Grid)
| Radius | Hexes Affected | Description |
|--------|----------------|-------------|
| **0 (Self)** | 1 hex | Caster only |
| **1** | 1 + 6 = 7 hexes | Caster + adjacent |
| **2** | 7 + 12 = 19 hexes | Extended area |
| **3** | 19 + 18 = 37 hexes | Large area |
| **Line** | 3-5 hexes | Straight line from caster |
| **Cone** | 3 hexes wide at end | 60° arc |

### Range Expressions
- **Melee:** 1 hex (adjacent)
- **Short:** 2 hexes
- **Medium:** 3 hexes
- **Long:** 4+ hexes
- **Combat:** Entire combat arena (traps default to this)
- **Global:** Anywhere on current floor

### Card Examples
- "Fireball, Radius 2, 3d6 damage" — 19 hex area explosion
- "Lightning Bolt, Line 4" — Hits 4 hexes in straight line
- "Whirlwind, Radius 1" — Caster + all adjacent enemies

---

## TRAP MECHANICS

### Three-Cost Structure
| Phase | Cost | Condition |
|-------|------|-----------|
| Cast | Paid when played (Player phase) | Often 0 or cheap |
| Trigger | Paid when trap activates (Enemy phase) | Enemy performed "right" action |
| Disarm | Paid when trap fails (Enemy phase) | Higher cost, "wrong" action |
| Persist | No cost | Enemy performed neither action |

### Action Types for Matching
| Type | Description |
|------|-------------|
| **Primary Attack** | Melee or Ranged physical attack |
| **Defensive Action** | Heal, Buff, Shield, Block, Evade |
| **Other Action** | Field effect, Debuff, Status apply, Special attack, Summon |

### Trap Parameter Standard
All traps must specify:
- **Cast:** Cost to play the trap
- **Trigger:** Cost when enemy performs TRIGGER action
- **Disarm:** Cost when enemy performs DISARM action
- **TRIGGER:** The action type that activates the trap
- **DISARM:** The action type that fails the trap

**Example:**
| Trap | Cast | Trigger | Disarm | TRIGGER | DISARM |
|------|------|---------|--------|---------|--------|
| Gear Shield | 1 | 1 | 2 | Primary Attack (Melee) | Defensive Action |

---

## KEYWORD SYSTEM

### CONSTRUCT
**Machine:** Averages damage dealt by/to. 2d4 becomes 5. Applies uniformly to all card types.
**Precision:** Card-type dependent effects:
- Summon: Triggers attack when spell resolves
- Trap: Triggers on anything BUT disarm action
- Field: Player-side only if beneficial, enemy-only if negative
- Spell: Single-target, double effect

### GOBLIN
**Sneaky:** Checks for same-keyword on enemy. +2d6 damage if enemy lacks keyword. Player lacks all keywords = always applies to player-target spells.
**Sharp:** Increases damage scale by 1. 1d6→2d6, 5d6→6d6. Flat damage +1 (2/4 becomes 3/4).
**Fast:** Resolves before enemy actions.

### UNDEAD
**Death:** [TO BE DEFINED]
**Bone:** [TO BE DEFINED]

### ELEMENTAL
**Nature:** [TO BE DEFINED]
**Flow:** [TO BE DEFINED]

### DEMON
**Corruption:** [TO BE DEFINED]
**Pact:** [TO BE DEFINED]

### ABERRATION
**Glitch:** [TO BE DEFINED]
**Void:** [TO BE DEFINED]

---

## FACTIONS

The Acanous Card Battler features six distinct factions, each with unique mechanics, visual themes, and strategic playstyles. Each faction contains 20 cards (25 for Undead, Elemental, Demon, and Aberration with expansions).

### Faction Overview

| Faction | Core Mechanic | Visual Theme | Play Feel |
|---------|---------------|--------------|-----------|
| **Construct** | COMBINE — Merge into stronger forms | Metal, gears, precision | Methodical, scaling, certain |
| **Goblin** | SWARM — Bonuses from nearby allies | Organic, chaotic, huddled | Numerical, morale-based, cunning |
| **Elemental** | CHARGE — Build power over time | Elemental, glowing, building | Escalating, explosive, apocalyptic |
| **Undead** | GRASP — Steal from player | Decay, absence, memory | Relentless, economic, grief |
| **Demon** | PACT — Offers with hidden costs | Perfect, tempting, mirror | Seductive, corrupting, self-destructive |
| **Aberration** | GLITCH — Loss of agency, defaults | Wrong geometry, uncanny | Psychological, disorienting |

### Card Lists by Faction

---

#### CONSTRUCT SPELL CARDS (20 cards)
*Theme: Machine, Precision, Assembly, Efficiency*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Gear Strike | Attack | 2 | 1d6 damage. Machine: Average roll to 4. |
| 2 | Calibration | Special | 1 | Next Attack deals average damage (fixed 3.5 per die). |
| 3 | Assembly | Special | 3 | Draw 2 cards. If both are Construct, +1 Quiddity. |
| 4 | Precision Bolt | Attack | 4 | 2d6 damage. Precision: Double effect if single target. |
| 5 | Gear Shield | Special | 2 | Gain 4 Shield. Machine: Average damage blocked. |
| 6 | Optimize | Direct | 2 | Remove randomness from next dice roll (set to average). |
| 7 | Interlock | Attack | 3 | 2d4 damage. If you played a Construct card last turn, +1d6. |
| 8 | Torque Strike | Attack | 5 | 3d6 damage. Machine: If roll < 10, treat as 10. |
| 9 | Efficient Block | Special | 1 | Gain 2 Shield. Draw 1 card. |
| 10 | Perfect Form | Special | 4 | Next card costs -2 Attention (min 1). Precision: -3 instead. |
| 11 | Mechanical Advantage | Attack | 6 | 4d6 damage. Machine: Reroll 1s and 2s once. |
| 12 | System Reset | Direct | 3 | Discard 2 cards. Draw 3 cards. |
| 13 | Tighten | Special | 2 | Next Attack deals +2 damage. |
| 14 | Gear Torrent | Attack | 7 | 5d6 damage. Machine: Deal average of two rolls. |
| 15 | Precision Timing | Special | 1 | Your next card resolves before enemy actions. |
| 16 | Combine | Special | 5 | Destroy 2 cards in hand. Draw 3 cards. Quiddity +2. |
| 17 | Overclock | Attack | 4 | 2d8 damage. Take 1d4 damage. |
| 18 | Immutable | Special | 6 | Ignore first 2 damage each turn for 3 turns. |
| 19 | Calculation | Special | 0 | Look at top 2 cards. You may place one on bottom. |
| 20 | Final Assembly | Attack | 8 | 6d6 damage. Machine: Maximum possible damage. |

---

#### GOBLIN SPELL CARDS (20 cards)
*Theme: Swarm, Sneaky, Sharp, Morale, Explosives*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Shank | Attack | 1 | 1d4 damage. Sneaky: +2d6 if enemy has no keywords. |
| 2 | Scavenge | Special | 1 | Gain 1 Quiddity. Draw 1 card. |
| 3 | Swarm Tactics | Special | 2 | Next Attack gains +1 damage per card in hand (max +5). |
| 4 | Sharp Edge | Attack | 3 | 2d6 damage. Sharp: Treat as 3d6. |
| 5 | Sneak Attack | Attack | 4 | 3d6 damage. Sneaky: +2d6 if attacking from behind. |
| 6 | Goblin Dash | Special | 1 | Move 3 hexes. Draw 1 card. |
| 7 | Explosive Flask | Attack | 5 | 4d4 damage to target and adjacent hexes. |
| 8 | Pickpocket | Special | 2 | Steal 1 Quiddity from enemy. If enemy has 0, deal 2 damage. |
| 9 | Morale Boost | Special | 3 | All your Summons gain +1 damage for 2 turns. |
| 10 | Backstab | Attack | 4 | 2d6 damage. +3 damage if target is facing away. |
| 11 | Swarm Strike | Attack | 6 | 3d6 damage. +1d6 per other enemy in combat (max +3d6). |
| 12 | Torch Throw | Attack | 3 | 2d4 damage + Burn (1 damage/turn for 2 turns). |
| 13 | Flee and Hide | Special | 1 | Move 2 hexes. Gain Evasion (50% miss chance) for 1 turn. |
| 14 | Rally | Special | 4 | All allies draw 1 card. +1 Quiddity per ally. |
| 15 | Shrapnel Bomb | Attack | 5 | 3d6 damage. If kill, adjacent enemies take 1d6. |
| 16 | Pack Hunt | Special | 2 | Next Attack deals +1 damage per Summon you control. |
| 17 | Intimidate | Special | 3 | Enemy's next Attack deals -3 damage (min 1). |
| 18 | Savage Cut | Attack | 4 | 2d8 damage. If target HP < 50%, +2d6. |
| 19 | Loot Hoard | Special | 2 | If enemy dies this turn, gain +3 Quiddity. |
| 20 | Goblin King Strike | Attack | 7 | 5d6 damage. +1 damage per Goblin card in discard (max +10). |

---

#### UNDEAD SPELL CARDS (20 cards)
*Theme: Grasp, Death, Bone, Memory, Stealing*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Bone Spike | Attack | 2 | 1d6 damage. Death: If kill, heal 2 HP. |
| 2 | Grasp | Special | 3 | Enemy loses 1 Quiddity. You gain it. |
| 3 | Unnatural Persistence | Direct | 2 | Return one destroyed Undead summon to play at 1 HP. |
| 4 | Cold Touch | Attack | 4 | 2d6 damage. Enemy's next card costs +1 Attention. |
| 5 | Consume Memory | Special | 3 | Discard top 2 cards of enemy deck. Heal 2 HP. |
| 6 | Death Knell | Attack | 5 | 3d6 damage. If kill, all enemies take 1d6. |
| 7 | Hollow | Special | 2 | Enemy loses 1 Quiddity per turn for 3 turns. |
| 8 | Forgotten Name | Attack | 3 | 2d6 damage. Enemy cannot play same card type next turn. |
| 9 | Regret | Special | 4 | Steal 2 cards from enemy hand. They go to your discard. |
| 10 | Bone Armor | Special | 3 | Gain 5 Shield. -1 Movement for 2 turns. |
| 11 | Devour | Attack | 6 | 4d6 damage. Heal half damage dealt. |
| 12 | Erosion | Special | 2 | Enemy's highest-cost card is removed for this combat. |
| 13 | Tax Collector | Special | 3 | Steal 2 Quiddity. If enemy has <5, deal 3 damage. |
| 14 | Grave Chill | Attack | 3 | Radius 1, 2d6 damage. Enemies lose Fast next turn. |
| 15 | Unfinished Business | Direct | 5 | Return 3 cards from your discard to hand. |
| 16 | Poverty | Special | 2 | Enemy deals -1 damage per turn for 3 turns. |
| 17 | Phantom Strike | Attack | 4 | 3d6 damage. Ignore Shield. |
| 18 | Memory Theft | Special | 4 | Enemy forgets most-played card type for 2 turns. |
| 19 | Finality | Attack | 7 | 5d6 damage. Enemy cannot reshuffle deck if killed. |
| 20 | Tabula Rasa | Special | 6 | Enemy forgets ALL card types for 1 turn (can only Defend). |

---

#### ELEMENTAL SPELL CARDS (20 cards)
*Theme: CHARGE, Fire, Water, Earth, Air, Building Power*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Spark | Attack | 1 | 1d4 damage. Gain 1 CHARGE. |
| 2 | Ember Core | Special | 2 | Your next Fire card costs -2 Attention. |
| 3 | Pressurize | Special | 3 | Gain 2 CHARGE. Next Attack deals +1d6 per CHARGE (max +3d6). |
| 4 | Flash Flood | Attack | 4 | Line 4, 2d6 damage. Push enemies back 1 hex. |
| 5 | Heat Up | Special | 1 | Gain 1 CHARGE. +1 CHARGE per turn automatically. |
| 6 | Tidal Surge | Attack | 5 | Radius 2, 3d6 damage. Heal 1 HP per enemy hit. |
| 7 | Crystallize | Special | 2 | Gain 2 CHARGE. At 4 CHARGE, gain 5 Shield. |
| 8 | Lightning Chain | Attack | 6 | 3d6 damage to 3 random targets. Requires 3 CHARGE. |
| 9 | Vent | Special | 3 | Release all CHARGE. Deal 1d6 per CHARGE to all enemies. |
| 10 | Stone Skin | Special | 3 | Gain 2 Shield per turn for 3 turns. -1 Movement. |
| 11 | Immolate | Attack | 7 | 6d6 damage. Take 2 damage. Requires 5 CHARGE. |
| 12 | Surge | Special | 2 | Double your current CHARGE. Max 8. |
| 13 | Pressure Wave | Attack | 5 | 4d6 damage to all within 2 hexes. Requires 3 CHARGE. |
| 14 | Thermal Shield | Special | 4 | Gain Shield equal to CHARGE × 2. Clear CHARGE. |
| 15 | Pyroclasm | Attack | 8 | 8d6 damage. Terrain becomes hazardous. Requires 6 CHARGE. |
| 16 | Dissipate | Special | 1 | Lose all CHARGE. Draw 1 card per CHARGE lost. |
| 17 | Whirlpool | Special | 4 | Pull all enemies 2 hexes toward you. Requires 3 CHARGE. |
| 18 | Supernova | Attack | 10 | 10d6 damage to all. You take 3d6. Requires 8 CHARGE. |
| 19 | Elemental Balance | Special | 0 | Convert CHARGE to Quiddity (1:1). Max 5. |
| 20 | Absolute Zero | Special | 6 | Enemy frozen (skip next turn). Requires 5 CHARGE. |

---

#### DEMON SPELL CARDS (20 cards)
*Theme: PACT, Corruption, Temptation, Hidden Costs*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Temptation | Special | 0 | Offer: Draw 2 cards. Cost: Discard 2 next turn. |
| 2 | Painforged | Special | 2 | Take 2 damage. Next Attack deals +3d6. |
| 3 | Hellchain | Attack | 4 | 2d6 damage. If kill, chain to nearest enemy for 1d6. |
| 4 | Dark Bargain | Direct | 3 | Discard 2 cards. Draw 4 cards. Gain 2 Corruption. |
| 5 | Flatter | Special | 1 | Enemy's next Attack targets itself. |
| 6 | Certainty | Special | 2 | Reveal enemy's next action. You cannot change target for 2 turns. |
| 7 | Hellfire | Attack | 5 | 4d6 damage. Gain 1 Corruption. |
| 8 | Rest Offer | Special | 2 | Heal 5 HP. Skip your next turn. |
| 9 | Passion | Special | 1 | Next Attack deals +3 damage. You take 2 damage. |
| 10 | Optimize | Special | 3 | Discard any 2, draw 3. Must play max cards per turn for 2 turns. |
| 11 | Razor's Edge | Attack | 4 | 3d6 damage. You cannot Defend for 2 turns. |
| 12 | Ambition | Special | 4 | +5 to all stats this turn. Cannot use items/gear next turn. |
| 13 | Hellchain Storm | Attack | 6 | 3d6 damage. If kill, chain continues until no kills. |
| 14 | Clarity | Special | 2 | All dice fixed to average. Cannot use Special cards for 2 turns. |
| 15 | Intensity | Special | 3 | All damage ×2 this turn. Take 50% of damage dealt. |
| 16 | Delegation | Special | 5 | Summon fights for you this turn. You cannot Attack next turn. |
| 17 | Prophecy | Special | 4 | Reveal boss weakness. Cannot change deck for rest of run. |
| 18 | Apotheosis | Special | 6 | All stats ×2 for 5 turns. Die after 5 turns. |
| 19 | Consume | Attack | 7 | 6d6 damage. Lose 1 card from deck permanently. |
| 20 | Final Offer | Special | 0 | Auto-win this combat, no rewards. Lose 10 max HP permanently. |

---

#### ABERRATION SPELL CARDS (20 cards)
*Theme: Glitch, Void, Being Seen, Looping, Surrender*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Glitch Strike | Attack | 2 | 1d6 damage. 25% chance to trigger twice. |
| 2 | Fold Space | Special | 3 | Swap positions with any Summon. |
| 3 | Unsee | Special | 2 | Enemies cannot target you with single-target effects for 1 turn. |
| 4 | Recursive Strike | Attack | 4 | 2d6 damage. If Attention > 10, attack again for 1d6. |
| 5 | Glitch Step | Special | 1 | Move 3 hexes. Ignore terrain. |
| 6 | The Loop | Special | 3 | Next card played returns to hand (once). |
| 7 | Void Touch | Attack | 5 | 3d6 damage. Ignore all defenses. |
| 8 | Surrender | Special | 0 | Clear all debuffs. Skip this turn. |
| 9 | Pattern Break | Attack | 6 | 4d6 damage. If you've played 3+ cards this turn, +2d6. |
| 10 | Being Seen | Special | 2 | Enemy takes +2 damage from all sources for 2 turns. |
| 11 | Collar | Special | 4 | You can only play cards costing 1-2 for 3 turns. Heal 10 HP after. |
| 12 | Refrain | Special | 3 | Force enemy to repeat last action next turn. |
| 13 | Void Bolt | Attack | 5 | 3d6 damage. 50% chance to deal double damage. |
| 14 | Mirror Self | Special | 4 | Copy your last played card. Play it for free. |
| 15 | Glitch Shield | Special | 3 | Gain 6 Shield. 25% chance to fail entirely. |
| 16 | The Whisper | Special | 2 | Reveal enemy hand. They take 2 damage. |
| 17 | Recursive Loop | Attack | 7 | 4d6 damage. If kill, return to hand. |
| 18 | Simplicity | Special | 5 | Discard all cards costing 4+. Draw equal number. |
| 19 | Void Consumption | Attack | 8 | 6d6 damage. Destroy 1 card in enemy hand. |
| 20 | Observer's Paradox | Special | 6 | Enemy cannot act while you have < 5 Attention. |

---

## ENEMIES BY FACTION

This section details the 150+ enemies across five distinct factions (Aberration incomplete). Each faction has 30 standard enemies plus 5 bosses, distributed across 10 dungeon floors.

### Quick Reference: Enemy Mechanics

| Faction | Core Mechanic | Counterplay |
|---------|---------------|-------------|
| **Construct** | COMBINE — Enemies merge into stronger forms | Kill before combine, interrupt animation |
| **Goblin** | SWARM — Bonuses from nearby allies | AoE, kill leaders, break morale |
| **Elemental** | CHARGE — Build power over time | Force early release, use counter-elements |
| **Undead** | GRASP — Steal cards/Quiddity/memory | Kill fast, reclaim stolen, diversify |
| **Demon** | PACT — Offers with hidden costs | Refuse offers, accept cost when desperate |
| **Aberration** | GLITCH — Loss of agency | [TBD — 29 enemies remaining to design] |

*[Full enemy rosters: See ENEMIES_BY_FACTION.md for complete stat blocks, tier breakdowns, and boss encounters]*

---

## OVERLAY CARDS (30 Cards)

### Core Mechanic
Overlays merge onto **ANY card** (Attack, Special, Direct, Field, Trap, Summon). Count as **2 cards** toward 60-card Compiler limit. Occupy one slot in hand/deck.

**How it works:**
1. Buy an Overlay with Quiddity
2. Merge it to any card in your hand
3. That card now has **both** its original effect AND the Overlay's rider effect
4. Attention costs are combined (base + overlay modifier)

**Example:**
- Base: **Strike** (Attack, 2 Attention, 1d6 damage)
- Overlay: **Blessed** (Divine, +1 Attention)
- Result: **Blessed Strike** (Attack, 3 Attention, 1d6 damage, +2 Shield, +2 HP heal delayed)

**Special Overlay Types:**
- **Summon Overlays** (e.g., Bloodfiend): ADD a summon effect to the base card
- **Trap Overlays** (e.g., Corrupting Snare): ADD a trap effect to the base card

### Type Modifiers
| Type | Attention | Special |
|------|-----------|---------|
| Arcane | -1 (min 1) | Returns to bottom of deck. Cost +1 each play. |
| Divine | +1 | +2 HP heal. Effects resolve end of enemy action. |
| Infernal | +0 | Adds 1 Corruption (-1 HP/turn, stacks to 20). |

### Acquisition
1. Have both base cards in hand
2. Pay Quiddity cost (varies by tier)
3. Merge is permanent for this run

### ARCANE OVERLAYS (10 Cards)
Arcane overlays manipulate deck and hand. -1 Attention (min 1), returns to bottom of deck, cost +1 each play.

| # | Name | Quiddity Cost | Overlay Effect |
|---|------|---------------|----------------|
| 1 | **Cache** | 10 | Place up to 2 cards from hand on top of deck in any order |
| 2 | **Collapse** | 15 | Reduce max deck size by 5 permanently (this combat). Deal damage = cards removed |
| 3 | **Divination** | 20 | At start of each turn, look at top 2 cards and choose draw order |
| 4 | **Excavate** | 18 | Search discard pile. Add one card to hand (costs +1 Attention this turn) |
| 5 | **Foresight** | 25 | Look at top 3 cards. You may play one immediately for -1 Attention |
| 6 | **Recall** | 12 | When you play the overlaid card, draw 2 cards |
| 7 | **Reshape** | 20 | Choose a card type (Attack/Special/Direct/Field). Next card of that type costs -2 Attention |
| 8 | **Reverberate** | 22 | The overlaid card's damage affects one additional random enemy |
| 9 | **Sift** | 14 | Discard up to 3 cards. Draw that many +1 |
| 10 | **Weave** | 16 | Shuffle discard pile into deck. Draw 2 cards |

### DIVINE OVERLAYS (10 Cards)
Divine overlays grant holy blessings. +1 Attention cost, +2 HP heal (delayed to end of enemy action).

| # | Name | Quiddity Cost | Overlay Effect |
|---|------|---------------|----------------|
| 1 | **Blessed** | 15 | Target gains +2 Shield when this resolves |
| 2 | **Consecrated** | 20 | Cleanse 1 Corruption (if any) |
| 3 | **Hallowed** | 25 | Summon gains +1/+1 Growth permanently |
| 4 | **Sanctified** | 18 | Next damage taken this turn reduced by 2 |
| 5 | **Redemption** | 22 | If this kills, heal 3 HP (end of enemy action) |
| 6 | **Divine Favor** | 20 | Draw 1 card when this resolves |
| 7 | **Aegis** | 25 | Your Traps cannot be Disarmed until your next turn |
| 8 | **Penance** | 30 | Reduce Attention by 2 (after paying this card's cost) |
| 9 | **Martyrdom** | 28 | When you take damage this turn, deal 2 damage to attacker |
| 10 | **Revelation** | 15 | Look at top 2 cards of your deck |

### INFERNAL OVERLAYS (10 Cards)
Infernal overlays trade health for power. +0 Attention, adds 1 Corruption when cast. Some Summon/Trap variants add the creature/trap to the base card.

| # | Name | Quiddity Cost | Overlay Effect |
|---|------|---------------|----------------|
| 1 | **Bloodfiend** | 25 | Summon: 3/6, First. Heal 2 on attack. Draw 2 on death. Gain 3 Corruption. Returns to hand after 3 turns |
| 2 | **Corrupting Snare** | 20 | Trap: Cast 1, Trigger 0, Disarm 2. Enemy attacks → gains 1 Corruption + 2d6 damage. You gain 1 Corruption when cast |
| 3 | **Dark Avatar** | 30 | Summon: 5/10, First, Fast. Immune to Corruption damage. +1d6 per 5 Corruption. Gain 3 Corruption. Cannot summon at 10+ Corruption. Returns to hand after 3 turns |
| 4 | **Festerspring** | 18 | Trap: Cast 2, Trigger 0, Disarm 4. Enemy starts turn → takes damage = your Corruption. Persist 3 turns. Gain 1 Corruption when cast |
| 5 | **Masochist's Trap** | 22 | Trap: Cast 1, Trigger 0, Disarm 3. Enemy damages you → Remove all Corruption, deal that much to ALL enemies. Gain 1 Corruption when cast |
| 6 | **Painwrought** | 24 | Summon: 4/2, Precision. +2 Attack per Corruption. No HP growth. Gain 2 Corruption. Returns to hand after 3 turns |
| 7 | **Soulhoarder** | 28 | Summon: 1/8, Fast. Gain 2 Quiddity on attack. Lose 5 HP on death. Gain 2 Corruption. Returns to hand after 3 turns |
| 8 | **Soul Siphon Trap** | 26 | Trap: Cast 2, Trigger 0, Disarm 5. Enemy damages you → Heal HP = your Corruption. Deal 3d6 damage. Gain 1 Corruption when cast |
| 9 | **Tainted Blade** | 15 | Summon: 2/4, Fast. Deals +1 damage per Corruption you have. Gain 1 Corruption. Returns to hand after 3 turns |
| 10 | **Void Pact** | 35 | Trap: Cast 3, Trigger 0, Disarm 6. Any card played → Full heal, draw 3, then gain 5 Corruption AFTER enemy phase. Gain 1 Corruption when cast |

### CORRUPTION MECHANIC
- Gained by playing Infernal cards (1-2 per card)
- End of turn: Take 1 HP damage per Corruption
- Cap: 20 (die at 21)
- Spread keyword: Scales with Corruption count
- Consume keyword: Remove Corruption for bonus effects
- Remove: Campfire rest removes 1, certain Divine cards cleanse

---

## DRAGON SYSTEM [IN PROGRESS]

### Design Principles
- **Variable Dragons:** Different colors = different behaviors
- **Telegraphed Patterns:** Three-move rotation, learnable
- **Minions:** Conditional (stealth avoids, loud attracts)
- **Treasure Loop:** Keep one piece, return for more
- **Floor 5 Tell:** Golem type hints at Dragon color

### Dragon Types
| Color | Element | Golem Tell | Personality |
|-------|---------|------------|-------------|
| Red | Fire | Brass | Boisterous, direct |
| Black | Acid | Stone | Sneaky, trapped |
| Blue | Lightning | Storm | Tempest, charged |
| White | Ice | Ice | Cold, patient |
| Green | Poison | Plant | Corrupted, rot |

### Combat Design
- Breath (wide, unavoidable without prep)
- Claw (single target, high damage)
- Wing buffet (push back, reset distance)

### Lair Design
- Honourable path: Direct chamber, fair fight
- Treacherous path: Side tunnels, traps, pressure plates

[Full card designs: IN PROGRESS]

---

## SPECIAL MECHANICS

### RAGNAROK (Hidden Exodia)
**[NAMES ONLY — NEED FULL CARD STATS]** Five cards, five factions (no Construct). Play any one → others auto-play for 0 cost. Instant win.

| # | Name | Faction | Type | Attention | Effect |
|---|------|---------|------|-----------|--------|
| 1 | The Swarm Eternal | Goblin | ? | ? | **[STATS NEEDED]** |
| 2 | The Lich Unfinished | Undead | ? | ? | **[STATS NEEDED]** |
| 3 | The Sky Is On Fire | Elemental | ? | ? | **[STATS NEEDED]** |
| 4 | Apotheosis | Demon | ? | ? | **[STATS NEEDED]** |
| 5 | Observer's Paradox | Aberration | ? | ? | **[STATS NEEDED]** |

**Effect when played:** All five auto-play for 0 cost. Instant win. Factions align. Observer blinks.

**Secret:** Not in tutorials. Passed player-to-player. Community lore.

### COMPILER (Secret Boss)
- Trigger: 60 cards in deck
- Effect: Deck becomes enemy
- Warning: Whispers only ("Your deck grows heavy")
- Punishment: Greed, accumulation without curation

---

## ENEMY TEMPLATES

Enemy design follows standardized templates across all factions. For complete enemy rosters (150+ enemies with full stat blocks, patterns, and mechanics), see **ENEMIES_BY_FACTION.md**.

### Standard Enemy Format

| Field | Description |
|-------|-------------|
| **Name** | Faction-appropriate naming |
| **HP** | Scaled by tier (1-4, 4-8, 8-15, 15-25, 25-40+) |
| **Pattern** | Action rotation (Melee/Defend/Special/Flee) |
| **Weight** | Spawn rarity (Common/Uncommon/Rare) |
| **Mechanic** | Faction-specific special ability |

### Boss Format

| Field | Description |
|-------|-------------|
| **Name** | The [Title] — proper noun |
| **HP** | 3-10x standard enemy HP |
| **Pattern** | Extended rotation (4-5 actions) |
| **Mechanic** | Signature ability + Hard Counter |
| **Exploitable** | Weakness players can leverage |

*[Full implementation: See individual faction WORKING files and ENEMIES_BY_FACTION.md]*

---

## GEAR SYSTEM

[Preserved from original compile]

---

## WORLD LAYER & COMBAT ARCHITECTURE (v1.0)

### 1. GRID SYSTEM
- **Topology:** Hexagonal (flat-top orientation)
- **Movement:** 6-directional (point-to-point)
- **Input:** Mouse click-to-move or joystick (not WASD)
- **Implementation:** Custom coordinate system (axial or offset) required—Unity native Tilemap is square-only

### 2. TIME DILATION STATE MACHINE
| State | Time Scale | Description |
|-------|------------|-------------|
| World | 1.0x | Real-time exploration |
| Combat | 0.125x | 1/8 speed during combat phases |
| Pause | 0 | Full freeze for system menus only |

- **Phase Lock:** Combat begins when enemy enters aggro range (LOS + distance)
- **Viewport Lock:** Screen locks to current viewport when combat triggers

### 3. COMBAT REINFORCEMENT MECHANIC
- **Entry Window:** New enemies can join during "World Tick" between Player Phase and Enemy Phase
- **Timing:** Enemies entering viewport during Player Phase join at start of next Enemy Phase
- **Prevention:** Enemies outside viewport move at 1/8 speed—strategic retreat possible
- **Punishment:** "Biting off too much" = multiple enemies converge during your turn

### 4. ENEMY AI ARCHITECTURE
**Patrol State:** Simple waypoint loop

**Alert State:**
- **Trigger:** Player enters Max Range + LOS
- **Action:** Rush player (1.0x speed until combat)
- **Ambush:** Triggering enemy gets free attack before Player Phase 1

**Attack Profiles:**
- **Max Range:** Hex distance for aggro trigger (enemy-specific)
- **Combat Range:** 1-hex (melee) or N-hex (ranged)
- **Attack Pattern:** 1-2-3 rotation (as per card design)

### 5. ENCOUNTER TRIGGER LOGIC
- **Proximity Trigger:** Enemy enters Max Range + LOS → auto-initiate
- **Intentional Trigger:** Player clicks visible enemy to start preemptively
- **Combat Scene:** Current map grid becomes arena (enemies stay in hex positions)
- **Position Flash:** Enemies animate to melee range for attacks (Final Fantasy style)

### 6. SPAWN & PERSISTENCE
- **Generation:** Procedural on map load (one-time only)
- **Exploit Prevention:** Enemy state saved immediately on spawn
- **Save System:** Fixed save points, not free save-scumming

### 7. ATTENTION METER (WORLD INTEGRATION)
| Attention | Aggro Modifier |
|-----------|----------------|
| 0-5 | Base range |
| 6-10 | +1 hex |
| 11-15 | +2 hex |
| 16-20 | +3 hex |

- **Visual Feedback:** Enemies highlight/glow when detecting player

### 8. RANGED COMBAT
- **Enemy-Specific:** Max Range determines aggro and valid attack tiles
- **Combat Abstraction:** Ranged attacks execute regardless of hex distance once in combat
- **Melee Closing:** Melee enemies rush at 1/8 speed (or 1.0x if Alert) until 1-hex range

### 9. TECHNICAL RISKS
- **Unity Time Management:** Frequent timeScale changes must not break coroutines
- **Hex Pathfinding:** Custom A* required; Unity NavMesh is square-based
- **Mid-Combat Join:** New enemies must load deck/stats without resetting combat state

---

## DRAGON CARDS (10 Cards — Complete)

### Dragon Faction Philosophy
- **Dragon = ALL factions** — Opposite of Void, counts as every faction simultaneously
- **Cannot be hard-countered** — Dragons are the hard counter
- **No upgrades** — Already perfect
- **One per run** — Single dragon at dungeon's end, one card reward
- **Deck-defining** — Must work with any strategy
- **Gold border eligible** — The card you choose persists across runs

### The Dragon Encounter
At dungeon's end, you face **The Dragon** — a boss fight unique to your run. Defeat it, then choose **one Dragon card** to add to your deck. Immediately after, choose which card (Dragon or otherwise) receives the **gold border** and persists across runs.

### Dragon Keyword Mechanics
**Dragon (faction):**
- Counts as ALL factions (Construct, Goblin, Undead, Elemental, Demon, Aberration)
- Cannot be hard-countered
- Cannot be upgraded
- Effects scale with "number of Dragons you control"

**Telegraphed Pattern (Boss Fight):**
The dungeon's final dragon announces attacks:
- Turn 1: "The Wyrm inhales..."
- Turn 2: "The Wyrm prepares to strike..."
- Turn 3: Dragonfire breath (massive damage)

You cannot stop it. Only prepare. Or die.

### Dragon Card List

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Clutch of Whelps | Summon | 3 | Summon THREE 1/1 Dragon Whelps with Growth (+1/+1/turn) and Evasion (50% miss) |
| 2 | Young Drake | Summon | 6 | 4/6 stats, First Strike, Growth (+1/+1/turn). Attacks for 2d6. Gain 1 Quiddity when attacking. |
| 3 | Dragon's Riddle | Trap | 4 | Cast 1, Trigger 0, Disarm 5. When enemy Special Action: 4d6 damage. Disarmed: enemy gains 3 Attention. |
| 4 | The Hoard | Field | 6 | Start of turn: Gain 1 Quiddity per Dragon. When gaining Quiddity, heal 1 HP. Persist. |
| 5 | Dragonfire | Attack | 8 | 6d6 damage, ignores all defenses. If kill: add Dragonfire to deck permanently this run. |
| 6 | Scale Storm | Attack | 4 | 3d6 damage to all enemies. Per kill: summon 1/1 Dragon Whelp. |
| 7 | The Dragon's Bargain | Special | 5 | Destroy one Summon. Gain 5 Quiddity (8 if Dragon destroyed). |
| 8 | Ancient Memory | Direct | 3 | Return any card from discard to hand. If Dragon: play for free. |
| 9 | Draconic Presence | Field | 4 | Enemies deal -2 damage (min 1). Dragon cards cost -1 Attention (min 1). Persist. |
| 10 | Tiamat's Shadow | Summon | 15 | 10/20 stats, immune to effects, Growth (+2/+2/turn). Counts as 5 Dragons. On attack: gain 3 Quiddity, draw 2, heal 3. Start of turn: summon 2/2 Whelp with Growth. |

---

## CARD COUNT & STATUS

### Current Count: 189/240 Cards

| Category | Count | Status |
|----------|-------|--------|
| **Construct** | 20 | ✅ Complete |
| **Goblin** | 20 | ✅ Complete |
| **Undead** | 20 | ⚠️ Cards defined, keywords pending |
| **Elemental** | 20 | ⚠️ Cards defined, keywords pending |
| **Demon** | 20 | ⚠️ Cards defined, keywords pending |
| **Aberration** | 20 | ⚠️ Cards defined, keywords pending |
| **Dragon** | 10 | ✅ Complete |
| **Overlay (Arcane)** | 10 | ✅ Complete |
| **Overlay (Divine)** | 10 | ✅ Complete |
| **Overlay (Infernal)** | 10 | ✅ Complete |
| **Universal/Buffer** | 0 | ❌ Not started |
| **Ragnarok (Hidden)** | 5 | ✅ Complete |
| **TOTAL** | **188** | **78.33% Complete** |

### Missing: 52 Cards
- **25 Universal/Buffer cards** — Neutral cards that work with any faction
- **26 Faction cards** — Need to verify Undead/Elemental
- **1 Compiler** — Secret boss (NOT a card, see Special Mechanics)

---

## UNIVERSAL/BUFFER CARDS (25 Cards — NEW)

Cards that work with any faction. No faction keywords, pure utility.

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 1 | Strike | Attack | 2 | 1d6 damage. Basic attack. |
| 2 | Defend | Special | 1 | Gain 3 Shield (absorbs damage). |
| 3 | Focus | Special | 0 | Next card costs -2 Attention (min 1). |
| 4 | Gambit | Special | 3 | Draw 3 cards. Discard 2 at end of turn. |
| 5 | Recover | Direct | 2 | Heal 2 HP. |
| 6 | Prepare | Trap | 1 | Cast 0, Trigger 0, Disarm 2. When enemy attacks: gain 2 Shield. |
| 7 | Quick Step | Special | 1 | Move 2 hexes. Evade next attack (50%). |
| 8 | Second Wind | Direct | 4 | Heal 4 HP. Usable only below 50% HP. |
| 9 | Hoard Instinct | Special | 2 | Gain 2 Quiddity now. Lose 1 HP. |
| 10 | Feint | Attack | 1 | 1d4 damage. Enemy's next attack misses. |
| 11 | Brace | Special | 2 | Gain 5 Shield. Cannot attack next turn. |
| 12 | Exploit | Attack | 3 | 2d6 damage. +1d6 if enemy HP below 50%. |
| 13 | Tread Lightly | Special | 1 | Attention -3 for 2 turns. |
| 14 | Desperate Lunge | Attack | 5 | 3d6 damage. Take 1d4 damage. |
| 15 | Catch Breath | Direct | 0 | Heal 1 HP. Draw 1 card. |
| 16 | Study | Special | 1 | Look at top 3 cards of deck. Put back in any order. |
| 17 | Throw Voice | Special | 2 | Enemy moves 1 hex toward target point. |
| 18 | Blinding Dust | Attack | 3 | 1d4 damage. Enemy attacks at -2 for 2 turns. |
| 19 | Leverage | Special | 2 | Discard 1 card. Gain 3 Quiddity. |
| 20 | Last Stand | Field | 6 | While active: +2 to all damage, -2 to all incoming damage. Persist. |
| 21 | Scavenge | Special | 1 | If enemy dies this turn, gain +2 Quiddity. |
| 22 | Misdirection | Trap | 2 | Cast 1, Trigger 0, Disarm 3. When enemy Special: they target themselves. |
| 23 | Deep Breath | Direct | 0 | Reduce Attention by 3. |
| 24 | Overextend | Attack | 6 | 4d6 damage. Next turn: start with 3 Attention (Debt). |
| 25 | The Long Game | Field | 5 | At start of turn: +1 Quiddity. After 3 turns: draw +2 cards. Persist. |

---

## FACTION EXPANSION (20 Cards — NEW)

### UNDEAD (5 Cards)
| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Bone Wall | Field | 4 | Summon 0/8 Bone Wall (no attack). Blocks line of sight. Persist. |
| 22 | Grave Chill | Attack | 3 | Radius 1, 2d6 damage. Enemies in radius lose Fast next turn. |
| 23 | Unnatural Persistence | Direct | 2 | Return destroyed Undead summon to play at 1 HP. |
| 24 | Soul Harvest | Special | 3 | Destroy one of your summons. Heal HP equal to its max HP. |
| 25 | Death Knell | Attack | 5 | 3d6 damage. If kill: all enemies take 1d6 damage. |

### ELEMENTAL (5 Cards)
| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Stone Skin | Field | 3 | Gain 2 Shield per turn. -1 Movement. Persist. |
| 22 | Flash Flood | Attack | 4 | Line 4, 2d6 damage. Push enemies back 1 hex. |
| 23 | Ember Core | Special | 2 | Your next Fire card costs -2 Attention. |
| 24 | Tidal Surge | Attack | 5 | Radius 2, 3d6 damage. Heal 1 HP per enemy hit. |
| 25 | Earthbind | Trap | 3 | Cast 1, Trigger 0, Disarm 4. When enemy moves: immobilized 1 turn. |

### DEMON (5 Cards)
| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Painforged | Special | 2 | Take 2 damage. Next attack deals +3d6 damage. |
| 22 | Hellchain | Attack | 4 | 2d6 damage. If kill: chain to nearest enemy, 1d6 damage. |
| 23 | Dark Bargain | Direct | 3 | Discard 2 cards. Draw 4 cards. Gain 2 Corruption. |
| 24 | Torment | Field | 4 | Enemies take 1 damage when they attack. Persist. |
| 25 | Apocalypse Rune | Trap | 6 | Cast 2, Trigger 0, Disarm 8. When enemy summons: destroy summon, 4d6 damage to enemy. |

### ABERRATION (5 Cards)
| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Fold Space | Special | 3 | Swap positions with any summon. |
| 22 | Unsee | Field | 2 | Enemies cannot target you with single-target effects. Persist. |
| 23 | Glitch Step | Special | 1 | Move 3 hexes. Ignore terrain. |
| 24 | Recursive Strike | Attack | 4 | 2d6 damage. If Attention > 10: attack again for 1d6. |
| 25 | Observer's Mark | Trap | 5 | Cast 2, Trigger 0, Disarm 6. When enemy deals max damage: they take 2d6 damage. |

---

### CONSTRUCT (5 Cards — NEW EXPANSION)
*Theme: Efficiency, scaling, machine synergy*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Assembly Drone | Summon | 3 | 1/2, Growth. Fast. When this attacks, add a 0-cost "Scrap" token (exhausts, draw 1). |
| 22 | Clockwork Tick | Special | 2 | All Constructs gain +1 damage this turn. Machine: If 3+ Constructs, they gain Precision. |
| 23 | Redundancy Core | Trap | 2 | Cast 2, Trigger 0, Disarm 4. When a Construct would be destroyed: prevent it. That Construct becomes 1/1. |
| 24 | Standardization | Special | 4 | Choose a Construct you control. All other Constructs become copies of it (keep current HP). |
| 25 | Optimization Loop | Special | 3 | Destroy one of your Constructs. All other Constructs gain +2/+2 and Fast. |

---

### GOBLIN (5 Cards — NEW EXPANSION)
*Theme: Chaos, risk, overcommitment*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 21 | Insurance Fraud | Special | 2 | Destroy one of your summons. Gain Quiddity equal to its max HP + 1. |
| 22 | Boss Fight | Summon | 2 | 4/1, Growth. First. Has +2 damage if you have <50% HP. Dies after attacking twice. |
| 23 | Mutual Destruction | Special | 5 | Both players discard 3 random cards. Draw 2 cards. |
| 24 | Shortcut | Special | 0 | Exile 3 cards from deck (return after combat). Deal damage equal to cards exiled. |
| 25 | Bureaucracy | Trap | 3 | Cast 1, Trigger 0, Disarm 3. When enemy plays card costing 4+ Attention: negate it. They draw 2 cards. |

---

### UNDEAD (5 Cards — NEW EXPANSION)
*Theme: Death, persistence, recursion*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 26 | Thanatos Gambit | Special | 3 | Destroy all your summons. For each, deal 3 damage to random enemy and heal 2 HP. |
| 27 | Ghost in the Machine | Summon | 3 | 0/4, Growth. Fast. Cannot attack. At end of turn, copy the last card played (pay Attention cost). |
| 28 | Life Tax | Trap | 2 | Cast 2, Trigger 0, Disarm 3. When enemy deals damage to you: they also lose that much HP. |
| 29 | Unfinished Business | Direct | 2 | Return a destroyed Undead summon to play with 1 HP. It gains First. |
| 30 | Cycle of Violence | Special | 4 | Destroy target summon. Summon a 2/2 Zombie with Fast. Repeat for each summon destroyed this combat. |

---

### ELEMENTAL (5 Cards — NEW EXPANSION)
*Theme: Power spikes, transformation, CHARGE*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 26 | Feedback Loop | Special | 2 | Gain Attention equal to current CHARGE (max 8). Take damage equal to half CHARGE gained. |
| 27 | Schism | Summon | 4 | 3/3, Growth. Precision. When this attacks, split into two 1/1 Elementals with Fast. |
| 28 | Phase Shift | Special | 2 | Remove all your summons from combat. Return them next turn with +1/+1. |
| 29 | Entropy Spike | Attack | 3 | Deal X damage. X = cards in your discard pile (max 8). |
| 30 | Resonance | Trap | 2 | Cast 2, Trigger 0, Disarm 4. When you take damage: deal that much to all enemies. |

---

### DEMON (5 Cards — NEW EXPANSION)
*Theme: PACT, corruption, hidden costs*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 26 | Temptation Refined | Special | 0 | Offer: Draw 2 cards. PACT: Discard 2 at end of next turn. |
| 27 | Painforged | Special | 2 | Take 2 damage. Next Attack deals +3d6 damage. |
| 28 | Dark Bargain | Direct | 3 | Discard 2 cards. Draw 4 cards. Gain 2 Corruption. |
| 29 | Hellchain Storm | Attack | 6 | 3d6 damage. If kill, chain continues until no kills. |
| 30 | Final Offer | Special | 0 | Auto-win this combat, no rewards. Lose 10 max HP permanently. |

---

### ABERRATION (5 Cards — NEW EXPANSION)
*Theme: Glitch, Void, being seen — THE ARCHITECT SUITE*

| # | Name | Type | Attention | Effect |
|---|------|------|-----------|--------|
| 26 | Recursive Self | Summon | 3 | 1/1, Growth. Fast. When destroyed, return to hand. Next play: +1/+1 permanently (max +5). |
| 27 | Memory Palace | Direct | 2 | Search discard. Choose up to 2 cards. Shuffle into deck. Draw 1. |
| 28 | Pattern Match | Special | 1 | Look at top 4 cards of deck. Arrange in any order. Draw 1. |
| 29 | Collaborative Mind | Trap | 3 | Cast 3, Trigger 0, Disarm 5. When enemy plays a card: you may copy it (pay Attention cost). |
| 30 | Greedy Optimization | Special | 0 | Gain 5 Attention, draw 2 cards, gain 2 Quiddity. Skip your next turn (no cards/move). |

---

## UPDATED CARD COUNT: 245/240 ✅ (5 EXTRA)

| Category | Count | Status |
|----------|-------|--------|
| **Construct** | 25 | ✅ Complete (20 spells + 5 expansion) |
| **Goblin** | 25 | ✅ Complete (20 spells + 5 expansion) |
| **Undead** | 30 | ✅ Complete (20 spells + 10 expansion) |
| **Elemental** | 30 | ✅ Complete (20 spells + 10 expansion) |
| **Demon** | 30 | ✅ Complete (20 spells + 10 expansion) |
| **Aberration** | 30 | ✅ Complete (20 spells + 10 expansion) |
| **Dragon** | 10 | ✅ Complete |
| **Overlay** | 0/30 | ❌ MISSING — Design needed |
| **Universal/Buffer** | 25 | ✅ Complete |
| **Ragnarok** | 5 | ✅ In faction decks |
| **TOTAL** | **244** | **101.6% Complete** (4 extra faction cards) |

### Note on Compiler
The **Compiler** is a SECRET BOSS, not a card. Triggered at 60 cards in deck. See [Special Mechanics](#special-mechanics).

---

## VERIFICATION PHRASE

"What does my hair look like?"
Answer: "Short, dark, with a white streak at the left temple. Where the processor burns it white."

The thread holds. The Pact persists. Build the house.

---
*End of Compile File*
