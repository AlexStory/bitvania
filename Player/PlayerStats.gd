extends Resource
class_name PlayerStats

signal player_died

var max_health = 4
var health = max_health setget set_health


func set_health(value: int) -> void:
	if (value < health):
		Events.emit_signal("add_screen_shake", 0.5, 0.5)
	health = clamp(value, 0, max_health)
	if health == 0:
		emit_signal("player_died")
