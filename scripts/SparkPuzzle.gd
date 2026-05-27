class_name SparkPuzzle
extends RoomPuzzle

# ============================================
# THE SPARK — Room 2 Ignition Sequence Puzzle
# ============================================
# Watch the spark trail, then light the 6 boilers in that order.
# Wrong order = backfire (damage + reset). Correct = furnace ignites.

@export var num_boilers: int = 6
@export var spark_trail_interval: float = 5.0
@export var backfire_damage: int = 5

# Puzzle objects
var boilers: Array[Dictionary] = []  # {node, position, lit, label}
var furnace: Node2D
var spark_trail_timer: float = 0.0
var showing_trail: bool = false
var correct_sequence: Array[int] = []
var player_sequence: Array[int] = []
var trail_index: int = 0
var trail_progress: float = 0.0

# Visual nodes (created procedurally)
var boiler_nodes: Array[Node2D] = []
var spark_particle: Node2D
var furnace_glow: Polygon2D
var sequence_label: Label

# State
enum SparkState { WATCHING, INPUTTING, BACKFIRE, SOLVED }
var spark_state: SparkState = SparkState.WATCHING

func _ready():
	super._ready()
	puzzle_name = "The Spark"
	puzzle_description = "Watch the spark trail, then light the boilers in that order."

func initialize():
	super.initialize()
	
	# Generate random correct sequence (0-5, no repeats)
	correct_sequence = range(num_boilers)
	correct_sequence.shuffle()
	
	# Create 6 boiler valves in hexagonal arrangement around center
	for i in range(num_boilers):
		var angle = (TAU / 6.0) * i - PI / 2  # Start from top
		var pos = Vector2(cos(angle) * 100, sin(angle) * 100)
		
		var boiler = Node2D.new()
		boiler.name = "Boiler_%d" % i
		boiler.position = pos
		
		# Boiler tank visual (hexagon)
		var tank = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in 6:
			var a = (TAU / 6.0) * j
			pts.append(Vector2(cos(a) * 14, sin(a) * 14))
		tank.polygon = pts
		tank.color = Color(0.5, 0.5, 0.5, 0.8)
		boiler.add_child(tank)
		
		# Unlit indicator (dark center)
		var center = Polygon2D.new()
		var cpts = PackedVector2Array()
		for j in 6:
			var a = (TAU / 6.0) * j
			cpts.append(Vector2(cos(a) * 8, sin(a) * 8))
		center.polygon = cpts
		center.color = Color(0.2, 0.2, 0.2)
		center.name = "Center"
		boiler.add_child(center)
		
		# Lit flame (hidden until lit)
		var flame = Polygon2D.new()
		var fpts = PackedVector2Array()
		for j in 8:
			var a = (TAU / 8.0) * j
			var r = 6.0 if j % 2 == 0 else 10.0
			fpts.append(Vector2(cos(a) * r, sin(a) * r - 5))
		flame.polygon = fpts
		flame.color = Color(1.0, 0.5, 0.1)
		flame.visible = false
		flame.name = "Flame"
		boiler.add_child(flame)
		
		# Pipe connecting to furnace
		var pipe = Line2D.new()
		pipe.points = PackedVector2Array([Vector2.ZERO, pos * 0.45])
		pipe.width = 5
		pipe.default_color = Color(0.6, 0.4, 0.3)
		pipe.name = "Pipe"
		boiler.add_child(pipe)
		
		# Number label above boiler
		var lbl = Label.new()
		lbl.text = str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(-10, -28)
		lbl.size = Vector2(20, 16)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(0.8, 0.8, 0.8)
		boiler.add_child(lbl)
		
		boilers.append({
			"index": i,
			"position": pos,
			"lit": false,
			"node": boiler,
			"center_node": center,
			"flame_node": flame
		})
		boiler_nodes.append(boiler)
		add_child(boiler)
	
	# Central furnace
	furnace = Node2D.new()
	furnace.name = "CentralFurnace"
	
	# Furnace hex body - sprite or procedural
	var furn_body = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_spark_furnace.png"):
		furn_body.texture = load("res://assets/sprites/puzzles/puzzle_spark_furnace.png")
		furn_body.scale = Vector2(0.6, 0.6)
	else:
		var furn_poly = Polygon2D.new()
		var fpts2 = PackedVector2Array()
		for i in 6:
			var a = (TAU / 6.0) * i
			fpts2.append(Vector2(cos(a) * 35, sin(a) * 35))
		furn_poly.polygon = fpts2
		furn_poly.color = Color(0.8, 0.3, 0.1)
		furn_body.add_child(furn_poly)
	furn_body.name = "Body"
	furnace.add_child(furn_body)
	
	# Inner glow (intensifies as boilers light)
	furnace_glow = Polygon2D.new()
	var gpts = PackedVector2Array()
	for i in 6:
		var a = (TAU / 6.0) * i
		gpts.append(Vector2(cos(a) * 22, sin(a) * 22))
	furnace_glow.polygon = gpts
	furnace_glow.color = Color(0.5, 0.2, 0.05)
	furnace_glow.name = "Glow"
	furnace.add_child(furnace_glow)
	
	# Furnace gauge (shows lit count)
	var gauge_bg = Polygon2D.new()
	var gbpts = PackedVector2Array()
	for i in 16:
		var a = (TAU / 16.0) * i
		gbpts.append(Vector2(cos(a) * 18, sin(a) * 18))
	gauge_bg.polygon = gbpts
	gauge_bg.color = Color(0.3, 0.3, 0.3)
	furnace.add_child(gauge_bg)
	
	add_child(furnace)
	
	# Spark particle (the traveling spark that shows the trail)
	spark_particle = Node2D.new()
	spark_particle.name = "SparkParticle"
	spark_particle.visible = false
	
	var spark_vis = Polygon2D.new()
	var spts = PackedVector2Array()
	for i in 8:
		var a = (TAU / 8.0) * i
		var r = 5.0 if i % 2 == 0 else 8.0
		spts.append(Vector2(cos(a) * r, sin(a) * r))
	spark_vis.polygon = spts
	spark_vis.color = Color(1.0, 0.9, 0.3)
	spark_particle.add_child(spark_vis)
	
	var spark_glow = Polygon2D.new()
	var sgpts = PackedVector2Array()
	for i in 8:
		var a = (TAU / 8.0) * i
		sgpts.append(Vector2(cos(a) * 12, sin(a) * 12))
	spark_glow.polygon = sgpts
	spark_glow.color = Color(1.0, 0.7, 0.2, 0.3)
	spark_particle.add_child(spark_glow)
	
	add_child(spark_particle)
	
	# Instruction label
	sequence_label = Label.new()
	sequence_label.name = "InstructionLabel"
	sequence_label.text = "Watch the spark trail..."
	sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sequence_label.position = Vector2(-150, -180)
	sequence_label.size = Vector2(300, 30)
	sequence_label.add_theme_font_size_override("font_size", 16)
	sequence_label.modulate = Color(0.9, 0.7, 0.3)
	add_child(sequence_label)
	
	# Start showing the trail
	_start_trail_demo()

func _process(delta: float):
	if state == PuzzleState.SOLVED or state == PuzzleState.LOCKED:
		return
	
	match spark_state:
		SparkState.WATCHING:
			_process_trail(delta)
		SparkState.BACKFIRE:
			_process_backfire(delta)
	
	# Update furnace glow based on lit count
	var lit_count = _get_lit_count()
	var intensity = float(lit_count) / float(num_boilers)
	if furnace_glow:
		furnace_glow.color = Color(lerp(0.5, 1.0, intensity), lerp(0.2, 0.6, intensity), lerp(0.05, 0.1, intensity))
		furnace_glow.modulate.a = 0.5 + intensity * 0.5

func _start_trail_demo():
	spark_state = SparkState.WATCHING
	showing_trail = true
	trail_index = 0
	trail_progress = 0.0
	spark_trail_timer = spark_trail_interval
	sequence_label.text = "Watch the spark trail..."
	sequence_label.modulate = Color(0.9, 0.7, 0.3)
	spark_particle.visible = true
	
	# Clear any previously lit boilers
	for boiler in boilers:
		boiler.lit = false
		boiler.flame_node.visible = false
		boiler.center_node.color = Color(0.2, 0.2, 0.2)
	player_sequence.clear()

func _process_trail(delta: float):
	if not showing_trail or correct_sequence.is_empty():
		return
	
	trail_progress += delta * 2.0  # Speed of spark travel
	
	if trail_index >= correct_sequence.size():
		# Trail complete, pause then restart or switch to input
		spark_trail_timer -= delta
		spark_particle.visible = false
		
		if spark_trail_timer <= 0:
			# After showing trail enough times, let player try
			spark_state = SparkState.INPUTTING
			sequence_label.text = "Light the boilers in the same order!"
			sequence_label.modulate = Color(0.3, 0.9, 0.3)
			spark_particle.visible = false
			showing_trail = false
		return
	
	# Move spark particle between boilers
	var from_idx = trail_index
	var to_idx = (trail_index + 1) % correct_sequence.size()
	
	var from_pos = boilers[correct_sequence[from_idx]].position
	var to_pos = boilers[correct_sequence[to_idx]].position
	
	if trail_progress >= 1.0:
		trail_progress = 0.0
		trail_index += 1
		# Brief flash at arrival
		_flash_boiler(correct_sequence[to_idx])
	
	spark_particle.position = from_pos.lerp(to_pos, trail_progress)
	spark_particle.visible = true

func _flash_boiler(idx: int):
	var boiler = boilers[idx]
	var flash = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in 8:
		var a = (TAU / 8.0) * i
		pts.append(Vector2(cos(a) * 20, sin(a) * 20))
	flash.polygon = pts
	flash.color = Color(1.0, 0.9, 0.5, 0.6)
	flash.name = "Flash"
	boiler.node.add_child(flash)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	await tween.finished
	flash.queue_free()

func _process_backfire(delta: float):
	# Visual backfire effect on furnace
	furnace_glow.color = Color(1.0, 0.1, 0.1)
	furnace_glow.modulate.a = 1.0
	
	# Shake the furnace
	furnace.position = Vector2(randf() * 6 - 3, randf() * 6 - 3)
	
	# Reset after short delay
	backfire_damage -= 1
	if backfire_damage <= 0:
		backfire_damage = 5  # Reset for next time
		furnace.position = Vector2.ZERO
		_start_trail_demo()

func try_interact() -> bool:
	if state != PuzzleState.ACTIVE:
		return false
	
	if spark_state != SparkState.INPUTTING:
		return false
	
	# Find nearest boiler
	var nearest_idx = -1
	var nearest_dist = 999999.0
	
	for i in range(boilers.size()):
		var dist = player_position.distance_to(boilers[i].position + self.global_position)
		if dist < 40.0 and dist < nearest_dist:
			nearest_dist = dist
			nearest_idx = i
	
	if nearest_idx < 0:
		return false
	
	# Check if already lit
	if boilers[nearest_idx].lit:
		return false
	
	# Add to player sequence
	player_sequence.append(nearest_idx)
	
	# Check if correct so far
	var idx_in_sequence = player_sequence.size() - 1
	if idx_in_sequence < correct_sequence.size():
		if player_sequence[idx_in_sequence] != correct_sequence[idx_in_sequence]:
			# WRONG! Backfire!
			_trigger_backfire()
			return true
	
	# Correct! Light this boiler
	_light_boiler(nearest_idx)
	
	# Check if complete
	if player_sequence.size() == correct_sequence.size():
		_solve_puzzle()
	
	return true

func _light_boiler(idx: int):
	var boiler = boilers[idx]
	boiler.lit = true
	boiler.flame_node.visible = true
	boiler.center_node.color = Color(1.0, 0.6, 0.2)
	
	# Update instruction
	var remaining = num_boilers - _get_lit_count()
	sequence_label.text = "%d remaining..." % remaining
	sequence_label.modulate = Color(0.9, 0.7, 0.3)
	
	# Play light sound if available
	_play_sound("boiler_ignite")

func _trigger_backfire():
	spark_state = SparkState.BACKFIRE
	sequence_label.text = "BACKFIRE! Wrong sequence!"
	sequence_label.modulate = Color(1.0, 0.2, 0.2)
	
	# Damage player
	GameState.damage_player(backfire_damage)
	
	# Extinguish all boilers
	for boiler in boilers:
		boiler.lit = false
		boiler.flame_node.visible = false
		boiler.center_node.color = Color(0.2, 0.2, 0.2)
	player_sequence.clear()
	
	_play_sound("backfire")
	
	# Show backfire for 1 second then restart trail
	await get_tree().create_timer(1.0).timeout
	_start_trail_demo()

func _get_lit_count() -> int:
	var count = 0
	for boiler in boilers:
		if boiler.lit:
			count += 1
	return count

func _solve_puzzle():
	spark_state = SparkState.SOLVED
	sequence_label.text = "FURNACE IGNITED!"
	sequence_label.modulate = Color(1.0, 0.9, 0.3)
	
	# Intense furnace glow
	furnace_glow.color = Color(1.0, 0.6, 0.1)
	furnace_glow.modulate.a = 1.0
	
	# Pulse the furnace
	var tween = create_tween()
	tween.tween_property(furnace_glow, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_property(furnace_glow, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Spawn token
	_spawn_token(Vector2(0, -60))
	
	state = PuzzleState.SOLVED
	emit_signal("puzzle_solved")
	
	_play_sound("furnace_ignite")
	_show_victory_popup("The furnace roars to life! A Gear Devil Token materializes in the heat shimmer.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -220)
	popup.size = Vector2(400, 60)
	popup.add_theme_font_size_override("font_size", 14)
	popup.modulate = Color(0.9, 0.9, 0.5)
	add_child(popup)
	
	# Fade out after 4 seconds
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 2.0)
	await tween.finished
	popup.queue_free()

func _setup_shrine():
	# Heat Kami - prefers fire offerings
	kami_shrine = _create_shrine_from_db("heat_kami", Vector2(-80, 60))
	add_child(kami_shrine)

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["correct_sequence"] = correct_sequence
	data["player_sequence"] = player_sequence
	data["spark_state"] = spark_state
	data["lit_boilers"] = _get_lit_array()
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("correct_sequence"):
		correct_sequence = data["correct_sequence"]
	if data.has("player_sequence"):
		player_sequence = data["player_sequence"]
	if data.has("spark_state"):
		spark_state = data["spark_state"]
	
	if data.has("lit_boilers"):
		var lit = data["lit_boilers"]
		for i in range(min(lit.size(), boilers.size())):
			boilers[i].lit = lit[i]
			boilers[i].flame_node.visible = lit[i]
			boilers[i].center_node.color = Color(1.0, 0.6, 0.2) if lit[i] else Color(0.2, 0.2, 0.2)

func _get_lit_array() -> Array[bool]:
	var arr: Array[bool] = []
	for boiler in boilers:
		arr.append(boiler.lit)
	return arr
