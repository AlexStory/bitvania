extends Enemy

export(int) var acceleration = 100

var instances: MainInstances = ResLoader.MainInstances

onready var sprite := $Sprite

var state := IDLE

enum { CHASE, IDLE }


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	var player: Player = instances.Player
	if player != null:
		chase_player(player, delta)


func chase_player(player: Player, delta: float) -> void:
	var direction := (player.global_position - global_position).normalized()
	motion += direction * acceleration * delta
	motion = motion.clamped(MAX_SPEED)
	sprite.flip_h = global_position > player.global_position
	motion = move_and_slide(motion)




func _on_VisibilityNotifier2D_screen_entered():
	set_physics_process(true)
