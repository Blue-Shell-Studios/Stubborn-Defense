class_name ShopItem extends Resource

const TIER_MULTIPLIERS := {
	0: 1.0,
	1: 1.35,
	2: 1.8,
	3: 2.4,
	4: 3.2,
}

@export var item_id := ""
@export var display_name := "Item"
@export_multiline var description := ""
@export var base_cost := 10
@export var stat_modifiers := {}
@export_range(0, 4, 1) var tier := 0

func setup(
	new_item_id: String,
	new_display_name: String,
	new_description: String,
	new_base_cost: int,
	new_stat_modifiers: Dictionary,
	new_tier: int
) -> ShopItem:
	item_id = new_item_id
	display_name = new_display_name
	description = new_description
	base_cost = new_base_cost
	stat_modifiers = new_stat_modifiers
	tier = clampi(new_tier, 0, 4)
	return self

func get_cost() -> int:
	return ceili(base_cost * pow(tier + 1, 1.45))

func get_scaled_stat_modifiers() -> Dictionary:
	var scaled_stats := {}
	var tier_multiplier: float = TIER_MULTIPLIERS.get(tier, 1.0)
	for stat_name in stat_modifiers:
		scaled_stats[stat_name] = stat_modifiers[stat_name] * tier_multiplier

	return scaled_stats

func get_shop_text() -> String:
	return "%s\nTier %d\n%s\n%d Scrap" % [
		display_name,
		tier,
		get_stat_summary(),
		get_cost(),
	]

func get_stat_summary() -> String:
	var parts: Array[String] = []
	var scaled_stats := get_scaled_stat_modifiers()
	for stat_key in scaled_stats:
		var stat_name := String(stat_key)
		var value: float = scaled_stats[stat_name]
		parts.append("%s %s" % [get_stat_label(stat_name), get_signed_value_text(stat_name, value)])

	return ", ".join(PackedStringArray(parts))

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
