class_name ElevenLabsAPI
extends RefCounted

# ElevenLabs Sound Effects API wrapper
# https://elevenlabs.io/docs/api-reference/sound-generation

const API_BASE = "https://api.elevenlabs.io/v1"
const SFX_ENDPOINT = "/sound-generation"

var api_key: String = ""
var http: HTTPRequest = null

func _init(key: String = ""):
	api_key = key

func set_api_key(key: String):
	api_key = key

# Generate a sound effect from text prompt
# Returns: AudioStreamMP3 (ready to play) or null on failure
func generate_sfx(prompt: String, duration_seconds: float = -1.0, prompt_influence: float = 0.3) -> AudioStream:
	if api_key.is_empty():
		push_error("ElevenLabsAPI: No API key set!")
		return null
	
	var headers = [
		"Content-Type: application/json",
		"xi-api-key: " + api_key
	]
	
	var body = {
		"text": prompt,
		"prompt_influence": prompt_influence
	}
	
	# If duration specified, add it (0.5 - 22 seconds)
	if duration_seconds > 0:
		body["duration_seconds"] = clampf(duration_seconds, 0.5, 22.0)
	
	var json_body = JSON.stringify(body)
	
	# Create HTTPRequest node for the call
	var http_req = HTTPRequest.new()
	Engine.get_main_loop().current_scene.add_child(http_req)
	
	var url = API_BASE + SFX_ENDPOINT
	var error = http_req.request(url, headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		push_error("ElevenLabsAPI: HTTP request failed to start: %d" % error)
		http_req.queue_free()
		return null
	
	# Wait for response
	var result = await http_req.request_completed
	# result: [result_code, response_code, headers, body]
	
	var response_code = result[1]
	var response_body = result[3]
	
	http_req.queue_free()
	
	if response_code != 200:
		push_error("ElevenLabsAPI: HTTP error %d - %s" % [response_code, response_body.get_string_from_utf8()])
		return null
	
	# Parse MP3 data into AudioStream
	var stream = AudioStreamMP3.new()
	stream.data = response_body
	return stream

# Batch generate multiple SFX and save to files
# sfx_list: Array of { "name": "hit", "prompt": "sword slash impact", "duration": 1.5 }
# save_dir: String path like "res://assets/audio/sfx/"
func batch_generate(sfx_list: Array, save_dir: String) -> Dictionary:
	var results = {}
	
	for sfx_data in sfx_list:
		var name = sfx_data.get("name", "unnamed")
		var prompt = sfx_data.get("prompt", "")
		var duration = sfx_data.get("duration", -1.0)
		
		print("ElevenLabsAPI: Generating '%s' - %s" % [name, prompt])
		
		var stream = await generate_sfx(prompt, duration)
		
		if stream:
			var save_path = save_dir + name + ".mp3"
			var err = ResourceSaver.save(stream, save_path)
			if err == OK:
				results[name] = save_path
				print("ElevenLabsAPI: Saved '%s' to %s" % [name, save_path])
			else:
				push_error("ElevenLabsAPI: Failed to save '%s' - error %d" % [name, err])
				results[name] = null
		else:
			results[name] = null
	
	return results
