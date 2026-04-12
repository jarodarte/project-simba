extends Resource
class_name WeaponData

@export var name: String = "Pistol"
@export var ammo_type: String = "9mm"
@export var fire_rate: float = 0.2  # Time in seconds between shots
@export var is_auto: bool = false   # Semi-auto by default
@export var damage: int = 10
@export var magazine_size: int = 10
@export var max_reserve_magazines: int = 3
@export var current_ammo: int = magazine_size
@export var weapon_scene: PackedScene #weapon mesh
@export var current_reserve_magazines = max_reserve_magazines
@export var headshot_multiplier: float = 1.5
@export var burst_count = 1
@export var burst_delay = 0.1
@export_group("Spray")
@export var spread_radius: float = 0.0
@export var max_spread_radius: float = 1.0
@export var spread_per_shot = 0.2
@export var spray_pattern: Array[Vector2] = []
@export var spray_reset_time: float = 0.4
@export var move_spread_max: float = 0.0
@export var jump_spread: float = 0.0
