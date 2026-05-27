# ACANOUS CARD BATTLER — ENEMY SYSTEM
## Date: 2026-03-01
## Enemy Spawn, Patrol, and Behavior

---

## SPAWN SYSTEM

### Level Load Sequence
1. **Roll Total Enemies:** Based on floor depth
2. **Assign Factions:** Weighted by floor allowed factions
3. **Pick Enemy Types:** Weighted random from faction lists
4. **Spawn at Patrol Points:** Random valid locations
5. **Begin Patrol:** Simple right-hand rule behavior

### Enemy Count by Floor
| Floor | Min | Max | Roll |
|-------|-----|-----|------|
| 1 | 2 | 4 | 1d3+1 |
| 2 | 3 | 5 | 1d3+2 |
| 3 | 3 | 6 | 1d4+2 |
| 4 | 4 | 7 | 1d4+3 |
| 5 | 4 | 8 | 1d4+4 |
| 6+ | 5 | 10 | 1d6+4 |

### Faction Assignment by Floor
| Floor | Primary Faction | Secondary Faction | Weight |
|-------|-----------------|-------------------|--------|
| 1 | Construct | Goblin | 60/40 |
| 2 | Goblin | Construct | 60/40 |
| 3 | Undead | Goblin | 60/40 |
| 4 | Undead | Elemental | 60/40 |
| 5 | Elemental | Demon | 60/40 |
| 6 | Demon | Elemental | 60/40 |
| 7 | Aberration | Demon | 60/40 |
| 8 | Aberration | Undead | 60/40 |
| 9 | Mixed | Mixed | 25/25/25/25 |
| 10 | Dragon | — | 100 |

---

## FACTION ENEMY LISTS

### CONSTRUCT ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Training Dummy | 3 | Defend→Special→Defend | Common | 1 |
| Gear Drone | 5 | Melee→Defend→Melee | Common | 1 |
| Clockwork Sentinel | 8 | Melee→Defend→Ranged | Uncommon | 2 |
| Brass Enforcer | 15 | Melee→Melee→Special | Rare | 5 |
| The Immutable | 30 | Calculate/Execute | Boss | 9 |

---

### GOBLIN ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Skitterling | 2 | Melee→Melee→Flee | Common | 1 |
| Rustblade | 4 | Melee→Defend→Melee | Common | 1 |
| Goblin Sapper | 6 | Special→Melee→Special | Uncommon | 2 |
| Wolf Rider | 10 | Melee→Ranged→Melee | Uncommon | 3 |
| Shaman | 8 | Special→Special→Melee | Rare | 2 |
| War Chief | 18 | Melee→Buff→Melee | Rare | 6 |

---

### UNDEAD ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Rattlebone | 4 | Melee→Defend→Melee | Common | 2 |
| Forgotten Soldier | 6 | Melee→Defend→Ranged | Common | 3 |
| Crypt Walker | 8 | Defend→Melee→Special | Uncommon | 3 |
| Bone Collector | 12 | Special→Melee→Melee | Uncommon | 4 |
| Hollow Knight | 20 | Defend→Defend→Melee | Rare | 6 |
| The Lich Unfinished | 40 | Variable | Boss | 10 |

---

### ELEMENTAL ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Ash Wisp | 2 | Ranged→Special→Defend | Common | 3 |
| Sparkling | 4 | Melee→Ranged→Melee | Common | 3 |
| Root Witch | 10 | Special→Defend→Ranged | Uncommon | 4 |
| Stone Elemental | 18 | Defend→Defend→Melee | Uncommon | 5 |
| Storm Caller | 15 | Ranged→Ranged→Special | Rare | 5 |
| The Ancient | 50 | Variable | Boss | 10 |

---

### DEMON ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Ichor Mite | 4 | Melee→Melee→Special | Common | 4 |
| Hungering Wisp | 8 | Special→Ranged→Ranged | Common | 5 |
| Pain Hound | 12 | Melee→Special→Melee | Uncommon | 5 |
| Gluttony Demon | 15 | Melee→Special→Melee | Uncommon | 6 |
| The Lie | 25 | Variable | Rare | 7 |

---

### ABERRATION ENEMIES
| Enemy | HP | Pattern | Weight | Floor Min |
|-------|----|---------|--------|-----------|
| Glitch Wisp | 3 | Random | Common | 5 |
| Void Hound | 10 | Melee→Random→Ranged | Common | 6 |
| Paradox Knight | 18 | Special→Special→Melee | Uncommon | 7 |
| Fractal Horror | 25 | Variable | Rare | 8 |
| The Unraveling | 30 | Variable | Boss | 9 |

---

## PATROL AI

### Right-Hand Rule Algorithm
1. Start facing random direction (0-5 hex)
2. Move forward 1 hex
3. If obstacle (wall, pit, other enemy): Turn right (clockwise), try move
4. Continue forward
5. If interrupted by player: Switch to Alert state
6. After combat/lose LOS: Resume patrol, reset to step 1

### Patrol Properties
- **Speed:** 0.5 hexes/second (world time)
- **Turn delay:** 0.2 seconds at obstacles
- **Shared zones:** Multiple enemies can patrol same area
- **Resume:** After combat, return to nearest patrol point, continue

### Spawn Validation
- **Min distance from player:** 8 hexes
- **Not in LOS:** Behind walls/obstacles
- **Valid terrain:** Walkable hex only
