extends Node

const SAVE_PATH = "user://settings.cfg"

var mouse_sensitivity: float = 0.001
var sound_volume: float = 0.5
var keybindings: Dictionary = {}
var resolution: int = 1
var resolutions = [Vector2i(1280, 720),Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("controls","mouse_sensitivity", mouse_sensitivity)
	config.set_value("sound","sound_volume", sound_volume)
	config.set_value("controls","keybinds", keybindings)
	config.set_value("video","resolution", resolution)
	config.save(SAVE_PATH)
	_apply_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	mouse_sensitivity = config.get_value("controls","mouse_sensitivity", 0.001)
	sound_volume = config.get_value("sound","sound_volume", 0.5)
	keybindings = config.get_value("controls","keybinds", {})
	resolution = config.get_value("video","resolution", 1)
	_apply_settings()

func _apply_settings() ->void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sound_volume))
	DisplayServer.window_set_size(resolutions[resolution])
