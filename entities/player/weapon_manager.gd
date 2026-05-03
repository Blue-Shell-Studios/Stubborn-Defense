class_name WeaponManager extends Node2D

const WEAPON_DISTANCE := 30.0
const MAX_WEAPON_SLOTS := 6

func _ready() -> void:
	add_to_group("player_weapon_manager")
	set_weapons()

func set_active(is_active: bool) -> void:
	visible = is_active
	for weapon in get_weapons():
		weapon.set_process(is_active)
		weapon.visible = is_active

func set_weapons() -> void:
	var weapons := get_weapons()
	var num_weapons = weapons.size()
	if num_weapons == 0:
		return
	
	for i in range(num_weapons):
		var angle = 2*PI / num_weapons * i
		(weapons[i] as Node2D).position = WEAPON_DISTANCE * Vector2.RIGHT.rotated(angle)

func add_weapon(weapon_scene: PackedScene, tier: int = 0) -> bool:
	if get_weapons().size() >= MAX_WEAPON_SLOTS:
		return false

	var weapon := weapon_scene.instantiate() as Weapon
	if not weapon:
		return false

	add_child(weapon)
	weapon.tier = tier
	set_weapons()
	return true

func combine_weapon(weapon_id: String, tier: int) -> bool:
	if tier >= 4:
		return false

	var matches: Array[Weapon] = []
	for weapon in get_weapons():
		if weapon.weapon_id == weapon_id and weapon.tier == tier:
			matches.append(weapon)

	if matches.size() < 2:
		return false

	remove_child(matches[1])
	matches[1].queue_free()
	matches[0].tier = tier + 1
	set_weapons()
	return true

func get_weapon_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var weapons := get_weapons()
	for index in range(MAX_WEAPON_SLOTS):
		if index >= weapons.size():
			snapshots.append({"empty": true})
			continue

		var weapon := weapons[index]
		if not weapon:
			snapshots.append({"empty": true})
			continue

		snapshots.append({
			"empty": false,
			"index": index,
			"id": weapon.weapon_id,
			"name": weapon.display_name,
			"tier": weapon.tier,
			"sell_value": maxi(1, int(weapon.shop_cost * 0.5)),
		})

	return snapshots

func can_combine_index(index: int) -> bool:
	var weapon := get_weapon_at(index)
	if not weapon or weapon.tier >= 4:
		return false

	for other in get_weapons():
		if other != weapon and other.weapon_id == weapon.weapon_id and other.tier == weapon.tier:
			return true

	return false

func combine_weapon_at(index: int) -> bool:
	var weapon := get_weapon_at(index)
	if not weapon or weapon.tier >= 4:
		return false

	for other in get_weapons():
		if other != weapon and other.weapon_id == weapon.weapon_id and other.tier == weapon.tier:
			remove_child(other)
			other.queue_free()
			weapon.tier += 1
			set_weapons()
			return true

	return false

func sell_weapon_at(index: int) -> int:
	var weapon := get_weapon_at(index)
	if not weapon:
		return 0

	var sell_value := maxi(1, int(weapon.shop_cost * 0.5))
	remove_child(weapon)
	weapon.queue_free()
	set_weapons()
	return sell_value

func get_weapon_at(index: int) -> Weapon:
	var weapons := get_weapons()
	if index < 0 or index >= weapons.size():
		return null

	return weapons[index]

func get_weapons() -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	for child in get_children():
		var weapon := child as Weapon
		if weapon and not weapon.is_queued_for_deletion():
			weapons.append(weapon)

	return weapons
