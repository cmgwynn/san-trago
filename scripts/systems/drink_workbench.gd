extends RefCounted

const INGREDIENTS: Array[String] = ["draft", "rum", "cola"]

var has_glass: bool = false
var contents: Dictionary = {}


func select_glass() -> String:
	if has_glass:
		return "A glass is already on the counter."
	has_glass = true
	contents.clear()
	return ""


func add_unit(ingredient: String) -> String:
	return add_amount(ingredient, 1.0)


func add_amount(ingredient: String, amount: float) -> String:
	if ingredient not in INGREDIENTS:
		return "Unknown ingredient: %s." % ingredient
	if not has_glass:
		return "Select a clean glass before pouring."
	if not is_finite(amount) or amount <= 0.0:
		return "Pour amount must be finite and positive."
	contents[ingredient] = float(contents.get(ingredient, 0.0)) + amount
	return ""


func check_recipe(required: Dictionary, tolerance: float = 0.0) -> String:
	if not has_glass:
		return "Select a clean glass before serving."
	var differences := PackedStringArray()
	for ingredient: String in INGREDIENTS:
		var actual := float(contents.get(ingredient, 0.0))
		var expected := float(required.get(ingredient, 0.0))
		var allowed := tolerance if expected > 0.0 else 0.0
		if actual < expected - allowed - 0.00001:
			differences.append("Add %s %s." % [_amount_text(expected - actual), ingredient])
		elif actual > expected + allowed + 0.00001:
			differences.append("Too much %s: %s extra. Discard and start again." % [ingredient, _amount_text(actual - expected)])
	return " ".join(differences)


func _amount_text(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(roundi(amount))
	return String.num(amount, 2)


func clear_glass() -> void:
	has_glass = false
	contents.clear()
