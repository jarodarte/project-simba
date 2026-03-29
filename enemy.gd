extends CharacterBody3D

const GRAVITY = 9.8
var player: Node3D = null
var health: float = 100.0
var death_sound = preload("res://Audio/minimize_001.ogg")
var DamageTextScene = preload("res://damage_text.tscn")
@export var SPEED = 2.0
@export var head_collision_shape: CollisionShape3D
@onready var nav_agent = $NavigationAgent3D
@onready var damage_zone = $DamageZone
@onready var mesh = $MeshInstance3D
@onready var material = mesh.get_surface_override_material(0)

var is_flashing: bool = false

func _ready():
	damage_zone.body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)

func _physics_process(delta):
	if player == null:
		return
	nav_agent.target_position = player.global_position
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	GameManager.take_damage(10)
	GameManager.enemy_died()
	queue_free()

func take_damage(base_amount: float, raycast: RayCast3D = null):
	var amount = base_amount
	var is_headshot = false

	if raycast != null and raycast.is_colliding() and raycast.get_collider() == self:
		var hit_shape = shape_owner_get_owner(raycast.get_collider_shape())
		is_headshot = hit_shape == head_collision_shape
		if is_headshot:
			amount *= player.current_weapon.headshot_multiplier
	
	health -= amount
	#floating damage text
	var damage_text = DamageTextScene.instantiate()
	get_tree().root.add_child(damage_text)
	damage_text.display(amount, global_position)
	#removes enemy if dead
	if health <= 0.0:
		GameManager.enemy_died()
		GameManager.update_points(GameManager.points + 10)
		play_death_sound()
		queue_free()
		return

	# only start a new flash if one isn't already running
	if not is_flashing:
		flash_damage(is_headshot)
	
	if is_headshot : GameManager.update_points(GameManager.points + 15) 
	else: GameManager.update_points(GameManager.points + 10)

func flash_damage(is_headshot: bool):
	is_flashing = true
	var original_color = material.albedo_color
	material.albedo_color = Color.ORANGE if is_headshot else Color.RED
	await get_tree().create_timer(0.05).timeout
	if is_inside_tree():
		material.albedo_color = original_color
	is_flashing = false

func play_death_sound():
	var sound = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound)
	sound.global_position = global_position
	sound.stream = death_sound
	sound.play()
	sound.finished.connect(sound.queue_free)
