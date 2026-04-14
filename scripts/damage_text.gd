extends Label3D

func display(amount: int, start_pos: Vector3):
	text = str(amount)
	global_position = start_pos
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	global_position += Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
	var tween = create_tween().set_parallel(true)
	var target_y = global_position.y + 2.0
	tween.tween_property(self, "global_position:y", target_y, 1.0)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.chain().finished.connect(queue_free)
