extends Node

const BOB_SPEED = (2 * PI)
const BOB_AMOUNT = 0.05
const BOB_LERP_SPEED = 10.0
const RECOIL_RECOVER_SPEED = 8.0   

var recoil_offset: Vector3 = Vector3.ZERO

var bob_time: float = 0.0

@export var gun_holder: Node3D

func update(delta: float, is_moving: bool, is_grounded: bool):
	# weapon sway
	var bob_target = Vector3.ZERO
	if is_moving and is_grounded:
		bob_time += delta * BOB_SPEED
		var bob_x = sin(bob_time) * BOB_AMOUNT
		var bob_y = sin(bob_time * 2) * BOB_AMOUNT
		bob_target = Vector3(bob_x, bob_y, 0)
	else:
		bob_time = 0.0

	recoil_offset = lerp(recoil_offset, Vector3.ZERO, RECOIL_RECOVER_SPEED * delta)

	gun_holder.position = lerp(gun_holder.position, bob_target + recoil_offset, BOB_LERP_SPEED * delta)

func add_recoil(kick_up: float = 0.05, kick_back: float = 0.2):
	recoil_offset += Vector3(0, kick_up, kick_back)
