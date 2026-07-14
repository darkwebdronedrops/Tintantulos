extends Node

# Syntax check script - loads all modified scripts to verify compilation
func _ready():
	# Force load autoloads
	var audio = preload("res://scripts/AudioManager.gd").new()
	var carddb = preload("res://scripts/CardDB.gd").new()
	var gs = preload("res://scripts/GameState.gd").new()
	var tm = preload("res://scripts/TutorialManager.gd").new()
	
	# Load modified scripts
	var hex = preload("res://scripts/HexFloor1Controller.gd").new()
	var cm = preload("res://scripts/CombatManager.gd").new()
	var ct = preload("res://scripts/CombatTutorial.gd").new()
	
	print("All scripts loaded successfully!")
	get_tree().quit()
