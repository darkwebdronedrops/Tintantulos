extends Node
class_name DebugSpriteLoader

# Debug script to test if room object sprites load correctly

func _ready():
	print("=== DEBUG: Testing sprite loading ===")
	
	var test_sprites = [
		"res://assets/sprites/room_objects/quench_cooling_tank.png",
		"res://assets/sprites/room_objects/spark_furnace.png",
		"res://assets/sprites/room_objects/temper_anvil.png",
		"res://assets/sprites/room_objects/beacon_lift_gear.png",
	]
	
	for path in test_sprites:
		var exists = ResourceLoader.exists(path)
		print("File exists: %s -> %s" % [path, exists])
		
		if exists:
			var tex = load(path)
			if tex:
				print("  -> LOADED: %s (size: %s)" % [path, tex.get_size()])
			else:
				print("  -> FAILED TO LOAD: %s" % path)
		else:
			print("  -> FILE NOT FOUND")
	
	print("=== DEBUG COMPLETE ===")
