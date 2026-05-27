@tool
extends EditorScript

# CardArtImporter - Links card art to card data resources
# Run this from Godot's Script Editor (File > Run)

const CARD_FOLDERS = {
	"Aberration": "res://assets/sprites/cards/Aberration/",
	"Construct": "res://assets/sprites/cards/Construct/",
	"Demon": "res://assets/sprites/cards/Demon/",
	"Dragon": "res://assets/sprites/cards/Dragon/",
	"Elemental": "res://assets/sprites/cards/Elemental/",
	"Goblin": "res://assets/sprites/cards/Goblin/",
	"Undead": "res://assets/sprites/cards/Undead/",
	"Universal": "res://assets/sprites/cards/Universal/"
}

const FRAME_TEXTURES = {
	"Aberration": "res://assets/sprites/cards/aberration_frame.png",
	"Construct": "res://assets/sprites/cards/construct_frame.png",
	"Demon": "res://assets/sprites/cards/demon_frame.png",
	"Dragon": "res://assets/sprites/cards/dragon_frame.png",
	"Elemental": "res://assets/sprites/cards/elemental_frame.png",
	"Goblin": "res://assets/sprites/cards/goblin_frame.png",
	"Undead": "res://assets/sprites/cards/undead_frame.png",
	"Universal": "res://assets/sprites/cards/untyped_frame.png"
}

func _run():
	print("=== Card Art Importer ===")
	
	var card_db = load("res://scripts/CardDB.gd").new()
	
	# Count cards by faction
	var counts = {}
	for faction in CARD_FOLDERS.keys():
		counts[faction] = 0
	
	# Process each faction folder
	for faction in CARD_FOLDERS.keys():
		var folder_path = CARD_FOLDERS[faction]
		var frame_path = FRAME_TEXTURES[faction]
		
		print("\nProcessing %s..." % faction)
		
		var dir = DirAccess.open(folder_path)
		if not dir:
			print("  Warning: Could not open %s" % folder_path)
			continue
		
		dir.list_dir_begin()
		var file = dir.get_next()
		var processed = 0
		
		while file != "":
			if file.ends_with(".png") and not file.ends_with(".import"):
				var card_name = file.get_basename()
				var art_path = folder_path + file
				
				# Try to find matching card data
				var card_data = _find_card_data(faction, card_name)
				if card_data:
					card_data.frame_texture_path = frame_path
					card_data.sprite_texture_path = art_path
					
					# Save the resource
					var err = ResourceSaver.save(card_data, card_data.resource_path)
					if err == OK:
						processed += 1
					else:
						print("  Error saving %s: %d" % [card_name, err])
				else:
					print("  Warning: No card data found for %s" % card_name)
			
			file = dir.get_next()
		
		dir.list_dir_end()
		counts[faction] = processed
		print("  Linked %d cards" % processed)
	
	print("\n=== Import Complete ===")
	for faction in counts.keys():
		print("%s: %d cards" % [faction, counts[faction]])

func _find_card_data(faction: String, card_name: String) -> CardData:
	"""Find card data resource by faction and name"""
	var folder = "res://finished_cards/%s/" % faction
	
	var dir = DirAccess.open(folder)
	if not dir:
		return null
	
	dir.list_dir_begin()
	var file = dir.get_next()
	
	while file != "":
		if file.ends_with(".tres"):
			var path = folder + file
			var card = load(path)
			if card and card is CardData:
				# Match by card_name (case insensitive, underscores to spaces)
				var normalized_card = card.card_name.to_lower().replace(" ", "_")
				var normalized_search = card_name.to_lower().replace(" ", "_")
				
				if normalized_card == normalized_search:
					dir.list_dir_end()
					return card
				
				# Also check if the card name is contained
				if normalized_search in normalized_card or normalized_card in normalized_search:
					dir.list_dir_end()
					return card
		
		file = dir.get_next()
	
	dir.list_dir_end()
	return null