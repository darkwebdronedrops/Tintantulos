# 🏰 Tintantulos

A card battler roguelike built in Godot 4. Navigate the tower floor by floor, collect cards, build your deck, and survive.

**[Play the latest build](https://github.com/darkwebdronedrops/Tintantulos/releases)** • **[Report issues](https://github.com/darkwebdronedrops/Tintantulos/issues)**

---

## 🎮 About

Tintantulos is a deck-building card battler with:
- **10+ floors** of escalating challenge
- **7 factions** with distinct mechanics (Aberration, Construct, Demon, Dragon, Elemental, Goblin, Undead)
- **3 overlay types** (Arcane, Divine, Infernal) that modify card behavior
- **Deep deck customization** with cross-faction synergy
- **Boss encounters** on key floors

## 📁 Project Structure

| Folder | Contents |
|--------|----------|
| `assets/` | Sprites, audio, card art |
| `scenes/` | Floor scenes, room scenes, UI |
| `scripts/` | GDScript game logic, card compositor |
| `finished_cards/` | Completed card data resources |
| `enemies/` | Enemy data and boss configs |
| `docs/` | Design documents and specifications |

## 🛠️ Development

Built with **Godot 4.x**. Open `project.godot` in the Godot Editor to run.

### Key Scripts
- `scripts/CombatUI.gd` — Combat interface and card rendering
- `scripts/CombatManager.gd` — Turn logic and state machine
- `scripts/CardData.gd` — Card resource definitions
- `scripts/card_compositor.py` — Python pipeline for generating card frame overlays

## 📝 License

© Acanous. All rights reserved.

---

*"The tower has no top. Only deeper."*
