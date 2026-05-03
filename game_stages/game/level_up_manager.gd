class_name LevelUpManager extends Node

const UPGRADE_POOL := [
	{"id": "hull_patch", "name": "Hull Patch Protocol", "description": "Emergency nanites reinforce your frame.", "cost": 0, "stats": {"max_hp": 10.0}},
	{"id": "plasma_tune", "name": "Plasma Tuning", "description": "Weapons burn hotter after calibration.", "cost": 0, "stats": {"damage_bonus_percent": 6.0}},
	{"id": "rapid_cycle", "name": "Rapid Cycle Matrix", "description": "Reload and charge systems pulse faster.", "cost": 0, "stats": {"attack_speed_bonus_percent": 7.0}},
	{"id": "target_oracle", "name": "Target Oracle", "description": "Predictive optics find fragile armor seams.", "cost": 0, "stats": {"crit_chance": 0.04}},
	{"id": "singularity_focus", "name": "Singularity Focus", "description": "Critical strikes hit with denser energy.", "cost": 0, "stats": {"crit_damage_multiplier": 0.12}},
	{"id": "deep_scan_array", "name": "Deep Scan Array", "description": "Weapon sensors lock on from farther away.", "cost": 0, "stats": {"range": 35.0}},
	{"id": "meteor_armor", "name": "Meteor Armor", "description": "Reactive plates blunt incoming impacts.", "cost": 0, "stats": {"armor": 1.0}},
	{"id": "phase_veil", "name": "Phase Veil", "description": "Short flickers make direct hits less certain.", "cost": 0, "stats": {"dodge": 0.025}},
	{"id": "solar_sail", "name": "Solar Sail Tuning", "description": "Thrusters catch more stellar pressure.", "cost": 0, "stats": {"speed": 35.0}},
	{"id": "fortune_beacon", "name": "Fortune Beacon", "description": "Salvage telemetry improves future rolls.", "cost": 0, "stats": {"luck": 1.5}},
]

@export var choice_count := 4
@export var refresh_cost := 8

var choices: Array[ShopItem] = []
var is_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	SignalBus.player_level_up_available.connect(_on_player_level_up_available)
	SignalBus.level_up_choice_selected.connect(select_choice)
	SignalBus.level_up_refresh_requested.connect(refresh_with_payment)

func _on_player_level_up_available(level: int) -> void:
	if is_open:
		return

	open_choices()

func open_choices() -> void:
	is_open = true
	SignalBus.shop_visibility_changed.emit(false)
	get_tree().paused = true
	SignalBus.level_up_visibility_changed.emit(true)
	SignalBus.level_up_message_changed.emit("")
	refresh_choices()

func close_choices() -> void:
	is_open = false
	get_tree().paused = false
	SignalBus.level_up_visibility_changed.emit(false)
	SignalBus.level_up_message_changed.emit("")

func refresh_choices() -> void:
	choices.clear()
	var player := get_player()
	var used_ids := {}
	for index in range(mini(choice_count, UPGRADE_POOL.size())):
		var template := get_unused_template(used_ids)
		used_ids[template["id"]] = true
		choices.append(create_upgrade_choice(template, roll_upgrade_tier(player.luck if player else 0.0)))

	emit_choices()

func refresh_with_payment() -> void:
	if not is_open:
		return

	var player := get_player()
	if not player:
		return

	if not player.spend_scrap(refresh_cost):
		SignalBus.level_up_message_changed.emit("Not enough scrap to refresh.")
		return

	SignalBus.level_up_message_changed.emit("")
	refresh_choices()

func select_choice(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= choices.size():
		return

	var player := get_player()
	if not player:
		return

	player.apply_item(choices[choice_index])
	var has_more_level_ups := player.resolve_level_up()
	if has_more_level_ups:
		SignalBus.level_up_message_changed.emit("")
		refresh_choices()
	else:
		close_choices()

func emit_choices() -> void:
	var snapshots: Array[Dictionary] = []
	for choice in choices:
		snapshots.append({
			"tier": choice.tier,
			"summary": choice.get_stat_summary(),
		})

	SignalBus.level_up_choices_changed.emit(snapshots, refresh_cost)

func get_unused_template(used_ids: Dictionary) -> Dictionary:
	var available: Array[Dictionary] = []
	for template in UPGRADE_POOL:
		if not used_ids.has(template["id"]):
			available.append(template)

	return available.pick_random()

func create_upgrade_choice(template: Dictionary, tier: int) -> ShopItem:
	var stats: Dictionary = template["stats"]
	return ShopItem.new().setup(
		template["id"],
		template["name"],
		template["description"],
		int(template["cost"]),
		stats,
		tier
	)

func roll_upgrade_tier(luck: float) -> int:
	var weights := [
		100.0,
		26.0 * (1.0 + luck * 0.16),
		9.0 * (1.0 + luck * 0.32),
		2.5 * (1.0 + luck * 0.58),
		0.6 * (1.0 + luck * 0.9),
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

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player_target") as Player
