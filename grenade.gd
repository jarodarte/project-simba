extends RigidBody3D

@export var data: ExplosiveData

var _exploded: bool = false
var _player: CharacterBody3D = null
var _cooking: bool = false
var _stuck_to: Node3D = null
var _stuck_offset: Vector3 = Vector3.ZERO

@onready var fuse_timer: Timer = $FuseTimer
@onready var explosion_area: Area3D = $ExplosionArea

func _ready() -> void:
	freeze = true
	_player = get_tree().get_first_node_in_group("player")
	$CollisionShape3D.disabled = true

func throw(camera: Camera3D) -> void:
	_cooking = false
	freeze = false
	$CollisionShape3D.disabled = false
	var throw_speed: float = 20.0
	var forward: Vector3 = -camera.global_transform.basis.z
	var player_vel: Vector3 = _player.velocity if _player else Vector3.ZERO
	linear_velocity = forward * throw_speed + player_vel

func _on_body_entered(body: Node) -> void:
	if body == _player:
		return
	if _stuck_to != null:  
		return
	if data.sticky:
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		freeze = true
		$CollisionShape3D.disabled = true
		# push grenade back to surface of the body
		var push_dir = (global_position - body.global_position).normalized()
		global_position = body.global_position + push_dir * .5
		_stuck_to = body
		_stuck_offset = global_position - body.global_position
	if data.impact_explosion:
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	collision_layer = 0
	collision_mask = 0

	# make sure overlapping bodies are detected
	explosion_area.monitoring = true
	await get_tree().physics_frame

	for body in explosion_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			var dist: float = global_position.distance_to(body.global_position)
			var t: float = clampf(1.0 - dist / data.explosion_radius, 0.0, 1.0)
			var final_damage: float = data.damage * t
			body.take_damage(final_damage)

	_play_vfx_then_free()

func _play_vfx_then_free() -> void:
	# Hide the mesh immediately
	if has_node("MeshInstance3D"):
		$MeshInstance3D.visible = false

	# TODO: spawn your explosion VFX/sound here
	# e.g. var vfx = ExplosionVFX.instantiate(); get_tree().root.add_child(vfx)

	await get_tree().create_timer(0.1).timeout
	queue_free()

func start_fuse() -> void:
	_cooking = true
	var shape = explosion_area.get_node("CollisionShape3D")
	(shape.shape as SphereShape3D).radius = data.explosion_radius
	if data.fuse_time > 0.0:
		fuse_timer.wait_time = data.fuse_time
		fuse_timer.one_shot = true
		fuse_timer.timeout.connect(_explode)
		fuse_timer.start()
	if data.sticky or data.impact_explosion:
		if not _exploded and is_inside_tree():
			body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if _stuck_to != null and is_instance_valid(_stuck_to):
		global_position = _stuck_to.global_position + _stuck_offset
		return
	if not _cooking or _exploded:
		return
