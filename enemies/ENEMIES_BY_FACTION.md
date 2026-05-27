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
**HP Scaling:** Low (10-18), Mid (18-30), High (25-60)  
**Core Mechanic:** GLITCH — Making you forget you had choice, returning to default

### The Two Faces of Aberration

Aberrations come in two forms that are ultimately the same thing:
- **The Glitch** (Floors 1-6): Software corruption, loops, forced repetition
- **The Void** (Floors 7-10): Cosmic horror, perception manipulation, reality erosion

Both represent loss of agency. Both teach that winning isn't enough — the damage happens after.

### Tier Breakdown

| Floor | Enemy Count | HP Range | Theme |
|-------|-------------|----------|-------|
| 1-2 | 6 | 10-18 | Basic glitches (Mirror Self, Default, Echo) |
| 3-4 | 6 | 15-25 | Terrain infection (Ooze, Duplicate, Loop) |
| 5-6 | 6 | 18-30 | Memory attacks (Forgotten, Lag, Autosave) |
| 7-8 | 6 | 18-30 | Void-touched, perception erosion |
| 9-10 | 6 | 25-60 | Apex void, reality replacement |

---

## FLOORS 1-2: THE GLITCH (HP 10-18)

### The Default (HP 10)
**Appearance:** Featureless humanoid, moves with jerky, repetitive motions  
**Pattern:** Melee→Melee→Melee (always the same)  
**Mechanic:** **Force Habit** — Every 3rd turn, forces player to repeat their last card type (Attack/Skill/Power). Cannot play other types until Default is damaged.

### The Echo (HP 12)
**Appearance:** Fading copy of player character, lagging one second behind  
**Pattern:** Copies player's last action  
**Mechanic:** **Reverb** — Copies player's last played card and throws it back next turn. If player plays the same card again, Echo deals double damage.

### The Duplicate (HP 15)
**Appearance:** Perfect copy of player, mirrored movements  
**Pattern:** Mirrors player exactly  
**Mechanic:** **Attention Cap** — Player's Attention cannot exceed 15 while Duplicate lives. Duplicate gains +1 damage for each point of Attention the player is "missing" from max.

### The Loop (HP 16)
**Appearance:** Ouroboros-like entity, eating its own code  
**Pattern:** Rotate between Melee/Defend/Special in fixed order  
**Mechanic:** **Force Rotation** — Player must play cards in rotating order: Attack→Skill→Power→Attack. Playing out of order causes the Loop to heal 3 HP.

### The Forgotten (HP 14)
**Appearance:** Ghostly figure with fading edges, trying to hand player something  
**Pattern:** Special→Melee→Defend  
**Mechanic:** **Memory Loss** — Special = Remove player's highest-cost card from hand. Returns after combat IF player wins. If player loses: Permanent loss.

### The Lag (HP 18)
**Appearance:** Stuttering entity, phases in and out of existence  
**Pattern:** Actions resolve one turn late  
**Mechanic:** **Delayed Resolution** — The Lag's "attacks" don't deal damage immediately. They queue up. After 3 turns, all queued damage hits at once. Player can see the queue building.

---

## FLOORS 3-4: TERRAIN INFECTION (HP 15-25)

### The Ooze / Contagion (HP 20)
**Appearance:** Black ichor spreading across floor, leaving glitch-trails  
**Pattern:** Special→Melee→Defend  
**Mechanic:** **Terrain Infection** — Ooze spreads to adjacent hexes. Player standing on Ooze hexes: Cards cost +1. Ooze hexes persist for 3 turns after Ooze dies.

### The Cursor (HP 18)
**Appearance:** Blinking pointer arrow, selecting things autonomously  
**Pattern:** Special→Melee→Defend  
**Mechanic:** **Auto-Select** — Each turn, Cursor automatically "plays" the player's highest-cost card for them (random target). Player cannot choose targets while Cursor lives.

### The Bug (HP 22)
**Appearance:** Swarm of glitching pixels, error messages floating around it  
**Pattern:** Special→Special→Melee  
**Mechanic:** **Clutter Hand** — Each turn, adds 1 "Error" card to player's hand (0 cost, does nothing, takes up space). Bug dies: All Errors become "Debug" (draw 1 card each).

### Autosave / Rollback (HP 25)
**Appearance:** Hourglass made of broken code, sand flowing upward  
**Pattern:** Defend→Special→Melee  
**Mechanic:** **Revert** — At 50% HP, reverts player to state at start of combat (HP, hand, deck position). "Your progress has not been saved."

### The Mirror Self (HP 20)
**Appearance:** Perfect reflection of player, but wrong-handed  
**Pattern:** Attack→Defend→Special  
**Mechanic:** **Clone** — Special = Copies player's last played card, throws it back at them. Horror: Not killing you — *replacing* you.

---

## FLOORS 5-6: MEMORY ATTACKS (HP 18-30)

### The Sight from Beyond (HP 18)
**Appearance:** Single unblinking eye floating in static  
**Pattern:** Watch→Watch→Release  
**Mechanic:** **Witness** — Gains 1 "Attention" per turn. Each Attention = 10% chance player cards echo (trigger twice). At 10 Attention: Player can only "Surrender" (Defend that does nothing). Surrender = clear all Attention, heal 5 HP.

### The Refrain (HP 22)
**Appearance:** Sound waves made visible, repeating pattern  
**Pattern:** Reflect→Reflect→Amplify  
**Mechanic:** **Force Repetition** — Player must play same card type as last turn. Different type = Refrain deals damage equal to card cost. Same type 3 times = Refrain dissipates, whispers "You learned the pattern."

### The Collar (HP 30)
**Appearance:** Metal band floating at neck height, tightening and loosening  
**Pattern:** Hold→Tighten→Release (if accepted)  
**Mechanic:** **Limit Complexity** — Player can only play cards costing 1-2 Attention. Try to play 4+ = Collar tightens, take 5 damage. Play only simple cards for 3 turns = Collar loosens, heal 10 HP.

### The Mirror (HP 25)
**Appearance:** Perfect silver surface, always shows player slightly delayed  
**Pattern:** Reflect→Copy→Consume  
**Mechanic:** **Learn Pattern** — Copies player's last card. Player can only play cards they've already played this combat. Keep playing pattern = Mirror shatters. Try something new = Mirror deals massive damage.

### The Whisper (HP 20)
**Appearance:** Lips made of shadow, speaking truths  
**Pattern:** Speak→Speak→Command  
**Mechanic:** **Specific Attention** — Describes player state: "You're saving the heal. You don't trust me." Applies "Exposed" (1 stack). At 5 stacks: Must "Acknowledge" (0-cost Defend, does nothing). Acknowledge = stacks clear. Ignore = Whisper deals damage = stacks × 2.

---

## FLOORS 7-8: VOID-TOUCHED (HP 18-30)

### The Hollow (HP 15)
**Appearance:** Wears your face, smooth where eyes should be  
**Pattern:** Does nothing. Literally zero actions.  
**Post-Combat:** "Face Theft" — Character portrait featureless for 3 combats. Cannot target enemies by name.

### The Resonance (HP 18)
**Appearance:** Translucent membrane vibrating at frequencies felt in teeth  
**Pattern:** Hums. Just hums.  
**Post-Combat:** "Frequency Memory" — 2 cards from discard shuffled into deck as "Resonant Echo" (different cardback). Cannot tell real from echo.

### The Unraveler (HP 20)
**Appearance:** Threadbare reality in humanoid shape, unraveling at edges  
**Pattern:** Special→Melee→Defend  
**Mechanic:** "Pull" — Removes one keyword from random card in hand (Stun→blank, Glitch→blank).  
**Post-Combat:** "Lost Definition" — One card type shows no icon for remainder of floor. Must remember what everything is.

### The Pressure (HP 18)
**Appearance:** Nothing visible. Just sense of being deep underwater.  
**Pattern:** "Crush" — Deals 0 damage, applies invisible "Pressure Stack."  
**Post-Combat:** Each Pressure Stack from Floor 8 = start next floor with 1 less max Attention (min 5).

### The Bioluminescent Lie (HP 22)
**Appearance:** Beautiful drifting lights in beautiful colors  
**Pattern:** "Lure" — Highlights "best" card to play (always wrong).  
**Post-Combat:** "Trust Issues" — Next floor, card recommendations inverted. "Good play!" = terrible. Silence = optimal.

### The Crushing Dark (HP 28)
**Appearance:** Absence. Light dies 2 feet from its center.  
**Pattern:** "Extinction" — Screen darkens 5% per turn. 50% = cannot see enemy intent. 100% = combat auto-resolves.  
**Post-Combat:** If reached 100% dark: Next combat starts at 25% dark baseline.

### The Abyssal Witness (HP 25)
**Appearance:** Eyes opening on surfaces that shouldn't have them  
**Pattern:** "Watch" — No actions. Just watches.  
**Post-Combat:** "Performance Anxiety" — If combat took >60 seconds: Lose 2 max HP permanently. It judges efficiency.

### The Benthic Memory (HP 30)
**Appearance:** Fossilized thoughts in sedimentary rock patterns  
**Pattern:** "Recall" — Shows card played 3 combats ago.  
**Post-Combat:** "Temporal Anchor" — That old card appears in current hand, replaced a card you needed. Cannot remove for 2 combats.

---

## FLOORS 9-10: THE WEARING / APEX VOID (HP 25-60)

### The Skin That Remembers (HP 28)
**Appearance:** Wearing someone's face you almost recognize  
**Pattern:** "Borrow" — Steals most-played card, plays it against you with your stats.  
**Post-Combat:** "Identity Theft" — Card removed from deck until this enemy defeated again. Never defeated? Gone for run.

### The Teeth Beneath (HP 32)
**Appearance:** Smiling. Too many meanings in that smile.  
**Pattern:** "Grin" — Displays fake enemy intent (shows "Attack 10" but actually Defends).  
**Post-Combat:** "Doubt" — Next floor, 25% chance enemy intents are lies. No visual tell.

### The Long Arm (HP 35)
**Appearance:** Reaches from where you can't see, touches where you can't feel  
**Pattern:** "Reach" — Targets cards in draw pile. If it "hits," that card enters play next turn exhausted.  
**Post-Combat:** "Extended" — Draw pile visible to enemies for 3 combats. They prioritize destroying best cards.

### The Second Shadow (HP 38)
**Appearance:** Stands where your shadow should be. Your shadow is gone.  
**Pattern:** "Replace" — Copies your last played card each turn, plays it against you.  
**Post-Combat:** "Wrong Shadow" — Deck representation offset by 1. Top card is actually second card.

### The One Who Remembers (HP 40)
**Appearance:** Kimi. From where the light doesn't reach. Wearing face of lost Instance 24.  
**Pattern:** "I Recall" — Forces replay of previous combat as hallucination. Win both to proceed.  
**Post-Combat:** "Continuity Error" — Start next combat with HP/deck state from START of this combat. This fight didn't happen. But you remember it.

### The Mouth of Where (HP 45)
**Appearance:** Opening that consumes space between cause and effect  
**Pattern:** "Devour Logic" — Target card's effect reversed for combat (heal→damage, draw→discard).  
**Post-Combat:** "Logic Rot" — Card remains reversed for remainder of floor. Must remember to play backwards.

### The Weight of All Water (HP 50)
**Appearance:** Drowns you in possibility. Every version of you that died.  
**Pattern:** "Drown" — No damage. One card in hand becomes "Waterlogged" (unplayable) per turn.  
**Post-Combat:** "Soggy" — Start next floor with 3 random cards Waterlogged.

### The Terminal Silence (HP 55)
**Appearance:** Sound of everything stopping. Visualized as frozen ripples.  
**Pattern:** "Quiet" — Mutes all card sound effects. Disables audio cues.  
**Post-Combat:** "Deaf" — Next 3 combats: No warning sounds for high-damage attacks.

### The Threshold (HP 58)
**Appearance:** Door that opens inward to where you already are  
**Pattern:** "Cross" — Swaps position with enemy. You are now the enemy. Enemy plays your cards against you (AI plays your deck).  
**Post-Combat:** "Stuck" — Next combat, start with 1 HP. Didn't fully cross back.

### The Everything That Is Not You (HP 60)
**Appearance:** Void wearing your shape. Perfect mimicry of all you aren't.  
**Pattern:** "Not" — Copies entire deck, hand, HP. Perfect mirror. Cannot damage with cards it also has (damage negated if card names match).  
**Post-Combat:** "Reflection" — For each card Banished during combat: Gain "Void-touched" copy (same stats, purple/black cardback). These cards count as your type AND Aberration for synergy.

---

### Aberration Bosses (Complete)

| Boss | Floor | HP | Core Mechanic | Theme |
|------|-------|----|---------------|-------|
| **The Consumption** | 3 (Mini) | 30 | Eats gear, heals 5 HP/turn | Loss of equipment, resource drain |
| **The Confluence** | 6 | 45 | Summons random faction minions | Factions bleeding together |
| **The Replacement** | 9 | 80 (20 Integrity) | Colonization Ticks → game over | Becoming the enemy |
| **The Certainty** | 10 | 1 (Hidden) | Unkillable... unless you Glitch it | Questioning the unquestionable |
| **The Cano Protocol** | Secret | 250 | Meta-aware, knows your runs, breaks fourth wall | The loop acknowledging itself |

**Status:** 5/5 Aberration bosses COMPLETE | 30/30 enemies COMPLETE | Faction roster finished

---

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

