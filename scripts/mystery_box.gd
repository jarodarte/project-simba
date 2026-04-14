extends Interactable

@onready var sound = $AudioStreamPlayer3D
@onready var mesh_instance = $MeshInstance3D
@onready var collision = $CollisionShape3D

@export var weapon_table: Array[WeaponData] = [] 

enum State { IDLE, ROLLED }
var state: State = State.IDLE
var rolled_weapon: WeaponData = null
var reset_timer: SceneTreeTimer = null

signal weapon_received(weapon_data: WeaponData)

func _ready() -> void:
	super()
	update_label()
	interacted.connect(attempt_purchase)
	if player:
		weapon_received.connect(player._on_weapon_received)

func update_label(message: String = ""):
	label.text = message if message != "" else "Mystery Box Cost: " + str(cost)

func apply_reward() -> bool:
	state = State.ROLLED
	rolled_weapon = weapon_table[randi() % weapon_table.size()]
	label.visible = true  
	sound.play()
	finish_reward()
	return true

func finish_reward():
	await roll_animation()
	reset_timer = get_tree().create_timer(10.0)
	await reset_timer.timeout
	if state == State.ROLLED:
		update_label()
		state = State.IDLE
	label.visible = false

func give_gun_to_player():
	var new_weapon = rolled_weapon.duplicate(true)
	new_weapon.current_ammo = new_weapon.magazine_size
	new_weapon.current_reserve_magazines = new_weapon.max_reserve_magazines
	weapon_received.emit(new_weapon)
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
				interacted.emit()
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
