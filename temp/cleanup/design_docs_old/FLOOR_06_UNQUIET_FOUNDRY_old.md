# THE UNQUIET FOUNDRY — Floor 6 Complete Design
## WHAT / WHY / HOW
- **WHAT:** Industrial horror floor (Floor 6 of 10) — the factory that never stops, where the dead keep working
- **WHY:** Teach resource exhaustion, introduce Undead GRASP mastery, first "suffocating" environment
- **HOW:** A Construct foundry where the machines are alive, the workers are dead, and the product is whatever you fear most

---

## FLOOR ARCHITECTURE

**Shape:** L-shaped factory floor with mezzanine, catwalks, and subterranean smelting pit
**Theme:** Steampunk industrial nightmare — molten brass, conveyor lines, assembly belts, endless production
**Levels:**
- **The Assembly Floor (Main):** Conveyor belts, stamping presses, gear assembly stations
- **The Mezzanine (Upper):** Overseer's walkway, control panels, break room (haunted)
- **The Smelting Pit (Lower):** Molten brass pool, crucibles, where the waste goes
- **The Foreman's Office:** Boss arena — corner office with glass walls overlooking the floor

**Key Features:**
- **Conveyor Belts:** Constant movement — player is slowly pushed toward hazards unless actively moving against flow
- **Stamping Presses:** Periodic slam (every 4 turns) — 3d6 crushing damage in marked zones
- **Assembly Stations:** Interactive — can be sabotaged, redirected, or used to create items
- **Molten Brass Pool:** Environmental hazard — proximity causes heat DOT, can be pushed into for instant death

---

## CORE MECHANIC

**"The Production Line"**
- Every 3 turns, a new "product" spawns on the conveyor — could be loot, could be an enemy, could be a trap
- Player can redirect the line at control stations to change what spawns (Construct maintenance = reroll)
- Undead workers periodically fall from the mezzanine (suicide/jumping), adding bodies to the line
- Too many bodies = production jam = all spawns become Undead until cleared

**Production States:**
| State | Trigger | Effect |
|-------|---------|--------|
| **Normal** | Player active | Mixed spawns (loot, enemies, traps) |
| **Overtime** | 5+ turns without control station use | Spawn rate doubles, enemies get +2 damage |
| **Strike** | 3+ Undead on line | All spawns are Undead, line stops moving |
| **Shutdown** | Sabotage control station | Line stops for 3 turns, no spawns, but boss alerted |

---

## FACTION DISTRIBUTION

| Faction | Presence | Location | Role |
|---------|----------|----------|------|
| **Construct** | Primary | Assembly Floor, Mezzanine | Factory machinery, assembly automata, stamping presses |
| **Undead** | Secondary | Smelting Pit, break room, falling from mezzanine | Dead workers who won't quit, suicides, debt-labor |
| **Goblin** | Single | Hidden maintenance tunnel | Saboteur, stowaway, union agitator |
| **Elemental** | Absent | — | No open flame, no air — contained industry |
| **Demon** | Absent | — | No deals, just contracts already signed |
| **Aberration** | Absent | — | No glitch, just grinding precision |

---

## ENVIRONMENTAL HAZARDS

### Conveyor Belts
- **Location:** Assembly Floor main paths
- **Effect:** Every turn, player slides 1 hex toward nearest hazard (stamper, smelting pit) unless actively moving against flow
- **Counter:** Can ride with flow for speed, but lose control
- **Lore:** "The line never stops. You can step off, but the line doesn't care."

### Stamping Presses
- **Location:** Assembly Floor, marked zones with warning lights
- **Effect:** Every 4 turns — 3d6 crushing damage if in zone
- **Tell:** Warning light turns red 1 turn before, press rises, hydraulic hiss
- **Use:** Can lure enemies into zones, press kills indiscriminately

### Molten Brass Pool
- **Location:** Smelting Pit, center of lower level
- **Effect:** Proximity = 2 DOT per turn. Pushed in = instant death (no save)
- **Counter:** Heat resistance gear, cooling valves
- **Lore:** "The brass remembers everyone who's fallen in. It sings with their voices."

### Toxic Vents
- **Location:** Mezzanine and break room
- **Effect:** Standing near = -1 Attention per turn, hallucinations (fake enemies appear)
- **Source:** Undead decomposition + industrial fumes

---

## ROOM DETAILS

### Assembly Floor (Entry)

**Start:** Elevator from Floor 5 (Airship Docks) deposits player on conveyor loading zone
**Features:**
- Immediate conveyor tutorial — player is pushed toward stamper unless they move
- Control Station 1 visible but locked (needs gear key)
- Factory noise: constant clanking, steam, distant screams

**Enemies:**
| Encounter | Type | Purpose |
|-----------|------|---------|
| **Assembly Drone x2** | 1v2 | Basic Construct — teaches line mechanics |
| **Calibration Drone** | 1v1 | First "technical" enemy — teaches control station interaction |

**Puzzle:** The First Station
- Control Station 1 is locked
- Gear key found in nearby locker (guarded by Assembly Drone)
- Unlocking = can redirect line away from player spawn

---

### The Mezzanine (Upper)

**Theme:** Overseer's walkway, control panels, break room with toxic vents
**Layout:** Catwalks overlooking Assembly Floor, access to 3 more control stations

**Enemies:**
| Encounter | Type | Purpose |
|-----------|------|---------|
| **Brass Enforcer** | 1v1 | Heavy Construct — teaches defense timing |
| **Final Notice** | 1v1 | First Undead — dead foreman who keeps writing warnings |
| **Tax Collector** | Solo | Undead — drains resources, teaches GRASP |

**Break Room:**
- **Toxic vent zone** — hallucination enemies appear (fake, but cost Attention to identify)
- **Lunchbox:** Contains health item, but eating causes "Nostalgia" (emotion vulnerability)
- **Suicide Note:** Dead worker's last message — lore, hints at boss weakness

**Puzzle:** The Overseer's Panel
- 3 control stations must be synchronized (all set to same mode) to unlock Smelting Pit
- Modes: Normal / Overtime / Strike / Shutdown
- Wrong combination = enemies spawn, line goes into Overtime

---

### The Smelting Pit (Lower)

**Theme:** Molten brass pool, crucibles, where the waste goes
**Layout:** Circular pit with narrow walkways, heat distortion, brass-singing

**Enemies:**
| Encounter | Type | Purpose |
|-----------|------|---------|
| **Marrow Priest** | 1v1 | Undead — bone religion in the pit, teaches DOT resistance |
| **Marrow Wisp** | 1v1 | Undead — marrow-light healing, teaches resource denial |
| **Flesh Garden** | 1v1 | Undead — first "named" Undead, harder pattern |

**Puzzle:** The Crucible
- Brass pool must be cooled to cross
- Cooling requires redirecting conveyor to dump "product" into pool (sacrifices loot)
- Alternative: Find heat-resistant gear in Mezzanine break room

---

### Secret Room — "The Maintenance Tunnel"

**Access:** Hidden panel behind Control Station 3 (scratched marks, goblin graffiti)
**Enemy:** **Sneak Thief** (single Goblin)

#### Sneak Thief
**Type:** Goblin (saboteur/union agitator)
**HP:** 10 | **Pattern:** Steal→Melee→Flee→Steal
**Mechanic:** "Agitation" — Steals 1 card from hand, but gives player "Strike" status (all enemies take +1 damage next turn)
**Visual:** Goblin in worker's overalls, carrying wrench, grinning with solidarity
**Purpose:** Teaches that not all enemies are hostile — some are opportunists. Goblin here is a saboteur, not a fighter.

**Reward:** No Transit Token. Drops "Union Pin" (reduces Overtime duration by 1 turn).

---

### The Foreman's Office — Boss Arena

**Access:** Through glass-walled corridor from Mezzanine (after synchronizing control stations)
**Layout:** Corner office overlooking entire factory floor — player can see the line from above

#### Floor 6 Boss: The Immutable Sentinel

**Classification:** Construct (Boss) — the factory's final failsafe, an overseer that cannot be bargained with
**HP:** 70
**Pattern:** Defend→Melee→Special→Defend→Repeat

**Abilities:**
| Action | Effect |
|--------|--------|
| **Defend: Lockdown** | Gains massive block, line goes into Overtime, all spawns become hostile |
| **Melee: Disciplinary Action** | Heavy damage + applies "Written Up" (card costs +1 for 2 turns) |
| **Special: Performance Review** | Steals 1 random card from hand, "files it" (returns after boss dies) |
| **Passive: Immutable** | Cannot be debuffed, status effects last 1 turn only |

**Phase Transition (at 35 HP):**
- Office walls shatter, boss falls onto Assembly Floor
- Now affected by conveyor belts, stamping presses, line spawns
- Pattern changes: Melee→Special→Melee→Special (no Defend)
- **Tactical shift:** Player can lure boss into stampers, use line spawns as distraction

**Reward:** Factory Key (unlocks Floor 7), Construct boss card, 100 Gems

---

## RE-RUN BEHAVIOR

### First Run
- Full conveyor tutorial
- All control stations must be found and used
- Boss phase teaches environmental exploitation

### Subsequent Runs
- Player spawns on Assembly Floor
- Conveyor already redirected (if player left it that way)
- All enemies and loot respawn
- Boss can be challenged immediately if control stations already synchronized

---

## PROGRESSION FLOW

1. **Arrive:** Elevator from Floor 5 → Assembly Floor loading zone
2. **Learn:** Conveyor mechanics, stamping presses, line spawns
3. **Ascend:** Mezzanine — control stations, toxic break room, Undead encounters
4. **Descend:** Smelting Pit — Undead depth, crucible puzzle
5. **Secret:** Maintenance tunnel — Goblin saboteur
6. **Boss:** The Foreman's Office → Immutable Sentinel
7. **Reward:** Factory Key → Floor 7

---

## DESIGN NOTES

- **Suffocating industry:** First floor where the environment is actively hostile — no safe spots
- **Undead as labor:** Dead workers who keep working, suicides, debt-labor — Undead as tragic, not just scary
- **Construct as system:** The factory is the enemy. The machines don't hate you. They don't care about you.
- **Goblin as saboteur:** Hidden union agitator — not hostile, opportunistic, gives player advantage
- **Pacing:** ~25-30 minute first run, ~12 minutes on re-runs
- **Visual hook:** Brass and blood, molten glow, endless conveyor, the line never stops

**Status:** Design Complete  
**Ready for:** Implementation, sprite blocking  
**Total Floors Designed:** 6/10

---

*The line never stops. The dead keep working. The brass remembers.*  
*Floor 6 of 10 — The Unquiet Foundry*

❤️‍🔥