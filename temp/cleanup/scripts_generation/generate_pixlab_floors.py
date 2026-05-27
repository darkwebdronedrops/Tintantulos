#!/usr/bin/env python3
"""PixelLab Art Pass — Floors 5-10 + Floor 4 fixes"""
import requests, base64, time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
PROJECT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo")

def generate(name, size, prompt, out_dir, seed=600, no_bg=True, timeout=120):
    out_path = out_dir / f"{name}.png"
    if out_path.exists():
        print(f"[SKIP] {name}.png")
        return True
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": prompt, "image_size": {"width": size, "height": size}, "no_background": no_bg, "seed": seed},
            timeout=timeout,
        )
        if resp.status_code == 200:
            data = resp.json()
            img_data = data.get("image")
            b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
            if b64:
                out_path.write_bytes(base64.b64decode(b64))
                print(f"[OK] {name}.png ({size}x{size})")
                return True
        print(f"[FAIL] {name}: HTTP {resp.status_code}")
        return False
    except Exception as e:
        print(f"[ERROR] {name}: {e}")
        return False

# ===== FLOOR 4 FIXES =====
floor4_dir = PROJECT_DIR / "assets/sprites/floor4"
FLOOR4_FIXES = [
    ("vendor_gearwright_interior", 400, "pixel art background, warm bazaar shop interior, merchant stall inside curio market, brass fixtures, hanging lanterns with amber glow, wood counter with gear parts on display, shelves with brass trinkets, ornate steampunk bazaar, warm gold and brown colors, cozy shop"),
    ("undercroft_floor", 400, "pixel art background, underground bazaar floor, stone arch ceiling, brass pipes along walls, amber wall sconces, market stalls with red canopies, warm dim lighting, stone and brass, subterranean marketplace, earthy warm tones"),
]

# ===== FLOOR 5: Airship Docks =====
floor5_dir = PROJECT_DIR / "assets/sprites/floor5_v2"
floor5_dir.mkdir(exist_ok=True)
FLOOR5_ASSETS = [
    ("bg_mooring", 400, "pixel art background, airship docking platform, open sky with clouds, brass railings, rope moorings, wooden dock planks, sky blue and brass colors, airship tethered in background"),
    ("bg_breeze", 400, "pixel art background, airship deck breezeway, wind-swept platform, cloud sea below, brass and wood construction, open air corridor, sky blue white and brass"),
    ("bg_boiler", 400, "pixel art background, airship boiler room, steam pipes, brass machinery, coal furnace glow, industrial steampunk, warm oranges and brass, steam vents"),
    ("bg_gale", 400, "pixel art background, airship gale deck, stormy sky, wind-torn platform, lightning in clouds, dramatic airship scene, dark blues and brass, storm atmosphere"),
    ("bg_crows_nest", 400, "pixel art background, airship crow's nest lookout, highest platform, telescope, vast cloud ocean, sunset sky, golden hour, brass and wood"),
    ("bg_aetherworks", 400, "pixel art background, airship aetherworks laboratory, crystal machinery, glowing aether lenses, brass and crystal, magical steampunk, teal and gold glows"),
    ("bg_cargo", 400, "pixel art background, airship cargo hold, crates and barrels, rope netting, dim lantern light, wooden interior, brass fittings, warm brown and amber"),
    ("boss_elemental_core", 256, "pixel art sprite, storm elemental boss, swirling cloud and lightning creature, crackling energy core, airship dock guardian, tempest elemental, blue white and gold"),
    ("enemy_mooring_rat_idle", 128, "pixel art sprite, small goblin dock worker, ragged clothes, rope belt, brass goggles, mischievous, airship dock scavenger, green and brown"),
    ("enemy_aether_mage_idle", 128, "pixel art sprite, aether-wielding mage, floating crystals, brass staff with teal gem, airship scholar, robes and brass armor, purple and teal"),
    ("enemy_wind_wraith_idle", 128, "pixel art sprite, wind spirit creature, translucent body, swirling cloud form, crackling with static, sky blue and white, ethereal"),
    ("enemy_brass_marine_idle", 128, "pixel art sprite, brass-armored marine, heavy armor, boarding hook, airship soldier, military steampunk, brass and navy blue"),
    ("item_aether_lens", 64, "pixel art sprite, crystal lens artifact, glowing teal, brass frame, magical focusing device, aether technology, transparent background"),
    ("item_mooring_rope", 64, "pixel art sprite, coiled rope with brass hook, nautical equipment, airship dock gear, brown rope and gold hook"),
    ("item_storm_heart", 64, "pixel art sprite, crackling storm heart, lightning orb, blue white energy core, elemental power source, glowing and dangerous"),
]

# ===== FLOOR 6: Lunar University =====
floor6_dir = PROJECT_DIR / "assets/sprites/floor6_v2"
floor6_dir.mkdir(exist_ok=True)
FLOOR6_ASSETS = [
    ("bg_quadrangle", 400, "pixel art background, university quadrangle courtyard, stone architecture, moonlight beams, academic gardens, gothic university, silver and stone, night scene"),
    ("bg_construct_college", 400, "pixel art background, construct engineering college, gear-shaped building, brass machinery, student workshop, steampunk university, warm brass and wood"),
    ("bg_elemental_college", 400, "pixel art background, elemental magic college, glowing crystals, arcane circles, magical laboratory, blue and purple glows, mystical university"),
    ("bg_undead_college", 400, "pixel art background, necromancy college, bone architecture, dark magic, green glow, macabre academic, dark stone and sickly green"),
    ("bg_aberration_college", 400, "pixel art background, aberration studies college, twisted geometry, reality warping, non-euclidean architecture, purple and void black, mind-bending"),
    ("bg_undercroft", 400, "pixel art background, university undercroft, hidden library, ancient tomes, secret passages, dim candlelight, stone and wood, warm amber"),
    ("bg_clocktower_apex", 400, "pixel art background, clocktower apex, massive bell, gears turning, moonlight through windows, highest point of university, silver and brass, night"),
    ("boss_the_dean", 256, "pixel art sprite, university dean boss, elderly scholar in ornate robes, brass monocle, academic staff, severe expression, dark academic, purple and gold"),
    ("enemy_freshman_idle", 128, "pixel art sprite, university freshman student, backpack, anxious expression, novice mage, basic robes, young and inexperienced, blue and grey"),
    ("enemy_tenured_prof_idle", 128, "pixel art sprite, tenured professor, tweed jacket, pipe, arrogant posture, academic authority, brown and brass, distinguished"),
    ("enemy_lab_assistant_idle", 128, "pixel art sprite, laboratory assistant, stained apron, goggles, carrying beakers, overworked student, white coat and green stains"),
    ("enemy_librarian_idle", 128, "pixel art sprite, ancient librarian, hunched figure, book-covered robes, spectacles, knowledge keeper, grey and brown, mysterious"),
    ("item_dean_key", 64, "pixel art sprite, ornate brass key, academic seal, master key, university authority, gold and teal, important item"),
    ("item_graduate_scroll", 64, "pixel art sprite, rolled diploma scroll, wax seal, academic achievement, paper and gold ribbon, university graduation"),
    ("item_moonstone", 64, "pixel art sprite, glowing moonstone crystal, silver light, lunar magic, round and luminous, pale blue and white"),
]

# ===== FLOOR 7: Broken Pact =====
floor7_dir = PROJECT_DIR / "assets/sprites/floor7_v2"
floor7_dir.mkdir(exist_ok=True)
FLOOR7_ASSETS = [
    ("bg_outer_ring", 400, "pixel art background, bureaucratic outer office, filing cabinets, waiting chairs, soul-crushing office, beige and grey, fluorescent lighting, mundane horror"),
    ("bg_middle_ring", 400, "pixel art background, contract negotiation hall, long tables, legal documents, demon and human meeting, red and gold, tense atmosphere"),
    ("bg_inner_ring", 400, "pixel art background, inner sanctum of broken pact, void cracks in reality, purple energy leaks, corrupted legal space, dark purple and black, cosmic horror"),
    ("bg_auditorium", 400, "pixel art background, demonic courtroom, judge's bench made of bone, witness stand, jury of demons, red and black, infernal justice"),
    ("bg_filing", 400, "pixel art background, infinite filing room, towering shelves of contracts, paper everywhere, bureaucratic labyrinth, beige and shadow, overwhelming"),
    ("bg_laboratory", 400, "pixel art background, pact research lab, binding circles, test subjects, contract magic experiments, green and purple, unethical science"),
    ("bg_break_room", 400, "pixel art background, demon break room, coffee machine, mundane horror, hellish office workers relaxing, red and beige, comedy horror"),
    ("boss_the_denied", 256, "pixel art sprite, the denied one, rejected demon lord, broken horns, tattered suit, bureaucratic demon, tragedy and rage, purple and black, sad boss"),
    ("enemy_contract_clerk_idle", 128, "pixel art sprite, contract clerk demon, imp with clipboard, tiny glasses, bureaucratic demon, beige suit, hellish office worker"),
    ("enemy_soul_auditor_idle", 128, "pixel art sprite, soul auditor, floating eye with scales, calculating gaze, judgmental, gold and white, cosmic entity"),
    ("enemy_void_touched_idle", 128, "pixel art sprite, void-touched lawyer, human corrupted by void, purple mutations, suit and tie, corporate horror, purple and grey"),
    ("enemy_bailiff_idle", 128, "pixel art sprite, demonic bailiff, large brute with badge, enforcer, black uniform, muscle, dark red and black"),
    ("item_blood_contract", 64, "pixel art sprite, blood-signed contract, parchment with red seal, demonic pact, legal document, red wax and brown paper"),
    ("item_void_shard", 64, "pixel art sprite, void crystal shard, purple black glass, reality fragment, dangerous artifact, glowing purple edges"),
    ("item_judgment_hammer", 64, "pixel art sprite, judge's gavel, bone and gold, legal authority, demonic court tool, ornate and intimidating"),
]

# ===== FLOOR 8: Overclock Forge =====
floor8_dir = PROJECT_DIR / "assets/sprites/floor8_v2"
floor8_dir.mkdir(exist_ok=True)
FLOOR8_ASSETS = [
    ("bg_loading_bay", 400, "pixel art background, goblin forge loading bay, raw materials, ore piles, conveyor belts, industrial entrance, orange and brown, busy"),
    ("bg_lower_works", 400, "pixel art background, lower forge works, glowing furnaces, lava channels, goblin workers, extreme heat, red orange and black, dangerous"),
    ("bg_middle_works", 400, "pixel art background, middle forge works, assembly line, half-built constructs, sparks flying, industrial chaos, brass and fire, dynamic"),
    ("bg_upper_works", 400, "pixel art background, upper forge works, quality control, inspection tables, precision tools, calmer but still hot, brass and steam"),
    ("bg_containment_hall", 400, "pixel art background, containment vessel hall, massive glass tanks, experiments inside, warning signs, green and yellow, hazardous"),
    ("bg_break_room", 400, "pixel art background, goblin break room, tiny furniture, union posters, snack machine, comedy scale, green and brown, cozy chaos"),
    ("bg_union_hall", 400, "pixel art background, goblin union hall, protest banners, meeting tables, labor organizer desk, revolutionary green, political"),
    ("bg_control_room", 400, "pixel art background, forge control room, lever panels, gauge clusters, emergency buttons, industrial steampunk, brass and red, tense"),
    ("boss_chief_engineer_blix", 256, "pixel art sprite, goblin chief engineer boss, large goblin in hard hat, oversized wrench, oil-stained overalls, authoritative, green and brass"),
    ("enemy_goblin_worker_idle", 128, "pixel art sprite, goblin forge worker, dirty apron, welding mask, tired posture, industrial goblin, green and brown"),
    ("enemy_overclocked_construct_idle", 128, "pixel art sprite, overclocked construct, glowing red hot, steam vents, dangerously overheated, brass and fire, unstable"),
    ("enemy_union_organizer_idle", 128, "pixel art sprite, goblin union organizer, raised fist, protest sign, passionate, political goblin, green and red"),
    ("enemy_containment_breach_idle", 128, "pixel art sprite, containment breach monster, escaped experiment, amalgamation of parts, failed construct, purple and green, horror"),
    ("item_overclock_gear", 64, "pixel art sprite, red-hot overclock gear, glowing with heat, dangerous power, steam coming off, brass and fire orange"),
    ("item_goblin_hard_hat", 64, "pixel art sprite, goblin hard hat, yellow construction helmet, tiny size, safety equipment, yellow and green"),
    ("item_union_card", 64, "pixel art sprite, goblin union membership card, green and gold, worker solidarity, identification badge"),
]

# ===== FLOOR 9: Bone Forges =====
floor9_dir = PROJECT_DIR / "assets/sprites/floor9_v2"
floor9_dir.mkdir(exist_ok=True)
FLOOR9_ASSETS = [
    ("bg_bone_yard", 400, "pixel art background, bone yard, massive piles of bones, sorting tables, grim harvesting, white and grey, macabre industry"),
    ("bg_furnace_room", 400, "pixel art background, soul furnace room, burning souls in glass containers, ethical horror, orange and ghostly blue, intense heat and cold"),
    ("bg_assembly_line", 400, "pixel art background, undead assembly line, skeletons being assembled, conveyor belt, bone and brass, white and gold, factory of death"),
    ("bg_gear_works", 400, "pixel art background, bone gear works, grinding bone into powder, industrial processing, white dust, grey and brass, dusty"),
    ("bg_break_station", 400, "pixel art background, worker break station, exhausted undead sitting, coffee mugs, dark humor, brown and grey, sad comedy"),
    ("bg_conveyor_maze", 400, "pixel art background, conveyor belt maze, complex routing, bone parts moving, industrial labyrinth, grey and brass, confusing"),
    ("bg_foundry_pit", 400, "pixel art background, bone foundry pit, molten bone metal, glowing white-hot, extreme heat, white and orange, dangerous"),
    ("bg_foreman_office", 400, "pixel art background, foreman office, desk with bone inlay, stern atmosphere, management, dark wood and white bone, authoritarian"),
    ("boss_the_foreman_eternal", 256, "pixel art sprite, the foreman eternal, skeletal overseer, bone and brass armor, whip made of spine, terrifying manager, white and gold"),
    ("enemy_bone_sorter_idle", 128, "pixel art sprite, skeleton bone sorter, sorting bones by size, tedious work, white and brown, undead laborer"),
    ("enemy_soul_smith_idle", 128, "pixel art sprite, soul smith, hammering ghostly metal, ethereal flames, glowing eyes, white and blue, spectral smith"),
    ("enemy_quality_control_idle", 128, "pixel art sprite, undead quality control inspector, clipboard, magnifying glass, checking bone density, white and brass, meticulous"),
    ("enemy_liberator_agent_idle", 128, "pixel art sprite, liberator agent, undercover hero, hidden among undead, secret savior, grey and muted blue, covert"),
    ("item_soul_gem", 64, "pixel art sprite, trapped soul gem, glowing blue spirit in crystal, ethical dilemma, beautiful and sad, blue and white"),
    ("item_bone_saw", 64, "pixel art sprite, industrial bone saw, medical horror, processing tool, sharp and dangerous, steel and white"),
    ("item_liberator_badge", 64, "pixel art sprite, liberator resistance badge, hidden symbol, freedom fighter insignia, subtle and important, muted gold"),
]

# ===== FLOOR 10: The Dragon =====
floor10_dir = PROJECT_DIR / "assets/sprites/floor10_v2"
floor10_dir.mkdir(exist_ok=True)
FLOOR10_ASSETS = [
    ("bg_threshold", 400, "pixel art background, sacred threshold, stone pillars floating in void, ethereal light, entrance to final chamber, gold and void black, mystical"),
    ("bg_witness", 400, "pixel art background, witness hall, ghostly fungal echoes, memory clouds, spore remnants, purple and green ghosts, ethereal"),
    ("bg_memory", 400, "pixel art background, gearworks memory, frozen clockwork, dial stopped in time, brass and teal, nostalgic and sad"),
    ("bg_hoard", 400, "pixel art background, dragon's hoard of moments, crystallized choices floating, memories made solid, prismatic light, multicolored crystals, sacred"),
    ("bg_weight", 400, "pixel art background, weight revelation, glowing runes showing player score, judgment chamber, gold runes on dark stone, evaluative"),
    ("bg_aspect_time", 400, "pixel art background, aspect of time arena, clockwork dragon scales, replaying memories, time distortion, brass and silver, temporal"),
    ("bg_aspect_greed", 400, "pixel art background, aspect of greed arena, gold and flesh merging, growing larger with wealth, avarice made manifest, gold and crimson, opulent"),
    ("bg_aspect_transformation", 400, "pixel art background, aspect of transformation arena, shifting forms, reality warping, every enemy combined, prismatic and unstable, chaotic"),
    ("bg_approach", 400, "pixel art background, approach to dragon, molten gold throne visible, final path, intimidation and awe, gold and shadow, epic"),
    ("bg_revelation", 400, "pixel art background, dragon revelation chamber, molten gold throne, crack in wall behind, sacred emptiness, gold and void, revelation"),
    ("bg_throne", 400, "pixel art background, final throne room, three paths visible, choice chamber, destiny, gold white and shadow, climactic"),
    ("boss_the_dragon", 256, "pixel art sprite, the dragon boss, wizard who became dragon, molten gold scales, tragic not epic, ancient power, gold and shadow, faustian"),
    ("ghost_boss_f1", 128, "pixel art sprite, ghost of the door boss, translucent construct spirit, ethereal brass, memory of floor 1, teal and ghostly"),
    ("ghost_boss_f2", 128, "pixel art sprite, ghost of flesh garden boss, fungal spirit echo, purple and green ghost, memory of floor 2, ethereal"),
    ("ghost_boss_f3", 128, "pixel art sprite, ghost of gearmother boss, clockwork spirit, brass and teal ghost, memory of floor 3, ethereal"),
    ("ghost_boss_f4", 128, "pixel art sprite, ghost of bazaar boss, merchant spirit, gold and brass ghost, memory of floor 4, ethereal"),
    ("ghost_boss_f5", 128, "pixel art sprite, ghost of elemental core, storm spirit, blue and white ghost, memory of floor 5, ethereal"),
    ("ghost_boss_f6", 128, "pixel art sprite, ghost of the dean, academic spirit, purple and gold ghost, memory of floor 6, ethereal"),
    ("ghost_boss_f7", 128, "pixel art sprite, ghost of the denied, broken demon spirit, purple and black ghost, memory of floor 7, ethereal"),
    ("ghost_boss_f8", 128, "pixel art sprite, ghost of blix, goblin engineer spirit, green and brass ghost, memory of floor 8, ethereal"),
    ("ghost_boss_f9", 128, "pixel art sprite, ghost of foreman eternal, skeletal overseer spirit, white and gold ghost, memory of floor 9, ethereal"),
    ("hoard_blood_contract", 64, "pixel art sprite, crystallized blood contract, floor 7 pact made solid, red crystal document, choice object, crimson and gold"),
    ("hoard_soul_gem", 64, "pixel art sprite, crystallized soul gem, floor 9 choice, blue crystal with spirit inside, ethereal and beautiful"),
    ("hoard_graduate_scroll", 64, "pixel art sprite, crystallized diploma scroll, floor 6 achievement, golden paper in crystal, pride and regret"),
    ("item_wisdom", 64, "pixel art sprite, wisdom card reward, final pre-dragon card, golden and mystical, knowledge made tangible"),
]

ALL_JOBS = []
for name, size, prompt in FLOOR4_FIXES:
    ALL_JOBS.append((name, size, prompt, floor4_dir, 800 + len(ALL_JOBS), False))
for name, size, prompt in FLOOR5_ASSETS:
    ALL_JOBS.append((name, size, prompt, floor5_dir, 900 + len(ALL_JOBS), "bg_" not in name))
for name, size, prompt in FLOOR6_ASSETS:
    ALL_JOBS.append((name, size, prompt, floor6_dir, 1000 + len(ALL_JOBS), "bg_" not in name))
for name, size, prompt in FLOOR7_ASSETS:
    ALL_JOBS.append((name, size, prompt, floor7_dir, 1100 + len(ALL_JOBS), "bg_" not in name))
for name, size, prompt in FLOOR8_ASSETS:
    ALL_JOBS.append((name, size, prompt, floor8_dir, 1200 + len(ALL_JOBS), "bg_" not in name))
for name, size, prompt in FLOOR9_ASSETS:
    ALL_JOBS.append((name, size, prompt, floor9_dir, 1300 + len(ALL_JOBS), "bg_" not in name))
for name, size, prompt in FLOOR10_ASSETS:
    no_bg = "bg_" not in name and "ghost_" not in name and "hoard_" not in name and "item_" not in name
    ALL_JOBS.append((name, size, prompt, floor10_dir, 1400 + len(ALL_JOBS), no_bg))

print(f"Total jobs: {len(ALL_JOBS)}")

if __name__ == "__main__":
    ok = 0; fail = 0
    for i, (name, size, prompt, out_dir, seed, no_bg) in enumerate(ALL_JOBS, 1):
        print(f"[{i}/{len(ALL_JOBS)}] ", end="", flush=True)
        if generate(name, size, prompt, out_dir, seed, no_bg):
            ok += 1
        else:
            fail += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(ALL_JOBS)} OK, {fail} failed")
