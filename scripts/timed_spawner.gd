extends Node3D

@export var enemy_scene: Array[PackedScene] = []

func _ready():
	add_to_group("spawn_point")

func spawn_enemy():
	if GameManager.enemies_alive >= GameManager.spawn_cap:
		return
	if enemy_scene.is_empty():
		return
	GameManager.enemies_to_spawn = max(0, GameManager.enemies_to_spawn - 1)
	var enemy = enemy_scene[int(randi() % enemy_scene.size())].instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.health = GameManager.get_health_per_wave()
	enemy.global_position = global_position
