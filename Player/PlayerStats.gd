extends Resource
class_name PlayerStats

signal player_died
signal player_health_changed(value)

var max_health = 4
var health = max_health setget set_health


func set_health(value: int) -> void:
	if (value < health):
		Events.emit_signal("add_screen_shake", 0.5, 0.5)
	health = clamp(value, 0, max_health)
	emit_signal("player_health_changed", health)
	if health == 0:
		emit_signal("player_died")
