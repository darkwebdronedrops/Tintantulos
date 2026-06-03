extends Node

# In-scene gameplay test for Floor 1
# Attach this to Floor1 node temporarily, it auto-runs and logs results

@onready var hex_map: HexTileMap = get_parent().get_node("HexTileMap")
@onready var controller = get_parent()
@onready var player = get_parent().get_node_or_null("Player")

var test_results: Array[String] = []
var test_complete: bool = false

func _ready():
	call_deferred("_run_tests")

func _run_tests():
	_log("=== FLOOR 1 GAMEPLAY TEST ===")
	
	# Find player
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if not player:
		_log("FAIL: No player found")
		_finish()
		return
	
	# Test 1: Starting position
	var start_hex = hex_map.world_to_hex(player.global_position)
	_log("[1] START POSITION")
	_log("  Hex: %s" % str(start_hex))
	_log("  Tile: %d (0=floor, 1=wall, 3=void, 4=portal)" % hex_map.get_tile(start_hex))
	
	# Test 2: Walk in each direction
	_log("[2] WALK TESTS")
	var directions = {
		"E":  Vector2i(1, 0),    # East (D key)
		"NE": Vector2i(1, -1),   # Northeast (E key)
		"NW": Vector2i(0, -1),   # Northwest (W key)
		"W":  Vector2i(-1, 0),   # West (A key)
		"SW": Vector2i(-1, 1),   # Southwest (Z key)
		"SE": Vector2i(0, 1),    # Southeast (X key)
	}
	
	for dir_name in directions.keys():
		var offset = directions[dir_name]
		var target = start_hex + offset
		var walkable = hex_map.is_walkable(target)
		var tile = hex_map.get_tile(target)
		_log("  %s: hex=%s walkable=%s tile=%d" % [dir_name, str(target), walkable, tile])
		
		if walkable:
			# Actually move the player
			var old_pos = player.global_position
			player.global_position = hex_map.hex_to_world(target)
			_log("    MOVED to %s" % str(player.global_position))
			# Move back
			player.global_position = old_pos
	
	# Test 3: Path to upper room
	_log("[3] PATH TO UPPER ROOM")
	var upper = hex_map.get_room_center("upper")
	var path = hex_map.find_path(start_hex, upper)
	_log("  Upper center: %s" % str(upper))
	_log("  Path length: %d steps" % path.size())
	
	if path.size() > 0:
		# Walk the full path
		_log("  Walking path...")
		for i in range(path.size()):
			player.global_position = hex_map.hex_to_world(path[i])
			await get_tree().create_timer(0.01).timeout
		_log("  Arrived at upper room center: %s" % str(player.global_position))
		
		# Check room entry
		var current_hex = hex_map.world_to_hex(player.global_position)
		var dist_to_upper = HexTileMap._hex_distance(current_hex, upper)
		_log("  Distance to upper center: %d hexes" % dist_to_upper)
	
	# Test 4: Portal tiles
	_log("[4] PORTAL TILES")
	var portal_count = 0
	for hex in hex_map.grid.keys():
		if hex_map.grid[hex] == hex_map.TILE_PORTAL:
			portal_count += 1
	_log("  Found %d portal tiles" % portal_count)
	
	# Test 5: Combat check
	_log("[5] COMBAT SYSTEM")
	var combat_manager = controller.get_node_or_null("CombatManager")
	if combat_manager:
		_log("  CombatManager: FOUND")
		_log("  Has start_combat: %s" % combat_manager.has_method("start_combat"))
		_log("  Has combat_ended signal: %s" % combat_manager.has_signal("combat_ended"))
	else:
		_log("  CombatManager: NOT FOUND")
	
	# Test 6: Deck
	_log("[6] PLAYER DECK")
	_log("  Deck size: %d cards" % GameState.player_deck.size())
	_log("  First card: %s" % GameState.player_deck[0].card_name if GameState.player_deck.size() > 0 else "  (empty)")
	
	# Test 7: Room data
	_log("[7] ROOM DEFINITIONS")
	if controller.has_method("_enter_room"):
		var room_data = controller.get("room_data") if controller.get("room_data") else {}
		_log("  Rooms: %d" % room_data.size())
		for room_id in room_data.keys():
			var data = room_data[room_id]
			_log("  - %s: encounter=%s" % [room_id, data.get("encounter", "none")])
	
	_log("=== TEST COMPLETE ===")
	_finish()

func _log(msg: String):
	print("[F1-TEST] %s" % msg)
	test_results.append(msg)

func _finish():
	# Save results to file
	var file = FileAccess.open("/tmp/floor1_gameplay_results.txt", FileAccess.WRITE)
	for line in test_results:
		file.store_line(line)
	file.close()
	
	print("[F1-TEST] Results saved to /tmp/floor1_gameplay_results.txt")
	test_complete = true
	
	# Remove self after delay
	await get_tree().create_timer(0.5).timeout
	queue_free()
