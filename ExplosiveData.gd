extends Resource
class_name ExplosiveData

@export var name: String = "Frag Grenade"
@export var grenade_scene: PackedScene  # the 3D object that gets thrown

# Throw behavior
@export var throw_force: float = 15.0   # how hard it's thrown (m/s)
@export var cook_time: float = 0.0      # hold to cook - reduces fuse
@export var is_sticky: bool = false     # sticks to geometry

# Detonation
@export var fuse_time: float = 3.0      # seconds before it explodes
@export var explosion_radius: float = 5.0
@export var explodes_on_impact: bool = true

# Damage
@export var max_damage: int = 100       # damage at epicenter
@export var min_damage: int = 10        # damage at edge of radius
@export var falloff_curve: Curve        # optional: custom damage falloff shape

# Inventory
@export var count: int = 2             # how many the player carries
