extends Node3D

@export var enemy_scene: PackedScene

func _ready():
	add_to_group("spawn_point")

func spawn_enemy():
	if enemy_scene == null:
		return
	var enemy = enemy_scene.instantiate()
	get_tree().root.add_child(enemy)
	enemy.global_position = global_position
