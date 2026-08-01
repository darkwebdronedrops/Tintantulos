# TINTANTULOS — GAME DESIGN DOCUMENT (Canonical)
**Generated from codebase:** `darkwebdronedrops/Tintantulos` @ `zar/gdd-reconciliation`  
**Date:** 2026-08-02  
**Source of truth:** The `.tres` card library and shipped Godot 4 code. When this doc and the code disagree, the code wins.

---

## 1. GAME OVERVIEW

**Genre:** Deckbuilding Roguelike  
**Engine:** Godot 4 (pointy-top hex grid)  
**Perspective:** Top-down overworld + turn-based card combat  
**Core Loop:** Explore hex dungeon floors → enter combat → build deck → ascend

The player descends through 10 procedurally generated dungeon floors, each with unique visual themes, enemy compositions, environmental hazards, and narrative beats. Combat is card-based: the player draws cards, pays Attention to play them, and manages a rising Attention meter that shifts through four states (Whisper → Borrowed → Undefined → Scream).

---

## 2. CORE MECHANICS

### 2.1 Attention System
The core combat resource. Each card has an Attention cost. Playing a card adds its cost to your Attention.

| State | Threshold | Damage YOU Deal | Damage YOU Take |
|-------|-----------|-----------------|-----------------|
| Whisper | 0–5 | ×½ (min 1) | ×½ |
| Borrowed | 6–10 | ×1 | ×1 |
| Undefined | 11–15 | ×1 | ×2 |
| Scream | 16–20 | ×2–3 | ×2–3 |

**Hard cap: 20.** The only way to exceed 20 is a Pact resolving on the next turn (see 2.4).

### 2.2 Stake
Before playing cards each turn, the player may stake 0–5 cards. Staked cards are not drawn; instead, the player receives Quiddity. Stake resets to 0 after each draw phase — it is a per-turn decision, not persistent.

### 2.3 Three-Currency Economy

| Currency | Source | Sink |
|----------|--------|------|
| **Quiddity** | Combat victories, staked cards | Post-combat card picks (choose 1 of 3) |
| **Gems** 💎 | Burn cards at Offering Shrines, sell offerings to Machinist | Keyword injection (15💎), Overlay fusion (15💎), shop items |
| **Offerings** | Kami Shrine boons, room rewards | Burn at shrines for permanent blessings |

### 2.4 Pact & Debt
A Pact card replays itself on the next turn at full Attention cost. Pacts can push you into Debt (above 20 Attention). Debt is not fatal — it resolves when the Pact plays. Hard cap remains 20; Pacts are the **only** overflow mechanism.

### 2.5 Backfire
If you target an enemy with a card sharing their faction, the card's Attention cost is doubled. **Void** keyword prevents backfire (counts as no faction).

### 2.6 Deck Death
When the deck is empty, the discard pile reshuffles. If **both** deck and discard are empty, each missing draw deals 5 "existential damage" to the player.

### 2.7 CHARGE (Elemental Resource)
Playing Elemental cards builds CHARGE (+1 per card, cap 10). CHARGE is hidden until first Nature/Flow play. 
- **Nature:** +2 flat damage per CHARGE
- **Flow:** +1d6 per CHARGE (max +3d6), then **consumes all CHARGE**

### 2.8 Corruption
Unimplemented player-side resource (see Design History). Enemy DoT "corruption" renamed to **Taint** (2 dmg/3 turns) to avoid collision.

---

## 3. COMBAT SYSTEM

### 3.1 Turn Structure
1. **Player Turn:** Draw 5 − stake cards. Play cards until out of Attention or cards. End turn discards remaining hand.
2. **Summon Attack Phase:** Living summons attack (summoning sickness unless Fast keyword).
3. **Enemy Phase:** Each living enemy acts (ATTACK → DEFEND → SPECIAL cycle).
4. **Cleanup:** Apply DoT, growth, remove dead summons, check combat end.

### 3.2 Trap Cards
Traps are cast for their cost and enter an active state. They trigger when an enemy performs a matching action:
- **Trigger:** Trap effect fires (e.g., Gear Shield blocks attack, Tripwire deals 3 dmg + skips enemy's next action)
- **Disarm:** Enemy performs disarm action → trap fizzles, player pays disarm cost
- **Persist:** Neither trigger nor disarm → trap stays active

### 3.3 Death Keyword (Undead)
Cards with the Death keyword can be cast from the discard pile by sacrificing the lowest-HP living summon. Still costs normal Attention. Requires CombatHUD "Death" button (purple skull, appears when conditions met).

### 3.4 Flee
Costs: 1d6 parting damage, lose 1 random card from deck, quiddity evaporates. 3-second No Aggro grace period.

### 3.5 The Compiler (Secret Boss)
Triggered when weighted deck count ≥ **50** (not 60). Replaces the Dragon at Floor 10. Phases: Debug → Memory Leak → Stack Overflow → Garbage Collection. Reuses Cano Protocol fight skeleton.

---

## 4. KEYWORDS

### Implemented
| Keyword | Faction | Effect |
|---------|---------|--------|
| **First** | Universal | First play of this card each combat costs 1 less |
| **Machine** | Construct | Roll damage dice twice, take average |
| **Precision** | Construct | Attack immediately when summoned |
| **Sneaky** | Goblin | +2d6 damage if enemy lacks Sneaky |
| **Sharp** | Goblin | Damage scale +1 (dice count +1 or flat +1) |
| **Fast** | Goblin | Resolves before enemy actions (no summoning sickness) |
| **Death** | Undead | Cast from discard by sacrificing lowest-HP summon |
| **Bone** | Universal | Gain shield = card's Attention cost (vanishes next turn) |
| **Poison** | Goblin | DoT: 3 dmg/turn, 4 turns |
| **Fire** | Elemental | DoT: 4 dmg/turn, 2 turns |
| **Corruption** | Demon | DoT: 2 dmg/turn, 3 turns |
| **Glitch** | Aberration | 25% chance for bonus effect (heal, cost reduction, AoE damage) |
| **Pact** | Demon | Triggers again next turn (with Attention cost, can debt) |
| **Void** | Aberration | Counts as NO faction. Immune to backfire |
| **Nature** | Elemental | +2 flat damage per CHARGE. Ignores Shield |
| **Flow** | Elemental | +1d6 per CHARGE (max +3d6), then consumes all CHARGE |
| **Persist** | Universal | Field effect lasts until removed |
| **Grasp** | Universal | Immobilizes target when attacking |
| **Charge** | Elemental | Related to CHARGE mechanic |
| **Lifedrain** | Demon | Heal on damage dealt |
| **Evasion** | Universal | Avoid damage |

### Known Gaps (Implementation Pending)
- **First Strike** — exists on cards (Dragon, Infernal overlays) but not mechanically distinct from First
- **Overlay types** (Arcane, Divine, Infernal) are card types, not keywords

---

## 5. FACTIONS & CARDS (Canonical)

**Total: 240 cards** across 8 factions + Universal + Overlays + Dragon.

*(Tables generated from `finished_cards/**/*.tres` — THE LIBRARY IS CANONICAL)*

### Aberration (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Aberrant Form | Special | 3 | 0 | Glitch | Your cards have random effects this turn (damage/heal/shield values vary +/- ... |
| Beyond the Veil | Special | 6 | 0 | Void, Glitch | Return all cards from your discard pile to your deck. Void: Draw 2 cards. Gli... |
| Consume Sanity | Attack | 3 | 3d6 | Void, Glitch | Deal 3d6 damage to yourself. Void: Target enemy takes equal damage. Glitch: I... |
| Dimensional Anchor | Trap | 3 | 3d6 | Glitch, Trap | Trap: Cast 1, Trigger 0, Disarm 4. TRIGGER: Enemy Special. Their Special fail... |
| Eldritch Horror | Summon | 6 | 0 | Void, Glitch | 5/5 with Growth. All enemies have -1 Attack while this lives. |
| Fold Space | Special | 3 | 0 | Void | Special: Target enemy attacks your summon instead of you this turn. |
| Fractured Mind | Special | 2 | 0 | Glitch, Void | Draw 3 cards. Glitch: 50% chance to draw 1 extra card. Void: Discard 1 random... |
| Glitch Shield | Special | 2 | 0 | Glitch | Gain 5 Shield. 50% chance to gain 10 instead. |
| Glitch Step | Special | 1 | 0 | Glitch | Special: Next card you play costs -2 Attention. |
| Glitch Strike | Attack | 2 | 1d6 | Glitch | 1d6 damage. 25% chance to trigger twice. |
| Glitch Swarm | Summon | 5 | 0 | Glitch | THREE 2/2 Glitches with Growth. Each has 20% chance to miss each turn. |
| Mind Flay | Attack | 5 | 2d6 | Void | 2d6 damage. Target loses 1d4 Attention. |
| Null Field | Field | 5 | 0 | Void, Persist | Field (Persist): All Shield effects are reduced by 50%. |
| Phase Shift | Special | 3 | 0 | Void | Become ethereal for 2 turns. You can only be damaged by Void attacks. |
| Probability Storm | Field | 4 | 0 | Glitch, Persist | Field (Persist): All die rolls have +/- 2 variance (random). |
| Reality Bend | Special | 3 | 0 | Glitch | Reroll any die result this turn. Glitch: May reroll twice. |
| Reality Tear | Attack | 7 | 4d6 | Void, Glitch | 4d6 damage. Glitch: 50% chance to deal 8d6 instead. |
| Recursive Strike | Attack | 4 | 2d6 | Glitch | Attack: 2d6, if Attention >10 attack again. |
| System Error | Special | 2 | 0 | Glitch | Special: Glitch chance to double-cast. |
| Tentacle Spawn | Summon | 3 | 0 | Glitch, Void | Summon 1/3 Tentacle. Glitch: When summoned, 50% chance to summon a second 1/3... |
| Unnatural Selection | Special | 2 | 0 | Glitch | Look at top 5 cards of any deck. Put them back in any order. |
| Unravel Reality | Field | 5 | 1d6 | Glitch, Void | Field: All damage is randomized (1d6 added or subtracted). Glitch: Cards you ... |
| Unstable Bolt | Attack | 3 | 1d12 | Glitch | 1d12 damage. Also hits random adjacent target (friend or foe). |
| Void Collapse | Attack | 6 | 3d8 | Void | 3d8 damage. Void: Removes all Shield before dealing damage. |
| Void Gaze | Attack | 4 | 2d6 | Void, Glitch | Deal 2d6 damage. Void: Target loses their next action (stunned). Glitch: 50% ... |
| Void Rift | Trap | 4 | 0 | Void | Trap: When triggered, deal 4 damage and apply Glitch (next action has 50% fai... |
| Void Spawn | Summon | 4 | 0 | Void | 3/3. Its attacks ignore Shield. It phases out (untargetable) every other turn. |
| Void Tentacles | Summon | 4 | 0 | Void, Grasp | 2/6 with Growth. Grasp: Immobilizes target when attacking. |
| Void Touch | Attack | 3 | 2d6 | Void | Attack: Void - cannot be countered. |
| Warp Reality | Direct | 4 | 0 | Void | Enemy attacks themselves. They take 2d4 damage. |

### Construct (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Assembly Drone | Summon | 3 | 0 | Machine, Fast | 1/2 Drone with Growth (+1/+1 per turn). Fast: Can act immediately. |
| Assembly Line | Summon | 3 | 0 | Machine | Summon: 2/3 with Growth +1/+1 each turn. |
| Assembly Protocol | Special | 3 | 0 | Machine | Summon a 1/1 Assembly Drone. Machine: If you have 3+ summons, summon two 1/1 ... |
| Calibrate | Field | 3 | 0 | Machine, Precision | Field: +1 damage for Machine cards. Persist. |
| Calibration | Special | 2 | 0 | Machine | Your next Machine card this turn has Precision (double effect on single target). |
| Calibration Error | Attack | 3 | 3d6 | Machine | Deal 3d6 damage to a random target (could hit enemy, yourself, or summons). M... |
| Clockwork Tick | Summon | 2 | 0 | Machine, Fast | Summon TWO 1/1 Clockwork Ticks. Fast. They expire after 3 turns. |
| Combine | Special | 4 | 0 | Machine | Sacrifice two Constructs. Create one with combined stats +1/+1. |
| Efficient Block | Special | 1 | 0 | Machine | Gain 3 Shield. If this prevents all damage, gain 1 Attention next turn. |
| Final Assembly | Summon | 6 | 0 | Machine, Precision | 4/5 Construct with Growth. Precision: Deals double damage to single targets. |
| Gear Shield | Trap | 1 | 0 | Machine, Precision | Trap: Cast 1, Trigger 1, Disarm 2. Blocks next attack. |
| Gear Strike | Attack | 3 | 1d8 | Machine | 1d8 damage. Gains +1 damage for each Construct card played this turn. |
| Gear Works | Field | 4 | 0 | Machine, Precision | Field: All your Machine summons have +1 attack and +1 HP. Machine cards cost ... |
| Immutable | Special | 2 | 0 | Machine | Your Constructs cannot be targeted by enemy effects this turn. |
| Interlock | Field | 5 | 0 | Machine, Persist | Field (Persist): When you play a Machine card, gain 2 Shield. |
| Mechanical Advantage | Special | 3 | 0 | Machine | For each Construct you control, deal 1d4 damage to target enemy. |
| Modular Design | Special | 2 | 0 | Machine | Draw 2 cards. Machine: If you played a Machine card this turn, draw 3 instead. |
| Optimization Loop | Field | 4 | 0 | Machine, Persist | Field (Persist): Your Machine cards cost 1 less Attention. |
| Optimize | Special | 2 | 0 | Precision | Special: Averages next damage roll (round up). |
| Overclock | Attack | 4 | 3d6 | Machine | Attack: 3d6 damage, take 2 damage. |
| Precision Bolt | Attack | 4 | 2d6 | Machine, Precision | 2d6 damage. Machine Precision: Double damage on single target. |
| Prototype Unit | Summon | 4 | 0 | Machine, Precision | Summon 3/2 Prototype. Machine: Gains +2 attack. Precision: Deals double damag... |
| Redundancy Core | Trap | 3 | 0 | Machine | Trap: When you would take damage, prevent it and gain 4 Shield instead. |
| Scanner Probe | Special | 1 | 0 | Machine | Look at top 3 cards of target deck. Put one on bottom, rest on top in any order. |
| Scrap Salvage | Field | 3 | 0 | Machine | Field: When one of your summons dies, draw 1 card and gain 1 Quiddity. Persist. |
| Standardization | Field | 4 | 0 | Machine, Persist | Field (Persist): All your Constructs have +1 Attack. |
| System Reset | Special | 3 | 0 | Machine | Return all your exhausted Construct cards to hand. Exhaust this card. |
| Tighten | Special | 2 | 0 | Machine | Target Construct gains +2 Attack and +2 HP permanently. |
| Torque Strike | Attack | 5 | 3d6 | Machine, Precision | 3d6 damage. Precision: If this is your only attack this turn, add +4 damage. |
| Turret Deployment | Trap | 3 | 2d6 | Machine, Trap | Trap: Cast 1, Trigger 0, Disarm 3. TRIGGER: Enemy attacks. Deal 2d6 damage to... |

### Demon (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Apocalypse | Attack | 8 | 4d10 | Pact | 4d10 damage. If you have 8+ Corruption, destroy target enemy. |
| Archdemon | Summon | 5 | 0 | Corruption, Pact | Summon 4/4 Archdemon. Corruption: Gains +1/+1 for every 3 Corruption you have... |
| Blood Frenzy | Attack | 3 | 3d6 | Corruption, Pact | Deal 3d6 damage. Corruption: For every 4 Corruption, this attack has +1 crit ... |
| Blood Pact | Special | 1 | 0 | Pact | Pay 3 HP. Gain 5 Attention this turn. Gain 1 Corruption. |
| Corrupting Presence | Field | 3 | 1 | Corruption, Pact | Field: Enemies take 1 damage at start of their turn. Corruption: Damage incre... |
| Dark Bargain | Special | 2 | 0 | Pact | Gain 5 Attention. At start of next turn, lose 5 HP. |
| Dark Pact | Special | 2 | 0 | Pact | Pay 2 HP. Next card costs 0. Gain 1 Corruption. |
| Demon Blade | Attack | 4 | 2d6 | Corruption | Deal 2d6. Corruption: For every 3 stacks, add +1d6. |
| Demon Lord | Summon | 6 | 0 | Corruption, Pact | Summon 5/5 Demon Lord. Corruption: On attack, heal for damage dealt. |
| Final Offer | Attack | 5 | 3d6 | Pact | 3d6 damage. Pact: After 3 turns, deal 3d6 again. |
| Hellchain | Attack | 4 | 2d6 | Corruption, Pact | 2d6 damage. Corruption: Chain to next enemy (repeat until no Corruption or enemy dies). |
| Hellchain Storm | Attack | 6 | 3d6 | Corruption, Pact | 3d6 to all enemies. Corruption: Chain to next enemy. |
| Hellfire | Attack | 5 | 3d6 | Corruption | 3d6 damage. Gain 2 Corruption. |
| Imp | Summon | 2 | 0 | Corruption, Pact | Summon 2/2 Imp. Corruption: At end of turn, deal 1 damage to random enemy. |
| Infernal Bargain | Special | 3 | 0 | Pact | Discard your hand. Draw 5 cards. Gain 2 Corruption. |
| Infernal Pact | Special | 2 | 0 | Pact | Pay 3 HP. Draw 2 cards. Gain 1 Corruption. |
| Painforged | Attack | 4 | 2d6 | Corruption | Deal 2d6. Corruption: +1 damage per stack. |
| Possession | Special | 3 | 0 | Corruption, Pact | Take control of target enemy for 2 turns. Corruption: They fight for you. |
| Sacrificial Lamb | Special | 1 | 0 | Pact | Sacrifice a summon. Gain 10 Attention. |
| Soul Drain | Attack | 3 | 1d6 | Corruption, Pact | 1d6 damage. Heal for damage dealt. Corruption: Heal doubled. |
| Soul Pact | Special | 2 | 0 | Pact | Pay 5 HP. Next card costs 0. |
| Summon Demon | Summon | 4 | 0 | Corruption, Pact | Summon 3/3 Demon. Corruption: +1/+1 per 2 stacks. |
| Temptation | Special | 2 | 0 | Pact | Look at top 3 cards of any deck. Draw one. Discard others. |
| Torment | Attack | 3 | 2d4 | Corruption | 2d4 damage. Corruption: Target loses next action. |
| Unholy Ritual | Special | 4 | 0 | Corruption, Pact | Discard 2 cards. Draw 4. Gain 2 Corruption. |
| Void Pact | Special | 3 | 0 | Pact | Pay 4 HP. Draw 3 cards. |

### Dragon (5 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Dragon's Wrath | Attack | 6 | 4d6 | - | 4d6 fire damage. |
| Dragonfire | Attack | 5 | 3d6 | Fire | 3d6 Fire damage to target enemy. |
| Scale Shield | Special | 2 | 0 | - | Gain 8 Shield. |
| Tiamat's Shadow | Attack | 7 | 4d8 | - | 4d8 damage. If you control 3+ Dragons, this hits target enemy. |
| Young Drake | Summon | 4 | 0 | First Strike | 4/6 with Growth. Attacks for 2d6. Gain 1 Quiddity when attacking. |

### Elemental (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Aether Spark | Attack | 2 | 1d6 | Nature | 1d6 damage. Nature: +2 per CHARGE. |
| Avalanche | Attack | 5 | 3d8 | Nature | 3d8 damage. Nature: Ignores Shield. |
| Catalyst | Special | 2 | 0 | Nature, Flow | Next Elemental card costs -1. Gain 1 CHARGE. |
| Cyclone | Attack | 4 | 1d6 | Flow | 1d6 damage. Flow: Consume all CHARGE. Each stack adds +1d6 damage. |
| Earthquake | Attack | 6 | 3d6 | Nature, Flow | 3d6 damage. Nature: Ignores Shield. Flow: Add +1d6 per CHARGE (max +2d6). |
| Ember | Attack | 1 | 1d4 | Fire | 1d4 fire damage. |
| Fireball | Attack | 3 | 2d6 | Fire | 2d6 fire damage. |
| Flame Warden | Summon | 4 | 0 | Fire, Nature | Summon 3/3 Flame Warden. Fire: On attack, apply Fire DoT. |
| Flare | Attack | 2 | 1d8 | Fire | 1d8 fire damage. |
| Frostbolt | Attack | 3 | 2d4 | Nature | 2d4 damage. Nature: +2 per CHARGE. |
| Ignite | Special | 2 | 0 | Fire | Apply Fire DoT (4 dmg/turn, 2 turns). |
| Inferno | Attack | 6 | 4d6 | Fire | 4d6 fire damage. |
| Lightning Bolt | Attack | 4 | 2d8 | Nature | 2d8 damage. Nature: +2 per CHARGE. |
| Mana Spring | Special | 2 | 0 | Nature | Gain 3 CHARGE. Draw 1 card. |
| Meteor | Attack | 7 | 5d6 | Fire, Nature | 5d6 damage. Nature: +2 per CHARGE. Fire: Apply Fire DoT. |
| Pyroclasm | Attack | 5 | 3d6 | Fire | 3d6 fire damage. Apply Fire DoT. |
| Stone Skin | Special | 2 | 0 | Nature | Gain 5 Shield. Nature: +2 Shield per CHARGE. |
| Storm | Attack | 5 | 2d10 | Nature, Flow | 2d10 damage. Flow: Consume CHARGE for extra dice. |
| Tidal Wave | Attack | 5 | 2d8 | Flow | 2d8 damage. Flow: If 3+ Flow cards in discard, +1d8. |
| Wildfire | Attack | 4 | 2d6 | Fire, Nature | 2d6 damage. Nature: +2 per CHARGE. Fire: Apply Fire DoT. |

### Goblin (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Backstab | Attack | 2 | 2d4 | Sneaky | 2d4 damage. Sneaky: +2d6 if enemy lacks Sneaky. |
| Cheap Shot | Attack | 1 | 1d6 | Sneaky | 1d6 damage. Sneaky: +2d6 if enemy lacks Sneaky. |
| Explosive Trap | Trap | 2 | 2d6 | Trap | Trap: Cast 2, Trigger 0, Disarm 1. TRIGGER: Enemy moves. 2d6 damage. |
| Filch | Special | 1 | 0 | Sneaky | Draw 2 cards. Sneaky: Draw 3 if enemy lacks Sneaky. |
| Goblin Ambush | Attack | 3 | 2d6 | Sneaky | 2d6 damage. Sneaky: +2d6 if enemy lacks Sneaky. |
| Goblin Horde | Summon | 4 | 0 | Sneaky | Summon THREE 1/1 Goblins. Sneaky: +1/+1 each. |
| Goblin Sapper | Special | 2 | 0 | Sneaky | Destroy target trap. Deal 2d4 damage to trap owner. |
| Goblin Scout | Summon | 2 | 0 | Sneaky, Fast | Summon 1/2 Scout. Fast: No summoning sickness. |
| Knife Toss | Attack | 2 | 1d8 | Sharp | 1d8 damage. Sharp: +1 damage. |
| Mug | Attack | 2 | 1d6 | Sneaky | 1d6 damage. Gain 1 Quiddity. Sneaky: +2d6. |
| Poison Blade | Attack | 3 | 1d6 | Poison, Sneaky | 1d6 damage. Apply Poison. Sneaky: +2d6. |
| Shank | Attack | 2 | 1d6 | Sneaky | 1d6 damage. Sneaky: +2d6 if enemy lacks Sneaky. |
| Shiv | Attack | 1 | 1d4 | Sharp | 1d4 damage. Sharp: +1 damage. |
| Sneak Attack | Attack | 3 | 2d6 | Sneaky | 2d6 damage. Sneaky: +2d6 if enemy lacks Sneaky. |
| Swindle | Special | 2 | 0 | Sneaky | Enemy loses 1d4 Quiddity. You gain it. |
| Thief's Reflex | Special | 2 | 0 | Sneaky | Next card costs -2. Sneaky: -3 instead. |
| Tripwire | Trap | 2 | 0 | Sneaky | Trap: Cast 2, Trigger 0, Disarm 1. TRIGGER: Enemy moves. 3 damage, loses next action. |

### Undead (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Bone Armor | Special | 2 | 0 | Bone | Gain 5 Shield. Bone: +shield = Attention cost. |
| Bone Shield | Special | 2 | 0 | Bone | Gain 4 Shield. Bone: +shield = Attention cost. |
| Bone Spear | Attack | 3 | 2d6 | Bone | 2d6 damage. Bone: +shield = Attention cost. |
| Corpse Explosion | Attack | 4 | 0 | Death | Sacrifice summon. Deal its HP as damage. |
| Dark Ritual | Special | 3 | 0 | Death | Sacrifice summon. Draw 3 cards. |
| Death Knight | Summon | 5 | 0 | Death | Summon 4/4 Death Knight. Death: Can cast from discard. |
| Death Touch | Attack | 3 | 2d6 | Death | 2d6 damage. Death: Can cast from discard. |
| Flesh Golem | Summon | 4 | 0 | Death | Summon 5/6 Bone Golem. Bone: When damaged, gain 1 GRASP. Death: At 0 HP, deal 2d6 damage. |
| Graveyard Shift | Special | 3 | 0 | Death | Return 2 cards from discard to hand. |
| Lich | Summon | 6 | 0 | Death | Summon 3/3 Lich. Death: On attack, apply random DoT. |
| Necromancy | Special | 4 | 0 | Death | Summon 2/2 Skeleton. Death: Summon another if you have Death card in discard. |
| Raise Dead | Special | 3 | 0 | Death | Return highest-cost card from discard to hand. |
| Reanimate | Special | 2 | 0 | Death | Return 1 card from discard to hand. |
| Skeleton | Summon | 2 | 0 | Death | Summon 2/2 Skeleton. Death: Can cast from discard. |
| Soul Harvest | Attack | 3 | 1d6 | Death | 1d6 damage. Heal for damage dealt. Death: Can cast from discard. |
| Zombie | Summon | 3 | 0 | Death | Summon 3/3 Zombie. Death: Can cast from discard. |

### Universal (30 cards)

| Name | Type | Attn | Dmg | Keywords | Effect |
|------|------|------|-----|----------|--------|
| Adapt | Special | 2 | 0 | - | Draw 2 cards of the faction you have most cards of. |
| Block | Special | 1 | 0 | - | Gain 3 Shield. |
| Draw | Special | 1 | 0 | - | Draw 2 cards. |
| Heal | Special | 2 | 0 | - | Heal 5 HP. |
| Quiddity Surge | Special | 0 | 0 | - | Gain 2 Quiddity. |
| Rest | Special | 0 | 0 | - | Heal 3 HP. Draw 1 card. |
| Second Wind | Special | 3 | 0 | - | Heal 10 HP. Clear all DoTs. |
| Sharpen | Special | 2 | 0 | - | Next attack deals +2 damage. |
| Study | Special | 2 | 0 | - | Look at top 3 cards of your deck. Put back in any order. |
| Swap | Special | 1 | 0 | - | Swap a card in hand with one from discard. |

### Overlays (30 cards)

Overlays are special card modifications that fuse onto existing cards. They cost 0 Attention, count as 2 cards toward the Compiler threshold, and return to hand after 3 turns.

**Types:** Arcane (Construct/Aberration), Divine (Elemental/Undead), Infernal (Demon/Goblin/Dragon)

| Name | Type | Overlay | Effect |
|------|------|---------|--------|
| Arcane Infusion | Overlay | Arcane | +2 damage, draw 1 card |
| Divine Blessing | Overlay | Divine | +3 HP heal when played |
| Infernal Wrath | Overlay | Infernal | Summon 4/8 with Growth. At 5+ Corruption, has First Strike. Gain 1 Corruption. Returns after 3 turns. |
| Infernal Pact | Overlay | Infernal | Summon 3/6 with First Strike. Heal 2 on attack. Gain 1 Corruption. Returns after 3 turns. |

---

## 6. DUNGEON FLOORS (From Code)

| Floor | Name | Theme | Faction Focus | Key Mechanics |
|-------|------|-------|---------------|---------------|
| 1 | Portal Room | Transit/tutorial | Construct | Transit tokens, tutorial combat |
| 2 | The Fungal Cavern | Living caves | Aberration | Spore states, elevator repair, toxic pools |
| 3 | The Gearworks | Clockwork factory | Construct | Machinist shop, 12 puzzle rooms, kami shrines |
| 4 | The Curio Bazaar | Abandoned mall (×3 levels) | Goblin | Three-level vertical dungeon, shops |
| 5 | The Airship Docks | Mooring towers | Elemental | Breeze/boiler/gale valves, wind/steam/lightning/aether charge states |
| 6 | The Lunar University | Academic quadrangle | Universal/Aberration | Courses, grades, clocktower, master key, goblin janitor |
| 7 | The Broken Pact | Void-torn contracts | Demon | Pact signing, void cracks, docket weight |
| 8 | The Overclock Forge | Elemental foundry | Elemental | Overclock meter, elemental vessels, venting |
| 9 | The Bone Forges | Necromantic factory | Undead | Bone count, soul debt, liberator status |
| 10 | The Dragon's Lair | Boss arena | Dragon | 11 Moments, ghost bosses, four endings, Cano Protocol |

**Non-wall hex counts:** F1: 806, F2: 914, F3: 1,349, F4: 1,038, F5: 784, F6: 3,616, F7: 2,393, F8: 2,621, F9: 1,844, F10: 981

---

## 7. WORLD LAYER & COMBAT ARCHITECTURE

### Overworld
- **Grid:** Pointy-top hexes (axial coordinates, cube distance)
- **Movement:** WEADZX keyboard + click-to-move (NOT WASD)
- **Camera:** Follows player, viewport-relative UI (1280×720 base)

### Combat
- **Menu-based targeting:** Enemies are an index array (no hex positions in combat)
- **Turn order:** Player → Summons → Enemies (each enemy acts once)
- **Enemy patterns:** ATTACK → DEFEND → SPECIAL (repeating)

### Future Systems (Unimplemented)
- Time-dilation based on Attention state
- Aggro-by-Attention (enemies react to player's Attention level)
- Reinforcement spawns
- Positional combat on hex grid (AoE/Radius/Line/Cone)

---

## 8. GEAR SYSTEM

### Weapons (5)

| ID | Name | Floor | Charge | Start Ready | Damage | Cost | Special |
|----|------|-------|--------|-------------|--------|------|---------|
| goblin_shiv | Goblin Shiv | 1 | 2 | Yes | 3–6 | 15 | Fast, ready immediately |
| gearwork_hammer | Gearwork Hammer | 3 | 3 | No | 5–10 | 25 | Breaks shields, needs windup |
| aether_channel | Aether Channel | 5 | 4 | Yes | 4–8 | 40 | Ignores block |
| pact_blade | Pact Blade | 7 | 5 | No | 8–15 | 60 | Costs HP to swing, heals on kill |
| dragon_maw | Dragon Maw | 9 | 3 | Yes | 6–12 | 80 | Hits all enemies, attention distributes |

### Armor (5)

| ID | Name | Floor | HP Bonus | Special | Cost |
|----|------|-------|----------|---------|------|
| goblin_scrap | Goblin Scrap | 1 | +5 | +1 Quiddity per kill | 10 |
| gearworks_plate | Gearworks Plate | 3 | +10 | Ignore first trap damage per floor | 20 |
| aether_weave | Aether Weave | 5 | +15 | +1 card draw per turn | 35 |
| pactbound_mail | Pactbound Mail | 7 | +20 | 50% resist first debuff per combat | 50 |
| dragonbone | Dragonbone | 9 | +30 | Survive first lethal hit per combat | 75 |

### Shields (3 types)

| Type | Effect |
|------|--------|
| Block | Reduces incoming damage by flat amount |
| Retributive | Blocks damage AND deals return damage to attacker |
| Special Negates | Completely nullifies specific attack types |

### Trinkets (10)

Per-trinket unique effects parsed from description strings. Examples:
- **Veil Piercer:** +1 Attention at turn start
- **Catalyst Ring:** Elemental cards charge faster (+1 bonus CHARGE)

---

## 9. BOSSES

Seven bosses with telegraphed rotations and Phase 2 at 50% HP:

| Boss | Floor | Theme |
|------|-------|-------|
| The Geode Heart | 1 | Construct |
| The Spore Mother | 2 | Aberration |
| The Machinist | 3 | Construct |
| The Debt Collector | 4 | Goblin |
| The Windcaller | 5 | Elemental |
| The Dean | 6 | Universal |
| The Contract | 7 | Demon |
| The Scram | 8 | Elemental |
| The Soul Warden | 9 | Undead |
| The Dragon | 10 | Dragon (replaced by Compiler at 50+ cards) |

**The Interview & The Eidolon** — Aberration faction's soul. The Eidolon mirrors your last damage dealt.

---

## 10. RAGNAROK

**Status:** Legend — implementation pending (K3 R4)

Five cards across five factions (no Construct). Play any one → all five auto-play for 0 cost → instant win. "The Observer blinks." Gated to Floor 10.

---

## 11. ENDINGS (Floor 10)

Four endings based on cross-floor choices:

| Ending | Condition |
|--------|-----------|
| Destroy | Defeat the Dragon |
| Become | Accept the Dragon's power |
| Walk Away | Refuse both |
| True | Complete all 11 Moments, speak to all ghosts, touch all hoard objects |

---

## 12. DESIGN HISTORY (Superseded)

### Card Count Evolution
- **Original GDD (Mar 2026):** 245 cards claimed, 189/240 mid-doc, overlays "0/30 ❌ MISSING"
- **Canonical count (Aug 2026):** 240 cards exactly (verified from `finished_cards/*.tres`)

### Mechanics That Changed
- **Debt:** Originally complex debt system → simplified to hard cap 20 + Pact overflow
- **Corruption:** Player-side resource proposed, unimplemented → enemy DoT renamed to Taint
- **AoE:** Radius/Line/Cone taxonomy in GDD, unimplemented → stripped from descriptions
- **Stake:** Originally "persists" → clarified as per-turn decision, resets after draw

### Floor Names That Changed
- Tutorial Mines → Portal Room
- Elemental Depths → Fungal Cavern
- Bone Treasury → Bone Forges
- Confluence → Curio Bazaar
- Dragon's Approach → Dragon's Lair

---

## APPENDIX: VERIFICATION PHRASE

> "The code is the document. The library is canonical. When in doubt, grep."
