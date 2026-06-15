extends Node

func _ready():
	print("=== DEBUG: Floor1 Tutorial Test ===")
	
	# Reset state
	GameState.is_first_run = true
	print("Set is_first_run = true")
	
	# Load floor scene
	var floor_scene = load("res://scenes/Floor1.tscn")
	var floor = floor_scene.instantiate()
	get_tree().root.call_deferred("add_child", floor)
	
	# Wait for everything to settle
	await get_tree().create_timer(2.0).timeout
	
	print("Root children: ")
	for child in get_tree().root.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	var tutorial = get_tree().root.get_node_or_null("TutorialOverlay")
	if tutorial:
		print("SUCCESS: TutorialOverlay found in root!")
		print("  Visible: ", tutorial.visible)
		print("  Layer: ", tutorial.layer)
	else:
		print("FAIL: TutorialOverlay NOT found in root")
		# Check floor
		var floor_tut = floor.get_node_or_null("TutorialOverlay")
		if floor_tut:
			print("  But found in floor! Visible: ", floor_tut.visible)
		else:
			print("  Not in floor either")
	
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)
