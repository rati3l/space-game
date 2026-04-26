extends RefCounted
class_name SkillTree

# Data-driven passive tree generator inspired by PoE-like node layouts.
# Generates 324 nodes across 6 regions with tier templates and adjacency links.

const REGION_COUNT := 6
const REGION_ROWS := 6
const REGION_COLS := 9
const NODE_COUNT_TARGET := REGION_COUNT * REGION_ROWS * REGION_COLS

const TYPE_SMALL := "small"
const TYPE_MEDIUM := "medium"
const TYPE_NOTABLE := "notable"
const TYPE_KEYSTONE := "keystone"

const REGION_TEMPLATES := [
	{
		"id": "might",
		"name": "Crimson Bastion",
		"tags": ["strength", "melee", "armor"],
		"small_pool": [
			{"name": "Iron Skin", "tags": ["armor"], "mods": [{"stat": "armor", "op": "add", "value": 12}]},
			{"name": "Heavy Blow", "tags": ["melee"], "mods": [{"stat": "damage", "op": "add", "value": 1}]},
			{"name": "Sturdy Frame", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "add", "value": 3}]}
		],
		"medium_pool": [
			{"name": "War Drills", "tags": ["melee"], "mods": [{"stat": "damage", "op": "increased_pct", "value": 8}]},
			{"name": "Blood Routine", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "increased_pct", "value": 7}]}
		],
		"notable_pool": [
			{"name": "Juggernaut Form", "tags": ["armor"], "mods": [{"stat": "armor", "op": "increased_pct", "value": 20}]},
			{"name": "Smash Doctrine", "tags": ["melee"], "mods": [{"stat": "damage", "op": "increased_pct", "value": 18}]}
		],
		"keystone_pool": [
			{"name": "Unbreakable Oath", "tags": ["armor", "life"], "mods": [{"stat": "armor", "op": "more_pct", "value": 35}, {"stat": "move_speed", "op": "add", "value": -1}]}
		]
	},
	{
		"id": "precision",
		"name": "Verdant Reach",
		"tags": ["dexterity", "ranged", "evasion"],
		"small_pool": [
			{"name": "Nimble Feet", "tags": ["speed"], "mods": [{"stat": "move_speed", "op": "add", "value": 1}]},
			{"name": "Swift Arrows", "tags": ["ranged"], "mods": [{"stat": "damage", "op": "add", "value": 1}]},
			{"name": "Leaf Guard", "tags": ["evasion"], "mods": [{"stat": "evasion", "op": "add", "value": 12}]}
		],
		"medium_pool": [
			{"name": "Kite Motion", "tags": ["speed"], "mods": [{"stat": "move_speed", "op": "increased_pct", "value": 8}]},
			{"name": "Volley Form", "tags": ["ranged"], "mods": [{"stat": "damage", "op": "increased_pct", "value": 8}]}
		],
		"notable_pool": [
			{"name": "Windline Expert", "tags": ["ranged"], "mods": [{"stat": "crit_chance", "op": "add", "value": 4}, {"stat": "damage", "op": "increased_pct", "value": 12}]},
			{"name": "Ghost Sprint", "tags": ["evasion"], "mods": [{"stat": "evasion", "op": "increased_pct", "value": 20}]}
		],
		"keystone_pool": [
			{"name": "Perfect Distance", "tags": ["ranged", "speed"], "mods": [{"stat": "damage", "op": "more_pct", "value": 28}, {"stat": "armor", "op": "add", "value": -20}]}
		]
	},
	{
		"id": "arcana",
		"name": "Azure Archive",
		"tags": ["intelligence", "spell", "mana"],
		"small_pool": [
			{"name": "Runic Memory", "tags": ["mana"], "mods": [{"stat": "max_mana", "op": "add", "value": 6}]},
			{"name": "Spark Logic", "tags": ["spell"], "mods": [{"stat": "spell_damage", "op": "add", "value": 2}]},
			{"name": "Focused Thought", "tags": ["spell"], "mods": [{"stat": "cast_speed", "op": "add", "value": 1}]}
		],
		"medium_pool": [
			{"name": "Mana Weave", "tags": ["mana"], "mods": [{"stat": "max_mana", "op": "increased_pct", "value": 10}]},
			{"name": "Channel Precision", "tags": ["spell"], "mods": [{"stat": "spell_damage", "op": "increased_pct", "value": 9}]}
		],
		"notable_pool": [
			{"name": "Arc Scholar", "tags": ["spell"], "mods": [{"stat": "cast_speed", "op": "increased_pct", "value": 16}, {"stat": "spell_damage", "op": "increased_pct", "value": 10}]},
			{"name": "Mana Bastion", "tags": ["mana"], "mods": [{"stat": "max_mana", "op": "increased_pct", "value": 25}]}
		],
		"keystone_pool": [
			{"name": "Mind Over Steel", "tags": ["mana", "defense"], "mods": [{"stat": "max_mana", "op": "more_pct", "value": 35}, {"stat": "max_hp", "op": "increased_pct", "value": -15}]}
		]
	},
	{
		"id": "vitality",
		"name": "Amber Wilds",
		"tags": ["life", "regen", "nature"],
		"small_pool": [
			{"name": "Rooted Pulse", "tags": ["regen"], "mods": [{"stat": "hp_regen", "op": "add", "value": 1}]},
			{"name": "Hardy Breath", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "add", "value": 3}]},
			{"name": "Natural Rhythm", "tags": ["utility"], "mods": [{"stat": "stamina", "op": "add", "value": 2}]}
		],
		"medium_pool": [
			{"name": "Forest Flow", "tags": ["regen"], "mods": [{"stat": "hp_regen", "op": "increased_pct", "value": 12}]},
			{"name": "Bodycraft", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "increased_pct", "value": 8}]}
		],
		"notable_pool": [
			{"name": "Enduring Bloom", "tags": ["regen"], "mods": [{"stat": "hp_regen", "op": "add", "value": 3}, {"stat": "max_hp", "op": "increased_pct", "value": 10}]},
			{"name": "Wild Tenacity", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "increased_pct", "value": 22}]}
		],
		"keystone_pool": [
			{"name": "Living Fortress", "tags": ["life"], "mods": [{"stat": "max_hp", "op": "more_pct", "value": 30}, {"stat": "cast_speed", "op": "add", "value": -2}]}
		]
	},
	{
		"id": "guile",
		"name": "Umbral Circuit",
		"tags": ["trickery", "crit", "utility"],
		"small_pool": [
			{"name": "Silent Grip", "tags": ["crit"], "mods": [{"stat": "crit_chance", "op": "add", "value": 2}]},
			{"name": "Quick Fingers", "tags": ["utility"], "mods": [{"stat": "loot_rarity", "op": "add", "value": 3}]},
			{"name": "Ambush Step", "tags": ["speed"], "mods": [{"stat": "move_speed", "op": "add", "value": 1}]}
		],
		"medium_pool": [
			{"name": "Lethal Setup", "tags": ["crit"], "mods": [{"stat": "crit_chance", "op": "increased_pct", "value": 14}]},
			{"name": "Veil Mechanics", "tags": ["utility"], "mods": [{"stat": "cooldown_recovery", "op": "increased_pct", "value": 10}]}
		],
		"notable_pool": [
			{"name": "Execution Geometry", "tags": ["crit"], "mods": [{"stat": "crit_chance", "op": "increased_pct", "value": 22}, {"stat": "damage", "op": "increased_pct", "value": 8}]},
			{"name": "Night Routine", "tags": ["speed"], "mods": [{"stat": "move_speed", "op": "increased_pct", "value": 18}]}
		],
		"keystone_pool": [
			{"name": "First Strike Law", "tags": ["crit"], "mods": [{"stat": "crit_chance", "op": "more_pct", "value": 40}, {"stat": "max_hp", "op": "increased_pct", "value": -12}]}
		]
	},
	{
		"id": "warding",
		"name": "Ivory Conclave",
		"tags": ["block", "resistance", "support"],
		"small_pool": [
			{"name": "Aegis Drill", "tags": ["block"], "mods": [{"stat": "block_chance", "op": "add", "value": 1}]},
			{"name": "Warding Mark", "tags": ["resistance"], "mods": [{"stat": "all_res", "op": "add", "value": 2}]},
			{"name": "Protective Chant", "tags": ["support"], "mods": [{"stat": "aura_power", "op": "add", "value": 2}]}
		],
		"medium_pool": [
			{"name": "Shield Pattern", "tags": ["block"], "mods": [{"stat": "block_chance", "op": "increased_pct", "value": 12}]},
			{"name": "Resonant Ward", "tags": ["resistance"], "mods": [{"stat": "all_res", "op": "increased_pct", "value": 10}]}
		],
		"notable_pool": [
			{"name": "Bulwark Doctrine", "tags": ["block"], "mods": [{"stat": "block_chance", "op": "add", "value": 4}, {"stat": "armor", "op": "increased_pct", "value": 10}]},
			{"name": "Sanctified Core", "tags": ["resistance"], "mods": [{"stat": "all_res", "op": "add", "value": 8}]}
		],
		"keystone_pool": [
			{"name": "Immutable Ward", "tags": ["block", "resistance"], "mods": [{"stat": "block_chance", "op": "more_pct", "value": 30}, {"stat": "move_speed", "op": "add", "value": -1}]}
		]
	}
]

var nodes: Dictionary = {}
var region_index: Dictionary = {}
var start_nodes: Array = []


func _init() -> void:
	_generate_tree()


func _generate_tree() -> void:
	nodes.clear()
	region_index.clear()
	start_nodes.clear()

	for region_id in range(REGION_COUNT):
		var template: Dictionary = REGION_TEMPLATES[region_id % REGION_TEMPLATES.size()]
		var region_key := String(template.get("id", "region_%d" % region_id))
		var node_ids: Array = []
		var keystone_row := region_id % REGION_ROWS

		for row in range(REGION_ROWS):
			for col in range(REGION_COLS):
				var node_id := _build_node_id(region_key, row, col)
				var node_type := _resolve_node_type(col, row, keystone_row)
				var definition := _pick_definition(template, node_type, row, col)
				var node_data := {
					"id": node_id,
					"name": definition.get("name", node_id),
					"type": node_type,
					"region": region_key,
					"region_name": template.get("name", region_key),
					"grid_pos": Vector2i(col, row),
					"tags": _merge_tags(template.get("tags", []), definition.get("tags", [])),
					"mods": definition.get("mods", []).duplicate(true),
					"adjacent": []
				}

				nodes[node_id] = node_data
				node_ids.append(node_id)
			# Keep one obvious entry point per row to simplify outside integration.
			var start_id := _build_node_id(region_key, row, 0)
			start_nodes.append(start_id)

		region_index[region_key] = node_ids

	_connect_adjacency()


func _connect_adjacency() -> void:
	for region_id in range(REGION_COUNT):
		var template: Dictionary = REGION_TEMPLATES[region_id % REGION_TEMPLATES.size()]
		var region_key := String(template.get("id", "region_%d" % region_id))

		for row in range(REGION_ROWS):
			for col in range(REGION_COLS):
				var current_id := _build_node_id(region_key, row, col)
				if not nodes.has(current_id):
					continue
				var links: Array = nodes[current_id]["adjacent"]

				if col > 0:
					_push_unique(links, _build_node_id(region_key, row, col - 1))
				if col < REGION_COLS - 1:
					_push_unique(links, _build_node_id(region_key, row, col + 1))
				if row > 0:
					_push_unique(links, _build_node_id(region_key, row - 1, col))
				if row < REGION_ROWS - 1:
					_push_unique(links, _build_node_id(region_key, row + 1, col))

				nodes[current_id]["adjacent"] = links


func _build_node_id(region_key: String, row: int, col: int) -> String:
	return "%s_r%d_c%d" % [region_key, row, col]


func _resolve_node_type(col: int, row: int, keystone_row: int) -> String:
	if col == REGION_COLS - 1 and row == keystone_row:
		return TYPE_KEYSTONE
	if col == 4 or col == 7:
		return TYPE_NOTABLE
	if col == 2 or col == 6 or col == 8:
		return TYPE_MEDIUM
	return TYPE_SMALL


func _pick_definition(template: Dictionary, node_type: String, row: int, col: int) -> Dictionary:
	var pool_name := "%s_pool" % node_type
	var pool: Array = template.get(pool_name, [])
	if pool.is_empty():
		return {"name": "Unnamed Node", "tags": [], "mods": []}
	var index := (row * REGION_COLS + col) % pool.size()
	return pool[index]


func _merge_tags(region_tags: Array, node_tags: Array) -> Array:
	var merged: Array = []
	for tag in region_tags:
		_push_unique(merged, String(tag))
	for tag in node_tags:
		_push_unique(merged, String(tag))
	return merged


func _push_unique(values: Array, value: Variant) -> void:
	if not values.has(value):
		values.append(value)


func get_node_count() -> int:
	return nodes.size()


func get_all_nodes() -> Dictionary:
	return nodes


func get_node(node_id: String) -> Dictionary:
	if not nodes.has(node_id):
		return {}
	return nodes[node_id]


func get_region_nodes(region_id: String) -> Array:
	if not region_index.has(region_id):
		return []
	return region_index[region_id]


func get_start_nodes() -> Array:
	return start_nodes.duplicate()


# Returns nodes that can be allocated from current ownership.
func get_allocatable_nodes(allocated_node_ids: Array) -> Array:
	var allocated := {}
	for node_id in allocated_node_ids:
		allocated[String(node_id)] = true

	var allocatable: Array = []
	if allocated.is_empty():
		return get_start_nodes()

	for node_id in allocated.keys():
		if not nodes.has(node_id):
			continue
		for neighbor in nodes[node_id]["adjacent"]:
			var neighbor_id := String(neighbor)
			if allocated.has(neighbor_id):
				continue
			_push_unique(allocatable, neighbor_id)
	return allocatable


# Applies allocated node modifiers onto a stats dictionary and returns a new one.
func apply_node_modifiers(base_stats: Dictionary, allocated_node_ids: Array) -> Dictionary:
	var output := base_stats.duplicate(true)

	for node_id in allocated_node_ids:
		var id := String(node_id)
		if not nodes.has(id):
			continue

		var mods: Array = nodes[id].get("mods", [])
		for mod in mods:
			var stat := String(mod.get("stat", ""))
			if stat.is_empty():
				continue
			var op := String(mod.get("op", "add"))
			var value := float(mod.get("value", 0.0))
			var current := float(output.get(stat, 0.0))

			match op:
				"add":
					output[stat] = current + value
				"increased_pct":
					output[stat] = current * (1.0 + (value / 100.0))
				"more_pct":
					output[stat] = current * (1.0 + (value / 100.0))
				"set":
					output[stat] = value
				_:
					output[stat] = current + value

	return output


func build_default_tree_data() -> Dictionary:
	return {
		"target_node_count": NODE_COUNT_TARGET,
		"node_count": get_node_count(),
		"regions": region_index.duplicate(true),
		"start_nodes": get_start_nodes(),
		"nodes": get_all_nodes()
	}
