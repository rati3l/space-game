extends SceneTree

const SPECIAL_KEYS: Array[String] = [
	"pulse_overclock", "fang_convergence", "rail_afterimage", "forked_arc",
	"plasma_scorch", "stellar_fragments", "vortex_teeth", "viral_cascade",
	"saw_acceleration", "mycelium_zone", "prism_edge", "singularity_echo"
]

var failures: Array[String] = []
var passed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Could not load main scene")
		_finish()
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	_test_upgrade_offers(game)
	_test_upgrade_choices_are_unique(game)
	_test_tier_descriptions_show_scaled_benefit(game)
	_test_reload_feedback_is_capped(game)
	_test_damage_trails_are_visible(game)
	_test_pulse_overclock(game)
	_test_fang_convergence(game)
	_test_rail_afterimage(game)
	_test_forked_arc(game)
	_test_plasma_scorch(game)
	_test_stellar_fragments(game)
	_test_vortex_teeth(game)
	_test_viral_cascade(game)
	_test_saw_acceleration(game)
	_test_mycelium_zone(game)
	_test_prism_edge(game)
	_test_singularity_echo(game)

	game.queue_free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("SPECIAL_UPGRADE_E2E PASS: %d assertions" % passed)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SPECIAL_UPGRADE_E2E FAIL: %d failure(s), %d assertions passed" % [failures.size(), passed])
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failures.append(message)


func _fail(message: String) -> void:
	failures.append(message)


func _reset(game: Node, weapon_id: int, upgrade_key: String = "") -> void:
	game.call("_reset_run")
	game.set("run_started", true)
	game.set("selected_weapon_id", weapon_id)
	var levels := game.get("upgrade_levels") as Dictionary
	var power := game.get("upgrade_power") as Dictionary
	for key in levels.keys():
		levels[key] = 0
	for key in power.keys():
		power[key] = 0.0
	if upgrade_key != "":
		levels[upgrade_key] = 3
		power[upgrade_key] = 3.0
	game.set("upgrade_levels", levels)
	game.set("upgrade_power", power)
	game.set("survival_time", 10.0)


func _weapon(game: Node, weapon_id: int) -> Dictionary:
	var weapons := game.get("weapon_defs") as Array
	return weapons[weapon_id] as Dictionary


func _enemy(game: Node, position: Vector2, hp: float = 300.0) -> Node2D:
	game.call("_spawn_enemy", 0.0)
	var enemies := game.get("enemies") as Array
	var enemy := enemies[enemies.size() - 1] as Node2D
	enemy.global_position = position
	enemy.set_meta("spawn_delay", 0.0)
	enemy.set_meta("health", hp)
	enemy.set_meta("max_health", hp)
	enemy.set_meta("velocity", Vector2.ZERO)
	enemy.set_meta("poison_dps", 0.0)
	enemy.set_meta("poison_time", 0.0)
	return enemy


func _health(enemy: Node2D) -> float:
	return float(enemy.get_meta("health", 0.0))


func _first_bullet(game: Node) -> Node2D:
	var bullets := game.get("bullets") as Array
	if bullets.is_empty():
		return null
	return bullets[0] as Node2D


func _fire(game: Node, weapon_id: int, target: Vector2) -> void:
	game.call("_fire_weapon", _weapon(game, weapon_id), target)


func _hit_first_bullet(game: Node, enemy: Node2D) -> float:
	var bullet := _first_bullet(game)
	if bullet == null:
		return 0.0
	var bullets := game.get("bullets") as Array
	var index := bullets.find(bullet)
	var before := _health(enemy)
	bullet.global_position = enemy.global_position
	game.call("_on_bullet_hit_enemy", bullet, enemy, index)
	return before - _health(enemy)


func _test_upgrade_offers(game: Node) -> void:
	for weapon_id in range(12):
		var weapon := _weapon(game, weapon_id)
		var key := String(game.call("_weapon_specific_key", weapon))
		_ok(SPECIAL_KEYS.has(key), "Weapon %d has no recognized special upgrade" % weapon_id)
		var pool := game.call("_compatible_upgrade_pool", weapon) as Array
		_ok(pool.has(key), "%s is not offered for weapon %d" % [key, weapon_id])


func _test_upgrade_choices_are_unique(game: Node) -> void:
	for weapon_id in range(12):
		_reset(game, weapon_id)
		game.call("_open_upgrade_panel")
		var offered := game.get("offered_upgrades") as Array
		var seen: Array[String] = []
		for key in offered:
			var upgrade_key := String(key)
			_ok(not seen.has(upgrade_key), "Duplicate upgrade shown for weapon %d: %s" % [weapon_id, upgrade_key])
			seen.append(upgrade_key)
		_ok(offered.size() == 3, "Weapon %d did not receive three upgrade choices" % weapon_id)


func _test_tier_descriptions_show_scaled_benefit(game: Node) -> void:
	var rare_damage := String(game.call("_upgrade_effect_text", "damage", 1.5))
	var epic_trail := String(game.call("_upgrade_effect_text", "ion_trails", 3.0))
	_ok(rare_damage.contains("18%") and rare_damage.contains("x1.5"), "Rare damage text does not show scaled benefit")
	_ok(epic_trail.contains("x3.0"), "Epic non-numeric upgrade text does not show scaled benefit")


func _test_reload_feedback_is_capped(game: Node) -> void:
	_reset(game, 0, "reload_feedback")
	game.set("auto_fire_timer", 1.0)
	var first := _enemy(game, Vector2(100, 0), 1.0)
	var second := _enemy(game, Vector2(120, 0), 1.0)
	game.call("_damage_enemy", first, 5.0)
	var after_first := float(game.get("auto_fire_timer"))
	game.call("_damage_enemy", second, 5.0)
	var after_second := float(game.get("auto_fire_timer"))
	_ok(after_first < 1.0, "reload_feedback did not reduce cooldown on first kill")
	_ok(is_equal_approx(after_first, after_second), "reload_feedback triggered more than once inside 2 seconds")


func _test_damage_trails_are_visible(game: Node) -> void:
	_reset(game, 0, "ion_trails")
	_fire(game, 0, Vector2(160, 0))
	var ion_bullet := _first_bullet(game)
	_ok(ion_bullet != null and ion_bullet.has_meta("damage_trail_node"), "ion_trails did not add a visible damage trail node")
	_reset(game, 6, "vortex_teeth")
	_fire(game, 6, Vector2(160, 0))
	var vortex_bullet := _first_bullet(game)
	_ok(vortex_bullet != null and vortex_bullet.has_meta("damage_trail_node"), "vortex_teeth did not add a visible shrapnel trail node")


func _test_pulse_overclock(game: Node) -> void:
	_reset(game, 0, "pulse_overclock")
	var enemy := _enemy(game, Vector2(140, 0), 2000.0)
	var max_damage := 0.0
	for i in range(40):
		_fire(game, 0, enemy.global_position)
		max_damage = maxf(max_damage, _hit_first_bullet(game, enemy))
		game.set("survival_time", float(game.get("survival_time")) + 0.04)
	_ok(max_damage > 18.0, "pulse_overclock never produced an overclocked pulse hit")


func _test_fang_convergence(game: Node) -> void:
	_reset(game, 1, "fang_convergence")
	var enemy := _enemy(game, Vector2(140, 0), 1000.0)
	_fire(game, 1, enemy.global_position)
	var first_hit := _hit_first_bullet(game, enemy)
	_fire(game, 1, enemy.global_position)
	var second_hit := _hit_first_bullet(game, enemy)
	_ok(second_hit > first_hit * 1.35, "fang_convergence did not increase paired follow-up damage")


func _test_rail_afterimage(game: Node) -> void:
	_reset(game, 2, "rail_afterimage")
	var enemy_a := _enemy(game, Vector2(220, 0), 500.0)
	var enemy_b := _enemy(game, Vector2(480, 0), 500.0)
	_fire(game, 2, Vector2(700, 0))
	var damage_a := 500.0 - _health(enemy_a)
	var damage_b := 500.0 - _health(enemy_b)
	_ok(damage_a > 43.0 and damage_b > 43.0, "rail_afterimage failed to damage every enemy in line with trace damage")
	var traces := game.get("rail_traces") as Array
	_ok(not traces.is_empty(), "rail_afterimage did not leave a lingering damage trace")


func _test_forked_arc(game: Node) -> void:
	_reset(game, 3, "forked_arc")
	var enemy_a := _enemy(game, Vector2(140, 0), 300.0)
	var enemy_b := _enemy(game, Vector2(-140, 0), 300.0)
	_fire(game, 3, enemy_a.global_position)
	_ok(_health(enemy_a) < 300.0 and _health(enemy_b) < 300.0, "forked_arc did not start an additional lightning arc")


func _test_plasma_scorch(game: Node) -> void:
	_reset(game, 4, "plasma_scorch")
	var enemy := _enemy(game, Vector2(120, 0), 500.0)
	_fire(game, 4, enemy.global_position)
	var damage := _hit_first_bullet(game, enemy)
	_ok(damage > 25.0, "plasma_scorch did not amplify mortar blast damage")


func _test_stellar_fragments(game: Node) -> void:
	_reset(game, 5, "stellar_fragments")
	_fire(game, 5, Vector2(220, 0))
	var bullet := _first_bullet(game)
	if bullet == null:
		_fail("stellar_fragments could not spawn a starbreaker projectile")
		return
	bullet.global_position = Vector2(220, 0)
	game.call("_detonate_projectile", bullet, 0)
	var bullets := game.get("bullets") as Array
	_ok(bullets.size() >= 10, "stellar_fragments did not spawn star shard projectiles")


func _test_vortex_teeth(game: Node) -> void:
	_reset(game, 6, "vortex_teeth")
	var enemy := _enemy(game, Vector2(80, 0), 300.0)
	_fire(game, 6, enemy.global_position)
	var bullet := _first_bullet(game)
	if bullet == null:
		_fail("vortex_teeth could not spawn shrapnel projectile")
		return
	bullet.global_position = enemy.global_position
	game.call("_update_special_projectile", bullet, 0.16, 0)
	_ok(_health(enemy) < 300.0, "vortex_teeth trail damage did not affect nearby enemies")


func _test_viral_cascade(game: Node) -> void:
	_reset(game, 7, "viral_cascade")
	var carrier := _enemy(game, Vector2(110, 0), 6.0)
	var nearby := _enemy(game, Vector2(150, 0), 300.0)
	_fire(game, 7, carrier.global_position)
	_hit_first_bullet(game, carrier)
	_ok(float(nearby.get_meta("poison_dps", 0.0)) > 0.0, "viral_cascade did not spread poison from a toxic kill")


func _test_saw_acceleration(game: Node) -> void:
	_reset(game, 8, "saw_acceleration")
	var first := _enemy(game, Vector2(120, 0), 300.0)
	_enemy(game, Vector2(240, 0), 300.0)
	_fire(game, 8, first.global_position)
	var bullet := _first_bullet(game)
	if bullet == null:
		_fail("saw_acceleration could not spawn ricochet disk")
		return
	var initial_damage := float(bullet.get_meta("damage", 0.0))
	_hit_first_bullet(game, first)
	_ok(is_instance_valid(bullet) and float(bullet.get_meta("damage", 0.0)) > initial_damage * 1.19, "saw_acceleration did not raise ricochet damage after a bounce")


func _test_mycelium_zone(game: Node) -> void:
	_reset(game, 9, "mycelium_zone")
	var outer_enemy := _enemy(game, Vector2(330, 0), 300.0)
	_fire(game, 9, Vector2(220, 0))
	var bullet := _first_bullet(game)
	if bullet == null:
		_fail("mycelium_zone could not spawn spore projectile")
		return
	bullet.global_position = Vector2(220, 0)
	game.call("_detonate_projectile", bullet, 0)
	_ok(_health(outer_enemy) < 300.0, "mycelium_zone did not expand/strengthen the spore blast zone")


func _test_prism_edge(game: Node) -> void:
	_reset(game, 10, "prism_edge")
	var enemy := _enemy(game, Vector2(120, 0), 300.0)
	_fire(game, 10, enemy.global_position)
	_hit_first_bullet(game, enemy)
	_ok(float(enemy.get_meta("poison_dps", 0.0)) > 0.0, "prism_edge did not add burn/DoT to photon hits")


func _test_singularity_echo(game: Node) -> void:
	_reset(game, 11, "singularity_echo")
	var enemy := _enemy(game, Vector2(100, 0), 300.0)
	_fire(game, 11, enemy.global_position)
	var bullet := _first_bullet(game)
	if bullet == null:
		_fail("singularity_echo could not spawn void projectile")
		return
	bullet.global_position = Vector2(75, 0)
	game.call("_update_special_projectile", bullet, 0.4, 0)
	var enemy_velocity := enemy.get_meta("velocity", Vector2.ZERO) as Vector2
	_ok(_health(enemy) < 300.0 and enemy_velocity.length() > 0.0, "singularity_echo did not pull and damage nearby enemies")
