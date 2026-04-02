extends StaticBody3D

@onready var label = $Label3D
@onready var sound = $AudioStreamPlayer3D
@onready var mesh_instance = $MeshInstance3D
@onready var collision = $CollisionShape3D

@export var weapon_table: Array[WeaponData] = [] 
@export var points_cost: int = 900
@export var interaction_range: float = 3.0
@export var mesh_resource: Mesh

var player: Node3D = null
enum State { IDLE, ROLLED }
var state: State = State.IDLE
var rolled_weapon: WeaponData = null
var reset_timer: SceneTreeTimer = null
var label_locked: bool = false

func _ready() -> void:
	label.visible = false
	update_label()
	player = get_tree().get_first_node_in_group("player")
	if mesh_resource:
		mesh_instance.mesh = mesh_resource
	_build_collision()

func _build_collision() -> void:
	if mesh_instance.mesh == null:
		return
	collision.shape = mesh_instance.mesh.create_trimesh_shape()

func update_label(message: String = ""):
	label.text = message if message != "" else "Mystery Box Cost: " + str(points_cost)

func attempt_purchase():
	if GameManager.points >= points_cost:
		GameManager.update_points(GameManager.points - points_cost)
		apply_reward()
	else:
		flash_error("Not enough points!")

func flash_error(msg: String):
	update_label(msg)
	label.modulate = Color.RED
	await get_tree().create_timer(1.5).timeout
	label.modulate = Color.WHITE
	update_label()

func apply_reward() -> void:
	state = State.ROLLED
	rolled_weapon = weapon_table[randi() % weapon_table.size()]
	label_locked = true  
	label.visible = true  
	sound.play()
	await roll_animation()
	reset_timer = get_tree().create_timer(10.0)
	await reset_timer.timeout
	if state == State.ROLLED:
		update_label()
		state = State.IDLE
	label_locked = false 
	label.visible = false

func give_gun_to_player():
	label_locked = false
	var new_weapon = rolled_weapon.duplicate(true)
	new_weapon.current_ammo = new_weapon.magazine_size
	new_weapon.current_reserve_magazines = new_weapon.max_reserve_magazines
	player.player_shooter.runtime_weapons[player.player_shooter.weapon_index] = new_weapon
	player.player_shooter.current_weapon = new_weapon
	player.player_shooter.spawn_weapon()
	player.player_shooter.reset_gun_state()
	player.player_shooter.emit_weapon_stats()
	hide_info()

func _input(event: InputEvent):
	if not event.is_action_pressed("interact"):
		return
	if player == null:
		return
	if player.global_position.distance_to(global_position) > interaction_range:
		return
	var raycast = player.get_node_or_null("Camera3D/RayCast3D")
	if raycast and raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit == self or hit.get_parent() == self:
			if state == State.IDLE:
				attempt_purchase()
			elif state == State.ROLLED:
				give_gun_to_player()
				state = State.IDLE
				update_label()

func roll_animation() -> void:
	if weapon_table.size() == 0:
		return
	var rolls := 12
	var delay := 0.05
	for i in rolls:
		label.text = weapon_table[randi() % weapon_table.size()].name
		await get_tree().create_timer(delay).timeout
		delay += 0.018
	label.text = rolled_weapon.name

func show_info():
	label.visible = true

func hide_info():
	if not label_locked:
		label.visible = false
