class_name ShopManager extends Node

const WEAPON_POOL := [
	{
		"id": "gatling_turret",
		"name": "Gatling Turret",
		"scene": preload("res://entities/weapons/gatling_turret/gatling_turret.tscn"),
		"icon": "res://asset/shop_icons/weapon_icons/Basic Cannon 1.png",
		"cost": 12,
	},
	{
		"id": "torpedo_launcher",
		"name": "Torpedo Launcher",
		"scene": preload("res://entities/weapons/torpedo_launcher/torpedo_launcher.tscn"),
		"icon": "res://asset/shop_icons/weapon_icons/Torpedo 1.png",
		"cost": 24,
	},
	{
		"id": "beam_emitter",
		"name": "Beam Emitter",
		"scene": preload("res://entities/weapons/beam_emitter/beam_emitter.tscn"),
		"icon": "res://asset/shop_icons/weapon_icons/Laser.png",
		"cost": 20,
	},
]
const ITEM_POOL := [
	{
		"id": "nebula_plating",
		"name": "Nebula Plating",
		"description": "Layered hull panels tuned for long patrols.",
		"cost": 10,
		"stats": {"max_hp": 14.0, "armor": 1.0},
		"icon": "res://asset/shop_icons/item_icons/Nebula Plating.png"
	},
	{
		"id": "ion_overcharger",
		"name": "Ion Overcharger",
		"description": "Pushes extra current through weapon emitters.",
		"cost": 14,
		"stats": {"damage_bonus_percent": 6.0, "attack_speed_bonus_percent": -4.0},
		"icon": "res://asset/shop_icons/item_icons/Ion Overcharger.png"
	},
	{
		"id": "pulse_regulator",
		"name": "Pulse Regulator",
		"description": "Stabilizes firing cycles for quicker volleys.",
		"cost": 13,
		"stats": {"attack_speed_bonus_percent": 8.0},
		"icon": "res://asset/shop_icons/item_icons/Pulse Regulator.png"
	},
	{
		"id": "comet_lens",
		"name": "Comet Lens",
		"description": "Focuses weapon tracking beyond standard range.",
		"cost": 12,
		"stats": {"range": 30.0},
		"icon": "res://asset/shop_icons/item_icons/Comet Lens.png"
	},
	{
		"id": "void_targeter",
		"name": "Void Targeter",
		"description": "Highlights weak points in hostile hulls.",
		"cost": 16,
		"stats": {"crit_chance": 0.04, "crit_damage_multiplier": 0.12},
		"icon": "res://asset/shop_icons/item_icons/Void Targeter.png"
	},
	{
		"id": "phase_thrusters",
		"name": "Phase Thrusters",
		"description": "Adds erratic micro-jumps to your flight path.",
		"cost": 15,
		"stats": {"speed": 35.0, "dodge": 0.025},
		"icon": "res://asset/shop_icons/item_icons/Phase Thrusters.png"
	},
	{
		"id": "starfinder_core",
		"name": "Starfinder Core",
		"description": "Improves salvage scans and rare stock discovery.",
		"cost": 18,
		"stats": {"luck": 1.5},
		"icon": "res://asset/shop_icons/item_icons/Starfinder Core.png"
	},
	{
		"id": "sun_scepter",
		"name": "Sun Scepter",
		"description": "Infuse the power of the sun to weapons",
		"cost": 15,
		"stats": {"damage_bonus_percent": 10.0},
		"icon": "res://asset/shop_icons/item_icons/Sun Scepter.png"
	},
	{
		"id": "startouch_visor",
		"name": "Startouch Visor",
		"description": "Enhance field of vision",
		"cost": 10,
		"stats": {"range": 25.0},
		"icon": "res://asset/shop_icons/item_icons/Startouch Visor.png"
	},
	{
		"id": "star_atlas",
		"name": "Star Atlas",
		"description": "Maps out the location through the guidance of the stars",
		"cost": 30,
		"stats": {"range": 15.0, "luck": 4.0},
		"icon": "res://asset/shop_icons/item_icons/Star Atlas.png"
	},
	{
		"id": "dark_matter",
		"name": "Dark Matter",
		"description": "A highly valuable fuel throughout the cosmos",
		"cost": 19,
		"stats": {"attack_speed_bonus_percent": -6.0, "speed": 45.0},
		"icon": "res://asset/shop_icons/item_icons/Dark Matter.png"
	},
	{
		"id": "cosmic_core",
		"name": "Cosmic Core",
		"description": "Analyses enemy movement patterns increasing deadly stikes",
		"cost": 13,
		"stats": {"crit_chance": 0.07, "damage_bonus_percent": 3.0},
		"icon": "res://asset/shop_icons/item_icons/Comet Lens.png"
	},
	{
		"id": "time_warp",
		"name": "Time Warp",
		"description": "Creates time space fluctuations to pass through matter",
		"cost": 16,
		"stats": {"dodge": 0.05, "speed": 30.0},
		"icon": "res://asset/shop_icons/item_icons/Time Warp.png"
	},
	{
		"id": "astral_deflector",
		"name": "Astral Deflector",
		"description": "Defense system module that provides protection against astral forces",
		"cost": 17,
		"stats": {"max_hp": 6.0, "armor": 3.0},
		"icon": "res://asset/shop_icons/item_icons/Astral Deflector.png"
	},
	{
		"id": "pulsar_shot",
		"name": "Pulsar Shot",
		"description": "Weapon modification that mimics neutron star beams",
		"cost": 14,
		"stats": {"crit_chance": 0.09, "crit_damage_multiplier": 0.1},
		"icon": "res://asset/shop_icons/item_icons/Pulsar Shot.png"
	},
	{
		"id": "chaos_amulet",
		"name": "Chaos Amulet",
		"description": "Super dense compressed energy that bends probability",
		"cost": 25,
		"stats": {"luck": 3.0, "dodge": 0.02},
		"icon": "res://asset/shop_icons/item_icons/Chaos Amulet.png"
	},
	{
		"id": "structural_integrity_module",
		"name": "Structural Integrity Module",
		"description": "Creates a thin layer of energy field that absorb impacts",
		"cost": 15,
		"stats": {"armor": 3.0},
		"icon": "res://asset/shop_icons/item_icons/Structural Integrity Module.png"
	},
	{
		"id": "blazar_energy_cube",
		"name": "Blazar energy cube",
		"description": "Integrate gamma rays into weapons",
		"cost": 12,
		"stats": {"crit_damage_multiplier": 0.3},
		"icon": "res://asset/shop_icons/item_icons/Blazar energy cube.png"
	},
	{
		"id": "nanotech_system",
		"name": "Nanotech System",
		"description": "Micro repair technology that can transform into ship components",
		"cost": 14,
		"stats": {"max_hp": 20.0},
		"icon": "res://asset/shop_icons/item_icons/Nanotech System.png"
	}
]

@export var offer_count := 3
@export var auto_refresh_interval := 30.0
@export var manual_refresh_cost := 5
@export_range(0.0, 1.0, 0.05) var weapon_offer_chance := 0.55

var offers: Array[Dictionary] = []
var refresh_time_left := 0.0
var is_open := false
var selected_weapon_index := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	SignalBus.shop_toggle_requested.connect(toggle_shop)
	SignalBus.shop_visibility_changed.connect(_on_shop_visibility_changed)
	SignalBus.shop_buy_requested.connect(buy_offer)
	SignalBus.shop_refresh_requested.connect(refresh_with_payment)
	SignalBus.shop_offer_lock_requested.connect(set_offer_locked)
	SignalBus.shop_weapon_selected.connect(select_weapon)
	SignalBus.shop_selected_weapon_combine_requested.connect(combine_selected_weapon)
	SignalBus.shop_selected_weapon_sell_requested.connect(sell_selected_weapon)
	refresh_offers()

func _process(delta: float) -> void:
	if is_open:
		return

	refresh_time_left -= delta
	if refresh_time_left <= 0.0:
		refresh_offers()
	else:
		emit_shop_state()

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		close_shop()

func toggle_shop() -> void:
	if is_open:
		close_shop()
	else:
		open_shop()

func _on_shop_visibility_changed(new_is_open: bool) -> void:
	is_open = new_is_open
	get_tree().paused = is_open
	emit_shop_state()

func open_shop() -> void:
	is_open = true
	get_tree().paused = true
	selected_weapon_index = -1
	SignalBus.shop_visibility_changed.emit(true)
	emit_shop_state()

func close_shop() -> void:
	is_open = false
	get_tree().paused = false
	selected_weapon_index = -1
	SignalBus.shop_visibility_changed.emit(false)
	emit_shop_state()

func refresh_offers() -> void:
	var old_offers := offers.duplicate(true)
	offers.clear()
	var player := get_player()
	var has_item_offer := false
	for index in range(offer_count):
		var kept := false
		if index < old_offers.size():
			var old_offer: Dictionary = old_offers[index]
			if old_offer.get("locked", false) and not old_offer.get("empty", false):
				offers.append(old_offer)
				kept = true
				has_item_offer = has_item_offer or old_offer.get("type", "weapon") == "item"

		if kept:
			continue

		var tier := roll_offer_tier(player.luck if player else 0.0)
		var offer := create_random_offer(tier)
		offer["locked"] = false
		has_item_offer = has_item_offer or offer.get("type", "weapon") == "item"
		offers.append(offer)

	if offer_count > 0 and not has_item_offer:
		# Ensure at least one item offer, but don't override locked slots.
		var unlockable_slots: Array[int] = []
		for i in range(offers.size()):
			if not offers[i].get("locked", false):
				unlockable_slots.append(i)

		if unlockable_slots.size() > 0:
			var tier := roll_offer_tier(player.luck if player else 0.0)
			var slot: int = unlockable_slots.pick_random()
			var item_offer := create_item_offer(ITEM_POOL.pick_random(), tier)
			item_offer["locked"] = false
			offers[slot] = item_offer

		# If all slots are locked and none are items, we accept the state rather than forcing a reroll.

	refresh_time_left = auto_refresh_interval
	SignalBus.shop_message_changed.emit("")
	emit_shop_state()

func set_offer_locked(offer_index: int, locked: bool) -> void:
	if offer_index < 0 or offer_index >= offers.size():
		return

	if offers[offer_index].get("empty", false):
		return

	offers[offer_index]["locked"] = locked
	emit_shop_state()

func refresh_with_payment() -> void:
	var player := get_player()
	if not player:
		return

	var reroll_count := 0
	for offer in offers:
		if offer is Dictionary and not offer.get("empty", false) and not offer.get("locked", false):
			reroll_count += 1
	if reroll_count <= 0:
		SignalBus.shop_message_changed.emit("All offers locked.")
		return

	if not player.spend_scrap(manual_refresh_cost):
		SignalBus.shop_message_changed.emit("Not enough scrap to refresh.")
		return

	refresh_offers()

func buy_offer(offer_index: int) -> void:
	if offer_index < 0 or offer_index >= offers.size():
		return

	var offer := offers[offer_index]
	if offer.get("empty", false):
		return

	var player := get_player()
	var weapon_manager := get_weapon_manager()
	if not player:
		return

	var cost := int(offer["cost"])
	if not player.spend_scrap(cost):
		SignalBus.shop_message_changed.emit("Not enough scrap.")
		return

	if offer.get("type", "weapon") == "item":
		player.apply_item(offer["item"])
		offers[offer_index] = {"empty": true}
		SignalBus.shop_message_changed.emit("Installed %s." % offer["name"])
	elif weapon_manager and weapon_manager.add_weapon(offer["scene"], offer["tier"]):
		offers[offer_index] = {"empty": true}
		SignalBus.shop_message_changed.emit("Purchased %s." % offer["name"])
	else:
		player.add_scrap(cost)
		SignalBus.shop_message_changed.emit("Weapon slots full.")

	emit_shop_state()

func select_weapon(weapon_index: int) -> void:
	selected_weapon_index = weapon_index
	emit_shop_state()

func combine_selected_weapon() -> void:
	var weapon_manager := get_weapon_manager()
	if not weapon_manager:
		return

	if weapon_manager.combine_weapon_at(selected_weapon_index):
		SignalBus.shop_message_changed.emit("Combined weapon to next tier.")
		selected_weapon_index = -1
		emit_shop_state()
		return
	else:
		SignalBus.shop_message_changed.emit("No matching weapon to combine.")

	emit_shop_state()

func sell_selected_weapon() -> void:
	var player := get_player()
	var weapon_manager := get_weapon_manager()
	if not player or not weapon_manager:
		return

	var sell_value: int = weapon_manager.sell_weapon_at(selected_weapon_index)
	if sell_value <= 0:
		SignalBus.shop_message_changed.emit("No weapon selected.")
		return

	player.add_scrap(sell_value)
	SignalBus.shop_message_changed.emit("Sold weapon for %d scrap." % sell_value)
	selected_weapon_index = -1
	emit_shop_state()

func emit_shop_state() -> void:
	SignalBus.shop_offers_changed.emit(offers, max(refresh_time_left, 0.0), manual_refresh_cost)
	var weapon_manager := get_weapon_manager()
	if not weapon_manager:
		SignalBus.shop_weapons_changed.emit([], -1)
		SignalBus.shop_selected_weapon_changed.emit({}, false, 0)
		return

	var weapons: Array[Dictionary] = weapon_manager.get_weapon_snapshots()
	SignalBus.shop_weapons_changed.emit(weapons, selected_weapon_index)

	var selected := {}
	var can_combine := false
	if selected_weapon_index >= 0 and selected_weapon_index < weapons.size():
		selected = weapons[selected_weapon_index]
		if not selected.get("empty", true):
			can_combine = weapon_manager.can_combine_index(selected_weapon_index)

	SignalBus.shop_selected_weapon_changed.emit(selected, can_combine, selected.get("sell_value", 0))

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player_target") as Player

func get_weapon_manager() -> WeaponManager:
	return get_tree().get_first_node_in_group("player_weapon_manager") as WeaponManager

func create_random_offer(tier: int) -> Dictionary:
	if randf() < weapon_offer_chance:
		return create_weapon_offer(WEAPON_POOL.pick_random(), tier)

	return create_item_offer(ITEM_POOL.pick_random(), tier)

func create_weapon_offer(template: Dictionary, tier: int) -> Dictionary:
	var weapon_stats := get_weapon_offer_stats(template, tier)
	var icon := _get_offer_icon(template)
	return {
		"empty": false,
		"type": "weapon",
		"id": template["id"],
		"name": template["name"],
		"scene": template["scene"],
		"cost": get_offer_cost(int(template["cost"]), tier),
		"tier": tier,
		"description": "Weapon",
		"weapon_stats": weapon_stats,
		"icon": icon,
	}

func create_item_offer(template: Dictionary, tier: int) -> Dictionary:
	var stats: Dictionary = template["stats"]
	var icon := _get_offer_icon(template)
	var item := ShopItem.new().setup(
		template["id"],
		template["name"],
		template["description"],
		icon,
		int(template["cost"]),
		stats,
		tier
	)
	return {
		"empty": false,
		"type": "item",
		"id": item.item_id,
		"name": item.display_name,
		"cost": item.get_cost(),
		"tier": item.tier,
		"description": item.description,
		"summary": item.get_stat_summary(),
		"stat_modifiers": item.get_scaled_stat_modifiers(),
		"item": item,
		"icon": icon,
	}
	
func _get_offer_icon(template: Dictionary) -> Texture2D:
	var icon_path_val: String = template.get("icon")
	var icon_path := icon_path_val as String if icon_path_val is String else ""
	if icon_path.is_empty():
		return null

	return load(icon_path) as Texture2D



func get_weapon_offer_stats(template: Dictionary, tier: int) -> Dictionary:
	var scene := template.get("scene") as PackedScene
	if not scene:
		return {}

	var weapon := scene.instantiate() as Weapon
	if not weapon:
		return {}

	var damage_multiplier: float = Weapon.TIER_DAMAGE_MULTIPLIERS.get(tier, 1.0)
	var cooldown_multiplier: float = Weapon.TIER_COOLDOWN_MULTIPLIERS.get(tier, 1.0)
	var stats := {
		"damage": {
			"text": "%.1f" % (weapon.damage * damage_multiplier),
			"delta": damage_multiplier - 1.0,
		},
		"cooldown": {
			"text": "%.2fs" % (weapon.cooldown * cooldown_multiplier),
			"delta": 1.0 - cooldown_multiplier,
		},
		"range": {
			"text": "%d" % roundi(weapon.range),
			"delta": 0.0,
		},
		"crit_chance": {
			"text": "%d%%" % roundi(weapon.critical_rate * 100.0),
			"delta": 0.0,
		},
		"crit_damage_multiplier": {
			"text": "%.2fx" % weapon.critical_damage_multiplier,
			"delta": 0.0,
		},
	}
	weapon.free()
	return stats

func roll_offer_tier(luck: float) -> int:
	var weights := [
		100.0,
		24.0 * (1.0 + luck * 0.15),
		8.0 * (1.0 + luck * 0.3),
		2.0 * (1.0 + luck * 0.55),
		0.5 * (1.0 + luck * 0.85),
	]
	var total_weight := 0.0
	for weight in weights:
		total_weight += maxf(weight, 0.0)

	var roll := randf() * total_weight
	for tier in range(weights.size()):
		roll -= maxf(weights[tier], 0.0)
		if roll <= 0.0:
			return tier

	return 0

func get_offer_cost(base_cost: int, tier: int) -> int:
	return ceili(base_cost * pow(tier + 1, 1.7))
