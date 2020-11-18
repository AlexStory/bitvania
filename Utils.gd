extends Node

func instance_scene_on_main(scene: PackedScene, position: Vector2):
	var instance = scene.instance()
	var main = get_tree().current_scene
	instance.global_position = position
	main.call_deferred("add_child", instance)
	return instance
