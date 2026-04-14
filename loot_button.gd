extends Area3D

@export_group("Button Config")
@export var points_cost: int = 50
@export_enum("ammo", "health" , "gun") var pickup_type: String = "ammo"
@export var ammo_type: String = "9mm"
@export var ammo_amount: int = 10
@export var health_amount: float = 20
@export var interaction_range: float = 3.0
@export var gun_drop: WeaponData

@onready var label = $Label3D
@onready var sound = $AudioStreamPlayer3D

signal weapon_received(weapon_data: WeaponData)

var player: Node3D = null

func _ready() -> void:
	label.visible = false
	player = get_tree().get_first_node_in_group("player")
	if player:
		weapon_received.connect(player._on_weapon_received)
	update_label()

func update_label(message: String = ""):
	if message != "":
		label.text = message
		return
	var reward_text = ""
	if pickup_type == "ammo":
		reward_text = str(ammo_amount) + " " + ammo_type + " Mag"
	elif pickup_type == "health":
		reward_text = "+" + str(health_amount) + " Health"
	else: 
		if gun_drop == null: reward_text = "???"
		else: reward_text = gun_drop.name
	label.text = "%s\nCost: %d" % [reward_text, points_cost]

func _input(event: InputEvent):
	if not event.is_action_pressed("interact"):
		return
	if player == null:
		return
	if player.global_position.distance_to(global_position) > interaction_range:
		return
	var raycast = player.get_node_or_null("Camera3D/RayCast3D")
	if raycast and raycast.is_colliding() and raycast.get_collider() == self:
		attempt_purchase()

func attempt_purchase():
	if GameManager.points >= points_cost:
		GameManager.update_points(GameManager.points - points_cost)
		if not apply_reward():
			GameManager.update_points(GameManager.points + points_cost)
			flash_error("Gun doesn't use that ammo!")
	else:
		flash_error("Not enough points!")

func apply_reward() -> bool:
	sound.play()
	if pickup_type == "ammo":
		var weapon = player.player_shooter.current_weapon
		if weapon.ammo_type == ammo_type:
			weapon.current_reserve_magazines = min(
				weapon.current_reserve_magazines + ammo_amount,
				weapon.max_reserve_magazines
			)
			player.player_shooter.emit_weapon_stats()
			return true
		return false
	elif pickup_type == "health":
		GameManager.heal(health_amount)
		return true
	else:
		give_gun_to_player()
		return true

func flash_error(msg: String):
	update_label(msg)
	label.modulate = Color.RED
	await get_tree().create_timer(1.5).timeout
	label.modulate = Color.WHITE
	update_label()

func give_gun_to_player():
	var new_weapon = gun_drop.duplicate(true)
	new_weapon.current_ammo = new_weapon.magazine_size
	new_weapon.current_reserve_magazines = new_weapon.max_reserve_magazines
	weapon_received.emit(new_weapon)

func show_info():
	label.visible = true

func hide_info():
	label.visible = false
