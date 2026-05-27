extends Node2D
class_name RoomPuzzle

# Base class for Floor 3 room puzzles
# Each room has a puzzle that must be solved to activate its light emitter
# Puzzles also contain a hidden Gear Devil Token and optionally a Kami Shrine

signal puzzle_solved(room_id: int)
signal token_found(room_id: int)
signal combat_triggered(room_id: int, enemies: Array)

enum PuzzleState { LOCKED, ACTIVE, SOLVED, FAILED }

var room_id: int = 0
var room_name: String = ""
var state: PuzzleState = PuzzleState.LOCKED

# Puzzle metadata (set by subclasses)
var puzzle_name: String = ""
var puzzle_description: String = ""

# Puzzle components
var light_emitter: Node2D  # The widget/emitter that shoots toward center
var gear_devil_token: Node2D  # Hidden token, one per room
var kami_shrine: KamiShrine  # Optional shrine for offerings
var token_collected: bool = false

# Interaction tracking
var interactables: Array[Node2D] = []  # Objects player can interact with (E key)
var active_interactable: Node2D = null

# Player position (updated by Floor3Controller)
var player_position: Vector2 = Vector2.ZERO

# Visual feedback
var interact_label: Label
const INTERACT_DISTANCE: float = 60.0

func _ready():
	_setup_visuals()
	_setup_interactables()
	_setup_token()
	_setup_shrine()
	_setup_emitter()

func initialize():
	"""Called by Floor3Controller after adding to scene. Override in subclass."""
	state = PuzzleState.ACTIVE

func activate_puzzle():
	"""Called when player enters the room. Override in subclass."""
	state = PuzzleState.ACTIVE

func _on_interact(obj: Node2D):
	"""Override in subclass to handle specific interactable objects."""
	pass

func _play_sound(sound_name: String):
	"""Play a sound effect via AudioManager. Falls back to print if not found."""
	var audio_mgr = get_audio_manager()
	if audio_mgr:
		audio_mgr.play_sfx(sound_name)
	else:
		print("RoomPuzzle sound: %s (no AudioManager)" % sound_name)

func get_audio_manager() -> AudioManager:
	"""Find the AudioManager in the scene tree."""
	# Try to find AudioManager anywhere in the tree
	var root = get_tree().root
	for child in root.get_children():
		var found = _find_audio_manager(child)
		if found:
			return found
	return null

func _find_audio_manager(node: Node) -> AudioManager:
	if node is AudioManager:
		return node
	for child in node.get_children():
		var found = _find_audio_manager(child)
		if found:
			return found
	return null

func _spawn_token(position: Vector2 = Vector2.ZERO) -> Node2D:
	"""Spawn a visual token at the given position. Override in subclass."""
	var token = Node2D.new()
	token.position = position
	return token

func _on_token_collected():
	"""Called when the Gear Devil Token is collected."""
	collect_token()

func _setup_visuals():
	"""Override in subclass for room-specific visuals"""
	pass

func _setup_interactables():
	"""Override in subclass to create interactive puzzle objects"""
	pass

func _setup_token():
	"""Create hidden Gear Devil Token for this room"""
	gear_devil_token = Node2D.new()
	gear_devil_token.name = "GearDevilToken"
	
	# Token sprite (placeholder - PixelLab: gear_devil_token_32x32.png)
	var sprite = Sprite2D.new()
	var tex_path = "res://assets/sprites/items/gear_devil_token.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		# Fallback: golden gear shape
		var poly = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 6:
			var a = (TAU / 6.0) * i
			pts.append(Vector2(cos(a) * 12, sin(a) * 12))
		poly.polygon = pts
		poly.color = Color(0.9, 0.8, 0.3)
		gear_devil_token.add_child(poly)
		
	gear_devil_token.add_child(sprite)
	add_child(gear_devil_token)
	
	# Token starts hidden/inaccessible
	gear_devil_token.visible = false
	gear_devil_token.process_mode = Node.PROCESS_MODE_DISABLED

func _setup_shrine():
	"""Override in subclass if room has a Kami Shrine"""
	pass

func _create_shrine_from_db(kami_id: String, position: Vector2 = Vector2(0, 0)) -> KamiShrine:
	"""Helper to create a KamiShrine from GameState database"""
	var shrine = KamiShrine.new()
	var kami_data = GameState.get_kami_data(kami_id)
	
	if kami_data.is_empty():
		push_warning("RoomPuzzle: No kami data found for %s" % kami_id)
		return shrine
	
	shrine.shrine_name = kami_data.get("name", "Unknown Kami")
	var pref = kami_data.get("preferred", [])
	shrine.preferred_offerings.assign(pref)
	shrine.accepts_any = kami_data.get("accepts_any", false)
	shrine.minor_boon = kami_data.get("minor_boon", "")
	shrine.major_boon = kami_data.get("major_boon", "")
	shrine.epic_boon = kami_data.get("epic_boon", "")
	shrine.sprite_path = kami_data.get("sprite", "")
	shrine.position = position
	
	return shrine

func _load_sprite_or_fallback(parent: Node, sprite_path: String, fallback_color: Color, fallback_size: float = 12.0) -> Sprite2D:
	"""Try to load a sprite, fall back to procedural shape if missing"""
	var sprite = Sprite2D.new()
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		sprite.scale = Vector2(1.0, 1.0)
		print("RoomPuzzle: Loaded sprite %s" % sprite_path)
	else:
		# Fallback: simple colored polygon
		var poly = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 6:
			var a = (TAU / 6.0) * i
			pts.append(Vector2(cos(a) * fallback_size, sin(a) * fallback_size))
		poly.polygon = pts
		poly.color = fallback_color
		parent.add_child(poly)
		print("WARNING: Missing sprite %s, using fallback" % sprite_path)
	parent.add_child(sprite)
	return sprite

func _setup_emitter():
	"""Create the light emitter widget"""
	light_emitter = Node2D.new()
	light_emitter.name = "LightEmitter"
	
	# Emitter sprite (placeholder - PixelLab: light_emitter_32x32.png)
	var sprite = Sprite2D.new()
	var tex_path = "res://assets/sprites/puzzles/light_emitter.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(0, -15), Vector2(10, 5), Vector2(0, 0), Vector2(-10, 5)
		])
		poly.color = Color(0.8, 0.9, 0.3)
		light_emitter.add_child(poly)
	
	light_emitter.add_child(sprite)
	light_emitter.visible = false  # Hidden until puzzle solved
	add_child(light_emitter)

# --- Interaction System ---

func update_player_position(player_world_pos: Vector2):
	"""Called by Floor3Controller when player moves in this room"""
	player_position = player_world_pos
	_find_nearest_interactable(player_world_pos)
	_update_interact_label()

func _find_nearest_interactable(player_pos: Vector2):
	var nearest: Node2D = null
	var nearest_dist: float = INTERACT_DISTANCE
	
	for obj in interactables:
		var d = player_pos.distance_to(obj.global_position)
		if d < nearest_dist:
			nearest = obj
			nearest_dist = d
	
	active_interactable = nearest

func _update_interact_label():
	if not interact_label:
		interact_label = Label.new()
		interact_label.text = "[E] Interact"
		interact_label.add_theme_font_size_override("font_size", 10)
		interact_label.modulate = Color(1.0, 1.0, 0.8)
		add_child(interact_label)
	
	if active_interactable:
		interact_label.visible = true
		interact_label.global_position = active_interactable.global_position + Vector2(-30, -40)
		interact_label.text = "[E] " + _get_interact_prompt(active_interactable)
	else:
		interact_label.visible = false

func _get_interact_prompt(obj: Node2D) -> String:
	"""Override to return context-specific prompts"""
	return "Interact"

func try_interact() -> bool:
	"""Returns true if interaction was handled"""
	if not active_interactable:
		return false
	
	_process_interaction(active_interactable)
	return true

func _process_interaction(obj: Node2D):
	"""Override in subclass to handle specific interactable objects"""
	pass

# --- Token Collection ---

func reveal_token():
	"""Make the Gear Devil Token accessible"""
	if token_collected:
		return
	gear_devil_token.visible = true
	gear_devil_token.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Add to interactables
	interactables.append(gear_devil_token)
	
	# Visual sparkle
	var tween = create_tween()
	gear_devil_token.scale = Vector2.ZERO
	tween.tween_property(gear_devil_token, "scale", Vector2(1.0, 1.0), 0.3)
	
	print("RoomPuzzle: Gear Devil Token revealed in %s" % room_name)

func collect_token() -> bool:
	"""Returns true if token was collected"""
	if token_collected or not gear_devil_token.visible:
		return false
	
	token_collected = true
	GameState.add_gear_devil_token(room_id)
	
	# Remove from interactables
	interactables.erase(gear_devil_token)
	
	# Visual collection effect
	var tween = create_tween()
	tween.tween_property(gear_devil_token, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func():
		gear_devil_token.visible = false
		token_found.emit(room_id)
	)
	
	print("RoomPuzzle: Gear Devil Token collected from %s" % room_name)
	return true

# --- Puzzle Completion ---

func solve_puzzle():
	"""Call when puzzle conditions are met"""
	if state == PuzzleState.SOLVED:
		return
	
	state = PuzzleState.SOLVED
	
	# Activate light emitter
	light_emitter.visible = true
	_show_emitter_activation()
	
	# Reveal token
	reveal_token()
	
	puzzle_solved.emit(room_id)
	print("RoomPuzzle: %s puzzle SOLVED!" % room_name)

func _show_emitter_activation():
	"""Visual effect when emitter activates"""
	var tween = create_tween()
	light_emitter.modulate = Color(0.5, 0.5, 0.5)
	tween.tween_property(light_emitter, "modulate", Color(1.0, 1.0, 1.0), 0.5)
	
	# Beam flash
	var beam = Line2D.new()
	beam.width = 3
	beam.default_color = Color(1.0, 0.9, 0.3, 0.8)
	beam.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -80)])
	add_child(beam)
	
	var beam_tween = create_tween()
	beam_tween.tween_property(beam, "default_color:a", 0.0, 1.0)
	beam_tween.tween_callback(beam.queue_free)

# --- Combat Integration ---

func trigger_combat(enemies: Array[CombatManager.EnemyData]):
	"""Call when puzzle should transition to combat (e.g., trap triggered, ambush)"""
	combat_triggered.emit(room_id, enemies)

# --- Save/Load ---

func get_save_data() -> Dictionary:
	return {
		"room_id": room_id,
		"state": state,
		"token_collected": token_collected,
		"shrine_state": kami_shrine.get_save_data() if kami_shrine else {}
	}

func load_save_data(data: Dictionary):
	state = data.get("state", PuzzleState.LOCKED)
	token_collected = data.get("token_collected", false)
	if token_collected:
		gear_devil_token.visible = false
		gear_devil_token.process_mode = Node.PROCESS_MODE_DISABLED
	if kami_shrine and data.has("shrine_state"):
		kami_shrine.load_save_data(data["shrine_state"])
	if state == PuzzleState.SOLVED:
		light_emitter.visible = true
		reveal_token()
