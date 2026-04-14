extends CharacterBody3D

const GRAVITY = 9.8
const ATTACK_RANGE = 1.5

var player: Node3D = null
var health: int = 0
var is_flashing: bool = false
var _is_dead: bool = false
var death_sound = preload("res://Audio/minimize_001.ogg")
var DamageTextScene = preload("res://damage_text.tscn")
var materials = []
var is_attacking: bool = false
var attack_timer: Timer

@export var data: EnemyData
@export var head_collision_shape: CollisionShape3D
@onready var nav_agent = $NavigationAgent3D
@onready var damage_zone = $DamageZone
@onready var skeleton = $Skeleton3D
@onready var animation = $AnimationPlayer
@onready var meshes = find_children("*", "MeshInstance3D", true)
@onready var hitbox = $DamageZone/EnemyHitbox


func _ready():
	data.contact_damage = 35
	for mesh in meshes:
		var mat = mesh.get_surface_override_material(0)
		if mat == null:
			continue
		var dup = mat.duplicate()
		if data.skin_texture:
			dup.albedo_texture = data.skin_texture
		materials.append(dup)
		mesh.set_surface_override_material(0, dup)
	hitbox.shape.radius = ATTACK_RANGE
	health = data.max_health
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animation.play("zombie_walk")
	damage_zone.body_entered.connect(_on_body_entered)
	damage_zone.body_exited.connect(_on_body_exited)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player == null:
		return
	nav_agent.target_position = player.global_position
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	look_at(player.global_position, up_direction)
	rotation.y += PI 
	rotation.x = 0
	rotation.z = 0
	if global_position.distance_to(player.global_position) > ATTACK_RANGE:
		velocity.x = direction.x * data.speed
		velocity.z = direction.z * data.speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	player.take_damage(data.contact_damage)
	is_attacking = true
	attack_timer.start()

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	is_attacking = false
	attack_timer.stop()

func take_damage(base_amount: float, hit: Dictionary = {}):
	if not is_inside_tree():
		return
	var amount = base_amount
	var is_headshot = false

	if not hit.is_empty() and hit.get("collider") == self:
		var shape_idx = hit.get("shape", -1)
		if shape_idx >= 0:
			var hit_shape = shape_owner_get_owner(shape_idx)
			if hit_shape != null:
				is_headshot = hit_shape == head_collision_shape
				if is_headshot:
					if is_instance_valid(player):
						amount *= player.get_headshot_multiplier() * data.enemy_headshot_multiplier

	health -= amount
	GameManager.update_points(GameManager.points + 10)

	var damage_text = DamageTextScene.instantiate()
	get_tree().root.add_child(damage_text)
	damage_text.display(amount, global_position)

	if health <= 0.0:
		play_death_sound()
		_die()
		return

	if not is_flashing:
		flash_damage(is_headshot)

func flash_damage(is_headshot: bool):
	is_flashing = true
	var original_colors = []
	for material in materials:
		original_colors.append(material.albedo_color)
		material.albedo_color = Color.ORANGE if is_headshot else Color.RED
	await get_tree().create_timer(0.05).timeout
	if is_inside_tree():
		for i in materials.size():
			materials[i].albedo_color = original_colors[i]
	is_flashing = false

func play_death_sound():
	var sound = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound)
	sound.global_position = global_position
	sound.stream = death_sound
	sound.play()
	sound.finished.connect(sound.queue_free)

func _die():
	if _is_dead:
		return
	_is_dead = true
	GameManager.enemy_died()
	GameManager.update_points(GameManager.points + data.points_on_death)
	queue_free()

func _exit_tree():
	if not _is_dead:
		_is_dead = true
		GameManager.enemy_died()

func _on_attack_timer_timeout() -> void:
	player.take_damage(data.contact_damage)
