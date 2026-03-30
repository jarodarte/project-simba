extends Node

var current_lookat = null
@export var raycast: RayCast3D

func check_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("show_info"):
			if current_lookat != collider:
				if current_lookat and current_lookat.has_method("hide_info"):
					current_lookat.hide_info()
				current_lookat = collider
				current_lookat.show_info()
		else:
			_clear_current_lookat()
	else:
		_clear_current_lookat()

func _clear_current_lookat():
	if current_lookat:
		if is_instance_valid(current_lookat) and current_lookat.has_method("hide_info"):
			current_lookat.hide_info()
		current_lookat = null
