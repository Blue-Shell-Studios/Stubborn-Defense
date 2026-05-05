extends Node

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"

const MUSIC_MENU: AudioStream = preload("res://asset/sound/music/menu_track.ogg")
const MUSIC_GAME: AudioStream = preload("res://asset/sound/music/game_track.ogg")

const SFX_COLLECT_SCRAP: AudioStream = preload("res://asset/sound/sfx/collect_scrap.mp3")
const SFX_SHIELD_REGEN: AudioStream = preload("res://asset/sound/sfx/shield_regen.mp3")
const SFX_PLAYER_HIT: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/impactMetal_000.ogg")
const SFX_UI_CLICK: AudioStream = preload("res://asset/sound/sfx/kenney/interface/Audio/click_001.ogg")

const SFX_FIRE_GATLING: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/laserSmall_000.ogg")
const SFX_FIRE_TORPEDO: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/laserLarge_000.ogg")
const SFX_FIRE_BEAM: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/laserRetro_000.ogg")

const SFX_PROJECTILE_HIT: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/impactMetal_001.ogg")
const SFX_PROJECTILE_EXPLODE: AudioStream = preload("res://asset/sound/sfx/kenney/sci-fi/Audio/explosionCrunch_000.ogg")

@export var master_volume_db := 0.0
@export var music_volume_db := -6.0
@export var sfx_volume_db := -4.0

@export var max_simultaneous_sfx := 12

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0

var _current_stage_type := -1
var _last_planet_shield := -1.0
var _shield_regen_cooldown := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_ensure_audio_buses()
	_create_players()
	_apply_bus_volumes()

	SignalBus.player_hit.connect(func(_damage: float) -> void:
		play_sfx_stream(SFX_PLAYER_HIT, -2.0, 0.1)
	)
	# UI SFX are triggered directly by button handlers (ui_click). No open/close stingers for now.

func _process(delta: float) -> void:
	_tick_music()
	_tick_planet_shield_regen(delta)

func _tick_planet_shield_regen(delta: float) -> void:
	_shield_regen_cooldown = maxf(_shield_regen_cooldown - delta, 0.0)

	var planet := get_tree().get_first_node_in_group("planet_objective") as Node
	if not planet:
		_last_planet_shield = -1.0
		return

	var shield_value: float = planet.get("shield")
	if typeof(shield_value) != TYPE_FLOAT and typeof(shield_value) != TYPE_INT:
		return

	var current_shield := float(shield_value)
	if _last_planet_shield < 0.0:
		_last_planet_shield = current_shield
		return

	var is_regening := current_shield > _last_planet_shield + 0.1
	_last_planet_shield = current_shield

	if is_regening and _shield_regen_cooldown <= 0.0:
		_shield_regen_cooldown = 1.2
		play_sfx_stream(SFX_SHIELD_REGEN, -12.0, 0.0)

func play_sfx(id: String) -> void:
	match id:
		"collect_scrap":
			play_sfx_stream(SFX_COLLECT_SCRAP, -3.0, 0.08)
		"ui_click":
			play_sfx_stream(SFX_UI_CLICK, -8.0, 0.0)
		"projectile_hit":
			play_sfx_stream(SFX_PROJECTILE_HIT, -7.0, 0.05)
		"projectile_explode":
			play_sfx_stream(SFX_PROJECTILE_EXPLODE, -4.0, 0.04)
		_:
			pass

func play_weapon_fire(weapon_id: String) -> void:
	match weapon_id:
		"gatling_turret":
			play_sfx_stream(SFX_FIRE_GATLING, -10.0, 0.08)
		"torpedo_launcher":
			play_sfx_stream(SFX_FIRE_TORPEDO, -8.0, 0.03)
		"beam_emitter":
			play_sfx_stream(SFX_FIRE_BEAM, -11.0, 0.02)
		_:
			play_sfx_stream(SFX_FIRE_GATLING, -10.0, 0.08)

func play_music(track: String) -> void:
	match track:
		"menu":
			_set_music_stream(MUSIC_MENU)
		"game":
			_set_music_stream(MUSIC_GAME)
		"none":
			if is_instance_valid(_music_player):
				_music_player.stop()
		_:
			pass

func play_sfx_stream(stream: AudioStream, volume_db: float = 0.0, pitch_random: float = 0.0) -> void:
	if not stream:
		return
	if _sfx_players.is_empty():
		return

	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_random, pitch_random)
	player.play()

func _tick_music() -> void:
	if not is_instance_valid(GameStateManager) or not GameStateManager.current_stage:
		return
	var stage_type := int(GameStateManager.current_stage.type)
	if stage_type == _current_stage_type:
		return
	_current_stage_type = stage_type

	match stage_type:
		GameStage.Type.MAIN_MENU:
			play_music("menu")
		GameStage.Type.GAME:
			play_music("game")

func _set_music_stream(stream: AudioStream) -> void:
	if not is_instance_valid(_music_player) or not stream:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()

func _create_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.volume_db = 0.0
	_music_player.autoplay = false
	add_child(_music_player)

	_sfx_players.clear()
	var count := maxi(1, max_simultaneous_sfx)
	for _i in range(count):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

func _ensure_audio_buses() -> void:
	# Create buses if missing so the project works without manual editor setup.
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	if music_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_MUSIC)

	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	if sfx_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)

func _apply_bus_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), master_volume_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), music_volume_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), sfx_volume_db)
