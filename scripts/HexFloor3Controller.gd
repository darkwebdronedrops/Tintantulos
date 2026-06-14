extends Node2D

# ===================================================================
# FLOOR 3 CONTROLLER — Hex-Based — The Gearworks
# ===================================================================
# 12 rooms arranged in a large ring around the Crown Cog center hub.
# Room 12 (The Quench) is stationary at the top (12 o'clock).
# Rooms 1-11 rotate clockwise when the dial is triggered (R key).
# Light Beam Puzzle: align widgets to the center.
# Machinist Shop in the Crown Cog.
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "12"  # Start at The Quench
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false
var is_paused: bool = false

# Click-to-Move
var path_movement_active: bool = false
var path_movement_target: Array[Vector2i] = []
var path_movement_index: int = 0
var path_movement_timer: float = 0.0
const PATH_MOVE_STEP_INTERVAL: float = 0.12

# Dial rotation
var dial_position: int = 0
const ROOM_COUNT: int = 12

# Room data
var room_data: Dictionary = {}
var room_hex_positions: Array[Vector2i] = []  # Current hex positions for each room (1-12)

# Center hub
var crown_cog_hex: Vector2i = Vector2i(0, 0)

# Light Beam Puzzle
var light_beam_widgets: Array[Dictionary] = []
var light_beam_active: bool = false

# Machinist Shop
var in_shop: bool = false
var shop_ui: Control

# Combat
var hex_enemies: Array[HexEnemy] = []
var enemy_container: Node2D
var ambush_bonus: bool = false

# UI
var interact_prompt: Label
var pause_menu: CanvasLayer

# Room names
const ROOM_NAMES: Array[String] = [
"The Reservoir", "The Spark", "The Governor", "The Draft", "The Temper",
"The Beacon", "The Escapement", "The Bearing", "The Flywheel",
"The Counterweight", "The Oiler", "The Quench"
]

const BOSS_ROOMS: Array[int] = [6, 9, 11]
const BOSS_TYPES: Dictionary = {
6: "TheCaldera", 9: "GearMother", 11: "TheEidolon"
}

# Colors
const ROOM_COLORS: Array[Color] = [
Color(0.3, 0.4, 0.45), Color(0.45, 0.3, 0.25), Color(0.35, 0.35, 0.4),
Color(0.4, 0.4, 0.45), Color(0.45, 0.3, 0.2), Color(0.35, 0.35, 0.4),
Color(0.4, 0.4, 0.35), Color(0.4, 0.4, 0.4), Color(0.35, 0.35, 0.4),
Color(0.4, 0.4, 0.35), Color(0.35, 0.3, 0.25), Color(0.3, 0.4, 0.45)
]

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
    call_deferred("_build_floor")

func _build_floor():
    if hex_map:
        hex_map.generate_floor3_layout()
        print("[Floor3-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())

    _setup_room_positions()
    _setup_combat()
    _setup_ui()
    _setup_player()
    _setup_enemies()
    _setup_light_beam_puzzle()
    _setup_machinist_shop()

    AudioManager.play_floor_ambient(3)
    _enter_room("12")

# ===================================================================
# ROOM POSITIONS (Dial System)
# ===================================================================

func _setup_room_positions():
    """Place 12 rooms in a ring around the center. Room 12 is fixed at top."""
    var ring_radius: int = 18
    var center = Vector2i(0, 0)

    for i in range(ROOM_COUNT):
        var room_id = str(i + 1)
        var angle = _get_room_angle(i + 1)
        var hex_pos = _angle_to_hex(center, ring_radius, angle)
        room_hex_positions.append(hex_pos)
        room_data[room_id] = {
            "hex": hex_pos,
            "radius": 5,
            "encounter": "standard" if (i + 1) not in BOSS_ROOMS else "boss",
            "display": ROOM_NAMES[i],
            "boss_type": BOSS_TYPES.get(i + 1, ""),
            "color": ROOM_COLORS[i]
        }
        print("[Floor3-Hex] Room %s: %s at %s" % [room_id, ROOM_NAMES[i], str(hex_pos)])

func _get_room_angle(room_id: int) -> float:
    """Get the base angle for a room (1-12 like clock positions). Room 12 at top (-90 degrees)."""
    var slot = (room_id % ROOM_COUNT)
    return -90.0 + (slot * 30.0)  # 30 degrees per slot

func _angle_to_hex(center: Vector2i, radius: int, angle_deg: float) -> Vector2i:
    """Convert angle and radius to hex coordinates."""
    var angle_rad = deg_to_rad(angle_deg)
    var x = int(center.x + radius * cos(angle_rad))
    var y = int(center.y + radius * sin(angle_rad) * 0.577)  # Flatten for hex grid
    return Vector2i(x, y)

func _rotate_dial():
    """Rotate rooms 1-11 clockwise by one position. Room 12 stays fixed."""
    AudioManager.play_sfx("dial_click")

    # Rotate positions 0-10 (rooms 1-11), keep position 11 (room 12) fixed
    var last_pos = room_hex_positions[10]
    for i in range(10, 0, -1):
        room_hex_positions[i] = room_hex_positions[i - 1]
    room_hex_positions[0] = last_pos

    dial_position = (dial_position + 1) % 11

    # Update room_data with new positions
    for i in range(ROOM_COUNT):
        var room_id = str(i + 1)
        room_data[room_id]["hex"] = room_hex_positions[i]

    _show_notification("DIAL ROTATED! Rooms have shifted!", Color(0.9, 0.7, 0.3), 3.0)
    print("[Floor3-Hex] Dial rotated. New positions: %s" % str(room_hex_positions))

    # Regenerate hex grid with new positions
    _regenerate_hex_grid()
    
    # Update light beam widget positions
    _update_widget_positions()
    
    # Update enemy positions to match new room positions
    _update_enemy_positions()

    # Move player if they're now inside a wall
    _ensure_player_walkable()

func _regenerate_hex_grid():
    """Clear and rebuild hex grid with current room positions."""
    if not hex_map:
        return
    
    hex_map.clear_grid()
    
    # Regenerate center hub
    var empty_portals: Array[Vector2i] = []
    hex_map._generate_room("f3_center", crown_cog_hex, 4, empty_portals)
    for q in range(-2, 3):
        for r in range(-2, 3):
            var hex = Vector2i(q, r)
            if HexTileMap._hex_distance(hex, Vector2i(0, 0)) <= 2:
                hex_map.set_tile(hex, HexTileMap.TILE_OBJECT)
    
    # Regenerate 12 rooms at current positions
    for i in range(ROOM_COUNT):
        var room_id = str(i + 1)
        var room_hex = room_data[room_id]["hex"]
        hex_map._generate_room("f3_room_%d" % (i + 1), room_hex, 5, empty_portals)
    
    # Regenerate corridors connecting adjacent rooms in the ring
    for i in range(ROOM_COUNT):
        var a = room_data[str(i + 1)]["hex"]
        var next_idx = ((i + 1) % 12) + 1
        var b = room_data[str(next_idx)]["hex"]
        var line = HexTileMap._hex_line(a, b)
        for hex in line:
            if not hex_map.grid.has(hex):
                hex_map.set_tile(hex, HexTileMap.TILE_FLOOR)
    
    print("[Floor3-Hex] Hex grid regenerated: %d tiles" % hex_map.grid.size())

func _update_widget_positions():
    """Update light beam widget positions after rotation."""
    for widget in light_beam_widgets:
        var room_id = widget["room_id"]
        var room_hex = room_data[room_id]["hex"]
        widget["hex"] = room_hex + Vector2i(0, 2)  # Offset toward center

func _update_enemy_positions():
    """Move enemies to match new room positions after rotation."""
    for enemy in hex_enemies:
        if not is_instance_valid(enemy):
            continue
        
        # Find which room this enemy belongs to (by original position)
        for room_id in room_data.keys():
            if room_id == "12":
                continue
            var room = room_data[room_id]
            # If enemy was near this room's original position, move it to new position
            if HexTileMap._hex_distance(enemy.patrol_center, room["hex"]) <= 5:
                # Reposition enemy relative to new room center
                var offset = enemy.hex_pos - enemy.patrol_center
                enemy.patrol_center = room["hex"]
                enemy.hex_pos = room["hex"] + offset
                break


func _ensure_player_walkable():
    var player_hex = hex_map.world_to_hex(player_node.global_position)
    if not hex_map.is_walkable(player_hex):
        # Move player to nearest walkable hex
        for dir in HexTileMap.DIRECTIONS:
            var neighbor = player_hex + dir
            if hex_map.is_walkable(neighbor):
                player_node.global_position = hex_map.hex_to_world(neighbor)
                break

# ===================================================================
# PLAYER
# ===================================================================

func _setup_player():
    player_node = get_tree().get_first_node_in_group("player")

    if not player_node:
        player_node = CharacterBody2D.new()
        player_node.name = "Player"
        player_node.z_index = 100
        player_node.add_to_group("player")

        var collision = CollisionShape2D.new()
        var circle = CircleShape2D.new()
        circle.radius = 12.0
        collision.shape = circle
        player_node.add_child(collision)

        player_node.collision_layer = 2
        player_node.collision_mask = 1

        var player_sprite = Sprite2D.new()
        player_sprite.name = "PlayerSprite"
        player_sprite.centered = true
        player_sprite.scale = Vector2(3.0, 3.0)
        player_node.add_child(player_sprite)

        var animator = Node2D.new()
        animator.name = "PlayerAnimator"
        animator.set_script(preload("res://scripts/PlayerAnimator.gd"))
        player_node.add_child(animator)

        var shadow = Polygon2D.new()
        shadow.name = "Shadow"
        shadow.polygon = PackedVector2Array([
            Vector2(-15, 25), Vector2(15, 25),
            Vector2(10, 35), Vector2(-10, 35)
        ])
        shadow.color = Color(0.0, 0.0, 0.0, 0.3)
        shadow.z_index = -1
        player_node.add_child(shadow)

        add_child(player_node)
        print("[Floor3-Hex] Player created")

    # Place at Room 12 (The Quench)
    var start_hex = room_data["12"]["hex"]
    player_node.global_position = hex_map.hex_to_world(start_hex)
    print("[Floor3-Hex] Player placed at The Quench: %s" % str(start_hex))

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
    var combat_manager = get_node_or_null("CombatManager")
    var ui = get_node_or_null("CombatUI")
    if ui and combat_manager:
        ui.setup(combat_manager)

func _start_combat(encounter_type: String, room_id: String = ""):
    if in_combat:
        return
    in_combat = true

    var combat_manager = get_node_or_null("CombatManager")
    var ui = get_node_or_null("CombatUI")
    if not combat_manager or not ui:
        return

    # Build enemy list
    var enemy_data = _build_enemy_list(encounter_type, room_id)
    var enemy_list = enemy_data["enemies"]
    var is_boss = enemy_data.get("is_boss", false)

    if enemy_list.is_empty():
        in_combat = false
        return

    var player_deck = GameState.player_deck
    if player_deck.is_empty():
        player_deck = CardDB.get_starter_deck()
        GameState.player_deck = player_deck

    combat_manager.start_combat(enemy_list, player_deck)
    ui.visible = true

    # Hide interact prompt
    _hide_interact_prompt()

    print("[Floor3-Hex] Combat started: %s" % encounter_type)

func _build_enemy_list(encounter_type: String, room_id: String = "") -> Dictionary:
    var enemies = []
    var is_boss = false

    if encounter_type == "boss" and room_id != "":
        var boss_type = room_data[room_id].get("boss_type", "")
        if boss_type != "":
            enemies.append({"name": boss_type, "level": 5, "is_boss": true})
            is_boss = true
    elif encounter_type == "standard":
        enemies.append({"name": "Construct_gearling", "level": 2})
        enemies.append({"name": "Construct_piston", "level": 2})
    elif encounter_type == "warren":
        enemies.append({"name": "Goblin_tinkerer", "level": 2})
        enemies.append({"name": "Goblin_scrapper", "level": 1})
    elif encounter_type == "elite":
        enemies.append({"name": "Construct_automaton", "level": 3})
        enemies.append({"name": "Construct_gearling", "level": 2})

    return {"enemies": enemies, "is_boss": is_boss}

func _on_combat_ended(player_won: bool):
    in_combat = false
    var ui = get_node_or_null("CombatUI")
    if ui:
        ui.visible = false

    if not player_won:
        _show_notification("Defeated! Returning to The Quench...", Color(0.9, 0.3, 0.3), 3.0)
        # Respawn at Room 12
        var quench_hex = room_data["12"]["hex"]
        player_node.global_position = hex_map.hex_to_world(quench_hex)
    else:
        # Mark room cleared
        if room_data.has(current_room_id):
            room_data[current_room_id]["cleared"] = true

# ===================================================================
# ENEMIES
# ===================================================================

func _setup_enemies():
    enemy_container = Node2D.new()
    enemy_container.name = "EnemyContainer"
    add_child(enemy_container)

    # Spawn enemies in each room (except The Quench which is safe)
    for room_id in room_data.keys():
        if room_id == "12":
            continue  # Safe room

        var room = room_data[room_id]
        var center = room["hex"]
        var encounter = room["encounter"]

        if encounter == "boss":
            # Boss is stationary, doesn't patrol
            var enemy = HexEnemy.new("boss_%s" % room_id, room.get("boss_type", "Boss"), center + Vector2i(2, 0), "Construct", true)
            enemy.patrol_center = enemy.hex_pos
            enemy.patrol_radius = 0
            enemy.view_range = 4
            enemy_container.add_child(enemy)
            hex_enemies.append(enemy)
        else:
            # Standard patrol enemies
            var enemy = HexEnemy.new("enemy_%s" % room_id, "Construct_gearling", center + Vector2i(1, 1), "Construct", false)
            enemy.patrol_center = center
            enemy.patrol_radius = 3
            enemy.view_range = 4
            enemy_container.add_child(enemy)
            hex_enemies.append(enemy)

    print("[Floor3-Hex] %d hex enemies spawned" % hex_enemies.size())

func _process(delta: float):
    if not player_node or in_combat or is_paused:
        return

    # Path movement
    if path_movement_active:
        path_movement_timer += delta
        if path_movement_timer >= PATH_MOVE_STEP_INTERVAL:
            path_movement_timer = 0.0
            _step_path()

    # Check enemy sight and ambush
    _check_enemy_sight()

    # Check if player entered a room
    _check_room_entry()

func _check_room_entry():
    var player_hex = hex_map.world_to_hex(player_node.global_position)

    for room_id in room_data.keys():
        var room = room_data[room_id]
        var center = room["hex"]
        var radius = room["radius"]

        if HexTileMap._hex_distance(player_hex, center) <= radius:
            if current_room_id != room_id:
                _enter_room(room_id)
            break

func _enter_room(room_id: String):
    current_room_id = room_id
    var room = room_data[room_id]
    var display_name = room["display"]

    print("[Floor3-Hex] Entered room: %s" % display_name)

    # Show room name
    _show_notification("Entered: %s" % display_name, room["color"], 2.0)

    # Trigger encounter if not cleared
    if not room.get("cleared", false) and room["encounter"] != "none":
        _try_ambush_at_hex(room["hex"])

func _check_enemy_sight():
    if not player_node:
        return
    var player_hex = hex_map.world_to_hex(player_node.global_position)

    for enemy in hex_enemies:
        if not is_instance_valid(enemy) or enemy.state == HexEnemy.State.IN_COMBAT:
            continue

        var dist = HexTileMap._hex_distance(player_hex, enemy.hex_pos)
        if dist <= enemy.view_range and enemy.state == HexEnemy.State.UNAWARE:
            enemy.state = HexEnemy.State.ALERT
            print("[Floor3-Hex] Enemy alerted: %s" % enemy.enemy_name)

func _try_ambush_at_hex(hex: Vector2i) -> bool:
    for enemy in hex_enemies:
        if not is_instance_valid(enemy):
            continue
        if enemy.hex_pos == hex or HexTileMap._hex_distance(hex, enemy.hex_pos) <= 1:
            if enemy.state == HexEnemy.State.IN_COMBAT:
                continue

            var ambush = (enemy.state == HexEnemy.State.UNAWARE)
            enemy.state = HexEnemy.State.IN_COMBAT
            _start_combat(room_data[current_room_id]["encounter"], current_room_id)
            return true
    return false

# ===================================================================
# MOVEMENT
# ===================================================================

func _input(event: InputEvent):
    if in_combat or in_ui or is_paused:
        return

    # WASD movement
    if event is InputEventKey and event.pressed:
        var move_vec = Vector2.ZERO
        if event.keycode == KEY_W: move_vec = Vector2(0, -1)
        elif event.keycode == KEY_S: move_vec = Vector2(0, 1)
        elif event.keycode == KEY_A: move_vec = Vector2(-1, 0)
        elif event.keycode == KEY_D: move_vec = Vector2(1, 0)
        elif event.keycode == KEY_E: _interact()
        elif event.keycode == KEY_R: _rotate_dial()
        elif event.keycode == KEY_ESCAPE: _toggle_pause_menu()

        if move_vec != Vector2.ZERO:
            _hex_move(move_vec)
            get_viewport().set_input_as_handled()

    # Mouse click-to-move
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if hex_map:
            var click_pos = get_global_mouse_position()
            var click_hex = hex_map.world_to_hex(click_pos)
            var player_hex = hex_map.world_to_hex(player_node.global_position)
            var path = hex_map.find_path(player_hex, click_hex)
            if path.size() > 0:
                path_movement_target = path
                path_movement_index = 0
                path_movement_active = true

func _hex_move(move_vec: Vector2):
    if not player_node:
        return
    var current_hex = hex_map.world_to_hex(player_node.global_position)
    var direction = _vector_to_hex_dir(move_vec)
    var dirs = HexTileMap.DIRECTIONS
    var target_hex = current_hex + dirs[direction]

    if not hex_map.is_walkable(target_hex):
        return

    if _try_ambush_at_hex(target_hex):
        return

    player_node.global_position = hex_map.hex_to_world(target_hex)

    var animator = player_node.get_node_or_null("PlayerAnimator")
    if animator and animator.has_method("play_walk"):
        animator.play_walk(direction)

func _vector_to_hex_dir(move_vec: Vector2) -> int:
    var angle = atan2(move_vec.y, move_vec.x)
    var degrees = rad_to_deg(angle)
    if degrees < 0: degrees += 360

    if degrees >= 330 or degrees < 30: return 3    # E
    if degrees >= 30 and degrees < 90: return 1     # NE
    if degrees >= 90 and degrees < 150: return 0    # NW
    if degrees >= 150 and degrees < 210: return 2    # W
    if degrees >= 210 and degrees < 270: return 4    # SW
    if degrees >= 270 and degrees < 330: return 5    # SE
    return 3

func _step_path():
    if path_movement_index >= path_movement_target.size():
        path_movement_active = false
        return

    var next_hex = path_movement_target[path_movement_index]
    if not hex_map.is_walkable(next_hex):
        path_movement_active = false
        return

    if _try_ambush_at_hex(next_hex):
        path_movement_active = false
        return

    player_node.global_position = hex_map.hex_to_world(next_hex)
    path_movement_index += 1

    var animator = player_node.get_node_or_null("PlayerAnimator")
    if animator and animator.has_method("play_walk"):
        var current_hex = hex_map.world_to_hex(player_node.global_position)
        var dir_idx = _vector_to_hex_dir(Vector2(next_hex.x - current_hex.x, next_hex.y - current_hex.y))
        animator.play_walk(dir_idx)

# ===================================================================
# INTERACTION
# ===================================================================

func _interact():
    var player_hex = hex_map.world_to_hex(player_node.global_position)

    # Check if near Crown Cog (center)
    if HexTileMap._hex_distance(player_hex, crown_cog_hex) <= 2:
        _open_machinist_shop()
        return

    # Check if near light beam widget
    for widget in light_beam_widgets:
        var widget_hex = widget["hex"]
        if HexTileMap._hex_distance(player_hex, widget_hex) <= 1:
            _activate_widget(widget)
            return

    # Check if in a room with an encounter
    if room_data.has(current_room_id):
        var room = room_data[current_room_id]
        if not room.get("cleared", false) and room["encounter"] != "none":
            _start_combat(room["encounter"], current_room_id)
            return

    _show_notification("Nothing to interact with here.", Color(0.7, 0.7, 0.7), 2.0)

# ===================================================================
# LIGHT BEAM PUZZLE
# ===================================================================

func _setup_light_beam_puzzle():
    """Create 11 light beam widgets around the ring pointing to center."""
    for i in range(11):  # 11 widgets (excluding Room 12 which is at top)
        var room_id = i + 1
        var room_hex = room_data[str(room_id)]["hex"]
        var widget_hex = room_hex + Vector2i(0, 2)  # Offset toward center

        light_beam_widgets.append({
            "id": room_id,
            "hex": widget_hex,
            "aligned": false,
            "room_id": str(room_id)
        })

    print("[Floor3-Hex] Light beam puzzle: %d widgets" % light_beam_widgets.size())

func _activate_widget(widget: Dictionary):
    """Player interacts with a light beam widget."""
    AudioManager.play_sfx("click")
    widget["aligned"] = !widget["aligned"]

    var aligned_count = 0
    for w in light_beam_widgets:
        if w["aligned"]:
            aligned_count += 1

    _show_notification("Widget %d %s! (%d/11 aligned)" % [
        widget["id"],
        "aligned" if widget["aligned"] else "misaligned",
        aligned_count
    ], Color(0.9, 0.9, 0.3), 2.0)

    if aligned_count >= 11:
        _light_beam_complete()

func _light_beam_complete():
    _show_notification("🌟 ALL WIDGETS ALIGNED! Light beam opens the Crown Cog!", Color(0.9, 0.9, 0.3), 4.0)
    # Unlock center portal
    room_data["center"] = {
        "hex": crown_cog_hex,
        "radius": 3,
        "encounter": "none",
        "display": "Crown Cog"
    }

# ===================================================================
# MACHINIST SHOP
# ===================================================================

func _setup_machinist_shop():
    shop_ui = Control.new()
    shop_ui.name = "ShopUI"
    shop_ui.visible = false
    shop_ui.z_index = 200
    shop_ui.size = Vector2(600, 400)
    shop_ui.position = Vector2(340, 160)
    add_child(shop_ui)
    
    # Shop title
    var title = Label.new()
    title.text = "🔧 Machinist's Shop"
    title.add_theme_font_size_override("font_size", 28)
    title.position = Vector2(150, 20)
    shop_ui.add_child(title)
    
    # Gold display (uses gems)
    var gems_label = Label.new()
    gems_label.name = "GoldLabel"
    gems_label.text = "Gems: %d💎" % GameState.gems
    gems_label.add_theme_font_size_override("font_size", 18)
    gems_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
    gems_label.position = Vector2(420, 30)
    shop_ui.add_child(gems_label)
    
    # Shop stock items - all valid cards from CardDB
    var shop_items = [
        {"card_id": "Construct_efficient_block", "cost": 8, "name": "Efficient Block", "desc": "1-cost: Block 3, Draw 1"},
        {"card_id": "Construct_gear_shield", "cost": 10, "name": "Gear Shield", "desc": "1-cost: Block 4, Trap 1 dmg when attacked"},
        {"card_id": "Construct_clockwork_tick", "cost": 12, "name": "Clockwork Tick", "desc": "2-cost: Summon 2 ticks that deal 1 dmg each turn"},
        {"card_id": "Construct_overclock", "cost": 15, "name": "Overclock", "desc": "2-cost: Next attack +50% damage"},
        {"card_id": "Construct_torque_strike", "cost": 12, "name": "Torque Strike", "desc": "2-cost: Deal 4-6 damage, ignore 2 shield"},
        {"card_id": "Construct_precision_bolt", "cost": 10, "name": "Precision Bolt", "desc": "1-cost: Deal 3 damage, +1 if target has shield"},
        {"card_id": "Construct_turret_deployment", "cost": 15, "name": "Turret Deploy", "desc": "2-cost: Summon turret (2 atk, 8 hp)"},
        {"card_id": "Construct_assembly_drone", "cost": 18, "name": "Assembly Drone", "desc": "3-cost: Summon drone (3 atk, 10 hp)"},
        {"card_id": "Universal_fortify", "cost": 10, "name": "Fortify", "desc": "2-cost: Gain 5 shield"},
        {"card_id": "Universal_cleanse", "cost": 10, "name": "Cleanse", "desc": "2-cost: Heal 3, remove debuffs"},
    ]
    
    for i in range(shop_items.size()):
        var item = shop_items[i]
        var row = i / 2
        var col = i % 2
        var x = 30 + col * 280
        var y = 80 + row * 70
        
        var btn = Button.new()
        btn.name = "ShopItem_%d" % i
        btn.text = "%s\n%d Gold" % [item["name"], item["cost"]]
        btn.position = Vector2(x, y)
        btn.size = Vector2(260, 60)
        btn.add_theme_font_size_override("font_size", 14)
        
        # Store item data in button metadata
        btn.set_meta("item_data", item)
        
        btn.pressed.connect(func(): _buy_shop_item(item, gems_label))
        shop_ui.add_child(btn)
    
    # Close button
    var close_btn = Button.new()
    close_btn.text = "Close [ESC]"
    close_btn.position = Vector2(230, 350)
    close_btn.size = Vector2(140, 40)
    close_btn.pressed.connect(_close_machinist_shop)
    shop_ui.add_child(close_btn)
    
    # Background panel
    var bg = ColorRect.new()
    bg.color = Color(0.1, 0.1, 0.15, 0.95)
    bg.size = Vector2(600, 400)
    bg.position = Vector2(0, 0)
    shop_ui.move_child(bg, 0)

func _buy_shop_item(item: Dictionary, gems_label: Label):
    var gems = GameState.gems
    if gems < item["cost"]:
        _show_notification("Not enough gems! Need %d💎" % item["cost"], Color(0.9, 0.3, 0.3), 2.0)
        return
    
    # Deduct gems
    GameState.gems -= item["cost"]
    gems_label.text = "Gems: %d💎" % GameState.gems
    
    # Add card to deck
    var card = CardDB.get_card(item["card_id"])
    if card:
        GameState.player_deck.append(card)
        AudioManager.play_sfx("buy_item")
        _show_notification("Purchased: %s!" % item["name"], Color(0.3, 0.9, 0.3), 2.0)
    else:
        _show_notification("Card not found: %s" % item["card_id"], Color(0.9, 0.3, 0.3), 2.0)

func _open_machinist_shop():
    in_shop = true
    in_ui = true
    shop_ui.visible = true
    
    # Update gems display
    var gems_label = shop_ui.get_node_or_null("GoldLabel")
    if gems_label:
        gems_label.text = "Gems: %d💎" % GameState.gems
    
    _show_notification("🔧 Machinist Shop: Buy gear upgrades!", Color(0.3, 0.9, 0.3), 3.0)

func _close_machinist_shop():
    in_shop = false
    in_ui = false
    shop_ui.visible = false


# ===================================================================
# UI
# ===================================================================

func _setup_ui():
    interact_prompt = Label.new()
    interact_prompt.name = "InteractPrompt"
    interact_prompt.text = "[E] Interact"
    interact_prompt.position = Vector2(600, 650)
    interact_prompt.add_theme_font_size_override("font_size", 18)
    add_child(interact_prompt)
    interact_prompt.visible = false

func _show_interact_prompt(text: String = "[E] Interact"):
    if interact_prompt:
        interact_prompt.text = text
        interact_prompt.visible = true

func _hide_interact_prompt():
    if interact_prompt:
        interact_prompt.visible = false

func _toggle_pause_menu():
    is_paused = !is_paused
    if pause_menu:
        pause_menu.visible = is_paused
    get_tree().paused = is_paused

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.9), duration: float = 3.0):
    var label = Label.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", 20)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(640, 360)
    label.size = Vector2(600, 40)
    add_child(label)

    await get_tree().create_timer(duration).timeout
    label.queue_free()

# ===================================================================
# FLOOR COMPLETE
# ===================================================================

func _floor_complete():
    _show_notification("⚙ Floor 3 Complete! The Gearworks are subdued!", Color(0.3, 0.9, 0.3), 4.0)
    GameState.mark_floor_complete(3)
    await get_tree().create_timer(2.0).timeout

    # Save and offer continue
    GameState.save_game()
    _show_floor_transition_prompt()

func _show_floor_transition_prompt():
    var prompt = Label.new()
    prompt.name = "FloorTransitionPrompt"
    prompt.text = "Press [S] to Ascend to Floor 4 — The Curio Bazaar"
    prompt.position = Vector2(640, 600)
    prompt.size = Vector2(600, 40)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 20)
    prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
    add_child(prompt)
