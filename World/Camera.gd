extends Camera2D

var shake = 0

onready var timer = $Timer

func _ready():
	var _status = Events.connect("add_screen_shake", self, "_on_events_add_screen_shake")
	
	
func _process(_delta):
	offset_h = rand_range(-shake, shake)
	offset_v = rand_range(-shake, shake)
	

func screen_shake(amount, duration) -> void:
	shake = amount
	timer.wait_time = duration
	timer.start()


func _on_Timer_timeout():
	shake = 0


func _on_events_add_screen_shake(amount: float, duration: float) -> void:
	screen_shake(amount, duration)
