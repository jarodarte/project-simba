extends Node3D

const SPEED = 4.0

@export var camera: Camera3D
@export var raycast: RayCast3D
@export var shoot_timer: Timer
@export var weapons: Array[WeaponData] = []
@export var weapon_anchor: Node3D
@export var player: CharacterBody3D
@export var explosives: Array[ExplosiveData] = []

var _is_bursting: bool = false
var current_weapon: WeaponData
var weapon_index: int = 0
var can_shoot: bool = true
var _spray_index: int = 0
var _spray_reset_timer: float = 0.0
var _current_move_spread: float = 0.0
var is_reloading: bool = false
var runtime_weapons: Array[WeaponData] = []
var current_weapon_node: Node3D
var _reload_id: int = 0
var hit_effect_scene = preload("res://hit_effect.tscn")
var tracer_scene = preload("res://bullet_tracer.tscn")
var runtime_explosives: Array[ExplosiveData] = []
var grenade_index: int = 0
var grenade_equipped: bool = false
var current_grenade_data: ExplosiveData = null
var current_grenade_node: Node3D = null
var _cooking: bool = false

func spawn_weapon():
	if current_weapon_node:
		current_weapon_node.queue_free()
	if current_weapon and current_weapon.weapon_scene:
		current_weapon_node = current_weapon.weapon_scene.instantiate()
		weapon_anchor.add_child(current_weapon_node)

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
		_spray_reset_timer = current_weapon.spray_reset_time
		var audio = current_weapon_node.get_node_or_null("ShootSound")
		if audio:
			audio.play()

		emit_weapon_stats()

		var shot_dir = get_shot_direction(is_grounded)
		var hit = shoot_ray(shot_dir)

		var muzzle = current_weapon_node.get_node_or_null("Muzzle")
		var muzzle_pos = muzzle.global_position if muzzle else camera.global_position
		var end_pos = hit.position if not hit.is_empty() else camera.global_position + shot_dir * 1000.0

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
	GameManager.weapon_ui_update.emit(
		current_weapon.name,
		current_weapon.current_ammo,
		current_weapon.current_reserve_magazines
	)
func emit_grenade_stats():
	GameManager.grenade_ui_update.emit(
		current_grenade_data.name,
		current_grenade_data.current_amount
	)
func get_shot_direction(is_grounded: bool) -> Vector3:
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
	if not is_grounded:
		offset_deg += _random_spread(current_weapon.jump_spread)

	# applies 2d offset to 3d direction
	var right = camera.global_transform.basis.x
	var up = camera.global_transform.basis.y
	var offset_rad = offset_deg * (PI / 180.0)
	return (base_dir + right * offset_rad.x + up * offset_rad.y).normalized()

func shoot_ray(direction: Vector3) -> Dictionary:
	var origin = camera.global_position
	var end = origin + direction * 1000.0

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [player]

	return space.intersect_ray(query)

func _random_spread(radius: float) -> Vector2:
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle)) * randf() * radius

func reset_gun_state():
	_is_bursting = false
	can_shoot = true
	shoot_timer.stop()
	is_reloading = false
	_reload_id += 1  # cancels any reload

func _on_shoot_timer_timeout():
	can_shoot = true

func _ready() -> void:
	for weapon in weapons:
		var w = weapon.duplicate(true)
		w.current_ammo = w.magazine_size
		w.current_reserve_magazines = w.max_reserve_magazines
		runtime_weapons.append(w)
	
	if runtime_weapons.size() > 0:
		current_weapon = runtime_weapons[0]
	
	for explosive in explosives:
		var e = explosive.duplicate(true)
		runtime_explosives.append(e)

	if runtime_explosives.size() > 0:
		current_grenade_data = runtime_explosives[0]


	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	if current_weapon:
		spawn_weapon()
		emit_weapon_stats()

func update(delta, speed_ratio: float):
	if _spray_reset_timer > 0.0:
		_spray_reset_timer -= delta
	if _spray_reset_timer <= 0.0:
		_spray_index = 0
	var target_spread = current_weapon.move_spread_max * speed_ratio if current_weapon else 0.0
	_current_move_spread = lerp(_current_move_spread, target_spread, 10.0 * delta)

func equip_grenade() -> void:
	if runtime_explosives.is_empty():
		return
	current_grenade_data = runtime_explosives[grenade_index]
	grenade_equipped = true
	_cooking = false

	if current_weapon_node:
		current_weapon_node.visible = false

	if current_grenade_node:
		current_grenade_node.queue_free()
	current_grenade_node = current_grenade_data.grenade_scene.instantiate()
	current_grenade_node.data = current_grenade_data  # assign before adding to tree
	weapon_anchor.add_child(current_grenade_node)
	emit_grenade_stats()  # emit after data is set

func unequip_grenade() -> void:
	grenade_equipped = false
	_cooking = false

	if current_grenade_node:
		current_grenade_node.queue_free()
		current_grenade_node = null

	if current_weapon_node:
		current_weapon_node.visible = true
	emit_weapon_stats()

func start_cook() -> void:
	if _cooking or current_grenade_node == null  or current_grenade_data.current_amount == 0:
		return
	_cooking = true
	current_grenade_node.start_fuse()

func throw_grenade() -> void:
	if not _cooking or current_grenade_node == null:
		return
	current_grenade_data.current_amount -= 1
	var grenade = current_grenade_node
	current_grenade_node = null          

	weapon_anchor.remove_child(grenade)
	get_tree().root.add_child(grenade)
	grenade.global_position = camera.global_position
	grenade.throw(camera)

	unequip_grenade()
