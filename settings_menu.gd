extends Control

const ACTIONS = [ "forward", "back", "left", "right", "interact", "jump", "shoot", "reload", "next_weapon", "prev_weapon", "weapon_1", "weapon_2",]

@onready var action_list = $TabContainer/Input/ScrollContainer/ActionList
@onready var reset_button = $TabContainer/Input/ResetButton
@onready var sens_slider = $TabContainer/Input/HSlider
@onready var volume_slider = $TabContainer/Sound/HSlider
@onready var option_button = $TabContainer/Video/OptionButton
@onready var save_button = $HBoxContainer/Save
@onready var cancel_button = $HBoxContainer/Cancel
@onready var save_exit_button = $HBoxContainer/SaveExit
@onready var length_slider = $TabContainer/Gameplay/HBoxContainer/LengthSlider
@onready var thickness_slider = $TabContainer/Gameplay/HBoxContainer2/ThicknessSlider
@onready var gap_slider = $TabContainer/Gameplay/HBoxContainer3/GapSlider
@onready var color_picker = $TabContainer/Gameplay/HBoxContainer4/ColorPicker
@onready var crosshair_preview = $TabContainer/Gameplay/CrosshairPreview

signal crosshair_updated(length: float, thickness: float, gap: float, color: Color)

var listening_for: String = ""

func load_crosshair_settings(length: float, thickness: float, gap: float, color: Color) -> void:
	length_slider.value = length
	thickness_slider.value = thickness
	gap_slider.value = gap
	color_picker.color = color
	crosshair_preview.update_preview(length, thickness, gap, color)

func _ready() -> void:
	option_button.add_item("720p", 0)
	option_button.add_item("1080p", 1)
	option_button.add_item("1440p", 2)
	option_button.add_item("4k", 3)
	sens_slider.value = SettingsManager.mouse_sensitivity
	volume_slider.value = SettingsManager.sound_volume
	option_button.selected = SettingsManager.resolution
	length_slider.value_changed.connect(_on_preview_control_changed)
	thickness_slider.value_changed.connect(_on_preview_control_changed)
	gap_slider.value_changed.connect(_on_preview_control_changed)
	color_picker.color_changed.connect(_on_preview_control_changed)
	_build_action_list()

func _on_save_pressed() -> void:
	SettingsManager.keybindings = {}
	SettingsManager.mouse_sensitivity = sens_slider.value
	SettingsManager.sound_volume = volume_slider.value
	SettingsManager.resolution = option_button.selected
	SettingsManager.crosshair_color = color_picker.color
	SettingsManager.crosshair_length = length_slider.value
	SettingsManager.crosshair_thickness = thickness_slider.value
	SettingsManager.crosshair_gap = gap_slider.value
	for key in ACTIONS:
		var events = InputMap.action_get_events(key)
		if not events.is_empty():
			var event = events[0]
			if event is InputEventKey:
					var code = event.keycode if event.keycode != 0 else event.physical_keycode
					SettingsManager.keybindings[key] = {"type": "key", "value": code}
			elif event is InputEventMouseButton:
				SettingsManager.keybindings[key] = {"type": "mouse", "value": event.button_index}
	crosshair_updated.emit(length_slider.value, thickness_slider.value, gap_slider.value, color_picker.color)
	SettingsManager.save_settings()

func _on_cancel_pressed() -> void:
	visible = false

func _on_save_exit_pressed() -> void:
	_on_save_pressed()
	visible = false

func _build_action_list() -> void:
	for child in action_list.get_children():
		child.free()
	
	for action in ACTIONS:
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var button = Button.new()
		button.text = _get_binding_label(action)
		button.pressed.connect(_on_remap_pressed.bind(action, button))
		
		hbox.add_child(label)
		hbox.add_child(button)
		action_list.add_child(hbox)

func _get_binding_label(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	
	var event = events[0]
	
	if event is InputEventKey:
		return event.as_text().replace(" (Physical)", "").replace(" - Physical", "")
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   return "Left Click"
			MOUSE_BUTTON_RIGHT:  return "Right Click"
			MOUSE_BUTTON_MIDDLE: return "Middle Click"
			_: return "Mouse %d" % event.button_index
	
	return "Unknown"

func _on_remap_pressed(action: String, button: Button) -> void:
	if listening_for != "":
		_cancel_listening()
	
	listening_for = action
	button.text = "Press a key..."

func _cancel_listening() -> void:
	listening_for = ""
	_build_action_list()

func _input(event: InputEvent) -> void:
	if listening_for == "":
		return
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_cancel_listening()
		return
	
	var valid = false
	if event is InputEventKey and event.pressed and not event.echo:
		valid = true
	if event is InputEventMouseButton and event.pressed:
		valid = true
	
	if not valid:
		return
	
	InputMap.action_erase_events(listening_for)
	InputMap.action_add_event(listening_for, event)
	listening_for = ""
	_build_action_list()
	get_viewport().set_input_as_handled()

func _on_preview_control_changed(_value) -> void:
	crosshair_preview.update_preview(length_slider.value, thickness_slider.value, gap_slider.value, color_picker.color)

func _on_reset_button_pressed() -> void:
	SettingsManager.keybindings = {}
	InputMap.load_from_project_settings()
	_build_action_list()

func _on_crosshair_reset_button_pressed() -> void:
	SettingsManager.crosshair_color = Color.GREEN
	SettingsManager.crosshair_length = 10.0
	SettingsManager.crosshair_thickness = 3.0
	SettingsManager.crosshair_gap = 3.0
	load_crosshair_settings(10.0, 3.0, 3.0, Color.GREEN)
	crosshair_updated.emit(length_slider.value, thickness_slider.value, gap_slider.value, color_picker.color)
	SettingsManager.save_settings()
