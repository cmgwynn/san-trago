extends Button

signal glass_docked
var docking_enabled: bool = false


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return docking_enabled and not disabled and data is Dictionary \
		and data.get("kind") == "lab_glass" and is_instance_valid(data.get("source")) \
		and data.source.drag_enabled


func _drop_data(position: Vector2, data: Variant) -> void:
	if _can_drop_data(position, data):
		glass_docked.emit()
