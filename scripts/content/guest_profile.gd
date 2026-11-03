extends Resource

## A regular guest and the facts the player can learn about them.

@export var id: String = ""
@export var display_name: String = ""
@export var role: String = ""
## Drink ID this guest orders. Leave empty for guests who don't order (like Churro).
@export var usual_drink: String = ""
## Small-talk topics, in the order the guest brings them up.
@export var topics: Array[Resource] = []
@export var facts: Array[Resource] = []


func fact(fact_id: String) -> Resource:
	for item: Resource in facts:
		if item.id == fact_id:
			return item
	return null


func topic(topic_id: String) -> Resource:
	for item: Resource in topics:
		if item != null and item.id == topic_id:
			return item
	return null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.strip_edges().is_empty():
		errors.append("Guest ID is required.")
	if display_name.strip_edges().is_empty():
		errors.append("Guest '%s' needs a display name." % id)
	if facts.is_empty():
		errors.append("Guest '%s' needs at least one fact." % id)
	var seen := {}
	for item: Resource in facts:
		if item == null:
			errors.append("Guest '%s' has an empty fact slot." % id)
			continue
		errors.append_array(item.validation_errors())
		if seen.has(item.id):
			errors.append("Guest '%s' has duplicate fact ID '%s'." % [id, item.id])
		seen[item.id] = true
	var topic_ids := {}
	for item: Resource in topics:
		if item == null:
			errors.append("Guest '%s' has an empty topic slot." % id)
			continue
		errors.append_array(item.validation_errors())
		if topic_ids.has(item.id):
			errors.append("Guest '%s' has duplicate topic ID '%s'." % [id, item.id])
		topic_ids[item.id] = true
	for item: Resource in facts:
		if item != null and item.unlock == item.Unlock.TOPIC and not item.target.is_empty() and not topic_ids.has(item.target):
			errors.append("Fact '%s' is unlocked by topic '%s', which guest '%s' never brings up." % [item.id, item.target, id])
	for item: Resource in facts:
		if item == null or item.requires.is_empty():
			continue
		if not seen.has(item.requires):
			errors.append("Fact '%s' requires unknown fact '%s'." % [item.id, item.requires])
		elif _has_cycle(item):
			errors.append("Fact '%s' is part of a requirement cycle." % item.id)
	return errors


func _has_cycle(start: Resource) -> bool:
	var visited := {}
	var current := start
	while current != null and not current.requires.is_empty():
		if visited.has(current.id):
			return true
		visited[current.id] = true
		current = fact(current.requires)
	return false
