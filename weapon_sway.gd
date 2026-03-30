extends Node

const BOB_SPEED = (2 * PI) # how fast the cycle runs
const BOB_AMOUNT = 0.05    # how far it moves 
const BOB_LERP_SPEED = 10.0

var bob_time: float = 0.0

@export var gun_holder: Node3D

func update( delta: float, is_moving: bool, is_grounded: bool):
		# weapon sway
	var bob_target = Vector3.ZERO
	if is_moving and is_grounded:
		bob_time += delta * BOB_SPEED
		var bob_x = sin(bob_time) * BOB_AMOUNT
		var bob_y = sin(bob_time * 2) * BOB_AMOUNT
		bob_target = Vector3(bob_x, bob_y, 0)
	else: bob_time = 0.0
	gun_holder.position = lerp(gun_holder.position, bob_target, BOB_LERP_SPEED * delta)
