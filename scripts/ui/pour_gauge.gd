extends Control

var amount: float = 0.0
var target: float = 0.0
var tolerance: float = 0.25


func _draw() -> void:
	var maximum := maxf(target + 1.0, amount + 0.2)
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color("#253e44"))
	if target > 0.0:
		var start := (target - tolerance) / maximum * size.x
		var width := tolerance * 2.0 / maximum * size.x
		draw_rect(Rect2(start, 0, width, size.y), Color("#46776a"))
	var fill := amount / maximum * size.x
	draw_rect(Rect2(0, size.y * 0.4, fill, size.y * 0.6), Color("#f5cd76"))
	if target > 0.0:
		for boundary: float in [target - tolerance, target + tolerance]:
			var x := boundary / maximum * size.x
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color.WHITE, 2.0)
	draw_rect(area, Color("#a3b9b6"), false, 1.0)
