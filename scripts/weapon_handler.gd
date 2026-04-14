extends RefCounted
class_name WeaponHandler

# signals
signal weapon_stats_changed(name, ammo, reserves)

# preloads
var hit_effect_scene = preload("res://scenes/hit_effect.tscn")
var tracer_scene = preload("res://scenes/bullet_tracer.tscn")

# external references
var owner_node: Node3D
var camera: Camera3D
var player: CharacterBody3D
var weapon_anchor: Node3D
var shoot_timer: Timer

# weapon data
var weapons: Array[WeaponData] = []
var runtime_weapons: Array[WeaponData] = []
var current_weapon: WeaponData
var current_weapon_node: Node3D
var weapon_index: int = 0

# state
var can_shoot: bool = true
var is_reloading: bool = false
var _is_bursting: bool = false
var _reload_id: int = 0

# spread
var _spray_index: int = 0
var _spray_reset_timer: float = 0.0
var _current_spread: float = 0.0
var _current_move_spread: float = 0.0


func init(p_owner, p_camera, p_player, p_weapon_anchor, p_shoot_timer, p_weapons):
	owner_node = p_owner
	camera = p_camera
	player = p_player
	weapon_anchor = p_weapon_anchor
	shoot_timer = p_shoot_timer
	weapons = p_weapons
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func fire_gun(is_grounded: bool):
	if current_weapon_node == null:
		return
	if _is_bursting:
		return

	_is_bursting = true
	can_shoot = false

	for i in current_weapon.burst_count:
		if current_weapon.current_ammo <= 0 or is_reloading:
			break

		current_weapon.current_ammo -= 1
		_spray_index += 1
		_current_spread += current_weapon.spread_per_shot
		_spray_reset_timer = current_weapon.spray_reset_time

		var audio = current_weapon_node.get_node_or_null("ShootSound")
		if audio:
			audio.play()

		emit_weapon_stats()

		var muzzle = current_weapon_node.get_node_or_null("Muzzle")
		var muzzle_pos = muzzle.global_position if muzzle else camera.global_position

		for n in current_weapon.pellet_count:
			var shot_dir = get_shot_direction(is_grounded)
			if current_weapon.explosive_data:
				var proj = current_weapon.explosive_scene.instantiate()
				proj.data = current_weapon.explosive_data
				owner_node.get_tree().root.add_child(proj)
				proj.global_position = camera.global_position
				proj.launch(shot_dir, current_weapon.projectile_speed)
			else:
				var hit = shoot_ray(shot_dir)
				var end_pos = hit.position if not hit.is_empty() else camera.global_position + shot_dir * current_weapon.max_range

				var tracer = tracer_scene.instantiate()
				owner_node.get_tree().root.add_child(tracer)
				tracer.init(muzzle_pos, end_pos)

				if not hit.is_empty():
					var effect = hit_effect_scene.instantiate()
					var distance = camera.global_position.distance_to(hit.position)
					var t = clamp(inverse_lerp(current_weapon.min_range, current_weapon.max_range, distance), 0, 1)
					owner_node.get_tree().root.add_child(effect)
					effect.global_position = hit.position
					effect.emitting = true
					if hit.collider and hit.collider.is_in_group("enemy"):
						hit.collider.take_damage(current_weapon.damage * (1.0 - t), hit)

		await owner_node.get_tree().create_timer(current_weapon.burst_delay).timeout
	_is_bursting = false
	shoot_timer.start(current_weapon.fire_rate)

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

	await owner_node.get_tree().create_timer(current_weapon.reload_time).timeout
	_spray_index = 0
	_spray_reset_timer = 0.0

	# if weapon was swapped or another reload started during the wait, abort
	if _reload_id != my_reload_id or current_weapon != weapon_at_start:
		return

	current_weapon.current_ammo = current_weapon.magazine_size
	current_weapon.current_reserve_magazines -= 1
	emit_weapon_stats()
	is_reloading = false

func reset_gun_state():
	_is_bursting = false
	can_shoot = true
	shoot_timer.stop()
	is_reloading = false
	_reload_id += 1

func spawn_weapon():
	if current_weapon_node:
		current_weapon_node.queue_free()
	if current_weapon and current_weapon.weapon_scene:
		current_weapon_node = current_weapon.weapon_scene.instantiate()
		weapon_anchor.add_child(current_weapon_node)

func swap_weapon(direction: int):
	if weapons.size() == 0:
		return
	_spray_index = 0
	_spray_reset_timer = 0.0
	weapon_index = wrap(weapon_index + direction, 0, runtime_weapons.size())
	current_weapon = runtime_weapons[weapon_index]
	spawn_weapon()
	emit_weapon_stats()
	reset_gun_state()

func swap_to_weapon(new_position: int):
	if weapons.size() == 0:
		return
	_spray_index = 0
	_spray_reset_timer = 0.0
	current_weapon = runtime_weapons[new_position]
	spawn_weapon()
	emit_weapon_stats()
	reset_gun_state()

func emit_weapon_stats():
	weapon_stats_changed.emit(
		current_weapon.name,
		current_weapon.current_ammo,
		current_weapon.current_reserve_magazines
	)

func update(delta: float, speed_ratio: float):
	if _spray_reset_timer > 0.0:
		_current_spread = lerp(_current_spread, current_weapon.max_spread_radius, 10 * delta)
		_spray_reset_timer -= delta
	else:
		_current_spread = lerp(_current_spread, current_weapon.spread_radius, 10 * delta)
		_spray_index = 0
	var target_spread = current_weapon.move_spread_max * speed_ratio if current_weapon else 0.0
	_current_move_spread = lerp(_current_move_spread, target_spread, 10.0 * delta)

func update_player_gun(weapon_data: WeaponData):
	if runtime_weapons.size() < 2:
		runtime_weapons.append(weapon_data)
		weapon_index = runtime_weapons.size() - 1
	else:
		runtime_weapons[weapon_index] = weapon_data
	current_weapon = weapon_data
	spawn_weapon()
	reset_gun_state()
	emit_weapon_stats()

func get_shot_direction(is_grounded: bool) -> Vector3:
	var base_dir = -camera.global_transform.basis.z
	var offset_deg := Vector2.ZERO

	if current_weapon.spray_pattern.size() > 0:
		var idx = min(_spray_index, current_weapon.spray_pattern.size() - 1)
		offset_deg = current_weapon.spray_pattern[idx]
	elif current_weapon.spread_radius > 0.0:
		offset_deg = _random_spread(_current_spread)

	offset_deg += _random_spread(_current_move_spread)

	if not is_grounded:
		offset_deg += _random_spread(current_weapon.jump_spread)

	var right = camera.global_transform.basis.x
	var up = camera.global_transform.basis.y
	var offset_rad = offset_deg * (PI / 180.0)
	return (base_dir + right * offset_rad.x + up * offset_rad.y).normalized()

func shoot_ray(direction: Vector3) -> Dictionary:
	var origin = camera.global_position
	var end = origin + direction * 1000.0
	var space = owner_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [player]
	return space.intersect_ray(query)

func _random_spread(radius: float) -> Vector2:
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle)) * randf() * radius

func _on_shoot_timer_timeout():
	can_shoot = true
