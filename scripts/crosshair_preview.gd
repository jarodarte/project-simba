extends Control

var length: float = 10.0
var thickness: float = 3.0
var gap: float = 3.0
var color: Color = Color.GREEN

func _draw() -> void:
	var center = size / 2.0
	
	# Right
	draw_rect(Rect2(center.x + gap, center.y - thickness / 2.0, length, thickness), color)
	# Left
	draw_rect(Rect2(center.x - gap - length, center.y - thickness / 2.0, length, thickness), color)
	# Up
	draw_rect(Rect2(center.x - thickness / 2.0, center.y - gap - length, thickness, length), color)
	# Down
	draw_rect(Rect2(center.x - thickness / 2.0, center.y + gap, thickness, length), color)

func update_preview(new_length: float, new_thickness: float, new_gap: float, new_color: Color) -> void:
	length = new_length
	thickness = new_thickness
	gap = new_gap
	color = new_color
	queue_redraw()
