extends Resource
class_name ExplosiveData

@export var name: String = "grenade"
@export var sticky: bool = false
@export var flaming: bool = false
@export var impact_explosion: bool = false
@export var explosion_radius: float = 10.0
@export var damage: float = 50.0
@export var fuse_time: float = 0.0
@export var current_fuse_time: float = 0.0
@export var grenade_scene: PackedScene
@export var amount: int = 0
@export var current_amount: int = 0
@export var gravity_scale: float
