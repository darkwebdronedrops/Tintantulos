extends Node2D
class_name EnemySpawner

# EnemySpawner — Handles spawning enemies in rooms with proper sprites
# Updated to use RoomEnemyDatabase for thematic enemy compositions

const ENEMY_SPRITES = {
	"Piston Assembly": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png",
	"Clockwork Hound": "res://assets/sprites/enemies/Construct/enemy_clockwork_hound_idle.png",
	"Diagnostic Eye": "res://assets/sprites/enemies/Construct/enemy_diagnostic_eye_idle.png",
	"Gear Pair": "res://assets/sprites/enemies/Construct/enemy_gear_pair_idle.png",
	"The Caldera": "res://assets/sprites/enemies/Elemental/enemy_the_caldera_idle.png",
	"The Bug": "res://assets/sprites/enemies/enemy_the_bug_idle.png",
	"The Lag": "res://assets/sprites/enemies/enemy_the_lag_idle.png",
	"The Echo": "res://assets/sprites/enemies/enemy_the_echo_idle.png",
	"The Loop": "res://assets/sprites/enemies/enemy_the_loop_idle.png",
	"The Cursor": "res://assets/sprites/enemies/enemy_the_cursor_idle.png",
	"The Default": "res://assets/sprites/enemies/enemy_the_default_idle.png",
	"The Collar": "res://assets/sprites/enemies/enemy_the_collar_idle.png",
	"The Contagion": "res://assets/sprites/enemies/enemy_the_contagion_idle.png",
	"The Hollow": "res://assets/sprites/enemies/enemy_the_hollow_idle.png",
	"The Forgotten": "res://assets/sprites/enemies/enemy_the_forgotten_idle.png",
	"The Whisper": "res://assets/sprites/enemies/enemy_the_whisper_idle.png",
	"The Mirror": "res://assets/sprites/enemies/enemy_the_mirror_idle.png",
	"The Duplicate": "res://assets/sprites/enemies/enemy_the_duplicate_idle.png",
	"The Refrain": "res://assets/sprites/enemies/enemy_the_refrain_idle.png",
	"Gear Mother": "res://assets/sprites/enemies/Construct/boss_gear_mother_idle.png",
	"GoblinKingGrimgut": "res://assets/sprites/enemies/Goblin/boss_goblin_king_grimgut_idle.png",
	"Minion": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png"
}

# Spawn positions relative to room center (hex offsets)
const SPAWN_POSITIONS = [
	Vector2i(-2, -1),  # NW
	Vector2i(2, -1),   # NE
	Vector2i(-3, 0),   # W
	Vector2i(3, 0),    # E
	Vector2i(-2, 1),   # SW
	Vector2i(2, 1),    # SE
]

static func spawn_enemies_in_room(room_node: Node2D, enemy_data: Array[CombatManager.EnemyData]) -> Array[Node2D]:
	"""Spawn visual enemy nodes in a room using RoomEnemyDatabase templates."""
	var spawned: Array[Node2D] = []
	
	for i in range(enemy_data.size()):
		if i >= SPAWN_POSITIONS.size():
			break
		
		var enemy = enemy_data[i]
		var enemy_node = _create_enemy_node(enemy, i)
		
		# Position in hex grid around room
		var hex_offset = SPAWN_POSITIONS[i]
		var world_pos = HexGrid.hex_to_world(hex_offset)
		enemy_node.position = world_pos
		
		room_node.add_child(enemy_node)
		spawned.append(enemy_node)
	
	return spawned

static func _create_enemy_node(enemy: CombatManager.EnemyData, index: int) -> Node2D:
	var container = Node2D.new()
	container.name = "Enemy_%d_%s" % [index, enemy.name.replace(" ", "_")]
	
	# Get sprite path — check RoomEnemyDatabase first, then fallback
	var sprite_path = ENEMY_SPRITES.get(enemy.name, "")
	if sprite_path.is_empty():
		# Try to look up via database
		var template = RoomEnemyDatabase.get_enemy_template(enemy.name)
		if template:
			sprite_path = template.sprite_path
	
	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	var texture = null
	if not sprite_path.is_empty():
		texture = load(sprite_path)
	
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(0.8, 0.8)  # Scale down to fit hex
	else:
		# Fallback - colored rectangle
		sprite = _create_fallback_sprite(enemy.name)
	container.add_child(sprite)
	
	# HP bar above enemy
	var hp_bar = _create_hp_bar(enemy.hp, enemy.max_hp)
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(0, -40)
	container.add_child(hp_bar)
	
	# Name label
	var label = Label.new()
	label.name = "NameLabel"
	label.text = enemy.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -60)
	label.size = Vector2(100, 20)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	return container

static func _create_fallback_sprite(enemy_name: String) -> Polygon2D:
	"""Create a colored shape if sprite is missing"""
	var poly = Polygon2D.new()
	
	# Different colors for different enemy types
	var color = Color(0.7, 0.3, 0.3)  # Default red
	if "Boss" in enemy_name or enemy_name.begins_with("The"):
		color = Color(0.9, 0.2, 0.2)  # Boss red
	elif "Minion" in enemy_name or enemy_name == "Piston Assembly":
		color = Color(0.5, 0.5, 0.5)  # Grey minion
	elif "Hound" in enemy_name:
		color = Color(0.6, 0.4, 0.2)  # Bronze hound
	elif "Eye" in enemy_name:
		color = Color(0.2, 0.7, 0.7)  # Cyan eye
	elif "Gear" in enemy_name:
		color = Color(0.8, 0.7, 0.3)  # Gold gear
	
	poly.color = color
	poly.polygon = HexGrid.get_hex_polygon()
	poly.scale = Vector2(0.6, 0.6)
	
	return poly

static func _create_hp_bar(current: int, maximum: int) -> Node2D:
	var container = Node2D.new()
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2)
	bg.size = Vector2(50, 8)
	bg.position = Vector2(-25, -4)
	container.add_child(bg)
	
	# Fill
	var fill = ColorRect.new()
	fill.name = "Fill"
	fill.color = Color(0.9, 0.2, 0.2)
	var percent = float(current) / maximum
	fill.size = Vector2(50 * percent, 8)
	fill.position = Vector2(-25, -4)
	container.add_child(fill)
	
	return container

static func update_enemy_hp(enemy_node: Node2D, current: int, maximum: int):
	"""Update the HP bar of an enemy node"""
	var hp_bar = enemy_node.get_node_or_null("HPBar")
	if hp_bar:
		var fill = hp_bar.get_node_or_null("Fill")
		if fill:
			var percent = float(current) / maximum
			fill.size = Vector2(50 * percent, 8)
			# Change color if low HP
			if percent < 0.3:
				fill.color = Color(0.9, 0.5, 0.1)  # Orange warning
			elif percent < 0.6:
				fill.color = Color(0.9, 0.7, 0.2)  # Yellow caution
			else:
				fill.color = Color(0.9, 0.2, 0.2)  # Red healthy
	
	# Grey out if dead
	if current <= 0:
		enemy_node.modulate = Color(0.3, 0.3, 0.3)
		var sprite = enemy_node.get_node_or_null("Sprite")
		if sprite and sprite is Node2D:
			sprite.rotation = PI / 2  # Fall over
			
	# Flash on damage
	else:
		var tween = enemy_node.create_tween()
		enemy_node.modulate = Color(1.0, 0.3, 0.3)
		tween.tween_property(enemy_node, "modulate", Color(1.0, 1.0, 1.0), 0.3)

static func show_spawn_animation(enemy_nodes: Array[Node2D]):
	"""Play spawn-in animation for newly spawned enemies"""
	for node in enemy_nodes:
		node.scale = Vector2.ZERO
		var tween = node.create_tween()
		tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.4)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
