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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reload") and not weapon_handler.is_reloading:
		weapon_handler.reload()

	if event.is_action_pressed("next_weapon"):
		if grenade_handler.grenade_equipped:
			grenade_handler.unequip_grenade()
		weapon_handler.swap_weapon(1)
	if event.is_action_pressed("prev_weapon"):
		if grenade_handler.grenade_equipped:
			grenade_handler.unequip_grenade()
		weapon_handler.swap_weapon(-1)
	if event.is_action_pressed("weapon_1"):
		if grenade_handler.grenade_equipped:
			grenade_handler.unequip_grenade()
		weapon_handler.swap_to_weapon(0)
	if event.is_action_pressed("weapon_2"):
		if grenade_handler.grenade_equipped:
			grenade_handler.unequip_grenade()
		weapon_handler.swap_to_weapon(1)
	if event.is_action_pressed("grenade"):
		if grenade_handler.grenade_equipped:
			grenade_handler.unequip_grenade()
		else:
			grenade_handler.equip_grenade()

	if event.is_action_pressed("shoot") and grenade_handler.grenade_equipped:
		grenade_handler.start_cook()

	if event.is_action_released("shoot") and grenade_handler.grenade_equipped:
		grenade_handler.throw_grenade()

func _physics_process(delta: float) -> void:
		# shooting process
	if weapon_handler.current_weapon and not weapon_handler.is_reloading and not grenade_handler.grenade_equipped:
		var trying_to_shoot = Input.is_action_pressed("shoot") if weapon_handler.current_weapon.is_auto else Input.is_action_just_pressed("shoot")
		if trying_to_shoot and weapon_handler.can_shoot and weapon_handler.current_weapon.current_ammo > 0:
			weapon_handler.fire_gun(player.is_on_floor())
			player.weapon_sway.add_recoil()
			
