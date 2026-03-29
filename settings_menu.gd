extends Control

@onready var sens_slider = $TabContainer/Input/HSlider
@onready var volume_slider = $TabContainer/Sound/HSlider
@onready var option_button = $TabContainer/Video/OptionButton
@onready var save_button = $HBoxContainer/Save
@onready var cancel_button = $HBoxContainer/Cancel
@onready var save_exit_button = $HBoxContainer/SaveExit

func _ready() -> void:
	option_button.add_item("720p", 0)
	option_button.add_item("1080p", 1)
	option_button.add_item("1440p", 2)
	option_button.add_item("4k", 3)
	sens_slider.value = SettingsManager.mouse_sensitivity
	volume_slider.value = SettingsManager.sound_volume
	option_button.selected = SettingsManager.resolution

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
