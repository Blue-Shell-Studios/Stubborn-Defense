# Stubborn Defense

Stubborn Defense is a 2D space survival defense game made in Godot. You pilot a lone ship protecting a central planet from waves of enemies, collecting scrap, upgrading weapons, and trying to keep the planet alive as long as possible.

## Features

- Main menu with play and exit flow.
- WASD spaceship movement with smooth rotation, acceleration, deceleration, and drift.
- Central planet objective with health, shield durability, delayed shield repair, and game-over state.
- Player health, EXP, level, scrap currency, revive countdown, and downed-state recovery.
- Scrap pickups that enemies drop and the player pulls in with a suction area.
- Floating weapon slots around the player, with up to 6 active weapons.
- Weapon tiers from 0 to 4 with colored outlines and stronger stats at higher tiers.
- Current weapons:
  - Gatling Turret
  - Torpedo Launcher
  - Beam Emitter
- Projectile system with bullets, torpedoes, beams, enemy projectiles, damage, cooldowns, crit chance, crit damage, and range.
- Floating damage text, with a stronger effect for critical hits.
- Enemy types:
  - Fodder: chases and attacks in melee range.
  - Shooter: keeps distance and fires red round projectiles.
- Full-screen shop near the planet with random weapons/items, paid refresh, auto refresh, buy buttons, weapon slots, combine, and sell.
- Level-up screen with 4 random stat upgrade choices and scrap-based refresh.
- Mini map with player-centered markers, planet marker, enemy markers, and edge arrows for off-range points.
- HUD panels for player stats, planet health/shield, revive countdown, shop, level-up choices, and game over.
- Web export support with GitHub Pages workflow.

## Controls

- `W`, `A`, `S`, `D`: move
- `P`: open shop when near the planet
- `Esc`: close shop
- Click game-over screen: return to main menu

## Project Layout

- `project.godot`: Godot project configuration.
- `core/main.tscn`: root scene loaded by the project.
- `autoloads/`: global managers and signal bus.
- `game_stages/`: main menu, game scene, shop manager, level-up manager.
- `entities/player/`: player movement, stats, weapon manager.
- `entities/planet/`: planet objective, shield, health, game-over trigger.
- `entities/enemies/`: shared enemy base and enemy scenes.
- `entities/weapons/`: shared weapon base and weapon scenes.
- `entities/projectiles/`: player and enemy projectiles.
- `entities/items/`: shop item resource class.
- `entities/pickups/`: scrap pickup behavior.
- `ui/hud/`: HUD panels and scripts.
- `ui/theme/`: project-wide font/theme.
- `export/web/`: exported web build.
- `.github/workflows/deploy-pages.yml`: GitHub Pages deploy workflow.

## Dev Notes

### Adding More Shop Items

Shop items are defined in `game_stages/game/shop_manager.gd` inside `ITEM_POOL`.

Add a new dictionary like this:

```gdscript
{
	"id": "gravity_capacitor",
	"name": "Gravity Capacitor",
	"description": "Improves ship handling and rare stock discovery.",
	"cost": 18,
	"stats": {"speed": 25.0, "luck": 1.0},
}
```

Supported player stat keys are handled in `entities/player/player.gd` inside `apply_stat_modifiers()`:

- `max_hp`
- `damage_bonus_percent`
- `attack_speed_bonus_percent`
- `crit_chance`
- `crit_damage_multiplier`
- `range`
- `armor`
- `dodge`
- `speed`
- `luck`

Item tier scaling is handled by `entities/items/shop_item.gd` through `TIER_MULTIPLIERS`.

### Adding More Level-Up Upgrades

Level-up choices are separate from shop stock. Add level-up upgrades in `game_stages/game/level_up_manager.gd` inside `UPGRADE_POOL`.

Use the same stat keys as shop items:

```gdscript
{"id": "shielded_cockpit", "name": "Shielded Cockpit", "description": "Emergency plating improves survivability.", "cost": 0, "stats": {"max_hp": 8.0, "armor": 1.0}}
```

The level-up UI currently displays compact stat summaries instead of item names/descriptions.

### Adding More Weapons

Weapons are scene-based. Each weapon should extend or use `entities/weapons/Weapon.gd`.

To add a weapon:

1. Create a new folder under `entities/weapons/`, for example `entities/weapons/railgun/`.
2. Create a weapon scene, for example `railgun.tscn`.
3. Use `Weapon.gd` as the root script or subclass it if the weapon needs custom behavior.
4. Set exported values in the scene:
   - `weapon_id`
   - `display_name`
   - `shop_cost`
   - `projectile_scene`
   - `damage`
   - `cooldown`
   - `critical_rate`
   - `critical_damage_multiplier`
   - `range`
   - projectile stats such as speed, width, lifetime, or AOE radius
5. Make sure the weapon scene has the expected child nodes used by `Weapon.gd`:
   - `RangeArea`
   - `RangeArea/CollisionShape2D`
   - `Output`
   - `CooldownTimer`
6. Register it in `game_stages/game/shop_manager.gd` inside `WEAPON_POOL`:

```gdscript
{
	"id": "railgun",
	"name": "Railgun",
	"scene": preload("res://entities/weapons/railgun/railgun.tscn"),
	"cost": 22,
}
```

Weapon tiers automatically affect damage, cooldown, and sprite outline color through `Weapon.gd`.

### Adding More Projectiles

Projectiles live in `entities/projectiles/`.

Player projectiles usually implement:

```gdscript
func setup(stats: Dictionary) -> void:
	# Read direction, damage, range, speed, is_critical, etc.
```

If the projectile damages enemies, pass both damage and crit metadata:

```gdscript
target.take_damage(damage, is_critical)
```

Enemy projectiles should call player/planet damage without crit metadata:

```gdscript
target.take_damage(damage)
```

### Adding More Enemies

Enemy shared behavior lives in `entities/enemies/enemy.gd`. It handles:

- Health
- Damage intake
- Floating damage text
- Death
- Scrap drops
- Target selection
- Minimap registration
- Basic facing helper

To add a new enemy:

1. Create a new folder under `entities/enemies/`, for example `entities/enemies/tank/`.
2. Create `tank_enemy.gd` extending `Enemy`.
3. Create `tank_enemy.tscn` with its own editable nodes.
4. Recommended scene structure:
   - Root: `CharacterBody2D`
   - `Vessel`: `Area2D` on enemy collision layer
   - `Vessel/CollisionShape2D`
   - `Vessel/BodySprite`
5. Implement enemy-specific movement and attack in `_physics_process()` and helper methods.
6. Preload and spawn it from `game_stages/game/game.gd`.

Example registration:

```gdscript
const TankEnemyScene := preload("res://entities/enemies/tank/tank_enemy.tscn")
```

Then add a spawn function and include it in `spawn_enemy()`.

Current enemy spawns are controlled by:

- `spawn_interval`
- `initial_spawn_count`
- `shooter_spawn_chance`
- `get_random_edge_position()`

### Adding More Enemy Drops

Enemies currently drop scrap through `Enemy.drop_scrap()`.

To tune drops per enemy, set `scrap_drop_count` on the enemy scene. For more complex loot, extend `drop_scrap()` in a subclass or add a new drop method to `Enemy`.

### GitHub Pages Deploy

The repository includes a GitHub Pages workflow:

```text
.github/workflows/deploy-pages.yml
```

The workflow deploys `export/web`, copies `Stubborn-Defense.html` to `index.html`, and uploads the result to GitHub Pages.

Before deploying:

1. Export the Godot web build locally into `export/web`.
2. Commit the updated export files.
3. Push to `main` or `master`.
4. In GitHub repo settings, set Pages source to `GitHub Actions`.

## Notes

- The project currently targets Godot 4.6 compatibility based on `project.godot`.
- Scrap is both pickup count and shop currency.
- Player crit chance starts at `0`; crit chance can come from items, level-up upgrades, or weapon-specific settings.
- The planet is the win-condition anchor: if planet HP reaches zero, the game ends.
