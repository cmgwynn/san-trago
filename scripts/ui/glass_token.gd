extends Button

var drag_enabled: bool = false


func _get_drag_data(_position: Vector2) -> Variant:
	if not drag_enabled or disabled:
		return null
	var preview := Label.new()
	preview.text = "[ GLASS ]"
	preview.add_theme_font_size_override("font_size", 24)
	set_drag_preview(preview)
	return {"kind": "lab_glass", "source": self}
