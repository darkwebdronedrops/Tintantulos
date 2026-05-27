#!/usr/bin/env python3
"""
PixelLab Floor Sprite Repair Batch — Auto-Scan & Replace
Scans all floor directories for primitive sprites (<2KB), categorizes them,
and regenerates them via PixelLab API with auto-generated descriptions.

Priority: Boss > Enemy > Object
Kira handles tile maps (tile_* files excluded)

Usage:
    export PIXELLAB_API_KEY="7121a3bf-3da7-44e9-a18e-39582de2362f"
    python3 pixellab_floor_repair_batch.py
"""

import os
import sys
import time
import base64
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

# --- Config ---
API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
BASE_SPRITES_DIR = Path("acanous_floor3_demo/assets/sprites")
REQUEST_DELAY = 3
MAX_RETRIES = 3
SIZE_THRESHOLD = 2048  # Files < 2KB are considered primitives

# --- Entity Descriptions (rich lookup) ---
# Format: name_snake_case -> "Description text for pixel art prompt"
ENTITY_DESCRIPTIONS = {
    # Bosses
    "the_dean": "The Dean — a scholarly administrator boss, tall thin figure in academic robes made of clockwork gears and parchment, face a blank clock-face with ticking hands, quill-pen staff, glasses on a chain, bureaucratic menace",
    "the_denied": "The Denied — a rejected contract given form, humanoid made of torn parchment and red ink, body covered in stamped REJECTED seals, void cracks leaking black emptiness, legal horror",
    "chief_engineer_blix": "Chief Engineer Blix — a goblin engineer boss fused with machinery, half-goblin half-steam-plant, multiple mechanical arms holding wrenches, pressure gauges embedded in chest, wild genius energy",
    "foreman_eternal": "Foreman Eternal — an undead factory supervisor boss, skeletal figure in tattered foreman vest and hard hat, clipboard made of bone, whistle around neck, commanding presence",
    "the_dragon": "The Dragon — an ancient world-building dragon boss, massive serpentine form with crystalline scales, four wings of starlight, eyes like dying suns, hoard of memories beneath claws, apocalyptic scale",
    
    # Floor 5 Enemies
    "debt_eternal": "Debt Eternal — a floating ledger-spirit enemy, body made of chained account books, ink-black tears streaming, hands clutching unpaid bills, ethereal financial horror",
    "elemental_core": "Elemental Core — a crystalline energy elemental enemy, floating geometric shape with raw elemental power glowing inside, facets refracting light, pure magical construct",
    "goblin_grunt": "Goblin Grunt — a basic goblin soldier enemy, small green humanoid in scrap-metal armor, holding a crude spear, snarling expression, cannon fodder",
    "jetstream_shepherd": "Jetstream Shepherd — an air elemental enemy, humanoid made of wind and cloud, hair streaming like a contrail, staff made of solidified gust, sky-blue palette",
    "pressure_knot": "Pressure Knot — a steam elemental enemy, roiling ball of compressed vapor with angry face, pipes bursting from body, pressure gauge on chest showing critical",
    "resonance": "Resonance — a sound elemental enemy, body like a tuning fork given humanoid shape, vibrating visibly, sound-waves radiating from head, sonic attack pose",
    "sneak_thief": "Sneak Thief — a goblin rogue enemy, small green figure in dark cloak, daggers drawn, crouched sneaking posture, mischievous grin, thief tools on belt",
    
    # Floor 6 Enemies
    "brass_enforcer": "Brass Enforcer — a heavy construct enemy, bulky humanoid made of brass armor plates, glowing red eye slit, steam-powered hammer arms, industrial sentinel",
    "calibration_drone": "Calibration Drone — a small flying construct enemy, spherical body with optical sensors, delicate instrument arms, hovering on tiny rotors, diagnostic scanner",
    "logic_core": "Logic Core — a crystalline AI enemy, floating diamond-shaped brain with circuitry visible inside, energy arcs between points, calculating cold intelligence",
    "marrow_priest": "Marrow Priest — an undead cleric enemy, skeletal figure in bone-adorned robes, holding a staff made of fused vertebrae, empty eye sockets glowing with unholy light",
    "the_forgotten": "The Forgotten — a memory-eaten undead enemy, body fading at edges, face almost erased smooth, cobwebs and dust, confused lost posture, existential horror",
    "the_one_who_remembers": "The One Who Remembers — a knowledge-keeper aberration enemy, humanoid with too many eyes, each showing different memories, head oversized with brain visible, remembering everything",
    
    # Floor 7 Enemies
    "blood_notary": "Blood Notary — a demonic bureaucrat enemy, impish figure in ink-stained formalwear, stamping contracts with bloody seal, red ink dripping from fingers, official menace",
    "contract_lawyer": "Contract Lawyer — a sharp-suited demon enemy, slender figure with contract-paper skin showing clauses written in blood, briefcase made of bone, predatory smile",
    "debt_collector": "Debt Collector — a muscular demon enforcer enemy, hulking figure with abacus chest and coin-shaped scales, collection bag of souls, intimidating brute force",
    "paper_cut": "Paper Cut — a swarm-paper enemy, humanoid made of a thousand razor-edged sheets, edges gleaming sharp, origami-folding movements, paper-cut terror",
    "soul_clerk": "Soul Clerk — a skeletal administrator enemy, bony figure in dusty clerk vest, filing cabinet back, sorting soul fragments into drawers, bureaucratic undead",
    "the_redacted": "The Redacted — a censored information entity enemy, humanoid form with black-bar redaction across face and body, classified stamp on chest, information horror",
    "void_researcher": "Void Researcher — a mad scientist aberration enemy, robed figure with void-black skin, multiple arms holding beakers of nothingness, cracked goggles, obsessed genius",
    
    # Floor 8 Enemies
    "alarm_ringer": "Alarm Ringer — a goblin sentry enemy, small green figure with massive brass alarm bell for a head, ringing frantically, red alert light flashing from chest",
    "containment_goblin": "Containment Goblin — a hazmat goblin enemy, green figure in bulky protective suit with glass dome helmet, radiation warnings, carrying containment crate",
    "glass_wraith": "Glass Wraith — a shattered spirit enemy, translucent humanoid with cracks across body like broken window, sharp glass shard hands, refracting light, fragile deadly",
    "ion_howler": "Ion Howler — an energy-scream enemy, beast made of plasma and lightning, mouth open in silent radioactive scream, fur of static electricity, wild unstable",
    "overclock_shaman": "Overclock Shaman — a goblin shaman enemy, green figure with steam-pipe headdress and glowing runes, overcharged with elemental power, manic energy",
    "steam_mote": "Steam Mote — a tiny steam elemental enemy, small puff of sentient vapor with cute face, boiling hot, wisps forming arms, miniature elemental",
    
    # Floor 9 Enemies
    "assembly_skeleton": "Assembly Skeleton — a factory-line undead enemy, skeletal figure with conveyor-belt joints, numbered stamp on forehead, mechanical repetitive movements",
    "femur_golem": "Femur Golem — a bone-construct enemy, hulking figure made of fused femurs and thigh bones, massive club arms, marrow leaking from seams, crude powerful",
    "foreman_specter": "Foreman Specter — a ghostly supervisor enemy, translucent figure in tattered foreman coat, hard hat glowing with ethereal light, pointing accusing finger",
    "ribcage_loader": "Ribcage Loader — a skeletal laborer enemy, figure with exposed ribcage carrying bone-crates, spine bent from weight, hollow worker drone",
    "skull_machinist": "Skull Machinist — a skeletal engineer enemy, skull head with gear-clockwork brain exposed, caliper hands, measuring everything, precise undead",
    "soul_burner": "Soul Burner — a furnace-tender undead enemy, figure with chest cavity open like a furnace, souls burning as fuel, ash-black skin, fire-light from within",
    "soul_piston": "Soul Piston — a mechanical undead enemy, half-skeleton half-piston, repetitive pounding movements, steam from bone joints, industrial horror",
    "the_pensioned": "The Pensioned — a retired undead enemy, elderly skeletal figure in comfortable robe, sitting in bone-chair, finally at rest, peaceful but dead",
    
    # Floor 10 Enemies
    "aspect_greed": "Aspect of Greed — a dragon's sin fragment enemy, serpentine form made of gold coins and gemstones, hoarding everything, glittering avarice, golden scales",
    "aspect_time": "Aspect of Time — a dragon's sin fragment enemy, serpentine form made of clockwork and hourglass sand, chronos wings, ticking scales, temporal distortion",
    "aspect_transformation": "Aspect of Transformation — a dragon's sin fragment enemy, serpentine form constantly shifting between materials, molten to crystal to void, unstable change",
    
    # Objects (key items, NPCs, environment)
    "door_escape": "massive stone door with runic lock, dungeon exit portal, heavy granite with ancient symbols, final escape",
    "ghost_boss": "spectral dragon fragment, ghostly wisp of apocalyptic power, faint and fading, memory of the dragon's presence",
    "hidden_crack": "barely visible crack in stone wall, secret passage hint, subtle shadow line, dungeon secret",
    "hoard_aether_key": "Aether Key — ethereal key made of solidified mist and light, shimmering translucent, unlocking celestial locks",
    "hoard_blood_contract": "Blood Contract — rolled parchment sealed with crimson wax and blood-drop seal, demonic legal document",
    "hoard_dial_fragment": "Dial Fragment — broken piece of an ancient measuring device, brass and crystal, partial numerals visible",
    "hoard_elevator_gear": "Elevator Gear — massive toothed gear for lifting mechanisms, dark iron, industrial machinery part",
    "hoard_graduate_scroll": "Graduate Scroll — academic diploma made of enchanted parchment, gold seal, university certification",
    "hoard_lifter_part": "Lifter Part — hydraulic piston component for cargo lifts, brass cylinder, industrial spare part",
    "hoard_master_key": "Master Key — ornate skeleton key of masterwork quality, gold and silver intertwined, universal lock opener",
    "hoard_pact_scroll": "Pact Scroll — rolled demonic contract document, black ribbon, infernal script visible at edges",
    "hoard_reforged_blade": "Reforged Blade — sword made from melted enemy weapons, dark metal with glowing heat-lines, renewed purpose",
    "hoard_soul_gem": "Soul Gem — crystalline container holding a trapped soul, pulsing with inner light, precious and terrible",
    "item_wisdom": "Wisdom Item — glowing book or scroll radiating knowledge, golden light, enlightenment artifact",
    "stone_pillar": "ancient stone pillar with carved runes, dungeon architecture, weathered granite, structural support",
    "trap_tripwire": "nearly invisible thin wire trap, dungeon hazard, taut line at ankle height, danger warning",
    "banner_construct": "faction banner of the Construct alliance, gear and cog symbol on dark cloth, steampunk heraldry",
    "banner_elemental": "faction banner of the Elemental alliance, fire-water-earth-air symbols on colored cloth, primal heraldry",
    "banner_undead": "faction banner of the Undead alliance, skull and bone symbol on grey cloth, death heraldry",
    "banner_aberration": "faction banner of the Aberration alliance, impossible geometry symbol on purple cloth, cosmic horror heraldry",
    "banner_demon": "faction banner of the Demon alliance, horned skull symbol on red cloth, infernal heraldry",
    "banner_goblin": "faction banner of the Goblin alliance, crude goblin face symbol on green cloth, tribal heraldry",
    "elevator_brass": "brass elevator platform with ornate railings, mechanical lift, steampunk vertical transport",
    "elevator_gear": "gear-driven elevator mechanism, interlocking cogs lifting platform, industrial transport",
    "elevator_valve": "steam-valve elevator control, brass wheel and pressure gauge, steampunk lift control",
    "mushroom_giant": "massive bioluminescent mushroom, towering fungal growth, glowing spore cap, cavern flora",
    "mushroom_small": "small glowing mushroom cluster, tiny fungal sprout, soft bioluminescence, cave decoration",
    "portal_cavern": "cavern portal gate, stone archway with magical shimmer, dungeon transition point, mystical glow",
    "stalactite": "hanging stone icicle formation, cave roof dripstone, pointed mineral deposit, natural hazard",
    "hex_gearworks_floor": "hexagonal gear-pattern floor tile, mechanical dungeon ground, brass inlay on dark stone",
    "hex_ring_corridor": "hexagonal corridor floor with ring pattern, dungeon pathway, geometric stone paving",
    "light_widget": "small mechanical light fixture, brass lamp with warm glow, dungeon illumination device",
    "machinist_npc": "NPC machinist character, friendly goblin mechanic with wrench and oil stains, helpful engineer",
    "trap_cog": "spinning cog trap, mechanical hazard with sharp gear teeth, industrial dungeon danger",
    "trap_compression": "hydraulic compression trap, ceiling piston crusher, steam-powered smashing hazard",
    "wall_gearworks": "gearworks wall panel, mechanical dungeon architecture, interlocking cogs as decoration",
    "balcony_railing": "balcony railing with ornate metalwork, overlooking drop, decorative safety barrier",
    "booth_curio": "curiosity shop booth, merchant stall with strange artifacts, display case with oddities",
    "booth_trap": "trap merchant booth, vendor stall selling dangerous devices, display of mechanical hazards",
    "dumbwaiter": "dumbwaiter lift, small service elevator, food delivery platform, vertical transport",
    "food_station_bread": "bread food station, bakery display, fresh loaves on counter, sustenance point",
    "food_station_meat": "meat food station, butcher display, cooked cuts on counter, sustenance point",
    "food_station_stew": "stew food station, cauldron of bubbling broth, ladle and bowls, sustenance point",
    "gear_part": "loose gear component, spare mechanical part, brass cog wheel, crafting material",
    "grate": "metal floor grate, drainage grid, gaps showing darkness below, dungeon flooring",
    "ladder": "wooden ladder leaning against wall, vertical climbing tool, dungeon navigation",
    "pipe_h": "horizontal steam pipe, brass tubing running wall-to-wall, industrial plumbing",
    "pipe_v": "vertical steam pipe, brass tubing floor-to-ceiling, industrial plumbing",
    "refectory_hex": "refectory dining floor tile, eating hall ground pattern, institutional stone",
    "stairs_down": "stone stairs descending downward, dungeon staircase, leading deeper, architectural",
    "stairs_up": "stone stairs ascending upward, dungeon staircase, leading out, architectural",
    "steam_vent": "steam vent outlet, brass grate with white vapor escaping, industrial atmosphere",
    "undercroft_hex": "undercroft cellar floor tile, storage room ground pattern, dark stone",
    "aether_lens": "aether lens device, magical focusing crystal on stand, prismatic light refraction",
    "airship_tether": "airship mooring tether, heavy rope and anchor chain, docking connection",
    "anchor_point": "anchor bolt in floor, heavy ring for securing airships, metal fastening point",
    "cargo_crane": "cargo loading crane, mechanical lifting arm, industrial dock equipment",
    "cargo_crate": "wooden cargo crate, shipping container with labels, storage box",
    "gangplank": "gangplank boarding plank, wooden walkway to airship, temporary bridge",
    "lightning_rod": "lightning rod conductor, tall metal pole with crystal tip, electrical safety",
    "mooring_valve": "mooring valve control, brass wheel for dock pressure, steampunk mechanism",
    "wind_gust": "wind gust visual effect, swirling air currents, visible breeze, atmospheric element",
    "book_stack": "stack of ancient books, scholarly tomes piled high, university library decoration",
    "clocktower_bell": "massive clocktower bell, bronze hanging bell with striker, timekeeping monument",
    "ink_vat": "ink vat container, large ceramic pot of dark liquid, writing supply",
    "item_deans_key": "Dean's Key — ornate academic key, gold and ivory, university master key",
    "item_master_key": "Master Key — skeleton key of ultimate access, silver and crystal, universal opener",
    "lecture_desk": "lecture hall desk, scholar's writing table with inkwell, academic furniture",
    "npc_registrar": "NPC registrar character, fussy academic administrator with scrolls, bureaucrat",
    "npc_sneak_thief": "NPC sneak thief character, shifty goblin rogue in dark corner, criminal contact",
    "statue_construct": "construct faction statue, brass guardian monument, mechanical art sculpture",
    "steam_pipe": "steam heating pipe, brass radiator tube, warm industrial infrastructure",
    "blood_ink_vat": "blood ink vat, ceramic container of crimson liquid, demonic writing supply",
    "contract_altar": "contract altar, stone table for signing pacts, demonic legal station",
    "contract_station": "contract station desk, bureaucratic signing table, official paperwork surface",
    "filing_cabinet": "filing cabinet drawer, bureaucratic storage, paper-filled office furniture",
    "item_pact_scroll": "Pact Scroll item, rolled demonic contract with seal, infernal document",
    "item_void_stabilizer": "Void Stabilizer item, device for sealing reality cracks, brass and crystal tech",
    "npc_goblin_forger": "NPC goblin forger character, shady document forger with stamps, criminal forger",
    "summoning_circle": "summoning circle, ritual magic diagram on floor, glowing runic pattern",
    "void_crack": "void crack in reality, tear showing black emptiness, dimensional rupture hazard",
    "witness_stand": "witness stand podium, courtroom testimony platform, bureaucratic furniture",
    "coolant_pipe": "coolant circulation pipe, frosted metal tube, temperature control infrastructure",
    "goblin_alarm": "goblin alarm device, mechanical warning bell, brass alert system, sentry tool",
    "item_elemental_core": "Elemental Core item, crystal containment of pure elemental energy, power source",
    "item_wrench": "wrench tool item, adjustable spanner, engineer's essential tool, mechanical repair",
    "npc_union_representative": "NPC union rep character, tough goblin labor organizer with pamphlets, activist",
    "overclock_console": "overclock control console, steam-powered control panel, pressure gauges and levers",
    "padlock": "heavy brass padlock, locked security device, keyhole and shackle, barrier",
    "reactor_core": "reactor core containment, glowing elemental furnace, critical power source, dangerous",
    "vent_valve": "pressure vent valve, steam release control, brass wheel and pipe, safety device",
    "assembly_station": "bone assembly workbench, skeletal construction table, crafting station",
    "bone_crate": "crate of bones, shipping container filled with skeletal parts, material storage",
    "conveyor_belt": "conveyor belt mechanism, moving transport line, industrial automation, factory floor",
    "gear_crate": "crate of gears, shipping container of mechanical parts, steampunk material storage",
    "glass_case_skull": "glass display case with skull, museum presentation, protective vitrine, exhibit",
    "item_bone_material": "Bone Material crafting resource, pile of bleached bones, construction supply",
    "item_companion_card": "Companion Card item, magical binding card, creature summoning token, ally contract",
    "item_gear_material": "Gear Material crafting resource, pile of brass cogs and springs, mechanical supply",
    "npc_liberated_soul": "NPC liberated soul character, freed ghostly figure with peaceful expression, grateful spirit",
    "smokestack_femur": "femur bone smokestack, industrial chimney made of giant bone, pollution exhaust",
    "soul_furnace": "soul-burning furnace, industrial oven powered by trapped spirits, glowing hot, terrible",
    "soul_orb": "soul orb container, glass sphere holding glowing soul fragment, magical light source",
}

# --- Special case: ghost boss frames ---
GHOST_DESCRIPTION = "ghostly dragon fragment, spectral apocalyptic wisp, faint ethereal presence, memory of power"

# --- Size mapping ---
BOSS_SIZE = (128, 128)
ENEMY_SIZE = (64, 64)
OBJECT_SIZE = (64, 64)  # Most objects are 64x64
LARGE_OBJECT_SIZE = (128, 128)  # Some objects need more detail

LARGE_OBJECTS = {"door_escape", "reactor_core", "soul_furnace", "conveyor_belt", "assembly_station", "cargo_crane"}


def categorize_file(filepath: Path) -> tuple[str, str, str, tuple[int, int]]:
    """
    Categorize a sprite file and return (category, name, state, size).
    Category: 'boss', 'enemy', 'object'
    State: 'attack', 'damage', 'death', 'idle', or 'static'
    """
    filename = filepath.stem
    parts = filename.split('_')
    
    # Determine category from prefix
    if parts[0] == 'boss':
        category = 'boss'
        # boss_the_dean_attack -> name = 'the_dean', state = 'attack'
        if len(parts) >= 3 and parts[-1] in ('attack', 'damage', 'death', 'idle'):
            name = '_'.join(parts[1:-1])
            state = parts[-1]
        else:
            name = '_'.join(parts[1:])
            state = 'static'
        size = BOSS_SIZE
        
    elif parts[0] == 'enemy':
        category = 'enemy'
        # enemy_brass_enforcer_attack -> name = 'brass_enforcer', state = 'attack'
        if len(parts) >= 3 and parts[-1] in ('attack', 'damage', 'death', 'idle'):
            name = '_'.join(parts[1:-1])
            state = parts[-1]
        else:
            name = '_'.join(parts[1:])
            state = 'static'
        size = ENEMY_SIZE
        
    else:
        category = 'object'
        name = filename
        state = 'static'
        # Check if this is a large object
        base_name = name.replace('_f1', '').replace('_f2', '').replace('_f3', '').replace('_f4', '').replace('_f5', '').replace('_f6', '').replace('_f7', '').replace('_f8', '').replace('_f9', '')
        if base_name in LARGE_OBJECTS:
            size = LARGE_OBJECT_SIZE
        else:
            size = OBJECT_SIZE
    
    return category, name, state, size


def get_description(name: str, category: str, state: str) -> str:
    """Build a pixel art description from entity name and state."""
    # Clean up name for lookup
    lookup_name = name
    
    # Handle ghost_boss_f1..f9
    if lookup_name.startswith('ghost_boss'):
        base_desc = GHOST_DESCRIPTION
        frame_num = lookup_name[-1] if lookup_name[-1].isdigit() else ''
        return f"Pixel art sprite, 64x64, transparent background. {base_desc}, animation frame {frame_num}, slightly different pose, side view, highly detailed, medium shading, single color outline."
    
    # Handle booth_trap_1..9
    if lookup_name.startswith('booth_trap_'):
        num = lookup_name[-1]
        return f"Pixel art sprite, 64x64, transparent background. Trap merchant booth variation {num}, vendor stall selling mechanical hazards, different trap display arrangement, side view, highly detailed, medium shading, single color outline."
    
    # Handle gear_part_1..3
    if lookup_name.startswith('gear_part_'):
        num = lookup_name[-1]
        return f"Pixel art sprite, 64x64, transparent background. Gear component variation {num}, spare mechanical part, brass cog wheel, different size and teeth pattern, side view, highly detailed, medium shading, single color outline."
    
    # Handle hoard_* items
    if lookup_name.startswith('hoard_'):
        item_name = lookup_name[6:]  # Remove 'hoard_' prefix
        if item_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[item_name]
        else:
            desc = f"precious treasure item, dungeon hoard loot, valuable artifact"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, treasure item, side view, highly detailed, medium shading, single color outline."
    
    # Handle item_* 
    if lookup_name.startswith('item_'):
        item_name = lookup_name[5:]  # Remove 'item_' prefix
        if item_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[item_name]
        else:
            desc = f"usable item, dungeon equipment, player inventory object"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle npc_*
    if lookup_name.startswith('npc_'):
        npc_name = lookup_name[4:]  # Remove 'npc_' prefix
        if npc_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[npc_name]
        else:
            desc = f"NPC character, dungeon inhabitant, non-player character"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, friendly or neutral, side view, highly detailed, medium shading, single color outline."
    
    # Handle trap_*
    if lookup_name.startswith('trap_'):
        trap_name = lookup_name[5:]  # Remove 'trap_' prefix
        if trap_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[trap_name]
        else:
            desc = f"dungeon trap hazard, dangerous mechanism"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle banner_*
    if lookup_name.startswith('banner_'):
        banner_name = lookup_name[7:]  # Remove 'banner_' prefix
        if banner_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[banner_name]
        else:
            desc = f"faction banner, alliance heraldry, hanging cloth flag"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle elevator_*
    if lookup_name.startswith('elevator_'):
        elev_name = lookup_name[9:]  # Remove 'elevator_' prefix
        if elev_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[elev_name]
        else:
            desc = f"elevator mechanism, vertical transport device"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle food_station_*
    if lookup_name.startswith('food_station_'):
        food_name = lookup_name[13:]  # Remove 'food_station_' prefix
        if food_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[food_name]
        else:
            desc = f"food service station, sustenance point"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle pipe_*
    if lookup_name.startswith('pipe_'):
        pipe_name = lookup_name[5:]  # Remove 'pipe_' prefix
        if pipe_name in ENTITY_DESCRIPTIONS:
            desc = ENTITY_DESCRIPTIONS[pipe_name]
        else:
            desc = f"industrial pipe, plumbing tube, steampunk infrastructure"
        return f"Pixel art sprite, 64x64, transparent background. {desc}, side view, highly detailed, medium shading, single color outline."
    
    # Handle tile_* - Kira handles these, skip
    if lookup_name.startswith('tile_'):
        return "SKIP"
    
    # Standard lookup
    if lookup_name in ENTITY_DESCRIPTIONS:
        base_desc = ENTITY_DESCRIPTIONS[lookup_name]
    else:
        # Generic description from name
        base_desc = lookup_name.replace('_', ' ').title()
    
    # Build state modifier
    if state == 'attack':
        state_desc = "attacking pose, combat stance, aggressive action"
    elif state == 'damage':
        state_desc = "taking damage, hit reaction, wounded posture, pain"
    elif state == 'death':
        state_desc = "defeated, dead, collapsed, final stillness"
    elif state == 'idle':
        state_desc = "idle stance, waiting, passive, ready"
    else:
        state_desc = ""
    
    # Build full prompt
    width, height = (ENEMY_SIZE if category == 'enemy' else BOSS_SIZE if category == 'boss' else OBJECT_SIZE)
    if lookup_name in LARGE_OBJECTS:
        width, height = LARGE_OBJECT_SIZE
    
    if category == 'boss':
        return f"Pixel art sprite, {width}x{height}, transparent background. Boss — {base_desc}, {state_desc}, massive dungeon boss, side view, highly detailed, medium shading, single color outline."
    elif category == 'enemy':
        return f"Pixel art sprite, {width}x{height}, transparent background. Enemy — {base_desc}, {state_desc}, dungeon enemy, side view, highly detailed, medium shading, single color outline."
    else:
        return f"Pixel art sprite, {width}x{height}, transparent background. {base_desc}, dungeon object, side view, highly detailed, medium shading, single color outline."


@dataclass
class SpriteDef:
    filepath: Path
    category: str
    name: str
    state: str
    width: int
    height: int
    prompt: str


def scan_primitives() -> list[SpriteDef]:
    """Scan all floor directories for primitive sprites."""
    sprites = []
    floor_dirs = sorted(BASE_SPRITES_DIR.glob("floor*"))
    
    for floor_dir in floor_dirs:
        # Skip _v2 variants (those are likely already fixed or duplicates)
        if "_v2" in floor_dir.name:
            continue
            
        for png_file in floor_dir.glob("*.png"):
            # Skip import files
            if png_file.suffixes == ['.png', '.import']:
                continue
            # Skip already good files
            if png_file.stat().st_size >= SIZE_THRESHOLD:
                continue
            # Skip tile files (Kira handles these)
            if png_file.stem.startswith("tile_"):
                continue
            
            category, name, state, (width, height) = categorize_file(png_file)
            prompt = get_description(name, category, state)
            
            if prompt == "SKIP":
                continue
            
            sprites.append(SpriteDef(
                filepath=png_file,
                category=category,
                name=name,
                state=state,
                width=width,
                height=height,
                prompt=prompt
            ))
    
    # Sort by priority: boss > enemy > object
    priority = {'boss': 0, 'enemy': 1, 'object': 2}
    sprites.sort(key=lambda s: (priority.get(s.category, 3), s.filepath.name))
    
    return sprites


def generate_sprite(sprite: SpriteDef, api_key: str) -> bool:
    """Generate a single sprite via PixelLab API."""
    output_path = sprite.filepath
    backup_path = output_path.with_suffix(".png.primitive_backup")
    
    # Backup existing primitive
    if output_path.exists():
        try:
            output_path.rename(backup_path)
        except Exception as e:
            print(f"  [WARN] Could not backup {output_path.name}: {e}")
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "description": sprite.prompt,
        "image_size": {"width": sprite.width, "height": sprite.height},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "view": "side",
        "detail": "highly detailed",
        "outline": "single color outline",
        "shading": "medium shading",
    }
    
    for attempt in range(MAX_RETRIES):
        try:
            print(f"  [GEN] {output_path.parent.name}/{output_path.name} ({sprite.category}, {sprite.width}x{sprite.height}) — attempt {attempt + 1}/{MAX_RETRIES}")
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
                    print(f"  [OK]  {output_path.parent.name}/{output_path.name} saved ({len(img_data)} bytes)")
                    # Clean up backup on success
                    if backup_path.exists():
                        backup_path.unlink()
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
    
    print(f"  [FAIL] {output_path.parent.name}/{output_path.name} — all retries exhausted")
    # Restore backup if generation failed
    if backup_path.exists():
        try:
            backup_path.rename(output_path)
            print(f"  [RESTORE] Restored backup for {output_path.name}")
        except:
            pass
    return False


def main():
    print("=" * 70)
    print("PixelLab Floor Sprite Repair — Auto-Scan & Replace")
    print("=" * 70)
    print(f"API Key: {API_KEY[:8]}...{API_KEY[-4:]}")
    print(f"Scanning: {BASE_SPRITES_DIR}/floor*")
    print(f"Threshold: < {SIZE_THRESHOLD} bytes = primitive")
    print("=" * 70)
    
    if not API_KEY or API_KEY == "your-api-key-here":
        print("\n[ERROR] No API key found!")
        sys.exit(1)
    
    # Scan for primitives
    print("\n--- Scanning for primitive sprites ---")
    sprites = scan_primitives()
    
    # Count by category
    bosses = [s for s in sprites if s.category == 'boss']
    enemies = [s for s in sprites if s.category == 'enemy']
    objects = [s for s in sprites if s.category == 'object']
    
    print(f"Found {len(sprites)} primitive sprites:")
    print(f"  - Bosses:     {len(bosses)}")
    print(f"  - Enemies:    {len(enemies)}")
    print(f"  - Objects:    {len(objects)}")
    print("=" * 70)
    
    if len(sprites) == 0:
        print("\n[OK] No primitive sprites found! All clean.")
        return
    
    # Generate all sprites
    success_count = 0
    fail_count = 0
    
    if bosses:
        print(f"\n--- Batch 1: Boss Sprites ({len(bosses)}) ---")
        for sprite in bosses:
            if generate_sprite(sprite, API_KEY):
                success_count += 1
            else:
                fail_count += 1
            time.sleep(REQUEST_DELAY)
    
    if enemies:
        print(f"\n--- Batch 2: Enemy Sprites ({len(enemies)}) ---")
        for sprite in enemies:
            if generate_sprite(sprite, API_KEY):
                success_count += 1
            else:
                fail_count += 1
            time.sleep(REQUEST_DELAY)
    
    if objects:
        print(f"\n--- Batch 3: Object Sprites ({len(objects)}) ---")
        for sprite in objects:
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
    print(f"Total:    {success_count + fail_count}/{len(sprites)}")
    
    # Clean up any remaining backups
    backup_files = list(BASE_SPRITES_DIR.rglob("*.primitive_backup"))
    for backup in backup_files:
        backup.unlink()
    if backup_files:
        print(f"\nCleaned up {len(backup_files)} backup files.")
    
    print("=" * 70)


if __name__ == "__main__":
    main()
