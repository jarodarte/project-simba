extends Node

var points:  int   = 0
var health: float = 100
var current_wave: int = 0
var enemies_alive: int = 0


signal wave_started(new_wave: int)
signal points_changed(new_points: int)
signal health_changed(new_health: float)
@warning_ignore("unused_signal")
signal weapon_ui_update(gun_name: String, current: int, reserve: int)
@warning_ignore("unused_signal")
signal grenade_ui_update(grenade_name: String, amount: int)

func get_enemies_per_wave() -> int:
	return 5 + (current_wave * 5)

func reset():
	points = 0
	health = 100.0
	current_wave = 0
	enemies_alive = 0

func update_points(amount: int):
	points = amount
	points_changed.emit(points)

func start_wave():
	current_wave += 1
	enemies_alive = get_enemies_per_wave()
	wave_started.emit(current_wave)

func enemy_died():
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive <= 0:
		start_wave()

func heal(amount: float):
	health = min(health + amount, 100)
	health_changed.emit(health)

# Access from anywhere:
# GameManager.add_points(10)
# GameManager.take_damage(25.0)
# GameManager.shoot_gun(1)
