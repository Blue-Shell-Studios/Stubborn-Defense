class_name ShopManager extends Node

const WEAPON_POOL := [
	{
		"id": "gatling_turret",
		"name": "Gatling Turret",
		"scene": preload("res://entities/weapons/gatling_turret/gatling_turret.tscn"),
		"cost": 12,
	},
	{
		"id": "torpedo_launcher",
		"name": "Torpedo Launcher",
		"scene": preload("res://entities/weapons/torpedo_launcher/torpedo_launcher.tscn"),
		"cost": 24,
	},
	{
		"id": "beam_emitter",
		"name": "Beam Emitter",
		"scene": preload("res://entities/weapons/beam_emitter/beam_emitter.tscn"),
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
	},
	{
		"id": "ion_overcharger",
		"name": "Ion Overcharger",
		"description": "Pushes extra current through weapon emitters.",
		"cost": 14,
		"stats": {"damage_bonus_percent": 8.0, "attack_speed_bonus_percent": -3.0},
	},
	{
		"id": "pulse_regulator",
		"name": "Pulse Regulator",
		"description": "Stabilizes firing cycles for quicker volleys.",
		"cost": 13,
		"stats": {"attack_speed_bonus_percent": 10.0},
	},
	{
		"id": "comet_lens",
		"name": "Comet Lens",
		"description": "Focuses weapon tracking beyond standard range.",
		"cost": 12,
		"stats": {"range": 45.0},
	},
	{
		"id": "void_targeter",
		"name": "Void Targeter",
		"description": "Highlights weak points in hostile hulls.",
		"cost": 16,
		"stats": {"crit_chance": 0.05, "crit_damage_multiplier": 0.15},
	},
	{
		"id": "phase_thrusters",
		"name": "Phase Thrusters",
		"description": "Adds erratic micro-jumps to your flight path.",
		"cost": 15,
		"stats": {"speed": 45.0, "dodge": 0.03},
	},
	{
		"id": "starfinder_core",
		"name": "Starfinder Core",
		"description": "Improves salvage scans and rare stock discovery.",
		"cost": 18,
		"stats": {"luck": 2.0},
	},
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
	offers.clear()
	var player := get_player()
	var has_item_offer := false
	for index in range(offer_count):
		var tier := roll_offer_tier(player.luck if player else 0.0)
		var offer := create_random_offer(tier)
		has_item_offer = has_item_offer or offer.get("type", "weapon") == "item"
		offers.append(offer)

	if offer_count > 0 and not has_item_offer:
		var tier := roll_offer_tier(player.luck if player else 0.0)
		offers[randi_range(0, offers.size() - 1)] = create_item_offer(ITEM_POOL.pick_random(), tier)

	refresh_time_left = auto_refresh_interval
	SignalBus.shop_message_changed.emit("")
	emit_shop_state()

func refresh_with_payment() -> void:
	var player := get_player()
	if not player:
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
	return {
		"empty": false,
		"type": "weapon",
		"id": template["id"],
		"name": template["name"],
		"scene": template["scene"],
		"cost": get_offer_cost(int(template["cost"]), tier),
		"tier": tier,
		"description": "Weapon",
	}

func create_item_offer(template: Dictionary, tier: int) -> Dictionary:
	var stats: Dictionary = template["stats"]
	var item := ShopItem.new().setup(
		template["id"],
		template["name"],
		template["description"],
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
		"item": item,
	}

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
	return ceili(base_cost * pow(tier + 1, 1.5))
