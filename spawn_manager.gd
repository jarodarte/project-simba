extends Node


var spawn_points: Array = []     
var current_index: int = 0      
var enemies_spawned: int = 0       
var enemies_to_spawn: int = 0    

@export var spawn_rate: float = 0.5
@onready var timer = $Timer

func _ready():
	GameManager.wave_started.connect(_start_wave)
	timer.timeout.connect(_spawn_next)
	GameManager.start_wave()  

func _start_wave(_current_wave: int):
	current_index = 0
	spawn_points = get_tree().get_nodes_in_group("spawn_point")
	enemies_spawned = 0
	enemies_to_spawn = GameManager.get_enemies_per_wave()
	timer.wait_time = spawn_rate
	timer.start()

func _spawn_next():
	var point = spawn_points[current_index]
	point.spawn_enemy()
	current_index = (current_index + 1) % spawn_points.size()
	enemies_spawned += 1
	if enemies_spawned == enemies_to_spawn: timer.stop()
