extends RoomPuzzle
class_name OilerPuzzle

# The Oiler - Room 11
# Puzzle: Clean and oil specific points on machine to reveal hidden light path
# Mechanic: Interactive oil spots (5-7 points) that must all be maintained
# Token: Inside oil reservoir (visible through sight glass after enough maintenance)
# Shrine: Maintenance Kami - prefers Machine Oil

const OIL_SPOTS_COUNT: int = 5
const OIL_SPOT_RADIUS: float = 20.0

# Puzzle state
var oil_spots: Array[Node2D] = []  # Each spot needs oiling
var spots_oiled: Array[bool] = []  # Track which are done
var oil_can: Node2D  # The oil can player must pick up
var has_oil_can: bool = false
var sight_glass: Node2D  # Oil reservoir sight glass
var sight_glass_cleaned: bool = false

func _ready():
	room_id = 11
	room_name = "The Oiler"
	super._ready()

func _setup_visuals():
	# Main machine (large central engine with multiple components)
	var machine = Node2D.new()
	machine.name = "Machine"
	machine.position = Vector2(0, 0)
	
	# Base machine body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-60, -40), Vector2(60, -40),
		Vector2(60, 40), Vector2(-60, 40)
	])
	body.color = Color(0.5, 0.5, 0.45)
	machine.add_child(body)
	
	# Moving pistons (visual only, animated)
	for i in 3:
		var piston = Polygon2D.new()
		piston.name = "Piston_%d" % i
		piston.polygon = PackedVector2Array([
			Vector2(-8, -15), Vector2(8, -15),
			Vector2(8, 15), Vector2(-8, 15)
		])
		piston.color = Color(0.7, 0.6, 0.4)
		piston.position = Vector2(-30 + (i * 30), -10)
		machine.add_child(piston)
	
	add_child(machine)
	
	# Sight glass (oil reservoir - must clean to see token)
	sight_glass = Node2D.new()
	sight_glass.name = "SightGlass"
	sight_glass.position = Vector2(70, -20)
	
	var glass = Polygon2D.new()
	glass.name = "Glass"
	glass.polygon = PackedVector2Array([
		Vector2(-12, -20), Vector2(12, -20),
		Vector2(12, 20), Vector2(-12, 20)
	])
	glass.color = Color(0.4, 0.3, 0.2, 0.8)  # Dark/brown = dirty
	sight_glass.add_child(glass)
	
	var frame = Line2D.new()
	frame.points = PackedVector2Array([
		Vector2(-12, -20), Vector2(12, -20),
		Vector2(12, 20), Vector2(-12, 20), Vector2(-12, -20)
	])
	frame.width = 2
	frame.default_color = Color(0.7, 0.7, 0.6)
	sight_glass.add_child(frame)
	
	add_child(sight_glass)

func _setup_interactables():
	# Oil spots on machine components
	var spot_positions = [
		Vector2(-40, -30),  # Top-left joint
		Vector2(0, -35),     # Top center
		Vector2(40, -30),   # Top-right joint
		Vector2(-50, 10),    # Left piston base
		Vector2(50, 10),     # Right piston base
	]
	
	for i in OIL_SPOTS_COUNT:
		var spot = _create_oil_spot(i)
		spot.position = spot_positions[i]
		oil_spots.append(spot)
		spots_oiled.append(false)
		interactables.append(spot)
		add_child(spot)
	
	# Oil can (must pick up first)
	oil_can = _create_oil_can()
	oil_can.position = Vector2(-70, 30)
	interactables.append(oil_can)
	add_child(oil_can)
	
	# Sight glass
	interactables.append(sight_glass)

func _create_oil_spot(index: int) -> Node2D:
	var spot = Node2D.new()
	spot.name = "OilSpot_%d" % index
	spot.set_meta("type", "oil_spot")
	spot.set_meta("index", index)
	
	# Base (metal component)
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(6, 6), Vector2(-6, 6)
	])
	base.color = Color(0.5, 0.5, 0.5)
	spot.add_child(base)
	
	# Oil indicator (invisible until oiled)
	var indicator = Polygon2D.new()
	indicator.name = "OilIndicator"
	indicator.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(4, 4), Vector2(-4, 4)
	])
	indicator.color = Color(0.2, 0.2, 0.1, 0.9)  # Dark oil
	indicator.visible = false
	spot.add_child(indicator)
	
	# Dry/dirty indicator
	var dry = Polygon2D.new()
	dry.name = "DryIndicator"
	dry.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3),
		Vector2(3, 3), Vector2(-3, 3)
	])
	dry.color = Color(0.7, 0.6, 0.3)  # Rusty/dry
	spot.add_child(dry)
	
	return spot

func _create_oil_can() -> Node2D:
	var can = Node2D.new()
	can.name = "OilCan"
	can.set_meta("type", "oil_can")
	
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-8, -10), Vector2(8, -10),
		Vector2(8, 10), Vector2(-8, 10)
	])
	poly.color = Color(0.4, 0.4, 0.5)
	can.add_child(poly)
	
	var spout = Line2D.new()
	spout.points = PackedVector2Array([Vector2(8, 0), Vector2(14, -4)])
	spout.width = 3
	spout.default_color = Color(0.7, 0.7, 0.7)
	can.add_child(spout)
	
	return can

func _setup_shrine():
	# Maintenance Kami - prefers Machine Oil
	kami_shrine = _create_shrine_from_db("maintenance_kami", Vector2(0, 60))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _setup_emitter():
	super._setup_emitter()
	light_emitter.position = Vector2(0, -50)  # Top of machine

# --- Interaction Handling ---

func _get_interact_prompt(obj: Node2D) -> String:
	var type = obj.get_meta("type", "")
	match type:
		"oil_spot":
			var idx = obj.get_meta("index")
			if spots_oiled[idx]:
				return "Oiled ✓"
			elif has_oil_can:
				return "Oil Spot"
			else:
				return "Need Oil Can"
		"oil_can":
			if has_oil_can:
				return "Drop Oil Can"
			else:
				return "Pick Up Oil Can"
		_:
			if obj == sight_glass:
				if sight_glass_cleaned:
					return "Sight Glass"
				elif has_oil_can:
					return "Clean Glass"
				else:
					return "Dirty Glass"
			if obj == kami_shrine:
				return "Offer to Kami"
			if obj == gear_devil_token:
				return "Collect Token"
	return "Interact"

func _process_interaction(obj: Node2D):
	var type = obj.get_meta("type", "")
	match type:
		"oil_spot":
			if has_oil_can:
				_oil_spot(obj.get_meta("index"))
		"oil_can":
			_pickup_or_drop_oil_can()
		_:
			if obj == sight_glass and has_oil_can and not sight_glass_cleaned:
				_clean_sight_glass()
			elif obj == gear_devil_token:
				collect_token()

func _pickup_or_drop_oil_can():
	has_oil_can = not has_oil_can
	
	if has_oil_can:
		# Pick up
		interactables.erase(oil_can)
		oil_can.visible = false
		print("OilerPuzzle: Oil can picked up")
	else:
		# Drop
		oil_can.visible = true
		interactables.append(oil_can)
		oil_can.global_position = get_tree().root.get_node("Floor3/Player").global_position + Vector2(10, 10)
		print("OilerPuzzle: Oil can dropped")

func _oil_spot(index: int):
	if spots_oiled[index]:
		return
	
	spots_oiled[index] = true
	
	# Update visual
	var spot = oil_spots[index]
	spot.get_node("DryIndicator").visible = false
	spot.get_node("OilIndicator").visible = true
	
	# Shine effect
	var tween = create_tween()
	spot.get_node("OilIndicator").modulate = Color(1.5, 1.5, 1.0)
	tween.tween_property(spot.get_node("OilIndicator"), "modulate", Color(1.0, 1.0, 1.0), 0.5)
	
	print("OilerPuzzle: Spot %d oiled (%d/%d)" % [index, _oiled_count(), OIL_SPOTS_COUNT])
	
	# Check completion
	if _oiled_count() >= OIL_SPOTS_COUNT:
		_all_spots_oiled()

func _oiled_count() -> int:
	var count = 0
	for oiled in spots_oiled:
		if oiled:
			count += 1
	return count

func _all_spots_oiled():
	print("OilerPuzzle: All spots oiled! Machine running smooth.")
	
	# Animate pistons running smoothly
	for i in 3:
		var piston = get_node("Machine/Piston_%d" % i)
		if piston:
			var tween = create_tween()
			tween.set_loops(3)
			tween.tween_property(piston, "position:y", piston.position.y + 8, 0.2)
			tween.tween_property(piston, "position:y", piston.position.y, 0.2)
	
	# Machine glows healthy
	var machine = get_node("Machine")
	var tween = create_tween()
	tween.tween_property(machine.get_child(0), "color", Color(0.5, 0.55, 0.5), 0.5)
	
	# Clean sight glass to reveal token
	if not sight_glass_cleaned:
		# Prompt player to clean glass
		var hint = Label.new()
		hint.text = "Machine smooth! Check sight glass."
		hint.position = Vector2(-60, -70)
		hint.add_theme_font_size_override("font_size", 10)
		hint.modulate = Color(0.8, 0.9, 0.3)
		add_child(hint)
		
		await get_tree().create_timer(3.0).timeout
		hint.queue_free()

func _clean_sight_glass():
	sight_glass_cleaned = true
	
	# Animate cleaning
	var glass = sight_glass.get_node("Glass")
	var tween = create_tween()
	tween.tween_property(glass, "color", Color(0.3, 0.5, 0.6, 0.4), 1.0)  # Clear blue
	
	print("OilerPuzzle: Sight glass cleaned!")
	
	await get_tree().create_timer(1.0).timeout
	
	# Reveal token inside reservoir
	reveal_token()
	gear_devil_token.position = sight_glass.position
	
	# If all spots are also oiled, solve puzzle
	if _oiled_count() >= OIL_SPOTS_COUNT:
		solve_puzzle()

# --- Override solve to include machine activation ---

func solve_puzzle():
	if state == PuzzleState.SOLVED:
		return
	
	# Ensure all visuals show solved state
	for i in OIL_SPOTS_COUNT:
		if not spots_oiled[i]:
			spots_oiled[i] = true
			oil_spots[i].get_node("DryIndicator").visible = false
			oil_spots[i].get_node("OilIndicator").visible = true
	
	if not sight_glass_cleaned:
		_clean_sight_glass()
	
	super.solve_puzzle()
	
	# Final machine hum effect
	var hum = Label.new()
	hum.text = "MACHINE PURRS"
	hum.position = Vector2(-40, -70)
	hum.add_theme_font_size_override("font_size", 12)
	hum.modulate = Color(0.3, 0.8, 0.4)
	add_child(hum)
	
	await get_tree().create_timer(2.0).timeout
	hum.queue_free()

# --- Reset ---

func reset_puzzle():
	for i in OIL_SPOTS_COUNT:
		spots_oiled[i] = false
		oil_spots[i].get_node("DryIndicator").visible = true
		oil_spots[i].get_node("OilIndicator").visible = false
	
	has_oil_can = false
	oil_can.visible = true
	if not interactables.has(oil_can):
		interactables.append(oil_can)
	
	sight_glass_cleaned = false
	sight_glass.get_node("Glass").color = Color(0.4, 0.3, 0.2, 0.8)
	
	light_emitter.visible = false
	state = PuzzleState.ACTIVE
