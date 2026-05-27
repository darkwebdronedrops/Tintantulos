extends Trap
class_name GraspingCogTrap

# Grasping Cog Trap
# A giant gear tooth sweeps across a hex corridor, blocking movement and dealing 2d6 damage.
# Trigger: Player steps into affected hex while trap is armed.
# Effect: Immediate 2d6 physical damage + knockback + blocks the hex for 3 seconds.

# Visual: Massive rusted gear tooth emerging from wall/floor, rotating sweep arc

var sweep_direction: Vector2 = Vector2.RIGHT  # Direction of sweep
var sweep_arc_degrees: float = 60.0
var knockback_hexes: int = 1  # How many hexes to push player back

func _ready():
	trap_id = "grasping_cog"
	trap_name = "Grasping Cog"
	description = "A massive gear tooth sweeps the corridor. Dodge or be crushed."
	damage_dice = "2d6"
	damage_flat = 0
	damage_type = "physical"
	blocks_movement = true
	max_triggers = -1
	duration = 0  # Permanent until disarmed
	pushes_to_combat = true
	combat_enemies = ["Gear Pair", "Piston Assembly"]
	super._ready()

func _setup_visuals():
	visual_node = Node2D.new()
	visual_node.name = "GraspingCogVisual"
	
	# Gear tooth sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/trap_grasping_cog.png"):
		sprite.texture = load("res://assets/sprites/puzzles/trap_grasping_cog.png")
		sprite.scale = Vector2(0.8, 0.8)
	else:
		# Fallback: massive gear tooth shape
		var tooth = Polygon2D.new()
		tooth.polygon = PackedVector2Array([
			Vector2(-20, -30), Vector2(20, -30),
			Vector2(25, 30), Vector2(-25, 30)
		])
		tooth.color = Color(0.5, 0.35, 0.3)  # Rusted metal
		visual_node.add_child(tooth)
		
		# Gear hub
		var hub = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 12:
			var a = (TAU / 12.0) * i
			var r = 15.0 if i % 2 == 0 else 10.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		hub.polygon = pts
		hub.color = Color(0.4, 0.3, 0.25)
		visual_node.add_child(hub)
	visual_node.add_child(sprite)
	
	# Warning indicator (hidden until triggered)
	var warning = Label.new()
	warning.name = "WarningLabel"
	warning.text = "⚠ GRASPING COG"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(-50, -50)
	warning.size = Vector2(100, 20)
	warning.add_theme_font_size_override("font_size", 10)
	warning.modulate = Color(0.9, 0.3, 0.1)
	warning.visible = false
	visual_node.add_child(warning)
	warning_label = warning
	
	add_child(visual_node)

func _apply_trap_effect():
	# Deal damage
	_deal_damage()
	
	# Block terrain (affected hexes should already be set by spawner)
	if affected_hexes.size() > 0:
		_modify_terrain(affected_hexes, false)
		# Unblock after 3 seconds
		await get_tree().create_timer(3.0).timeout
		if state != TrapState.DISABLED:
			_modify_terrain(affected_hexes, true)
	
	# Knockback visual + combat push
	_show_sweep_animation()
	
	# Push to combat after brief delay
	await get_tree().create_timer(0.5).timeout
	_force_combat()

func _show_sweep_animation():
	# Rotate and sweep the cog tooth
	if visual_node:
		var tween = create_tween()
		# Rapid sweep arc
		tween.tween_property(visual_node, "rotation_degrees", sweep_arc_degrees, 0.3)
		tween.tween_property(visual_node, "rotation_degrees", 0.0, 0.5)
		
		# Flash warning
		if warning_label:
			warning_label.visible = true
			var tw2 = create_tween()
			tw2.tween_property(warning_label, "modulate:a", 0.0, 1.0)
			tw2.tween_callback(func(): warning_label.visible = false)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween3 = create_tween()
		for i in 8:
			tween3.tween_property(camera, "offset:x", randf() * 10 - 5, 0.05)
		tween3.tween_property(camera, "offset:x", 0, 0.05)

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["affected_hexes"] = affected_hexes
	data["sweep_direction"] = [sweep_direction.x, sweep_direction.y]
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	if data.has("affected_hexes"):
		affected_hexes = data["affected_hexes"]
	if data.has("sweep_direction"):
		var sd = data["sweep_direction"]
		sweep_direction = Vector2(sd[0], sd[1])