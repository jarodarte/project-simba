extends Node3D

var current_lookat = null
@onready var raycast = get_parent().get_node("Camera3D/RayCast3D")

func check_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var target = collider.get_parent() if collider else null  
		if target and target.has_method("show_info"):
			if current_lookat != target:
				if current_lookat and current_lookat.has_method("hide_info"):
					current_lookat.hide_info()
				current_lookat = target
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
