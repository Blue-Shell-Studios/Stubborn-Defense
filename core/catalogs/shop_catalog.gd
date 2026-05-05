class_name ShopCatalog
extends Object

# Pure data: keep the pools in one place so ShopManager can focus on behavior.

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

