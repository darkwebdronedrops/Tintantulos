extends Node2D
class_name PlayerAnimator

# PlayerAnimator - Handles all player sprite animations with texture caching
# 4 Stances: borrowed, scream, whisper, undefined
# 5 Actions: idle, walk, cast, hurt, death
# 8 Directions for walk: n, ne, e, se, s, sw, w, nw
# Patched Oct 15 (Zera): always-reparent into BobOffset; play_idle keep-last-frame
# fallback ported from old script via a proper _halted flag (the old frame_timer=999
# hack advanced one extra frame and then kept animating — intent now actually enforced).

var current_stance: String = "borrowed"
var current_action: String = "idle"
var current_direction: String = "s"

var frame_timer: float = 0.0
var frame_interval: float = 0.12
var current_frame: int = 0
var last_loaded_frame: int = -1 # Guard: only load when frame changes
var _halted: bool = false # True when idle fallback kept the last walk frame

# Bobbing offset applied to a child node, NOT the sprite itself
var bob_timer: float = 0.0
const BOB_SPEED: float = 8.0
const BOB_HEIGHT: float = 4.0

var sprite: Sprite2D = null
var bob_node: Node2D = null # Child node that gets bobbed

const FRAME_COUNTS = {
	"idle": 4,
	"walk": 6,
	"cast": 8,
	"hurt": 6,
	"death": 8
}

const SPRITE_BASE = "res://assets/sprites/player/"

# CACHE: path -> Texture2D, loaded once and reused
var _texture_cache: Dictionary = {}

func _ready():
	var parent = get_parent()
	if parent:
		sprite = parent.get_node_or_null("PlayerSprite")
		bob_node = parent.get_node_or_null("BobOffset")

	if not sprite:
		push_error("PlayerAnimator: No PlayerSprite node found!")
		return

	# If no bob node exists, create one as a sibling, then ALWAYS reparent the
	# sprite under it (even if the scene shipped with a pre-made BobOffset).
	if not bob_node:
		bob_node = Node2D.new()
		bob_node.name = "BobOffset"
		if sprite.get_parent():
			sprite.get_parent().add_child(bob_node)
	if sprite.get_parent() != bob_node:
		sprite.reparent(bob_node)

	_load_frame()

func _process(delta: float):
	if _halted:
		return

	var max_frames = FRAME_COUNTS.get(current_action, 1)

	if current_action in ["walk", "cast", "hurt", "death"]:
		frame_timer += delta
		if frame_timer >= frame_interval:
			frame_timer = 0.0
			current_frame = (current_frame + 1) % max_frames
			_load_frame() # Guard inside checks if frame actually changed

	# Bobbing: apply to bob_node offset, never touch sprite.position directly
	if current_action == "walk" and bob_node:
		bob_timer += delta * BOB_SPEED
		bob_node.position.y = sin(bob_timer) * BOB_HEIGHT
	elif bob_node:
		bob_node.position.y = 0.0
		bob_timer = 0.0

func set_state(stance: String, action: String, direction: String = "s"):
	var changed = (current_stance != stance) or (current_action != action) or (current_direction != direction)
	current_stance = stance
	current_action = action
	current_direction = direction
	_halted = false

	if changed:
		current_frame = 0
		frame_timer = 0.0
		last_loaded_frame = -1 # Force reload on state change
		if bob_node:
			bob_node.position.y = 0.0
			bob_timer = 0.0

	_load_frame()

func set_direction(direction: String):
	if current_direction != direction:
		current_direction = direction
		last_loaded_frame = -1 # Force reload on direction change
		_load_frame()

func _load_frame():
	# GUARD: don't reload same frame
	if current_frame == last_loaded_frame:
		return

	last_loaded_frame = current_frame

	if not sprite:
		return

	var path = _build_sprite_path()

	# CACHE HIT
	if _texture_cache.has(path):
		sprite.texture = _texture_cache[path]
		return

	# CACHE MISS: try to load and cache
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			_texture_cache[path] = tex
			sprite.texture = tex
			return

	# FALLBACK 1: frame 0 of this action
	var fallback = _build_sprite_path(0)
	if _texture_cache.has(fallback):
		sprite.texture = _texture_cache[fallback]
		return
	if ResourceLoader.exists(fallback):
		var tex = load(fallback)
		if tex:
			_texture_cache[fallback] = tex
			sprite.texture = tex
			return

	# FALLBACK 2: idle sprite for current stance
	var idle_path = SPRITE_BASE + "player_%s_idle_f0.png" % current_stance
	if _texture_cache.has(idle_path):
		sprite.texture = _texture_cache[idle_path]
		return
	if ResourceLoader.exists(idle_path):
		var tex = load(idle_path)
		if tex:
			_texture_cache[idle_path] = tex
			sprite.texture = tex
			return

	# FALLBACK 3: character_sprite.png
	var char_path = SPRITE_BASE + "character_sprite.png"
	if _texture_cache.has(char_path):
		sprite.texture = _texture_cache[char_path]
		return
	if ResourceLoader.exists(char_path):
		var tex = load(char_path)
		if tex:
			_texture_cache[char_path] = tex
			sprite.texture = tex
			return

	# LAST RESORT: blue circle (only happens if ALL assets are missing)
	sprite.texture = _get_fallback_texture()

func _get_fallback_texture() -> Texture2D:
	if _texture_cache.has("__fallback"):
		return _texture_cache["__fallback"]
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.6, 1.0, 1.0))
	for x in range(64):
		for y in range(64):
			var dx = x - 32
			var dy = y - 32
			if dx * dx + dy * dy > 900:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex = ImageTexture.create_from_image(img)
	_texture_cache["__fallback"] = tex
	return tex

func _build_sprite_path(frame: int = -1) -> String:
	var f = frame if frame >= 0 else current_frame
	if current_action in ["idle", "hurt", "cast", "death"]:
		return SPRITE_BASE + "player_%s_%s_f%d.png" % [current_stance, current_action, f]
	return SPRITE_BASE + "player_%s_walk_%s_f%d.png" % [current_stance, current_direction, f]

func play_idle():
	# Switch to idle action; if no idle sprite exists for this stance, keep the
	# last walk frame and halt (properly — the old frame_timer=999 hack never
	# actually stopped the animation).
	var prev_action = current_action
	set_state(current_stance, "idle", current_direction)

	# Only reload sprite if the idle frame exists; otherwise keep the current frame
	var path = _build_sprite_path()
	if not ResourceLoader.exists(path):
		current_action = prev_action
		_halted = true
		frame_timer = 0.0

func play_walk(direction: String):
	set_state(current_stance, "walk", direction)

func play_cast():
	set_state(current_stance, "cast", current_direction)

func play_hurt():
	set_state(current_stance, "hurt", current_direction)

func play_death():
	set_state(current_stance, "death", current_direction)

func change_stance(new_stance: String):
	if current_stance != new_stance:
		current_stance = new_stance
		last_loaded_frame = -1
		_load_frame()
