extends Node2D
class_name WorldOfferingPickup

# WorldOfferingPickup — A hidden offering placed on the overworld hex map
# Player steps on it → offering added to inventory, pickup despawns

var offering_id: String = "interesting_trash"
var current_hex: Vector2i = Vector2i.ZERO
var visual_node: Node2D = null

signal offering_collected(offering_id: String, hex: Vector2i)

func _ready():
	_create_visual()
	_update_position()

func setup(id: String, hex: Vector2i):
	offering_id = id
	current_hex = hex
	_update_position()

func check_player_collision(player_hex: Vector2i) -> bool:
	"""Returns true if player is on same hex — triggers collection."""
	if current_hex == player_hex:
		_collect()
		return true
	return false

func _collect():
	"""Add offering to player inventory and despawn."""
	var data = GameState.get_offering_data(offering_id)
	var name = data.get("name", offering_id)
	
	if GameState.add_offering(offering_id):
		# Success
		print("WorldOffering: Collected %s at hex %s" % [name, str(current_hex)])
		# Visual feedback could go here (particle, flash)
	else:
		# Inventory full
		print("WorldOffering: Inventory full — %s left behind" % name)
	
	offering_collected.emit(offering_id, current_hex)
	
	# Despawn
	if visual_node:
		visual_node.queue_free()
	queue_free()

func _create_visual():
	visual_node = Node2D.new()
	visual_node.name = "WorldOfferingVisual"
	
	# Get offering sprite
	var data = GameState.get_offering_data(offering_id)
	var sprite_path = data.get("sprite", "")
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		sprite.scale = Vector2(0.6, 0.6)
	else:
		# Fallback: small glowing orb
		var orb = Polygon2D.new()
		orb.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(8, -4),
			Vector2(8, 4), Vector2(0, 10),
			Vector2(-8, 4), Vector2(-8, -4)
		])
		orb.color = Color(0.9, 0.7, 0.2)  # Gold glow
		visual_node.add_child(orb)
		# Don't add the empty sprite
		add_child(visual_node)
		return
	
	visual_node.add_child(sprite)
	
	# Subtle bob animation
	var tween = create_tween().set_loops()
	tween.tween_property(visual_node, "position:y", -5, 1.0)
	tween.tween_property(visual_node, "position:y", 0, 1.0)
	
	add_child(visual_node)

func _update_position():
	var world_pos = HexGrid.hex_to_world(current_hex)
	if visual_node:
		visual_node.position = world_pos
	position = world_pos
