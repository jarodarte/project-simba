extends Control

@onready var settings_menu = $SettingsMenu
@onready var play_button =$VBoxContainer/PlayButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_button.pressed.connect(_on_play)

func _on_play():
	GameManager.reset()
	get_tree().change_scene_to_file("res://outside_map.tscn")

func _on_options_button_pressed() -> void:
	settings_menu.visible = true

func _on_quit_button_pressed() -> void:
	get_tree().quit()
