extends Trap
class_name RecalibrationTrap

# Recalibration Trap
# Floor spins toward center pit. 3d6 fall damage into gear works.
# Visual: Rotating platform with calibration dials, sparks, center void.
# Can be used as shortcut: intentional fall = lower level access.

var spin_speed: float = 90.0  # degrees per second
var spin_direction: int = 1  # 1 = clockwise, -1 = counter
var center_hex: Vector2i = Vector2i(0, 0)
var is_shortcut: bool = false  # If true, falling here leads to lower level instead of just damage

func _ready():
	trap_id = "recalibration"
	trap_name = "Recalibration"
	description = "The floor spins toward a yawning pit. Hold on, or fall into the gears below."
	damage_dice = "3d6"
	damage_flat = 0
	damage_type = "fall"
	blocks_movement = true
	max_triggers = 1
	duration = 0  # Permanent until disarmed
	pushes_to_combat = true
	combat_enemies = ["Diagnostic Eye", "The Default", "The Cursor"]
	super._ready()

func _setup_visuals():
	visual_node = Node2D.new()
	visual_node.name = "RecalibrationVisual"
	
	# Spinning platform (octagonal)
	var platform = Polygon2D.new()
	platform.name = "Platform"
	var pts = PackedVector2Array()
	for i in 8:
		var a = (TAU / 8.0) * i
		pts.append(Vector2(cos(a) * 50, sin(a) * 50))
	platform.polygon = pts
	platform.color = Color(0.4, 0.4, 0.45)
	visual_node.add_child(platform)
	
	# Center pit (void)
	var pit = Polygon2D.new()
	pit.name = "Pit"
	pit.polygon = PackedVector2Array()
	for i in 16:
		var a = (TAU / 16.0) * i
		pit.polygon.append(Vector2(cos(a) * 20, sin(a) * 20))
	pit.color = Color(0.05, 0.05, 0.05)  # Near-black void
	visual_node.add_child(pit)
	
	# Calibration dials around edge
	for i in 3:
		var dial = Polygon2D.new()
		var a = (TAU / 3.0) * i
		var pos = Vector2(cos(a) * 35, sin(a) * 35)
		dial.polygon = PackedVector2Array([
			pos + Vector2(-5, -5), pos + Vector2(5, -5),
			pos + Vector2(5, 5), pos + Vector2(-5, 5)
		])
		dial.color = Color(0.6, 0.5, 0.3)
		dial.name = "Dial_%d" % i
		visual_node.add_child(dial)
	
	# Sparks (animated)
	for i in 5:
		var spark = Polygon2D.new()
		spark.name = "Spark_%d" % i
		spark.polygon = PackedVector2Array([
			Vector2(-2, -2), Vector2(2, -2),
			Vector2(2, 2), Vector2(-2, 2)
		])
		spark.color = Color(1.0, 0.7, 0.1)
		spark.position = Vector2(randf() * 60 - 30, randf() * 60 - 30)
		spark.visible = false
		visual_node.add_child(spark)
	
	# Sprite fallback
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/trap_recalibration.png"):
		sprite.texture = load("res://assets/sprites/puzzles/trap_recalibration.png")
		sprite.scale = Vector2(0.7, 0.7)
		visual_node.add_child(sprite)
	
	# Warning label
	var warning = Label.new()
	warning.name = "WarningLabel"
	warning.text = "⚠ RECALIBRATION"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(-50, -65)
	warning.size = Vector2(100, 20)
	warning.add_theme_font_size_override("font_size", 10)
	warning.modulate = Color(0.9, 0.5, 0.1)
	warning.visible = false
	visual_node.add_child(warning)
	warning_label = warning
	
	add_child(visual_node)

func trigger_trap():
	super.trigger_trap()
	if warning_label:
		warning_label.visible = true

func _tick(delta: float):
	# Spin the platform
	if visual_node:
		visual_node.rotation_degrees += spin_speed * spin_direction * delta
		
		# Animate sparks
		for i in 5:
			var spark = visual_node.get_node_or_null("Spark_%d" % i)
			if spark:
				spark.visible = randf() < 0.3
				spark.position = Vector2(randf() * 60 - 30, randf() * 60 - 30)
				spark.rotation = randf() * TAU
				spark.scale = Vector2(randf() * 0.5 + 0.5, randf() * 0.5 + 0.5)
	
	# Pull player toward center if they're on affected hex
	# (Floor3Controller handles this via _process checking trap states)

func _apply_trap_effect():
	# Deal massive fall damage
	_deal_damage()
	
	# Show dramatic fall visual
	_show_fall_animation()
	
	# If shortcut, emit signal for level transition
	if is_shortcut:
		# TODO: Connect to level transition system
		print("RECALLIBRATION SHORTCUT: Player fell to lower level!")
	else:
		# Push to combat
		_force_combat()

func _show_fall_animation():
	if visual_node:
		var tween = create_tween()
		# Platform shakes violently
		for i in 12:
			tween.tween_property(visual_node, "position", Vector2(randf() * 8 - 4, randf() * 8 - 4), 0.05)
		tween.tween_property(visual_node, "position", Vector2.ZERO, 0.1)
		
		# Flash red
		tween.tween_property(visual_node, "modulate", Color(1.5, 0.2, 0.2), 0.2)
		tween.tween_property(visual_node, "modulate", Color(1, 1, 1), 0.5)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera:
		var ct = create_tween()
		for i in 10:
			ct.tween_property(camera, "offset", Vector2(randf() * 15 - 7, randf() * 15 - 7), 0.05)
		ct.tween_property(camera, "offset", Vector2.ZERO, 0.1)

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["spin_direction"] = spin_direction
	data["is_shortcut"] = is_shortcut
	data["affected_hexes"] = affected_hexes
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	if data.has("spin_direction"):
		spin_direction = data["spin_direction"]
	if data.has("is_shortcut"):
		is_shortcut = data["is_shortcut"]
	if data.has("affected_hexes"):
		affected_hexes = data["affected_hexes"]
