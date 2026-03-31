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

var pitch: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	footstep_timer.timeout.connect(footstep_sound.play)

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
