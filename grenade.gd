extends RigidBody3D

var has_exploded: bool = false
var data: ExplosiveData

@onready var area = $Area3D
@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
@onready var audio = $AudioStreamPlayer3D

func init(explosive_data: ExplosiveData, fuse_override: float = -1.0):
	data = explosive_data
	if data.explodes_on_impact:
		body_entered.connect(_on_body_entered)
	else:
		var fuse = fuse_override if fuse_override >= 0.0 else data.fuse_time
		await get_tree().create_timer(fuse).timeout
		explode()

func _on_body_entered(_body):
	explode()

func explode():
	if has_exploded:
		return
	has_exploded = true
	print("exploded at: ", global_position)
	print("bodies found: ", area.get_overlapping_bodies())
	var shape = area.get_node("CollisionShape3D")
	shape.shape = SphereShape3D.new()
	shape.shape.radius = data.explosion_radius
	await get_tree().physics_frame
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body == self:
			continue
		var distance = (global_position - body.global_position).length()
		var ratio = distance / data.explosion_radius
		var damage = lerp(float(data.max_damage), float(data.min_damage), ratio)
		if body.is_in_group("enemy"):
			body.take_damage(int(damage), {})
		if body.is_in_group("player"):
			GameManager.take_damage(int(damage))
	mesh.visible = false
	particles.emitting = true
	audio.play()
	await audio.finished
	queue_free()
