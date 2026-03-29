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

var listening_for: String = ""

func _ready() -> void:
	option_button.add_item("720p", 0)
	option_button.add_item("1080p", 1)
	option_button.add_item("1440p", 2)
	option_button.add_item("4k", 3)
	sens_slider.value = SettingsManager.mouse_sensitivity
	volume_slider.value = SettingsManager.sound_volume
	option_button.selected = SettingsManager.resolution
	_build_action_list()

func _on_save_pressed() -> void:
	SettingsManager.mouse_sensitivity = sens_slider.value
	SettingsManager.sound_volume = volume_slider.value
	SettingsManager.resolution = option_button.selected
	SettingsManager.save_settings()

func _on_cancel_pressed() -> void:
	visible = false

func _on_save_exit_pressed() -> void:
	SettingsManager.mouse_sensitivity = sens_slider.value
	SettingsManager.sound_volume = volume_slider.value
	SettingsManager.resolution = option_button.selected
	SettingsManager.save_settings()
	visible = false

func _build_action_list() -> void:
	for child in action_list.get_children():
		child.queue_free()
	
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
