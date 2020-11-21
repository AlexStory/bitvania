extends Control
class_name HealthMeter

onready var full: TextureRect = $Full

var PlayerStats = ResLoader.PlayerStats

func _ready():
	PlayerStats.connect("player_health_changed", self, "on_player_health_changed")
	
	
func on_player_health_changed(value: int) -> void:
	full.rect_size.x = full.texture.get_width() * value + 1
