extends Node3D

const SPEED = 4.0

@export var camera: Camera3D
@export var raycast: RayCast3D
@export var shoot_timer: Timer
@export var weapons: Array[WeaponData] = []
@export var weapon_anchor: Node3D
@export var player: CharacterBody3D
@export var explosives: Array[ExplosiveData] = []

var weapon_handler: WeaponHandler
var grenade_handler: GrenadeHandler
var is_reloading: bool:
	get: return weapon_handler.is_reloading
var can_shoot: bool:
	get: return weapon_handler.can_shoot
var grenade_equipped: bool:
	get: return grenade_handler.grenade_equipped
var current_weapon: WeaponData:
	get: return weapon_handler.current_weapon

func _ready() -> void:
	weapon_handler = WeaponHandler.new()
	weapon_handler.init(self, camera, player, weapon_anchor, shoot_timer, weapons)
	grenade_handler = GrenadeHandler.new()
	grenade_handler.init(self, camera, weapon_anchor, explosives, weapon_handler)
	weapon_handler.weapon_stats_changed.connect(GameManager.weapon_ui_update.emit)
	grenade_handler.grenade_stats_changed.connect(GameManager.grenade_ui_update.emit)
	for weapon in weapons:
		var w = weapon.duplicate(true)
		w.current_ammo = w.magazine_size
		w.current_reserve_magazines = w.max_reserve_magazines
		weapon_handler.runtime_weapons.append(w)
	
	if weapon_handler.runtime_weapons.size() > 0:
		weapon_handler.current_weapon = weapon_handler.runtime_weapons[0]
	
	for explosive in explosives:
		var e = explosive.duplicate(true)
		grenade_handler.runtime_explosives.append(e)

	if grenade_handler.runtime_explosives.size() > 0:
		grenade_handler.current_grenade_data = grenade_handler.runtime_explosives[0]

	if weapon_handler.current_weapon:
		weapon_handler.spawn_weapon()
		weapon_handler.emit_weapon_stats()
