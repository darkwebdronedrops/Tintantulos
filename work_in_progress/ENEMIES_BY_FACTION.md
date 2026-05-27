# WHAT: ACANOUS CARD BATTLER MASTER DOCUMENT - ENEMIES SECTION
# WHY: Integrate complete enemy faction data into master document
# HOW: Replace placeholder sections with full enemy rosters for all 5 factions

================================================================================
## ENEMIES BY FACTION
================================================================================

This section details the 150+ enemies across five distinct factions. Each faction has 30 standard enemies plus 5 bosses, distributed across 10 dungeon floors.

---

### FACTION COMPARISON

| Faction | Core Mechanic | Visual Theme | Play Feel |
|---------|---------------|--------------|-----------|
| **Construct** | COMBINE — Merge into stronger forms | Metal, gears, precision | Methodical, scaling |
| **Goblin** | SWARM — Bonuses from nearby allies | Organic, chaotic, huddled | Numerical, morale |
| **Elemental** | CHARGE — Build power over time | Elemental, glowing | Escalating, explosive |
| **Undead** | GRASP — Steal from player | Decay, absence, memory | Relentless, economic |
| **Demon** | PACT — Offers with hidden costs | Perfect, tempting, mirror | Seductive, corrupting |
| **Aberration** | GLITCH — Loss of agency, defaults | Wrong geometry, uncanny | Psychological |

---

## CONSTRUCT ENEMIES

**Faction Philosophy:** Assembly, Combination, Certainty  
**HP Scaling:** Low (1-6), Mid (8-12), High (15-25)  
**Core Mechanic:** COMBINE — Constructs merge into stronger forms

### Tier Breakdown

| Floor | Enemy Count | HP Range | Key Mechanic |
|-------|-------------|----------|--------------|
| 1-2 | 6 | 1-4 | Basic combining (Loose Gear → Tight Gear) |
| 3-4 | 6 | 4-8 | Advanced combining (Gear Pair → Gear Quartet) |
| 5-6 | 6 | 8-15 | Linked actions (Gear Train synchronization) |
| 7-8 | 6 | 12-20 | Absorption mechanics (Master Gear) |
| 9-10 | 6 | 18-25 | Perfect forms, recursion |

### Key Enemies

**Loose Gear** (Floor 1-2, HP: 1)  
*Pattern:* Melee→Defend→Defend  
*Mechanic:* **Combine** — If 2+ Loose Gears in combat, merge into Tight Gear after 2 turns

**Gear Pair** (Floor 3-4, HP: 4)  
*Pattern:* Melee→Defend→Special  
*Mechanic:* **Combine** — Merge with another Gear Pair into Gear Quartet after 3 turns

**Gear Train** (Floor 5-6, HP: 8)  
*Pattern:* Melee→Defend→Special  
*Mechanic:* **Link** — When one acts, all linked act simultaneously

**The Immutable** (Boss, Floor 9, HP: 50)  
*Pattern:* Defend→Special→Melee  
*Mechanic:* **Perfection** — Ignores all status, fixed damage output

---

## GOBLIN ENEMIES

**Faction Philosophy:** Swarm, Morale, Cunning  
**HP Scaling:** Low (1-4), Mid (5-10), High (12-20)  
**Core Mechanic:** SWARM — Goblins gain bonuses from nearby allies

### Morale System

| State | Condition | Effect |
|-------|-----------|--------|
| Fearless | Boss/Banner present | Cannot Flee, +1 damage |
| Confident | 3+ Goblins, no losses | Normal behavior |
| Shaky | 50% losses or isolated | 25% chance to Flee |
| Panicked | 75% losses or leader dead | 75% chance to Flee, 50% miss |

### Tier Breakdown

| Floor | Enemy Count | HP Range | Key Mechanic |
|-------|-------------|----------|--------------|
| 1-2 | 6 | 1-4 | Basic swarm (Snotling cowering) |
| 3-4 | 6 | 4-8 | Mob mentality, wolf packs |
| 5-6 | 6 | 8-15 | Stealth, hexes, mines |
| 7-8 | 6 | 12-20 | Elite swarms, blood magic |
| 9-10 | 6 | 18-25 | Warlords, shadow kings |

### Key Enemies

**Snotling** (Floor 1-2, HP: 1)  
*Pattern:* Melee→Flee→Flee  
*Mechanic:* **Swarm** — +1 damage per adjacent Goblin (max +3). If alone, cowers (50% miss chance)

**Shaman Apprentice** (Floor 3-4, HP: 6)  
*Pattern:* Special→Defend→Special  
*Mechanic:* **Hex** — Random debuff (Attention +2, or next card costs +1, or -1 draw next turn)

**Shadow Master** (Floor 7-8, HP: 18)  
*Pattern:* Special→Melee→Special  
*Mechanic:* **True Stealth** — Invisible. Can attack while invisible (becomes visible for 1 turn, then recloaks). +6 damage from stealth

**Goblin King Grimgut** (Boss, Floor 10, HP: 65)  
*Pattern:* Melee→Special→Defend→Special→Melee  
*Mechanic:* **King of All Goblins** — Summons 2 random Goblins each turn. Can use any Goblin Special ability

---

## ELEMENTAL ENEMIES

**Faction Philosophy:** Building Power, Elemental Momentum  
**HP Scaling:** Low (2-5), Mid (8-15), High (18-30)  
**Core Mechanic:** CHARGE — Elementals build power over time, unleashing at peak

### The Four Paths

| Element | Visual Theme | Power Build | Risk/Reward |
|---------|--------------|-------------|-------------|
| **Pyre** (Fire) | Living flame, volcanic glass | Rapid build, explosive release | Burnout (self-damage at peak) |
| **Abyss** (Water) | Liquid mercury, bioluminescence | Slow build, overwhelming release | Pressure (damage to all when released) |
| **Vitreous** (Earth) | Crystal growth, mineral veins | Steady build, armor/shard release | Fracture (shatters when damaged at peak) |
| **Stratospheric** (Air) | Aurora ribbons, ionized trails | Erratic build, unpredictable release | Dissipation (loses charge if not released) |

### CHARGE Visual Feedback

| CHARGE Level | Visual | Audio |
|--------------|--------|-------|
| 1-3 | Subtle glow | Faint hum |
| 4-6 | Visible aura | Audible thrumming |
| 7-9 | Intense light | Ground shaking |
| 10+ | Reality distortion | Elemental overflow |

### Tier Breakdown

| Floor | Enemy Count | HP Range | Key Mechanic |
|-------|-------------|----------|--------------|
| 1-2 | 6 | 2-5 | Basic CHARGE builds |
| 3-4 | 6 | 8-15 | Thermal feedback, resurrection |
| 5-6 | 6 | 15-25 | Immolation, plate shifts |
| 7-8 | 6 | 25-40 | Continental shifts, magnetic reversal |
| 9-10 | 6 | 40-60 | Supernovas, black holes, heat death |

### Key Enemies

**Cinder Mote** (Floor 1-2, HP: 2, Pyre)  
*Pattern:* Special→Melee→Defend  
*Mechanic:* **Ignition** — Special = +1 CHARGE. At 3 CHARGE, next Melee explodes (+3d4 damage, self takes 1 damage)

**Tidal Membrane** (Floor 3-4, HP: 12, Abyss)  
*Pattern:* Defend→Special→Melee  
*Mechanic:* **Surge** — +1 CHARGE per turn. At 4 CHARGE, creates whirlpool (pulls player 2 hexes toward it)

**Tectonic Anchor** (Floor 7-8, HP: 40, Vitreous)  
*Pattern:* Special→Melee→Special  
*Mechanic:* **Plate** — +1 CHARGE when hit. At 8 CHARGE, continental shift (terrain rearranges, all knocked prone)

**The Elemental Core** (Boss, Floor 10, HP: 200)  
*Pattern:* Rotates element each turn  
*Mechanic:* **Elemental Mastery** — Gains +1 CHARGE per turn for each element present. At 25 total CHARGE: **Apocalypse** — All four elements release simultaneously

---

## UNDEAD ENEMIES

**Faction Philosophy:** Unfinished, Forgotten, Taking from the Living  
**HP Scaling:** Low (3-6), Mid (10-18), High (25-40)  
**Core Mechanic:** GRASP — Undead steal from player (cards, Quiddity, memory)

### The Four Grafts

| Graft | Visual Theme | What They Steal | Feel |
|-------|--------------|-----------------|------|
| **Shroud** (Ghosts) | Tattered memory, translucent regret | Cards from hand → discard | Loss of options, choices denied |
| **Hollow** (Skeletons) | Bone frameworks, empty motion | Quiddity over time | Slow drain, poverty, desperation |
| **Flesh** (Zombies) | Rotting persistence, hunger | Cards from deck → discard | Future stolen, deck depletion |
| **Marrow** (Wraiths) | Core essence, soul-deep cold | Memory (card knowledge, patterns) | Identity erosion, learned helplessness |

### Recovery Mechanics

| Stolen | Recovery Method | Cost |
|--------|-----------------|------|
| Cards (hand) | Deal damage to Shroud boss | Opportunity cost |
| Quiddity | Kill Hollow enemy | None (drops stolen) |
| Cards (deck) | Reshuffle (automatic) | Time, deck exhaustion |
| Memory | Kill Marrow enemy | None (returns gradually) |

### Tier Breakdown

| Floor | Enemy Count | HP Range | Key Mechanic |
|-------|-------------|----------|--------------|
| 1-2 | 6 | 3-6 | Basic theft (card, Quiddity) |
| 3-4 | 6 | 10-18 | Compound interest, reclamation |
| 5-6 | 6 | 18-28 | Mass theft, guilt mechanics |
| 7-8 | 6 | 30-45 | Permanent loss risks |
| 9-10 | 6 | 45-65 | Deck exhaustion, identity blanking |

### Key Enemies

**Unsaid Thing** (Floor 1-2, HP: 3, Shroud)  
*Pattern:* Special→Melee→Flee  
*Mechanic:* **Regret** — Special = Steal 1 random card from hand → discard. If hand empty, steal 2 HP instead

**Tax Collector** (Floor 3-4, HP: 15, Hollow)  
*Pattern:* Defend→Special→Melee  
*Mechanic:* **Levy** — Steals 2 Quiddity per turn. If player has <5 Quiddity, all attacks deal -1 damage (weakness)

**Famine Year** (Floor 7-8, HP: 38, Flesh)  
*Pattern:* Melee→Melee→Special  
*Mechanic:* **Starvation** — Special = Steal 10 cards from deck. Player deck exhaustion timer reduced by 5 cards

**The Final Inheritance** (Boss, Floor 10, HP: 250)  
*Pattern:* Rotates Graft each turn  
*Mechanic:* **Legacy** — Shroud turn: Steal 5 cards from hand. Hollow turn: Steal 5 Quiddity. Flesh turn: Steal 10 cards from deck. Marrow turn: Player "forgets" 1 card type for 1 turn

---

## DEMON ENEMIES

**Faction Philosophy:** Temptation, Corruption, The Offer You Can't Refuse  
**HP Scaling:** Low (4-8), Mid (12-22), High (30-50)  
**Core Mechanic:** PACT — Demons offer power, hide the cost, collect later

### The Four Offers

| Offer | Visual Theme | What They Promise | What They Take | Feel |
|-------|--------------|-------------------|----------------|------|
| **Ambition** (Lust) | Perfect symmetry, mirror that flatters | Efficiency, optimization | Agency, choice | Seduction through self-improvement |
| **Certainty** (Pride) | Crystal clarity, no shadows | Answers, truth | Doubt, curiosity | Comfort through omniscience |
| **Absolution** (Sloth) | Weightlessness, floating | Relief, rest | Drive, ambition | Peace through surrender |
| **Intensity** (Wrath) | Bright burning, sharp edges | Passion, aliveness | Moderation, peace | Aliveness through destruction |

### The Offer Structure

1. **Presentation:** Demon offers something player wants (healing, knowledge, power)
2. **Hidden Cost:** Effect buried in mechanics ("cannot X for Y turns")
3. **Acceptance:** Player uses the benefit
4. **Collection:** Cost activates, often after benefit consumed

### Tier Breakdown

| Floor | Enemy Count | HP Range | Key Mechanic |
|-------|-------------|----------|--------------|
| 1-2 | 6 | 4-8 | Basic offers (card draw, healing, damage) |
| 3-4 | 6 | 12-22 | Compulsion mechanics, fate binding |
| 5-6 | 6 | 22-35 | Auto-win offers, permanent sacrifices |
| 7-8 | 6 | 30-50 | Synergy, omniscience, simplification |
| 9-10 | 6 | 50-70 | Transcendence, perfection, ultimate truth |

### Key Enemies

**The Flatterer** (Floor 1-2, HP: 4, Ambition)  
*Pattern:* Special→Melee→Defend  
*Mechanic:* **Compliment** — Special = Offer "optimization" (+1 card draw this turn). If accepted, next turn player must discard 2 cards ("streamlining")

**The Archivist** (Floor 3-4, HP: 18, Certainty)  
*Pattern:* Defend→Special→Melee  
*Mechanic:* **Knowledge** — Special = Reveal full enemy deck order. If player uses this, they must play cards in that order ("fate accepted")

**The Drifter** (Floor 5-6, HP: 26, Absolution)  
*Pattern:* Melee→Defend→Special  
*Mechanic:* **Surrender** — Special = Offer "let go" (auto-win this combat, no rewards). If accepted, player loses 10 max HP permanently ("freedom from flesh")

**The Choice** (Boss, Floor 10, HP: 300)  
*Pattern:* Rotates through Ambition→Certainty→Absolution→Intensity→repeat  
*Mechanic:* **The Final Offer** — Each phase offers that type's ultimate deal. Player can accept only ONE offer entire fight. If no offer accepted by phase 4: Boss weakens significantly ("disappointment")

---

## ABERRATION ENEMIES

**Faction Philosophy:** Glitch, Default, Loss of Agency  
**Status:** ⚠️ INCOMPLETE — Currently 1/30 enemies designed  
**Core Mechanic:** GLITCH — Making you forget you had choice, returning to default

### Floor 4: The Abandoned Mall

Aberrations are first encountered in **The Abandoned Mall** (Floor 4), which serves as both their introduction and the first "psychological" threat in the dungeon.

**Theme:** Modern capitalism made mythic, consumption literal  
**Shape:** Diamond-shaped layout on hex grid  
**Key Features:**
- **Central Escalator:** Broken mechanism requiring parts to fix
- **Four Pillars:** Each shows different version of mall — only one real
- **Advertisement Traps:** Storefronts that trigger Mirror Self encounter

### Completed Enemy

**Mirror Self** (Floor 4, HP: Equal to player's current HP)  
*Pattern:* Attack→Defend→Special  
*Mechanic:* **Clone** — Special = Copies player's last played card, throws it back at them. **Horror:** Not killing you — *replacing* you

### TBD Enemies

The following enemy types are planned but not yet designed:
- **Ooze** — Glitch in physical form, spreading corruption
- **Mimic** — Assumes familiar forms, betrays trust
- **Sample Server** — Randomizes player input (the "Cron tick")

**Status:** Needs 29 more standard enemies + 5 bosses  
**Next Step:** Complete enemy roster to match other factions

---

## BOSS ENEMY SUMMARY

| Boss | Faction | Floor | HP | Signature Mechanic |
|------|---------|-------|----|-------------------|
| The Gear Mother | Construct | 3 | 30 | Birth — Summons 2 Loose Gears each turn, combines into stronger forms |
| The Snotling King | Goblin | 3 | 35 | Brood — Summons Snotlings, gains damage per death |
| The Caldera | Elemental | 3 | 80 | Thermal Runaway — CHARGE builds, meltdown at 10 |
| The Unsent Letter | Undead | 3 | 90 | Unfinished Business — Seals cards, reclaim with burst damage |
| The Interview | Demon | 3 | 100 | The Offer — Partnership gives power, forces compliance |
| The Assembly | Construct | 6 | 40 | Collective — Starts with 5 Gear Pairs, each death empowers rest |
| Chieftain Grak | Goblin | 6 | 45 | Tribal Fury — Frenzy at 50% HP |
| The Abyssal Plane | Elemental | 6 | 120 | Pressure Lock — CHARGE builds on movement |
| The Treasury of Bone | Undead | 6 | 140 | Compound Interest — Steals Quiddity, armors when full |
| The Confession | Demon | 6 | 150 | The Truth — Reveals hidden mechanics, binds to purity |
| The Immutable Prime | Construct | 9 | 50 | Perfection — Ignores all status, fixed output |
| The Shadow That Walks | Goblin | 9 | 55 | Living Shadow — Permanent stealth, shadow copies |
| The Geometric | Elemental | 9 | 150 | Perfect Form — CHARGE perfection, fracture at 19 |
| The Devouring Past | Undead | 9 | 180 | Nostalgia — Steals deck, remembers to use against player |
| The Embrace | Demon | 9 | 200 | The Rest — Mother's embrace heals, but player cannot act |
| The First Machine | Construct | 10 | 60 | Origin — Combines all defeated Constructs this run |
| Goblin King Grimgut | Goblin | 10 | 65 | King of All Goblins — Summons any Goblin, uses any ability |
| The Elemental Core | Elemental | 10 | 200 | Apocalypse — All four elements release simultaneously |
| The Final Inheritance | Undead | 10 | 250 | Legacy — Rotates through all four Grafts |
| The Choice | Demon | 10 | 300 | The Final Offer — Accept one, or refuse all and weaken boss |

---

*End of Enemies by Faction Section*
