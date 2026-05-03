extends PanelContainer

@onready var shop_timer_label: Label = %ShopTimerLabel
@onready var shop_message_label: Label = %ShopMessageLabel
@onready var refresh_button: Button = %RefreshButton
@onready var combine_button: Button = %CombineButton
@onready var sell_button: Button = %SellButton
@onready var shop_stats_label: Label = %ShopStatsLabel
@onready var offer_cards := [%OfferCard1, %OfferCard2, %OfferCard3]
@onready var offer_name_labels := [%OfferName1, %OfferName2, %OfferName3]
@onready var offer_type_labels := [%OfferType1, %OfferType2, %OfferType3]
@onready var offer_details_labels := [%OfferDetails1, %OfferDetails2, %OfferDetails3]
@onready var offer_buy_buttons := [%OfferBuyButton1, %OfferBuyButton2, %OfferBuyButton3]
@onready var weapon_slot_buttons := [%WeaponSlot1, %WeaponSlot2, %WeaponSlot3, %WeaponSlot4, %WeaponSlot5, %WeaponSlot6]

var current_health := 0.0
var current_max_health := 0.0
var current_exp := 0.0
var current_max_exp := 0.0
var current_scrap := 0
var current_player_stats := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	SignalBus.player_health_changed.connect(_on_player_health_changed)
	SignalBus.player_exp_changed.connect(_on_player_exp_changed)
	SignalBus.player_scrap_changed.connect(_on_player_scrap_changed)
	SignalBus.player_stats_changed.connect(_on_player_stats_changed)
	SignalBus.shop_available_changed.connect(_on_shop_available_changed)
	SignalBus.shop_visibility_changed.connect(_on_shop_visibility_changed)
	SignalBus.shop_offers_changed.connect(_on_shop_offers_changed)
	SignalBus.shop_weapons_changed.connect(_on_shop_weapons_changed)
	SignalBus.shop_selected_weapon_changed.connect(_on_shop_selected_weapon_changed)
	SignalBus.shop_message_changed.connect(_on_shop_message_changed)

	refresh_button.pressed.connect(_on_refresh_button_pressed)
	combine_button.pressed.connect(_on_combine_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	for index in range(offer_buy_buttons.size()):
		offer_buy_buttons[index].pressed.connect(_on_offer_button_pressed.bind(index))
	for index in range(weapon_slot_buttons.size()):
		weapon_slot_buttons[index].pressed.connect(_on_weapon_slot_pressed.bind(index))

func _on_player_health_changed(current_health: float, max_health: float) -> void:
	self.current_health = current_health
	current_max_health = max_health
	update_shop_stats()

func _on_player_exp_changed(current_exp: float, max_exp: float) -> void:
	self.current_exp = current_exp
	current_max_exp = max_exp
	update_shop_stats()

func _on_player_scrap_changed(scrap_count: int) -> void:
	current_scrap = scrap_count
	update_shop_stats()

func _on_player_stats_changed(stats: Dictionary) -> void:
	current_player_stats = stats
	update_shop_stats()

func _on_shop_available_changed(is_available: bool) -> void:
	if not is_available:
		visible = false

func _on_shop_visibility_changed(is_visible: bool) -> void:
	visible = is_visible

func _on_shop_offers_changed(offers: Array, refresh_time_left: float, refresh_cost: int) -> void:
	shop_timer_label.text = "Refresh: %ds" % ceili(refresh_time_left)
	refresh_button.text = "Refresh %d Scrap" % refresh_cost

	for index in range(offer_cards.size()):
		var card := offer_cards[index] as Control
		var name_label := offer_name_labels[index] as Label
		var type_label := offer_type_labels[index] as Label
		var details_label := offer_details_labels[index] as Label
		var buy_button := offer_buy_buttons[index] as Button
		if index >= offers.size():
			card.visible = false
			buy_button.disabled = true
			continue

		card.visible = true
		var offer: Dictionary = offers[index]
		if offer.get("empty", false):
			name_label.text = "Empty"
			type_label.text = "-"
			details_label.text = ""
			buy_button.text = "Bought"
			buy_button.disabled = true
			continue

		var offer_type := String(offer.get("type", "weapon"))
		name_label.text = offer["name"]
		type_label.text = "%s - Tier %d" % [offer_type.capitalize(), offer["tier"]]
		buy_button.text = "Buy - %d Scrap" % offer["cost"]
		buy_button.disabled = false
		if offer_type == "item":
			details_label.text = "%s\n%s" % [offer.get("summary", ""), offer.get("description", "")]
		else:
			details_label.text = offer.get("description", "Weapon")

func _on_shop_weapons_changed(weapons: Array, selected_index: int) -> void:
	for index in range(weapon_slot_buttons.size()):
		var button := weapon_slot_buttons[index] as Button
		if index >= weapons.size() or weapons[index].get("empty", true):
			button.text = "Empty"
			button.disabled = true
			continue

		var weapon: Dictionary = weapons[index]
		button.disabled = false
		button.text = "%s\nT%d" % [get_compact_weapon_name(weapon["name"]), weapon["tier"]]
		if index == selected_index:
			button.text = "> " + button.text

func _on_shop_selected_weapon_changed(weapon: Dictionary, can_combine: bool, sell_value: int) -> void:
	var has_weapon: bool = not weapon.is_empty() and not weapon.get("empty", true)
	combine_button.disabled = not has_weapon or not can_combine
	sell_button.disabled = not has_weapon

	if has_weapon:
		combine_button.text = "Combine" if can_combine else "No Match"
		sell_button.text = "Sell %d Scrap" % sell_value
	else:
		combine_button.text = "Combine"
		sell_button.text = "Sell"

func _on_shop_message_changed(message: String) -> void:
	shop_message_label.text = message

func _on_refresh_button_pressed() -> void:
	SignalBus.shop_refresh_requested.emit()

func _on_combine_button_pressed() -> void:
	SignalBus.shop_selected_weapon_combine_requested.emit()

func _on_sell_button_pressed() -> void:
	SignalBus.shop_selected_weapon_sell_requested.emit()

func _on_offer_button_pressed(index: int) -> void:
	SignalBus.shop_buy_requested.emit(index)

func _on_weapon_slot_pressed(index: int) -> void:
	SignalBus.shop_weapon_selected.emit(index)

func get_compact_weapon_name(weapon_name: String) -> String:
	match weapon_name:
		"Gatling Turret":
			return "Gatling"
		"Torpedo Launcher":
			return "Torpedo"
		"Beam Emitter":
			return "Beam"
		_:
			return weapon_name

func update_shop_stats() -> void:
	shop_stats_label.text = (
		"Stats\n"
		+ "HP: %d / %d\n"
		+ "EXP: %d / %d\n"
		+ "Scrap: %d\n"
		+ "Damage: %+d%%\n"
		+ "Attack Speed: %+d%%\n"
		+ "Crit Chance: %d%%\n"
		+ "Crit Damage: %.2fx\n"
		+ "Range: %+d\n"
		+ "Armor: %d\n"
		+ "Dodge: %d%%\n"
		+ "Speed: %d\n"
		+ "Luck: %d"
	) % [
		roundi(current_health),
		roundi(current_max_health),
		roundi(current_exp),
		roundi(current_max_exp),
		current_scrap,
		roundi(current_player_stats.get("damage_bonus_percent", 0.0)),
		roundi(current_player_stats.get("attack_speed_bonus_percent", 0.0)),
		roundi(current_player_stats.get("crit_chance", 0.0) * 100.0),
		current_player_stats.get("crit_damage_multiplier", 1.0),
		roundi(current_player_stats.get("range", 0.0)),
		roundi(current_player_stats.get("armor", 0.0)),
		roundi(current_player_stats.get("dodge", 0.0) * 100.0),
		roundi(current_player_stats.get("speed", 0.0)),
		roundi(current_player_stats.get("luck", 0.0)),
	]
