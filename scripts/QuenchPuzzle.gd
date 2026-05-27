extends RoomPuzzle
class_name QuenchPuzzle

# The Quench - Room 1 (entry point)
# Puzzle: Redirect steam condensation to cool overheated gears
# Mechanic: Water flow pipes with rotatable valves
# Token: Inside cooling tank (visible only after draining)
# Shrine: Desperate Water Kami - accepts ANY offering (even trash)

enum WaterState { STEAM_HOT, COOLING, COOLED }

# Puzzle objects
var valves: Array[Node2D] = []  # 3 rotatable pipe valves
var cooling_tank: Node2D  # Contains hidden token, must drain
var drain_plug: Node2D  # Remove to drain tank
var overheated_gears: Node2D  # Must cool to activate emitter
var water_flow_state: WaterState = WaterState.STEAM_HOT

# Valve configuration (0-3, representing pipe direction)
var valve_configs: Array[int] = [0, 0, 0]  # Start random or misaligned
var valve_solution: Array[int] = [2, 1, 3]  # Correct: water flows through

func _ready():
	room_id = 1
	room_name = "The Quench"
	valve_solution = _generate_solution()  # Randomize each run
	super._ready()

func _generate_solution() -> Array[int]:
	# Random but solvable configuration
	return [randi() % 4, randi() % 4, randi() % 4]

func _setup_visuals():
	# Cooling tank (large rectangular container)
	cooling_tank = Node2D.new()
	cooling_tank.name = "CoolingTank"
	cooling_tank.position = Vector2(80, -40)
	
	# Try sprite first, fallback to procedural
	var tank_sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_quench_tank.png"):
		tank_sprite.texture = load("res://assets/sprites/puzzles/puzzle_quench_tank.png")
		tank_sprite.scale = Vector2(0.8, 0.8)
		cooling_tank.add_child(tank_sprite)
	else:
		var tank_poly = Polygon2D.new()
		tank_poly.polygon = PackedVector2Array([
			Vector2(-40, -30), Vector2(40, -30),
			Vector2(40, 30), Vector2(-40, 30)
		])
		tank_poly.color = Color(0.3, 0.5, 0.6, 0.6)
		cooling_tank.add_child(tank_poly)
	
	# Water level indicator
	var water = Polygon2D.new()
	water.name = "WaterLevel"
	water.polygon = PackedVector2Array([
		Vector2(-36, 26), Vector2(36, 26),
		Vector2(36, 10), Vector2(-36, 10)
	])
	water.color = Color(0.2, 0.6, 0.8, 0.8)
	cooling_tank.add_child(water)
	
	add_child(cooling_tank)
	
	# Overheated gears
	overheated_gears = Node2D.new()
	overheated_gears.name = "OverheatedGears"
	overheated_gears.position = Vector2(-60, 20)
	
	var gear_poly = Polygon2D.new()
	gear_poly.name = "GearVisual"
	var pts = PackedVector2Array()
	for i in 8:
		var a = (TAU / 8.0) * i
		var r = 20.0 if i % 2 == 0 else 14.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	gear_poly.polygon = pts
	gear_poly.color = Color(0.8, 0.2, 0.1)  # Red = hot
	overheated_gears.add_child(gear_poly)
	
	# Heat shimmer effect (tweened glow)
	var glow = Polygon2D.new()
	glow.name = "HeatGlow"
	glow.polygon = pts
	glow.color = Color(0.9, 0.4, 0.1, 0.3)
	glow.scale = Vector2(1.3, 1.3)
	overheated_gears.add_child(glow)
	
	add_child(overheated_gears)

func _setup_interactables():
	# Create 3 valves
	for i in 3:
		var valve = _create_valve(i)
		valve.position = Vector2(-80 + (i * 50), -60)
		valves.append(valve)
		interactables.append(valve)
		add_child(valve)
	
	# Drain plug
	drain_plug = _create_drain_plug()
	drain_plug.position = Vector2(80, 20)
	interactables.append(drain_plug)
	add_child(drain_plug)
	
	# Make overheated gears interactable (pour water on them)
	interactables.append(overheated_gears)

func _create_valve(index: int) -> Node2D:
	var valve = Node2D.new()
	valve.name = "Valve_%d" % index
	valve.set_meta("type", "valve")
	valve.set_meta("index", index)
	
	# Valve body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8)
	])
	body.color = Color(0.6, 0.6, 0.5)
	valve.add_child(body)
	
	# Pipe direction indicator
	var pipe = Line2D.new()
	pipe.name = "PipeIndicator"
	pipe.width = 4
	pipe.default_color = Color(0.4, 0.5, 0.7)
	_update_pipe_visual(pipe, valve_configs[index])
	valve.add_child(pipe)
	
	return valve

func _update_pipe_visual(pipe: Line2D, config: int):
	# Config 0: horizontal, 1: vertical, 2: L-down, 3: L-up
	match config:
		0:
			pipe.points = PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)])
		1:
			pipe.points = PackedVector2Array([Vector2(0, -12), Vector2(0, 12)])
		2:
			pipe.points = PackedVector2Array([Vector2(-12, 0), Vector2(0, 0), Vector2(0, 12)])
		3:
			pipe.points = PackedVector2Array([Vector2(0, -12), Vector2(0, 0), Vector2(12, 0)])

func _create_drain_plug() -> Node2D:
	var plug = Node2D.new()
	plug.name = "DrainPlug"
	plug.set_meta("type", "drain_plug")
	
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)
	])
	poly.color = Color(0.7, 0.7, 0.7)
	plug.add_child(poly)
	
	return plug

func _setup_shrine():
	# Desperate Water Kami - accepts ANY offering
	kami_shrine = _create_shrine_from_db("water_kami", Vector2(0, 50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _setup_emitter():
	super._setup_emitter()
	light_emitter.position = Vector2(-60, -30)  # Near gears

# --- Interaction Handling ---

func _get_interact_prompt(obj: Node2D) -> String:
	var type = obj.get_meta("type", "")
	match type:
		"valve":
			return "Rotate Valve"
		"drain_plug":
			if drain_plug.visible:
				return "Pull Drain Plug"
			else:
				return "Drain Open"
		_:
			if obj == overheated_gears:
				return "Pour Water"
			if obj == kami_shrine:
				return "Offer to Kami"
			if obj == gear_devil_token:
				return "Collect Token"
	return "Interact"

func _process_interaction(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"valve":
			_rotate_valve(obj.get_meta("index"))
		"drain_plug":
			if drain_plug.visible:
				_drain_tank()
		_:
			if obj == overheated_gears:
				if water_flow_state == WaterState.COOLED:
					_pour_water_on_gears()
			elif obj == gear_devil_token:
				collect_token()

func _rotate_valve(index: int):
	valve_configs[index] = (valve_configs[index] + 1) % 4
	_update_pipe_visual(valves[index].get_node("PipeIndicator"), valve_configs[index])
	_check_water_flow()
	
	# Visual feedback
	var tween = create_tween()
	valves[index].rotation_degrees = valve_configs[index] * 90.0
	
	print("QuenchPuzzle: Valve %d rotated to config %d" % [index, valve_configs[index]])

func _check_water_flow():
	# Check if all valves match solution
	var correct = true
	for i in 3:
		if valve_configs[i] != valve_solution[i]:
			correct = false
			break
	
	if correct and water_flow_state == WaterState.STEAM_HOT:
		water_flow_state = WaterState.COOLING
		_start_cooling_sequence()

func _start_cooling_sequence():
	print("QuenchPuzzle: Water flow correct! Cooling sequence started.")
	
	# Visual: water flows through pipes
	for valve in valves:
		var tween = create_tween()
		valve.get_node("PipeIndicator").default_color = Color(0.2, 0.6, 0.8)
		
	# Gears start changing color
	var gear = overheated_gears.get_node("GearVisual")
	var tween = create_tween()
	tween.tween_property(gear, "color", Color(0.6, 0.5, 0.4), 2.0)  # Brown = cooling
	
	await get_tree().create_timer(2.0).timeout
	water_flow_state = WaterState.COOLED
	gear.color = Color(0.3, 0.4, 0.5)  # Blue-grey = cooled
	overheated_gears.get_node("HeatGlow").visible = false
	
	print("QuenchPuzzle: Gears cooled! Ready for water pouring.")

func _drain_tank():
	print("QuenchPuzzle: Drain plug pulled!")
	
	# Remove plug visual
	drain_plug.visible = false
	interactables.erase(drain_plug)
	
	# Animate water draining
	var water = cooling_tank.get_node("WaterLevel")
	var tween = create_tween()
	# Shrink water polygon to empty
	var empty_poly = PackedVector2Array([
		Vector2(-36, 26), Vector2(36, 26),
		Vector2(36, 26), Vector2(-36, 26)
	])
	tween.tween_property(water, "polygon", empty_poly, 1.5)
	
	await tween.finished
	
	# Reveal token in tank
	reveal_token()
	gear_devil_token.position = cooling_tank.position  # Token at tank bottom
	
	print("QuenchPuzzle: Cooling tank drained. Token revealed!")

func _pour_water_on_gears():
	print("QuenchPuzzle: Water poured on cooled gears!")
	
	# Final activation
	var gear = overheated_gears.get_node("GearVisual")
	var tween = create_tween()
	gear.color = Color(0.3, 0.6, 0.8)  # Bright blue = activated
	
	# Steam burst effect
	var steam = _create_steam_burst()
	add_child(steam)
	
	await get_tree().create_timer(0.5).timeout
	
	solve_puzzle()
	
	# Remove gears from interactables (already done)
	interactables.erase(overheated_gears)

func _create_steam_burst() -> Node2D:
	var steam = Node2D.new()
	for i in 5:
		var p = Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(0, -8)
		])
		p.color = Color(0.8, 0.9, 0.9, 0.6)
		p.position = Vector2(randf() * 30 - 15, randf() * 10)
		steam.add_child(p)
		
		var tween = create_tween()
		tween.tween_property(p, "position:y", p.position.y - 40, 1.0)
		tween.tween_property(p, "modulate:a", 0.0, 1.0)
		
	return steam

# --- Reset ---

func reset_puzzle():
	water_flow_state = WaterState.STEAM_HOT
	for i in 3:
		valve_configs[i] = 0
		_update_pipe_visual(valves[i].get_node("PipeIndicator"), 0)
		valves[i].rotation_degrees = 0
	
	# Reset tank
	var water = cooling_tank.get_node("WaterLevel")
	water.polygon = PackedVector2Array([
		Vector2(-36, 26), Vector2(36, 26),
		Vector2(36, 10), Vector2(-36, 10)
	])
	water.color = Color(0.2, 0.6, 0.8, 0.8)
	
	drain_plug.visible = true
	if not interactables.has(drain_plug):
		interactables.append(drain_plug)
	
	# Reset gears
	var gear = overheated_gears.get_node("GearVisual")
	gear.color = Color(0.8, 0.2, 0.1)
	overheated_gears.get_node("HeatGlow").visible = true
	if not interactables.has(overheated_gears):
		interactables.append(overheated_gears)
	
	light_emitter.visible = false
	
	state = PuzzleState.ACTIVE
	_generate_solution()
