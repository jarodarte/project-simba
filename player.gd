extends CharacterBody3D

const SPEED = 4.0
const JUMP_FORCE = 6.0
const GRAVITY_UP = 9.8
const GRAVITY_DOWN = 18.0

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var flash = $Camera3D/GunHolder/OmniLight3D
@onready var shoot_timer = $ShootTimer
@onready var gun_holder = $Camera3D/GunHolder
@onready var weapon_anchor = $Camera3D/GunHolder/WeaponAnchor
@onready var footstep_timer = $FootstepTimer
@onready var footstep_sound = $FootstepSound
@export var weapons: Array[WeaponData] = []

var current_weapon: WeaponData
var weapon_index: int = 0
var current_lookat = null
var hit_effect_scene = preload("res://hit_effect.tscn")
var pitch: float = 0.0
var can_shoot: bool = true
var is_reloading: bool = false
var runtime_weapons: Array[WeaponData] = []
var current_weapon_node: Node3D
var _reload_id: int = 0

func spawn_weapon():
	if current_weapon_node:
		current_weapon_node.queue_free()
	if current_weapon and current_weapon.weapon_scene:
		current_weapon_node = current_weapon.weapon_scene.instantiate()
		weapon_anchor.add_child(current_weapon_node)

var _is_bursting: bool = false

func fire_gun():
	if current_weapon_node == null:
		return
	if _is_bursting:
		return

	_is_bursting = true
	can_shoot = false

	for i in current_weapon.burst_count:
		if current_weapon.current_ammo <= 0:
			break

		current_weapon.current_ammo -= 1

		var audio = current_weapon_node.get_node_or_null("ShootSound")
		if audio:
			audio.play()

		emit_weapon_stats()
		flash.visible = true
		get_tree().create_timer(0.05).timeout.connect(func(): flash.visible = false)

		if raycast.is_colliding():
			var effect = hit_effect_scene.instantiate()
			get_tree().root.add_child(effect)
			effect.global_position = raycast.get_collision_point()
			effect.emitting = true
			var collider = raycast.get_collider()
			if collider and collider.is_in_group("enemy"):
				collider.take_damage(current_weapon.damage, raycast)
		await get_tree().create_timer(current_weapon.burst_delay).timeout
	_is_bursting = false
	shoot_timer.start(current_weapon.fire_rate)  # cooldown before next burst

func reload():
	if is_reloading:
		return
	if current_weapon.current_ammo >= current_weapon.magazine_size:
		return
	if current_weapon.current_reserve_magazines <= 0:
		return

	is_reloading = true
	_reload_id += 1
	var my_reload_id = _reload_id
	var weapon_at_start = current_weapon

	var reload_audio = current_weapon_node.get_node_or_null("ReloadSound")
	if reload_audio:
		reload_audio.play()
	current_weapon_node.get_node("AnimationPlayer").play("reload")

	await get_tree().create_timer(2.0).timeout

	# if weapon was swapped or another reload started during the wait, abort
	if _reload_id != my_reload_id or current_weapon != weapon_at_start:
		return
	#resets the current ammo and depletes the reserve magazines
	current_weapon.current_ammo = current_weapon.magazine_size
	current_weapon.current_reserve_magazines -= 1
	emit_weapon_stats()
	is_reloading = false

func swap_weapon(direction: int):
	if weapons.size() == 0:
		return
	weapon_index = wrap(weapon_index + direction, 0, weapons.size())
	current_weapon = runtime_weapons[weapon_index]
	spawn_weapon()
	emit_weapon_stats()
	reset_gun_state()

func emit_weapon_stats():
	GameManager.weapon_ui_update.emit(
		current_weapon.name,
		current_weapon.current_ammo,
		current_weapon.current_reserve_magazines
	)

func check_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("show_info"):
			if current_lookat != collider:
				if current_lookat and current_lookat.has_method("hide_info"):
					current_lookat.hide_info()
				current_lookat = collider
				current_lookat.show_info()
		else:
			_clear_current_lookat()
	else:
		_clear_current_lookat()

func _clear_current_lookat():
	if current_lookat:
		if is_instance_valid(current_lookat) and current_lookat.has_method("hide_info"):
			current_lookat.hide_info()
		current_lookat = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	flash.visible = false
	footstep_timer.timeout.connect(footstep_sound.play)

	for weapon in weapons:
		var w = weapon.duplicate(true)
		w.current_ammo = w.magazine_size
		w.current_reserve_magazines = w.max_reserve_magazines
		runtime_weapons.append(w)

	if runtime_weapons.size() > 0:
		current_weapon = runtime_weapons[0]

	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	if current_weapon:
		spawn_weapon()
		emit_weapon_stats()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SettingsManager.mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * SettingsManager.mouse_sensitivity, -PI/2.2, PI/2.2)
		camera.rotation.x = pitch

	if event.is_action_pressed("reload") and not is_reloading:
		reload()

	if event.is_action_pressed("interact") and current_lookat:
		if current_lookat.has_method("interact"):
			current_lookat.interact(self)

	if event.is_action_pressed("next_weapon"):
		swap_weapon(1)
	if event.is_action_pressed("prev_weapon"):
		swap_weapon(-1)

func _physics_process(delta):
	#shooting process
	if current_weapon and not is_reloading:
		var trying_to_shoot = Input.is_action_pressed("shoot") if current_weapon.is_auto else Input.is_action_just_pressed("shoot")
		if trying_to_shoot and can_shoot and current_weapon.current_ammo > 0:
			fire_gun()
	#jumping process
	if not is_on_floor():
		var gravity = GRAVITY_UP if velocity.y > 0 else GRAVITY_DOWN
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_FORCE
	#movement process
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()
	#movement sound fx
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_moving and is_on_floor():
		if footstep_timer.is_stopped(): footstep_timer.start()
	else:
		footstep_timer.stop()
	#checks to show information
	check_interaction()

func _on_shoot_timer_timeout():
	can_shoot = true

func reset_gun_state(): 
	_is_bursting = false
	can_shoot = true
	shoot_timer.stop()
	is_reloading = false
	_reload_id += 1  # cancels any reload
