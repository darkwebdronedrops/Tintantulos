# CONSTRUCT ENEMIES — 30 Total
## Faction Philosophy: Assembly, Combination, Certainty
## HP Scaling: Low (1-6), Mid (8-12), High (15-25)

---

## FLOORS 1-2 (Starter Tier) — 6 Enemies
**HP Range: 1-4**

| # | Enemy | HP | Pattern | Weight | Special Mechanic |
|---|-------|----|---------|--------|------------------|
| 1 | Loose Gear | 1 | Melee→Defend→Defend | Common | **Combine:** If 2+ Loose Gears in combat, merge into Tight Gear after 2 turns |
| 2 | Tight Gear | 3 | Melee→Melee→Defend | Common | **Summon Defend:** When defending, summon Loose Gear (max 2) |
| 3 | Winding Spring | 2 | Special→Melee→Defend | Common | **Wind Up:** Special charges next Melee (+2 damage) |
| 4 | Brass Knuckle | 4 | Melee→Melee→Melee | Uncommon | **Relentless:** Enemies within 2 hexes skip Defend actions (execute next action instead) |
| 5 | Calibration Drone | 2 | Special→Defend→Special | Rare | **Scan:** Special reveals player's highest-cost card in hand |

**Combining Example:**
- 3 Loose Gears spawn → After 2 turns, they animate toward each other → Merge into Tight Gear with 9 HP (3×3) → Tight Gear can summon more Loose Gears

---

## FLOORS 3-4 (Early Tier) — 6 Enemies
**HP Range: 4-8**

| # | Enemy | HP | Pattern | Weight | Special Mechanic |
|---|-------|----|---------|--------|------------------|
| 6 | Gear Pair | 4 | Melee→Defend→Special | Common | **Combine:** Merge with another Gear Pair into Gear Quartet after 3 turns |
| 7 | Gear Quartet | 8 | Melee→Melee→Special→Defend | Common | **Summon Defend:** Summon Gear Pair when defending (max 1) |
| 8 | Piston Assembly | 6 | Special→Melee→Defend | Common | **Compress:** Special stores damage, releases on next Melee (+stored) |
| 9 | Clockwork Hound | 5 | Melee→Special→Flee | Uncommon | **Chase:** Special = Rush player (close distance), Flee = Reset to max range |
| 10 | Diagnostic Eye | 4 | Special→Defend→Special | Rare | **Analyze:** Special reveals player's deck faction breakdown |

---

## FLOORS 5-6 (Mid Tier) — 6 Enemies
**HP Range: 8-15**

| # | Enemy | HP | Pattern | Weight | Special Mechanic |
|---|-------|----|---------|--------|------------------|
| 11 | Gear Train | 8 | Melee→Defend→Special | Common | **Combine:** Link with 1 other Gear Train. When one acts, all linked act simultaneously (same action, same target). Each still gets its own separate turn. |
| 12 | Engine Block | 15 | Melee→Melee→Special | Common | **Summon Defend:** Summon Gear Train when HP drops below 50% |
| 13 | Pressurized Cylinder | 10 | Special→Melee→Defend | Common | **Vent:** Special = Charge (gain 5 Shield), next Melee = Release (damage = Shield) |
| 14 | Brass Enforcer | 12 | Melee→Special→Melee | Uncommon | **Overclock:** Special = Take 3 damage, next 2 attacks deal +4 damage |
| 15 | Logic Core | 8 | Special→Defend→Special | Rare | **Calculate:** Special predicts player's next card type (80% accuracy) |

---

## FLOORS 7-8 (High Tier) — 6 Enemies
**HP Range: 12-20**

| # | Enemy | HP | Pattern | Weight | Special Mechanic |
|---|-------|----|---------|--------|------------------|
| 16 | Assembly Line | 12 | Melee→Defend→Special | Common | **Combine:** Each turn, if another Construct within 3 hexes, merge HP (max 24) |
| 17 | Prime Mechanism | 20 | Melee→Melee→Special→Defend | Common | **Summon Defend:** Summon Assembly Line, gain its HP as Shield |
| 18 | Kinetic Battery | 15 | Special→Melee→Defend | Common | **Store/Release:** Special absorbs next attack, Melee releases stored damage ×2 |
| 19 | Immutable Sentinel | 18 | Defend→Defend→Melee | Uncommon | **Immutable:** Ignores first 2 damage each turn, fixed damage output |
| 20 | System Architect | 14 | Special→Special→Melee | Rare | **Rewrite:** Special changes one of player's card costs (+2 or -2) for 2 turns |

---

## FLOORS 9-10 (End Tier) — 6 Enemies
**HP Range: 18-25**

| # | Enemy | HP | Pattern | Weight | Special Mechanic |
|---|-------|----|---------|--------|------------------|
| 21 | Master Gear | 18 | Melee→Defend→Special | Common | **Combine:** Absorbs any defeated Construct, gains its max HP and pattern |
| 22 | The Immutable | 25 | Special→Melee→Defend | Common | **Summon Defend:** Summon copy of self at 50% HP (once) |
| 23 | Perfect Engine | 22 | Melee→Special→Melee→Defend | Common | **Optimize:** Special removes all randomness (fixed damage, fixed everything) for 2 turns |
| 24 | Recursive Loop | 20 | Melee→Defend→Special | Uncommon | **Loop:** When killed, returns at 50% HP once (Immortal for 1 turn) |
| 25 | Final Calculation | 18 | Special→Special→Melee | Rare | **Compute:** Special locks all dice to average (3.5) for 2 turns |

---

## BOSS ENEMIES — 5 Total

| # | Enemy | HP | Floor | Pattern | Mechanic |
|---|-------|----|-------|---------|----------|
| 26 | The Gear Mother | 30 | 3 (Mini) | Melee→Summon→Defend→Special | **Birth:** Summon 2 Loose Gears each turn. Combine into stronger forms. |
| 27 | The Assembly | 40 | 6 | Melee→Melee→Special→Defend | **Collective:** Starts with 5 Gear Pairs. Each killed empowers remaining (+2 damage) |
| 28 | The Immutable Prime | 50 | 9 | Defend→Special→Melee→Melee | **Perfection:** Ignores all status, fixed damage, cannot be debuffed |
| 29 | The Compiler Fragment | 35 | Secret | Variable | **Debug:** Destroys random player card each turn. Spawns if deck >40 cards. |
| 30 | The First Machine | 60 | 10 (Dragon Alt) | Melee→Special→Defend→Special→Melee | **Origin:** Combines all defeated Constructs this run. Gains their abilities. |

---

## COMBINING MECHANICS — DETAILED

### Visual Feedback
- Gears emit sparks when ready to combine
- Audible clicking intensifies
- Gears animate toward each other over 1 turn
- Merge animation: interlock, glow, resize

### Combination Rules
1. **Same-type only:** Loose Gear + Loose Gear, not Loose + Tight
2. **HP addition:** Combined HP = sum of components (capped at tier max)
3. **Pattern upgrade:** Simple → Complex (3-action → 4-action)
4. **Summon capability:** Most combined forms gain summon-on-defend
5. **Interruptible:** If one gear killed before merge, combination fails

### Strategic Implications
- **Kill quickly:** Prevent combinations
- **Let combine then kill:** Fewer enemies, but stronger
- **AoE value:** Damage both before they merge
- **Trap placement:** Catch merging gears mid-animation

---

## PATTERN LEGEND

| Symbol | Meaning |
|--------|---------|
| Melee | Physical attack at 1-hex range |
| Ranged | Physical attack at 2+ hex range |
| Defend | +Shield, may summon, may block |
| Special | Faction-specific ability |
| Flee | Move away, reset engagement |

---

## SPAWN WEIGHTS BY FLOOR

| Floor | Common (60%) | Uncommon (30%) | Rare (10%) |
|-------|--------------|----------------|------------|
| 1 | Loose Gear, Tight Gear, Winding Spring | Brass Knuckle | Calibration Drone |
| 2 | Same as Floor 1 | Same as Floor 1 | Same as Floor 1 |
| 3 | Gear Pair, Gear Quartet, Piston Assembly | Clockwork Hound | Diagnostic Eye |
| 4 | Same as Floor 3 | Same as Floor 3 | Same as Floor 3 |
| 5 | Gear Train, Engine Block, Pressurized Cylinder | Brass Enforcer | Logic Core |
| 6 | Same as Floor 5 | Same as Floor 5 | Same as Floor 5 |
| 7 | Assembly Line, Prime Mechanism, Kinetic Battery | Immutable Sentinel | System Architect |
| 8 | Same as Floor 7 | Same as Floor 7 | Same as Floor 7 |
| 9 | Master Gear, The Immutable, Perfect Engine | Recursive Loop | Final Calculation |
| 10 | Same as Floor 9 | Same as Floor 9 | Same as Floor 9 |

---
*30 Construct enemies. Combining mechanics. Learnable patterns.*
*The machine builds itself. The gears turn. The assembly grows.*
