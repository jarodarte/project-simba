extends RefCounted
class_name GrenadeHandler

# signals
signal grenade_stats_changed(name, amount)

# external references
var owner_node: Node3D
var camera: Camera3D
var weapon_anchor: Node3D
var explosives: Array[ExplosiveData] = []
var weapon_handler: WeaponHandler

# grenade data
var runtime_explosives: Array[ExplosiveData] = []
var current_grenade_data: ExplosiveData = null
var current_grenade_node: Node3D = null
var grenade_index: int = 0

# state
var grenade_equipped: bool = false
var _cooking: bool = false


func init(p_owner, p_camera, p_weapon_anchor, p_explosives, p_weapon_handler):
	owner_node = p_owner
	camera = p_camera
	weapon_anchor = p_weapon_anchor
	explosives = p_explosives
	weapon_handler = p_weapon_handler

func equip_grenade() -> void:
	if runtime_explosives.is_empty():
		return
	current_grenade_data = runtime_explosives[grenade_index]
	grenade_equipped = true
	_cooking = false

	if weapon_handler.current_weapon_node:
		weapon_handler.current_weapon_node.visible = false

	if current_grenade_node:
		current_grenade_node.queue_free()

	current_grenade_node = current_grenade_data.grenade_scene.instantiate()
	current_grenade_node.data = current_grenade_data
	weapon_anchor.add_child(current_grenade_node)
	emit_grenade_stats()

func unequip_grenade() -> void:
	grenade_equipped = false
	_cooking = false

	if current_grenade_node:
		current_grenade_node.queue_free()
		current_grenade_node = null

	if weapon_handler.current_weapon_node:
		weapon_handler.current_weapon_node.visible = true

	weapon_handler.emit_weapon_stats()

func start_cook() -> void:
	if _cooking or current_grenade_node == null or current_grenade_data.current_amount == 0:
		return
	_cooking = true
	current_grenade_node.start_fuse()

func throw_grenade() -> void:
	if not _cooking or current_grenade_node == null:
		return
	current_grenade_data.current_amount -= 1
	var grenade = current_grenade_node
	current_grenade_node = null

	weapon_anchor.remove_child(grenade)
	owner_node.get_tree().root.add_child(grenade)
	grenade.global_position = camera.global_position
	grenade.throw(camera)
	unequip_grenade()

func emit_grenade_stats():
	grenade_stats_changed.emit(
		current_grenade_data.name,
		current_grenade_data.current_amount
	)
