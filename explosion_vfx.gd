extends Node3D

@onready var light = $OmniLight3D
@onready var sparks = $Sparks
@onready var smoke = $Smoke

func _ready():
	sparks.emitting = true
	smoke.emitting = true
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.3)
	await get_tree().create_timer(2.0).timeout
	queue_free()
