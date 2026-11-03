extends Resource

## One thing the player can learn about a guest. Unlocks once its condition is met
## (and its required fact, if any, is already known).

enum Unlock { VISITS, PERFECT_SERVES, SERVED_DRINK, TOPIC }

@export var id: String = ""
@export_multiline var text: String = ""
@export var unlock: Unlock = Unlock.VISITS
## Drink ID for SERVED_DRINK, topic ID for TOPIC; unused otherwise.
@export var target: String = ""
@export var count: int = 1
## Optional ID of another fact on the same guest that must be known first.
@export var requires: String = ""
## Shown while locked. Leave empty to generate one from the condition.
@export var hint: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.strip_edges().is_empty():
		errors.append("Fact ID is required.")
	if text.strip_edges().is_empty():
		errors.append("Fact '%s' needs text." % id)
	if count < 1:
		errors.append("Fact '%s' count must be at least 1." % id)
	if (unlock == Unlock.SERVED_DRINK or unlock == Unlock.TOPIC) and target.strip_edges().is_empty():
		errors.append("Fact '%s' needs a target drink or topic." % id)
	if unlock == Unlock.TOPIC and hint.strip_edges().is_empty():
		errors.append("Fact '%s' is unlocked by a topic, so it needs an authored hint." % id)
	return errors
