extends SceneTree

func _initialize():
    var db = preload("res://scripts/CardDB.gd").new()
    db._ready()
    print("Total cards loaded: %d" % db.cards.size())
    
    var factions = ["Aberration", "Construct", "Demon", "Dragon", "Elemental", "Goblin", "Undead", "Universal", "Overlays"]
    for f in factions:
        var count = db.get_cards_by_faction(f).size()
        print("%s: %d" % [f, count])
    
    quit()
