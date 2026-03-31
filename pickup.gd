extends Area3D

@export_enum("ammo", "health") var pickup_type: String = "ammo"
@export var ammo_type: String = "9mm"
@export var ammo_amount: int = 10
@export var health_amount: float = 20

@onready var label = $Label3D

func _ready() -> void:
	if pickup_type == "ammo":
		label.text = str(ammo_amount) + " " + ammo_type
	elif pickup_type == "health": 
		label.text = "+" + str(health_amount) + " health"

func show_info():
	label.visible = true

func hide_info():
	label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if pickup_type == "ammo":
			for weapon in body.player_shooter.runtime_weapons:
				if weapon.ammo_type == ammo_type:
					weapon.current_reserve_magazines = min(weapon.current_reserve_magazines + ammo_amount, weapon.max_reserve_magazines)
					body.player_shooter.emit_weapon_stats()
		elif pickup_type == "health": 
			GameManager.heal(health_amount)
		queue_free()
