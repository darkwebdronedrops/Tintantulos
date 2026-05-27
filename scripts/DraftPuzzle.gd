extends RoomPuzzle
class_name DraftPuzzle

# The Draft - Room 4
# Puzzle: Direct steam pressure through pipes to push a prism into the light emitter slot
# Mechanic: Toggle 4 directional vents (N/E/S/W). Steam enters from S. 
#   E/W open = steam escapes, pressure drops. S+N open = pressure builds.
#   At 75+ PSI, prism pushes up into slot, emitter activates.
# Token: Carried by steam wisp — visible when pressure first exceeds 50
# Shrine: Steam Kami - accepts heat/steam related offerings

enum SteamState { IDLE, BUILDING, ESCAPING, PUSHING, SOLVED }

# Vents: each has state OPEN or CLOSED
var vents: Array[Node2D] = []
var vent_states: Array[bool] = [false, false, false, false]  # N, E, S, W (true = OPEN)
const VENT_NAMES: Array[String] = ["North", "East", "South", "West"]

# Prism
var prism: Node2D
var prism_position: int = 0  # 0=bottom, 1=low, 2=high, 3=slot (solved)
var prism_target_y: Array[float] = [40.0, 10.0, -20.0, -50.0]

# Pressure system
var pressure: float = 0.0  # 0-100
var pressure_gauge: Node2D
const PRESSURE_BUILD_RATE: float = 25.0  # Per cycle when correct
const PRESSURE_ESCAPE_RATE: float = 15.0  # Per cycle when wrong
const PRESSURE_TARGET: float = 75.0
const CYCLE_TIME: float = 1.5  # Seconds between pressure ticks
var cycle_timer: float = 0.0

# Steam wisp (carries token)
var steam_wisp: Node2D
var wisp_visible: bool = false

# Visual
var pipe_system: Node2D
var steam_state: SteamState = SteamState.IDLE
var status_label: Label

func _ready():
	room_id = 4
	room_name = "The Draft"
	vent_states = _generate_solution()
	super._ready()

func _generate_solution() -> Array[bool]:
	# Solution: S=OPEN (always), N=OPEN, E=CLOSED, W=CLOSED
	# Randomize which of E/W is the "trap" vent to keep it fresh
	return [true, false, true, false]

func _setup_visuals():
	# Central pipe junction
	pipe_system = Node2D.new()
	pipe_system.name = "PipeSystem"
	
	# Cross pipe sprite
	var cross = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_draft_pipe.png"):
		cross.texture = load("res://assets/sprites/puzzles/puzzle_draft_pipe.png")
		cross.scale = Vector2(0.8, 0.8)
	else:
		# Fallback: draw cross with Line2D
		var h_pipe = Line2D.new()
		h_pipe.points = PackedVector2Array([Vector2(-60, 0), Vector2(60, 0)])
		h_pipe.width = 8
		h_pipe.default_color = Color(0.5, 0.5, 0.55)
		pipe_system.add_child(h_pipe)
		
		var v_pipe = Line2D.new()
		v_pipe.points = PackedVector2Array([Vector2(0, -60), Vector2(0, 60)])
		v_pipe.width = 8
		v_pipe.default_color = Color(0.5, 0.5, 0.55)
		pipe_system.add_child(v_pipe)
	pipe_system.add_child(cross)
	add_child(pipe_system)
	
	# Pressure gauge (center)
	pressure_gauge = _create_pressure_gauge()
	pressure_gauge.position = Vector2(0, 0)
	add_child(pressure_gauge)
	
	# Prism (starts at bottom of vertical pipe)
	prism = _create_prism()
	prism.position = Vector2(0, prism_target_y[0])
	add_child(prism)
	
	# Steam wisp (hidden until pressure > 50)
	steam_wisp = _create_steam_wisp()
	steam_wisp.visible = false
	steam_wisp.position = Vector2(0, 60)
	add_child(steam_wisp)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Pressure: 0 PSI"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-80, -80)
	status_label.size = Vector2(160, 24)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.modulate = Color(0.8, 0.9, 0.9)
	add_child(status_label)

func _create_pressure_gauge() -> Node2D:
	var gauge = Node2D.new()
	gauge.name = "PressureGauge"
	
	# Gauge background
	var bg = Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(-30, -8), Vector2(30, -8),
		Vector2(30, 8), Vector2(-30, 8)
	])
	bg.color = Color(0.2, 0.2, 0.25)
	gauge.add_child(bg)
	
	# Green zone (target area)
	var green_zone = Polygon2D.new()
	green_zone.polygon = PackedVector2Array([
		Vector2(12, -8), Vector2(24, -8),
		Vector2(24, 8), Vector2(12, 8)
	])
	green_zone.color = Color(0.2, 0.7, 0.3, 0.3)
	gauge.add_child(green_zone)
	
	# Pressure bar
	var bar = Polygon2D.new()
	bar.name = "PressureBar"
	bar.polygon = PackedVector2Array([
		Vector2(-28, -6), Vector2(-28, 6),
		Vector2(-28, 6), Vector2(-28, -6)
	])
	bar.color = Color(0.3, 0.7, 0.9)
	gauge.add_child(bar)
	
	# Tick marks
	for i in 6:
		var tick = Line2D.new()
		tick.points = PackedVector2Array([Vector2(-28 + i * 12, -10), Vector2(-28 + i * 12, -8)])
		tick.width = 2
		tick.default_color = Color(0.6, 0.6, 0.6)
		gauge.add_child(tick)
	
	return gauge

func _create_prism() -> Node2D:
	var p = Node2D.new()
	p.name = "Prism"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_draft_prism.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_draft_prism.png")
		sprite.scale = Vector2(0.4, 0.4)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-8, 8), Vector2(8, 8),
			Vector2(0, -12)
		])
		poly.color = Color(0.7, 0.8, 0.9, 0.8)
		p.add_child(poly)
	p.add_child(sprite)
	return p

func _create_steam_wisp() -> Node2D:
	var wisp = Node2D.new()
	wisp.name = "SteamWisp"
	
	# Wisp core
	var core = Polygon2D.new()
	core.name = "Core"
	core.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(4, 4), Vector2(-4, 4)
	])
	core.color = Color(0.8, 0.9, 0.9, 0.7)
	wisp.add_child(core)
	
	# Glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8)
	])
	glow.color = Color(0.7, 0.85, 0.9, 0.2)
	glow.scale = Vector2(1.5, 1.5)
	wisp.add_child(glow)
	
	return wisp

func _setup_interactables():
	# Create 4 vents at cardinal directions
	var positions = [Vector2(0, -70), Vector2(70, 0), Vector2(0, 70), Vector2(-70, 0)]
	for i in 4:
		var vent = _create_vent(i, positions[i])
		vents.append(vent)
		interactables.append(vent)
		add_child(vent)
	
	# Make prism interactable (grab token from it when visible)
	interactables.append(prism)

func _create_vent(index: int, pos: Vector2) -> Node2D:
	var vent = Node2D.new()
	vent.name = "Vent_%s" % VENT_NAMES[index]
	vent.position = pos
	vent.set_meta("type", "vent")
	vent.set_meta("index", index)
	
	# Vent sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_draft_vent.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_draft_vent.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		# Fallback: rectangular vent cover
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-12, -12), Vector2(12, -12),
			Vector2(12, 12), Vector2(-12, 12)
		])
		poly.color = Color(0.55, 0.55, 0.6)
		vent.add_child(poly)
	vent.add_child(sprite)
	
	# State indicator (open = blue tint, closed = grey)
	var indicator = Polygon2D.new()
	indicator.name = "StateIndicator"
	indicator.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(6, 6), Vector2(-6, 6)
	])
	indicator.color = Color(0.4, 0.4, 0.4)  # Grey = closed
	indicator.position = Vector2(0, -20)
	vent.add_child(indicator)
	
	# Label
	var lbl = Label.new()
	lbl.text = VENT_NAMES[index]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-20, 16)
	lbl.size = Vector2(40, 14)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	vent.add_child(lbl)
	
	return vent

func _setup_shrine():
	# Steam/Pressure Kami - accepts heat and steam offerings
	kami_shrine = _create_shrine_from_db("steam_kami", Vector2(-60, -60))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	cycle_timer += delta
	if cycle_timer >= CYCLE_TIME:
		cycle_timer = 0.0
		_tick_pressure_cycle()
	
	# Animate steam wisp
	if steam_wisp.visible:
		steam_wisp.position.y = 60 - (pressure / 100.0) * 80
		steam_wisp.position.x = sin(Time.get_time_dict_from_system()["second"] * 2.0) * 5

func _tick_pressure_cycle():
	var s_open = vent_states[2]  # South (source)
	var n_open = vent_states[0]  # North (target)
	var e_open = vent_states[1]  # East (escape)
	var w_open = vent_states[3]  # West (escape)
	
	if not s_open:
		# Source closed — no steam entering
		steam_state = SteamState.IDLE
		_update_status("Source vent (South) is closed. No steam entering.")
		return
	
	if e_open or w_open:
		# Steam escaping
		steam_state = SteamState.ESCAPING
		pressure = max(0.0, pressure - PRESSURE_ESCAPE_RATE)
		_update_status("Steam escaping! Close East/West vents.")
		_show_steam_escape()
	else:
		# Steam building pressure
		steam_state = SteamState.BUILDING
		pressure += PRESSURE_BUILD_RATE
		_update_status("Pressure building... %d PSI" % int(pressure))
		
		# Show wisp when pressure first exceeds 50
		if pressure > 50.0 and not wisp_visible:
			wisp_visible = true
			steam_wisp.visible = true
			_show_wisp_emerge()
		
		# Check solve condition
		if pressure >= PRESSURE_TARGET:
			_pressure_solve()
			return
	
	# Clamp
	pressure = clamp(pressure, 0.0, 100.0)
	_update_gauge_visual()

func _update_gauge_visual():
	var bar = pressure_gauge.get_node("PressureBar")
	var bar_width = (pressure / 100.0) * 56.0
	bar.polygon = PackedVector2Array([
		Vector2(-28, -6), Vector2(-28 + bar_width, -6),
		Vector2(-28 + bar_width, 6), Vector2(-28, 6)
	])
	
	# Color shift: blue -> yellow -> red
	if pressure < 50:
		bar.color = Color(0.3, 0.7, 0.9)
	elif pressure < 75:
		bar.color = Color(0.9, 0.8, 0.3)
	else:
		bar.color = Color(0.9, 0.3, 0.2)

func _update_status(text: String):
	status_label.text = text

func _show_steam_escape():
	# Brief steam particle burst from escape vents
	for i in [1, 3]:  # East, West
		if vent_states[i]:
			var burst = _create_steam_burst(vents[i].position)
			add_child(burst)

func _create_steam_burst(pos: Vector2) -> Node2D:
	var burst = Node2D.new()
	burst.position = pos
	for i in 3:
		var p = Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(0, -6)
		])
		p.color = Color(0.8, 0.9, 0.9, 0.5)
		p.position = Vector2(randf() * 10 - 5, 0)
		burst.add_child(p)
		
		var tween = create_tween()
		tween.tween_property(p, "position:y", -30, 0.8)
		tween.tween_property(p, "modulate:a", 0.0, 0.8)
	
	# Auto-cleanup
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): burst.queue_free())
	return burst

func _show_wisp_emerge():
	var tween = create_tween()
	steam_wisp.modulate.a = 0.0
	tween.tween_property(steam_wisp, "modulate:a", 1.0, 0.5)
	
	# Token carried by wisp becomes visible
	if gear_devil_token:
		gear_devil_token.visible = true
		gear_devil_token.modulate.a = 0.0
		var tween2 = create_tween()
		tween2.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)

func _pressure_solve():
	steam_state = SteamState.PUSHING
	_update_status("MAXIMUM PRESSURE! Prism pushing into slot...")
	
	# Animate prism up to slot
	var tween = create_tween()
	tween.tween_property(prism, "position:y", prism_target_y[3], 1.0)
	
	# Steam wisp rises with it
	var tween2 = create_tween()
	tween2.tween_property(steam_wisp, "position:y", -50, 1.0)
	
	await tween.finished
	
	prism_position = 3
	steam_state = SteamState.SOLVED
	
	# Prism glows when locked in
	var prism_sprite = prism.get_child(0)
	if prism_sprite is Sprite2D:
		var glow_tween = create_tween()
		glow_tween.tween_property(prism_sprite, "modulate", Color(1.2, 1.2, 1.5), 0.3)
	
	_update_status("PRISM LOCKED! Light emitter activating...")
	
	# Emitter activation
	if light_emitter:
		light_emitter.visible = true
		var emit_tween = create_tween()
		emit_tween.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The prism clicks into place! Steam pressure channels through the crystal, activating the light emitter.")

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
		"vent":
			var idx = obj.get_meta("index", 0)
			var state = "OPEN" if vent_states[idx] else "CLOSED"
			return "[E] Toggle %s Vent (%s)" % [VENT_NAMES[idx], state]
		_:
			return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"vent":
			_toggle_vent(obj.get_meta("index", 0))
		_:
			super._on_interact(obj)

func _toggle_vent(index: int):
	vent_states[index] = not vent_states[index]
	
	# Update visual
	var vent = vents[index]
	var indicator = vent.get_node("StateIndicator")
	if vent_states[index]:
		indicator.color = Color(0.3, 0.7, 0.9)  # Blue = open
	else:
		indicator.color = Color(0.4, 0.4, 0.4)  # Grey = closed
	
	# Steam burst feedback
	if vent_states[index] and index == 2:  # Opening South
		_update_status("South vent opened. Steam entering...")
	elif not vent_states[index] and index == 2:
		_update_status("South vent closed. Steam cut off.")
	
	_play_sound("vent_toggle")

func activate_puzzle():
	super.activate_puzzle()
	_update_status("Toggle vents to direct steam pressure. Close East/West, open North/South.")

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["vent_states"] = vent_states
	data["pressure"] = pressure
	data["prism_position"] = prism_position
	data["wisp_visible"] = wisp_visible
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("vent_states"):
		vent_states = data["vent_states"]
		for i in 4:
			if i < vents.size():
				var indicator = vents[i].get_node("StateIndicator")
				if vent_states[i]:
					indicator.color = Color(0.3, 0.7, 0.9)
				else:
					indicator.color = Color(0.4, 0.4, 0.4)
	
	if data.has("pressure"):
		pressure = data["pressure"]
		_update_gauge_visual()
	
	if data.has("prism_position"):
		prism_position = data["prism_position"]
		if prism_position < prism_target_y.size():
			prism.position.y = prism_target_y[prism_position]
	
	if data.has("wisp_visible"):
		wisp_visible = data["wisp_visible"]
		steam_wisp.visible = wisp_visible

func reset_puzzle():
	steam_state = SteamState.IDLE
	pressure = 0.0
	prism_position = 0
	prism.position.y = prism_target_y[0]
	wisp_visible = false
	steam_wisp.visible = false
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	vent_states = _generate_solution()
	for i in 4:
		var indicator = vents[i].get_node("StateIndicator")
		indicator.color = Color(0.4, 0.4, 0.4)
	
	_update_gauge_visual()
	_update_status("Pressure: 0 PSI")
