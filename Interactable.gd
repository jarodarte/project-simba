extends Node3D
class_name Interactable

@export var cost: int
@export var interaction_range: float = 3.0
@onready var label = $Label3D

var player: Node3D = null


signal interacted()

func _ready() -> void:
	label.visible = false
	player = get_tree().get_first_node_in_group("player")

func show_info():
	label.visible = true

func hide_info():
	label.visible = false

func flash_error(msg: String):
	update_label(msg)
	label.modulate = Color.RED
	await get_tree().create_timer(1.5).timeout
	label.modulate = Color.WHITE
	update_label()

func attempt_purchase() -> void:
	if GameManager.points >= cost:
		GameManager.update_points(GameManager.points - cost)
		if not apply_reward():
			GameManager.update_points(GameManager.points + cost)
	else:
		flash_error("Not enough points!")

func apply_reward() -> bool:
	return true # subclasses override

func update_label(message: String = ""):
	if message:
		label.text = message
	else:
		label.text = "PLACEHOLDER"
