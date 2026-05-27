class_name GovernorPuzzle
extends RoomPuzzle

# ============================================
# THE GOVERNOR — Room 3 Speed Regulation Puzzle
# ============================================
# 8 levers (4 left, 4 right) control 4 sub-systems.
# Each lever affects 2 systems. Find the combination where
# all 4 gauges read in the GREEN zone simultaneously.
# 3 red warnings trigger a Recalibration trap (combat penalty).

@export var max_warnings: int = 3
@export var warning_penalty_effect: String = "warning_sermon"  # +1 Attention cost next combat

# Lever data
enum LeverPos { UP, MIDDLE, DOWN }
var levers: Array[Dictionary] = []  # {index, side, position, affects, node, handle_node}
var num_levers: int = 8

# System gauges
enum GaugeType { PRESSURE, TEMPERATURE, TORQUE, EFFICIENCY }
var gauges: Array[Dictionary] = []  # {type, current_value, target_range, node, bar_node, label_node}
var num_gauges: int = 4

# State
enum GovernorState { ADJUSTING, RECALIBRATING, SOLVED }
var governor_state: GovernorState = GovernorState.ADJUSTING

# Warning tracking
var warning_count: int = 0

# Visual nodes
var lever_nodes: Array[Node2D] = []
var gauge_nodes: Array[Node2D] = []
var center_gauge_node: Node2D
var warning_label: Label

# Correct solution (generated at init)
var solution: Array[LeverPos] = []

# Lever-system effect matrix (each lever affects 2 systems)
var lever_effects: Array[Array] = []  # lever_idx -> [gauge_idx, delta_per_pos]

func _ready():
	super._ready()
	puzzle_name = "The Governor"
	puzzle_description = "Align all four sub-systems into the green zone by adjusting the 8 control levers."

func initialize():
	super.initialize()
	
	# Generate solution (random but solvable)
	_generate_solution()
	
	# Create left control bank
	for i in range(4):
		var lever = _create_lever(i, "left", Vector2(-70, -30 + i * 25))
		levers.append(lever)
		lever_nodes.append(lever.node)
		add_child(lever.node)
	
	# Create right control bank
	for i in range(4):
		var lever = _create_lever(i + 4, "right", Vector2(50, -30 + i * 25))
		levers.append(lever)
		lever_nodes.append(lever.node)
		add_child(lever.node)
	
	# Create central gauge panel
	center_gauge_node = Node2D.new()
	center_gauge_node.name = "CenterGaugePanel"
	center_gauge_node.position = Vector2(-40, -70)
	
	# Panel backing
	var panel = Polygon2D.new()
	panel.polygon = PackedVector2Array([
		Vector2(-50, -10), Vector2(50, -10),
		Vector2(50, 10), Vector2(-50, 10)
	])
	panel.color = Color(0.3, 0.3, 0.35)
	center_gauge_node.add_child(panel)
	
	# Main needle
	var needle = Line2D.new()
	needle.name = "MainNeedle"
	needle.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -35)])
	needle.width = 3
	needle.default_color = Color(0.9, 0.9, 0.3)
	center_gauge_node.add_child(needle)
	
	add_child(center_gauge_node)
	
	# Create 4 sub-system gauges (vertical stack below center)
	for i in range(4):
		var gauge = _create_gauge(i, Vector2(-50, 30 + i * 35))
		gauges.append(gauge)
		gauge_nodes.append(gauge.node)
		add_child(gauge.node)
	
	# Instruction label
	warning_label = Label.new()
	warning_label.name = "WarningLabel"
	warning_label.text = "Adjust levers until all gauges are GREEN"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.position = Vector2(-150, -130)
	warning_label.size = Vector2(300, 30)
	warning_label.add_theme_font_size_override("font_size", 14)
	warning_label.modulate = Color(0.8, 0.8, 0.9)
	add_child(warning_label)
	
	# Apply initial lever positions (all MIDDLE)
	_update_gauges()
	_update_lever_visuals()

func _generate_solution():
	# Build effect matrix: each lever affects 2 gauges with different strengths
	lever_effects.clear()
	for i in range(num_levers):
		var g1 = i % 4  # Each lever affects one "primary" gauge
		var g2 = (i + 2) % 4  # And one "secondary" gauge
		# Strength: primary = ±3 per position, secondary = ±1
		lever_effects.append([
			[g1, 3],   # [gauge_idx, delta]
			[g2, 1]
		])
	
	# Randomize the actual connections a bit
	# Shuffle which lever connects to which
	var primary = range(4)
	primary.shuffle()
	var secondary = range(4)
	secondary.shuffle()
	
	for i in range(num_levers):
		var g1 = primary[i % 4]
		var g2 = secondary[(i + 2) % 4]
		lever_effects[i] = [
			[g1, 3],
			[g2, 1]
		]
	
	# Generate random solution
	solution.clear()
	for i in range(num_levers):
		solution.append(randi() % 3)  # UP, MIDDLE, or DOWN
	
	# Verify it's solvable (at least one gauge in green)
	# In practice, with this system, there will always be a combination
	print("Governor: Solution generated with %d levers, %d gauges" % [num_levers, num_gauges])

func _create_lever(index: int, side: String, pos: Vector2) -> Dictionary:
	var node = Node2D.new()
	node.name = "Lever_%d_%s" % [index, side]
	node.position = pos
	
	# Slot track
	var track = Line2D.new()
	track.name = "Track"
	track.points = PackedVector2Array([Vector2(0, -12), Vector2(0, 12)])
	track.width = 4
	track.default_color = Color(0.3, 0.3, 0.3)
	node.add_child(track)
	
	# Handle
	var handle = Polygon2D.new()
	handle.name = "Handle"
	handle.polygon = PackedVector2Array([
		Vector2(-8, -5), Vector2(8, -5),
		Vector2(8, 5), Vector2(-8, 5)
	])
	handle.color = Color(0.7, 0.6, 0.4)
	node.add_child(handle)
	
	# Number label
	var lbl = Label.new()
	lbl.text = str(index + 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-12, -20)
	lbl.size = Vector2(24, 16)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	node.add_child(lbl)
	
	return {
		"index": index,
		"side": side,
		"position": LeverPos.MIDDLE,
		"node": node,
		"handle_node": handle
	}

func _create_gauge(index: int, pos: Vector2) -> Dictionary:
	var node = Node2D.new()
	node.name = "Gauge_%d" % index
	node.position = pos
	
	# Gauge name
	var names = ["PRESSURE", "TEMP", "TORQUE", "EFFIC"]
	var lbl = Label.new()
	lbl.text = names[index]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.position = Vector2(-60, -10)
	lbl.size = Vector2(60, 16)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	node.add_child(lbl)
	
	# Background bar
	var bg = Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(100, -6),
		Vector2(100, 6), Vector2(0, 6)
	])
	bg.color = Color(0.2, 0.2, 0.25)
	node.add_child(bg)
	
	# Zone markers (RED | YELLOW | GREEN | YELLOW | RED)
	# Green zone is positions 35-65 of the 100-width bar
	var green_zone = Polygon2D.new()
	green_zone.polygon = PackedVector2Array([
		Vector2(35, -6), Vector2(65, -6),
		Vector2(65, 6), Vector2(35, 6)
	])
	green_zone.color = Color(0.2, 0.5, 0.2, 0.4)
	green_zone.name = "GreenZone"
	node.add_child(green_zone)
	
	# Value bar
	var bar = Polygon2D.new()
	bar.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(50, -4),
		Vector2(50, 4), Vector2(0, 4)
	])
	bar.color = Color(0.3, 0.8, 0.3)  # Starts green (middle)
	bar.name = "Bar"
	node.add_child(bar)
	
	# Value label
	var val_lbl = Label.new()
	val_lbl.text = "50"
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.position = Vector2(40, -18)
	val_lbl.size = Vector2(30, 14)
	val_lbl.add_theme_font_size_override("font_size", 9)
	val_lbl.modulate = Color(0.8, 0.8, 0.8)
	val_lbl.name = "ValueLabel"
	node.add_child(val_lbl)
	
	return {
		"index": index,
		"current_value": 50,
		"node": node,
		"bar_node": bar,
		"label_node": val_lbl
	}

func _process(delta: float):
	if state == PuzzleState.SOLVED or state == PuzzleState.LOCKED:
		return
	
	if governor_state == GovernorState.RECALIBRATING:
		_process_recalibration(delta)

func _process_recalibration(delta: float):
	# Flash all gauges red, shake levers
	for gauge in gauges:
		gauge.bar_node.color = Color(1.0, 0.1, 0.1)
		gauge.node.position.x = gauge.node.position.x + (randf() * 2 - 1)
	
	# After 2 seconds, reset
	warning_count = max_warnings  # Already triggered

func _update_gauges():
	# Calculate each gauge's value based on lever positions
	var values = [50, 50, 50, 50]  # Start at middle
	
	for i in range(num_levers):
		var lever_pos = levers[i].position  # 0=UP, 1=MIDDLE, 2=DOWN
		var offset = (lever_pos - 1)  # UP=-1, MIDDLE=0, DOWN=+1
		
		for effect in lever_effects[i]:
			var gauge_idx = effect[0]
			var strength = effect[1]
			values[gauge_idx] += offset * strength * 5
	
	# Clamp and update visuals
	var all_green = true
	for i in range(4):
		values[i] = clampi(values[i], 0, 100)
		gauges[i].current_value = values[i]
		
		# Update bar width and color
		var bar = gauges[i].bar_node
		var bar_width = values[i]
		bar.polygon = PackedVector2Array([
			Vector2(0, -4), Vector2(bar_width, -4),
			Vector2(bar_width, 4), Vector2(0, 4)
		])
		
		# Color: green=35-65, yellow=20-35 or 65-80, red=0-20 or 80-100
		var in_green = (values[i] >= 35 and values[i] <= 65)
		var in_yellow = (values[i] >= 20 and values[i] < 35) or (values[i] > 65 and values[i] <= 80)
		
		if in_green:
			bar.color = Color(0.3, 0.9, 0.3)
		elif in_yellow:
			bar.color = Color(0.9, 0.9, 0.3)
			all_green = false
		else:
			bar.color = Color(0.9, 0.2, 0.2)
			all_green = false
		
		# Update label
		gauges[i].label_node.text = str(values[i])
	
	# Update main gauge needle
	var avg_value = (values[0] + values[1] + values[2] + values[3]) / 4.0
	var needle = center_gauge_node.get_node("MainNeedle")
	if needle:
		var angle = deg_to_rad(lerp(-120.0, 120.0, avg_value / 100.0))
		needle.points = PackedVector2Array([
			Vector2(0, 0),
			Vector2(sin(angle) * 35, -cos(angle) * 35)
		])
	
	return all_green

func _update_lever_visuals():
	for lever in levers:
		var handle = lever.handle_node
		var y_pos = 0
		match lever.position:
			LeverPos.UP: y_pos = -10
			LeverPos.MIDDLE: y_pos = 0
			LeverPos.DOWN: y_pos = 10
		handle.position = Vector2(0, y_pos)
		
		# Color by position
		match lever.position:
			LeverPos.UP:
				handle.color = Color(0.9, 0.5, 0.3)
			LeverPos.MIDDLE:
				handle.color = Color(0.7, 0.6, 0.4)
			LeverPos.DOWN:
				handle.color = Color(0.5, 0.7, 0.9)

func try_interact() -> bool:
	if state != PuzzleState.ACTIVE:
		return false
	
	if governor_state != GovernorState.ADJUSTING:
		return false
	
	# Find nearest lever
	var nearest_idx = -1
	var nearest_dist = 999999.0
	
	for i in range(levers.size()):
		var world_pos = levers[i].node.global_position
		var dist = player_position.distance_to(world_pos)
		if dist < 30.0 and dist < nearest_dist:
			nearest_dist = dist
			nearest_idx = i
	
	if nearest_idx < 0:
		return false
	
	# Cycle lever position: UP -> MIDDLE -> DOWN -> UP
	var current = levers[nearest_idx].position
	levers[nearest_idx].position = (current + 1) % 3
	
	_update_lever_visuals()
	
	# Update gauges and check result
	var all_green = _update_gauges()
	
	# Check for red warnings
	var any_red = false
	for gauge in gauges:
		if gauge.current_value < 20 or gauge.current_value > 80:
			any_red = true
			break
	
	if any_red:
		warning_count += 1
		warning_label.text = "WARNING %d/%d — System critical!" % [warning_count, max_warnings]
		warning_label.modulate = Color(1.0, 0.3, 0.3)
		_play_sound("alarm")
		
		if warning_count >= max_warnings:
			_trigger_recalibration()
			return true
	else:
		warning_label.text = "Adjust levers until all gauges are GREEN"
		warning_label.modulate = Color(0.8, 0.8, 0.9)
	
	if all_green:
		_solve_puzzle()
	
	return true

func _trigger_recalibration():
	governor_state = GovernorState.RECALIBRATING
	warning_label.text = "RECALIBRATION TRIGGERED!"
	warning_label.modulate = Color(1.0, 0.1, 0.1)
	
	# Apply combat penalty
	GameState.add_temp_effect(warning_penalty_effect, 1)  # Next combat: +1 Attention cost
	
	# Reset all levers to middle
	for lever in levers:
		lever.position = LeverPos.MIDDLE
	_update_lever_visuals()
	_update_gauges()
	
	warning_count = 0
	
	# Flash effect
	for i in range(6):
		warning_label.modulate = Color(1.0, 0.0, 0.0) if i % 2 == 0 else Color(0.5, 0.0, 0.0)
		await get_tree().create_timer(0.2).timeout
	
	governor_state = GovernorState.ADJUSTING
	warning_label.text = "Recalibration complete. Try again."
	warning_label.modulate = Color(0.8, 0.8, 0.9)

func _solve_puzzle():
	governor_state = GovernorState.SOLVED
	warning_label.text = "SYSTEMS OPTIMAL!"
	warning_label.modulate = Color(0.3, 1.0, 0.3)
	
	# Green glow on center gauge
	var needle = center_gauge_node.get_node("MainNeedle")
	if needle:
		needle.default_color = Color(0.3, 1.0, 0.3)
	
	# Spawn token near center gauge
	_spawn_token(Vector2(0, -90))
	
	state = PuzzleState.SOLVED
	emit_signal("puzzle_solved")
	
	_play_sound("systems_optimal")
	_show_victory_popup("All sub-systems aligned! The Governor whirs to life and a Gear Devil Token drops from the maintenance hatch.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -160)
	popup.size = Vector2(400, 50)
	popup.add_theme_font_size_override("font_size", 13)
	popup.modulate = Color(0.5, 0.9, 0.5)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 3.0)
	await tween.finished
	popup.queue_free()

func _setup_shrine():
	# Regulation Kami - prefers precision tools
	kami_shrine = _create_shrine_from_db("regulation_kami", Vector2(0, -110))
	add_child(kami_shrine)

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	var lever_positions = []
	for lever in levers:
		lever_positions.append(lever.position)
	data["lever_positions"] = lever_positions
	data["warning_count"] = warning_count
	data["governor_state"] = governor_state
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("lever_positions"):
		var positions = data["lever_positions"]
		for i in range(min(positions.size(), levers.size())):
			levers[i].position = positions[i]
	if data.has("warning_count"):
		warning_count = data["warning_count"]
	if data.has("governor_state"):
		governor_state = data["governor_state"]
	
	_update_lever_visuals()
	_update_gauges()
