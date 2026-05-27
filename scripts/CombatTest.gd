extends Node

# Test script to simulate playing through combat
# Attach to any node in a scene with CombatManager + CombatUI

var combat_manager: CombatManager
var combat_ui: CombatUI
var turn_count: int = 0
var cards_played_this_turn: int = 0

func _ready():
	# Find combat manager and UI
	combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		combat_manager = get_tree().get_first_node_in_group("combat_manager")
	
	combat_ui = get_node_or_null("CombatUI")
	if not combat_ui:
		combat_ui = get_tree().get_first_node_in_group("combat_ui")
	
	if not combat_manager or not combat_ui:
		print("COMBAT_TEST: CombatManager or CombatUI not found")
		return
	
	print("COMBAT_TEST: Starting combat simulation")
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.turn_started.connect(_on_turn_started)

func _on_combat_started():
	print("COMBAT_TEST: Combat started!")
	turn_count = 0
	cards_played_this_turn = 0

func _on_combat_ended(victory: bool):
	print("COMBAT_TEST: Combat ended! Victory: %s" % victory)
	print("COMBAT_TEST: Final player HP: %d/%d" % [combat_manager.player_hp, combat_manager.player_max_hp])
	print("COMBAT_TEST: Total turns: %d" % turn_count)

func _on_turn_started(is_player: bool):
	print("COMBAT_TEST: Turn %d started - Player: %s" % [turn_count, is_player])
	if is_player:
		cards_played_this_turn = 0
		_play_player_turn()
	else:
		print("COMBAT_TEST: Enemy turn - waiting...")

func _play_player_turn():
	turn_count += 1
	print("COMBAT_TEST: Playing turn %d" % turn_count)
	print("COMBAT_TEST: Hand size: %d, Deck: %d, Discard: %d" % [
		combat_manager.hand.size(),
		combat_manager.deck.size(),
		combat_manager.discard_pile.size()
	])
	print("COMBAT_TEST: Player HP: %d/%d, Attention: %d" % [
		combat_manager.player_hp,
		combat_manager.player_max_hp,
		combat_manager.player_attention
	])
	print("COMBAT_TEST: Enemies: %s" % _get_enemy_status())
	
	# Try to play all affordable cards
	var cards_to_play = []
	for i in range(combat_manager.hand.size()):
		var card = combat_manager.hand[i]
		var cost = card.attention_cost
		if combat_manager.player_attention + cost <= 20:
			cards_to_play.append(i)
			print("COMBAT_TEST: Will play card %d (%s, cost %d)" % [i, card.card_name, cost])
		else:
			print("COMBAT_TEST: Card %d (%s, cost %d) too expensive" % [i, card.card_name, cost])
	
	if cards_to_play.is_empty():
		print("COMBAT_TEST: No affordable cards - ending turn")
		_end_turn.call_deferred()
		return
	
	# Play each card with a small delay
	for card_index in cards_to_play:
		await get_tree().create_timer(0.5).timeout
		if not combat_manager.combat_active:
			print("COMBAT_TEST: Combat ended mid-turn")
			return
		if combat_manager.hand.size() <= card_index:
			print("COMBAT_TEST: Card index %d no longer valid" % card_index)
			continue
		
		var card = combat_manager.hand[card_index]
		var target = _get_first_living_enemy()
		if target < 0:
			print("COMBAT_TEST: No living enemies!")
			break
		
		print("COMBAT_TEST: Playing card %d (%s) on enemy %d" % [card_index, card.card_name, target])
		combat_manager.play_card(card_index, target)
		cards_played_this_turn += 1
	
	await get_tree().create_timer(0.5).timeout
	if combat_manager.combat_active and combat_manager.is_player_turn:
		print("COMBAT_TEST: Ending turn after playing %d cards" % cards_played_this_turn)
		_end_turn.call_deferred()

func _end_turn():
	if combat_manager.combat_active and combat_manager.is_player_turn:
		print("COMBAT_TEST: Calling end_player_turn()")
		combat_manager.end_player_turn()

func _get_first_living_enemy() -> int:
	for i in range(combat_manager.enemies.size()):
		if combat_manager.enemies[i].hp > 0:
			return i
	return -1

func _get_enemy_status() -> String:
	var statuses = []
	for i in range(combat_manager.enemies.size()):
		var e = combat_manager.enemies[i]
		statuses.append("%s %d/%d" % [e.name, e.hp, e.max_hp])
	return ", ".join(statuses)
