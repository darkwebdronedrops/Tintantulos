extends Node

# ===================================================================
# STEAM INTEGRATION — GodotSteam Wrapper
# ===================================================================
# Handles Steamworks API initialization, user info, and basic features.
# Requires GodotSteam plugin: install via Asset Library or GitHub.
#
# To install:
#   1. Godot Editor → AssetLib → Search "GodotSteam"
#   2. Download and install
#   3. Enable in Project → Project Settings → Plugins
#   4. Replace APP_ID below with your real Steam App ID
# ===================================================================

const APP_ID: int = 480  # 480 = Spacewar (test app). REPLACE WITH YOUR APP ID.

var is_steam_ready: bool = false
var steam_id: int = 0
var steam_name: String = ""
var steam_level: int = 0
var steam_avatar: ImageTexture = null

func _ready():
	_initialize_steam()
	
	# Steam callbacks need to be polled
	if is_steam_ready:
		print("[Steam] Initialized — User: %s (ID: %d)" % [steam_name, steam_id])
	else:
		push_warning("[Steam] Not initialized — running in offline mode")

func _process(_delta: float):
	# Run Steam callbacks every frame
	if is_steam_ready and Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		if steam and steam.has_method("run_callbacks"):
			steam.run_callbacks()

func _initialize_steam() -> void:
	# Check if GodotSteam is available
	if not Engine.has_singleton("Steam"):
		push_warning("[Steam] GodotSteam singleton not found. Install via AssetLib.")
		return
	
	var steam = Engine.get_singleton("Steam")
	
	# Initialize Steam with your App ID
	var init_result = steam.steamInit(false, APP_ID)
	if init_result["status"] != 1:
		push_warning("[Steam] Init failed: %s" % init_result)
		return
	
	is_steam_ready = true
	steam_id = steam.getSteamID()
	steam_name = steam.getPersonaName()
	steam_level = steam.getPlayerSteamLevel()
	
	print("[Steam] Initialized successfully")
	print("[Steam] User: %s | ID: %d | Level: %d" % [steam_name, steam_id, steam_level])

# -------------------------------------------------------------------
# Achievements
# -------------------------------------------------------------------

func set_achievement(achievement_id: String) -> bool:
	if not is_steam_ready:
		push_warning("[Steam] Cannot set achievement — Steam not ready")
		return false
	
	var steam = Engine.get_singleton("Steam")
	var result = steam.setAchievement(achievement_id)
	steam.storeStats()
	
	if result:
		print("[Steam] Achievement unlocked: %s" % achievement_id)
	else:
		push_warning("[Steam] Failed to set achievement: %s" % achievement_id)
	
	return result

func has_achievement(achievement_id: String) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	return steam.getAchievement(achievement_id)["achieved"]

func clear_achievement(achievement_id: String) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	var result = steam.clearAchievement(achievement_id)
	steam.storeStats()
	return result

# -------------------------------------------------------------------
# Stats
# -------------------------------------------------------------------

func set_stat_int(stat_name: String, value: int) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	var result = steam.setStatInt(stat_name, value)
	steam.storeStats()
	return result

func get_stat_int(stat_name: String) -> int:
	if not is_steam_ready:
		return 0
	
	var steam = Engine.get_singleton("Steam")
	return steam.getStatInt(stat_name)

# -------------------------------------------------------------------
# Cloud Save (Steam Remote Storage)
# -------------------------------------------------------------------

func save_to_cloud(filename: String, data: String) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	var result = steam.fileWrite(filename, data.to_utf8_buffer())
	
	if result:
		print("[Steam] Saved to cloud: %s" % filename)
	else:
		push_warning("[Steam] Failed to save to cloud: %s" % filename)
	
	return result

func load_from_cloud(filename: String) -> String:
	if not is_steam_ready:
		return ""
	
	var steam = Engine.get_singleton("Steam")
	var data = steam.fileRead(filename)
	
	if data.is_empty():
		push_warning("[Steam] No cloud save found: %s" % filename)
		return ""
	
	return data.get_string_from_utf8()

func has_cloud_save(filename: String) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	return steam.fileExists(filename)

# -------------------------------------------------------------------
# Rich Presence
# -------------------------------------------------------------------

func set_rich_presence(key: String, value: String) -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	return steam.setRichPresence(key, value)

func clear_rich_presence() -> bool:
	if not is_steam_ready:
		return false
	
	var steam = Engine.get_singleton("Steam")
	return steam.clearRichPresence()

# -------------------------------------------------------------------
# Overlay
# -------------------------------------------------------------------

func open_overlay(url: String = "") -> void:
	if not is_steam_ready:
		return
	
	var steam = Engine.get_singleton("Steam")
	if url.is_empty():
		steam.activateGameOverlay("");
	else:
		steam.activateGameOverlayToWebPage(url)

# -------------------------------------------------------------------
# Graceful Shutdown
# -------------------------------------------------------------------

func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown_steam()

func _shutdown_steam() -> void:
	if is_steam_ready and Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		steam.steamShutdown()
		print("[Steam] Shutdown complete")

# -------------------------------------------------------------------
# Game-Specific Helpers
# -------------------------------------------------------------------

func report_floor_cleared(floor_num: int) -> void:
	set_stat_int("floors_cleared", floor_num)
	match floor_num:
		1: set_achievement("ACH_FLOOR_1")
		2: set_achievement("ACH_FLOOR_2")
		3: set_achievement("ACH_FLOOR_3")
		4: set_achievement("ACH_FLOOR_4")
		5: set_achievement("ACH_FLOOR_5")
		6: set_achievement("ACH_FLOOR_6")
		7: set_achievement("ACH_FLOOR_7")
		8: set_achievement("ACH_FLOOR_8")
		9: set_achievement("ACH_FLOOR_9")
		10: set_achievement("ACH_FLOOR_10")

func report_run_completed(won: bool) -> void:
	if won:
		set_achievement("ACH_VICTORY")
	else:
		set_achievement("ACH_DEFEAT")

func report_card_fused() -> void:
	var count = get_stat_int("cards_fused")
	set_stat_int("cards_fused", count + 1)
	if count + 1 >= 10:
		set_achievement("ACH_ALCHEMIST")

func report_compiler_defeated() -> void:
	set_achievement("ACH_COMPILER_SLAIN")

func report_goblin_king_defeated() -> void:
	set_achievement("ACH_GOBLIN_KING")

func report_dragon_defeated() -> void:
	set_achievement("ACH_DRAGON_SLAIN")
