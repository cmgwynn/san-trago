extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var draft_units: int = 0
@export var rum_units: int = 0
@export var cola_units: int = 0


func quantities() -> Dictionary:
	return {"draft": draft_units, "rum": rum_units, "cola": cola_units}


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.strip_edges().is_empty():
		errors.append("Recipe ID is required.")
	if display_name.strip_edges().is_empty():
		errors.append("Recipe display name is required.")
	if draft_units < 0 or rum_units < 0 or cola_units < 0:
		errors.append("Ingredient quantities cannot be negative.")
	if draft_units + rum_units + cola_units == 0:
		errors.append("Recipe must contain at least one measured unit.")
	return errors
