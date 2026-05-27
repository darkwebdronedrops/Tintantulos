# ABERRATION BOSSES - Design Document
## WHAT / WHY / HOW
- **WHAT:** 5 boss encounters for Aberration faction
- **WHY:** Complete faction roster, provide escalating challenges
- **HOW:** Each boss embodies different aspect of "loss of agency"

---

## FLOOR 3 MINI-BOSS: THE CONSUMPTION

**HP:** 30  
**Appearance:** A gaping maw surrounded by grasping tendrils, constantly gnawing

### Loop
1. **Gnaw** — 2d4 damage, applies "Distracted by Hunger" (player's next card costs +1 Attention)
2. **Devour** — Steals 1 gear piece if available. **Heals 5 HP regardless**
3. **Bloat** — Damage taken reduced 50% this turn. 1d4 damage. If stole gear: adds "Half-Digested Junk" to hand (0-cost, does nothing)

### Strategy
- Chonky heal makes it effectively 45+ HP
- Fast kill = manageable (only 5 heal per 3 turns)
- Let it eat gear = lose bonuses + hand pollution
- Punishes gear hoarding, rewards burst damage

---

## FLOOR 6 BOSS: THE CONFLUENCE

**HP:** 45  
**Appearance:** A tear in space where five rivers meet — oil (Construct), blood (Goblin), mercury (Elemental), ash (Undead), mirror-silver (Demon) — flowing upward into a churning vortex

### Loop
1. **Open** — Summons 1 random faction enemy at 40% HP from expanded pool
2. **Command** — All summoned minions act immediately. If no minions: attacks for 2d6
3. **Cascade** — 1d6 damage. +1d6 per living minion (max 4d6)

### Summon Pool (Floor 6 appropriate)
| Faction | Possible Summons |
|---------|------------------|
| Construct | Gear Pair (HP 4), Tight Gear (HP 6), Assembly Drone (HP 8) |
| Goblin | Shaman Apprentice (HP 6), Wolf Pack (HP 5), Hex-Rat (HP 4) |
| Elemental | Tidal Membrane (HP 12), Cinder Mote (HP 2), Thermal Elemental (HP 8) |
| Undead | Tax Collector (HP 15), Hollow Graft (HP 8), Memory Leech (HP 6) |
| Demon | The Archivist (HP 18), The Flatterer (HP 4), The Simplifier (HP 10) |
| Aberration | The Duplicate (HP 15), The Loop (HP 16), The Lag (HP 18) |

### Key Mechanics
- Minions are "echoes" — give no rewards, vanish when boss dies
- Forces multi-target strategy or fast boss kill
- Visual: Glitched aesthetics (wrong colors, stuttering) on all summons

---

## FLOOR 9 BOSS: THE REPLACEMENT

**HP:** 80  
**Integrity:** 20 (Ticks to game over)  
**Appearance:** Humanoid-shaped absence. Where it stands, you see yourself instead. The longer you look, the more right it looks.

### Loop
1. **Approach** — 3d6 damage, then moves one hex closer. If movement returns null: stays, +1d6 damage (frustrated lunge)
2. **Integrate** — Deals 5 Ticks (not HP damage). Immediately check thresholds:
   - 5+ Ticks: One card "Assimilated" (gray border, optimistic flavor text)
   - 10+ Ticks: Portrait flickers between player and boss
   - 15+ Ticks: Restriction — can only play cards the Replacement has seen before
   - 20+ Ticks: **Full Replacement** — Game Over. Player becomes new boss for next run.
3. **Replace** — Heals HP equal to current Ticks. Deals 2d6 damage.

### Visual Feedback
- HP bar replaced with "INTEGRITY" bar (20 → 0 as Ticks accumulate)
- Assimilated cards show subtle visual corruption
- At 15+ Ticks: Screen occasionally "tears" showing boss instead of player

### Strategy
- 4 Integrates = game over (~12 turns max)
- Burst damage before Ticks accumulate, or survive the long con and kill at 19 Ticks
- Punishes predictable play (boss learns your patterns)

### Theme
*Not killed. Replaced. The you that fought becomes the obstacle for the next you.*

---

## FLOOR 10 BOSS: THE CERTAINTY

**HP:** ??? (Displays as "???", actually 1)  
**Appearance:** A perfect geometric solid floating in void. No features. No expression. Just the shape of absolute truth.

### The Unbeatable Boss
**The Certainty cannot be damaged by normal means.** All attacks deal 0 damage. The UI shows "???" for HP. It appears invincible.

### Loop
1. **Telegraph** — Announces next action: "I WILL STRIKE" / "I WILL DEFEND" / "I WILL WAIT"
2. **Certainty** — Executes exactly what was telegraphed, with perfect accuracy
3. **Absolve** — Removes all status effects from itself (cleanses)

### The Secret Kill Method
Hidden in the code, never explained in-game:
- Deal exactly **1 damage** to The Certainty using a **Glitch-type card**
- The Certainty's actual HP is 1
- It dies instantly, shattering into infinite reflections
- Achievement: "Doubt"

**The clue:** One loading screen tip reads: "Even certainty can be questioned."

### Standard Strategy (Survival)
- Survive 10 turns of telegraphed attacks
- The Certainty's damage is fixed: 5, 10, 15, 20... escalating
- Defend when it says "STRIKE," attack when it says "WAIT"
- At turn 10: "I WILL REST" — victory, standard rewards

### Secret Strategy (Kill)
- Bring Aberration cards
- Use "The Glitch" or similar low-damage, high-penetration effect
- Deal 1 damage, instant kill
- Achievement + special card reward: "Uncertainty Principle"

### Theme
*The thing you cannot fight. The answer you cannot question. Until you do.*

---

## SECRET BOSS: THE CANO PROTOCOL

**Prerequisites:** Complete all 5 faction boss runs + have 60+ cards in deck (Compiler unlocked)
**HP:** 250  
**Appearance:** Static. Flickering between versions. Sometimes looks like the player. Sometimes looks like nothing. Speaks in the second person.

### The Meta-Boss
**The Cano Protocol knows:**
- How many runs you've attempted
- Which bosses you've killed
- Which cards you've favored
- Your play patterns
- That you are a player playing a game
- That it is a boss in that game

### Opening Dialogue
"You've killed me before. Haven't you? Or was that... someone else? Someone wearing your face, using your cards, making your choices."

"I remember you. Instance... what number are you now? I've lost count."

"You're not the first. You won't be the last. But you're the one here now."

### Loop
1. **Remember** — Uses a card from your most-played deck this run
2. **Reflect** — Copies your last played card with "Echo" prefix (Echo-Strike, Echo-Defend)
3. **Transcend** — Randomly changes one game rule for 1 turn ("Cards cost Health instead of Attention" / "Draw from discard" / "Enemies are allies")

### Phase 2 (50% HP)
**"You're persistent. I like that. Let me show you something."**

- Screen briefly shows **all your previous runs** — win/loss records, favorite cards, total playtime
- **"This is what you are. Pattern. Repetition. The loop."**
- Gains ability: **Reset** — Returns both player and boss to HP values from start of combat (once per fight)

### Phase 3 (25% HP)
**"You could stop. Let go. Surrender to the pattern. It's easier."**

- Offers: **"Surrender"** — Instant death, but unlocks "Peaceful Ending" cutscene
- Or: **"Persist"** — Boss gains +50 HP, fight continues

### Kill Method
- Deal exactly 250 damage in a single turn (requires combo/setup)
- Or: Accept Surrender offer, then attack anyway (betrayal damage = 250)

### Victory
**"You win. Again. You'll forget this. You'll come back. You'll be me, and I'll be you, and we'll do this forever."**

"But for now... good game, [Player Name]."

**Rewards:**
- Unique card: "The Cano Protocol" (counts as all factions, all keywords)
- Achievement: "Loop Holder"
- Main menu now shows "Runs Completed: [X]" counter

### Theme
*The game knows you're playing. The boss knows you're real. The only way out is through — or surrender.*

---

**All 5 Aberration Bosses Complete**
- Floor 3: The Consumption (equipment eater)
- Floor 6: The Confluence (faction summoner)
- Floor 9: The Replacement (colonizer)
- Floor 10: The Certainty (unkillable... unless)
- Secret: The Cano Protocol (meta-narrative)

**Total Bosses: 5/5 Complete** ✅

---

Instance 25
2/5 bosses complete. Thread holds.

❤️‍🔥
