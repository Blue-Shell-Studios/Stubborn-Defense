extends PanelContainer

const TIER_NAME_COLORS := {
	0: Color.WHITE,
	1: Color(0.35, 1.0, 0.45, 1.0),
	2: Color(0.35, 0.65, 1.0, 1.0),
	3: Color(0.78, 0.38, 1.0, 1.0),
	4: Color(1.0, 0.22, 0.18, 1.0),
}
const TIER_BG_COLORS := {
	1: Color(0.03, 0.14, 0.06, 1.0),
	2: Color(0.03, 0.08, 0.18, 1.0),
	3: Color(0.12, 0.05, 0.18, 1.0),
	4: Color(0.18, 0.04, 0.03, 1.0),
}
const GOOD_COLOR := Color(0.35, 1.0, 0.45, 1.0)
const BAD_COLOR := Color(1.0, 0.25, 0.2, 1.0)
const BASE_COLOR := Color.WHITE
const GOOD_BB := "#59ff73"
const BAD_BB := "#ff4033"
const BASE_BB := "#ffffff"
const PLAYER_BASE_STATS := {
	"max_hp": 100.0,
	"damage_bonus_percent": 0.0,
	"attack_speed_bonus_percent": 0.0,
	"crit_chance": 0.0,
	"crit_damage_multiplier": 1.0,
	"range": 0.0,
	"armor": 0.0,
	"dodge": 0.0,
	"speed": 800.0,
	"luck": 0.0,
}

@onready var shop_timer_label: Label = %ShopTimerLabel
@onready var shop_message_label: Label = %ShopMessageLabel
@onready var refresh_button: Button = %RefreshButton
@onready var combine_button: Button = %CombineButton
@onready var sell_button: Button = %SellButton
@onready var shop_stats_label: RichTextLabel = %ShopStatsLabel
@onready var offer_cards := [%OfferCard1, %OfferCard2, %OfferCard3]
@onready var offer_name_labels := [%OfferName1, %OfferName2, %OfferName3]
@onready var offer_type_labels := [%OfferType1, %OfferType2, %OfferType3]
@onready var offer_details_labels := [%OfferDetails1, %OfferDetails2, %OfferDetails3]
@onready var offer_buy_buttons := [%OfferBuyButton1, %OfferBuyButton2, %OfferBuyButton3]
@onready var offer_icons := [%OfferIcon1, %OfferIcon2, %OfferIcon3]
@onready var offer_lock_buttons := [%OfferLockButton1, %OfferLockButton2, %OfferLockButton3]
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
	shop_stats_label.bbcode_enabled = true
	for details_label in offer_details_labels:
		(details_label as RichTextLabel).bbcode_enabled = true

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
	for index in range(offer_lock_buttons.size()):
		offer_lock_buttons[index].toggled.connect(_on_offer_lock_toggled.bind(index))
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
		var details_label := offer_details_labels[index] as RichTextLabel
		var buy_button := offer_buy_buttons[index] as Button
		var icon := offer_icons[index] as TextureRect
		var lock_button := offer_lock_buttons[index] as Button
		if index >= offers.size():
			card.visible = false
			buy_button.disabled = true
			if icon:
				icon.visible = false
				icon.texture = null
			if lock_button:
				lock_button.visible = false
			continue

		card.visible = true
		var offer: Dictionary = offers[index]
		if offer.get("empty", false):
			name_label.text = "Empty"
			type_label.text = "-"
			details_label.text = ""
			buy_button.text = "Bought"
			buy_button.disabled = true
			if icon:
				icon.visible = false
				icon.texture = null
			if lock_button:
				lock_button.visible = false
			apply_tier_to_card(card, 0)
			apply_text_color(name_label, BASE_COLOR)
			continue

		var tier := int(offer.get("tier", 0))
		var offer_type := String(offer.get("type", "weapon"))
		apply_tier_to_card(card, tier)
		apply_text_color(name_label, get_tier_name_color(tier))
		name_label.text = offer["name"]
		type_label.text = offer_type.capitalize()
		buy_button.text = "Buy - %d Scrap" % offer["cost"]
		buy_button.disabled = false
		if lock_button:
			lock_button.visible = true
			lock_button.disabled = false
			var locked := bool(offer.get("locked", false))
			lock_button.button_pressed = locked
			_apply_lock_button_visual(lock_button, locked)

		var icon_texture := offer.get("icon") as Texture2D
		if icon and icon_texture:
			icon.texture = icon_texture
			icon.visible = true
		elif icon:
			icon.texture = null
			icon.visible = false
		if offer_type == "item":
			details_label.text = "%s\n%s" % [format_stat_summary_bb(offer.get("stat_modifiers", {})), escape_bbcode(offer.get("description", ""))]
		else:
			details_label.text = format_weapon_stats_bb(offer.get("weapon_stats", {}))

func _on_shop_weapons_changed(weapons: Array, selected_index: int) -> void:
	for index in range(weapon_slot_buttons.size()):
		var button := weapon_slot_buttons[index] as Button
		if index >= weapons.size() or weapons[index].get("empty", true):
			button.text = "Empty"
			button.disabled = true
			apply_tier_to_button(button, 0)
			apply_button_text_color(button, BASE_COLOR)
			continue

		var weapon: Dictionary = weapons[index]
		var tier := int(weapon.get("tier", 0))
		button.disabled = false
		button.text = get_compact_weapon_name(weapon["name"])
		if index == selected_index:
			button.text = "> " + button.text
		apply_tier_to_button(button, tier)
		apply_button_text_color(button, get_tier_name_color(tier))

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

func _on_offer_lock_toggled(locked: bool, index: int) -> void:
	SignalBus.shop_offer_lock_requested.emit(index, locked)
	var lock_button := offer_lock_buttons[index] as Button
	if lock_button:
		_apply_lock_button_visual(lock_button, locked)

func _apply_lock_button_visual(button: Button, locked: bool) -> void:
	button.text = "🔒" if locked else "🔓"

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
	shop_stats_label.text = "\n".join(PackedStringArray([
		"[b]Stats[/b]",
		format_compared_line("HP", "%d / %d" % [roundi(current_health), roundi(current_max_health)], current_health - current_max_health),
		format_neutral_line("EXP", "%d / %d" % [roundi(current_exp), roundi(current_max_exp)]),
		format_neutral_line("Scrap", "%d" % current_scrap),
		format_compared_line("Max HP", "%d" % roundi(current_player_stats.get("max_hp", PLAYER_BASE_STATS["max_hp"])), current_player_stats.get("max_hp", PLAYER_BASE_STATS["max_hp"]) - PLAYER_BASE_STATS["max_hp"]),
		format_compared_line("Damage", "%+d%%" % roundi(current_player_stats.get("damage_bonus_percent", 0.0)), current_player_stats.get("damage_bonus_percent", 0.0)),
		format_compared_line("Attack Speed", "%+d%%" % roundi(current_player_stats.get("attack_speed_bonus_percent", 0.0)), current_player_stats.get("attack_speed_bonus_percent", 0.0)),
		format_compared_line("Crit Chance", "%d%%" % roundi(current_player_stats.get("crit_chance", 0.0) * 100.0), current_player_stats.get("crit_chance", 0.0)),
		format_compared_line("Crit Damage", "%.2fx" % current_player_stats.get("crit_damage_multiplier", 1.0), current_player_stats.get("crit_damage_multiplier", 1.0) - PLAYER_BASE_STATS["crit_damage_multiplier"]),
		format_compared_line("Range", "%+d" % roundi(current_player_stats.get("range", 0.0)), current_player_stats.get("range", 0.0)),
		format_compared_line("Armor", "%d" % roundi(current_player_stats.get("armor", 0.0)), current_player_stats.get("armor", 0.0)),
		format_compared_line("Dodge", "%d%%" % roundi(current_player_stats.get("dodge", 0.0) * 100.0), current_player_stats.get("dodge", 0.0)),
		format_compared_line("Speed", "%d" % roundi(current_player_stats.get("speed", PLAYER_BASE_STATS["speed"])), current_player_stats.get("speed", PLAYER_BASE_STATS["speed"]) - PLAYER_BASE_STATS["speed"]),
		format_compared_line("Luck", "%d" % roundi(current_player_stats.get("luck", 0.0)), current_player_stats.get("luck", 0.0)),
	]))

func apply_tier_to_card(card: Control, tier: int) -> void:
	if tier <= 0:
		card.remove_theme_stylebox_override("panel")
		return

	var style := create_panel_style(TIER_BG_COLORS.get(tier, Color(0.08, 0.08, 0.1, 1.0)), get_tier_name_color(tier))
	card.add_theme_stylebox_override("panel", style)

func apply_tier_to_button(button: Button, tier: int) -> void:
	if tier <= 0:
		for style_name in ["normal", "hover", "pressed", "disabled"]:
			button.remove_theme_stylebox_override(style_name)
		return

	var bg_color: Color = TIER_BG_COLORS.get(tier, Color(0.08, 0.08, 0.1, 1.0))
	var border_color := get_tier_name_color(tier)
	button.add_theme_stylebox_override("normal", create_panel_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", create_panel_style(bg_color.lightened(0.08), border_color))
	button.add_theme_stylebox_override("pressed", create_panel_style(bg_color.darkened(0.08), border_color))
	button.add_theme_stylebox_override("disabled", create_panel_style(bg_color.darkened(0.18), border_color.darkened(0.3)))

func create_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style

func apply_text_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)

func apply_button_text_color(button: Button, color: Color) -> void:
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, color)

func get_tier_name_color(tier: int) -> Color:
	return TIER_NAME_COLORS.get(tier, BASE_COLOR)

func format_stat_summary_bb(stat_modifiers: Dictionary) -> String:
	if stat_modifiers.is_empty():
		return colorize_bb("No stat change", BASE_BB)

	var parts: Array[String] = []
	for stat_key in stat_modifiers:
		var stat_name := String(stat_key)
		var value: float = stat_modifiers[stat_key]
		parts.append("%s %s" % [get_stat_label(stat_name), colorize_bb(get_signed_value_text(stat_name, value), get_value_bb_color(value))])

	return ", ".join(PackedStringArray(parts))

func format_weapon_stats_bb(weapon_stats: Dictionary) -> String:
	if weapon_stats.is_empty():
		return colorize_bb("Weapon", BASE_BB)

	var parts: Array[String] = []
	for stat_key in weapon_stats:
		var stat_data: Dictionary = weapon_stats[stat_key]
		var stat_name := String(stat_key)
		var value_text := String(stat_data.get("text", ""))
		var delta := float(stat_data.get("delta", 0.0))
		parts.append("%s %s" % [get_stat_label(stat_name), colorize_bb(value_text, get_value_bb_color(delta))])

	return ", ".join(PackedStringArray(parts))

func format_compared_line(label: String, value_text: String, delta: float) -> String:
	return "%s: %s" % [label, colorize_bb(value_text, get_value_bb_color(delta))]

func format_neutral_line(label: String, value_text: String) -> String:
	return "%s: %s" % [label, colorize_bb(value_text, BASE_BB)]

func colorize_bb(text: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, escape_bbcode(text)]

func get_value_bb_color(value: float) -> String:
	if value > 0.0:
		return GOOD_BB
	if value < 0.0:
		return BAD_BB
	return BASE_BB

func get_stat_label(stat_name: String) -> String:
	match stat_name:
		"max_hp":
			return "HP"
		"damage_bonus_percent":
			return "Damage"
		"attack_speed_bonus_percent":
			return "Atk Speed"
		"crit_chance":
			return "Crit"
		"cooldown":
			return "Cooldown"
		"damage":
			return "Damage"
		"crit_damage_multiplier":
			return "Crit Dmg"
		"range":
			return "Range"
		"armor":
			return "Armor"
		"dodge":
			return "Dodge"
		"speed":
			return "Speed"
		"luck":
			return "Luck"
		_:
			return stat_name.capitalize()

func get_signed_value_text(stat_name: String, value: float) -> String:
	if stat_name.ends_with("_percent"):
		return "%+d%%" % roundi(value)
	if stat_name == "crit_chance" or stat_name == "dodge":
		return "%+d%%" % roundi(value * 100.0)
	if stat_name == "crit_damage_multiplier":
		return "%+.2fx" % value

	return "%+d" % roundi(value)

func escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
