extends Area2D
class_name Hitbox

export(int) var damage = 1


func _on_Hitbox_area_entered(hurtbox: Hurtbox):
	hurtbox.emit_signal("hit", damage)
