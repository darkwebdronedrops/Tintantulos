func _place_room_enemy(room, container: Node2D, enemy_template_name: String, faction: String):
	"""Place a patrol enemy around the room perimeter."""
	var room_hex = HexGrid.world_to_hex(room.position)
	
	# Find valid patrol hexes around the room (2-3 hexes out)
	var patrol_hexes = []
	for q in range(-3, 4):
		for r in range(-3, 4):
			if abs(q + r) > 3:
				continue
			var hex = room_hex + Vector2i(q, r)
			var dist = HexGrid.hex_distance(room_hex, hex)
			if dist >= 2 and dist <= 3:
				patrol_hexes.append(hex)
	
	if patrol_hexes.is_empty():
		return
	
	# Pick a patrol center
	var patrol_center = patrol_hexes[randi() % patrol_hexes.size()]
	
	# Create enemy
	var enemy = OverworldEnemy.new()
	enemy.name = "RoomEnemy_%d" % room.id
	
	# Get template from database
	var template = RoomEnemyDatabase.get_enemy_template(enemy_template_name)
	var sprite_path = ""
	if template:
		sprite_path = template.sprite_path
	
	enemy.setup(room.id * 100, patrol_center, faction, enemy_template_name, sprite_path)
	
	# Add bounds checking — RoomInteriorBuilder doesn't have access to Floor3Controller's
	# blocked_hexes, so we use a simple distance-from-room check as a fallback
	var max_room_patrol = 4
	enemy.can_move_to = func(hex: Vector2i) -> bool:
		var d = HexGrid.hex_distance(hex, room_hex)
		return d >= 1 and d <= max_room_patrol + 2
	enemy.patrol_radius = max_room_patrol
	
	
	# Connect to Floor3Controller for combat
	# Note: enemy will be added to Floor3Controller's overworld_enemies list
	# by the caller (Floor3Controller) when room is entered
	
	container.add_child(enemy)
	print("RoomInteriorBuilder: Placed enemy %s patrolling room %d" % [enemy_template_name, room.id])