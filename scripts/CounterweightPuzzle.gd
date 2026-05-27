extends RoomPuzzle
class_name CounterweightPuzzle

# The Counterweight - Room 10
# Puzzle: Balance a scale by adding/removing weights until equilibrium.
#   The beam has left and right pans. Add weights to either side.
#   Current weight on each side shown. Goal: difference = 0.
#   5 weights available: 1, 2, 3, 5, 8. Must use at least 3 different weights.
#   When balanced, a crystal aligns and light passes through, activating emitter.
# Token: Inside counterweight box — heavy box unlocks when balanced
# Shrine: Balance Kami - prefers Precision Tools, Sacred Gasket

enum PanSide { LEFT, RIGHT }

# Balance beam
var beam: Node2D
var beam_angle: float = 0.0  # -15° to +15° based on imbalance
const MAX_BEAM_ANGLE: float = 15.0

# Pans
var left_pan: Node2D
var right_pan: Node2D

# Weight pool (available to place)
var weight_pool: Node2D
var available_weights: Array[int] = [1, 2, 3, 5, 8]
var weight_sprites: Array[Node2D] = []
var weight_placed: Array[bool] = [false, false, false, false, false]

# Current weights on pans
var left_weights: Array[int] = []
var right_weights: Array[int] = []

# Target and current totals
var left_total: int = 0
var right_total: int = 0

# Balance box (token container)
var balance_box: Node2D
var box_open: bool = false

# Visual
var status_label: Label
var left_label: Label
var right_label: Label

func _ready():
	room_id = 10
	room_name = "The Counterweight"
	super._ready()

func _setup_visuals():
	# Balance beam (center, horizontal)
	beam = _create_beam()
	add_child(beam)
	
	# Left pan
	left_pan = _create_pan("Left")
	left_pan.position = Vector2(-50, 15)
	beam.add_child(left_pan)
	
	# Right pan
	right_pan = _create_pan("Right")
	right_pan.position = Vector2(50, 15)
	beam.add_child(right_pan)
	
	# Weight pool (bottom)
	weight_pool = _create_weight_pool()
	weight_pool.position = Vector2(0, 60)
	add_child(weight_pool)
	
	# Balance box (center, below beam)
	balance_box = _create_balance_box()
	balance_box.position = Vector2(0, 35)
	add_child(balance_box)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Add weights to balance the scale. Use at least 3 different weights."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-150, -80)
	status_label.size = Vector2(300, 24)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color(0.9, 0.9, 0.8)
	add_child(status_label)
	
	# Left total label
	left_label = Label.new()
	left_label.name = "LeftLabel"
	left_label.text = "0"
	left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_label.position = Vector2(-70, 25)
	left_label.size = Vector2(30, 18)
	left_label.add_theme_font_size_override("font_size", 12)
	left_label.modulate = Color(0.7, 0.7, 0.9)
	add_child(left_label)
	
	# Right total label
	right_label = Label.new()
	right_label.name = "RightLabel"
	right_label.text = "0"
	right_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_label.position = Vector2(40, 25)
	right_label.size = Vector2(30, 18)
	right_label.add_theme_font_size_override("font_size", 12)
	right_label.modulate = Color(0.7, 0.7, 0.9)
	add_child(right_label)

func _create_beam() -> Node2D:
	var b = Node2D.new()
	b.name = "BalanceBeam"
	
	# Beam sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_counterweight_scale.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_counterweight_scale.png")
		sprite.scale = Vector2(0.7, 0.5)
	else:
		# Fallback: beam bar
		var bar = Line2D.new()
		bar.points = PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)])
		bar.width = 6
		bar.default_color = Color(0.6, 0.5, 0.4)
		b.add_child(bar)
		
		# Fulcrum triangle
		var fulcrum = Polygon2D.new()
		fulcrum.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(-8, 15), Vector2(8, 15)
		])
		fulcrum.color = Color(0.5, 0.5, 0.55)
		b.add_child(fulcrum)
	b.add_child(sprite)
	
	return b

func _create_pan(side: String) -> Node2D:
	var pan = Node2D.new()
	pan.name = "%sPan" % side
	pan.set_meta("type", "pan")
	pan.set_meta("side", side.to_lower())
	
	# Pan bowl
	var bowl = Polygon2D.new()
	bowl.polygon = PackedVector2Array([
		Vector2(-15, 0), Vector2(15, 0),
		Vector2(12, 12), Vector2(-12, 12)
	])
	bowl.color = Color(0.6, 0.6, 0.65)
	pan.add_child(bowl)
	
	# Chain lines
	var chain = Line2D.new()
	chain.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -15)])
	chain.width = 2
	chain.default_color = Color(0.5, 0.5, 0.5)
	pan.add_child(chain)
	
	return pan

func _create_weight_pool() -> Node2D:
	var pool = Node2D.new()
	pool.name = "WeightPool"
	
	# Label
	var lbl = Label.new()
	lbl.text = "WEIGHTS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-30, -15)
	lbl.size = Vector2(60, 14)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	pool.add_child(lbl)
	
	# Create weight objects
	for i in available_weights.size():
		var w = _create_weight(i, available_weights[i])
		w.position = Vector2(-40 + i * 20, 5)
		weight_sprites.append(w)
		pool.add_child(w)
	
	return pool

func _create_weight(index: int, value: int) -> Node2D:
	var w = Node2D.new()
	w.name = "Weight_%d" % value
	w.set_meta("type", "weight")
	w.set_meta("index", index)
	w.set_meta("value", value)
	
	# Weight sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_weights.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_weights.png")
		sprite.scale = Vector2(0.3 + value * 0.05, 0.3 + value * 0.05)
	else:
		var poly = Polygon2D.new()
		var size = 4 + value * 1.5
		poly.polygon = PackedVector2Array([
			Vector2(-size, -size), Vector2(size, -size),
			Vector2(size, size), Vector2(-size, size)
		])
		poly.color = Color(0.4 + value * 0.05, 0.4, 0.35)
		w.add_child(poly)
	w.add_child(sprite)
	
	# Value label
	var lbl = Label.new()
	lbl.text = str(value)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-8, -8)
	lbl.size = Vector2(16, 14)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.9, 0.9, 0.8)
	w.add_child(lbl)
	
	return w

func _create_balance_box() -> Node2D:
	var box = Node2D.new()
	box.name = "BalanceBox"
	
	var door = Polygon2D.new()
	door.name = "Door"
	door.polygon = PackedVector2Array([
		Vector2(-12, -10), Vector2(12, -10),
		Vector2(12, 10), Vector2(-12, 10)
	])
	door.color = Color(0.4, 0.4, 0.45)
	box.add_child(door)
	
	return box

func _setup_interactables():
	# Pans
	interactables.append(left_pan)
	interactables.append(right_pan)
	
	# Weights in pool
	for w in weight_sprites:
		interactables.append(w)
	
	# Balance box (for token after open)
	interactables.append(balance_box)

func _setup_shrine():
	# Balance Kami
	kami_shrine = _create_shrine_from_db("balance_kami", Vector2(-60, -50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(_delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	# Update beam tilt based on weight difference
	var diff = left_total - right_total
	var target_angle = clamp(float(diff) / 10.0, -MAX_BEAM_ANGLE, MAX_BEAM_ANGLE)
	beam_angle = lerp(beam_angle, target_angle, 0.1)
	beam.rotation_degrees = beam_angle

func _add_weight_to_pan(weight_idx: int, side: PanSide):
	if weight_placed[weight_idx]:
		return  # Already placed
	
	var value = available_weights[weight_idx]
	weight_placed[weight_idx] = true
	
	# Track totals
	match side:
		PanSide.LEFT:
			left_weights.append(value)
			left_total += value
		PanSide.RIGHT:
			right_weights.append(value)
			right_total += value
	
	# Move weight sprite to pan
	var w = weight_sprites[weight_idx]
	var target_pos: Vector2
	match side:
		PanSide.LEFT:
			target_pos = left_pan.global_position + Vector2(randf() * 16 - 8, randf() * 6)
		PanSide.RIGHT:
			target_pos = right_pan.global_position + Vector2(randf() * 16 - 8, randf() * 6)
	
	var tween = create_tween()
	tween.tween_property(w, "global_position", target_pos, 0.3)
	
	# Remove from pool interactables, add to pan
	interactables.erase(w)
	
	_update_labels()
	_play_sound("place_weight")
	
	# Check solve
	_check_balance()

func _remove_weight_from_pan(weight_idx: int):
	if not weight_placed[weight_idx]:
		return
	
	var value = available_weights[weight_idx]
	
	# Find and remove from appropriate side
	if value in left_weights:
		left_weights.erase(value)
		left_total -= value
	elif value in right_weights:
		right_weights.erase(value)
		right_total -= value
	
	weight_placed[weight_idx] = false
	
	# Move back to pool
	var w = weight_sprites[weight_idx]
	var pool_pos = weight_pool.global_position + Vector2(-40 + weight_idx * 20, 5)
	
	var tween = create_tween()
	tween.tween_property(w, "global_position", pool_pos, 0.3)
	
	# Re-add to interactables
	interactables.append(w)
	
	_update_labels()
	_play_sound("remove_weight")
	
	# Reset if was solved
	if state == PuzzleState.SOLVED:
		state = PuzzleState.ACTIVE
		box_open = false
		var door = balance_box.get_node("Door")
		door.scale = Vector2(1, 1)

func _check_balance():
	var diff = abs(left_total - right_total)
	var unique_weights_used = _count_unique_weights_used()
	
	if diff == 0 and unique_weights_used >= 3:
		_solve_puzzle()
	elif diff == 0 and unique_weights_used < 3:
		status_label.text = "Balanced! But use at least 3 different weights."
		status_label.modulate = Color(0.9, 0.7, 0.3)
	else:
		var heavier = "LEFT" if left_total > right_total else "RIGHT"
		status_label.text = "%s side heavier by %d." % [heavier, diff]
		status_label.modulate = Color(0.9, 0.9, 0.8)

func _count_unique_weights_used() -> int:
	var unique = {}
	for w in left_weights:
		unique[w] = true
	for w in right_weights:
		unique[w] = true
	return unique.size()

func _solve_puzzle():
	state = PuzzleState.SOLVED
	status_label.text = "PERFECT BALANCE! Crystal aligned!"
	status_label.modulate = Color(0.3, 0.9, 0.3)
	
	# Open balance box
	box_open = true
	var door = balance_box.get_node("Door")
	var tween = create_tween()
	tween.tween_property(door, "scale:x", 0.1, 0.5)
	
	# Reveal token
	if gear_devil_token:
		gear_devil_token.visible = true
		gear_devil_token.position = balance_box.position + Vector2(0, -5)
		gear_devil_token.modulate.a = 0.0
		var tween2 = create_tween()
		tween2.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)
	
	# Activate emitter
	if light_emitter:
		light_emitter.visible = true
		var tween3 = create_tween()
		tween3.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	_show_victory_popup("The scale balances perfectly! A crystal aligns in the beam path, and light streams through the counterweight mechanism.")

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

func _update_labels():
	left_label.text = str(left_total)
	right_label.text = str(right_total)

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	var type = obj.get_meta("type", "")
	match type:
		"pan":
			var side = obj.get_meta("side", "")
			return "[E] Place selected weight on %s" % side.to_upper()
		"weight":
			var val = obj.get_meta("value", 0)
			return "[E] Pick up weight (%d)" % val
		_:
			if obj == balance_box:
				if box_open and gear_devil_token and not token_collected:
					return "[E] Collect Token from Box"
				if box_open:
					return "[E] Inspect Box"
				return "[E] Inspect Locked Box"
			return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"pan":
			# Place currently selected weight (if any) — simplified: place nearest available
			var side = PanSide.LEFT if obj.get_meta("side", "") == "left" else PanSide.RIGHT
			_place_next_available_weight(side)
		"weight":
			var idx = obj.get_meta("index", 0)
			if weight_placed[idx]:
				_remove_weight_from_pan(idx)
			else:
				# Pick up and prompt for side
				_show_weight_placement_prompt(idx)
		_:
			if obj == balance_box and box_open and gear_devil_token and not token_collected:
				_on_token_collected()
			else:
				super._on_interact(obj)

func _place_next_available_weight(side: PanSide):
	# Find first available weight
	for i in available_weights.size():
		if not weight_placed[i]:
			_add_weight_to_pan(i, side)
			return
	status_label.text = "No weights left in pool!"
	status_label.modulate = Color(0.9, 0.5, 0.2)

func _show_weight_placement_prompt(idx: int):
	# In a full game this would show a side selection UI
	# For now, auto-place on lighter side
	if left_total <= right_total:
		_add_weight_to_pan(idx, PanSide.LEFT)
	else:
		_add_weight_to_pan(idx, PanSide.RIGHT)

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["left_weights"] = left_weights
	data["right_weights"] = right_weights
	data["left_total"] = left_total
	data["right_total"] = right_total
	data["weight_placed"] = weight_placed
	data["box_open"] = box_open
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("left_weights"):
		left_weights = data["left_weights"]
	if data.has("right_weights"):
		right_weights = data["right_weights"]
	if data.has("left_total"):
		left_total = data["left_total"]
	if data.has("right_total"):
		right_total = data["right_total"]
	if data.has("weight_placed"):
		weight_placed = data["weight_placed"]
		for i in weight_placed.size():
			if weight_placed[i]:
				# Hide placed weights from pool
				if i < weight_sprites.size():
					var w = weight_sprites[i]
					w.visible = false
					interactables.erase(w)
	if data.has("box_open"):
		box_open = data["box_open"]
		if box_open:
			var door = balance_box.get_node("Door")
			door.scale.x = 0.1
	
	_update_labels()

func reset_puzzle():
	left_weights = []
	right_weights = []
	left_total = 0
	right_total = 0
	weight_placed = [false, false, false, false, false]
	box_open = false
	beam_angle = 0.0
	beam.rotation_degrees = 0.0
	
	for i in weight_sprites.size():
		var w = weight_sprites[i]
		w.visible = true
		w.position = Vector2(-40 + i * 20, 5)
		if w not in interactables:
			interactables.append(w)
	
	var door = balance_box.get_node("Door")
	door.scale = Vector2(1, 1)
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	_update_labels()
	status_label.text = "Add weights to balance the scale. Use at least 3 different weights."
	status_label.modulate = Color(0.9, 0.9, 0.8)
