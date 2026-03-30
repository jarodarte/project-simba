extends CharacterBody3D

const SPEED = 4.0
const JUMP_FORCE = 6.0
const GRAVITY_UP = 9.8
const GRAVITY_DOWN = 18.0
const ACCELERATION = 20.0
const FRICTION = 6.0
const COUNTER_STRAFE_DECEL = 16.

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var shoot_timer = $ShootTimer
@onready var weapon_anchor = $Camera3D/GunHolder/WeaponAnchor
@onready var footstep_timer = $FootstepTimer
@onready var footstep_sound = $FootstepSound
@export var weapons: Array[WeaponData] = []
@onready var weapon_sway = $WeaponSway

var tracer_scene = preload("res://bullet_tracer.tscn")
var _is_bursting: bool = false
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
var _spray_index: int = 0
var _spray_reset_timer: float = 0.0
var _current_move_spread: float = 0.0

func spawn_weapon():
	if current_weapon_node:
		current_weapon_node.queue_free()
	if current_weapon and current_weapon.weapon_scene:
		current_weapon_node = current_weapon.weapon_scene.instantiate()
		weapon_anchor.add_child(current_weapon_node)

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
		_spray_index += 1
		_spray_reset_timer = current_weapon.spray_reset_time
		var audio = current_weapon_node.get_node_or_null("ShootSound")
		if audio:
			audio.play()

		emit_weapon_stats()

		var hit = shoot_ray()

		var muzzle = current_weapon_node.get_node_or_null("Muzzle")
		var muzzle_pos = muzzle.global_position if muzzle else camera.global_position
		var end_pos = hit.position if not hit.is_empty() else camera.global_position + get_shot_direction() * 1000.0

		var tracer = tracer_scene.instantiate()
		get_tree().root.add_child(tracer)
		tracer.init(muzzle_pos, end_pos)

		if not hit.is_empty():
			var effect = hit_effect_scene.instantiate()
			get_tree().root.add_child(effect)
			effect.global_position = hit.position
			effect.emitting = true
			if hit.collider and hit.collider.is_in_group("enemy"):
				hit.collider.take_damage(current_weapon.damage, hit)

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
	_spray_index = 0
	_spray_reset_timer = 0.0

	# if weapon was swapped or another reload started during the wait, abort
	if _reload_id != my_reload_id or current_weapon != weapon_at_start:
		return
	# resets the current ammo and depletes the reserve magazines
	current_weapon.current_ammo = current_weapon.magazine_size
	current_weapon.current_reserve_magazines -= 1
	emit_weapon_stats()
	is_reloading = false

func swap_weapon(direction: int):
	if weapons.size() == 0:
		return
	_spray_index = 0
	_spray_reset_timer = 0.0
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

	if event.is_action_pressed("next_weapon"):
		swap_weapon(1)
	if event.is_action_pressed("prev_weapon"):
		swap_weapon(-1)

func _physics_process(delta):

	# shooting process
	if current_weapon and not is_reloading:
		var trying_to_shoot = Input.is_action_pressed("shoot") if current_weapon.is_auto else Input.is_action_just_pressed("shoot")
		if trying_to_shoot and can_shoot and current_weapon.current_ammo > 0:
			fire_gun()

	# jumping process
	if not is_on_floor():
		var gravity = GRAVITY_UP if velocity.y > 0 else GRAVITY_DOWN
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_FORCE

	# movement process
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	var input_dot = horizontal_velocity.dot(Vector2(dir.x, dir.z))
	if input.length() > 0.0:
		if input_dot < 0.0:
			velocity.x = lerp(velocity.x, dir.x * SPEED, COUNTER_STRAFE_DECEL * delta)
			velocity.z = lerp(velocity.z, dir.z * SPEED, COUNTER_STRAFE_DECEL * delta)
		else:
			velocity.x = lerp(velocity.x, dir.x * SPEED, ACCELERATION * delta)
			velocity.z = lerp(velocity.z, dir.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, FRICTION * delta)
		velocity.z = lerp(velocity.z, 0.0, FRICTION * delta)
	move_and_slide()
		
	var speed_ratio = clamp(Vector2(velocity.x, velocity.z).length() / SPEED, 0.0, 1.0)
	var target_spread = current_weapon.move_spread_max * speed_ratio if current_weapon else 0.0
	_current_move_spread = lerp(_current_move_spread, target_spread, 10.0 * delta)
	
	# movement sound fx
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_moving and is_on_floor():
		if footstep_timer.is_stopped(): footstep_timer.start()
	else:
		footstep_timer.stop()

	weapon_sway.update(delta, is_moving, is_on_floor())
	# checks to show information
	check_interaction()

	# spray reset
	if _spray_reset_timer > 0.0:
		_spray_reset_timer -= delta
		if _spray_reset_timer <= 0.0:
			_spray_index = 0

func _on_shoot_timer_timeout():
	can_shoot = true

func reset_gun_state():
	_is_bursting = false
	can_shoot = true
	shoot_timer.stop()
	is_reloading = false
	_reload_id += 1  # cancels any reload

func _random_spread(radius: float) -> Vector2:
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle)) * randf() * radius

func get_shot_direction() -> Vector3:
	var base_dir = -camera.global_transform.basis.z
	var offset_deg := Vector2.ZERO

	if current_weapon.spray_pattern.size() > 0:
		# pattern-based: walk the sequence, clamp at the end
		var idx = min(_spray_index, current_weapon.spray_pattern.size() - 1)
		offset_deg = current_weapon.spray_pattern[idx]
	elif current_weapon.spread_radius > 0.0:
		# random bloom: pick a point inside the spread cone
		offset_deg = _random_spread(current_weapon.spread_radius)

	# movement inaccuracy: scales with horizontal speed
	offset_deg += _random_spread(_current_move_spread)

	# jump penalty: flat spread added when airborne
	if not is_on_floor():
		offset_deg += _random_spread(current_weapon.jump_spread)

	# applies 2d offset to 3d direction
	var right = camera.global_transform.basis.x
	var up = camera.global_transform.basis.y
	var offset_rad = offset_deg * (PI / 180.0)
	return (base_dir + right * offset_rad.x + up * offset_rad.y).normalized()

func shoot_ray() -> Dictionary:
	var origin = camera.global_position
	var direction = get_shot_direction()
	var end = origin + direction * 1000.0

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]

	return space.intersect_ray(query)
