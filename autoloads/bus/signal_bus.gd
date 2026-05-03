extends Node

signal player_stats_requested
signal player_health_changed(current_health: float, max_health: float)
signal player_exp_changed(current_exp: float, max_exp: float)
signal player_level_changed(level: int)
signal player_level_up_available(level: int)
signal player_scrap_changed(scrap_count: int)
signal player_position_changed(position: Vector2)
signal player_stats_changed(stats: Dictionary)
signal player_revive_countdown_changed(seconds_left: int)
signal game_over_triggered
signal planet_status_changed(
	current_health: float,
	max_health: float,
	current_shield: float,
	max_shield: float,
	shield_active: bool,
	shield_shutdown_time_left: float,
	shield_shutdown_duration: float
)
signal level_up_visibility_changed(is_visible: bool)
signal level_up_choices_changed(choices: Array, refresh_cost: int)
signal level_up_choice_selected(choice_index: int)
signal level_up_refresh_requested
signal level_up_message_changed(message: String)
signal shop_available_changed(is_available: bool)
signal shop_toggle_requested
signal shop_visibility_changed(is_visible: bool)
signal shop_offers_changed(offers: Array, refresh_time_left: float, refresh_cost: int)
signal shop_weapons_changed(weapons: Array, selected_index: int)
signal shop_selected_weapon_changed(weapon: Dictionary, can_combine: bool, sell_value: int)
signal shop_buy_requested(offer_index: int)
signal shop_refresh_requested
signal shop_weapon_selected(weapon_index: int)
signal shop_selected_weapon_combine_requested
signal shop_selected_weapon_sell_requested
signal shop_message_changed(message: String)
