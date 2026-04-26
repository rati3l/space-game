extends Node2D

signal enemy_health_changed(enemy: Node2D, current_health: float, max_health: float)

const EnemyScene = preload("res://scenes/Enemy.tscn")
const ARENA_HALF_SIZE := Vector2(2600.0, 1500.0)
const PLAYER_SPEED := 290.0
const BULLET_SPEED := 680.0
const AUTO_TARGET_RADIUS := 420.0
const PLAYER_COLLISION_RADIUS := 14.0
const ENEMY_COLLISION_RADIUS := 9.0
const SIDE_PANEL_WIDTH := 336.0
const SIDE_PANEL_PADDING := 16.0
const CAMERA_START_ZOOM := 0.72
const CAMERA_MAX_ZOOM_OUT := 3.0

const UPGRADE_POOL := ["pierce", "bounce", "chain", "multishot", "split", "targeting", "velocity", "overload", "blast", "attack_speed", "damage", "impact_bloom", "corrosion_payload", "afterburn_field", "ion_trails", "siphon_matrix", "execution_voltage", "critical_capacitor", "field_amplifier", "status_spread", "shield_converter", "reload_feedback", "gravity_well", "pulse_overclock", "fang_convergence", "rail_afterimage", "forked_arc", "plasma_scorch", "stellar_fragments", "vortex_teeth", "viral_cascade", "saw_acceleration", "mycelium_zone", "prism_edge", "singularity_echo"]
const UPGRADE_NAMES := {
	"pierce": "Pierce",
	"bounce": "Bounce",
	"chain": "Chain",
	"multishot": "Multishot",
	"split": "Split",
	"targeting": "Targeting",
	"velocity": "Velocity",
	"overload": "Overload",
	"blast": "Blast",
	"attack_speed": "Attack Speed",
	"damage": "Damage",
	"impact_bloom": "Impact Bloom",
	"corrosion_payload": "Corrosion Payload",
	"afterburn_field": "Afterburn Field",
	"ion_trails": "Ion Trails",
	"siphon_matrix": "Siphon Matrix",
	"execution_voltage": "Execution Voltage",
	"critical_capacitor": "Critical Capacitor",
	"field_amplifier": "Field Amplifier",
	"status_spread": "Status Spread",
	"shield_converter": "Shield Converter",
	"reload_feedback": "Reload Feedback",
	"gravity_well": "Gravity Well",
	"pulse_overclock": "Pulse Overclock",
	"fang_convergence": "Fang Convergence",
	"rail_afterimage": "Rail Afterimage",
	"forked_arc": "Forked Arc",
	"plasma_scorch": "Plasma Scorch",
	"stellar_fragments": "Stellar Fragments",
	"vortex_teeth": "Vortex Teeth",
	"viral_cascade": "Viral Cascade",
	"saw_acceleration": "Saw Acceleration",
	"mycelium_zone": "Mycelium Zone",
	"prism_edge": "Prism Edge",
	"singularity_echo": "Singularity Echo"
}

const ENEMY_ARCHETYPES := [
	{
		"id": "spinner",
		"name": "Spinner",
		"hp_mult": 1.0,
		"speed_mult": 1.0,
		"touch_mult": 1.0,
		"accel_mult": 1.0,
		"orbit_mult": 1.0,
		"body_color": Color(1.0, 0.32, 0.72, 0.0),
		"outline_color": Color(1.0, 0.38, 0.82, 1.0),
		"outer_color": Color(1.0, 0.08, 0.7, 0.64),
		"shape": [Vector2(0, -24), Vector2(8, -8), Vector2(24, 0), Vector2(8, 8), Vector2(0, 24), Vector2(-8, 8), Vector2(-24, 0), Vector2(-8, -8)]
	},
	{
		"id": "dart",
		"name": "Dart",
		"hp_mult": 0.72,
		"speed_mult": 0.98,
		"touch_mult": 0.9,
		"accel_mult": 0.82,
		"orbit_mult": 0.75,
		"body_color": Color(0.7, 0.96, 1.0, 0.0),
		"outline_color": Color(0.04, 0.96, 1.0, 1.0),
		"outer_color": Color(0.0, 0.86, 1.0, 0.72),
		"shape": [Vector2(0, -26), Vector2(22, 12), Vector2(5, 7), Vector2(0, 20), Vector2(-5, 7), Vector2(-22, 12)]
	},
	{
		"id": "tank",
		"name": "Tank",
		"hp_mult": 2.1,
		"speed_mult": 0.64,
		"touch_mult": 1.4,
		"accel_mult": 0.6,
		"orbit_mult": 0.5,
		"body_color": Color(1.0, 0.7, 0.28, 0.0),
		"outline_color": Color(1.0, 0.8, 0.12, 1.0),
		"outer_color": Color(1.0, 0.42, 0.04, 0.66),
		"shape": [Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24)]
	},
	{
		"id": "hex",
		"name": "Hex",
		"hp_mult": 1.25,
		"speed_mult": 0.92,
		"touch_mult": 1.15,
		"accel_mult": 0.95,
		"orbit_mult": 0.85,
		"body_color": Color(0.9, 0.58, 1.0, 0.0),
		"outline_color": Color(0.92, 0.28, 1.0, 1.0),
		"outer_color": Color(0.66, 0.12, 1.0, 0.64),
		"shape": [Vector2(0, -26), Vector2(23, -13), Vector2(23, 13), Vector2(0, 26), Vector2(-23, 13), Vector2(-23, -13)]
	}
]

@onready var player: Node2D = $Player
@onready var enemies_root: Node2D = $Enemies
@onready var bullets_root: Node2D = $Bullets
@onready var space_background: TextureRect = $SpaceBackground
@onready var stars: Polygon2D = $Stars
@onready var player_back_glow: Polygon2D = $Player/BackGlow
@onready var nebula_magenta: Polygon2D = $NebulaGlowMagenta
@onready var nebula_cyan: Polygon2D = $NebulaGlowCyan
@onready var camera: Camera2D = $Camera2D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var time_label: Label = $CanvasLayer/HUD/TimeLabel
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var hp_bar: ProgressBar = $CanvasLayer/HUD/HPBar
@onready var shield_bar: ProgressBar = $CanvasLayer/HUD/ShieldBar
@onready var xp_bar: ProgressBar = $CanvasLayer/HUD/XPBar
@onready var upgrade_panel: Panel = $CanvasLayer/HUD/UpgradePanel
@onready var loadout_panel: Panel = $CanvasLayer/HUD/LoadoutPanel
@onready var loadout_info: Label = $CanvasLayer/HUD/LoadoutPanel/LoadoutInfo
@onready var start_run_button: Button = $CanvasLayer/HUD/LoadoutPanel/StartRunButton
@onready var shield_panel: Panel = $CanvasLayer/HUD/ShieldSelectionPanel
@onready var weapon_panel: Panel = $CanvasLayer/HUD/WeaponSelectionPanel
@onready var upgrade_buttons: Array[Button] = [
	$CanvasLayer/HUD/UpgradePanel/UpgradeButton1,
	$CanvasLayer/HUD/UpgradePanel/UpgradeButton2,
	$CanvasLayer/HUD/UpgradePanel/UpgradeButton3
]

var weapon_defs: Array[Dictionary] = []
var unlocked_weapons: Array[int] = []
var selected_weapon_id := 0
var selected_shield_id := 0
var bullets: Array[Node2D] = []
var enemies: Array[Node2D] = []
var rail_traces: Array[Dictionary] = []
var next_enemy_id := 0

var score := 0
var survival_time := 0.0
var wave_index := 0
var spawn_timer := 0.0
var wave_timer := 0.0
var auto_fire_timer := 0.0
var reload_feedback_timer := 0.0
var invuln_timer := 0.0
var game_over := false
var run_started := false

var player_max_hp := 100.0
var player_hp := 100.0
var player_hp_regen := 2.4
var shield_max := 60.0
var shield_hp := 60.0
var shield_regen := 14.0
var shield_regen_delay := 1.6
var shield_regen_lock_timer := 0.0
var shield_trait := "balanced"
var xp := 0.0
var level := 1
var xp_to_next := 35.0
var level_up_pending := 0
var offered_upgrades: Array[String] = []
var offered_upgrade_tiers: Array[String] = []
var upgrade_levels := {
	"pierce": 0,
	"bounce": 0,
	"chain": 0,
	"multishot": 0,
	"split": 0,
	"targeting": 0,
	"velocity": 0,
	"overload": 0,
	"blast": 0,
	"attack_speed": 0,
	"damage": 0,
	"impact_bloom": 0, "corrosion_payload": 0, "afterburn_field": 0, "ion_trails": 0,
	"siphon_matrix": 0, "execution_voltage": 0, "critical_capacitor": 0, "field_amplifier": 0,
	"status_spread": 0, "shield_converter": 0, "reload_feedback": 0, "gravity_well": 0,
	"pulse_overclock": 0, "fang_convergence": 0, "rail_afterimage": 0, "forked_arc": 0,
	"plasma_scorch": 0, "stellar_fragments": 0, "vortex_teeth": 0, "viral_cascade": 0,
	"saw_acceleration": 0, "mycelium_zone": 0, "prism_edge": 0, "singularity_echo": 0
}
var upgrade_power := {
	"pierce": 0.0, "bounce": 0.0, "chain": 0.0, "multishot": 0.0, "split": 0.0,
	"targeting": 0.0, "velocity": 0.0, "overload": 0.0, "blast": 0.0,
	"attack_speed": 0.0, "damage": 0.0,
	"impact_bloom": 0.0, "corrosion_payload": 0.0, "afterburn_field": 0.0, "ion_trails": 0.0,
	"siphon_matrix": 0.0, "execution_voltage": 0.0, "critical_capacitor": 0.0, "field_amplifier": 0.0,
	"status_spread": 0.0, "shield_converter": 0.0, "reload_feedback": 0.0, "gravity_well": 0.0,
	"pulse_overclock": 0.0, "fang_convergence": 0.0, "rail_afterimage": 0.0, "forked_arc": 0.0,
	"plasma_scorch": 0.0, "stellar_fragments": 0.0, "vortex_teeth": 0.0, "viral_cascade": 0.0,
	"saw_acceleration": 0.0, "mycelium_zone": 0.0, "prism_edge": 0.0, "singularity_echo": 0.0
}
var shield_defs: Array[Dictionary] = []
var shield_outer_ring: Line2D
var shield_inner_ring: Line2D
var shield_pulse: Polygon2D
var shield_phase := 0.0
var shield_spikes: Line2D
var stats_panel: Panel
var stats_icons_root: Node2D
var ship_icon: Line2D
var ship_icon_glow: Line2D
var weapon_icon: Line2D
var weapon_icon_glow: Line2D
var shield_icon: Line2D
var shield_icon_glow: Line2D
var ship_label: Label
var weapon_label: Label
var shield_label: Label
var prev_weapon_button: Button
var next_weapon_button: Button
var prev_shield_button: Button
var next_shield_button: Button
var player_trail_left: Line2D
var player_trail_right: Line2D
var player_trail_timer := 0.0
var sci_fi_font: SystemFont


func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color.BLACK)
	_setup_space_background()
	_setup_neon_look()
	_setup_shield_visuals()
	_setup_weapon_definitions()
	_setup_shield_definitions()
	_connect_weapon_buttons()
	_connect_shield_buttons()
	for i in range(upgrade_buttons.size()):
		upgrade_buttons[i].pressed.connect(_on_upgrade_pressed.bind(i))
	start_run_button.pressed.connect(_on_start_run_pressed)
	_set_ui_tooltips()
	_setup_side_panel()
	for i in range(weapon_defs.size()):
		_unlock_weapon(i)
	_select_weapon(0)
	_select_shield(0)
	_reset_run()


func _physics_process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			_reset_run()
		return

	if not run_started:
		_refresh_ui()
		return

	if upgrade_panel.visible:
		_refresh_ui()
		return

	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
	if shield_regen_lock_timer > 0.0:
		shield_regen_lock_timer = max(0.0, shield_regen_lock_timer - delta)
	if reload_feedback_timer > 0.0:
		reload_feedback_timer = max(0.0, reload_feedback_timer - delta)

	survival_time += delta
	wave_timer += delta
	_update_camera_zoom()
	_handle_player_movement(delta)
	_update_player_trails(delta)
	_handle_weapon_unlocks()
	_process_auto_fire(delta)
	_process_enemy_spawning(delta)
	_update_bullets(delta)
	_update_enemies(delta)
	_update_rail_traces(delta)
	_check_player_collisions(delta)
	_tick_player_regen(delta)
	_update_shield_visuals(delta)
	_refresh_ui()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and upgrade_panel.visible:
		match key_event.keycode:
			KEY_1, KEY_KP_1:
				_on_upgrade_pressed(0)
				get_viewport().set_input_as_handled()
				return
			KEY_2, KEY_KP_2:
				_on_upgrade_pressed(1)
				get_viewport().set_input_as_handled()
				return
			KEY_3, KEY_KP_3:
				_on_upgrade_pressed(2)
				get_viewport().set_input_as_handled()
				return
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and upgrade_panel.visible:
		for i in range(upgrade_buttons.size()):
			var button := upgrade_buttons[i]
			if button.visible and not button.disabled:
				var upgrade_rect := Rect2(button.global_position, button.size)
				if upgrade_rect.has_point(mouse_event.position):
					_on_upgrade_pressed(i)
					get_viewport().set_input_as_handled()
					return
	if run_started:
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_run_pressed()
		get_viewport().set_input_as_handled()
		return
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if start_run_button == null or not start_run_button.visible or start_run_button.disabled:
		return
	var button_rect := Rect2(start_run_button.global_position, start_run_button.size)
	if button_rect.has_point(mouse_event.position):
		_on_start_run_pressed()
		get_viewport().set_input_as_handled()


func _reset_run() -> void:
	for child in get_children():
		if child is Node and (bool(child.get_meta("is_blast_fx", false)) or bool(child.get_meta("is_temp_fx", false))):
			child.queue_free()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	enemies.clear()
	bullets.clear()
	rail_traces.clear()

	player.position = Vector2.ZERO
	player.rotation = 0.0
	if camera != null:
		camera.zoom = Vector2.ONE * CAMERA_START_ZOOM
	player_max_hp = 100.0
	player_hp = player_max_hp
	xp = 0.0
	level = 1
	xp_to_next = _xp_required(level)
	level_up_pending = 0
	offered_upgrades.clear()
	offered_upgrade_tiers.clear()
	for key in upgrade_levels.keys():
		upgrade_levels[key] = 0
	for key in upgrade_power.keys():
		upgrade_power[key] = 0.0

	score = 0
	survival_time = 0.0
	wave_index = 0
	spawn_timer = 0.12
	wave_timer = 0.0
	auto_fire_timer = 0.2
	reload_feedback_timer = 0.0
	player_trail_timer = 0.0
	invuln_timer = 0.0
	game_over = false
	run_started = false
	upgrade_panel.visible = false
	loadout_panel.visible = true
	start_run_button.disabled = false
	weapon_panel.visible = false
	shield_panel.visible = false
	loadout_info.text = "Pick both, then click Start Run"
	_refresh_ui()


func _setup_weapon_definitions() -> void:
	weapon_defs = [
		{"id": 0, "name": "Pulse Carbine", "role": "RELIABLE PULSE LASER", "tag": "balanced", "archetype": "pulse", "behavior": "pulse", "damage": 12.0, "cooldown": 0.34, "speed": 760.0, "projectiles": 1, "spread_deg": 0.0, "base_pierce": 1, "desc": "Clean high velocity bolts. The baseline weapon: accurate, steady, and readable.", "strong": "Accuracy\nPierce line", "weak": "Low drama\nSmall AoE"},
		{"id": 1, "name": "Twin Fang", "role": "CONVERGING PLASMA JAWS", "tag": "paired lances", "archetype": "twin_fang", "behavior": "twin_fang", "damage": 9.0, "cooldown": 0.29, "speed": 720.0, "projectiles": 2, "spread_deg": 12.0, "desc": "Two side lances bite inward. Strongest when packs stay in the convergence zone.", "strong": "Mid range bite\nTwo lanes", "weak": "Awkward close\nNeeds angle"},
		{"id": 2, "name": "Rail Spear", "role": "SURGICAL PIERCE CANNON", "tag": "rail pierce", "archetype": "rail", "behavior": "rail", "damage": 36.0, "cooldown": 0.84, "speed": 1220.0, "projectiles": 1, "spread_deg": 0.0, "base_pierce": 8, "desc": "A narrow hypersonic slug punches through entire lanes and leaves a white afterimage.", "strong": "Elite burst\nLine clears", "weak": "Slow cycle\nOverkill"},
		{"id": 3, "name": "Chain Arc", "role": "ION LIGHTNING NETWORK", "tag": "lightning", "archetype": "lightning", "behavior": "lightning", "damage": 11.0, "cooldown": 0.55, "chain_jumps": 5, "chain_range": 240.0, "desc": "Instant ion arcs jump target to target. Great at finishing scattered swarm edges.", "strong": "Auto chains\nNo aim lane", "weak": "Range capped\nLower single DPS"},
		{"id": 4, "name": "Plasma Mortar", "role": "LOBBED AREA DENIAL", "tag": "molten aoe", "archetype": "mortar", "behavior": "mortar", "damage": 15.0, "cooldown": 0.86, "speed": 390.0, "blast_radius": 94.0, "life": 1.15, "desc": "A heavy molten orb wobbles forward and detonates on impact or after its fuse.", "strong": "Zone control\nDense packs", "weak": "Slow travel\nCan miss darts"},
		{"id": 5, "name": "Starbreaker Charge", "role": "SLOW GUIDED WARHEAD", "tag": "heavy nuke", "archetype": "starbreaker", "behavior": "starbreaker", "damage": 40.0, "cooldown": 1.85, "speed": 300.0, "blast_radius": 165.0, "life": 1.85, "desc": "A slow charge steers toward massed enemies, then erupts into an angular starburst.", "strong": "Huge payoff\nCluster clear", "weak": "Long cooldown\nDelayed safety"},
		{"id": 6, "name": "Shrapnel Vortex", "role": "SPINNING FLAK CORE", "tag": "spiral flak", "archetype": "shrapnel", "behavior": "shrapnel", "damage": 7.0, "cooldown": 0.48, "speed": 470.0, "projectiles": 1, "spread_deg": 0.0, "base_pierce": 1, "life": 1.7, "desc": "A rotating core sheds shards in a spiral, shaving down wide swarms while it travels.", "strong": "Screen coverage\nSwarm shaving", "weak": "Low focus DPS\nRandom lanes"},
		{"id": 7, "name": "Toxic Needle", "role": "CORROSIVE EMBED DART", "tag": "bio dot", "archetype": "toxic_needle", "behavior": "toxic", "damage": 7.5, "cooldown": 0.19, "speed": 860.0, "projectiles": 1, "spread_deg": 0.0, "poison_dps": 8.5, "poison_time": 2.6, "desc": "Fast needles pin corrosion into targets and splash infection to nearby bodies.", "strong": "Elite melt\nFast cycle", "weak": "Little burst\nNeeds uptime"},
		{"id": 8, "name": "Ricochet Disk", "role": "SEEKING SAW DISC", "tag": "bounce", "archetype": "ricochet", "behavior": "ricochet", "damage": 12.0, "cooldown": 0.43, "speed": 610.0, "projectiles": 1, "spread_deg": 0.0, "base_bounce": 5, "life": 2.6, "desc": "A spinning saw ricochets through enemies and turns harder after every hit.", "strong": "Crowd pinball\nBounce scaling", "weak": "Open space\nUnstable path"},
		{"id": 9, "name": "Spore Launcher", "role": "LINGERING POISON CLOUD", "tag": "bio cloud", "archetype": "spore", "behavior": "spore", "damage": 8.0, "cooldown": 0.68, "speed": 360.0, "blast_radius": 84.0, "poison_dps": 9.0, "poison_time": 3.2, "life": 1.35, "desc": "Pods burst into drifting spores. It is a trap cloud, not a normal explosion.", "strong": "Choke clouds\nPoison packs", "weak": "Slow setup\nSpread enemies"},
		{"id": 10, "name": "Photon Fan", "role": "CLOSE RANGE LIGHT BLADES", "tag": "wide fan", "archetype": "photon", "behavior": "photon", "damage": 10.0, "cooldown": 0.25, "speed": 820.0, "projectiles": 5, "spread_deg": 34.0, "life": 0.58, "desc": "A broad fan of short-lived photon blades clears close arcs like a sci-fi shotgun.", "strong": "Close clear\nWide sweep", "weak": "Short reach\nRisky spacing"},
		{"id": 11, "name": "Void Repeater", "role": "GRAVITY FLECHETTES", "tag": "pull hybrid", "archetype": "void", "behavior": "void", "damage": 13.0, "cooldown": 0.35, "speed": 640.0, "projectiles": 2, "spread_deg": 9.0, "base_pierce": 1, "chain_jumps": 1, "chain_range": 170.0, "life": 1.8, "desc": "Twin dark bolts slow and tug enemies inward before snapping into purple shards.", "strong": "Crowd control\nPierce setup", "weak": "Moderate damage\nVisual chaos"}
	]


func _setup_shield_definitions() -> void:
	shield_defs = [
		{"id": 0, "name": "Aegis Core", "tag": "balanced", "max": 70.0, "regen": 14.0, "delay": 1.5, "trait": "balanced"},
		{"id": 1, "name": "Reflector Shell", "tag": "reflect", "max": 55.0, "regen": 12.0, "delay": 1.7, "trait": "reflect"},
		{"id": 2, "name": "Bulwark Vault", "tag": "tank", "max": 120.0, "regen": 8.0, "delay": 2.2, "trait": "tank"},
		{"id": 3, "name": "Flux Skin", "tag": "fast regen", "max": 45.0, "regen": 22.0, "delay": 0.9, "trait": "fast_regen"},
		{"id": 4, "name": "Static Mesh", "tag": "zap", "max": 65.0, "regen": 12.0, "delay": 1.4, "trait": "shock"},
		{"id": 5, "name": "Overcharge Halo", "tag": "dps boost full", "max": 75.0, "regen": 16.0, "delay": 1.4, "trait": "overcharge"},
		{"id": 6, "name": "Blood Mirror", "tag": "hp leech", "max": 58.0, "regen": 11.0, "delay": 1.5, "trait": "leech"},
		{"id": 7, "name": "Prism Ward", "tag": "damage split", "max": 80.0, "regen": 10.0, "delay": 1.6, "trait": "split"},
		{"id": 8, "name": "Void Veil", "tag": "evade burst", "max": 60.0, "regen": 13.0, "delay": 1.3, "trait": "evade"},
		{"id": 9, "name": "Fortress Ring", "tag": "flat reduce", "max": 92.0, "regen": 9.0, "delay": 1.9, "trait": "flat_reduce"},
		{"id": 10, "name": "Nanofiber Coat", "tag": "hp regen", "max": 68.0, "regen": 11.0, "delay": 1.4, "trait": "hp_regen"},
		{"id": 11, "name": "Entropy Guard", "tag": "burst absorb", "max": 48.0, "regen": 10.0, "delay": 1.2, "trait": "burst_absorb"}
	]


func _connect_weapon_buttons() -> void:
	for i in range(12):
		var button_name := "Weapon%d" % (i + 1)
		var button := _find_button(button_name)
		if button == null:
			continue
		button.pressed.connect(_on_weapon_pressed.bind(i))
		button.disabled = false
		var weapon_name: String = weapon_defs[i].get("name", "Weapon")
		button.text = weapon_name
		button.tooltip_text = _weapon_tooltip(weapon_defs[i])


func _connect_shield_buttons() -> void:
	for i in range(12):
		var button_name := "Shield%d" % (i + 1)
		var button := _find_button(button_name)
		if button == null:
			continue
		button.pressed.connect(_on_shield_pressed.bind(i))
		var shield_name: String = shield_defs[i].get("name", "Shield")
		button.text = shield_name
		button.tooltip_text = _shield_tooltip(shield_defs[i])


func _on_weapon_pressed(weapon_id: int) -> void:
	if unlocked_weapons.has(weapon_id):
		_select_weapon(weapon_id)


func _on_shield_pressed(shield_id: int) -> void:
	_select_shield(shield_id)


func _cycle_weapon(step: int) -> void:
	_select_weapon(posmod(selected_weapon_id + step, weapon_defs.size()))


func _cycle_shield(step: int) -> void:
	_select_shield(posmod(selected_shield_id + step, shield_defs.size()))


func _unlock_weapon(weapon_id: int) -> void:
	if unlocked_weapons.has(weapon_id):
		return
	unlocked_weapons.append(weapon_id)
	var button := _find_button("Weapon%d" % (weapon_id + 1))
	if button != null:
		button.disabled = false


func _select_weapon(weapon_id: int) -> void:
	selected_weapon_id = clampi(weapon_id, 0, weapon_defs.size() - 1)
	for i in range(12):
		var button := _find_button("Weapon%d" % (i + 1))
		if button == null:
			continue
		button.modulate = Color(0.7, 0.85, 1.0, 1)
		if i == selected_weapon_id:
			button.modulate = Color(0.25, 1.0, 0.95, 1)


func _select_shield(shield_id: int) -> void:
	selected_shield_id = clampi(shield_id, 0, shield_defs.size() - 1)
	var def: Dictionary = shield_defs[selected_shield_id]
	shield_max = float(def.get("max", 60.0))
	shield_regen = float(def.get("regen", 14.0))
	shield_regen_delay = float(def.get("delay", 1.6))
	shield_trait = String(def.get("trait", "balanced"))
	player_hp_regen = 2.4
	if shield_trait == "hp_regen":
		player_hp_regen = 4.2
	shield_hp = min(shield_hp, shield_max)
	_apply_shield_visual_theme()
	for i in range(12):
		var button := _find_button("Shield%d" % (i + 1))
		if button == null:
			continue
		button.modulate = Color(0.85, 0.78, 1.0, 1)
		if i == selected_shield_id:
			button.modulate = Color(0.65, 0.95, 1.0, 1)


func _handle_weapon_unlocks() -> void:
	return


func _handle_player_movement(delta: float) -> void:
	var dir := Vector2(
		_axis_strength(["ui_right", "move_right"], [KEY_D]) - _axis_strength(["ui_left", "move_left"], [KEY_A]),
		_axis_strength(["ui_down", "move_down"], [KEY_S]) - _axis_strength(["ui_up", "move_up"], [KEY_W])
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	player.position += dir * PLAYER_SPEED * delta
	player.position = _clamp_inside_arena(player.position)

	var aim_target := _get_nearest_enemy(player.global_position, AUTO_TARGET_RADIUS)
	if aim_target != null:
		player.rotation = (aim_target.global_position - player.global_position).angle() + PI / 2.0
	elif dir != Vector2.ZERO:
		player.rotation = dir.angle() + PI / 2.0


func _update_player_trails(delta: float) -> void:
	player_trail_timer -= delta
	if player_trail_timer > 0.0:
		return
	player_trail_timer = 0.035

	var rear_dir := Vector2.DOWN.rotated(player.rotation)
	var left_nozzle := player.global_position + Vector2(-7.0, 13.0).rotated(player.rotation)
	var right_nozzle := player.global_position + Vector2(7.0, 13.0).rotated(player.rotation)
	var trail_len := 24.0 + sin(survival_time * 18.0) * 5.0
	_spawn_player_trail_segment(left_nozzle, rear_dir, trail_len)
	_spawn_player_trail_segment(right_nozzle, rear_dir, trail_len * 0.86)


func _spawn_player_trail_segment(origin: Vector2, direction: Vector2, length: float) -> void:
	var trail := Line2D.new()
	trail.set_meta("is_temp_fx", true)
	trail.z_index = -4
	trail.width = 6.4
	trail.default_color = Color(0.08, 0.9, 1.0, 0.76)
	trail.points = PackedVector2Array([origin, origin + direction.normalized() * length])
	trail.antialiased = true
	trail.material = _make_additive_material()
	add_child(trail)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "modulate:a", 0.0, 0.42)
	tween.tween_property(trail, "width", 0.3, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(trail.queue_free).set_delay(0.46)


func _process_auto_fire(delta: float) -> void:
	auto_fire_timer -= delta
	if auto_fire_timer > 0.0:
		return
	var target_radius := AUTO_TARGET_RADIUS + float(upgrade_levels["targeting"]) * 120.0
	var target := _get_nearest_enemy(player.global_position, target_radius)
	if target == null:
		return

	var weapon: Dictionary = weapon_defs[selected_weapon_id]
	_fire_weapon(weapon, target.global_position)
	var cd := float(weapon.get("cooldown", 0.4))
	cd *= (1.0 - min(0.55, _upgrade_value("attack_speed") * 0.06))
	cd *= (1.0 - min(0.45, _upgrade_value("overload") * 0.07))
	if shield_trait == "overcharge" and shield_hp >= shield_max * 0.95:
		cd *= 0.82
	auto_fire_timer = max(0.05, cd)


func _process_enemy_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	var late_level := _late_game_level()
	var zoom_progress := _zoom_out_progress()
	var enemy_level_mult := _enemy_level_multiplier()
	var active_cap := int(round((125.0 + zoom_progress * 260.0) * enemy_level_mult)) + mini(late_level, 20) * 3
	if enemies.size() >= active_cap:
		spawn_timer = maxf(0.18, 0.45 - zoom_progress * 0.18)
		return

	var pre_late_wave := mini(wave_index, 8)
	var post_late_wave := maxi(0, wave_index - 8)
	var wave_size := int(round((12.0 + float(pre_late_wave) * 4.0 + float(post_late_wave) * 2.0 + zoom_progress * 26.0) * enemy_level_mult))
	if late_level > 0:
		wave_size = mini(wave_size + late_level, int(round((72.0 + float(late_level) * 2.0) * enemy_level_mult)))
	wave_size = mini(wave_size, active_cap - enemies.size())
	var interval: float = max(0.12, 0.62 - float(pre_late_wave) * 0.025 - zoom_progress * 0.18)
	if late_level > 0:
		interval = max(0.18, interval + float(late_level) * 0.004)
	for i in range(wave_size):
		_spawn_enemy(float(i) * 0.025)
	spawn_timer = interval + 0.55

	if wave_timer >= 14.0:
		wave_index += 1
		wave_timer = 0.0


func _late_game_level() -> int:
	return maxi(0, level - 30)


func _enemy_level_multiplier() -> float:
	return (1.0 + float(maxi(level, 1)) * 0.3) * _enemy_density_factor()


func _enemy_density_factor() -> float:
	if level <= 100:
		return 0.5
	return lerpf(0.5, 1.0, clampf(float(level - 100) / 20.0, 0.0, 1.0))


func _zoom_out_progress() -> float:
	var time_progress := clampf(survival_time / 6000.0, 0.0, 1.0)
	var level_progress := clampf(float(level - 1) / 500.0, 0.0, 1.0)
	var wave_progress := clampf(float(wave_index) / 300.0, 0.0, 1.0)
	return maxf(time_progress, maxf(level_progress, wave_progress))


func _current_zoom_out_factor() -> float:
	return lerpf(1.0, CAMERA_MAX_ZOOM_OUT, _zoom_out_progress())


func _update_camera_zoom() -> void:
	if camera == null:
		return
	var target_zoom := CAMERA_START_ZOOM / _current_zoom_out_factor()
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, 0.045)


func _choose_enemy_archetype() -> Dictionary:
	var roll: float = randf()
	var w: int = wave_index
	var tank_w: float = 0.11 + float(mini(w, 10)) * 0.028
	var dart_w: float = 0.27 + float(mini(w, 8)) * 0.022
	var hex_w: float = 0.24 + float(mini(w, 6)) * 0.015
	var t_end: float = tank_w
	var d_end: float = t_end + dart_w
	var h_end: float = d_end + hex_w
	if roll < t_end:
		return ENEMY_ARCHETYPES[2]
	if roll < d_end:
		return ENEMY_ARCHETYPES[1]
	if roll < h_end:
		return ENEMY_ARCHETYPES[3]
	return ENEMY_ARCHETYPES[0]


func _spawn_enemy(delay: float) -> void:
	var enemy := EnemyScene.instantiate() as Node2D
	enemy.name = "Enemy%d" % next_enemy_id
	next_enemy_id += 1
	enemy.position = _random_edge_position()
	enemy.set_meta("spawn_delay", delay)

	var archetype := _choose_enemy_archetype()
	enemy.set_meta("enemy_type", archetype.get("id", "spinner"))
	enemy.set_meta("enemy_name", archetype.get("name", "Enemy"))
	var late_level := _late_game_level()
	var quality_hp_mult := 1.0 + float(late_level) * 0.035
	var quality_damage_mult := 1.0 + float(late_level) * 0.022
	var quality_speed_mult := 1.0 + minf(0.18, float(late_level) * 0.006)
	var max_hp := (20.0 + float(wave_index) * 8.0 + randf_range(0.0, 6.0)) * float(archetype.get("hp_mult", 1.0)) * quality_hp_mult
	var speed := (92.0 + float(wave_index) * 10.0 + randf_range(0.0, 24.0)) * float(archetype.get("speed_mult", 1.0)) * quality_speed_mult
	var max_speed := speed * (1.65 + float(archetype.get("speed_mult", 1.0)) * 0.28)
	var accel := (260.0 + float(wave_index) * 24.0) * float(archetype.get("accel_mult", 1.0))
	var touch_damage := (11.0 + float(wave_index) * 1.8) * float(archetype.get("touch_mult", 1.0)) * quality_damage_mult
	enemy.set_meta("health", max_hp)
	enemy.set_meta("max_health", max_hp)
	enemy.set_meta("speed", speed)
	enemy.set_meta("max_speed", max_speed)
	enemy.set_meta("accel", accel)
	enemy.set_meta("velocity", Vector2.ZERO)
	enemy.set_meta("orbit_mult", float(archetype.get("orbit_mult", 1.0)))
	enemy.set_meta("score_value", 10 + wave_index * 3)
	enemy.set_meta("touch_damage", touch_damage)
	enemy.set_meta("touch_cooldown", 0.0)
	if enemy.has_method("initialize_stats"):
		enemy.call("initialize_stats", int(round(max_hp)))
	if String(archetype.get("id", "")) == "dart":
		enemy.set_meta("dart_fish_left", randf_range(0.3, 1.8))
		enemy.set_meta("dart_hunt_left", 0.0)
	_style_enemy_visual(enemy, archetype)

	enemies_root.add_child(enemy)
	enemies.append(enemy)
	_emit_enemy_health_changed(enemy)


func _dart_swarm_stats() -> Dictionary:
	var centroid := Vector2.ZERO
	var vel_sum := Vector2.ZERO
	var n: int = 0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if float(e.get_meta("spawn_delay", 0.0)) > 0.0:
			continue
		if String(e.get_meta("enemy_type", "")) != "dart":
			continue
		centroid += e.global_position
		vel_sum += e.get_meta("velocity", Vector2.ZERO) as Vector2
		n += 1
	if n < 1:
		return {"n": 0, "centroid": Vector2.ZERO, "avg_vel": Vector2.ZERO}
	return {"n": n, "centroid": centroid / float(n), "avg_vel": vel_sum / float(n)}


func _update_dart_enemy(enemy: Node2D, delta: float, swarm: Dictionary, player_pos: Vector2) -> void:
	var base_speed: float = float(enemy.get_meta("speed", 90.0))
	var max_speed: float = float(enemy.get_meta("max_speed", base_speed * 1.8))
	var accel: float = float(enemy.get_meta("accel", 220.0))
	max_speed *= 0.82
	base_speed *= 0.88
	var velocity: Vector2 = enemy.get_meta("velocity", Vector2.ZERO) as Vector2

	var hunt: float = float(enemy.get_meta("dart_hunt_left", 0.0))
	var fish: float = float(enemy.get_meta("dart_fish_left", 1.0))
	var hunt_active: bool = hunt > 0.0

	var to_player: Vector2 = (player_pos - enemy.global_position).normalized()
	var n_swarm: int = int(swarm.get("n", 0))
	var centroid: Vector2 = swarm.get("centroid", Vector2.ZERO) as Vector2
	var avg_vel: Vector2 = swarm.get("avg_vel", Vector2.ZERO) as Vector2
	var id_phase: float = float(enemy.get_instance_id()) * 0.00917

	var fish_dir: Vector2
	if n_swarm < 2:
		var wobble := Vector2(cos(survival_time * 1.65 + id_phase), sin(survival_time * 1.4 + id_phase * 1.1)).normalized()
		fish_dir = (wobble * 0.88 + to_player * 0.12).normalized()
	else:
		var to_centroid: Vector2 = centroid - enemy.global_position
		var cohesion: Vector2
		if to_centroid.length() > 16.0:
			cohesion = to_centroid.normalized()
		elif avg_vel.length() > 22.0:
			cohesion = avg_vel.normalized()
		else:
			cohesion = Vector2(cos(survival_time * 1.1 + id_phase), sin(survival_time * 0.95 + id_phase)).normalized()
		var alignv: Vector2
		if avg_vel.length() > 20.0:
			alignv = avg_vel.normalized()
		else:
			alignv = cohesion
		var swim: Vector2 = Vector2(-cohesion.y, cohesion.x) * sin(survival_time * 2.25 + id_phase) * 0.52
		fish_dir = (cohesion * 0.48 + alignv * 0.36 + swim).normalized()
		if fish_dir.length() < 0.01:
			fish_dir = to_player

	var desired: Vector2
	if hunt_active:
		desired = (to_player * 0.84 + fish_dir * 0.16).normalized() * max_speed
	else:
		desired = (fish_dir * 0.93 + to_player * 0.07).normalized() * max_speed * 0.74

	var desired_dir := desired.normalized()
	var thrust: float = accel * (0.82 if hunt_active else 0.46)
	velocity += desired_dir * thrust * delta
	var drag: float = 0.2 if hunt_active else 0.12
	velocity *= maxf(0.0, 1.0 - drag * delta)
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	if hunt_active:
		hunt = max(0.0, hunt - delta)
		if hunt <= 0.0:
			fish = randf_range(2.2, 5.5)
	else:
		fish = max(0.0, fish - delta)
		if fish <= 0.0:
			if randf() < 0.3:
				hunt = randf_range(0.55, 1.35)
			fish = randf_range(1.0, 2.7)
	enemy.set_meta("dart_hunt_left", hunt)
	enemy.set_meta("dart_fish_left", fish)

	enemy.set_meta("velocity", velocity)
	enemy.position += velocity * delta
	if velocity.length() > 0.01:
		enemy.rotation = velocity.angle() + PI / 2.0

	var touch_cd: float = max(0.0, float(enemy.get_meta("touch_cooldown", 0.0)) - delta)
	enemy.set_meta("touch_cooldown", touch_cd)
	_tick_enemy_effects(enemy, delta)


func _update_enemies(delta: float) -> void:
	var dart_swarm: Dictionary = _dart_swarm_stats()
	var player_pos: Vector2 = player.global_position
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Node2D = enemies[i]
		if not is_instance_valid(enemy):
			enemies.remove_at(i)
			continue

		var delay_left: float = float(enemy.get_meta("spawn_delay", 0.0))
		if delay_left > 0.0:
			enemy.set_meta("spawn_delay", max(0.0, delay_left - delta))
			continue

		if String(enemy.get_meta("enemy_type", "")) == "dart":
			_update_dart_enemy(enemy, delta, dart_swarm, player_pos)
			continue

		var base_speed: float = float(enemy.get_meta("speed", 90.0))
		var max_speed: float = float(enemy.get_meta("max_speed", base_speed * 1.8))
		var accel: float = float(enemy.get_meta("accel", 220.0))
		var orbit_mult: float = float(enemy.get_meta("orbit_mult", 1.0))
		var velocity: Vector2 = enemy.get_meta("velocity", Vector2.ZERO)
		var to_player := (player.global_position - enemy.global_position).normalized()
		var swarm_orbit := Vector2(-to_player.y, to_player.x) * sin((survival_time + float(enemy.get_instance_id()) * 0.01) * 2.4) * 0.38 * orbit_mult
		var desired_dir := (to_player + swarm_orbit).normalized()
		velocity += desired_dir * accel * 0.48 * delta
		velocity *= maxf(0.0, 1.0 - 0.16 * delta)
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
		enemy.set_meta("velocity", velocity)
		enemy.position += velocity * delta
		if velocity.length() > 0.01:
			enemy.rotation = velocity.angle() + PI / 2.0

		var touch_cd: float = max(0.0, float(enemy.get_meta("touch_cooldown", 0.0)) - delta)
		enemy.set_meta("touch_cooldown", touch_cd)
		_tick_enemy_effects(enemy, delta)


func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Node2D = bullets[i]
		if not is_instance_valid(bullet):
			bullets.remove_at(i)
			continue

		var vel: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
		var life: float = float(bullet.get_meta("life", 0.0))
		var age: float = float(bullet.get_meta("age", 0.0)) + delta
		bullet.set_meta("age", age)
		var trail_phase: float = float(bullet.get_meta("trail_phase", 0.0)) + delta * 8.0
		bullet.set_meta("trail_phase", trail_phase)
		_update_special_projectile(bullet, delta, i)
		if not is_instance_valid(bullet):
			continue
		vel = bullet.get_meta("velocity", Vector2.ZERO)
		if int(upgrade_levels["targeting"]) > 0 and not bool(bullet.get_meta("no_upgrade_homing", false)):
			var homing_target := _get_nearest_enemy(bullet.global_position, 260.0)
			if homing_target != null:
				var to_target := homing_target.global_position - bullet.global_position
				var current_speed: float = maxf(vel.length(), float(bullet.get_meta("projectile_speed", BULLET_SPEED)))
				if to_target.length_squared() > 64.0 and current_speed > 1.0:
					var desired := to_target.normalized() * current_speed
					var turn_rate: float = min(0.38, 0.12 + float(upgrade_levels["targeting"]) * 0.06)
					vel = vel.lerp(desired, turn_rate)
					if vel.length() < current_speed * 0.6:
						vel = vel.normalized() * current_speed * 0.6
					bullet.set_meta("velocity", vel)
		bullet.position += vel * delta
		bullet.rotation = vel.angle() + PI / 2.0
		life -= delta
		bullet.set_meta("life", life)
		_update_bullet_trail(bullet, trail_phase)
		if life <= 0.0:
			if _is_blast_behavior(String(bullet.get_meta("behavior", ""))):
				_detonate_projectile(bullet, i)
			else:
				_destroy_bullet(i)
			continue

		if not _is_inside_arena(bullet.global_position):
			_handle_bullet_boundary(bullet, i)
			continue

		var enemy := _first_hit_enemy(bullet.global_position, 16.0)
		if enemy != null:
			_on_bullet_hit_enemy(bullet, enemy, i)


func _fire_weapon(weapon: Dictionary, target_pos: Vector2) -> void:
	var behavior: String = String(weapon.get("behavior", weapon.get("archetype", "pulse")))
	var projectile_count := int(weapon.get("projectiles", 1)) + _upgrade_int("multishot")
	var spread_deg := float(weapon.get("spread_deg", 0.0)) + _upgrade_value("multishot") * 2.0
	var damage := _scaled_weapon_damage(weapon)
	var to_target := (target_pos - player.global_position).normalized()
	if to_target == Vector2.ZERO:
		to_target = Vector2.UP
	var base_angle := to_target.angle()

	if behavior == "lightning":
		var target := _get_nearest_enemy(player.global_position, AUTO_TARGET_RADIUS + _upgrade_value("targeting") * 120.0)
		if target != null:
			var jumps := int(weapon.get("chain_jumps", 2)) + _upgrade_int("chain")
			var chain_range := float(weapon.get("chain_range", 190.0)) + _upgrade_value("targeting") * 60.0
			_cast_lightning(target, damage, jumps, chain_range)
			for i in range(_upgrade_int("forked_arc")):
				var fork := _get_nearest_enemy(player.global_position, AUTO_TARGET_RADIUS, target)
				if fork != null:
					_spawn_special_burst(player.global_position, Color(0.25, 0.86, 1.0, 0.9), 22.0, 0.22, 9)
					_cast_lightning(fork, damage * 0.65, maxi(1, jumps - 1), chain_range * 0.8)
		return
	if behavior == "rail":
		_fire_rail_line(to_target, damage, weapon)
		return

	var bullet_speed := BULLET_SPEED
	if weapon.has("speed"):
		bullet_speed = float(weapon.get("speed", BULLET_SPEED))
	bullet_speed *= (1.0 + _upgrade_value("velocity") * 0.12)

	for i in range(projectile_count):
		var t := 0.5
		if projectile_count > 1:
			t = float(i) / float(projectile_count - 1)
		var spread := deg_to_rad(lerpf(-spread_deg, spread_deg, t))
		var dir := Vector2.from_angle(base_angle + spread).normalized()
		var muzzle_offset := Vector2.ZERO
		if behavior == "twin_fang":
			var side := -1.0 if i % 2 == 0 else 1.0
			muzzle_offset = Vector2(side * 13.0, -4.0)
			dir = dir.rotated(deg_to_rad(-side * 5.5)).normalized()
		_spawn_bullet(dir, damage, weapon, bullet_speed, muzzle_offset)


func _scaled_weapon_damage(weapon: Dictionary) -> float:
	return float(weapon.get("damage", 6.0)) * (1.0 + _upgrade_value("damage") * 0.12)


func _spawn_bullet(direction: Vector2, damage: float, weapon: Dictionary, speed: float, muzzle_offset: Vector2 = Vector2.ZERO) -> void:
	var bullet := Node2D.new()
	bullet.position = player.position + muzzle_offset.rotated(player.rotation)
	bullet.set_meta("velocity", direction * speed)
	bullet.set_meta("projectile_speed", speed)
	bullet.set_meta("damage", damage)
	bullet.set_meta("life", float(weapon.get("life", 2.2)))
	bullet.set_meta("archetype", String(weapon.get("archetype", "pulse")))
	bullet.set_meta("behavior", String(weapon.get("behavior", weapon.get("archetype", "pulse"))))
	bullet.set_meta("weapon_id", int(weapon.get("id", -1)))
	var blast_bonus := 1.0 + (_upgrade_value("blast") + _upgrade_value("field_amplifier") + _upgrade_value("plasma_scorch") + _upgrade_value("mycelium_zone")) * 0.18
	bullet.set_meta("blast_radius", float(weapon.get("blast_radius", 0.0)) * blast_bonus)
	var dot_power := _upgrade_value("corrosion_payload") + (_upgrade_value("prism_edge") if String(weapon.get("behavior", "")) == "photon" else 0.0)
	bullet.set_meta("poison_dps", float(weapon.get("poison_dps", 0.0)) + dot_power * 2.2)
	bullet.set_meta("poison_time", float(weapon.get("poison_time", 0.0)) + dot_power * 0.35)
	bullet.set_meta("pierce_left", int(weapon.get("base_pierce", 0)) + _upgrade_int("pierce"))
	bullet.set_meta("bounce_left", int(weapon.get("base_bounce", 0)) + _upgrade_int("bounce"))
	bullet.set_meta("chain_left", int(weapon.get("chain_jumps", 0)) + _upgrade_int("chain"))
	bullet.set_meta("chain_range", float(weapon.get("chain_range", 180.0)))
	bullet.set_meta("hit_ids", PackedInt64Array())
	bullet.set_meta("trail_phase", randf() * TAU)
	bullet.set_meta("special_tick", 0.0)
	bullet.set_meta("trail_damage_tick", 0.0)
	bullet.set_meta("age", 0.0)
	bullet.set_meta("split_left", _upgrade_int("split"))

	var glow := Polygon2D.new()
	var archetype: String = String(weapon.get("archetype", "bullet"))
	glow.color = _weapon_glow_color(archetype)
	glow.polygon = _weapon_glow_shape(archetype)
	glow.rotation = direction.angle() + PI / 2.0
	glow.scale = Vector2.ONE * _weapon_visual_scale(archetype)
	glow.material = _make_additive_material()
	bullet.add_child(glow)

	var core := Polygon2D.new()
	core.color = _weapon_core_color(archetype)
	core.polygon = _weapon_core_shape(archetype)
	core.rotation = direction.angle() + PI / 2.0
	core.scale = Vector2.ONE * (1.18 if archetype == "starbreaker" else 1.0)
	bullet.add_child(core)

	var trail := Line2D.new()
	trail.width = _weapon_trail_width(archetype)
	trail.default_color = _weapon_trail_color(archetype)
	trail.points = PackedVector2Array([Vector2(0, 0), Vector2(0, _weapon_trail_length(archetype))])
	trail.antialiased = true
	trail.z_index = -1
	trail.material = _make_additive_material()
	bullet.add_child(trail)
	bullet.set_meta("trail_node", trail)
	if _trail_damage_power_for_bullet(bullet) > 0.0:
		var damage_trail := Line2D.new()
		damage_trail.width = trail.width + 3.0
		damage_trail.default_color = Color(0.74, 1.0, 0.96, 0.9) if archetype != "shrapnel" else Color(1.0, 0.32, 0.98, 0.9)
		damage_trail.points = PackedVector2Array([Vector2(0, 0), Vector2(0, _weapon_trail_length(archetype) * 1.45)])
		damage_trail.antialiased = true
		damage_trail.z_index = -2
		damage_trail.material = _make_additive_material()
		bullet.add_child(damage_trail)
		bullet.set_meta("damage_trail_node", damage_trail)
	if archetype == "rail":
		var rail_core := Line2D.new()
		rail_core.width = 2.0
		rail_core.default_color = Color(0.96, 1.0, 1.0, 1.0)
		rail_core.points = PackedVector2Array([Vector2(0, -26), Vector2(0, 54)])
		rail_core.antialiased = true
		bullet.add_child(rail_core)
		_spawn_rail_lance(player.global_position, direction)
	elif _is_blast_behavior(String(bullet.get_meta("behavior", ""))):
		_add_blast_projectile_rings(bullet, archetype)

	bullets_root.add_child(bullet)
	bullets.append(bullet)
	_spawn_muzzle_flash(player.global_position + direction.normalized() * 20.0, direction, archetype)


func _on_bullet_hit_enemy(bullet: Node2D, enemy: Node2D, bullet_index: int) -> void:
	var damage := float(bullet.get_meta("damage", 1.0))
	var chain_left := int(bullet.get_meta("chain_left", 0))
	var pierce_left := int(bullet.get_meta("pierce_left", 0))
	var archetype: String = bullet.get_meta("archetype", "bullet")
	var behavior: String = String(bullet.get_meta("behavior", archetype))
	var poison_dps := float(bullet.get_meta("poison_dps", 0.0))
	var poison_time := float(bullet.get_meta("poison_time", 0.0))
	var blast_radius := float(bullet.get_meta("blast_radius", 0.0))
	var split_left := int(bullet.get_meta("split_left", 0))
	var velocity: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
	var speed := velocity.length()
	damage = _modified_hit_damage(enemy, damage, behavior)
	_spawn_hit_spark(enemy.global_position, archetype, max(0.7, min(1.8, damage / 14.0)))
	var dealt := _damage_enemy(enemy, damage)
	_apply_on_damage_dealt(dealt)
	if poison_dps > 0.0 and poison_time > 0.0:
		_apply_poison(enemy, poison_dps, poison_time)
		if behavior == "toxic":
			_splash_poison(enemy.global_position, poison_dps * 0.45, poison_time * 0.55, 82.0, enemy)

	if _is_blast_behavior(behavior):
		_apply_explosion(enemy.global_position, blast_radius, damage * 0.65, poison_dps, poison_time, archetype)
	elif _upgrade_value("impact_bloom") > 0.0:
		_apply_explosion(enemy.global_position, 24.0 + _upgrade_value("impact_bloom") * 9.0, damage * 0.22, 0.0, 0.0, archetype)

	if chain_left > 0:
		var chain_range := float(bullet.get_meta("chain_range", 180.0))
		_chain_from_enemy(enemy, damage * 0.8, chain_left - 1, chain_range)
		bullet.set_meta("chain_left", chain_left - 1)

	if split_left > 0 and speed > 0.0:
		_spawn_split_shards(bullet.global_position, velocity.normalized(), damage * 0.65, speed * 0.92, split_left - 1, archetype)

	if behavior == "ricochet" and _redirect_ricochet(bullet, enemy):
		return
	if _upgrade_value("gravity_well") > 0.0 or behavior == "void":
		_apply_pull(enemy.global_position, 90.0 + _upgrade_value("gravity_well") * 18.0, 150.0)

	if pierce_left > 0:
		bullet.set_meta("pierce_left", pierce_left - 1)
	else:
		_destroy_bullet(bullet_index)


func _handle_bullet_boundary(bullet: Node2D, bullet_index: int) -> void:
	var bounce_left := int(bullet.get_meta("bounce_left", 0))
	if bounce_left <= 0:
		_destroy_bullet(bullet_index)
		return

	var vel: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
	var p := bullet.position
	if p.x < -ARENA_HALF_SIZE.x or p.x > ARENA_HALF_SIZE.x:
		vel.x *= -1.0
	if p.y < -ARENA_HALF_SIZE.y or p.y > ARENA_HALF_SIZE.y:
		vel.y *= -1.0
	bullet.set_meta("velocity", vel)
	bullet.set_meta("bounce_left", bounce_left - 1)
	bullet.position = _clamp_inside_arena(bullet.position)


func _is_blast_behavior(behavior: String) -> bool:
	return behavior == "mortar" or behavior == "starbreaker" or behavior == "spore" or behavior == "bomb" or behavior == "nuke"


func _fire_rail_line(direction: Vector2, damage: float, weapon: Dictionary) -> void:
	var rail_dir := direction.normalized()
	if rail_dir == Vector2.ZERO:
		rail_dir = Vector2.UP
	var origin := player.global_position
	var rail_len := 2200.0
	var rail_width := 34.0
	_spawn_rail_lance(origin, rail_dir, rail_len)
	if _upgrade_value("rail_afterimage") > 0.0:
		_spawn_rail_damage_trace(origin, rail_dir, rail_len, rail_width + 18.0, damage * 0.08 * _upgrade_value("rail_afterimage"))
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var rel := enemy.global_position - origin
		var along := rel.dot(rail_dir)
		if along < 0.0 or along > rail_len:
			continue
		var closest := origin + rail_dir * along
		if enemy.global_position.distance_to(closest) > rail_width:
			continue
		var rail_damage := _modified_hit_damage(enemy, damage, "rail")
		var dealt := _damage_enemy(enemy, rail_damage)
		_apply_on_damage_dealt(dealt)
		_spawn_hit_spark(enemy.global_position, String(weapon.get("archetype", "rail")), max(1.0, min(2.2, rail_damage / 20.0)))
		if _upgrade_value("rail_afterimage") > 0.0:
			_damage_enemy(enemy, rail_damage * 0.08 * _upgrade_value("rail_afterimage"))
			_spawn_special_burst(enemy.global_position, Color(1.0, 0.45, 1.0, 0.75), 16.0, 0.2, 5)


func _detonate_projectile(bullet: Node2D, bullet_index: int) -> void:
	if not is_instance_valid(bullet):
		return
	var radius := float(bullet.get_meta("blast_radius", 0.0))
	var damage := float(bullet.get_meta("damage", 0.0))
	var poison_dps := float(bullet.get_meta("poison_dps", 0.0))
	var poison_time := float(bullet.get_meta("poison_time", 0.0))
	var archetype := String(bullet.get_meta("archetype", "mortar"))
	if radius > 0.0:
		_apply_explosion(bullet.global_position, radius, damage * 0.72, poison_dps, poison_time, archetype)
		if String(bullet.get_meta("behavior", "")) == "starbreaker" and _upgrade_value("stellar_fragments") > 0.0:
			_spawn_special_burst(bullet.global_position, Color(1.0, 0.88, 0.28, 0.9), 52.0, 0.34, 12)
			for i in range(6):
				_spawn_split_shards(bullet.global_position, Vector2.from_angle(TAU * float(i) / 6.0), damage * 0.22, 620.0, 0, archetype)
	_destroy_bullet(bullet_index)


func _update_special_projectile(bullet: Node2D, delta: float, _bullet_index: int) -> void:
	var behavior := String(bullet.get_meta("behavior", "pulse"))
	var vel: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
	var speed := maxf(1.0, vel.length())
	_tick_trail_damage(bullet, delta)
	match behavior:
		"shrapnel":
			var tick := float(bullet.get_meta("special_tick", 0.0)) - delta
			if tick <= 0.0:
				var age := float(bullet.get_meta("age", 0.0))
				var dir := vel.normalized().rotated(age * 7.5)
				_spawn_split_shards(bullet.global_position, dir, float(bullet.get_meta("damage", 1.0)) * 0.42, speed * 1.18, 0, "shrapnel")
				tick = 0.105
			bullet.set_meta("special_tick", tick)
		"void":
			vel *= maxf(0.0, 1.0 - delta * 0.32)
			bullet.set_meta("velocity", vel)
			var pull_radius := 126.0 + _upgrade_value("singularity_echo") * 28.0
			var echo_tick := float(bullet.get_meta("echo_vfx_tick", 0.0)) - delta
			var echo_visible := false
			for enemy in enemies:
				if not is_instance_valid(enemy):
					continue
				var to_bolt := bullet.global_position - enemy.global_position
				var dist := to_bolt.length()
				if dist <= 0.1 or dist > pull_radius:
					continue
				var enemy_velocity: Vector2 = enemy.get_meta("velocity", Vector2.ZERO)
				enemy_velocity += to_bolt.normalized() * (88.0 * (1.0 - dist / pull_radius)) * delta
				enemy.set_meta("velocity", enemy_velocity)
				if _upgrade_value("singularity_echo") > 0.0:
					_apply_on_damage_dealt(_damage_enemy(enemy, 1.4 * _upgrade_value("singularity_echo") * delta))
					echo_visible = true
			if echo_visible and echo_tick <= 0.0:
				_spawn_pull_visual(bullet.global_position, pull_radius, Color(0.78, 0.38, 1.0, 0.7))
				echo_tick = 0.16
			bullet.set_meta("echo_vfx_tick", echo_tick)
		"starbreaker":
			var target := _get_nearest_enemy(bullet.global_position, 420.0)
			if target != null:
				var desired := (target.global_position - bullet.global_position).normalized() * speed
				vel = vel.lerp(desired, 0.035)
				bullet.set_meta("velocity", vel)
		"mortar":
			var age := float(bullet.get_meta("age", 0.0))
			vel = vel.rotated(sin(age * 8.0) * delta * 0.9)
			bullet.set_meta("velocity", vel)
		"spore":
			var tick := float(bullet.get_meta("special_tick", 0.0)) - delta
			if tick <= 0.0:
				_spawn_spore_mote(bullet.global_position, String(bullet.get_meta("archetype", "spore")))
				tick = 0.12
			bullet.set_meta("special_tick", tick)


func _redirect_ricochet(bullet: Node2D, hit_enemy: Node2D) -> bool:
	var bounce_left := int(bullet.get_meta("bounce_left", 0))
	if bounce_left <= 0:
		return false
	var target := _get_nearest_enemy(hit_enemy.global_position, 520.0, hit_enemy)
	var velocity: Vector2 = bullet.get_meta("velocity", Vector2.RIGHT * BULLET_SPEED)
	var speed := maxf(float(bullet.get_meta("projectile_speed", BULLET_SPEED)) * 1.04, velocity.length())
	if target != null:
		velocity = (target.global_position - hit_enemy.global_position).normalized() * speed
	else:
		velocity = velocity.normalized().rotated(randf_range(-1.1, 1.1)) * speed
	bullet.set_meta("velocity", velocity)
	bullet.set_meta("damage", float(bullet.get_meta("damage", 1.0)) * (1.12 + _upgrade_value("saw_acceleration") * 0.03))
	if _upgrade_value("saw_acceleration") > 0.0:
		_spawn_special_burst(hit_enemy.global_position, Color(1.0, 0.86, 0.16, 0.86), 22.0, 0.18, 8)
	bullet.set_meta("bounce_left", bounce_left - 1)
	bullet.global_position += velocity.normalized() * 24.0
	return true


func _trail_damage_power_for_bullet(bullet: Node2D) -> float:
	return _upgrade_value("ion_trails") + (_upgrade_value("vortex_teeth") if String(bullet.get_meta("behavior", "")) == "shrapnel" else 0.0)


func _tick_trail_damage(bullet: Node2D, delta: float) -> void:
	var trail_power := _trail_damage_power_for_bullet(bullet)
	if trail_power <= 0.0:
		return
	var tick := float(bullet.get_meta("trail_damage_tick", 0.0)) - delta
	if tick > 0.0:
		bullet.set_meta("trail_damage_tick", tick)
		return
	bullet.set_meta("trail_damage_tick", 0.12)
	var damaged := false
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(bullet.global_position) <= 18.0 + trail_power * 2.0:
			_apply_on_damage_dealt(_damage_enemy(enemy, 0.7 * trail_power))
			damaged = true
	if damaged:
		_spawn_special_burst(bullet.global_position, Color(0.75, 1.0, 0.96, 0.72), 14.0 + trail_power * 2.0, 0.16, 4)


func _apply_pull(origin: Vector2, radius: float, force: float) -> void:
	var pulled := false
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var to_origin := origin - enemy.global_position
		var dist := to_origin.length()
		if dist <= 0.1 or dist > radius:
			continue
		var enemy_velocity: Vector2 = enemy.get_meta("velocity", Vector2.ZERO)
		enemy_velocity += to_origin.normalized() * force * (1.0 - dist / radius) * 0.08
		enemy.set_meta("velocity", enemy_velocity)
		pulled = true
	if pulled:
		_spawn_pull_visual(origin, radius, Color(0.58, 0.9, 1.0, 0.62))


func _chain_from_enemy(source: Node2D, damage: float, chain_left: int, chain_range: float) -> void:
	var target := _get_nearest_enemy(source.global_position, chain_range, source)
	if target == null:
		return
	var dir := (target.global_position - source.global_position).normalized()
	var chained := Node2D.new()
	chained.position = source.position
	chained.set_meta("velocity", dir * BULLET_SPEED * 1.2)
	chained.set_meta("damage", damage)
	chained.set_meta("life", 0.7)
	chained.set_meta("pierce_left", 0)
	chained.set_meta("bounce_left", 0)
	chained.set_meta("chain_left", chain_left)
	chained.set_meta("chain_range", chain_range)
	chained.set_meta("archetype", "chain")
	chained.set_meta("behavior", "chain")
	chained.set_meta("blast_radius", 0.0)
	chained.set_meta("poison_dps", 0.0)
	chained.set_meta("poison_time", 0.0)
	chained.set_meta("hit_ids", PackedInt64Array([source.get_instance_id()]))
	chained.set_meta("trail_phase", randf() * TAU)
	chained.set_meta("special_tick", 0.0)
	chained.set_meta("age", 0.0)
	var shard := Polygon2D.new()
	shard.color = Color(0.35, 1.0, 0.9, 0.85)
	shard.polygon = PackedVector2Array([Vector2(0, -4), Vector2(2, 2), Vector2(-2, 2)])
	shard.rotation = dir.angle() + PI / 2.0
	chained.add_child(shard)
	bullets_root.add_child(chained)
	bullets.append(chained)


func _spawn_split_shards(origin: Vector2, base_dir: Vector2, damage: float, speed: float, split_left: int, archetype: String) -> void:
	for spread_deg in [-20.0, 20.0]:
		var dir := base_dir.rotated(deg_to_rad(spread_deg))
		var shard := Node2D.new()
		shard.position = origin
		shard.set_meta("velocity", dir * speed)
		shard.set_meta("projectile_speed", speed)
		shard.set_meta("damage", damage)
		shard.set_meta("life", 1.0)
		shard.set_meta("archetype", archetype)
		shard.set_meta("behavior", "shard")
		shard.set_meta("blast_radius", 0.0)
		shard.set_meta("poison_dps", 0.0)
		shard.set_meta("poison_time", 0.0)
		shard.set_meta("pierce_left", 0)
		shard.set_meta("bounce_left", 0)
		shard.set_meta("chain_left", 0)
		shard.set_meta("chain_range", 0.0)
		shard.set_meta("hit_ids", PackedInt64Array())
		shard.set_meta("trail_phase", randf() * TAU)
		shard.set_meta("special_tick", 0.0)
		shard.set_meta("age", 0.0)
		shard.set_meta("split_left", split_left)

		var glow := Polygon2D.new()
		glow.color = _weapon_glow_color(archetype)
		glow.polygon = PackedVector2Array([Vector2(0, -7), Vector2(4, 3), Vector2(-4, 3)])
		glow.rotation = dir.angle() + PI / 2.0
		shard.add_child(glow)

		var core := Polygon2D.new()
		core.color = _weapon_core_color(archetype)
		core.polygon = PackedVector2Array([Vector2(0, -4), Vector2(2, 1), Vector2(-2, 1)])
		core.rotation = dir.angle() + PI / 2.0
		shard.add_child(core)

		var trail := Line2D.new()
		trail.width = 1.8
		trail.default_color = _weapon_trail_color(archetype)
		trail.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 8)])
		trail.antialiased = true
		trail.z_index = -1
		trail.material = _make_additive_material()
		shard.add_child(trail)
		shard.set_meta("trail_node", trail)

		bullets_root.add_child(shard)
		bullets.append(shard)


func _cast_lightning(start: Node2D, damage: float, jumps: int, chain_range: float) -> void:
	var current: Node2D = start
	var already_hit: Array[int] = []
	_spawn_chain_arc_visual(player.global_position, start.global_position, 0)
	for i in range(jumps + 1):
		if current == null or not is_instance_valid(current):
			return
		_damage_enemy(current, damage * (1.0 - float(i) * 0.12))
		already_hit.append(current.get_instance_id())

		var next_enemy: Node2D = null
		var best_d2 := chain_range * chain_range
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if already_hit.has(enemy.get_instance_id()):
				continue
			var d2 := enemy.global_position.distance_squared_to(current.global_position)
			if d2 < best_d2:
				best_d2 = d2
				next_enemy = enemy
		if next_enemy != null:
			_spawn_chain_arc_visual(current.global_position, next_enemy.global_position, i + 1)
		current = next_enemy


func _spawn_chain_arc_visual(from_pos: Vector2, to_pos: Vector2, jump_index: int) -> void:
	var delta := to_pos - from_pos
	var dist := delta.length()
	if dist < 4.0:
		return
	var dir := delta / dist
	var normal := Vector2(-dir.y, dir.x)
	var segments := maxi(4, int(dist / 28.0))
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var offset := 0.0
		if i > 0 and i < segments:
			offset = randf_range(-10.0, 10.0) * (1.0 - abs(t - 0.5) * 0.6)
		pts.append(from_pos + delta * t + normal * offset)

	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.z_index = 9
	add_child(fx)

	var glow := Line2D.new()
	glow.width = 6.0
	glow.default_color = Color(0.16, 0.82, 1.0, 0.34)
	glow.points = pts
	glow.antialiased = true
	glow.material = _make_additive_material()
	fx.add_child(glow)

	var core := Line2D.new()
	core.width = 2.0
	core.default_color = Color(0.82, 0.98, 1.0, 1.0)
	core.points = pts
	core.antialiased = true
	fx.add_child(core)

	var spark := Polygon2D.new()
	spark.position = to_pos
	spark.color = Color(0.82, 0.98, 1.0, 0.65)
	spark.polygon = _blast_circle_points(7.0 + float(jump_index) * 0.8, 12)
	spark.material = _make_additive_material()
	fx.add_child(spark)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.0, 0.18)
	tween.tween_property(core, "modulate:a", 0.0, 0.14)
	tween.tween_property(spark, "modulate:a", 0.0, 0.16)
	tween.tween_property(spark, "scale", Vector2(1.8, 1.8), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fx.queue_free).set_delay(0.2)


func _blast_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var ang := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	return pts


func _blast_star_points(radius: float, segments: int, inner_ratio: float = 0.42) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments * 2):
		var ang := TAU * float(i) / float(segments * 2)
		var r := radius if i % 2 == 0 else radius * inner_ratio
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	return pts


func _spawn_blast_visual(origin: Vector2, radius: float, archetype: String) -> void:
	if radius <= 0.0:
		return
	var fx := Node2D.new()
	fx.set_meta("is_blast_fx", true)
	fx.global_position = origin
	fx.z_index = 6
	add_child(fx)

	var glow_c := _weapon_glow_color(archetype)
	var ring_color := Color(glow_c.r, glow_c.g, glow_c.b, min(1.0, glow_c.a + 0.38))
	var core_c := _weapon_core_color(archetype)
	var fill_c := Color(core_c.r, core_c.g, core_c.b, 0.22)

	var fill := Polygon2D.new()
	fill.polygon = _blast_star_points(radius * 0.9, 6, 0.38) if archetype == "starbreaker" else _blast_circle_points(radius * 0.9, 36)
	fill.color = fill_c
	fill.material = _make_additive_material()
	fx.add_child(fill)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.8 if archetype == "starbreaker" else 3.8
	ring.default_color = ring_color
	ring.points = _blast_star_points(radius, 6, 0.45) if archetype == "starbreaker" else _blast_circle_points(radius, 44)
	ring.antialiased = true
	ring.material = _make_additive_material()
	fx.add_child(ring)

	var ring_inner := Line2D.new()
	ring_inner.closed = true
	ring_inner.width = 2.0
	ring_inner.default_color = Color(
		clampf(ring_color.r * 1.08, 0.0, 1.0),
		clampf(ring_color.g * 1.04, 0.0, 1.0),
		clampf(ring_color.b * 1.02, 0.0, 1.0),
		ring_color.a * 0.55
	)
	ring_inner.points = _blast_star_points(radius * 0.74, 6, 0.55) if archetype == "starbreaker" else _blast_circle_points(radius * 0.74, 32)
	ring_inner.antialiased = true
	ring_inner.material = _make_additive_material()
	fx.add_child(ring_inner)

	fill.scale = Vector2(0.1, 0.1)
	ring.scale = Vector2(0.14, 0.14)
	ring_inner.scale = Vector2(0.16, 0.16)

	var dur := 0.44 if archetype == "starbreaker" else 0.32
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fill, "scale", Vector2(1.0, 1.0), dur * 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.03, 1.03), dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_inner, "scale", Vector2(1.0, 1.0), dur * 0.92).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "modulate:a", 0.0, dur * 0.88).set_delay(0.03)
	tween.tween_property(ring, "modulate:a", 0.0, dur).set_delay(0.05)
	tween.tween_property(ring_inner, "modulate:a", 0.0, dur * 0.9).set_delay(0.07)
	tween.tween_property(ring, "width", 0.5, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(fx.queue_free).set_delay(dur + 0.1)


func _spawn_hit_spark(origin: Vector2, archetype: String, strength: float = 1.0) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.z_index = 8
	add_child(fx)

	var color := _weapon_trail_color(archetype)
	for i in range(14):
		var ray := Line2D.new()
		var angle := TAU * float(i) / 14.0 + randf_range(-0.22, 0.22)
		var ray_len := randf_range(10.0, 34.0) * strength
		ray.width = randf_range(1.0, 3.2) * strength
		ray.default_color = Color(color.r, color.g, color.b, minf(1.0, color.a + 0.22))
		ray.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * ray_len])
		ray.antialiased = true
		ray.material = _make_additive_material()
		fx.add_child(ray)

	for i in range(8):
		var chip := Polygon2D.new()
		var chip_angle := randf() * TAU
		chip.position = Vector2.from_angle(chip_angle) * randf_range(4.0, 16.0) * strength
		chip.rotation = chip_angle
		chip.color = Color(color.r, color.g, color.b, 0.72)
		chip.polygon = PackedVector2Array([Vector2(0, -3), Vector2(2, 2), Vector2(-2, 2)])
		chip.material = _make_additive_material()
		fx.add_child(chip)

	var core := Polygon2D.new()
	core.color = Color(color.r, color.g, color.b, 0.42)
	core.polygon = _blast_circle_points(9.0 * strength, 14)
	core.material = _make_additive_material()
	fx.add_child(core)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, 0.26)
	tween.tween_property(fx, "scale", Vector2(2.1, 2.1), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fx.queue_free).set_delay(0.28)


func _spawn_special_burst(origin: Vector2, color: Color, radius: float, duration: float = 0.24, rays: int = 8) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.z_index = 9
	add_child(fx)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 3.0
	ring.default_color = color
	ring.points = _blast_circle_points(radius, 22)
	ring.antialiased = true
	ring.material = _make_additive_material()
	fx.add_child(ring)

	for i in range(rays):
		var ray := Line2D.new()
		var angle := TAU * float(i) / float(maxi(1, rays))
		ray.width = 1.8
		ray.default_color = Color(color.r, color.g, color.b, color.a * 0.86)
		ray.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * radius * 0.95])
		ray.antialiased = true
		ray.material = _make_additive_material()
		fx.add_child(ray)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, duration)
	tween.tween_property(fx, "scale", Vector2(1.8, 1.8), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "width", 0.4, duration)
	tween.tween_callback(fx.queue_free).set_delay(duration + 0.04)


func _spawn_damage_zone_visual(origin: Vector2, radius: float, color: Color, duration: float = 0.72) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.z_index = 5
	add_child(fx)

	var fill := Polygon2D.new()
	fill.color = Color(color.r, color.g, color.b, 0.13)
	fill.polygon = _blast_circle_points(radius, 40)
	fill.material = _make_additive_material()
	fx.add_child(fill)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 2.6
	ring.default_color = Color(color.r, color.g, color.b, 0.82)
	ring.points = _blast_circle_points(radius, 48)
	ring.antialiased = true
	ring.material = _make_additive_material()
	fx.add_child(ring)

	var inner := Line2D.new()
	inner.closed = true
	inner.width = 1.2
	inner.default_color = Color(1.0, 1.0, 1.0, 0.42)
	inner.points = _blast_circle_points(radius * 0.58, 32)
	inner.antialiased = true
	inner.material = _make_additive_material()
	fx.add_child(inner)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fill, "modulate:a", 0.0, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_property(inner, "modulate:a", 0.0, duration * 0.8)
	tween.tween_property(ring, "scale", Vector2(1.08, 1.08), duration)
	tween.tween_callback(fx.queue_free).set_delay(duration + 0.05)


func _spawn_pull_visual(origin: Vector2, radius: float, color: Color) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.z_index = 8
	add_child(fx)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 2.4
	ring.default_color = color
	ring.points = _blast_circle_points(radius, 42)
	ring.antialiased = true
	ring.material = _make_additive_material()
	fx.add_child(ring)

	for i in range(8):
		var spoke := Line2D.new()
		var dir := Vector2.from_angle(TAU * float(i) / 8.0)
		spoke.width = 1.5
		spoke.default_color = Color(color.r, color.g, color.b, color.a * 0.72)
		spoke.points = PackedVector2Array([dir * radius, dir * radius * 0.42])
		spoke.antialiased = true
		spoke.material = _make_additive_material()
		fx.add_child(spoke)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, 0.22)
	tween.tween_property(fx, "rotation", PI * 0.18, 0.22)
	tween.tween_property(fx, "scale", Vector2(0.76, 0.76), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(fx.queue_free).set_delay(0.25)


func _spawn_muzzle_flash(origin: Vector2, direction: Vector2, archetype: String) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.rotation = direction.angle()
	fx.z_index = 6
	add_child(fx)

	var color := _weapon_trail_color(archetype)
	var flare := Line2D.new()
	flare.width = 7.0 if archetype != "rail" else 13.0
	flare.default_color = Color(color.r, color.g, color.b, 0.82)
	flare.points = PackedVector2Array([Vector2(-6, 0), Vector2(18, 0), Vector2(5, 0)])
	flare.antialiased = true
	flare.material = _make_additive_material()
	fx.add_child(flare)

	var burst := Polygon2D.new()
	burst.color = Color(color.r, color.g, color.b, 0.34)
	burst.polygon = PackedVector2Array([Vector2(0, -10), Vector2(22, 0), Vector2(0, 10), Vector2(6, 0)])
	burst.material = _make_additive_material()
	fx.add_child(burst)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "modulate:a", 0.0, 0.14)
	tween.tween_property(fx, "scale", Vector2(1.9, 1.9), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fx.queue_free).set_delay(0.16)


func _spawn_rail_lance(origin: Vector2, direction: Vector2, beam_len: float = 420.0, glow_color: Color = Color(0.08, 0.92, 1.0, 0.5), core_color: Color = Color(0.94, 1.0, 1.0, 1.0), glow_width: float = 18.0) -> void:
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = origin
	fx.z_index = 7
	add_child(fx)

	var beam_dir := direction.normalized()
	var side := Vector2(-beam_dir.y, beam_dir.x)
	var start := beam_dir * 16.0
	var end := beam_dir * beam_len
	var glow := Line2D.new()
	glow.width = glow_width
	glow.default_color = glow_color
	glow.points = PackedVector2Array([start - side * 1.5, end + side * 1.5])
	glow.antialiased = true
	glow.material = _make_additive_material()
	fx.add_child(glow)

	var core := Line2D.new()
	core.width = 3.2
	core.default_color = core_color
	core.points = PackedVector2Array([start, end])
	core.antialiased = true
	fx.add_child(core)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.0, 0.16)
	tween.tween_property(core, "modulate:a", 0.0, 0.11)
	tween.tween_property(glow, "width", 3.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fx.queue_free).set_delay(0.18)


func _spawn_rail_damage_trace(origin: Vector2, direction: Vector2, trace_len: float, trace_width: float, tick_damage: float) -> void:
	var trace_dir := direction.normalized()
	if trace_dir == Vector2.ZERO:
		trace_dir = Vector2.RIGHT
	var side := Vector2(-trace_dir.y, trace_dir.x)
	var start := origin + trace_dir * 24.0
	var end := origin + trace_dir * trace_len
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = Vector2.ZERO
	fx.z_index = 6
	add_child(fx)

	var glow := Line2D.new()
	glow.width = trace_width
	glow.default_color = Color(0.92, 0.16, 1.0, 0.34)
	glow.points = PackedVector2Array([start - side * 2.0, end + side * 2.0])
	glow.antialiased = true
	glow.material = _make_additive_material()
	fx.add_child(glow)

	var core := Line2D.new()
	core.width = 4.5
	core.default_color = Color(1.0, 0.72, 1.0, 0.9)
	core.points = PackedVector2Array([start, end])
	core.antialiased = true
	core.material = _make_additive_material()
	fx.add_child(core)

	var scan := Line2D.new()
	scan.width = 1.6
	scan.default_color = Color(1.0, 1.0, 1.0, 0.82)
	scan.points = PackedVector2Array([start + side * 9.0, end + side * 9.0])
	scan.antialiased = true
	scan.material = _make_additive_material()
	fx.add_child(scan)

	rail_traces.append({
		"origin": origin,
		"dir": trace_dir,
		"length": trace_len,
		"width": trace_width,
		"damage": tick_damage,
		"time": 1.15,
		"tick": 0.0
	})

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(glow, "modulate:a", 0.0, 1.15)
	tween.tween_property(core, "modulate:a", 0.0, 0.9).set_delay(0.12)
	tween.tween_property(scan, "modulate:a", 0.0, 0.45)
	tween.tween_property(glow, "width", 5.0, 1.15)
	tween.tween_callback(fx.queue_free).set_delay(1.2)


func _update_rail_traces(delta: float) -> void:
	for i in range(rail_traces.size() - 1, -1, -1):
		var trace := rail_traces[i]
		var time_left := float(trace.get("time", 0.0)) - delta
		if time_left <= 0.0:
			rail_traces.remove_at(i)
			continue
		trace["time"] = time_left
		var tick_left := float(trace.get("tick", 0.0)) - delta
		if tick_left > 0.0:
			trace["tick"] = tick_left
			rail_traces[i] = trace
			continue
		trace["tick"] = 0.18
		var origin: Vector2 = trace.get("origin", Vector2.ZERO)
		var trace_dir: Vector2 = trace.get("dir", Vector2.RIGHT)
		var trace_len := float(trace.get("length", 0.0))
		var trace_width := float(trace.get("width", 0.0))
		var tick_damage := float(trace.get("damage", 0.0))
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var rel := enemy.global_position - origin
			var along := rel.dot(trace_dir)
			if along < 0.0 or along > trace_len:
				continue
			var closest := origin + trace_dir * along
			if enemy.global_position.distance_to(closest) > trace_width:
				continue
			_apply_on_damage_dealt(_damage_enemy(enemy, tick_damage))
			_spawn_special_burst(enemy.global_position, Color(1.0, 0.38, 1.0, 0.7), 14.0, 0.16, 5)
		rail_traces[i] = trace


func _add_blast_projectile_rings(projectile: Node2D, archetype: String) -> void:
	var color := _weapon_trail_color(archetype)
	var outer := Line2D.new()
	outer.name = "BlastArmingRing"
	outer.closed = true
	outer.width = 2.0 if archetype != "starbreaker" else 2.8
	outer.default_color = Color(color.r, color.g, color.b, 0.74)
	outer.points = _blast_star_points(17.0, 6, 0.48) if archetype == "starbreaker" else _blast_circle_points(12.0, 24)
	outer.antialiased = true
	outer.material = _make_additive_material()
	projectile.add_child(outer)
	projectile.set_meta("arming_ring", outer)


func _spawn_enemy_death_burst(enemy: Node2D) -> void:
	var outline := enemy.get_node_or_null("Outline") as Line2D
	var color := Color(1.0, 0.35, 0.9, 0.86)
	if outline != null:
		color = outline.default_color
	var fx := Node2D.new()
	fx.set_meta("is_temp_fx", true)
	fx.global_position = enemy.global_position
	fx.rotation = enemy.rotation
	fx.z_index = 7
	add_child(fx)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.4
	ring.default_color = Color(color.r, color.g, color.b, 0.86)
	ring.points = _blast_circle_points(18.0, 32)
	ring.antialiased = true
	ring.material = _make_additive_material()
	fx.add_child(ring)

	var shock := Line2D.new()
	shock.closed = true
	shock.width = 2.0
	shock.default_color = Color(1.0, 1.0, 1.0, 0.72)
	shock.points = _blast_circle_points(10.0, 18)
	shock.antialiased = true
	shock.material = _make_additive_material()
	fx.add_child(shock)

	for i in range(26):
		var shard := Line2D.new()
		var angle := TAU * float(i) / 26.0 + randf_range(-0.18, 0.18)
		shard.width = randf_range(1.0, 3.0)
		shard.default_color = Color(color.r, color.g, color.b, 0.72)
		shard.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * randf_range(24.0, 62.0)])
		shard.antialiased = true
		shard.material = _make_additive_material()
		fx.add_child(shard)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.9, 2.9), 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(shock, "scale", Vector2(4.2, 4.2), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(fx, "modulate:a", 0.0, 0.42)
	tween.tween_callback(fx.queue_free).set_delay(0.46)


func _apply_explosion(origin: Vector2, radius: float, damage: float, poison_dps: float, poison_time: float, archetype: String) -> void:
	if radius <= 0.0:
		return
	_spawn_blast_visual(origin, radius, archetype)
	var field_power := _upgrade_value("afterburn_field") + _upgrade_value("field_amplifier") + _upgrade_value("plasma_scorch") + _upgrade_value("mycelium_zone")
	if field_power > 0.0:
		var zone_color := _weapon_trail_color(archetype)
		_spawn_damage_zone_visual(origin, radius * (1.0 + minf(0.35, field_power * 0.04)), Color(zone_color.r, zone_color.g, zone_color.b, 0.82))
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = enemy.global_position.distance_to(origin)
		if dist > radius:
			continue
		var falloff: float = 1.0 - (dist / radius)
		var dealt: float = _damage_enemy(enemy, _modified_hit_damage(enemy, max(1.0, damage * (0.5 + falloff * 0.5)), "explosion"))
		_apply_on_damage_dealt(dealt)
		if poison_dps > 0.0 and poison_time > 0.0:
			_apply_poison(enemy, poison_dps * 0.7, poison_time)
		if field_power > 0.0:
			_apply_on_damage_dealt(_damage_enemy(enemy, max(0.4, damage * 0.04 * field_power)))


func _apply_poison(enemy: Node2D, dps: float, duration: float) -> void:
	enemy.set_meta("poison_dps", max(float(enemy.get_meta("poison_dps", 0.0)), dps))
	enemy.set_meta("poison_time", max(float(enemy.get_meta("poison_time", 0.0)), duration))
	if randf() < 0.32:
		_spawn_special_burst(enemy.global_position, Color(0.46, 1.0, 0.28, 0.68), 13.0, 0.2, 5)


func _modified_hit_damage(enemy: Node2D, base_damage: float, behavior: String) -> float:
	var result := base_damage
	var health := float(enemy.get_meta("health", 1.0))
	var max_health := maxf(1.0, float(enemy.get_meta("max_health", health)))
	if _upgrade_value("execution_voltage") > 0.0 and health <= max_health * 0.3:
		result *= 1.0 + _upgrade_value("execution_voltage") * 0.08
		_spawn_special_burst(enemy.global_position, Color(0.35, 0.92, 1.0, 0.86), 18.0, 0.18, 7)
	if _upgrade_value("critical_capacitor") > 0.0 and randf() < minf(0.45, _upgrade_value("critical_capacitor") * 0.035):
		result *= 1.85
		_spawn_special_burst(enemy.global_position, Color(1.0, 0.9, 0.24, 0.95), 28.0, 0.22, 10)
	if behavior == "twin_fang" and _upgrade_value("fang_convergence") > 0.0:
		var last_hit := float(enemy.get_meta("fang_hit_time", -99.0))
		if survival_time - last_hit <= 0.28:
			result *= 1.0 + _upgrade_value("fang_convergence") * 0.18
			_spawn_special_burst(enemy.global_position, Color(1.0, 0.24, 0.48, 0.9), 22.0, 0.2, 8)
		enemy.set_meta("fang_hit_time", survival_time)
	if behavior == "pulse" and _upgrade_value("pulse_overclock") > 0.0:
		if randi() % maxi(2, 6 - _upgrade_int("pulse_overclock")) == 0:
			result *= 1.75
			_spawn_special_burst(enemy.global_position, Color(0.28, 1.0, 0.9, 0.9), 24.0, 0.2, 9)
	return result


func _apply_on_damage_dealt(amount: float) -> void:
	if amount <= 0.0:
		return
	if _upgrade_value("siphon_matrix") > 0.0:
		player_hp = min(player_max_hp, player_hp + amount * 0.004 * _upgrade_value("siphon_matrix"))


func _splash_poison(origin: Vector2, dps: float, duration: float, radius: float, ignore_enemy: Node2D = null) -> void:
	var spread_count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == ignore_enemy:
			continue
		if enemy.global_position.distance_to(origin) > radius:
			continue
		_apply_poison(enemy, dps, duration)
		spread_count += 1
	if spread_count > 0:
		_spawn_damage_zone_visual(origin, radius, Color(0.5, 1.0, 0.24, 0.78), 0.48)


func _spawn_spore_mote(origin: Vector2, archetype: String) -> void:
	var mote := Polygon2D.new()
	mote.set_meta("is_temp_fx", true)
	mote.global_position = origin + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 16.0)
	mote.z_index = 5
	var color := _weapon_trail_color(archetype)
	mote.color = Color(color.r, color.g, color.b, 0.28)
	mote.polygon = _blast_circle_points(randf_range(3.0, 7.0), 8)
	mote.material = _make_additive_material()
	add_child(mote)
	var drift := Vector2.from_angle(randf() * TAU) * randf_range(10.0, 26.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mote, "global_position", mote.global_position + drift, 0.42)
	tween.tween_property(mote, "scale", Vector2(1.8, 1.8), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mote, "modulate:a", 0.0, 0.42)
	tween.tween_callback(mote.queue_free).set_delay(0.45)


func _tick_enemy_effects(enemy: Node2D, delta: float) -> void:
	var poison_time := float(enemy.get_meta("poison_time", 0.0))
	if poison_time <= 0.0:
		return
	var poison_dps := float(enemy.get_meta("poison_dps", 0.0))
	poison_time = max(0.0, poison_time - delta)
	enemy.set_meta("poison_time", poison_time)
	if poison_dps <= 0.0:
		return
	_damage_enemy(enemy, poison_dps * delta)


func _damage_enemy(enemy: Node2D, damage: float) -> float:
	if not is_instance_valid(enemy):
		return 0.0
	var old_health := float(enemy.get_meta("health", 1.0))
	var health: float = max(0.0, old_health - damage)
	var dealt := maxf(0.0, old_health - health)
	enemy.set_meta("health", health)
	_emit_enemy_health_changed(enemy)
	if health <= 0.0:
		if _upgrade_value("status_spread") > 0.0 or _upgrade_value("viral_cascade") > 0.0:
			var poison_dps := float(enemy.get_meta("poison_dps", 0.0)) * (0.45 + _upgrade_value("viral_cascade") * 0.15)
			if poison_dps > 0.0:
				_splash_poison(enemy.global_position, poison_dps, 1.4 + _upgrade_value("status_spread") * 0.2, 88.0, enemy)
		if _upgrade_value("shield_converter") > 0.0:
			shield_hp = min(shield_max, shield_hp + dealt * 0.015 * _upgrade_value("shield_converter"))
		if _upgrade_value("reload_feedback") > 0.0 and reload_feedback_timer <= 0.0:
			auto_fire_timer = maxf(0.0, auto_fire_timer - 0.035 * _upgrade_value("reload_feedback"))
			reload_feedback_timer = 2.0
			_spawn_special_burst(enemy.global_position, Color(0.45, 1.0, 0.78, 0.86), 24.0, 0.22, 8)
		_spawn_enemy_death_burst(enemy)
		score += int(enemy.get_meta("score_value", 10))
		_gain_xp(10.0 + float(wave_index) * 2.0)
		var idx := enemies.find(enemy)
		if idx >= 0:
			enemies.remove_at(idx)
		enemy.queue_free()
	return dealt


func _check_player_collisions(_delta: float) -> void:
	if invuln_timer > 0.0:
		return
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if float(enemy.get_meta("spawn_delay", 0.0)) > 0.0:
			continue
		var dist := enemy.global_position.distance_to(player.global_position)
		if dist <= PLAYER_COLLISION_RADIUS + ENEMY_COLLISION_RADIUS:
			var touch_cd := float(enemy.get_meta("touch_cooldown", 0.0))
			if touch_cd > 0.0:
				continue
			var touch_damage := float(enemy.get_meta("touch_damage", 10.0))
			_apply_player_damage(touch_damage, enemy)
			invuln_timer = 0.35
			enemy.set_meta("touch_cooldown", 0.6)
			if player_hp <= 0.0:
				game_over = true
			break


func _gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		level_up_pending += 1
		xp_to_next = _xp_required(level)
	if level_up_pending > 0 and not upgrade_panel.visible:
		_open_upgrade_panel()


func _apply_player_damage(amount: float, source_enemy: Node2D) -> void:
	var dmg: float = amount
	if shield_trait == "flat_reduce":
		dmg = max(1.0, dmg - 2.5)
	if shield_trait == "evade" and randf() < 0.18:
		dmg = 0.0
	if shield_trait == "burst_absorb":
		dmg *= 0.82
	if shield_trait == "split":
		dmg *= 0.9

	var remaining: float = dmg
	if shield_hp > 0.0:
		var absorbed: float = min(shield_hp, remaining)
		shield_hp -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		player_hp = max(0.0, player_hp - remaining)

	shield_regen_lock_timer = shield_regen_delay
	if shield_trait == "reflect" and is_instance_valid(source_enemy):
		_damage_enemy(source_enemy, dmg * 0.35)
	if shield_trait == "shock" and is_instance_valid(source_enemy):
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if enemy.global_position.distance_to(player.global_position) <= 90.0:
				_damage_enemy(enemy, 4.5)


func _tick_player_regen(delta: float) -> void:
	player_hp = min(player_max_hp, player_hp + player_hp_regen * delta)
	if shield_regen_lock_timer <= 0.0:
		shield_hp = min(shield_max, shield_hp + shield_regen * delta)


func _xp_required(target_level: int) -> float:
	var l := float(target_level - 1)
	var required := 30.0 + l * 18.0 + pow(l, 1.45) * 4.5
	if target_level > 30:
		var late := float(target_level - 30)
		required += late * late * 32.0 + late * 120.0
	return round(required * _xp_slowdown_multiplier(target_level))


func _xp_slowdown_multiplier(target_level: int) -> float:
	if target_level <= 1:
		return 1.0
	if target_level <= 10:
		return lerpf(1.0, 10.0, float(target_level - 1) / 9.0)
	if target_level <= 20:
		return lerpf(10.0, 20.0, float(target_level - 10) / 10.0)
	if target_level <= 30:
		return lerpf(20.0, 30.0, float(target_level - 20) / 10.0)
	return 30.0


func _upgrade_value(key: String) -> float:
	return float(upgrade_power.get(key, 0.0))


func _upgrade_int(key: String) -> int:
	return maxi(0, int(round(_upgrade_value(key))))


func _roll_upgrade_tier() -> String:
	var roll := randf()
	if roll < 0.01:
		return "epic"
	if roll < 0.06:
		return "rare"
	if roll < 0.36:
		return "uncommon"
	return "common"


func _tier_multiplier(tier: String) -> float:
	match tier:
		"uncommon":
			return 1.2
		"rare":
			return 1.5
		"epic":
			return 3.0
		_:
			return 1.0


func _tier_label(tier: String) -> String:
	match tier:
		"uncommon":
			return "UNCOMMON "
		"rare":
			return "RARE "
		"epic":
			return "EPIC "
		_:
			return ""


func _weapon_specific_key(weapon: Dictionary) -> String:
	match String(weapon.get("behavior", "")):
		"pulse":
			return "pulse_overclock"
		"twin_fang":
			return "fang_convergence"
		"rail":
			return "rail_afterimage"
		"lightning":
			return "forked_arc"
		"mortar":
			return "plasma_scorch"
		"starbreaker":
			return "stellar_fragments"
		"shrapnel":
			return "vortex_teeth"
		"toxic":
			return "viral_cascade"
		"ricochet":
			return "saw_acceleration"
		"spore":
			return "mycelium_zone"
		"photon":
			return "prism_edge"
		"void":
			return "singularity_echo"
		_:
			return ""


func _is_weapon_specific_key(key: String) -> bool:
	return key in ["pulse_overclock", "fang_convergence", "rail_afterimage", "forked_arc", "plasma_scorch", "stellar_fragments", "vortex_teeth", "viral_cascade", "saw_acceleration", "mycelium_zone", "prism_edge", "singularity_echo"]


func _is_weapon_specific_upgrade(key: String, weapon: Dictionary) -> bool:
	return key == _weapon_specific_key(weapon)


func _is_upgrade_compatible(key: String, weapon: Dictionary) -> bool:
	var behavior := String(weapon.get("behavior", ""))
	var explosive := _is_blast_behavior(behavior)
	var projectile := behavior != "lightning" and behavior != "rail"
	if _is_weapon_specific_key(key):
		return _is_weapon_specific_upgrade(key, weapon)
	match key:
		"blast", "afterburn_field", "field_amplifier":
			return explosive
		"pierce", "bounce", "split":
			return projectile and not explosive
		"velocity", "ion_trails":
			return projectile
		"chain":
			return behavior == "lightning" or behavior == "void"
		"impact_bloom":
			return not explosive and behavior != "lightning"
		"multishot":
			return behavior != "lightning" and behavior != "rail"
		_:
			return true


func _compatible_upgrade_pool(weapon: Dictionary) -> Array[String]:
	var pool: Array[String] = []
	for key in UPGRADE_POOL:
		var upgrade_key := String(key)
		if _is_upgrade_compatible(upgrade_key, weapon):
			pool.append(upgrade_key)
	return pool


func _weighted_upgrade_pick(pool: Array[String], weapon: Dictionary) -> String:
	if pool.is_empty():
		return ""
	var total := 0.0
	for key in pool:
		total += 1.2 if _is_weapon_specific_upgrade(key, weapon) else 1.0
	var roll := randf() * total
	for key in pool:
		roll -= 1.2 if _is_weapon_specific_upgrade(key, weapon) else 1.0
		if roll <= 0.0:
			return key
	return pool[pool.size() - 1]


func _open_upgrade_panel() -> void:
	offered_upgrades.clear()
	offered_upgrade_tiers.clear()
	var weapon: Dictionary = weapon_defs[selected_weapon_id]
	var pool := _compatible_upgrade_pool(weapon)
	for i in range(3):
		var key := _weighted_upgrade_pick(pool, weapon)
		if key == "":
			for fallback_key in UPGRADE_POOL:
				var fallback := String(fallback_key)
				if not offered_upgrades.has(fallback) and _is_upgrade_compatible(fallback, weapon):
					key = fallback
					break
		if key == "":
			break
		pool.erase(key)
		var tier := _roll_upgrade_tier()
		offered_upgrades.append(key)
		offered_upgrade_tiers.append(tier)
		var next_level := int(upgrade_levels[key]) + 1
		upgrade_buttons[i].text = "[%d] %s%s %s\n%s" % [i + 1, _tier_label(tier), UPGRADE_NAMES[key], _to_roman(next_level), _upgrade_effect_text(key, _tier_multiplier(tier))]
		upgrade_buttons[i].tooltip_text = "Upgrade %s to level %d (%s)" % [UPGRADE_NAMES[key], next_level, tier]
		_style_upgrade_button(upgrade_buttons[i], tier, _is_weapon_specific_upgrade(key, weapon))
		upgrade_buttons[i].visible = true
	for i in range(offered_upgrades.size(), upgrade_buttons.size()):
		upgrade_buttons[i].visible = false
	upgrade_panel.visible = true
	_layout_side_panel()


func _upgrade_effect_text(key: String, tier_mult: float = 1.0) -> String:
	var effect_text := ""
	match key:
		"pierce":
			effect_text = "+%d pierce" % maxi(1, int(round(tier_mult)))
		"bounce":
			effect_text = "+%d bounce" % maxi(1, int(round(tier_mult)))
		"chain":
			effect_text = "+%d chain jump" % maxi(1, int(round(tier_mult)))
		"multishot":
			effect_text = "+%d projectile, +spread" % maxi(1, int(round(tier_mult)))
		"split":
			effect_text = "splits on hit"
		"targeting":
			effect_text = "+%d target radius" % int(round(120.0 * tier_mult))
		"velocity":
			effect_text = "+%d%% projectile speed" % int(round(12.0 * tier_mult))
		"overload":
			effect_text = "+%d%% faster cooldown" % int(round(7.0 * tier_mult))
		"blast":
			effect_text = "+%d%% blast radius" % int(round(18.0 * tier_mult))
		"attack_speed":
			effect_text = "+%d%% fire rate" % int(round(6.0 * tier_mult))
		"damage":
			effect_text = "+%d%% weapon damage" % int(round(12.0 * tier_mult))
		"impact_bloom":
			effect_text = "hits burst in small AoE"
		"corrosion_payload":
			effect_text = "hits add damage over time"
		"afterburn_field":
			effect_text = "explosions burn after hit"
		"ion_trails":
			effect_text = "bullet trails deal damage"
		"siphon_matrix":
			effect_text = "heal from damage dealt"
		"execution_voltage":
			effect_text = "bonus vs low-health foes"
		"critical_capacitor":
			effect_text = "chance for critical hits"
		"field_amplifier":
			effect_text = "stronger blast fields"
		"status_spread":
			effect_text = "status spreads on kills"
		"shield_converter":
			effect_text = "kills restore shield"
		"reload_feedback":
			effect_text = "kills reduce cooldown, 2s cap"
		"gravity_well":
			effect_text = "hits pull nearby enemies"
		"pulse_overclock":
			effect_text = "some pulse shots hit harder"
		"fang_convergence":
			effect_text = "paired fang hits combo"
		"rail_afterimage":
			effect_text = "rail leaves damage trace"
		"forked_arc":
			effect_text = "lightning starts extra arcs"
		"plasma_scorch":
			effect_text = "mortar blasts scorch harder"
		"stellar_fragments":
			effect_text = "warhead fires star shards"
		"vortex_teeth":
			effect_text = "shrapnel trails cut enemies"
		"viral_cascade":
			effect_text = "poison kills spread infection"
		"saw_acceleration":
			effect_text = "disk gains damage on bounce"
		"mycelium_zone":
			effect_text = "spore clouds grow stronger"
		"prism_edge":
			effect_text = "photon blades add burn"
		"singularity_echo":
			effect_text = "void pull deals tick damage"
		_:
			effect_text = "stat upgrade"
	if tier_mult > 1.0:
		effect_text += " (x%.1f effect)" % tier_mult
	return effect_text


func _on_upgrade_pressed(index: int) -> void:
	if index < 0 or index >= offered_upgrades.size():
		return
	var key := offered_upgrades[index]
	var tier := "common"
	if index < offered_upgrade_tiers.size():
		tier = offered_upgrade_tiers[index]
	upgrade_levels[key] = int(upgrade_levels[key]) + 1
	upgrade_power[key] = float(upgrade_power.get(key, 0.0)) + _tier_multiplier(tier)
	level_up_pending = max(0, level_up_pending - 1)
	player_max_hp += 6.0
	player_hp = min(player_max_hp, player_hp + 12.0)
	if level_up_pending > 0:
		_open_upgrade_panel()
	else:
		upgrade_panel.visible = false
		_layout_side_panel()


func _on_start_run_pressed() -> void:
	run_started = true
	loadout_panel.visible = false
	weapon_panel.visible = false
	shield_panel.visible = false
	loadout_info.text = ""


func _emit_enemy_health_changed(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	var current_health := float(enemy.get_meta("health", 0.0))
	var max_health: float = max(1.0, float(enemy.get_meta("max_health", 1.0)))
	enemy_health_changed.emit(enemy, current_health, max_health)
	if enemy.has_method("update_health_bar"):
		enemy.call("update_health_bar", current_health, max_health)


func _get_nearest_enemy(origin: Vector2, max_distance: float, ignore_enemy: Node2D = null) -> Node2D:
	var nearest: Node2D = null
	var best_dist_sq := max_distance * max_distance
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == ignore_enemy:
			continue
		if float(enemy.get_meta("spawn_delay", 0.0)) > 0.0:
			continue
		var d2 := enemy.global_position.distance_squared_to(origin)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			nearest = enemy
	return nearest


func _first_hit_enemy(point: Vector2, radius: float) -> Node2D:
	var radius_sq := radius * radius
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if float(enemy.get_meta("spawn_delay", 0.0)) > 0.0:
			continue
		if enemy.global_position.distance_squared_to(point) <= radius_sq:
			return enemy
	return null


func _destroy_bullet(index: int) -> void:
	var bullet: Node2D = bullets[index]
	bullets.remove_at(index)
	if is_instance_valid(bullet):
		bullet.queue_free()


func _random_edge_position() -> Vector2:
	var side := randi() % 4
	var spawn_margin := 160.0
	var view_half := _camera_visible_half_size()
	var min_x := maxf(-ARENA_HALF_SIZE.x, player.global_position.x - view_half.x - spawn_margin)
	var max_x := minf(ARENA_HALF_SIZE.x, player.global_position.x + view_half.x + spawn_margin)
	var min_y := maxf(-ARENA_HALF_SIZE.y, player.global_position.y - view_half.y - spawn_margin)
	var max_y := minf(ARENA_HALF_SIZE.y, player.global_position.y + view_half.y + spawn_margin)
	match side:
		0:
			return Vector2(randf_range(min_x, max_x), min_y)
		1:
			return Vector2(randf_range(min_x, max_x), max_y)
		2:
			return Vector2(min_x, randf_range(min_y, max_y))
		_:
			return Vector2(max_x, randf_range(min_y, max_y))


func _camera_visible_half_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var zoom_value := CAMERA_START_ZOOM
	if camera != null:
		zoom_value = maxf(0.05, camera.zoom.x)
	return viewport_size * 0.5 / zoom_value


func _axis_strength(actions: Array[String], keys: Array[int]) -> float:
	for action in actions:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return 1.0
	for key in keys:
		if Input.is_physical_key_pressed(key):
			return 1.0
	return 0.0


func _clamp_inside_arena(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, -ARENA_HALF_SIZE.x, ARENA_HALF_SIZE.x), clampf(p.y, -ARENA_HALF_SIZE.y, ARENA_HALF_SIZE.y))


func _is_inside_arena(p: Vector2, margin: float = 0.0) -> bool:
	return p.x >= -ARENA_HALF_SIZE.x - margin and p.x <= ARENA_HALF_SIZE.x + margin and p.y >= -ARENA_HALF_SIZE.y - margin and p.y <= ARENA_HALF_SIZE.y + margin


func _refresh_ui() -> void:
	_layout_side_panel()
	hp_bar.max_value = player_max_hp
	hp_bar.value = player_hp
	shield_bar.max_value = shield_max
	shield_bar.value = shield_hp
	xp_bar.max_value = xp_to_next
	xp_bar.value = xp
	xp_bar.tooltip_text = "XP %.0f / %.0f" % [xp, xp_to_next]

	var weapon: Dictionary = weapon_defs[selected_weapon_id]
	var base_cd: float = float(weapon.get("cooldown", 0.4))
	var effective_cd: float = base_cd * (1.0 - minf(0.55, float(upgrade_levels["attack_speed"]) * 0.06))
	effective_cd *= (1.0 - minf(0.45, float(upgrade_levels["overload"]) * 0.07))
	if shield_trait == "overcharge" and shield_hp >= shield_max * 0.95:
		effective_cd *= 0.82
	var projectile_count: int = int(weapon.get("projectiles", 1)) + int(upgrade_levels["multishot"])
	var pierce_count: int = int(weapon.get("base_pierce", 0)) + int(upgrade_levels["pierce"])
	var bounce_count: int = int(weapon.get("base_bounce", 0)) + int(upgrade_levels["bounce"])
	var chain_count: int = int(weapon.get("chain_jumps", 0)) + int(upgrade_levels["chain"])
	var target_radius: float = AUTO_TARGET_RADIUS + float(upgrade_levels["targeting"]) * 120.0
	var velocity_mult: float = 1.0 + float(upgrade_levels["velocity"]) * 0.12
	var blast_radius: float = float(weapon.get("blast_radius", 0.0)) * (1.0 + float(upgrade_levels["blast"]) * 0.18)
	var fire_rate: float = 0.0
	if effective_cd > 0.0:
		fire_rate = 1.0 / effective_cd
	var enemy_level_mult := _enemy_level_multiplier()
	var active_cap := int(round((125.0 + _zoom_out_progress() * 260.0) * enemy_level_mult)) + mini(_late_game_level(), 20) * 3
	if not run_started:
		score_label.text = "SELECT LOADOUT"
	else:
		score_label.text = "RUN\nScore %d\nWave %d  Level %d\nTime %.1fs  View %.1fx" % [
			score,
			wave_index + 1,
			level,
			survival_time,
			_current_zoom_out_factor()
		]
	time_label.text = "SURVIVAL\nHULL %.0f/%.0f  HP+ %.1f/s\nSHLD %.0f/%.0f  SH+ %.1f/s\nXP %.0f/%.0f\nWAIT %.1fs" % [
		player_hp,
		player_max_hp,
		player_hp_regen,
		shield_hp,
		shield_max,
		shield_regen,
		xp,
		xp_to_next,
		shield_regen_delay
	]
	status_label.text = "COMBAT\nDMG %.1f  CD %.2fs  FIRE %.1f/s\nPROJ %d  PIERCE %d  BOUNCE %d\nCHAIN %d  SPLIT %d  TARGET %.0f\nVEL x%.2f  BLAST %.0f\nOVR %d  AS %d  DMG %d\nENEMY %d/%d  LVLM x%.1f" % [
		_scaled_weapon_damage(weapon),
		effective_cd,
		fire_rate,
		projectile_count,
		pierce_count,
		bounce_count,
		chain_count,
		upgrade_levels["split"],
		target_radius,
		velocity_mult,
		blast_radius,
		upgrade_levels["overload"],
		upgrade_levels["attack_speed"],
		upgrade_levels["damage"],
		enemies.size(),
		active_cap,
		enemy_level_mult
	]
	_update_side_panel_icons()
	if game_over:
		status_label.text = "Game Over - press Enter/Space to restart"
	if not run_started:
		loadout_info.text = _weapon_loadout_text(weapon, shield_defs[selected_shield_id])
	start_run_button.disabled = false


func _setup_side_panel() -> void:
	var hud := $CanvasLayer/HUD as Control
	sci_fi_font = SystemFont.new()
	sci_fi_font.font_names = PackedStringArray(["Orbitron", "Rajdhani", "Audiowide", "Eurostile", "DejaVu Sans Mono"])
	stats_panel = Panel.new()
	stats_panel.name = "StatsPanel"
	stats_panel.z_index = 70
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.94)
	panel_style.border_color = Color(0.3, 0.85, 1.0, 0.55)
	panel_style.set_border_width_all(2)
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	hud.add_child(stats_panel)

	stats_icons_root = Node2D.new()
	stats_icons_root.name = "StatsIcons"
	stats_icons_root.z_index = 82
	hud.add_child(stats_icons_root)
	var ship_points := PackedVector2Array([Vector2(0, -22), Vector2(9, 4), Vector2(18, 18), Vector2(0, 10), Vector2(-18, 18), Vector2(-9, 4), Vector2(0, -22)])
	var weapon_points := PackedVector2Array([Vector2(-22, 10), Vector2(-8, -12), Vector2(0, -20), Vector2(8, -12), Vector2(22, 10), Vector2(5, 5), Vector2(0, 22), Vector2(-5, 5), Vector2(-22, 10)])
	var shield_points := _circle_points(21.0, 40)
	ship_icon_glow = _make_panel_icon(Color(0.25, 1.0, 1.0, 0.3), ship_points, 6.0, true)
	weapon_icon_glow = _make_panel_icon(Color(1.0, 0.5, 0.2, 0.3), weapon_points, 6.0, true)
	shield_icon_glow = _make_panel_icon(Color(0.55, 0.9, 1.0, 0.3), shield_points, 6.0, true)
	ship_icon = _make_panel_icon(Color(0.78, 1.0, 1.0, 1.0), ship_points, 2.6, false)
	weapon_icon = _make_panel_icon(Color(1.0, 0.62, 0.2, 1.0), weapon_points, 2.6, false)
	shield_icon = _make_panel_icon(Color(0.6, 0.9, 1.0, 1.0), shield_points, 2.6, false)
	stats_icons_root.add_child(ship_icon_glow)
	stats_icons_root.add_child(weapon_icon_glow)
	stats_icons_root.add_child(shield_icon_glow)
	stats_icons_root.add_child(ship_icon)
	stats_icons_root.add_child(weapon_icon)
	stats_icons_root.add_child(shield_icon)

	ship_label = _make_panel_label("SHIP\nOutline", Color(0.78, 1.0, 1.0, 1.0), 10)
	weapon_label = _make_panel_label("", Color(1.0, 0.86, 0.68, 1.0), 10)
	shield_label = _make_panel_label("", Color(0.74, 0.92, 1.0, 1.0), 10)
	hud.add_child(ship_label)
	hud.add_child(weapon_label)
	hud.add_child(shield_label)

	prev_weapon_button = _make_cycle_button("<W")
	next_weapon_button = _make_cycle_button("W>")
	prev_shield_button = _make_cycle_button("<S")
	next_shield_button = _make_cycle_button("S>")
	prev_weapon_button.pressed.connect(_cycle_weapon.bind(-1))
	next_weapon_button.pressed.connect(_cycle_weapon.bind(1))
	prev_shield_button.pressed.connect(_cycle_shield.bind(-1))
	next_shield_button.pressed.connect(_cycle_shield.bind(1))
	hud.add_child(prev_weapon_button)
	hud.add_child(next_weapon_button)
	hud.add_child(prev_shield_button)
	hud.add_child(next_shield_button)

	for label in [score_label, time_label, status_label]:
		label.z_index = 82
		label.clip_contents = true
		label.add_theme_font_override("font", sci_fi_font)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 1)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_label.add_theme_font_size_override("font_size", 11)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.66, 1.0, 1.0))
	time_label.add_theme_font_size_override("font_size", 9)
	time_label.add_theme_color_override("font_color", Color(0.68, 1.0, 1.0, 1.0))
	status_label.add_theme_font_size_override("font_size", 9)

	for bar in [hp_bar, shield_bar, xp_bar]:
		bar.z_index = 82

	for panel in [weapon_panel, shield_panel, upgrade_panel, loadout_panel]:
		panel.z_index = 81
		_style_black_panel(panel)
	upgrade_panel.z_index = 120
	weapon_panel.visible = false
	shield_panel.visible = false

	for button in upgrade_buttons:
		button.z_index = 121
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = false
		_style_side_button(button)
	start_run_button.z_index = 82
	_style_side_button(start_run_button)
	for i in range(12):
		var weapon_btn := _find_button("Weapon%d" % (i + 1))
		if weapon_btn != null:
			_style_side_button(weapon_btn)
		var shield_btn := _find_button("Shield%d" % (i + 1))
		if shield_btn != null:
			_style_side_button(shield_btn)


func _style_black_panel(panel: Panel) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.025, 0.04, 0.92)
	panel_style.border_color = Color(0.45, 0.9, 1.0, 0.35)
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.modulate = Color.WHITE


func _style_side_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.055, 0.085, 0.96)
	normal.border_color = Color(0.45, 0.95, 1.0, 0.3)
	normal.set_border_width_all(1)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.16, 0.24, 0.98)
	hover.border_color = Color(1.0, 0.55, 1.0, 0.65)
	hover.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	if sci_fi_font != null:
		button.add_theme_font_override("font", sci_fi_font)
	button.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 1.0, 1.0))
	button.add_theme_font_size_override("font_size", 12)


func _style_upgrade_button(button: Button, tier: String, weapon_specific: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.055, 0.085, 0.96)
	if weapon_specific:
		normal.border_color = Color(1.0, 0.16, 0.12, 0.85)
	else:
		match tier:
			"uncommon":
				normal.border_color = Color(0.25, 0.7, 1.0, 0.8)
			"rare":
				normal.border_color = Color(1.0, 0.78, 0.18, 0.9)
			"epic":
				normal.border_color = Color(0.82, 0.35, 1.0, 0.9)
			_:
				normal.border_color = Color(0.45, 0.95, 1.0, 0.32)
	normal.set_border_width_all(2 if tier != "common" or weapon_specific else 1)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.16, 0.24, 0.98)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


func _make_panel_icon(color: Color, points: PackedVector2Array, width: float = 2.7, additive: bool = false) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.closed = true
	line.points = points
	line.default_color = color
	line.antialiased = true
	if additive:
		line.material = _make_additive_material()
	else:
		line.material = null
	return line


func _make_panel_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.z_index = 82
	if sci_fi_font != null:
		label.add_theme_font_override("font", sci_fi_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_contents = true
	return label


func _make_cycle_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.z_index = 83
	_style_side_button(button)
	return button


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _layout_side_panel() -> void:
	if stats_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var panel_x := 0.0
	_set_control_rect(stats_panel, Vector2(panel_x, 0.0), Vector2(SIDE_PANEL_WIDTH, viewport_size.y))
	var inner_x := panel_x + SIDE_PANEL_PADDING
	var inner_w := SIDE_PANEL_WIDTH - SIDE_PANEL_PADDING * 2.0
	var upgrade_mode := level_up_pending > 0
	var loadout_mode := not run_started

	_set_control_rect(score_label, Vector2(inner_x, 8.0), Vector2(inner_w, 62.0))
	if stats_icons_root != null:
		stats_icons_root.position = Vector2(inner_x, 78.0)
		stats_icons_root.scale = Vector2.ONE * 0.82
	ship_icon.position = Vector2(34.0, 0.0)
	ship_icon_glow.position = ship_icon.position
	weapon_icon.position = Vector2(152.0, 0.0)
	weapon_icon_glow.position = weapon_icon.position
	shield_icon.position = Vector2(270.0, 0.0)
	shield_icon_glow.position = shield_icon.position
	_set_control_rect(ship_label, Vector2(inner_x, 100.0), Vector2(72.0, 28.0))
	_set_control_rect(weapon_label, Vector2(inner_x + 82.0, 100.0), Vector2(142.0, 28.0))
	_set_control_rect(shield_label, Vector2(inner_x + 226.0, 100.0), Vector2(78.0, 28.0))

	_set_control_rect(prev_weapon_button, Vector2(inner_x + 84.0, 132.0), Vector2(42.0, 20.0))
	_set_control_rect(next_weapon_button, Vector2(inner_x + 174.0, 132.0), Vector2(42.0, 20.0))
	_set_control_rect(prev_shield_button, Vector2(inner_x + 224.0, 132.0), Vector2(38.0, 20.0))
	_set_control_rect(next_shield_button, Vector2(inner_x + 266.0, 132.0), Vector2(38.0, 20.0))
	prev_weapon_button.visible = loadout_mode
	next_weapon_button.visible = loadout_mode
	prev_shield_button.visible = loadout_mode
	next_shield_button.visible = loadout_mode

	_set_control_rect(hp_bar, Vector2(inner_x, 154.0), Vector2(inner_w, 8.0))
	_set_control_rect(shield_bar, Vector2(inner_x, 167.0), Vector2(inner_w, 8.0))
	_set_control_rect(xp_bar, Vector2(inner_x, 180.0), Vector2(inner_w, 8.0))
	hp_bar.visible = not loadout_mode
	shield_bar.visible = not loadout_mode
	xp_bar.visible = not loadout_mode
	_set_control_rect(time_label, Vector2(inner_x, 194.0), Vector2(inner_w, 78.0))
	time_label.visible = not loadout_mode
	_set_control_rect(status_label, Vector2(inner_x, 276.0), Vector2(inner_w, 132.0))
	status_label.visible = not loadout_mode

	if upgrade_mode:
		var upgrade_w := minf(520.0, viewport_size.x - SIDE_PANEL_WIDTH - 48.0)
		var upgrade_h := 198.0
		var playfield_x := SIDE_PANEL_WIDTH
		var upgrade_pos := Vector2(
			playfield_x + maxf(24.0, (viewport_size.x - playfield_x - upgrade_w) * 0.5),
			maxf(24.0, (viewport_size.y - upgrade_h) * 0.5)
		)
		_set_control_rect(upgrade_panel, upgrade_pos, Vector2(upgrade_w, upgrade_h))
		_set_upgrade_child_layout(upgrade_w)
	else:
		_set_control_rect(upgrade_panel, Vector2(inner_x, 424.0), Vector2(inner_w, 174.0))
		_set_upgrade_child_layout(inner_w)
	var loadout_y: float = 172.0
	var loadout_h: float = minf(532.0, viewport_size.y - loadout_y - 16.0)
	_set_control_rect(loadout_panel, Vector2(inner_x, loadout_y), Vector2(inner_w, loadout_h))
	_set_loadout_child_layout(inner_w)
	loadout_panel.visible = loadout_mode
	weapon_panel.visible = false
	shield_panel.visible = false


func _set_control_rect(control: Control, rect_position: Vector2, size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = rect_position
	control.size = size


func _set_upgrade_child_layout(width: float) -> void:
	var title := upgrade_panel.get_node_or_null("UpgradeTitle") as Label
	if title != null:
		_set_control_rect(title, Vector2(12.0, 8.0), Vector2(width - 24.0, 24.0))
		if sci_fi_font != null:
			title.add_theme_font_override("font", sci_fi_font)
		title.add_theme_font_size_override("font_size", 13)
		title.text = "Level Up - Pick Upgrade (1 / 2 / 3)"
		title.clip_contents = true
	for i in range(upgrade_buttons.size()):
		_set_control_rect(upgrade_buttons[i], Vector2(16.0, 42.0 + float(i) * 48.0), Vector2(width - 32.0, 42.0))
		upgrade_buttons[i].add_theme_font_size_override("font_size", 12)
		upgrade_buttons[i].clip_text = false
		upgrade_buttons[i].disabled = false
		upgrade_buttons[i].mouse_filter = Control.MOUSE_FILTER_STOP


func _set_loadout_child_layout(width: float) -> void:
	var title := loadout_panel.get_node_or_null("LoadoutTitle") as Label
	if title != null:
		_set_control_rect(title, Vector2(12.0, 10.0), Vector2(width - 24.0, 26.0))
		if not weapon_defs.is_empty():
			title.text = String(weapon_defs[selected_weapon_id].get("name", "Weapon")).to_upper()
		else:
			title.text = "SELECT WEAPON"
		if sci_fi_font != null:
			title.add_theme_font_override("font", sci_fi_font)
		title.add_theme_font_size_override("font_size", 16)
		title.clip_contents = true
	var info := loadout_panel.get_node_or_null("LoadoutInfo") as Label
	if info != null:
		_set_control_rect(info, Vector2(12.0, 42.0), Vector2(width - 24.0, 370.0))
		if sci_fi_font != null:
			info.add_theme_font_override("font", sci_fi_font)
		info.add_theme_font_size_override("font_size", 9)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.clip_contents = true
	_set_control_rect(start_run_button, Vector2(12.0, 424.0), Vector2(width - 24.0, 38.0))


func _update_side_panel_icons() -> void:
	if weapon_defs.is_empty() or shield_defs.is_empty():
		return
	var weapon: Dictionary = weapon_defs[selected_weapon_id]
	var shield: Dictionary = shield_defs[selected_shield_id]
	var weapon_color := _weapon_core_color(String(weapon.get("archetype", "bullet")))
	weapon_icon.default_color = Color(weapon_color.r, weapon_color.g, weapon_color.b, 1.0)
	weapon_icon_glow.default_color = Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.32)
	var shield_color := _shield_icon_color()
	shield_icon.default_color = shield_color
	shield_icon_glow.default_color = Color(shield_color.r, shield_color.g, shield_color.b, 0.32)
	weapon_label.text = "WEAPON\n%s" % _short_label(String(weapon.get("name", "Weapon")), 12)
	shield_label.text = "SHIELD\n%s" % _short_label(String(shield.get("name", "Shield")), 9)


func _short_label(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, max_chars - 1) + "."


func _shield_icon_color() -> Color:
	match shield_trait:
		"reflect":
			return Color(1.0, 0.55, 0.96, 1.0)
		"shock":
			return Color(0.55, 0.95, 1.0, 1.0)
		"void":
			return Color(0.82, 0.62, 1.0, 1.0)
		"tank":
			return Color(0.72, 1.0, 0.9, 1.0)
		_:
			return Color(0.72, 0.92, 1.0, 1.0)


func _set_ui_tooltips() -> void:
	hp_bar.tooltip_text = "Hull HP. Recharges slowly over time."
	shield_bar.tooltip_text = "Shield HP. Regens after delay without taking damage."
	xp_bar.tooltip_text = "Gain XP from kills, level up for upgrades."
	upgrade_buttons[0].tooltip_text = "Upgrade slot 1"
	upgrade_buttons[1].tooltip_text = "Upgrade slot 2"
	upgrade_buttons[2].tooltip_text = "Upgrade slot 3"


func _weapon_loadout_text(weapon: Dictionary, shield: Dictionary) -> String:
	var projectile_count := int(weapon.get("projectiles", 1))
	var pierce_count := int(weapon.get("base_pierce", 0))
	var bounce_count := int(weapon.get("base_bounce", 0))
	var blast_radius := float(weapon.get("blast_radius", 0.0))
	var poison_dps := float(weapon.get("poison_dps", 0.0))
	var stats := "DMG %.1f  CD %.2fs  PROJ %d\nSPD %.0f  PIERCE %d  BOUNCE %d" % [
		float(weapon.get("damage", 0.0)),
		float(weapon.get("cooldown", 0.0)),
		projectile_count,
		float(weapon.get("speed", BULLET_SPEED)),
		pierce_count,
		bounce_count
	]
	if blast_radius > 0.0:
		stats += "\nBLAST %.0f" % blast_radius
	if poison_dps > 0.0:
		stats += "  POISON %.1f/s" % poison_dps
	return "%s\n%s\n\n%s\n\n%s\n\nSTRONG\n%s\n\nWEAK\n%s\n\nSHIELD: %s\n%s\n\nWEAPON %02d / %02d" % [
		String(weapon.get("role", weapon.get("tag", "WEAPON"))),
		String(weapon.get("tag", "")).to_upper(),
		String(weapon.get("desc", "")),
		stats,
		String(weapon.get("strong", "-")),
		String(weapon.get("weak", "-")),
		String(shield.get("name", "Shield")),
		"%.0f shield  %.1f/s regen" % [float(shield.get("max", 0.0)), float(shield.get("regen", 0.0))],
		selected_weapon_id + 1,
		weapon_defs.size()
	]


func _weapon_tooltip(def: Dictionary) -> String:
	return "%s\n%s\nDamage: %.1f  Cooldown: %.2f\nProjectiles: %d Spread: %.1f\n%s" % [
		def.get("name", "Weapon"),
		def.get("role", def.get("tag", "-")),
		float(def.get("damage", 0.0)),
		float(def.get("cooldown", 0.0)),
		int(def.get("projectiles", 1)),
		float(def.get("spread_deg", 0.0)),
		def.get("desc", "")
	]


func _shield_tooltip(def: Dictionary) -> String:
	return "%s\nType: %s\nShield: %.0f  Regen: %.1f/s  Delay: %.1fs" % [
		def.get("name", "Shield"),
		def.get("tag", "-"),
		float(def.get("max", 0.0)),
		float(def.get("regen", 0.0)),
		float(def.get("delay", 0.0))
	]


func _find_button(node_name: String) -> Button:
	return canvas_layer.find_child(node_name, true, false) as Button


func _setup_neon_look() -> void:
	var player_body := $Player/Body as Polygon2D
	player_body.color = Color(0.2, 0.9, 1.0, 0.0)
	var player_outline := $Player/Outline as Line2D
	player_outline.default_color = Color(0.55, 1.0, 1.0, 0.96)
	player_outline.width = 2.8
	player_outline.material = null
	_ensure_player_detail_lines(player_outline.points)
	if is_instance_valid(player_back_glow):
		player_back_glow.color = Color(0.02, 0.82, 1.0, 0.18)
		player_back_glow.material = _make_additive_material()
	if is_instance_valid(stars):
		stars.visible = false
		stars.material = null
	if is_instance_valid(nebula_magenta):
		nebula_magenta.visible = false
		nebula_magenta.material = null
	if is_instance_valid(nebula_cyan):
		nebula_cyan.visible = false
		nebula_cyan.material = null
	_style_hud_neon()


func _ensure_player_detail_lines(outline_points: PackedVector2Array) -> void:
	var old_glow := player.get_node_or_null("ShipOutlineGlow")
	if old_glow != null:
		old_glow.queue_free()
	var old_struts := player.get_node_or_null("ShipStruts")
	if old_struts != null:
		old_struts.queue_free()
	var old_engine := player.get_node_or_null("EngineNeedle")
	if old_engine != null:
		old_engine.queue_free()

	var glow := Line2D.new()
	glow.name = "ShipOutlineGlow"
	glow.z_index = -2
	glow.closed = true
	glow.width = 8.8
	glow.default_color = Color(0.04, 0.85, 1.0, 0.44)
	glow.points = _scaled_points(outline_points, 1.12)
	glow.antialiased = true
	glow.material = _make_additive_material()
	player.add_child(glow)

	var struts := Line2D.new()
	struts.name = "ShipStruts"
	struts.z_index = 1
	struts.width = 1.4
	struts.default_color = Color(0.82, 1.0, 1.0, 0.92)
	struts.points = PackedVector2Array([Vector2(0, -13), Vector2(0, 8), Vector2(-8, 10), Vector2(0, 3), Vector2(8, 10)])
	struts.antialiased = true
	player.add_child(struts)

	var engine := Line2D.new()
	engine.name = "EngineNeedle"
	engine.z_index = 1
	engine.width = 2.2
	engine.default_color = Color(0.12, 0.95, 1.0, 0.86)
	engine.points = PackedVector2Array([Vector2(-5, 12), Vector2(0, 20), Vector2(5, 12)])
	engine.antialiased = true
	engine.material = _make_additive_material()
	player.add_child(engine)


func _setup_shield_visuals() -> void:
	shield_outer_ring = Line2D.new()
	shield_outer_ring.width = 3.0
	shield_outer_ring.default_color = Color(0.4, 1.0, 1.0, 0.75)
	shield_outer_ring.closed = true
	shield_outer_ring.antialiased = true
	player.add_child(shield_outer_ring)

	shield_inner_ring = Line2D.new()
	shield_inner_ring.width = 2.0
	shield_inner_ring.default_color = Color(0.8, 1.0, 1.0, 0.6)
	shield_inner_ring.closed = true
	shield_inner_ring.antialiased = true
	player.add_child(shield_inner_ring)

	shield_pulse = Polygon2D.new()
	shield_pulse.color = Color(0.35, 1.0, 1.0, 0.12)
	player.add_child(shield_pulse)

	shield_spikes = Line2D.new()
	shield_spikes.width = 2.0
	shield_spikes.default_color = Color(0.7, 1.0, 1.0, 0.55)
	shield_spikes.closed = true
	shield_spikes.antialiased = true
	player.add_child(shield_spikes)

	_set_ring_points(shield_outer_ring, 28.0, 40)
	_set_ring_points(shield_inner_ring, 22.0, 32)
	_set_disc_points(shield_pulse, 34.0, 42)
	_set_spike_points(shield_spikes, 30.0, 36, 0.22)
	shield_outer_ring.material = _make_additive_material()
	shield_inner_ring.material = _make_additive_material()
	shield_pulse.material = _make_additive_material()
	shield_spikes.material = _make_additive_material()
	_apply_shield_visual_theme()


func _set_ring_points(line: Line2D, radius: float, segments: int) -> void:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = pts


func _set_disc_points(poly: Polygon2D, radius: float, segments: int) -> void:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts


func _set_spike_points(line: Line2D, radius: float, segments: int, spike_strength: float) -> void:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		var point_scale := 1.0
		if i % 2 == 0:
			point_scale += spike_strength
		pts.append(Vector2(cos(a), sin(a)) * radius * point_scale)
	line.points = pts


func _apply_shield_visual_theme() -> void:
	if shield_outer_ring == null or shield_inner_ring == null or shield_pulse == null:
		return
	match shield_trait:
		"reflect":
			shield_outer_ring.default_color = Color(1.0, 0.5, 0.95, 0.85)
			shield_inner_ring.default_color = Color(1.0, 0.72, 1.0, 0.7)
			shield_pulse.color = Color(1.0, 0.45, 0.9, 0.16)
			shield_spikes.default_color = Color(1.0, 0.7, 0.95, 0.72)
		"shock":
			shield_outer_ring.default_color = Color(0.5, 0.9, 1.0, 0.9)
			shield_inner_ring.default_color = Color(0.75, 0.95, 1.0, 0.75)
			shield_pulse.color = Color(0.45, 0.9, 1.0, 0.18)
			shield_spikes.default_color = Color(0.65, 0.95, 1.0, 0.78)
		"void":
			shield_outer_ring.default_color = Color(0.75, 0.55, 1.0, 0.85)
			shield_inner_ring.default_color = Color(0.9, 0.75, 1.0, 0.72)
			shield_pulse.color = Color(0.62, 0.45, 1.0, 0.16)
			shield_spikes.default_color = Color(0.86, 0.6, 1.0, 0.72)
		"tank":
			shield_outer_ring.default_color = Color(0.65, 1.0, 0.95, 0.85)
			shield_inner_ring.default_color = Color(0.8, 1.0, 0.95, 0.75)
			shield_pulse.color = Color(0.5, 1.0, 0.9, 0.15)
			shield_spikes.default_color = Color(0.8, 1.0, 0.96, 0.68)
		_:
			shield_outer_ring.default_color = Color(0.42, 1.0, 1.0, 0.82)
			shield_inner_ring.default_color = Color(0.85, 1.0, 1.0, 0.68)
			shield_pulse.color = Color(0.35, 1.0, 1.0, 0.12)
			shield_spikes.default_color = Color(0.7, 1.0, 1.0, 0.62)


func _update_shield_visuals(delta: float) -> void:
	if shield_outer_ring == null:
		return
	shield_phase += delta
	var ratio: float = 0.0
	if shield_max > 0.0:
		ratio = shield_hp / shield_max
	shield_outer_ring.visible = ratio > 0.01
	shield_inner_ring.visible = ratio > 0.01
	shield_pulse.visible = ratio > 0.01
	shield_spikes.visible = ratio > 0.01
	var pulse: float = 1.0 + sin(shield_phase * 6.0) * 0.06
	var depletion: float = clamp(ratio, 0.0, 1.0)
	var alpha_outer: float = 0.2 + depletion * 0.7
	var alpha_inner: float = 0.15 + depletion * 0.6
	var alpha_disc: float = 0.04 + depletion * 0.16
	shield_outer_ring.modulate = Color(1, 1, 1, alpha_outer)
	shield_inner_ring.modulate = Color(1, 1, 1, alpha_inner)
	shield_pulse.modulate = Color(1, 1, 1, alpha_disc)
	shield_spikes.modulate = Color(1, 1, 1, alpha_inner * 0.92)
	shield_outer_ring.scale = Vector2.ONE * pulse
	shield_inner_ring.scale = Vector2.ONE * (1.0 + sin(shield_phase * 8.0 + 0.8) * 0.04)
	shield_pulse.scale = Vector2.ONE * (1.0 + sin(shield_phase * 5.0 + 1.6) * 0.07)
	shield_spikes.rotation = shield_phase * 0.9


func _style_hud_neon() -> void:
	score_label.modulate = Color(0.98, 0.64, 1.0, 1)
	time_label.modulate = Color(0.62, 1.0, 1.0, 1)
	status_label.modulate = Color(0.92, 0.94, 1.0, 1)
	for label in [score_label, time_label, status_label]:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.1, 0.95))
		label.add_theme_constant_override("outline_size", 2)
	hp_bar.modulate = Color(1.0, 0.43, 0.72, 0.96)
	shield_bar.modulate = Color(0.42, 0.98, 1.0, 0.96)
	xp_bar.modulate = Color(0.9, 0.48, 1.0, 0.96)
	for panel in [weapon_panel, shield_panel, upgrade_panel, loadout_panel]:
		panel.modulate = Color(0.72, 0.8, 0.92, 0.9)
	for i in range(12):
		var weapon_btn := _find_button("Weapon%d" % (i + 1))
		if weapon_btn != null:
			weapon_btn.add_theme_color_override("font_color", Color(0.88, 0.97, 1.0))
			weapon_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 1.0))
		var shield_btn := _find_button("Shield%d" % (i + 1))
		if shield_btn != null:
			shield_btn.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))
			shield_btn.add_theme_color_override("font_hover_color", Color(0.98, 0.86, 1.0))


func _style_enemy_visual(enemy: Node2D, archetype: Dictionary) -> void:
	var body := enemy.get_node_or_null("Body") as Polygon2D
	var outer_glow := enemy.get_node_or_null("OuterGlow") as Polygon2D
	var core := enemy.get_node_or_null("Core") as Polygon2D
	var halo := enemy.get_node_or_null("NovaHalo") as Line2D
	var inner_lines := enemy.get_node_or_null("InteriorLines") as Line2D
	var orbit_marks := enemy.get_node_or_null("OrbitMarks") as Line2D
	var outline_glow := enemy.get_node_or_null("OutlineGlow") as Line2D
	var outline := enemy.get_node_or_null("Outline") as Line2D
	var trail := enemy.get_node_or_null("MotionTrail") as Line2D
	var hp := enemy.get_node_or_null("HealthBar") as ProgressBar
	var raw_points: Array = archetype.get("shape", [])
	var points := PackedVector2Array()
	for p in raw_points:
		points.append((p as Vector2) * 0.5)
	if outer_glow != null:
		outer_glow.visible = false
		outer_glow.material = null
	if points.size() > 0:
		if body != null:
			body.polygon = points
		if outline != null:
			outline.points = points
		if outline_glow != null:
			outline_glow.points = points
		if halo == null:
			halo = Line2D.new()
			halo.name = "NovaHalo"
			halo.z_index = -4
			halo.closed = true
			halo.antialiased = true
			halo.material = _make_additive_material()
			enemy.add_child(halo)
		halo.points = _scaled_points(points, 1.34)
		if inner_lines == null:
			inner_lines = Line2D.new()
			inner_lines.name = "InteriorLines"
			inner_lines.z_index = 1
			inner_lines.antialiased = true
			enemy.add_child(inner_lines)
		inner_lines.points = _enemy_interior_points(points)
		if orbit_marks == null:
			orbit_marks = Line2D.new()
			orbit_marks.name = "OrbitMarks"
			orbit_marks.z_index = -1
			orbit_marks.antialiased = true
			orbit_marks.material = _make_additive_material()
			enemy.add_child(orbit_marks)
		orbit_marks.points = _enemy_tick_points(18.0)
	if body != null:
		var bc: Color = archetype.get("body_color", Color(1.0, 0.28, 0.55, 0.0))
		body.color = Color(bc.r, bc.g, bc.b, 0.05)
		body.material = _make_additive_material()
	if core != null:
		core.visible = false
		core.material = _make_additive_material()
	var oc: Color = archetype.get("outline_color", Color(1.0, 0.66, 0.9, 0.95))
	var stroke := Color(
		clampf(oc.r * 1.18 + 0.08, 0.0, 1.0),
		clampf(oc.g * 1.14 + 0.06, 0.0, 1.0),
		clampf(oc.b * 1.12 + 0.08, 0.0, 1.0),
		1.0
	)
	if halo != null:
		halo.default_color = Color(stroke.r, stroke.g, stroke.b, 0.34)
		halo.width = 15.0
	if outline_glow != null:
		outline_glow.default_color = Color(stroke.r, stroke.g, stroke.b, 0.86)
		outline_glow.width = 10.0
		outline_glow.material = _make_additive_material()
	if outline != null:
		outline.default_color = stroke
		outline.width = 2.8
		outline.material = null
	if inner_lines != null:
		inner_lines.default_color = Color(1.0, 1.0, 1.0, 0.58)
		inner_lines.width = 1.55
		inner_lines.material = null
	if orbit_marks != null:
		orbit_marks.default_color = Color(stroke.r, stroke.g, stroke.b, 0.46)
		orbit_marks.width = 1.4
	if trail != null:
		trail.queue_free()
	if hp != null:
		hp.modulate = Color(0.75, 0.95, 1.0, 0.58)
		hp.scale = Vector2(0.72, 0.5)


func _scaled_points(points: PackedVector2Array, point_scale: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for p in points:
		scaled.append(p * point_scale)
	return scaled


func _enemy_interior_points(points: PackedVector2Array) -> PackedVector2Array:
	var inner := PackedVector2Array()
	if points.size() < 3:
		return inner
	inner.append(points[0] * 0.58)
	inner.append(Vector2.ZERO)
	inner.append(points[int(float(points.size()) / 3.0)] * 0.58)
	inner.append(Vector2.ZERO)
	inner.append(points[int(float(points.size() * 2) / 3.0)] * 0.58)
	return inner


func _enemy_tick_points(radius: float) -> PackedVector2Array:
	var ticks := PackedVector2Array()
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var dir := Vector2.from_angle(angle)
		ticks.append(dir * radius)
		ticks.append(dir * (radius + 5.0))
	return ticks


func _make_additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _weapon_glow_color(archetype: String) -> Color:
	match archetype:
		"pulse":
			return Color(0.04, 0.92, 1.0, 0.74)
		"twin_fang":
			return Color(1.0, 0.18, 0.9, 0.82)
		"rail":
			return Color(0.46, 0.95, 1.0, 0.92)
		"lightning":
			return Color(0.2, 0.62, 1.0, 0.82)
		"mortar":
			return Color(1.0, 0.34, 0.02, 0.95)
		"starbreaker":
			return Color(1.0, 0.18, 0.04, 0.98)
		"shrapnel":
			return Color(0.75, 1.0, 0.12, 0.76)
		"spore", "toxic_needle", "poison_shot":
			return Color(0.16, 1.0, 0.24, 0.76)
		"ricochet":
			return Color(1.0, 0.9, 0.08, 0.78)
		"photon":
			return Color(0.92, 1.0, 1.0, 0.64)
		"void":
			return Color(0.86, 0.18, 1.0, 0.82)
		_:
			return Color(0.04, 0.92, 1.0, 0.74)


func _weapon_core_color(archetype: String) -> Color:
	match archetype:
		"pulse":
			return Color(0.95, 1.0, 1.0, 1)
		"twin_fang":
			return Color(1.0, 0.76, 1.0, 1)
		"rail":
			return Color(0.96, 1.0, 1.0, 1)
		"lightning":
			return Color(0.75, 0.85, 1.0, 1)
		"mortar":
			return Color(1.0, 0.78, 0.18, 1)
		"starbreaker":
			return Color(1.0, 0.96, 0.46, 1)
		"shrapnel":
			return Color(0.9, 1.0, 0.55, 1)
		"spore", "toxic_needle", "poison_shot":
			return Color(0.45, 1.0, 0.45, 1)
		"ricochet":
			return Color(1.0, 0.95, 0.55, 1)
		"photon":
			return Color(1.0, 1.0, 1.0, 1)
		"void":
			return Color(0.9, 0.55, 1.0, 1)
		_:
			return Color(0.95, 1.0, 1.0, 1)


func _weapon_glow_shape(archetype: String) -> PackedVector2Array:
	match archetype:
		"pulse":
			return PackedVector2Array([Vector2(0, -9), Vector2(7, -2), Vector2(5, 7), Vector2(0, 10), Vector2(-5, 7), Vector2(-7, -2)])
		"twin_fang":
			return PackedVector2Array([Vector2(0, -16), Vector2(8, -6), Vector2(5, 8), Vector2(0, 14), Vector2(-5, 8), Vector2(-8, -6)])
		"rail":
			return PackedVector2Array([Vector2(0, -24), Vector2(5, -10), Vector2(4, 22), Vector2(0, 30), Vector2(-4, 22), Vector2(-5, -10)])
		"lightning":
			return PackedVector2Array([Vector2(0, -13), Vector2(4, -6), Vector2(-2, -1), Vector2(3, 5), Vector2(-5, 8), Vector2(-2, 1), Vector2(-6, -6)])
		"mortar":
			return PackedVector2Array([Vector2(0, -12), Vector2(8, -4), Vector2(10, 4), Vector2(0, 12), Vector2(-10, 4), Vector2(-8, -4)])
		"starbreaker":
			return PackedVector2Array([Vector2(0, -18), Vector2(7, -7), Vector2(18, 0), Vector2(7, 7), Vector2(0, 18), Vector2(-7, 7), Vector2(-18, 0), Vector2(-7, -7)])
		"shrapnel":
			return PackedVector2Array([Vector2(0, -14), Vector2(5, -3), Vector2(13, -1), Vector2(3, 5), Vector2(5, 14), Vector2(-2, 6), Vector2(-12, 8), Vector2(-6, -2)])
		"spore":
			return PackedVector2Array([Vector2(0, -9), Vector2(8, -2), Vector2(6, 7), Vector2(0, 10), Vector2(-6, 7), Vector2(-8, -2)])
		"toxic_needle", "poison_shot":
			return PackedVector2Array([Vector2(0, -18), Vector2(4, -2), Vector2(2, 12), Vector2(0, 17), Vector2(-2, 12), Vector2(-4, -2)])
		"ricochet":
			return PackedVector2Array([Vector2(0, -13), Vector2(11, -5), Vector2(7, 3), Vector2(13, 9), Vector2(0, 12), Vector2(-10, 6), Vector2(-8, -6)])
		"photon":
			return PackedVector2Array([Vector2(0, -8), Vector2(17, 9), Vector2(5, 5), Vector2(0, 13), Vector2(-5, 5), Vector2(-17, 9)])
		"void":
			return PackedVector2Array([Vector2(0, -12), Vector2(5, -4), Vector2(8, 2), Vector2(3, 10), Vector2(-3, 10), Vector2(-8, 2), Vector2(-5, -4)])
		_:
			return PackedVector2Array([Vector2(0, -10), Vector2(6, 4), Vector2(-6, 4)])


func _weapon_core_shape(archetype: String) -> PackedVector2Array:
	match archetype:
		"pulse":
			return PackedVector2Array([Vector2(0, -5), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)])
		"twin_fang":
			return PackedVector2Array([Vector2(0, -12), Vector2(3, 0), Vector2(0, 10), Vector2(-3, 0)])
		"rail":
			return PackedVector2Array([Vector2(0, -20), Vector2(2, -8), Vector2(2, 26), Vector2(0, 32), Vector2(-2, 26), Vector2(-2, -8)])
		"lightning":
			return PackedVector2Array([Vector2(0, -7), Vector2(2, -2), Vector2(-1, 1), Vector2(2, 4), Vector2(-2, 7), Vector2(-1, 2), Vector2(-3, -2)])
		"mortar":
			return PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)])
		"starbreaker":
			return PackedVector2Array([Vector2(0, -10), Vector2(5, -4), Vector2(10, 0), Vector2(5, 4), Vector2(0, 10), Vector2(-5, 4), Vector2(-10, 0), Vector2(-5, -4)])
		"shrapnel":
			return PackedVector2Array([Vector2(0, -8), Vector2(5, -1), Vector2(2, 6), Vector2(-6, 4), Vector2(-3, -3)])
		"spore":
			return PackedVector2Array([Vector2(0, -5), Vector2(5, 0), Vector2(3, 5), Vector2(-3, 5), Vector2(-5, 0)])
		"toxic_needle", "poison_shot":
			return PackedVector2Array([Vector2(0, -12), Vector2(2, 6), Vector2(0, 12), Vector2(-2, 6)])
		"ricochet":
			return PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
		"photon":
			return PackedVector2Array([Vector2(0, -4), Vector2(12, 6), Vector2(0, 8), Vector2(-12, 6)])
		"void":
			return PackedVector2Array([Vector2(0, -6), Vector2(4, -2), Vector2(5, 2), Vector2(2, 6), Vector2(-2, 6), Vector2(-5, 2), Vector2(-4, -2)])
		_:
			return PackedVector2Array([Vector2(0, -5), Vector2(3, 2), Vector2(-3, 2)])


func _weapon_trail_color(archetype: String) -> Color:
	match archetype:
		"pulse":
			return Color(0.62, 0.96, 1.0, 0.64)
		"twin_fang":
			return Color(1.0, 0.42, 0.95, 0.72)
		"rail":
			return Color(0.72, 1.0, 1.0, 0.96)
		"lightning":
			return Color(0.65, 0.78, 1.0, 0.7)
		"mortar":
			return Color(1.0, 0.62, 0.04, 0.9)
		"starbreaker":
			return Color(1.0, 0.76, 0.16, 0.92)
		"shrapnel":
			return Color(0.78, 1.0, 0.3, 0.66)
		"spore", "toxic_needle", "poison_shot":
			return Color(0.4, 1.0, 0.5, 0.66)
		"ricochet":
			return Color(1.0, 0.95, 0.5, 0.68)
		"photon":
			return Color(0.86, 1.0, 1.0, 0.58)
		"void":
			return Color(0.92, 0.58, 1.0, 0.72)
		_:
			return Color(0.62, 0.96, 1.0, 0.64)


func _weapon_visual_scale(archetype: String) -> float:
	match archetype:
		"rail":
			return 1.42
		"starbreaker":
			return 2.1
		"mortar", "spore":
			return 1.7
		"photon":
			return 1.55
		"toxic_needle":
			return 1.25
		_:
			return 1.35


func _weapon_trail_width(archetype: String) -> float:
	match archetype:
		"rail":
			return 13.0
		"starbreaker":
			return 9.5
		"mortar", "spore":
			return 7.0
		"lightning":
			return 4.6
		"ricochet":
			return 4.2
		"photon":
			return 3.0
		"toxic_needle":
			return 2.2
		"shrapnel":
			return 3.2
		_:
			return 5.4


func _weapon_trail_length(archetype: String) -> float:
	match archetype:
		"rail":
			return 110.0
		"starbreaker":
			return 56.0
		"mortar", "spore":
			return 42.0
		"lightning":
			return 28.0
		"ricochet":
			return 26.0
		"photon":
			return 18.0
		"toxic_needle":
			return 22.0
		"shrapnel":
			return 20.0
		_:
			return 34.0


func _update_bullet_trail(bullet: Node2D, phase: float) -> void:
	if not bullet.has_meta("trail_node"):
		return
	var trail := bullet.get_meta("trail_node") as Line2D
	if trail == null:
		return
	var archetype: String = String(bullet.get_meta("archetype", "bullet"))
	var length: float = 13.0 + sin(phase) * 2.5
	if archetype == "rail":
		length = 112.0 + sin(phase * 2.3) * 10.0
		trail.width = 13.0 + sin(phase * 3.0) * 1.8
	elif archetype == "starbreaker":
		length = 58.0 + sin(phase * 0.7) * 6.0
		trail.width = 9.5
		var arming_ring: Line2D = null
		if bullet.has_meta("arming_ring"):
			arming_ring = bullet.get_meta("arming_ring") as Line2D
		if arming_ring != null:
			arming_ring.rotation = phase * 1.2
			arming_ring.scale = Vector2.ONE * (1.0 + sin(phase * 2.0) * 0.12)
	elif archetype == "mortar" or archetype == "spore":
		length = 42.0 + sin(phase * 0.8) * 5.0
		trail.width = 7.0
		var arming_ring: Line2D = null
		if bullet.has_meta("arming_ring"):
			arming_ring = bullet.get_meta("arming_ring") as Line2D
		if arming_ring != null:
			arming_ring.rotation = phase * 1.6
			arming_ring.scale = Vector2.ONE * (1.0 + sin(phase * 2.4) * 0.1)
	elif archetype == "lightning":
		length = 18.0 + sin(phase * 1.8) * 6.0
		trail.width = 4.2
	elif archetype == "ricochet":
		length = 18.0 + sin(phase * 1.2) * 2.5
		trail.width = 4.0
	elif archetype == "photon":
		length = 16.0 + sin(phase * 1.6) * 2.0
		trail.width = 3.0
	elif archetype == "toxic_needle":
		length = 22.0 + sin(phase * 2.0) * 3.0
		trail.width = 2.2
	elif archetype == "shrapnel":
		length = 20.0 + sin(phase * 3.0) * 3.0
		trail.width = 3.2
	else:
		length = 34.0 + sin(phase) * 4.0
		trail.width = 5.4
	trail.points = PackedVector2Array([Vector2(0, 0), Vector2(0, length)])
	var trail_power := _trail_damage_power_for_bullet(bullet)
	var damage_trail := bullet.get_meta("damage_trail_node", null) as Line2D
	if trail_power > 0.0:
		if damage_trail == null:
			damage_trail = Line2D.new()
			damage_trail.antialiased = true
			damage_trail.z_index = -2
			damage_trail.material = _make_additive_material()
			bullet.add_child(damage_trail)
			bullet.set_meta("damage_trail_node", damage_trail)
		var color := Color(0.74, 1.0, 0.96, 0.9) if archetype != "shrapnel" else Color(1.0, 0.32, 0.98, 0.9)
		damage_trail.width = trail.width + 3.0 + trail_power * 0.8
		damage_trail.default_color = Color(color.r, color.g, color.b, minf(1.0, 0.62 + trail_power * 0.08))
		damage_trail.points = PackedVector2Array([Vector2(0, 2.0), Vector2(sin(phase * 2.5) * 5.0, length * 1.55)])
	elif damage_trail != null:
		damage_trail.queue_free()
		bullet.remove_meta("damage_trail_node")


func _to_roman(value: int) -> String:
	match value:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
		6:
			return "VI"
		7:
			return "VII"
		8:
			return "VIII"
		9:
			return "IX"
		10:
			return "X"
		_:
			return str(value)


func _setup_space_background() -> void:
	var w := 1280
	var h := 720
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 1))
	var grid_step := 96
	for x_line in range(0, w, grid_step):
		for y_px in range(h):
			image.set_pixel(x_line, y_px, Color(0.0, 0.085, 0.11, 1.0))
			if x_line + 1 < w:
				image.set_pixel(x_line + 1, y_px, Color(0.0, 0.04, 0.055, 1.0))
	for y_line in range(0, h, grid_step):
		for x_px in range(w):
			image.set_pixel(x_px, y_line, Color(0.085, 0.0, 0.08, 1.0))
			if y_line + 1 < h:
				image.set_pixel(x_px, y_line + 1, Color(0.04, 0.0, 0.04, 1.0))
	for i in range(1500):
		var sx := randi() % w
		var sy := randi() % h
		var bright := 0.45 + randf() * 0.55
		var cool := 0.78 + randf() * 0.22
		var star := Color(bright * cool, bright * cool, bright, 1.0)
		if randf() < 0.07:
			star = Color(1.0, 0.98, 0.95, 1.0)
		image.set_pixel(sx, sy, star)
		if randf() < 0.1:
			var glint: Color = star.lerp(Color.WHITE, 0.45)
			if sx < w - 1:
				image.set_pixel(sx + 1, sy, glint)
			if sy < h - 1:
				image.set_pixel(sx, sy + 1, glint)
	if is_instance_valid(space_background):
		var bg_size := ARENA_HALF_SIZE * 2.0 + Vector2(1400.0, 900.0)
		space_background.anchor_left = 0.0
		space_background.anchor_top = 0.0
		space_background.anchor_right = 0.0
		space_background.anchor_bottom = 0.0
		space_background.position = -bg_size * 0.5
		space_background.size = bg_size
		space_background.z_index = -1000
		space_background.modulate = Color.WHITE
		space_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		space_background.texture = ImageTexture.create_from_image(image)
	_setup_neon_playfield_grid()


func _setup_neon_playfield_grid() -> void:
	var old_grid := get_node_or_null("NeonPlayfieldGrid")
	if old_grid != null:
		old_grid.queue_free()
	var grid := Node2D.new()
	grid.name = "NeonPlayfieldGrid"
	grid.z_index = -990
	add_child(grid)

	var spacing := 96.0
	var left := -ARENA_HALF_SIZE.x - 320.0
	var right := ARENA_HALF_SIZE.x + 320.0
	var top := -ARENA_HALF_SIZE.y - 240.0
	var bottom := ARENA_HALF_SIZE.y + 240.0
	var x := left
	while x <= right:
		var line := _make_background_line(Vector2(x, top), Vector2(x, bottom), Color(0.05, 0.8, 1.0, 0.18))
		grid.add_child(line)
		x += spacing
	var y := top
	while y <= bottom:
		var line := _make_background_line(Vector2(left, y), Vector2(right, y), Color(1.0, 0.12, 0.92, 0.13))
		grid.add_child(line)
		y += spacing

	var border := Line2D.new()
	border.closed = true
	border.width = 3.0
	border.default_color = Color(0.08, 0.95, 1.0, 0.4)
	border.points = PackedVector2Array([
		Vector2(-ARENA_HALF_SIZE.x, -ARENA_HALF_SIZE.y),
		Vector2(ARENA_HALF_SIZE.x, -ARENA_HALF_SIZE.y),
		Vector2(ARENA_HALF_SIZE.x, ARENA_HALF_SIZE.y),
		Vector2(-ARENA_HALF_SIZE.x, ARENA_HALF_SIZE.y)
	])
	border.antialiased = true
	border.material = _make_additive_material()
	grid.add_child(border)


func _make_background_line(from_pos: Vector2, to_pos: Vector2, color: Color) -> Line2D:
	var line := Line2D.new()
	line.width = 1.25
	line.default_color = color
	line.points = PackedVector2Array([from_pos, to_pos])
	line.antialiased = true
	line.material = _make_additive_material()
	return line
