extends KinematicBody2D

export(int) var ACCELERATION = 512
export(int) var MAX_SPEED = 64
export(float) var friction = 0.25

var motion = Vector2.ZERO


func _physics_process(_delta) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
