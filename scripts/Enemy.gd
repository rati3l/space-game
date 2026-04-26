extends Node2D

signal died(enemy: Node2D)

@export var max_health: int = 10
@export var health: int = 10

@onready var health_bar: ProgressBar = $HealthBar

var _dead: bool = false


func _ready() -> void:
	health = clamp(health, 0, max_health)
	_dead = health <= 0
	update_health_bar()


func initialize_stats(new_max_health: int, new_health: int = -1) -> void:
	max_health = max(1, new_max_health)
	if new_health < 0:
		health = max_health
	else:
		health = clamp(new_health, 0, max_health)
	_dead = health <= 0
	update_health_bar()


func take_damage(amount: int) -> void:
	if _dead:
		return

	health = max(0, health - max(0, amount))
	update_health_bar()

	if health <= 0:
		_dead = true
		died.emit(self)


func heal(amount: int) -> void:
	if _dead:
		return

	health = min(max_health, health + max(0, amount))
	update_health_bar()


func is_dead() -> bool:
	return _dead


func update_health_bar(current_health: float = -1.0, max_health_value: float = -1.0) -> void:
	if not is_instance_valid(health_bar):
		return
	if max_health_value >= 0.0:
		health_bar.max_value = max(1.0, max_health_value)
	else:
		health_bar.max_value = max_health
	if current_health >= 0.0:
		health_bar.value = clamp(current_health, 0.0, health_bar.max_value)
	else:
		health_bar.value = health
	var ratio := 0.0
	if health_bar.max_value > 0.0:
		ratio = health_bar.value / health_bar.max_value
	health_bar.modulate = Color(1.0, 0.55 + ratio * 0.35, 0.8 + ratio * 0.2, 0.98)
