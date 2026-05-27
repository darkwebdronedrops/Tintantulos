# ENEMY INDEX
## Where to find every enemy in the project

**Location:** `acanous_floor3_demo/enemies/`

---

## Quick Navigation

| Faction | Count | Design Doc | JSON Data | Bosses |
|---------|-------|------------|-----------|--------|
| **Construct** | 30 + 5 bosses | [`Construct/CONSTRUCT_ENEMIES.md`](Construct/CONSTRUCT_ENEMIES.md) | [`Construct/*.json`](Construct/) | [`Construct/`](Construct/) — The Gear Mother, The Assembly, The Immutable Prime, The Compiler Fragment, The First Machine |
| **Goblin** | 30 + 5 bosses | [`Goblin/GOBLIN_ENEMIES_WORKING.md`](Goblin/GOBLIN_ENEMIES_WORKING.md) | [`Goblin/*.json`](Goblin/) | [`Goblin/`](Goblin/) — The Snotling King, Chieftain Grak, The Shadow That Walks, The Bomb Mother, Goblin King Grimgut |
| **Elemental** | 30 + 5 bosses | [`Elemental/ELEMENTAL_ENEMIES_WORKING.md`](Elemental/ELEMENTAL_ENEMIES_WORKING.md) | [`Elemental/*.json`](Elemental/) | [`Elemental/`](Elemental/) — The Caldera, The Abyssal Plane, The Geometric, The Jet Stream, The Elemental Core |
| **Undead** | 30 + 5 bosses | [`Undead/UNDEAD_ENEMIES_WORKING.md`](Undead/UNDEAD_ENEMIES_WORKING.md) | [`Undead/*.json`](Undead/) | [`Undead/`](Undead/) — The Unsent Letter, The Treasury of Bone, The Devouring Past, The Recursive Doubt, The Final Inheritance |
| **Demon** | 30 + 5 bosses | [`Demon/DEMON_ENEMIES_WORKING.md`](Demon/DEMON_ENEMIES_WORKING.md) | [`Demon/*.json`](Demon/) | [`Demon/`](Demon/) — The Interview, The Confession, The Embrace, The Edge, The Choice |
| **Aberration** | 30 + 5 bosses | [`Aberration/ABERRATION_ENEMIES_COMPLETE.md`](Aberration/ABERRATION_ENEMIES_COMPLETE.md) | [`Aberration/*.json`](Aberration/) | [`Aberration/`](Aberration/) — The Consumption, The Confluence, The Replacement, The Certainty, The Cano Protocol |

**Total: 180 standard enemies + 30 bosses = 210 entities**

---

## Supporting Documents

| File | What It Is |
|------|------------|
| [`ENEMIES_BY_FACTION.md`](ENEMIES_BY_FACTION.md) | Master comparison table — all 6 factions side by side with mechanics, visuals, feel |
| [`ENEMY_SYSTEM.md`](ENEMY_SYSTEM.md) | Spawn system, patrol AI, faction assignment by floor, enemy count scaling |
| [`ENEMY_AUDIT_COMPLETE.md`](ENEMY_AUDIT_COMPLETE.md) | Verification report — what's implemented vs. what's designed |

---

## Faction Mechanics at a Glance

| Faction | Core Mechanic | Counterplay | Feel |
|---------|---------------|-------------|------|
| **Construct** | COMBINE — merge into stronger forms | Kill before they combine | Industrial, methodical |
| **Goblin** | SWARM — bonuses from nearby allies | AoE, kill the leader | Chaotic, numerical |
| **Elemental** | CHARGE — build power, unleash at peak | Force early release | Escalating, explosive |
| **Undead** | GRASP — steal cards, Quiddity, memory | Reclaim stolen, diversity | Grief, economic |
| **Demon** | PACT — offers with hidden costs | Refuse, or accept and pay | Seductive, corrupting |
| **Aberration** | GLITCH — loss of agency, system breaks | Novelty, unpredictability | Paranoia, unreality |

---

## Floor Assignment

| Floor | Primary | Secondary | Aberration Presence |
|-------|---------|-----------|---------------------|
| 1 | Goblin | Construct | The Flicker, The Echo, The Blank |
| 2 | Undead/Elemental/Construct | — | The Wrong Door, The Afterimage, The Copycat |
| 3 | Construct | Demon/Aberration | The Bug, The Duplicate, The Loop |
| 4 | Aberration | Goblin/Elemental | The Forgotten, The Lag, The Autosave, The Cursor, The Mirror Self |
| 5 | Elemental | Undead/Goblin | The Resonance (secret) |
| 6 | Construct/Undead | — | The Attendance Record, The Schedule Conflict, The Wind Shear Ghost, The Cheating Student, The Dropped Frame |
| 7 | Demon | Aberration | Void-Touched Researcher, Paper Cut, The Redacted, Fractured Verdict |
| 8 | Goblin/Elemental | — | The Pressure, The Bioluminescent Lie |
| 9 | Undead/Construct | — | The Skin That Remembers, The Teeth Beneath, The Long Arm, The Second Shadow, The One Who Remembers |
| 10 | Dragon / All factions | — | The Everything That Is Not You, The Cano Protocol (secret) |

---

## How Files Are Organized

```
enemies/
├── ENEMY_INDEX.md              ← You are here
├── ENEMIES_BY_FACTION.md       ← Master comparison
├── ENEMY_SYSTEM.md             ← Spawn/patrol AI
├── ENEMY_AUDIT_COMPLETE.md     ← Implementation status
├── Construct/
│   ├── CONSTRUCT_ENEMIES.md    ← Full roster (30 + 5 bosses)
│   ├── Loose_Gear.json         ← Individual enemy data
│   ├── Tight_Gear.json
│   └── ... (31 files total)
├── Goblin/
│   ├── GOBLIN_ENEMIES_WORKING.md
│   └── ... (36 files)
├── Elemental/
│   ├── ELEMENTAL_ENEMIES_WORKING.md
│   └── ... (36 files)
├── Undead/
│   ├── UNDEAD_ENEMIES_WORKING.md
│   └── ... (36 files)
├── Demon/
│   ├── DEMON_ENEMIES_WORKING.md
│   └── ... (36 files)
└── Aberration/
    ├── ABERRATION_ENEMIES_COMPLETE.md  ← Full 30 + 5 roster
    ├── VOID_ABERRATIONS.md             ← Floors 7-10 deep tier
    ├── ABERRATION_BOSSES.md            ← Boss design doc
    └── ... (42 files)
```

---

*All enemy rosters complete. All tiers filled. All factions balanced.*
*No more hunting. Everything is where it goes.*
