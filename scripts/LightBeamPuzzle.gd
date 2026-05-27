extends Node2D
class_name LightBeamPuzzle

# Light Beam Puzzle — The Gearworks Core Mechanic
# 11 rooms, each with a light widget. When a room's puzzle is solved, its
# widget powers on. Player can rotate widgets (hex directions 0-5) from the
# overworld. When a powered widget faces the center (0,0), it emits a beam.
# All 11 beams hitting center simultaneously = optimal boss unlock.
# Any beams hitting center = suboptimal unlock.

signal puzzle_complete
signal widget_changed(room_id: int, powered: bool, aligned: bool)
signal beam_activated(room_id: int)
signal beam_deactivated(room_id: int)

# Widget data for each room
var widgets: Dictionary = {}  # room_id -> WidgetData
const WIDGET_ROOMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

# Visual
const BEAM_COLOR_ACTIVE = Color(1.0, 0.9, 0.3, 0.7)   # Golden
const BEAM_COLOR_INACTIVE = Color(0.3, 0.3, 0.3, 0.2)  # Dim grey
const WIDGET_COLOR_POWERED = Color(0.9, 0.8, 0.4)       # Warm glow
const WIDGET_COLOR_UNPOWERED = Color(0.4, 0.4, 0.45)     # Cold metal

# Beams are drawn as global lines (child of this node, not room)
var beam_lines: Dictionary = {}  # room_id -> Line2D

# Central beam collector
var collector_glow: Polygon2D

var is_complete: bool = false
var required_aligned: int = 11  # Can be reduced for suboptimal unlock

class WidgetData:
	var room_id: int
	var rotation: int = 0  # 0-5 (hex directions)
	var powered: bool = false  # Room puzzle solved → widget powered
	var aligned: bool = false  # Facing center
	var node: Node2D
	
	func _init(rid: int, rot: int = 0):
		room_id = rid
		rotation = rot

func _ready():
	_initialize_widgets()
	_setup_collector_visual()

func _initialize_widgets():
	for room_id in WIDGET_ROOMS:
		var widget = WidgetData.new(room_id, randi() % 6)
		widgets[room_id] = widget

# --- Visual Setup ---

func _setup_collector_visual():
	"""Visual at center (0,0) that shows beam collection state"""
	collector_glow = Polygon2D.new()
	collector_glow.name = "CollectorGlow"
	var pts = PackedVector2Array()
	for i in 12:
		var a = (TAU / 12.0) * i
		var r = 20.0 if i % 2 == 0 else 15.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	collector_glow.polygon = pts
	collector_glow.color = Color(0.3, 0.3, 0.3, 0.5)
	add_child(collector_glow)

func create_widget_visuals(room_nodes: Dictionary):
	"""Create widget nodes inside each room node"""
	for room_id in widgets.keys():
		if room_nodes.has(room_id):
			var room_node = room_nodes[room_id]
			var widget_node = _create_widget_node(widgets[room_id])
			widget_node.position = Vector2(0, -40)  # Above room center
			room_node.add_child(widget_node)
			widgets[room_id].node = widget_node
			update_widget_visual(room_id)
	
	# Create global beam lines (children of this node, not room)
	for room_id in WIDGET_ROOMS:
		var beam = Line2D.new()
		beam.name = "Beam_%d" % room_id
		beam.width = 3
		beam.default_color = BEAM_COLOR_INACTIVE
		beam.visible = false
		beam.z_index = -1  # Behind rooms
		add_child(beam)
		beam_lines[room_id] = beam

func _create_widget_node(widget: WidgetData) -> Node2D:
	var container = Node2D.new()
	container.name = "Widget_%d" % widget.room_id
	
	# Base — crystalline socket
	var socket = Polygon2D.new()
	socket.name = "Socket"
	var pts = PackedVector2Array()
	for i in 6:
		var a = (TAU / 6.0) * i
		pts.append(Vector2(cos(a) * 14, sin(a) * 14))
	socket.polygon = pts
	socket.color = WIDGET_COLOR_UNPOWERED
	container.add_child(socket)
	
	# Crystal prism (rotates to show direction)
	var prism = Polygon2D.new()
	prism.name = "Prism"
	prism.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)
	])
	prism.color = Color(0.5, 0.5, 0.6, 0.6)
	container.add_child(prism)
	
	# Glow halo (visible when powered)
	var halo = Polygon2D.new()
	halo.name = "Halo"
	for i in 16:
		var a = (TAU / 16.0) * i
		var r = 20.0 if i % 2 == 0 else 18.0
		halo.polygon.append(Vector2(cos(a) * r, sin(a) * r))
	halo.color = Color(1.0, 0.9, 0.3, 0.0)  # Starts invisible
	container.add_child(halo)
	
	# Interaction label
	var label = Label.new()
	label.name = "InteractLabel"
	label.text = "[E] Rotate"
	label.position = Vector2(-35, -45)
	label.size = Vector2(70, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.visible = false
	container.add_child(label)
	
	return container

# --- Core Logic ---

func power_widget(room_id: int):
	"""Call when room puzzle is solved — powers the widget"""
	if not widgets.has(room_id):
		return
	
	var widget = widgets[room_id]
	widget.powered = true
	update_widget_visual(room_id)
	print("LightBeamPuzzle: Widget %d powered on" % room_id)

func depower_widget(room_id: int):
	"""Widget loses power (e.g. room reset)"""
	if not widgets.has(room_id):
		return
	
	var widget = widgets[room_id]
	widget.powered = false
	widget.aligned = false
	update_widget_visual(room_id)

func rotate_widget(room_id: int) -> bool:
	"""Rotate widget clockwise by one hex direction. Returns true if rotated."""
	if not widgets.has(room_id):
		return false
	
	var widget = widgets[room_id]
	widget.rotation = (widget.rotation + 1) % 6
	update_widget_visual(room_id)
	
	print("LightBeamPuzzle: Widget %d rotated to %d" % [room_id, widget.rotation])
	return true

func update_widget_visual(room_id: int):
	"""Update widget node and beam line for a room"""
	if not widgets.has(room_id):
		return
	
	var widget = widgets[room_id]
	var room_world_pos = _get_room_world_pos(room_id)
	
	# Calculate alignment (does rotation face center?)
	var to_center = (-room_world_pos).normalized()
	var dir_vec = HexGrid.get_direction_vector(widget.rotation).normalized()
	var dot = dir_vec.dot(to_center)
	widget.aligned = dot > 0.7 and widget.powered  # Must be powered AND facing center
	
	# Update widget node visuals
	if widget.node:
		var socket = widget.node.get_node_or_null("Socket")
		var prism = widget.node.get_node_or_null("Prism")
		var halo = widget.node.get_node_or_null("Halo")
		
		if socket:
			socket.color = WIDGET_COLOR_POWERED if widget.powered else WIDGET_COLOR_UNPOWERED
		
		if prism:
			# Rotate prism to match direction
			var angle = dir_vec.angle() + PI / 2
			prism.rotation = angle
			# Color: bright when aligned, dim when not
			if widget.aligned:
				prism.color = Color(1.0, 0.95, 0.4, 0.9)
			elif widget.powered:
				prism.color = Color(0.7, 0.6, 0.3, 0.6)
			else:
				prism.color = Color(0.4, 0.4, 0.5, 0.4)
		
		if halo:
			var target_alpha = 0.4 if widget.aligned else (0.15 if widget.powered else 0.0)
			var tween = create_tween()
			tween.tween_property(halo, "color:a", target_alpha, 0.3)
	
	# Update beam line (global coordinates)
	var beam = beam_lines.get(room_id)
	if beam:
		if widget.aligned:
			beam.visible = true
			beam.points = PackedVector2Array([room_world_pos, Vector2.ZERO])
			beam.default_color = BEAM_COLOR_ACTIVE
			
			# Thicken beam based on alignment quality
			var quality = clamp((dot - 0.7) / 0.3, 0.0, 1.0)
			beam.width = lerp(2.0, 6.0, quality)
			
			beam_activated.emit(room_id)
		else:
			beam.visible = false
			beam_deactivated.emit(room_id)
	
	widget_changed.emit(room_id, widget.powered, widget.aligned)
	_check_puzzle_complete()

func update_all_widget_visuals(room_positions: Dictionary):
	"""Call after dial rotation — all widgets may need realignment"""
	for room_id in widgets.keys():
		update_widget_visual(room_id)
	
	# Update collector glow intensity
	_update_collector_visual()

func _get_room_world_pos(room_id: int) -> Vector2:
	"""Get world position of a room (needed for global beam drawing)"""
	# This is called from Floor3Controller which knows room positions
	# We can't access rooms directly, so we rely on the widget node's global position
	var widget = widgets.get(room_id)
	if widget and widget.node:
		return widget.node.global_position
	return Vector2.ZERO

func _update_collector_visual():
	"""Center glow brightens as more beams align"""
	var aligned_count = get_aligned_count()
	var t = float(aligned_count) / float(required_aligned)
	
	if collector_glow:
		var tween = create_tween()
		tween.tween_property(collector_glow, "color", Color(
			lerp(0.3, 1.0, t),
			lerp(0.3, 0.9, t),
			lerp(0.3, 0.3, t),
			lerp(0.5, 0.8, t)
		), 0.5)
		
		# Scale pulse
		var target_scale = lerp(1.0, 1.5, t)
		tween.parallel().tween_property(collector_glow, "scale", Vector2(target_scale, target_scale), 0.5)

# --- Completion ---

func _check_puzzle_complete():
	if is_complete:
		return
	
	var aligned_count = get_aligned_count()
	print("LightBeamPuzzle: %d/%d beams aligned" % [aligned_count, widgets.size()])
	
	if aligned_count >= required_aligned:
		is_complete = true
		GameState.crown_cog_unlocked = true
		puzzle_complete.emit()
		print("LightBeamPuzzle: COMPLETE! Crown Cog unlocked!")
		_show_completion_effect()

func _show_completion_effect():
	"""All beams converge — dramatic flash"""
	# Flash all beams white
	for beam in beam_lines.values():
		if beam.visible:
			var tween = create_tween()
			tween.tween_property(beam, "default_color", Color(1.0, 1.0, 1.0, 0.9), 0.3)
			tween.tween_property(beam, "default_color", BEAM_COLOR_ACTIVE, 0.7)
	
	# Collector explosion
	if collector_glow:
		var tween2 = create_tween()
		tween2.tween_property(collector_glow, "scale", Vector2(3.0, 3.0), 0.5)
		tween2.parallel().tween_property(collector_glow, "color:a", 0.0, 1.0)

# --- Queries ---

func get_aligned_count() -> int:
	var count = 0
	for widget in widgets.values():
		if widget.aligned:
			count += 1
	return count

func get_powered_count() -> int:
	var count = 0
	for widget in widgets.values():
		if widget.powered:
			count += 1
	return count

func is_widget_in_room(room_id: int) -> bool:
	return room_id in widgets

func is_widget_powered(room_id: int) -> bool:
	if widgets.has(room_id):
		return widgets[room_id].powered
	return false

func is_widget_aligned(room_id: int) -> bool:
	if widgets.has(room_id):
		return widgets[room_id].aligned
	return false

# --- Interaction ---

func get_interact_prompt(room_id: int) -> String:
	"""Returns interaction prompt for widget in a room"""
	if not widgets.has(room_id):
		return ""
	
	var widget = widgets[room_id]
	if not widget.powered:
		return "[E] Widget (inactive — solve room first)"
	
	if widget.aligned:
		return "[E] Rotate Widget (aligned)"
	
	return "[E] Rotate Widget"

func show_interact_label(room_id: int, visible: bool):
	if widgets.has(room_id) and widgets[room_id].node:
		var label = widgets[room_id].node.get_node_or_null("InteractLabel")
		if label:
			label.visible = visible
			if visible:
				label.text = get_interact_prompt(room_id)

# --- Save / Load ---

func get_save_data() -> Dictionary:
	var data = {
		"is_complete": is_complete,
		"widgets": {}
	}
	for room_id in widgets.keys():
		var w = widgets[room_id]
		data["widgets"][room_id] = {
			"rotation": w.rotation,
			"powered": w.powered,
			"aligned": w.aligned
		}
	return data

func load_save_data(data: Dictionary):
	is_complete = data.get("is_complete", false)
	var widget_data = data.get("widgets", {})
	for room_id_str in widget_data.keys():
		var room_id = int(room_id_str)
		if widgets.has(room_id):
			var wdata = widget_data[room_id_str]
			widgets[room_id].rotation = wdata.get("rotation", 0)
			widgets[room_id].powered = wdata.get("powered", false)
			widgets[room_id].aligned = wdata.get("aligned", false)
			update_widget_visual(room_id)
	
	_update_collector_visual()
