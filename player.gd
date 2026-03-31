extends CharacterBody3D

const SPEED = 4.0
const JUMP_FORCE = 6.0
const GRAVITY_UP = 9.8
const GRAVITY_DOWN = 18.0
const ACCELERATION = 20.0
const FRICTION = 6.0
const COUNTER_STRAFE_DECEL = 16.

@onready var camera = $Camera3D
@onready var footstep_timer = $FootstepTimer
@onready var footstep_sound = $FootstepSound
@onready var weapon_sway = $WeaponSway
@onready var interaction_checker = $InteractionChecker
@onready var player_shooter = $PlayerShooter
@onready var grenade_anchor = $GrenadeAnchor

@export var explosives: Array[ExplosiveData] = []

var current_explosive: ExplosiveData
var cook_elapsed: float = 0.0
var is_cooking: bool = false
var pitch: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	footstep_timer.timeout.connect(footstep_sound.play)
	if explosives.size() > 0:
		current_explosive = explosives[0].duplicate()
		emit_grenade_stats()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SettingsManager.mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * SettingsManager.mouse_sensitivity, -PI/2.2, PI/2.2)
		camera.rotation.x = pitch

	if event.is_action_pressed("reload") and not player_shooter.is_reloading:
		player_shooter.reload()
	
	if event.is_action_pressed("next_weapon"):
		player_shooter.swap_weapon(1)
	if event.is_action_pressed("prev_weapon"):
		player_shooter.swap_weapon(-1)

func _physics_process(delta):

	# shooting process
	if player_shooter.current_weapon and not player_shooter.is_reloading:
		var trying_to_shoot = Input.is_action_pressed("shoot") if player_shooter.current_weapon.is_auto else Input.is_action_just_pressed("shoot")
		if trying_to_shoot and player_shooter.can_shoot and player_shooter.current_weapon.current_ammo > 0:
			player_shooter.fire_gun(is_on_floor())

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

	if Input.is_action_pressed("throw_grenade"):
		is_cooking = true
		cook_elapsed += delta
	if Input.is_action_just_released("throw_grenade"):
		throw_grenade()
		is_cooking = false
	
	# movement sound fx
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_moving and is_on_floor():
		if footstep_timer.is_stopped(): footstep_timer.start()
	else:
		footstep_timer.stop()

	weapon_sway.update(delta, is_moving, is_on_floor())
	interaction_checker.check_interaction()

	# spray reset
	var speed_ratio = clamp(Vector2(velocity.x, velocity.z).length() / SPEED, 0.0, 1.0)
	player_shooter.update(delta, speed_ratio)

func throw_grenade():
	if current_explosive == null or current_explosive.count <= 0:
		return
	current_explosive.count -= 1
	emit_grenade_stats()
	var grenade = current_explosive.grenade_scene.instantiate()
	get_tree().root.add_child(grenade)
	grenade.global_position = grenade_anchor.global_position
	var throw_direction = -camera.global_transform.basis.z
	grenade.linear_velocity = throw_direction * current_explosive.throw_force
	grenade.init(current_explosive, current_explosive.fuse_time - cook_elapsed)
	cook_elapsed = 0.0  # reset for next throw

func emit_grenade_stats():
	GameManager.grenade_ui_update.emit(
		current_explosive.name,
		current_explosive.count
	)
