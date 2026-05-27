extends Node
# class_name AudioManager — REMOVED: conflicts with autoload singleton

# ===================================================================
# AUDIOMANAGER — Centralized audio system for Tower of Tintantulos
# Autoload singleton. Handles per-floor music, SFX pooling, and volume.
#
# DUMMY-SAFE DESIGN: Every function handles missing files/buses gracefully.
# If a music file is missing, the system logs a warning and continues.
# If audio buses are missing, they are auto-created or fall back to Master.
#
# Usage:
#   AudioManager.play_floor_ambient(1)       # Floor 1 music
#   AudioManager.play_combat(3)              # Floor 3 combat
#   AudioManager.play_boss("gear_devil")     # Boss fight
#   AudioManager.play_special("shop")        # Shop music
#   AudioManager.play_sfx("card_draw")
#   AudioManager.set_volume("music", 0.8)
# ===================================================================

# --- Config ---
const MAX_SFX_STREAMS := 16
const MUSIC_CROSSFADE_TIME := 1.5
const MUSIC_PATH := "res://assets/audio/music/"
const SFX_PATH := "res://assets/audio/sfx/"

# --- Volume State ---
var volumes := {
	"master": 1.0,
	"music": 0.7,
	"sfx": 0.8,
	"ambient": 0.5,
}

# --- Per-Floor Music Map ---
var floor_music := {
	1: { "ambient": "floor1_portal",         "combat": "combat_encounter_v1" },
	2: { "ambient": "floor2_fungal_v2_v2",   "combat": "combat_encounter_v1" },
	3: { "ambient": "floor3_gearworks_v2",   "combat": "combat_encounter_v1", "boss": "boss_general_v2" },
	4: { "ambient": "floor4_bazaar_main_v1", "combat": "combat_encounter_v1" },
	5: { "ambient": "floor5_airship_v1",       "combat": "floor5_airship_v2" },
	6: { "ambient": "floor6_university_v1",   "combat": "combat_encounter_v1" },
	7: { "ambient": "floor7_pact_v1",         "combat": "combat_encounter_v1" },
	8: { "ambient": "floor8_forge_main_v1",   "combat": "combat_encounter_v1", "boss": "floor8_forge_main_v2" },
	9: { "ambient": "floor9_bone_v1",         "combat": "combat_encounter_v1" },
	10: { "ambient": "floor10_dragon_v1",     "combat": "combat_encounter_v2" },
}

# --- Boss Music Map (by encounter key) ---
var boss_music := {
	"gear_devil":     "boss_general_v2",
	"red_dragon":     "boss_final_v1",
	"black_dragon":   "boss_final_v2",
	"gold_dragon":    "combat_encounter_v2",
	"compiler":       "floor8_forge_main_v2",
	"_fallback":      "boss_general_v1",
}

# --- Special Music Map (by context key) ---
var special_music := {
	"shop":           "shop_theme_v2",
	"game_over":      "floor6_university_v2",
	"demon_dean":     "floor7_pact_v2",
	"entis_marr":     "Entis_Marr",
	"credits":        "credits_v2",
	"title":          "main_title",
	"kradnire":        "kradnire_theme_v1",
	"floor4_lower":   "floor4_bazaar_main_v2",
	"floor4_shop_int": "floor4_bazaar_v1",
}

# --- Music State ---
var current_floor_id: int = 0
var current_mode: String = "none"  # "ambient", "combat", "boss", "special"
var _music_players: Array[AudioStreamPlayer] = []  # 0=main, 1=fade_buffer
var _current_music_player: AudioStreamPlayer
var _crossfade_tween: Tween
var _initialized: bool = false
var _pending_play: Dictionary = {}  # Queue play requests before init

# --- SFX Pool ---
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0

# --- Preloaded Streams ---
var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}

# --- Dragon key for Floor 10 ---
var _dragon_key: String = ""

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	call_deferred("_delayed_init")

func _delayed_init():
	# Dummy-safe: don't crash if audio system isn't ready
	if not AudioServer or AudioServer.bus_count == 0:
		push_warning("[AudioManager] AudioServer not ready, retrying in 0.5s")
		await get_tree().create_timer(0.5).timeout
		if not AudioServer or AudioServer.bus_count == 0:
			push_error("[AudioManager] AudioServer unavailable — audio disabled")
			return
	
	_setup_music_players()
	_setup_sfx_pool()
	_setup_buses()
	_load_all_streams()
	apply_volumes()
	_initialized = true
	print("[AudioManager] Initialized successfully")
	
	# Process any pending play requests
	if not _pending_play.is_empty():
		var req = _pending_play.duplicate()
		_pending_play = {}
		match req.get("type", ""):
			"ambient": play_floor_ambient(req.floor_id, req.get("fade", true))
			"combat": play_combat(req.floor_id)
			"boss": play_boss(req.get("boss_key", ""))
			"special": play_special(req.get("key", ""))

# ===================================================================
# MUSIC PLAYER SETUP
# ===================================================================

func _setup_music_players():
	# Create two music players for crossfading
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicPlayer_%d" % i
		player.bus = "Music"
		player.autoplay = false
		add_child(player)
		_music_players.append(player)
	
	_current_music_player = _music_players[0]
	print("[AudioManager] Created music players")

# ===================================================================
# SFX POOL SETUP
# ===================================================================

func _setup_sfx_pool():
	for i in range(MAX_SFX_STREAMS):
		var player = AudioStreamPlayer.new()
		player.name = "SFX_%d" % i
		player.bus = "SFX"
		player.autoplay = false
		add_child(player)
		_sfx_pool.append(player)
	print("[AudioManager] Created SFX pool (%d streams)" % MAX_SFX_STREAMS)

# ===================================================================
# BUS SETUP
# ===================================================================

func _setup_buses():
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		push_error("[AudioManager] Master bus not found!")
		return
	
	# Ensure Music bus exists
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx < 0:
		music_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
		print("[AudioManager] Created audio bus: Music")
	
	# Ensure SFX bus exists
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx < 0:
		sfx_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")
		print("[AudioManager] Created audio bus: SFX")
	
	# Ensure Ambient bus exists
	var ambient_idx = AudioServer.get_bus_index("Ambient")
	if ambient_idx < 0:
		ambient_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(ambient_idx, "Ambient")
		AudioServer.set_bus_send(ambient_idx, "Master")
		print("[AudioManager] Created audio bus: Ambient")

# ===================================================================
# STREAM LOADING
# ===================================================================

func _load_all_streams():
	# Load music streams
	var music_dir = DirAccess.open(MUSIC_PATH)
	if music_dir:
		music_dir.list_dir_begin()
		var file_name = music_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".mp3") or file_name.ends_with(".ogg") or file_name.ends_with(".wav"):
				var key = file_name.get_basename()
				var full_path = MUSIC_PATH + file_name
				if ResourceLoader.exists(full_path):
					_music_streams[key] = load(full_path)
				else:
					push_warning("[AudioManager] Music file not found: %s" % full_path)
			file_name = music_dir.get_next()
		music_dir.list_dir_end()
	else:
		push_warning("[AudioManager] Could not open music directory: %s" % MUSIC_PATH)
	
	# Load SFX streams
	var sfx_dir = DirAccess.open(SFX_PATH)
	if sfx_dir:
		sfx_dir.list_dir_begin()
		var sfx_name = sfx_dir.get_next()
		while sfx_name != "":
			if sfx_name.ends_with(".mp3") or sfx_name.ends_with(".ogg") or sfx_name.ends_with(".wav"):
				var key = sfx_name.get_basename()
				var full_path = SFX_PATH + sfx_name
				if ResourceLoader.exists(full_path):
					_sfx_streams[key] = load(full_path)
				else:
					push_warning("[AudioManager] SFX file not found: %s" % full_path)
			sfx_name = sfx_dir.get_next()
		sfx_dir.list_dir_end()
	else:
		push_warning("[AudioManager] Could not open SFX directory: %s" % SFX_PATH)
	
	print("[AudioManager] Loaded %d music streams, %d SFX streams" % [_music_streams.size(), _sfx_streams.size()])

# ===================================================================
# PUBLIC API — MUSIC PLAYBACK
# ===================================================================

func play_floor_ambient(floor_id: int, fade: bool = true) -> void:
	if not _initialized:
		_pending_play = {"type": "ambient", "floor_id": floor_id, "fade": fade}
		return
	
	current_floor_id = floor_id
	var music_data = floor_music.get(floor_id, {})
	var track_key = music_data.get("ambient", "")
	
	if track_key.is_empty():
		push_warning("[AudioManager] No ambient music for floor %d" % floor_id)
		return
	
	_play_track(track_key, "ambient", fade)

func play_combat(floor_id: int) -> void:
	if not _initialized:
		_pending_play = {"type": "combat", "floor_id": floor_id}
		return
	
	var music_data = floor_music.get(floor_id, {})
	var track_key = music_data.get("combat", "combat_encounter_v1")
	_play_track(track_key, "combat", true)

func play_boss(boss_key: String) -> void:
	if not _initialized:
		_pending_play = {"type": "boss", "boss_key": boss_key}
		return
	
	var track_key = boss_music.get(boss_key, boss_music.get("_fallback", "boss_general_v1"))
	_play_track(track_key, "boss", true)

func play_special(key: String) -> void:
	if not _initialized:
		_pending_play = {"type": "special", "key": key}
		return
	
	var track_key = special_music.get(key, "")
	if track_key.is_empty():
		push_warning("[AudioManager] No special music for key: %s" % key)
		return
	_play_track(track_key, "special", true)

func stop_music() -> void:
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	
	for player in _music_players:
		if is_instance_valid(player) and player.playing:
			player.stop()
	
	current_mode = "none"
	print("[AudioManager] Music stopped")

func return_to_ambient() -> void:
	if current_floor_id > 0 and current_mode != "ambient":
		play_floor_ambient(current_floor_id, true)

# ===================================================================
# PUBLIC API — SFX
# ===================================================================

func play_sfx(sfx_name: String, bus: String = "SFX") -> void:
	if not _initialized:
		return
	
	var stream = _sfx_streams.get(sfx_name, null)
	if not stream:
		# Try loading on-the-fly as fallback
		var full_path = SFX_PATH + sfx_name + ".mp3"
		if ResourceLoader.exists(full_path):
			stream = load(full_path)
			_sfx_streams[sfx_name] = stream
		else:
			# Try other extensions
			for ext in [".ogg", ".wav"]:
				var alt_path = SFX_PATH + sfx_name + ext
				if ResourceLoader.exists(alt_path):
					stream = load(alt_path)
					_sfx_streams[sfx_name] = stream
					break
	
	if not stream:
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return
	
	# Get next available player from pool
	var player = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % MAX_SFX_STREAMS
	
	# Re-parent to requested bus if needed
	if bus != player.bus and AudioServer.get_bus_index(bus) >= 0:
		player.bus = bus
	
	player.stream = stream
	player.play()

func preload_sfx(sfx_names: PackedStringArray) -> void:
	if not _initialized:
		return
	
	for name in sfx_names:
		if _sfx_streams.has(name):
			continue
		
		for ext in [".mp3", ".ogg", ".wav"]:
			var path = SFX_PATH + name + ext
			if ResourceLoader.exists(path):
				_sfx_streams[name] = load(path)
				break

# ===================================================================
# PUBLIC API — VOLUME
# ===================================================================

func set_volume(category: String, value: float) -> void:
	if volumes.has(category):
		volumes[category] = clamp(value, 0.0, 1.0)
		apply_volumes()
		_save_volumes()

func apply_volumes() -> void:
	if not AudioServer:
		return
	
	var master_db = linear_to_db(volumes.master)
	var music_db = linear_to_db(volumes.music * volumes.master)
	var sfx_db = linear_to_db(volumes.sfx * volumes.master)
	var ambient_db = linear_to_db(volumes.ambient * volumes.master)
	
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, master_db)
	
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, music_db)
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, sfx_db)
	
	var ambient_bus = AudioServer.get_bus_index("Ambient")
	if ambient_bus >= 0:
		AudioServer.set_bus_volume_db(ambient_bus, ambient_db)
	
	# Update currently playing music
	for player in _music_players:
		if is_instance_valid(player) and player.playing:
			player.volume_db = music_db

func _save_volumes() -> void:
	# Safe-check: GameState is an autoload that may not exist during test/isolated runs
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("save_audio_settings"):
		gs.save_audio_settings(volumes.duplicate())

func load_volumes(settings: Dictionary) -> void:
	for key in settings.keys():
		if volumes.has(key):
			volumes[key] = clamp(settings[key], 0.0, 1.0)
	apply_volumes()

# ===================================================================
# PUBLIC API — UTILITY / QUERIES
# ===================================================================

func is_music_playing() -> bool:
	return _current_music_player != null and is_instance_valid(_current_music_player) and _current_music_player.playing

func get_current_mode() -> String:
	return current_mode

func get_current_floor() -> int:
	return current_floor_id

func get_boss_key_for_enemy(enemy_name: String) -> String:
	# Map enemy names to boss music keys
	var mapping := {
		"Gear Devil": "gear_devil",
		"The Elemental Core": "compiler",
		"Red Dragon": "red_dragon",
		"Black Dragon": "black_dragon",
		"Gold Dragon": "gold_dragon",
		"Kradnire": "kradnire",
	}
	return mapping.get(enemy_name, "_fallback")

func _get_dragon_key() -> String:
	# For Floor 10: randomly select dragon aspect at start of run
	if _dragon_key.is_empty():
		var aspects = ["red_dragon", "black_dragon", "gold_dragon"]
		aspects.shuffle()
		_dragon_key = aspects[0]
		print("[AudioManager] Dragon aspect selected: %s" % _dragon_key)
	return _dragon_key

# ===================================================================
# INTERNAL — MUSIC TRACK PLAYBACK
# ===================================================================

func _play_track(track_key: String, mode: String, fade: bool) -> void:
	var stream = _music_streams.get(track_key, null)
	if not stream:
		push_warning("[AudioManager] Track not loaded: %s" % track_key)
		return
	
	# Don't restart same track
	if current_mode == mode and _current_music_player and _current_music_player.playing and _current_music_player.stream == stream:
		return
	
	current_mode = mode
	
	if fade and _current_music_player and _current_music_player.playing:
		_crossfade(stream)
	else:
		# Hard switch
		if _crossfade_tween and _crossfade_tween.is_valid():
			_crossfade_tween.kill()
		
		for player in _music_players:
			if player != _current_music_player:
				player.stop()
				player.volume_db = -80.0
		
		_current_music_player.stream = stream
		_current_music_player.volume_db = linear_to_db(volumes.music * volumes.master)
		_current_music_player.play()
		print("[AudioManager] Playing: %s (%s)" % [track_key, mode])

func _crossfade(new_stream: AudioStream) -> void:
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	
	var old_player = _current_music_player
	var new_player_idx = 0 if _music_players[0] == old_player else 1
	var new_player = _music_players[new_player_idx]
	
	_current_music_player = new_player
	
	new_player.stream = new_stream
	new_player.volume_db = -80.0
	new_player.play()
	
	var target_db = linear_to_db(volumes.music * volumes.master)
	
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(old_player, "volume_db", -80.0, MUSIC_CROSSFADE_TIME)
	_crossfade_tween.tween_property(new_player, "volume_db", target_db, MUSIC_CROSSFADE_TIME)
	_crossfade_tween.chain().tween_callback(func():
		old_player.stop()
		old_player.stream = null
	)
	
	print("[AudioManager] Crossfading to new track")
