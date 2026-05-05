class_name LevelUpManager extends Node

const UPGRADE_POOL := UpgradeCatalog.UPGRADE_POOL

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
	SignalBus.level_up_visibility_changed.emit(true)
	SignalBus.level_up_message_changed.emit("")
	refresh_choices()

func close_choices() -> void:
	is_open = false
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
			"stat_modifiers": choice.get_scaled_stat_modifiers(),
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
	var icon := _get_upgrade_icon(template)
	return ShopItem.new().setup(
		template["id"],
		template["name"],
		template["description"],
		icon,
		int(template["cost"]),
		stats,
		tier
	)

func _get_upgrade_icon(template: Dictionary) -> Texture2D:
	return IconLoader.load_texture(template.get("icon"))

func roll_upgrade_tier(luck: float) -> int:
	var weights := [
		100.0,
		26.0 * (1.0 + luck * 0.16),
		9.0 * (1.0 + luck * 0.32),
		2.5 * (1.0 + luck * 0.58),
		0.6 * (1.0 + luck * 0.9),
	]
	return WeightedRoll.pick_index(weights)

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player_target") as Player
