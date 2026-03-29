extends CanvasLayer


@onready var points_label = $Control/PointsLabel
@onready var health_label = $Control/HealthBar
@onready var ammo_counter = $Control/VBoxContainer/AmmoCounter
@onready var crosshair = $Control/Crosshair
@onready var wave_label = $Control/WaveLabel
@onready var weapon_name_label = $Control/VBoxContainer/WeaponNameLabel
@onready var settings_menu = $PauseMenu/SettingsMenu
@onready var wave_start_label = $Control/WaveStartLabel

var crosshair_length: float = SettingsManager.crosshair_length
var crosshair_thickness: float = SettingsManager.crosshair_thickness
var crosshair_gap: float = SettingsManager.crosshair_gap
var crosshair_color: Color = SettingsManager.crosshair_color
var _tween: Tween

func update_points(new_points: int):
	points_label.text = "Points: " + str(new_points)

func update_health(new_health: int):
	health_label.text = "HP: " + str(new_health)

func update_weapon_ui(weapon_name: String, current: int, reserve: int):
	weapon_name_label.text = weapon_name
	ammo_counter.text = str(current) + " / " + str(reserve)

func update_wave(new_wave: int):
	wave_label.text = str(new_wave)

func _on_wave_started(new_wave: int):
	update_wave(new_wave)
	wave_start_label.text = "Wave %d" % new_wave
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(wave_start_label, "modulate:a", 1.0, 0.4)
	_tween.tween_interval(1.2)
	_tween.tween_property(wave_start_label, "modulate:a", 0.0, 0.6)

func build_crosshair():
	crosshair.position = crosshair.get_parent().size / 2.0
	var right = ColorRect.new()
	right.size = Vector2(crosshair_length, crosshair_thickness)
	right.position = Vector2(crosshair_gap, -crosshair_thickness / 2.0)
	right.color = crosshair_color
	crosshair.add_child(right)
	var left = ColorRect.new()
	left.size = Vector2(crosshair_length, crosshair_thickness)
	left.position = Vector2(-crosshair_gap - crosshair_length, -crosshair_thickness / 2.0)
	left.color = crosshair_color
	crosshair.add_child(left)
	var up = ColorRect.new()
	up.size = Vector2(crosshair_thickness, crosshair_length)
	up.position = Vector2(-crosshair_thickness / 2.0, -crosshair_gap - crosshair_length)
	up.color = crosshair_color
	crosshair.add_child(up)
	var down = ColorRect.new()
	down.size = Vector2(crosshair_thickness, crosshair_length)
	down.position = Vector2(-crosshair_thickness / 2.0, crosshair_gap)
	down.color = crosshair_color
	crosshair.add_child(down)

func rebuild_crosshair(length: float, thickness: float, gap: float, color: Color) -> void:
	for item in crosshair.get_children():
		item.queue_free()
	crosshair_length = length
	crosshair_thickness = thickness
	crosshair_gap = gap
	crosshair_color = color
	build_crosshair()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$PauseMenu.visible = get_tree().paused

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func _ready():
	wave_start_label.modulate.a = 0.0
	GameManager.points_changed.connect(update_points)
	GameManager.health_changed.connect(update_health)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.weapon_ui_update.connect(update_weapon_ui)
	settings_menu.crosshair_updated.connect(rebuild_crosshair)
	update_points(GameManager.points)
	update_health(GameManager.health)
	_on_wave_started(GameManager.current_wave)
	build_crosshair()

func _on_options_button_pressed() -> void:
	settings_menu.visible = true
	settings_menu.load_crosshair_settings(crosshair_length, crosshair_thickness, crosshair_gap, crosshair_color)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_main_menu_button_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://game_start.tscn")
