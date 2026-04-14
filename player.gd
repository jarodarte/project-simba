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

var oof_sound = preload("res://Audio/error_008.ogg")
var pitch: float = 0.0
var weapon_handler: WeaponHandler
var grenade_handler: GrenadeHandler

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	footstep_timer.timeout.connect(footstep_sound.play)
	await get_tree().process_frame
	weapon_handler = player_shooter.weapon_handler
	grenade_handler = player_shooter.grenade_handler

func _input(event):
	if weapon_handler == null or grenade_handler == null:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SettingsManager.mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * SettingsManager.mouse_sensitivity, -PI/2.2, PI/2.2)
		camera.rotation.x = pitch


func _physics_process(delta):
	if weapon_handler == null or grenade_handler == null:
		return
	# shooting process
	if weapon_handler.current_weapon and not weapon_handler.is_reloading and not grenade_handler.grenade_equipped:
		var trying_to_shoot = Input.is_action_pressed("shoot") if weapon_handler.current_weapon.is_auto else Input.is_action_just_pressed("shoot")
		if trying_to_shoot and weapon_handler.can_shoot and weapon_handler.current_weapon.current_ammo > 0:
			weapon_handler.fire_gun(is_on_floor())
			weapon_sway.add_recoil()

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
	weapon_handler.update(delta, speed_ratio)

func take_damage(amount: float):
	GameManager.health = max(0, GameManager.health - amount)
	var sound = AudioStreamPlayer.new()
	get_tree().root.add_child(sound)
	sound.volume_db = -10
	sound.stream = oof_sound
	sound.play()
	sound.finished.connect(sound.queue_free)
	GameManager.health_changed.emit(GameManager.health)
	if GameManager.health == 0:
		get_tree().call_deferred("change_scene_to_file", "res://game_over.tscn")

func _on_weapon_received(weapon_data: WeaponData):
	weapon_handler.update_player_gun(weapon_data)

func get_headshot_multiplier() -> float:
	return weapon_handler.current_weapon.headshot_multiplier
