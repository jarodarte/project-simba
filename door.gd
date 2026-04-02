extends Node3D

@export var mesh_resource: Mesh
@export var cost: int
@export var interaction_range: float = 3.0

@onready var mesh_instance = $MeshInstance3D
@onready var sound = $AudioStreamPlayer
@onready var anim = $AnimationPlayer
@onready var label = $Label3D
@onready var collision = $StaticBody3D/CollisionShape3D

var player: Node3D = null

func _ready() -> void:
	label.visible = false
	player = get_tree().get_first_node_in_group("player")
	label.text = "Open: " + str(cost)
	if mesh_resource:
		mesh_instance.mesh = mesh_resource
		mesh_instance.set_surface_override_material(0, StandardMaterial3D.new())
		mesh_instance.get_active_material(0).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_build_collision()

func _build_collision() -> void:
	if mesh_instance.mesh == null:
		return
	var shape = mesh_instance.mesh.create_trimesh_shape()
	collision.shape = shape

func show_info():
	label.visible = true

func hide_info():
	label.visible = false

func _input(event: InputEvent):
	if not event.is_action_pressed("interact"):
		return
	if player == null:
		return
	if player.global_position.distance_to(global_position) > interaction_range:
		return
	var raycast = player.get_node_or_null("Camera3D/RayCast3D")
	if raycast and raycast.is_colliding():
		if raycast.get_collider().get_parent() == self:
			attempt_purchase()

func attempt_purchase():
	if GameManager.points >= cost:
		GameManager.update_points(GameManager.points - cost)
		open_door()
	else:
		flash_error("Not enough points!")

func flash_error(msg: String):
	update_label(msg)
	label.modulate = Color.RED
	await get_tree().create_timer(1.5).timeout
	label.modulate = Color.WHITE
	update_label()

func update_label(message: String = ""):
	if message != "":
		label.text = message
		return
	label.text = "Open: " + str(cost)  

func open_door() -> bool:
	label.visible = false
	collision.shape = null
	anim.play("disappear")
	sound.play()
	var mat = mesh_instance.get_active_material(0)
	if mat:
		var unique_mat = mat.duplicate()
		mesh_instance.set_surface_override_material(0, unique_mat)
		var tween = create_tween()
		tween.tween_property(unique_mat, "albedo_color:a", 0.0, 1.5)
	await anim.animation_finished
	queue_free()
	return true
