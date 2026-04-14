extends Control

@onready var end_wave = $VBoxContainer/FinalWaveLabel
@onready var replay_button =$VBoxContainer/ReplayButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	end_wave.text = "You Survived " + str(GameManager.current_wave) + " Waves"
	replay_button.pressed.connect(_on_replay)

func _on_replay():
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/outside_map.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game_start.tscn")
