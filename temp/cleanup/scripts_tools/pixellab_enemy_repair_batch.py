#!/usr/bin/env python3
"""
PixelLab Enemy Sprite Repair Batch — Primitive Replacement
Replaces 56 Python-generated primitive placeholder sprites with proper pixel art.

Usage:
    export PIXELLAB_API_KEY="7121a3bf-3da7-44e9-a18e-39582de2362f"
    python3 pixellab_enemy_repair_batch.py

Output: acanous_floor3_demo/assets/sprites/enemies/ (overwrites primitives)
"""

import os
import sys
import json
import time
import base64
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

# --- Config ---
API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
BASE_OUTPUT_DIR = Path("acanous_floor3_demo/assets/sprites/enemies")
REQUEST_DELAY = 3  # Seconds between API calls
MAX_RETRIES = 3

# Ensure output dirs exist
for subdir in ["", "Aberration", "Construct", "Elemental", "Undead"]:
    (BASE_OUTPUT_DIR / subdir).mkdir(parents=True, exist_ok=True)

# --- Sprite Definitions ---

@dataclass
class SpriteDef:
    filename: str
    subdir: str  # "" for root, or faction subdir
    width: int
    height: int
    prompt: str
    view: str = "side"
    detail: str = "highly detailed"
    outline: str = "single color outline"
    shading: str = "medium shading"

# =============================================================================
# BOSS SPRITES (Priority 1 — Most Visible)
# =============================================================================

BOSS_SPRITES = [
    # --- Gear Mother (Construct Boss) ---
    SpriteDef("boss_gear_mother_attack.png", "Construct", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Massive mechanical boss — Gear Mother, a towering brass and iron construct with a single huge cyclopean gear for a head, multiple segmented arms ending in spinning saw blades, steam vents on shoulders erupting white vapor, aggressive lunging pose with one arm raised to strike. Dark bronze and rusted iron palette with glowing amber eye in gear center. Industrial steampunk dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_gear_mother_damage.png", "Construct", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Massive mechanical boss — Gear Mother taking damage, same towering brass construct with cyclopean gear head, body tilted backward from impact, sparks flying from cracked shoulder plate, one arm hanging limp, steam leaking from ruptured vent, pained mechanical posture. Dark bronze and rusted iron palette with flickering amber eye. Industrial steampunk dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_gear_mother_death.png", "Construct", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Massive mechanical boss — Gear Mother defeated, same towering brass construct with cyclopean gear head, collapsed forward onto knees, gear head cracked and dark, arms sprawled, oil pooling beneath body, steam dissipating, broken and inert. Dark bronze and rusted iron palette with dead dark eye socket. Industrial steampunk dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_gear_mother_idle.png", "Construct", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Massive mechanical boss — Gear Mother idle stance, same towering brass construct with cyclopean gear head, arms at sides, steam gently venting from shoulders, gear head slowly rotating, patient menacing stillness. Dark bronze and rusted iron palette with steady glowing amber eye. Industrial steampunk dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- Goblin King Grimgut (Goblin Boss) ---
    SpriteDef("boss_goblin_king_grimgut_attack.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Goblin King boss — Grimgut, a massive obese goblin warlord wearing spiked iron crown and tattered royal cape, wielding a huge serrated cleaver, mouth open in battle roar showing gold-capped tusks, one foot raised stomping forward, gut bouncing with motion. Dark green skin, rusted iron armor, purple cape with gold trim. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_goblin_king_grimgut_damage.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Goblin King boss — Grimgut taking damage, same massive obese goblin warlord with spiked iron crown, body recoiling backward, cleaver deflected, one hand clutching gut wound, green blood spurting, enraged pained snarl. Dark green skin, rusted iron armor, purple cape torn. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_goblin_king_grimgut_death.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Goblin King boss — Grimgut defeated, same massive obese goblin warlord with spiked iron crown, collapsed on back, cleaver fallen beside him, crown askew, eyes crossed and tongue lolling, X-shaped dead eyes, royal cape spread like a blanket. Dark green skin, rusted iron armor. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_goblin_king_grimgut_idle.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Goblin King boss — Grimgut idle, same massive obese goblin warlord with spiked iron crown and royal cape, standing with weight on one leg, picking teeth with pinky claw, bored arrogant expression, gut resting on belt. Dark green skin, rusted iron armor, purple cape with gold trim. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- The Caldera (Infernal Boss) ---
    SpriteDef("boss_the_caldera_attack.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Infernal boss — The Caldera, a walking volcanic crater given humanoid form, body of cracked cooling lava with rivers of molten orange glow between plates, head a volcanic caldera mouth spewing ash and fire, one arm raised throwing a lava bomb, magma dripping from fingertips. Dark obsidian and bright magma orange palette. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_caldera_damage.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Infernal boss — The Caldera taking damage, same volcanic humanoid, body shell cracked showing brighter magma beneath, ash cloud puffing from wounds, staggered stance, one arm clutching chest crater, molten tears dripping. Dark obsidian and bright magma orange palette with extra glow from cracks. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_caldera_death.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Infernal boss — The Caldera defeated, same volcanic humanoid, collapsed into kneeling heap, lava cooling to dark grey rock, last embers dying in chest crater, ash settling, cracks dark and inert, molten light extinguished. Dark cooling obsidian palette, dim grey. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_caldera_idle.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Infernal boss — The Caldera idle, same volcanic humanoid, standing with slow heavy breaths, chest crater gently pulsing with inner fire, lava rivers ebbing and flowing, small puffs of smoke from shoulder vents, patient burning menace. Dark obsidian and bright magma orange palette. Fantasy dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- The Consumption (Aberration Boss) ---
    SpriteDef("boss_the_consumption_attack.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Aberration boss — The Consumption, a horror of fused mouths and teeth, central body like a bloated leech made of mouths, dozens of tooth-ringed orifices on all surfaces, long tentacle-mouths lashing forward to bite, digestive acid dripping from largest maw, writhing hungry mass. Pale sickly pink and dark purple palette with yellow bile accents. Cosmic horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_consumption_damage.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Aberration boss — The Consumption taking damage, same horror of fused mouths, several mouths sealed shut by wounds, black ichor spurting, tentacles flailing in pain, central mass convulsing, some teeth cracked and broken, defensive recoiling posture. Pale sickly pink and dark purple palette with black blood. Cosmic horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_consumption_death.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Aberration boss — The Consumption defeated, same horror of fused mouths, deflated and collapsed, mouths agape and empty, tentacles limp on ground, central mass split open showing hollow interior, no more teeth, still and dead. Pale grey and dark purple palette, drained of color. Cosmic horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_consumption_idle.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Aberration boss — The Consumption idle, same horror of fused mouths, central mass gently pulsing, mouths slowly opening and closing like breathing, tentacles gently swaying tasting the air, digestive juices bubbling in depths, patient waiting hunger. Pale sickly pink and dark purple palette with yellow bile glow. Cosmic horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- The Interview (??? Boss — bureaucratic horror) ---
    SpriteDef("boss_the_interview_attack.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Bureaucratic horror boss — The Interview, a faceless humanoid in a perfectly pressed dark suit, head a blank smooth oval with no features, holding a massive stamp-weapon like a warhammer, paper forms swirling around body like a shield, one hand reaching forward to grab. Dark navy suit, white shirt, red tie, pale featureless head. Corporate horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_interview_damage.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Bureaucratic horror boss — The Interview taking damage, same faceless suited humanoid, suit torn at shoulder showing paper-like flesh beneath, stamp-weapon dropped, blank head tilted in confusion, forms scattering from wound, one hand clutching chest. Dark navy suit torn, white shirt stained, pale head cracked. Corporate horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_interview_death.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Bureaucratic horror boss — The Interview defeated, same faceless suited humanoid, collapsed in desk chair, head lolling to side, suit deflated like empty skin, stamp-weapon fallen, forms settling on body like a shroud, blank head now just smooth paper. Dark navy suit, pale empty head. Corporate horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_interview_idle.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Bureaucratic horror boss — The Interview idle, same faceless suited humanoid, sitting behind a desk made of stacked forms, blank head tilted slightly as if listening, stamp-weapon resting across lap, papers slowly shuffling around body, patient silent waiting. Dark navy suit, white shirt, red tie, pale featureless head. Corporate horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- The Unsent Letter (??? Boss — epistolary ghost) ---
    SpriteDef("boss_the_unsent_letter_attack.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Ghostly boss — The Unsent Letter, a wraith formed of hundreds of floating paper sheets, central figure vaguely humanoid but translucent, eyes glowing with blue ink-light, arm raised throwing a razor-edged envelope like a shuriken, pages whipping around in ghostly wind. Pale blue-white spectral palette with dark ink stains. Spectral horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_unsent_letter_damage.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Ghostly boss — The Unsent Letter taking damage, same wraith of floating papers, several sheets torn and burning at edges, central figure flickering translucent, blue ink-eyes dimming, pages scattering from wound, defensive recoiling posture. Pale blue-white spectral palette with charred paper edges. Spectral horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_unsent_letter_death.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Ghostly boss — The Unsent Letter defeated, same wraith of floating papers, all pages settling to ground in a heap, central figure dissipated into mist, last few sheets fluttering down, ink stains fading, empty and still. Pale grey and white palette, fading to nothing. Spectral horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_unsent_letter_idle.png", "", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Ghostly boss — The Unsent Letter idle, same wraith of floating papers, pages gently orbiting in slow spiral, central figure semi-transparent with faint sad posture, blue ink-eyes softly glowing, one page held close to chest as if clutching a letter. Pale blue-white spectral palette with dark ink accents. Spectral horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
]

# =============================================================================
# UNDEAD ENEMIES (Priority 2 — Full Faction)
# =============================================================================

UNDEAD_SPRITES = [
    # --- Flesh Garden (Undead Boss) ---
    SpriteDef("boss_the_flesh_garden_attack.png", "Undead", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Undead boss — The Flesh Garden, a massive biomechanical monstrosity of fused corpses and plant growth, central trunk made of twisted bodies with limbs as branches, blooming flowers of flesh and teeth, roots made of grasping arms burrowing into ground, attacking with a vine-whip of spines. Dark rotting flesh pink and sickly green palette with blood red flower petals. Horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_flesh_garden_damage.png", "Undead", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Undead boss — The Flesh Garden taking damage, same biomechanical monstrosity, several blooms severed and bleeding sap, trunk split showing marrow, roots thrashing in pain, flesh-leaves wilting, defensive recoiling with pained moan implied. Dark rotting flesh pink and sickly green palette with black sap. Horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_flesh_garden_death.png", "Undead", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Undead boss — The Flesh Garden defeated, same biomechanical monstrosity, collapsed and withered, blooms dried and dead, trunk rotted to bone, roots lifeless on ground, last leaves falling, still and decaying. Grey and brown palette, drained of life. Horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("boss_the_flesh_garden_idle.png", "Undead", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Undead boss — The Flesh Garden idle, same biomechanical monstrosity, gently swaying as if in breeze, blooms slowly opening and closing like breathing, roots subtly shifting in soil, a soft pulsing glow from central heart-organ, patient growing hunger. Dark rotting flesh pink and sickly green palette with soft red pulse. Horror dungeon boss, side view, highly detailed, medium shading, single color outline."),
    
    # --- Flesh Crawler ---
    SpriteDef("enemy_flesh_crawler_attack.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Crawler, a crawling horror of stitched-together limbs, torso made of three fused torsos, six arms as legs scuttling forward, face a mosaic of mismatched eyeballs and mouths, lashing out with a bone-claw arm. Dark rotting flesh pink and brown palette. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_crawler_damage.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Crawler taking damage, same stitched limb horror, one arm severed and bleeding black, torso stitches popped showing organs, multiple eyes closed in pain, recoiling backward from hit, mouth-mosaic screaming. Dark rotting flesh pink and brown palette with black blood. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_crawler_death.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Crawler defeated, same stitched limb horror, collapsed in heap, limbs disassembled and scattered, eyes all X-shaped dead, stitches unraveled, just a pile of parts. Dark grey and brown palette, drained of unlife. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_crawler_idle.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Crawler idle, same stitched limb horror, crouched low with six arms tensed, multiple eyes scanning different directions, mouth-mosaic whispering, stitched body gently heaving with unnatural breath, patient waiting. Dark rotting flesh pink and brown palette. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    # --- Flesh Debt ---
    SpriteDef("enemy_flesh_debt_attack.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Debt, a gaunt skeletal figure wrapped in chains made of preserved sinew, ribcage open showing a beating heart inside made of gold coins, hollow eye sockets glowing with greed-light, one arm extended demanding payment, chain-whip lashing forward. Dark bone white and rusted chain grey with gold heart glow. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_debt_damage.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Debt taking damage, same gaunt skeletal figure wrapped in sinew chains, ribcage cracked, gold-coin heart spilling coins from wound, chains broken and dangling, hollow eye sockets dimming, recoiling from hit clutching chest. Dark bone white and rusted chain grey with dim gold. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_debt_death.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Debt defeated, same gaunt skeletal figure, collapsed and inert, chains rusted through and broken, ribcage empty no heart, hollow eye sockets dark, gold coins scattered around body, just a dead skeleton. Grey bone palette, no glow. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_flesh_debt_idle.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Flesh Debt idle, same gaunt skeletal figure wrapped in sinew chains, standing with one hand out palm up demanding payment, gold-coin heart slowly pulsing in ribcage, hollow eye sockets glowing with calculating greed-light, chains gently clinking. Dark bone white and rusted chain grey with gold heart glow. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    # --- Forgetful Wound ---
    SpriteDef("enemy_forgetful_wound_attack.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Forgetful Wound, a zombie-like figure with a massive gaping wound where its face should be, body covered in scars that keep reopening, hands ending in broken glass shards, lunging forward to grapple and infect. Pale grey-green skin, dark red fresh blood and old brown scabs. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_forgetful_wound_damage.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Forgetful Wound taking damage, same faceless wound zombie, body riddled with new holes, old scars torn open wider, broken glass fingers shattered, pale ichor spurting, recoiling backward with arms raised defensively. Pale grey-green skin with black and red mixed blood. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_forgetful_wound_death.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Forgetful Wound defeated, same faceless wound zombie, collapsed on knees, wounds finally still and closed, glass fingers fallen off, body deflating like empty skin, finally at peace. Pale grey palette, all wounds closed and dry. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_forgetful_wound_idle.png", "Undead", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — Forgetful Wound idle, same faceless wound zombie, standing with head tilted as if listening, wounds slowly pulsing and reopening, blood dripping rhythmically, broken glass fingers flexing open and closed, confused lost posture. Pale grey-green skin with fresh red blood. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
]

# =============================================================================
# ABERRATION ENEMIES (Priority 3)
# =============================================================================

ABERRATION_SPRITES = [
    SpriteDef("enemy_the_default_idle.png", "Aberration", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — The Default, a glitchy corrupted humanoid figure, body flickering between solid and wireframe, patches of skin replaced by static noise, eyes showing loading-spinner pupils, standing in a confused glitch-pose, reality breaking around edges. Digital corruption palette — blues, whites, black static. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_everything_that_is_not_you_attack.png", "Aberration", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Everything That Is Not You, a shifting mass of wrong-shaped limbs and inverse anatomy, joints bending backward, too many elbows, face a smooth mirror reflecting the viewer, lunging forward with grabbers extended. Sickly purple and impossible-black palette. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_long_arm_idle.png", "Aberration", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — The Long Arm, a humanoid whose arms extend to absurd length dragging on ground, fingers elongated into spider-like digits, body small and shrunken compared to limbs, head hanging low, arms gently swaying like tentacles. Pale grey skin with bruise-purple joint swelling. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_teeth_beneath_idle.png", "Aberration", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — The Teeth Beneath, a squatting figure with a mouth that opens across its entire torso from throat to groin, rows of teeth lining the chest cavity, belly distended and writhing, small beady eyes above the maw, crouched ready to bite. Pale pink flesh with white and yellow teeth, red gum tissue. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
]

# =============================================================================
# CONSTRUCT ENEMIES (Priority 4)
# =============================================================================

CONSTRUCT_SPRITES = [
    SpriteDef("enemy_drive_train_idle.png", "Construct", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Construct enemy — Drive Train, a mechanical serpent made of interlocking gears and drive shafts, body segmented like a centipede with rolling treads, head a gear with drill-bit nose, steam puffing from vent holes along back, coiled and ready. Dark iron and brass with steam white wisps. Steampunk dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_engine_block_idle.png", "Construct", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Construct enemy — Engine Block, a bulky rectangular mechanical golem made of a heavy engine block with piston legs, exhaust pipes as arms belching smoke, oil dripping from joints, radiator grille as chest plate, heavy and immovable stance. Dark cast iron and grease black with exhaust grey. Steampunk dungeon enemy, side view, highly detailed, medium shading, single color outline."),
]

# =============================================================================
# ELEMENTAL ENEMIES (Priority 4)
# =============================================================================

ELEMENTAL_SPRITES = [
    SpriteDef("enemy_cinder_mote_idle.png", "Elemental", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Elemental enemy — Cinder Mote, a tiny fire spirit, small humanoid shape made of glowing embers and ash, flickering orange and red flames for hair, coal-black body with cracks showing inner fire, gentle floating stance, small and cute but dangerous. Warm orange-red palette with ash grey. Fantasy dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_droplet_attack.png", "Elemental", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Elemental enemy — Droplet, a water spirit shaped like a teardrop with limbs, translucent blue body showing inner currents, droplet-shaped head with wave-crest hair, one arm raised forming a water spear, splash droplets around base. Cool blue and white foam palette. Fantasy dungeon enemy, side view, highly detailed, medium shading, single color outline."),
]

# =============================================================================
# MISC ENEMIES (Priority 4)
# =============================================================================

MISC_SPRITES = [
    SpriteDef("enemy_afterimage_idle.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Afterimage, a translucent ghostly figure made of afterimages and motion blur, multiple overlapping semi-transparent copies of itself trailing behind, face blurry and indistinct, flickering between solid and transparent, lost confused posture. Pale blue-white translucent palette with purple afterimage trails. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_mirror_self_idle.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Mirror Self, a perfect mirror-image duplicate of the player character but with inverted colors, body made of polished silver and mercury, holding a weapon mirrored, sinister knowing smile, standing in mockery pose. Silver and mercury mirror palette with inverted color scheme. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_duplicate_mimic.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Duplicate Mimic, a shapeless blob in the process of copying another creature, half-formed face melting off one side, one arm humanoid and one arm still amorphous, confused intermediate state. Sickly grey-purple palette with shifting highlights. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_echo_death.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Echo, a sound-wave made solid, body like a ripple frozen in time, face screaming with sound-lines radiating, mid-dissipation as if the sound is fading, semi-transparent and flickering. Blue-white ripple palette fading to grey. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_forgotten_damage.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Undead enemy — The Forgotten, a decaying figure with no face just smooth skin where features should be, body wrapped in cobwebs and dust, taking damage with dust cloud puffing from wound, featureless head tilted in confusion, crumbling. Grey and dust brown palette with cobweb white. Horror dungeon enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_hollow_death.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — The Hollow, a humanoid shell completely empty inside, skin like stretched parchment over nothing, collapsed and deflated, eyes and mouth just dark holes, empty husk on ground. Pale parchment white and dark hollow black. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
    
    SpriteDef("enemy_the_refrain_repeat.png", "", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Aberration enemy — Refrain Repeat, a looping figure caught in a repeating animation cycle, body showing motion-blur trails in a circle, same action frozen at multiple points, face twisted in endless repetition, broken record glitch. Purple and blue stutter-trails on pale body. Cosmic horror enemy, side view, highly detailed, medium shading, single color outline."),
]

ALL_SPRITES = BOSS_SPRITES + UNDEAD_SPRITES + ABERRATION_SPRITES + CONSTRUCT_SPRITES + ELEMENTAL_SPRITES + MISC_SPRITES

# --- API ---

def generate_sprite(sprite: SpriteDef, api_key: str) -> bool:
    """Generate a single sprite via PixelLab API. Returns True on success."""
    output_dir = BASE_OUTPUT_DIR / sprite.subdir
    output_path = output_dir / sprite.filename
    
    # Skip if already real art (>>5KB) - don't regenerate good files
    if output_path.exists() and output_path.stat().st_size > 5120:
        print(f"  [SKIP] {sprite.subdir}/{sprite.filename} already real art ({output_path.stat().st_size} bytes)")
        return True
    
    # Backup existing primitive if present
    if output_path.exists():
        backup_path = output_path.with_suffix(".png.primitive_backup")
        try:
            output_path.rename(backup_path)
            print(f"  [BKUP] Backed up existing {sprite.filename}")
        except Exception as e:
            print(f"  [WARN] Could not backup {sprite.filename}: {e}")
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "description": sprite.prompt,
        "image_size": {"width": sprite.width, "height": sprite.height},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "view": sprite.view,
        "detail": sprite.detail,
        "outline": sprite.outline,
        "shading": sprite.shading,
    }
    
    for attempt in range(MAX_RETRIES):
        try:
            print(f"  [GEN] {sprite.subdir}/{sprite.filename} ({sprite.width}x{sprite.height}) — attempt {attempt + 1}/{MAX_RETRIES}")
            resp = requests.post(API_URL, headers=headers, json=payload, timeout=120)
            
            if resp.status_code == 200:
                data = resp.json()
                if "image" in data and "base64" in data["image"]:
                    b64_str = data["image"]["base64"]
                    if b64_str.startswith("data:image"):
                        b64_str = b64_str.split(",", 1)[1]
                    img_data = base64.b64decode(b64_str)
                    with open(output_path, "wb") as f:
                        f.write(img_data)
                    usage = data.get("usage", {})
                    print(f"  [OK]  {sprite.subdir}/{sprite.filename} saved ({len(img_data)} bytes)")
                    return True
                else:
                    print(f"  [ERR] No image in response: {list(data.keys())}")
                    
            elif resp.status_code == 429:
                print(f"  [RATE] Rate limited, waiting 30s...")
                time.sleep(30)
                continue
                
            elif resp.status_code == 401:
                print(f"  [ERR] API key invalid or expired")
                return False
                
            else:
                print(f"  [ERR] HTTP {resp.status_code}: {resp.text[:200]}")
                
        except requests.exceptions.Timeout:
            print(f"  [ERR] Timeout on attempt {attempt + 1}")
        except Exception as e:
            print(f"  [ERR] {type(e).__name__}: {e}")
        
        if attempt < MAX_RETRIES - 1:
            time.sleep(5 * (attempt + 1))
    
    print(f"  [FAIL] {sprite.subdir}/{sprite.filename} — all retries exhausted")
    # Restore backup if generation failed
    if backup_path.exists():
        try:
            backup_path.rename(output_path)
            print(f"  [RESTORE] Restored backup for {sprite.filename}")
        except:
            pass
    return False


def main():
    print("=" * 70)
    print("PixelLab Enemy Sprite Repair Batch — Primitive Replacement")
    print("=" * 70)
    print(f"API Key: {API_KEY[:8]}...{API_KEY[-4:]}")
    print(f"Output:  {BASE_OUTPUT_DIR}")
    print(f"Sprites: {len(ALL_SPRITES)} total")
    print(f"  - Bosses:       {len(BOSS_SPRITES)}")
    print(f"  - Undead:       {len(UNDEAD_SPRITES)}")
    print(f"  - Aberration:   {len(ABERRATION_SPRITES)}")
    print(f"  - Construct:    {len(CONSTRUCT_SPRITES)}")
    print(f"  - Elemental:    {len(ELEMENTAL_SPRITES)}")
    print(f"  - Misc:         {len(MISC_SPRITES)}")
    print("=" * 70)
    
    if not API_KEY or API_KEY == "your-api-key-here":
        print("\n[ERROR] No API key found!")
        sys.exit(1)
    
    # Track results
    success_count = 0
    fail_count = 0
    
    # Generate all sprites
    print("\n--- Batch 1: Boss Sprites (Priority 1) ---")
    for sprite in BOSS_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 2: Undead Sprites (Priority 2) ---")
    for sprite in UNDEAD_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 3: Aberration Sprites (Priority 3) ---")
    for sprite in ABERRATION_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 4: Construct Sprites (Priority 4) ---")
    for sprite in CONSTRUCT_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 5: Elemental Sprites (Priority 4) ---")
    for sprite in ELEMENTAL_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 6: Misc Sprites (Priority 4) ---")
    for sprite in MISC_SPRITES:
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    # Summary
    print("\n" + "=" * 70)
    print("REPAIR COMPLETE")
    print("=" * 70)
    print(f"Success:  {success_count}")
    print(f"Failed:   {fail_count}")
    print(f"Total:    {success_count + fail_count}/{len(ALL_SPRITES)}")
    
    if fail_count > 0:
        print(f"\n[NOTE] {fail_count} sprites failed. Re-run to retry.")
        print("[INFO] Failed sprites keep their .primitive_backup files.")
    
    print(f"\nOutput directory: {BASE_OUTPUT_DIR.absolute()}")
    print("=" * 70)


if __name__ == "__main__":
    main()
