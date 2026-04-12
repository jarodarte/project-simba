extends Node3D

const SPEED = 200.0  # units per second, tune to taste
const LENGTH = 0.4   # visual length of the streak

var _target: Vector3
var _direction: Vector3
var _distance: float
var _travelled: float = 0.0

func init(from: Vector3, to: Vector3) -> void:
	global_position = from
	_target = to
	_direction = (to - from).normalized()
	_distance = from.distance_to(to)

	# orient the mesh along the travel direction
	look_at(to, Vector3.UP)

func _process(delta: float) -> void:
	var step = SPEED * delta
	_travelled += step
	global_position += _direction * step

	if _travelled >= _distance:
		queue_free()
