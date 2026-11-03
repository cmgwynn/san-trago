extends RefCounted

const SECONDS_PER_UNIT: float = 0.65
var ingredient: String = ""
var elapsed: float = 0.0


func start(value: String) -> void:
	ingredient = value
	elapsed = 0.0


func stop() -> void:
	ingredient = ""
	elapsed = 0.0


func advance(delta: float) -> int:
	if ingredient.is_empty():
		return 0
	elapsed += delta
	var units := int(elapsed / SECONDS_PER_UNIT)
	elapsed -= units * SECONDS_PER_UNIT
	return units


func progress() -> float:
	return elapsed / SECONDS_PER_UNIT
