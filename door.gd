extends Interactable

@onready var sound = $AudioStreamPlayer
@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape3D
@onready var mesh_resource = $MeshInstance3D

func _ready() -> void:
	super()
	label.text = "Open: " + str(cost)
	interacted.connect(attempt_purchase)
	if mesh_resource:
		mesh_resource.set_surface_override_material(0, StandardMaterial3D.new())
		mesh_resource.get_active_material(0).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _input(event: InputEvent):
	if not event.is_action_pressed("interact"):
		return
	if player == null:
		return
	if player.global_position.distance_to(global_position) > interaction_range:
		return
	var raycast = player.get_node_or_null("Camera3D/RayCast3D")
	if raycast and raycast.is_colliding():
		if raycast.get_collider() == self:
			interacted.emit()

func update_label(message: String = ""):
	if message != "":
		label.text = message
		return
	label.text = "Open: " + str(cost)  

func apply_reward() -> bool:
	collision.shape = null
	sound.play()
	anim.play("disappear")
	var mat = mesh_resource.get_active_material(0)
	if mat:
		var unique_mat = mat.duplicate()
		mesh_resource.set_surface_override_material(0, unique_mat)
		var tween = create_tween()
		tween.tween_property(unique_mat, "albedo_color:a", 0.0, 1.5)
	_finish_door()
	return true

func _finish_door() -> void:
	await anim.animation_finished
	queue_free()
