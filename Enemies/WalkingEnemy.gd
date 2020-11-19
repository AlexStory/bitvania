extends Enemy


enum DIRECTION {
	LEFT = -1,
	RIGHT = 1,
}

export(DIRECTION) var walking_direction

onready var state = walking_direction
onready var sprite := $Sprite
onready var floor_left := $FloorLeft
onready var floor_right := $FloorRight
onready var wall_left := $WallLeft
onready var wall_right := $WallRight

func _ready() -> void:
	motion.y = 8

func _physics_process(_delta: float) -> void:
	match state:
		DIRECTION.LEFT:
			motion.x = -MAX_SPEED
			if not floor_left.is_colliding() or wall_left.is_colliding():
				state = DIRECTION.RIGHT
		DIRECTION.RIGHT:
			motion.x = MAX_SPEED
			if not floor_right.is_colliding() or wall_right.is_colliding():
				state = DIRECTION.LEFT
	
	sprite.scale.x = sign(motion.x)
	motion = move_and_slide_with_snap(motion, Vector2.DOWN * 4, Vector2.UP, true)
	


