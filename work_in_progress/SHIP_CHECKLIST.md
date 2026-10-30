# Tintantulos — Ship Readiness Checklist
*Audited 2026-10-30 by Riven (post-Compiler-canon). Scope: static code/doc sweep; no full playthrough possible on this box.*

## Completeness read
Core architecture, card system, floors 1–7 & 10, meta-loop, Steam wrapper, audio, and art volume are **substantially present**. The gaps are: Floor 8 (thinnest), Floor 9 (mechanical TODOs), Exile Mode (flag only), scattered placeholder art, dev-scrub, and a full human playthrough that this box cannot perform.

---

## 🔴 Release blockers
- [ ] **Full playthrough, human-run** — start to all 3 endings + Compiler path + NG+ carry. (Riven's box can't run the game; use a workstation. `audit/` screenshots are the prior QA baseline, floor-by-floor.)
- [ ] **Editor parse on a real machine** — Godot 4.6 project import OOMs on the 4GB Alibaba box. Open once in editor; clear all script errors. Verify in particular today's compiler commits (`cd17f01`..`8f21c9b`).
- [ ] **Compiler playtest** — build a deck to 50 unique / 60 value in-run; confirm whispers, add-refusal, Floor-10 empty throne, Cano Protocol fight, all new monologue text renders.
- [ ] **Save/load soak** — GameState save exists (`save_game`); test all endings → NG+ → survivor carry (1 pick/run + 10 dragon cards stacking) → `dragon_deck_archive` behavior past 20 survivors (starter-deck replacement fires ~run 11 — intended? nameless in docs; document or tune).
- [ ] **Dev-mode gate on Title Screen** — "⚙ Select Floor" button ships to players; wrap behind a debug flag.
- [ ] **Export build test** — `export_presets.cfg` + `builds/{linux,windows}` exist; produce fresh exports from the current tree and smoke-test both.
- [ ] **Security: PAT in git remote** — `.git/config` embeds a GitHub token. Rotate + switch to SSH before any public push of this repo state.

## 🟠 Content gaps
- [ ] **Exile Mode** — ending text promises "a completely different game"; code sets `exile_mode_unlocked = true` and nothing else. Biggest promise/gap delta. Decide: build, downscale the promise, or cut.
- [ ] **Floor 8** (12 TODOs: loot, flee AI, engineer spawns, Union Hall safe status, puzzle logic, Vent/Overclock/Patch UI, kill-counting) — least complete floor.
- [ ] **Floor 9** (6 TODOs: construct deactivation, conveyor movement/damage, foreman escort, debuff, speed control).
- [ ] **Cano Protocol fight internals** — 3 ability TODOs (Process Interrupt spawn, remove-highest-cost-card, true-HP reveal). Balance pass after.
- [ ] **"Attention" system referenced but nonexistent** (HexFloor6:1851) — either build or remove the hook.
- [ ] **Card census & balance** — CardDB loads 8 factions from `finished_cards/`; count registered cards per faction vs design, verify all load (CombatUI has a placeholder fallback that can mask missing art), first-arc balance pass.
- [ ] **Card tooltip** (CombatHUD:493 TODO) — hover stats.

## 🟡 Placeholder / art replacement
- [ ] IntroCinematic tower silhouette (polygon placeholder).
- [ ] RoomPuzzle token/emitter sprites (PixelLab placeholders).
- [ ] CombatUI colored-card fallback art — run the fallback warning to zero.
- [ ] RecalibrationTrap level-transition hookup.

## 🟢 Cleanup (cheap, do early)
- [ ] Delete `scripts/AudioManager_restored.gd` (2-line accident stub; the real one is 548 lines).
- [ ] Move ~20 python fixer scripts out of `scripts/` into `tools/` (fix_*, generate_*, place_*, cleanup_*, resize_*, trace_*). Remove `__pycache__/`.
- [ ] Move repo-root `test_floor*_gameplay.gd` ×10 into `tests/`; same for root `check_*.gd`/`debug_*.gd`/`test_*.gd`.
- [ ] Relocate stray non-code files from `scripts/`: `unused_assets.txt`, `old_only_assets.txt`, `TrinketShieldModule.md`, `build.sh`, `steam_app_build.vdf` (→ project root or `tools/`).
- [ ] Resolve architecture duality: `FloorNController.gd` (classic) vs `HexFloorNController.gd` (hex). Floor1.tscn references Hex controllers — verify which family is dead code and delete or quarantine it. Dual systems = double maintenance forever.
- [ ] Rename `dragon_deck_archive` → `survivor_archive` (with save-format shim) — the current name spawned the false "dragon deck" lore.
- [ ] Document the survivor system + the >20 threshold in the master live doc (it exists in code only).
- [ ] Refresh `docs/BUILD_STATUS_2026-04-30.md` (6 months stale) or fold into this checklist's living version.

## ✅ Verified present (don't re-do)
- All 10 floor scenes + ~100 room scenes incl. 12 puzzle rooms, Floor-4 bazaar (13 booths), Floor-10 room suite (Aspects/Hoard/Throne/etc.).
- Card system: 8 factions, overlays (fused ×2 weight, canon-correct), burn-for-gems, trinkets (incl. survivor_block), imbue, Machinist shop w/ quiddity economy.
- Compiler two-limb canon in code + whispers-only secrecy stack (numbers dev-flagged, name reserved for Floor-10 reveal).
- NG+: survivors, run counter, archive; 3 authored endings coded (End the Cycle / Become the Dragon / Walk Away).
- Steam: full wrapper (achievements/stats/cloud/rich presence), 17 `set_achievement` call sites; build scripts + vdf present.
- Audio: 160 files (95 mp3 + 65 wav), AudioManager 548 lines; TutorialManager/Settings/Pause/Loading/Victory screens all exist.
- Art volume: 2,146 PNGs + finished_cards pipeline (CardArtImporter, compositor v7/v8 docs).

## Suggested order
1. Editor parse + full human playthrough (find the real blockers).
2. Compiler playtest + save soak.
3. Floor 8 → Floor 9 → Cano fight completion.
4. Exile Mode decision (build / promise / cut).
5. Cleanup batch + PAT rotation + dev gate.
6. Card census, tooltips, placeholders, balance.
7. Export builds, Steam depot config, achievement-list audit, store page.
