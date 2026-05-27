extends RoomPuzzle
class_name BeaconPuzzle

# The Beacon - Room 6
# Puzzle: Activate lift to reach the peak where the light crystal waits
# Mechanic: 3 gear levers on platforms must all be engaged to power the lift.
#   Once powered, call lift from bottom, ride to top platform.
#   Interact with light crystal at peak to activate emitter.
# Token: Hidden in a crack on Platform 2 — visible only when player is on Platform 3 looking down
# Shrine: Light Kami — prefers Phosphor Crystal, Polished Brass

enum LiftState { BROKEN, POWERED, MOVING_UP, AT_TOP, MOVING_DOWN }

# Platforms
var platforms: Array[Node2D] = []
const PLATFORM_Y: Array[float] = [60.0, 25.0, -15.0, -55.0, -95.0]
const PLATFORM_NAMES: Array[String] = ["Ground", "Lower", "Middle", "Upper", "Peak"]

# Gear levers (on platforms 1, 2, 3)
var gear_levers: Array[Node2D] = []
var lever_engaged: Array[bool] = [false, false, false]

# Lift
var lift_cage: Node2D
var lift_state: LiftState = LiftState.BROKEN
var lift_target_y: float = 60.0
const LIFT_SPEED: float = 40.0

# Light crystal (at peak)
var light_crystal: Node2D

# Token visibility
var token_platform: int = 2  # Token hidden on platform 2
var token_visible_from: int = 3  # Only visible when on platform 3+

# Visual
var status_label: Label

func _ready():
	room_id = 6
	room_name = "The Beacon"
	super._ready()

func _setup_visuals():
	# Create 5 platforms
	for i in 5:
		var plat = _create_platform(i)
		plat.position = Vector2(0, PLATFORM_Y[i])
		platforms.append(plat)
		add_child(plat)
	
	# Lift cage (starts at ground)
	lift_cage = _create_lift_cage()
	lift_cage.position = Vector2(0, PLATFORM_Y[0] - 15)
	add_child(lift_cage)
	
	# Light crystal at peak
	light_crystal = _create_light_crystal()
	light_crystal.position = Vector2(0, PLATFORM_Y[4] - 20)
	add_child(light_crystal)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Lift: BROKEN | Engage 3 gear levers to power it"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-150, -130)
	status_label.size = Vector2(300, 24)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color(0.9, 0.9, 0.7)
	add_child(status_label)

func _create_platform(index: int) -> Node2D:
	var plat = Node2D.new()
	plat.name = "Platform_%s" % PLATFORM_NAMES[index]
	
	# Platform sprite
	var sprite = Sprite2D.new()
	var sprite_path = "res://assets/sprites/puzzles/puzzle_beacon_platform.png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		sprite.scale = Vector2(0.6, 0.4)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-50, 5), Vector2(50, 5),
			Vector2(50, -5), Vector2(-50, -5)
		])
		poly.color = Color(0.5, 0.45, 0.35) if index < 4 else Color(0.7, 0.65, 0.4)
		plat.add_child(poly)
	plat.add_child(sprite)
	
	# Warning stripes on edges (platforms 1-3)
	if index > 0 and index < 4:
		var stripe = Line2D.new()
		stripe.points = PackedVector2Array([Vector2(-45, 6), Vector2(45, 6)])
		stripe.width = 2
		stripe.default_color = Color(0.8, 0.7, 0.2)
		plat.add_child(stripe)
	
	return plat

func _create_lift_cage() -> Node2D:
	var cage = Node2D.new()
	cage.name = "LiftCage"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_beacon_lift.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_beacon_lift.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-20, -20), Vector2(20, -20),
			Vector2(20, 20), Vector2(-20, 20)
		])
		poly.color = Color(0.6, 0.6, 0.65)
		cage.add_child(poly)
	cage.add_child(sprite)
	
	# Control panel indicator
	var panel = Polygon2D.new()
	panel.name = "ControlPanel"
	panel.polygon = PackedVector2Array([
		Vector2(-8, -18), Vector2(8, -18),
		Vector2(8, -10), Vector2(-8, -10)
	])
	panel.color = Color(0.3, 0.3, 0.3)  # Off = grey
	cage.add_child(panel)
	
	return cage

func _create_light_crystal() -> Node2D:
	var crystal = Node2D.new()
	crystal.name = "LightCrystal"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_beacon_peak.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_beacon_peak.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-10, 10), Vector2(10, 10),
			Vector2(0, -15)
		])
		poly.color = Color(0.8, 0.9, 1.0, 0.8)
		crystal.add_child(poly)
	crystal.add_child(sprite)
	
	# Crystal glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-15, 15), Vector2(15, 15),
		Vector2(0, -20)
	])
	glow.color = Color(0.7, 0.85, 1.0, 0.15)
	glow.scale = Vector2(1.5, 1.5)
	crystal.add_child(glow)
	
	return crystal

func _setup_interactables():
	# Gear levers on platforms 1, 2, 3
	for i in 3:
		var lever = _create_gear_lever(i)
		lever.position = Vector2(-30 if i % 2 == 0 else 30, PLATFORM_Y[i + 1] - 15)
		gear_levers.append(lever)
		interactables.append(lever)
		add_child(lever)
	
	# Lift cage (interact when powered)
	interactables.append(lift_cage)
	
	# Light crystal at peak
	interactables.append(light_crystal)

func _create_gear_lever(index: int) -> Node2D:
	var lever = Node2D.new()
	lever.name = "GearLever_%d" % index
	lever.set_meta("type", "gear_lever")
	lever.set_meta("index", index)
	
	# Lever base
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(6, 6), Vector2(-6, 6)
	])
	base.color = Color(0.5, 0.5, 0.55)
	lever.add_child(base)
	
	# Lever handle
	var handle = Line2D.new()
	handle.name = "Handle"
	handle.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -14)])
	handle.width = 3
	handle.default_color = Color(0.7, 0.5, 0.3)
	lever.add_child(handle)
	
	# Status dot
	var dot = Polygon2D.new()
	dot.name = "StatusDot"
	dot.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3),
		Vector2(3, 3), Vector2(-3, 3)
	])
	dot.color = Color(0.3, 0.3, 0.3)
	dot.position = Vector2(0, -20)
	lever.add_child(dot)
	
	return lever

func _setup_shrine():
	# Light Kami - prefers light/heat offerings
	kami_shrine = _create_shrine_from_db("light_kami", Vector2(-50, PLATFORM_Y[0] - 30))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	# Move lift if needed
	match lift_state:
		LiftState.MOVING_UP:
			lift_cage.position.y -= LIFT_SPEED * delta
			if lift_cage.position.y <= PLATFORM_Y[4] - 15:
				lift_cage.position.y = PLATFORM_Y[4] - 15
				lift_state = LiftState.AT_TOP
				_update_status("Lift: AT PEAK")
				_play_sound("lift_arrive")
		LiftState.MOVING_DOWN:
			lift_cage.position.y += LIFT_SPEED * delta
			if lift_cage.position.y >= PLATFORM_Y[0] - 15:
				lift_cage.position.y = PLATFORM_Y[0] - 15
				lift_state = LiftState.POWERED
				_update_status("Lift: READY")
	
	# Update lift control panel color
	var panel = lift_cage.get_node("ControlPanel")
	match lift_state:
		LiftState.BROKEN:
			panel.color = Color(0.3, 0.3, 0.3)
		LiftState.POWERED, LiftState.AT_TOP:
			panel.color = Color(0.2, 0.8, 0.3)
		LiftState.MOVING_UP, LiftState.MOVING_DOWN:
			panel.color = Color(0.8, 0.8, 0.2)

func _engage_lever(index: int):
	if lever_engaged[index]:
		return
	
	lever_engaged[index] = true
	
	# Visual: handle rotates, dot turns green
	var lever = gear_levers[index]
	var handle = lever.get_node("Handle")
	var dot = lever.get_node("StatusDot")
	
	var tween = create_tween()
	tween.tween_property(handle, "rotation_degrees", 45.0, 0.3)
	dot.color = Color(0.2, 0.9, 0.3)
	
	_play_sound("lever_engage")
	
	# Check if all 3 engaged
	var all_engaged = lever_engaged[0] and lever_engaged[1] and lever_engaged[2]
	if all_engaged and lift_state == LiftState.BROKEN:
		lift_state = LiftState.POWERED
		_update_status("LIFT POWERED! All gears engaged. Call the lift.")
		
		# Visual feedback on lift
		var panel = lift_cage.get_node("ControlPanel")
		var tween2 = create_tween()
		tween2.tween_property(panel, "color", Color(0.2, 0.9, 0.3), 0.5)
	else:
		var count = lever_engaged.count(true)
		_update_status("Gear engaged! %d/3 levers active." % count)

func _call_lift():
	match lift_state:
		LiftState.POWERED:
			lift_state = LiftState.MOVING_UP
			_update_status("Lift ascending...")
			_play_sound("lift_move")
		LiftState.AT_TOP:
			lift_state = LiftState.MOVING_DOWN
			_update_status("Lift descending...")
			_play_sound("lift_move")
		LiftState.BROKEN:
			_update_status("Lift is broken. Engage all 3 gear levers first.")
		LiftState.MOVING_UP, LiftState.MOVING_DOWN:
			_update_status("Lift is moving. Wait...")

func _activate_crystal():
	if lift_state != LiftState.AT_TOP:
		_update_status("The crystal is too high. Take the lift to the peak.")
		return
	
	_update_status("CRYSTAL ACTIVATED! Light emitter active!")
	
	# Visual: crystal brightens
	var crystal_sprite = light_crystal.get_child(0)
	if crystal_sprite is Sprite2D:
		var tween = create_tween()
		tween.tween_property(crystal_sprite, "modulate", Color(1.5, 1.5, 2.0), 0.5)
	
	# Beam shoots up from crystal
	var beam = Line2D.new()
	beam.points = PackedVector2Array([Vector2(0, -20), Vector2(0, -80)])
	beam.width = 4
	beam.default_color = Color(0.9, 0.95, 1.0, 0.8)
	light_crystal.add_child(beam)
	
	var tween2 = create_tween()
	tween2.tween_property(beam, "width", 8, 0.3)
	
	# Emitter
	if light_emitter:
		light_emitter.visible = true
		var tween3 = create_tween()
		tween3.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The light crystal flares brilliantly! A beam shoots upward from the peak, activating the emitter.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -200)
	popup.size = Vector2(400, 50)
	popup.add_theme_font_size_override("font_size", 12)
	popup.modulate = Color(0.9, 0.9, 0.5)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 3.0)
	await tween.finished
	popup.queue_free()

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	var type = obj.get_meta("type", "")
	match type:
		"gear_lever":
			var idx = obj.get_meta("index", 0)
			if lever_engaged[idx]:
				return "[E] Gear Lever %d (ENGAGED)" % (idx + 1)
			return "[E] Engage Gear Lever %d" % (idx + 1)
		_:
			if obj == lift_cage:
				if lift_state == LiftState.BROKEN:
					return "[E] Lift Control (BROKEN)"
				return "[E] Call Lift"
			elif obj == light_crystal:
				return "[E] Activate Light Crystal"
			return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"gear_lever":
			_engage_lever(obj.get_meta("index", 0))
		_:
			if obj == lift_cage:
				_call_lift()
			elif obj == light_crystal:
				_activate_crystal()
			else:
				super._on_interact(obj)

# --- Token visibility logic ---

func _check_token_visibility(player_y: float):
	# Token on platform 2 is visible only when player is on platform 3+
	var player_platform = _get_player_platform(player_y)
	if player_platform >= token_visible_from:
		if gear_devil_token and not token_collected:
			gear_devil_token.visible = true
			gear_devil_token.position = Vector2(20, PLATFORM_Y[2] - 5)

func _get_player_platform(player_y: float) -> int:
	# Find which platform the player is closest to
	for i in 5:
		if abs(player_y - PLATFORM_Y[i]) < 15:
			return i
	return -1

func activate_puzzle():
	super.activate_puzzle()
	_update_status("Engage 3 gear levers to power the lift. Ride it to the peak.")

func _update_status(text: String):
	status_label.text = text

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["lever_engaged"] = lever_engaged
	data["lift_state"] = lift_state
	data["lift_y"] = lift_cage.position.y
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("lever_engaged"):
		lever_engaged = data["lever_engaged"]
		for i in 3:
			if i < gear_levers.size() and lever_engaged[i]:
				var lever = gear_levers[i]
				var handle = lever.get_node("Handle")
				handle.rotation_degrees = 45.0
				var dot = lever.get_node("StatusDot")
				dot.color = Color(0.2, 0.9, 0.3)
	
	if data.has("lift_state"):
		lift_state = data["lift_state"]
	if data.has("lift_y"):
		lift_cage.position.y = data["lift_y"]
	
	# Recalculate powered state
	var all_engaged = lever_engaged[0] and lever_engaged[1] and lever_engaged[2]
	if all_engaged and lift_state == LiftState.BROKEN:
		lift_state = LiftState.POWERED

func reset_puzzle():
	lift_state = LiftState.BROKEN
	lift_cage.position.y = PLATFORM_Y[0] - 15
	
	for i in 3:
		lever_engaged[i] = false
		if i < gear_levers.size():
			var lever = gear_levers[i]
			var handle = lever.get_node("Handle")
			handle.rotation_degrees = 0.0
			var dot = lever.get_node("StatusDot")
			dot.color = Color(0.3, 0.3, 0.3)
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	_update_status("Lift: BROKEN | Engage 3 gear levers to power it")
