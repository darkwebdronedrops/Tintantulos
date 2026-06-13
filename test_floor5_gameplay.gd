extends SceneTree

# Floor 1 Xvfb Gameplay Test - Fixed version
# Run with: xvfb-run godot --headless --script test_floor5_gameplay.gd

var log_file: FileAccess
var test_passed: int = 0
var test_failed: int = 0

func _init():
	log_file = FileAccess.open("/tmp/floor5_gameplay_test.log", FileAccess.WRITE)
	_log("=== Floor 1 Gameplay Test: %s ===" % Time.get_datetime_string_from_system())
	
	# Wait a frame then run tests
	await create_timer(0.1).timeout
	_run_tests()

func _run_tests():
	var floor_instance: Node = null
	
	# Test 1: Load scene
	_log("\n--- Test: Load Floor5.tscn ---")
	var path = "res://scenes/Floor5.tscn"
	if not FileAccess.file_exists(path):
		_fail("Load scene", "File not found")
	else:
		var scene = load(path)
		if not scene:
			_fail("Load scene", "Failed to load")
		else:
			floor_instance = scene.instantiate()
			if not floor_instance:
				_fail("Load scene", "Failed to instantiate")
			else:
				_pass("Load scene")
	
	# Test 2: Add to tree and build
	_log("\n--- Test: Build Floor ---")
	if floor_instance:
		root.add_child(floor_instance)
		# Wait for deferred _build_floor
		await create_timer(2.0).timeout
		
		# Check hex_map
		var hex_map = floor_instance.get("hex_map")
		if hex_map and hex_map.get("grid"):
			var grid_size = hex_map.grid.size()
			_log("Hex grid: %d tiles" % grid_size)
			if grid_size > 100:
				_pass("Build floor (grid: %d tiles)" % grid_size)
			else:
				_fail("Build floor", "Grid too small: %d" % grid_size)
		else:
			_fail("Build floor", "Hex map not initialized")
			
		# Check player
		var player = floor_instance.get("player_node")
		if player:
			_log("Player at: %s" % str(player.global_position))
			_pass("Player setup")
		else:
			_fail("Player setup", "Player not found")
			
		# Check enemies
		var enemies = floor_instance.get("hex_enemies")
		if enemies:
			_log("Enemies: %d" % enemies.size())
			for e in enemies:
				if is_instance_valid(e):
					_log("  %s at %s" % [e.enemy_name, str(e.hex_pos)])
			if enemies.size() > 0:
				_pass("Enemies spawned")
			else:
				_fail("Enemies", "None spawned")
		else:
			_fail("Enemies", "hex_enemies array missing")
			
		# Check CombatUI
		var combat_ui = floor_instance.get_node_or_null("CombatUI")
		if combat_ui:
			if combat_ui.has_method("setup"):
				_pass("CombatUI has setup()")
			else:
				_fail("CombatUI", "Missing setup()")
		else:
			_fail("CombatUI", "Node not found")
			
		# Check CombatManager
		var combat_mgr = floor_instance.get_node_or_null("CombatManager")
		if combat_mgr:
			if combat_mgr.has_method("start_combat"):
				_pass("CombatManager has start_combat()")
			else:
				_fail("CombatManager", "Missing start_combat()")
		else:
			_fail("CombatManager", "Node not found")
			
		# Test movement
		_log("\n--- Test: Movement ---")
		if player and hex_map:
			var start_hex = hex_map.world_to_hex(player.global_position)
			var moved = false
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var target = start_hex + dir
				if hex_map.is_walkable(target):
					player.global_position = hex_map.hex_to_world(target)
					moved = true
					_log("Moved to: %s" % str(target))
					break
			if moved:
				_pass("Movement")
			else:
				_fail("Movement", "No walkable adjacent hex")
		else:
			_fail("Movement", "Missing player or hex_map")
			
		# Cleanup
		floor_instance.queue_free()
		await create_timer(0.5).timeout
		_pass("Cleanup")
	else:
		_fail("Build floor", "No floor instance to test")
	
	_log("\n=== Results: %d passed, %d failed ===" % [test_passed, test_failed])
	log_file.close()
	quit()

func _log(msg: String):
	print(msg)
	log_file.store_line(msg)
	log_file.flush()

func _pass(test_name: String):
	_log("[PASS] %s" % test_name)
	test_passed += 1

func _fail(test_name: String, details: String = ""):
	_log("[FAIL] %s: %s" % [test_name, details])
	test_failed += 1
