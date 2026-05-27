extends RoomPuzzle
class_name BearingPuzzle

# The Bearing - Room 8
# Puzzle: Oil seized bearings so the housing can rotate to align the light emitter
# Mechanic: 8 ball bearings in a ring. 5 are seized (rusty). Pick up oil can, oil each
#   seized bearing. Once all 5 freed, the bearing housing auto-rotates to alignment.
#   Attempting to rotate before all freed = jam (shake, no progress).
# Token: Inside bearing housing — visible only after full rotation completes
# Shrine: Friction Kami - prefers Machine Oil, Polished Brass

enum BearingState { SEIZED, OILED, ROTATING, ALIGNED }

# Bearing housing ring
var housing_ring: Node2D
var ring_rotation: float = 0.0
const TARGET_ROTATION: float = PI / 4.0  # 45 degrees
const ROTATION_SPEED: float = 1.5

# Ball bearings (8 around ring)
var bearings: Array[Node2D] = []
var bearing_states: Array[int] = []
const BEARING_COUNT: int = 8
const SEIZED_COUNT: int = 5

# Oil can
var oil_can: Node2D
var has_oil_can: bool = false

# Alignment marker
var alignment_marker: Node2D

# Visual
var status_label: Label

func _ready():
	room_id = 8
	room_name = "The Bearing"
	bearing_states = _generate_seized_pattern()
	super._ready()

func _generate_seized_pattern() -> Array[int]:
	# Randomly choose 5 of 8 to be seized
	var pattern: Array[int] = []
	for i in BEARING_COUNT:
		pattern.append(BearingState.OILED if i < 3 else BearingState.SEIZED)
	pattern.shuffle()
	return pattern

func _setup_visuals():
	# Housing ring (center)
	housing_ring = _create_housing_ring()
	add_child(housing_ring)
	
	# Ball bearings arranged in ring
	for i in BEARING_COUNT:
		var angle = (TAU / BEARING_COUNT) * i
		var pos = Vector2(cos(angle) * 40, sin(angle) * 40)
		var bearing = _create_bearing(i)
		bearing.position = pos
		bearings.append(bearing)
		housing_ring.add_child(bearing)
	
	# Alignment marker (shows where ring needs to point)
	alignment_marker = _create_alignment_marker()
	alignment_marker.position = Vector2(cos(TARGET_ROTATION) * 55, sin(TARGET_ROTATION) * 55)
	add_child(alignment_marker)
	
	# Oil can (left side)
	oil_can = _create_oil_can()
	oil_can.position = Vector2(-70, 50)
	add_child(oil_can)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "5 bearings seized. Find oil can and lubricate them."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-150, -80)
	status_label.size = Vector2(300, 24)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color(0.8, 0.8, 0.85)
	add_child(status_label)

func _create_housing_ring() -> Node2D:
	var ring = Node2D.new()
	ring.name = "HousingRing"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_bearing_housing.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_bearing_housing.png")
		sprite.scale = Vector2(0.8, 0.8)
	else:
		var outer = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 32:
			var a = (TAU / 32.0) * i
			var r = 50.0 if i % 2 == 0 else 48.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		outer.polygon = pts
		outer.color = Color(0.45, 0.45, 0.5)
		ring.add_child(outer)
		
		var inner = Polygon2D.new()
		var inner_pts = PackedVector2Array()
		for i in 32:
			var a = (TAU / 32.0) * i
			var r = 30.0
			inner_pts.append(Vector2(cos(a) * r, sin(a) * r))
		inner.polygon = inner_pts
		inner.color = Color(0.25, 0.25, 0.3)
		ring.add_child(inner)
	ring.add_child(sprite)
	
	return ring

func _create_bearing(index: int) -> Node2D:
	var b = Node2D.new()
	b.name = "Bearing_%d" % index
	b.set_meta("type", "bearing")
	b.set_meta("index", index)
	
	var sprite = Sprite2D.new()
	# Use different sprites for seized vs oiled? For now, color tint
	sprite.scale = Vector2(0.4, 0.4)
	b.add_child(sprite)
	
	# State indicator
	var indicator = Polygon2D.new()
	indicator.name = "StateIndicator"
	indicator.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(4, 4), Vector2(-4, 4)
	])
	indicator.position = Vector2(0, -10)
	b.add_child(indicator)
	
	_update_bearing_visual(index)
	
	return b

func _update_bearing_visual(index: int):
	if index >= bearings.size():
		return
	var b = bearings[index]
	var indicator = b.get_node("StateIndicator")
	var sprite = b.get_child(0)
	
	match bearing_states[index]:
		BearingState.SEIZED:
			indicator.color = Color(0.8, 0.3, 0.1)  # Red = seized
			if sprite is Sprite2D:
				sprite.modulate = Color(0.7, 0.4, 0.3)  # Rust tint
		BearingState.OILED:
			indicator.color = Color(0.2, 0.8, 0.3)  # Green = good
			if sprite is Sprite2D:
				sprite.modulate = Color(1.0, 1.0, 1.0)  # Normal

func _create_alignment_marker() -> Node2D:
	var marker = Node2D.new()
	marker.name = "AlignmentMarker"
	
	var arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0),
		Vector2(0, -12)
	])
	arrow.color = Color(0.3, 0.9, 0.3, 0.5)
	marker.add_child(arrow)
	
	# Pulse animation
	var tween = create_tween().set_loops()
	tween.tween_property(arrow, "scale", Vector2(1.3, 1.3), 0.5)
	tween.tween_property(arrow, "scale", Vector2(1.0, 1.0), 0.5)
	
	return marker

func _create_oil_can() -> Node2D:
	var can = Node2D.new()
	can.name = "OilCan"
	can.set_meta("type", "oil_can")
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_bearing_oilcan.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_bearing_oilcan.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-8, -10), Vector2(8, -10),
			Vector2(6, 10), Vector2(-6, 10)
		])
		poly.color = Color(0.6, 0.6, 0.5)
		can.add_child(poly)
	can.add_child(sprite)
	
	return can

func _setup_interactables():
	# Oil can
	interactables.append(oil_can)
	
	# Bearings
	for b in bearings:
		interactables.append(b)
	
	# Housing ring (inspect/rotate attempt)
	interactables.append(housing_ring)

func _setup_shrine():
	# Friction Kami - prefers oil
	kami_shrine = _create_shrine_from_db("friction_kami", Vector2(-60, -50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	# Check if all bearings oiled → start rotation
	var all_oiled = true
	for state in bearing_states:
		if state == BearingState.SEIZED:
			all_oiled = false
			break
	
	if all_oiled and housing_ring.rotation != TARGET_ROTATION:
		# Auto-rotate to alignment
		var diff = TARGET_ROTATION - housing_ring.rotation
		# Shortest path
		while diff > PI:
			diff -= TAU
		while diff < -PI:
			diff += TAU
		
		if abs(diff) > 0.01:
			housing_ring.rotation += sign(diff) * ROTATION_SPEED * delta
		else:
			housing_ring.rotation = TARGET_ROTATION
			_solve_puzzle()

func _oil_bearing(index: int):
	if not has_oil_can:
		_update_status("Need oil can! Pick it up first.")
		return
	
	if bearing_states[index] != BearingState.SEIZED:
		_update_status("This bearing is already lubricated.")
		return
	
	# Oil it!
	bearing_states[index] = BearingState.OILED
	_update_bearing_visual(index)
	
	# Visual feedback
	var b = bearings[index]
	var tween = create_tween()
	tween.tween_property(b, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
	
	var oiled_count = bearing_states.count(BearingState.OILED)
	var seized_count = bearing_states.count(BearingState.SEIZED)
	_update_status("Bearing oiled! %d seized remaining." % seized_count)
	
	_play_sound("oil_bearing")
	
	# Check if all done
	if seized_count == 0:
		_update_status("All bearings lubricated! Housing rotating to alignment...")

func _pickup_oil_can():
	if has_oil_can:
		return
	
	has_oil_can = true
	oil_can.visible = false
	
	_update_status("Oil can acquired! Click on seized bearings (red) to lubricate them.")
	_play_sound("pickup")

func _try_rotate_housing():
	var seized_count = bearing_states.count(BearingState.SEIZED)
	if seized_count > 0:
		_update_status("Cannot rotate! %d bearings still seized. Oil them first." % seized_count)
		
		# Jam visual
		var tween = create_tween()
		tween.tween_property(housing_ring, "rotation", housing_ring.rotation + 0.1, 0.05)
		tween.tween_property(housing_ring, "rotation", housing_ring.rotation - 0.1, 0.05)
		tween.tween_property(housing_ring, "rotation", housing_ring.rotation, 0.05)
		
		_play_sound("jam")
	else:
		_update_status("All bearings free! Housing will auto-align.")

func _solve_puzzle():
	_update_status("BEARING ALIGNED! Light emitter active!")
	
	# Reveal token in housing center
	if gear_devil_token:
		gear_devil_token.visible = true
		gear_devil_token.position = Vector2(0, 0)
		gear_devil_token.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)
	
	# Emitter
	if light_emitter:
		light_emitter.visible = true
		var tween2 = create_tween()
		tween2.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The bearing spins freely, locking into perfect alignment! Light shoots through the precision-machined channel.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -200)
	popup.size = Vector2(400, 50)
	popup.add_theme_font_size_override("font_size", 12)
	popup.modulate = Color(0.5, 0.9, 0.7)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 3.0)
	await tween.finished
	popup.queue_free()

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	var type = obj.get_meta("type", "")
	match type:
		"oil_can":
			if has_oil_can:
				return ""
			return "[E] Pick Up Oil Can"
		"bearing":
			var idx = obj.get_meta("index", 0)
			if bearing_states[idx] == BearingState.SEIZED:
				if has_oil_can:
					return "[E] Oil Bearing %d" % (idx + 1)
				return "[E] Inspect Seized Bearing %d" % (idx + 1)
			return "[E] Bearing %d (Lubricated)" % (idx + 1)
		_:
			if obj == housing_ring:
				return "[E] Attempt Rotation"
			return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"oil_can":
			_pickup_oil_can()
		"bearing":
			_oil_bearing(obj.get_meta("index", 0))
		_:
			if obj == housing_ring:
				_try_rotate_housing()
			else:
				super._on_interact(obj)

func activate_puzzle():
	super.activate_puzzle()
	_update_status("5 bearings are seized (red). Pick up oil can, then oil each one.")

func _update_status(text: String):
	status_label.text = text

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["bearing_states"] = bearing_states
	data["has_oil_can"] = has_oil_can
	data["ring_rotation"] = housing_ring.rotation
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("bearing_states"):
		bearing_states = data["bearing_states"]
		for i in BEARING_COUNT:
			if i < bearings.size():
				_update_bearing_visual(i)
	
	if data.has("has_oil_can"):
		has_oil_can = data["has_oil_can"]
		if has_oil_can:
			oil_can.visible = false
	
	if data.has("ring_rotation"):
		housing_ring.rotation = data["ring_rotation"]

func reset_puzzle():
	bearing_states = _generate_seized_pattern()
	has_oil_can = false
	oil_can.visible = true
	housing_ring.rotation = 0.0
	
	for i in BEARING_COUNT:
		if i < bearings.size():
			_update_bearing_visual(i)
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	_update_status("5 bearings seized. Find oil can and lubricate them.")
