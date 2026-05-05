class_name UpgradeCatalog
extends Object

const UPGRADE_POOL := [
	{"id": "hull_patch", "name": "Hull Patch Protocol", "description": "Emergency nanites reinforce your frame.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Hull Patch Protocol.png", "stats": {"max_hp": 10.0}},
	{"id": "plasma_tune", "name": "Plasma Tuning", "description": "Weapons burn hotter after calibration.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Plasma Tuning.png", "stats": {"damage_bonus_percent": 5.0}},
	{"id": "rapid_cycle", "name": "Rapid Cycle Matrix", "description": "Reload and charge systems pulse faster.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Rapid Cycle Matrix.png", "stats": {"attack_speed_bonus_percent": 6.0}},
	{"id": "target_oracle", "name": "Target Oracle", "description": "Predictive optics find fragile armor seams.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Target Oracle.png", "stats": {"crit_chance": 0.04}},
	{"id": "singularity_focus", "name": "Singularity Focus", "description": "Critical strikes hit with denser energy.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Singularity Focus.png", "stats": {"crit_damage_multiplier": 0.12}},
	{"id": "deep_scan_array", "name": "Deep Scan Array", "description": "Weapon sensors lock on from farther away.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Deep Scan Array.png", "stats": {"range": 25.0}},
	{"id": "meteor_armor", "name": "Meteor Armor", "description": "Reactive plates blunt incoming impacts.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Meteor Armor.png", "stats": {"armor": 1.0}},
	{"id": "phase_veil", "name": "Phase Veil", "description": "Short flickers make direct hits less certain.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Phase Veil.png", "stats": {"dodge": 0.025}},
	{"id": "solar_sail", "name": "Solar Sail Tuning", "description": "Thrusters catch more stellar pressure.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Solar Sail Tuning.png", "stats": {"speed": 35.0}},
	{"id": "fortune_beacon", "name": "Fortune Beacon", "description": "Salvage telemetry improves future rolls.", "cost": 0, "icon": "res://asset/shop_icons/upgrade_icon/Fortune Beacon.png", "stats": {"luck": 1.2}},
]

