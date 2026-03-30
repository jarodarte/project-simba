extends Node

const SAVE_PATH = "user://settings.cfg"

var mouse_sensitivity: float = 0.001
var sound_volume: float = 0.5
var keybindings: Dictionary = {}
var resolution: int = 1
var resolutions = [Vector2i(1280, 720),Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
var crosshair_length: float = 10.0
var crosshair_thickness: float = 3.0
var crosshair_gap: float = 3.0
var crosshair_color: Color = Color.GREEN

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("controls","mouse_sensitivity", mouse_sensitivity)
	config.set_value("sound","sound_volume", sound_volume)
	config.set_value("controls","keybinds", keybindings)
	config.set_value("video","resolution", resolution)
	config.set_value("crosshair", "length", crosshair_length)
	config.set_value("crosshair", "thickness", crosshair_thickness)
	config.set_value("crosshair", "gap", crosshair_gap)
	config.set_value("crosshair", "color", crosshair_color)
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
	crosshair_length = config.get_value("crosshair", "length", 10.0)
	crosshair_thickness = config.get_value("crosshair", "thickness", 3.0)
	crosshair_gap = config.get_value("crosshair", "gap", 3.0)
	crosshair_color = config.get_value("crosshair", "color", Color.GREEN)
	_apply_settings()

func _apply_settings() -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sound_volume))
	DisplayServer.window_set_size(resolutions[resolution])
	
	for action in keybindings:
		var value = keybindings[action]
		InputMap.action_erase_events(action)
		
		if value <= 3:  # it's a mouse button (1=left, 2=right, 3=middle)
			var event = InputEventMouseButton.new()
			event.button_index = value
			InputMap.action_add_event(action, event)
		else:  
			var event = InputEventKey.new()
			event.keycode = value
			InputMap.action_add_event(action, event)
