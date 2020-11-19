extends Node2D
class_name Projectile

const ExplosionEffect := preload("res://Effects/ExplosionEffect.tscn")

var velocity = Vector2.ZERO

func _process(delta):
	position += velocity * delta


func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()


func _on_Hitbox_body_entered(_body):
	queue_free()
	explode()


func _on_Hitbox_area_entered(_area):
	queue_free()
	explode()


func explode():
	var _explosion = Utils.instance_scene_on_main(ExplosionEffect, global_position)
