extends GameStage

const FodderScene := preload("res://entities/enemies/basic/fodder.tscn")
const ShooterEnemyScene := preload("res://entities/enemies/shooter/shooter_enemy.tscn")
const DasherEnemyScene := preload("res://entities/enemies/dasher/dasher_enemy.tscn")
const BossEnemyScene := preload("res://entities/enemies/boss/boss_enemy.tscn")

@export var map_size := Vector2(3000.0, 3000.0)
@export var edge_spawn_padding := 32.0

@export var max_waves := 10
@export var calm_duration := 6.0
@export var spawn_interval := 1.4

# Difficulty scaling per wave. Keep it readable and tunable in-editor.
@export var enemy_health_scale_per_wave := 0.14
@export var enemy_damage_scale_per_wave := 0.10
@export var enemy_speed_scale_per_wave := 0.02

var wave_index := 0
var wave_spawn_remaining := 0
var spawn_timer := 0.0
var calm_timer := 0.0
var is_in_calm := false
var boss_instance: BossEnemy
var has_won := false

func _ready() -> void:
	type = Type.GAME
	randomize()
	_start_next_wave()

func _process(delta: float) -> void:
	_check_win_condition()
	_tick_waves(delta)
	_update_dire_threat_state()

func _check_win_condition() -> void:
	if has_won:
		return

	if wave_index != max_waves:
		return

	if is_instance_valid(boss_instance) and boss_instance.is_destroyed:
		has_won = true
		# Stop any remaining scheduled spawns; the HUD will pause the game.
		wave_spawn_remaining = 0
		SignalBus.game_win_triggered.emit()

func _tick_waves(delta: float) -> void:
	# Spawning phase.
	if wave_spawn_remaining > 0:
		is_in_calm = false
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = spawn_interval
			_spawn_wave_enemy()
			wave_spawn_remaining -= 1
		return

	# Cleanup/calm phase.
	if _alive_enemy_count() > 0:
		is_in_calm = false
		return

	if not is_in_calm:
		is_in_calm = true
		calm_timer = calm_duration
		return

	calm_timer = maxf(calm_timer - delta, 0.0)
	if calm_timer <= 0.0 and wave_index < max_waves:
		_start_next_wave()

func _start_next_wave() -> void:
	wave_index += 1
	if wave_index > max_waves:
		return

	# New wave begins immediately. Calm time is applied after the wave is cleared.
	spawn_timer = 0.0

	# Scale spawns by wave. This is intentionally simple; we'll tune numbers once the feel is right.
	wave_spawn_remaining = 6 + wave_index * 3

	# Wave 10 is the boss push.
	if wave_index == max_waves:
		spawn_boss()
		# Keep some pressure on during the boss wave.
		wave_spawn_remaining = 16

func _update_dire_threat_state() -> void:
	var planet := get_tree().get_first_node_in_group("planet_objective") as Planet
	if not planet:
		return

	var boss_alive := is_instance_valid(boss_instance) and not boss_instance.is_destroyed
	planet.set_dire_threat_active(boss_alive)

func _spawn_wave_enemy() -> void:
	# Order of appearance: fodder -> shooter -> chargers (dashers).
	# Wave 1-2: fodder only
	# Wave 3-5: introduce shooters
	# Wave 6-10: introduce dashers
	var roll := randf()
	if wave_index >= 6:
		# Late game: lots of fodder pressure, plus dashers and some shooters.
		if roll < 0.22:
			spawn_dasher()
		elif roll < 0.45:
			spawn_shooter()
		else:
			spawn_fodder()
	elif wave_index >= 3:
		# Mid game: mix fodder + shooters.
		if roll < 0.28:
			spawn_shooter()
		else:
			spawn_fodder()
	else:
		spawn_fodder()

func spawn_fodder() -> void:
	var pos := get_random_edge_position()
	var fodder := FodderScene.instantiate() as Enemy
	add_child(fodder)
	fodder.global_position = pos
	_apply_wave_scaling(fodder)

func spawn_shooter() -> void:
	var pos := get_random_edge_position()
	var shooter := ShooterEnemyScene.instantiate() as Enemy
	add_child(shooter)
	shooter.global_position = pos
	_apply_wave_scaling(shooter)

func spawn_dasher() -> void:
	var pos := get_random_edge_position()
	var dasher := DasherEnemyScene.instantiate() as Enemy
	add_child(dasher)
	dasher.global_position = pos
	_apply_wave_scaling(dasher)

func spawn_boss() -> void:
	var pos := get_random_edge_position()
	boss_instance = BossEnemyScene.instantiate() as BossEnemy
	add_child(boss_instance)
	boss_instance.global_position = pos
	_apply_boss_scaling(boss_instance)

func _get_wave_multiplier(scale_per_wave: float) -> float:
	# Wave 1 should be baseline (1.0).
	return maxf(1.0, 1.0 + scale_per_wave * maxf(0.0, float(wave_index - 1)))

func _apply_wave_scaling(enemy: Enemy) -> void:
	if not enemy:
		return

	var hp_mult := _get_wave_multiplier(enemy_health_scale_per_wave)
	var dmg_mult := _get_wave_multiplier(enemy_damage_scale_per_wave)
	var spd_mult := _get_wave_multiplier(enemy_speed_scale_per_wave)

	enemy.max_health = enemy.max_health * hp_mult
	enemy.health = enemy.max_health
	enemy.attack_damage = enemy.attack_damage * dmg_mult
	enemy.move_speed = enemy.move_speed * spd_mult

func _apply_boss_scaling(boss: BossEnemy) -> void:
	if not boss:
		return

	# Boss appears at wave 10. Still scale slightly so late-game power doesn't trivialize it,
	# but avoid runaway values; the boss should feel beatable with good gear.
	var hp_mult := 1.0 + 0.08 * maxf(0.0, float(wave_index - 7))
	var dmg_mult := 1.0 + 0.06 * maxf(0.0, float(wave_index - 7))

	boss.max_health = boss.max_health * hp_mult
	boss.health = boss.max_health
	boss.red_ball_damage = boss.red_ball_damage * dmg_mult
	boss.beam_damage = boss.beam_damage * dmg_mult

func _alive_enemy_count() -> int:
	# Enemies register themselves in the "enemies" group (see Enemy.gd).
	var alive := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_destroyed:
			alive += 1
	return alive

func get_random_edge_position() -> Vector2:
	var edge := randi_range(0, 3)

	match edge:
		0:
			return Vector2(randf_range(0.0, map_size.x), -edge_spawn_padding)
		1:
			return Vector2(map_size.x + edge_spawn_padding, randf_range(0.0, map_size.y))
		2:
			return Vector2(randf_range(0.0, map_size.x), map_size.y + edge_spawn_padding)
		_:
			return Vector2(-edge_spawn_padding, randf_range(0.0, map_size.y))
