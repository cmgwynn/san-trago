extends RefCounted

## Finds content by folder, so adding a drink or guest needs no code changes:
## save a new .tres in content/drinks or content/guests and it is picked up.
## A file's name must match its ID (rum_cola.tres has id "rum_cola").

const DRINKS_DIR := "res://content/drinks"
const GUESTS_DIR := "res://content/guests"


## Every resource in a folder, sorted by file name. Works in exported builds too.
static func load_dir(dir: String) -> Array[Resource]:
	var files := PackedStringArray()
	for file: String in ResourceLoader.list_directory(dir):
		if file.get_extension() in ["tres", "res"]:
			files.append(file)
	files.sort()
	var found: Array[Resource] = []
	for file: String in files:
		var resource: Resource = load(dir.path_join(file))
		if resource != null:
			found.append(resource)
	return found


static func by_id(resources: Array[Resource]) -> Dictionary:
	var table := {}
	for resource: Resource in resources:
		table[resource.id] = resource
	return table


## Problems across all content: each item's own checks, file names matching IDs,
## duplicate IDs, and guests that reference drinks that don't exist.
static func validation_errors(drinks: Array[Resource], guests: Array[Resource]) -> PackedStringArray:
	var errors := PackedStringArray()
	var drink_ids := {}
	for group: Array[Resource] in [drinks, guests]:
		var seen := {}
		for item: Resource in group:
			errors.append_array(item.validation_errors())
			var file_id := item.resource_path.get_file().get_basename()
			if not item.resource_path.is_empty() and file_id != item.id:
				errors.append("%s has ID '%s'; rename the file or the ID so they match." % [item.resource_path.get_file(), item.id])
			if seen.has(item.id):
				errors.append("Two files use the ID '%s'." % item.id)
			seen[item.id] = true
		if group == drinks:
			drink_ids = seen
	for guest: Resource in guests:
		if not guest.usual_drink.is_empty() and not drink_ids.has(guest.usual_drink):
			errors.append("Guest '%s' orders '%s', which isn't in content/drinks." % [guest.id, guest.usual_drink])
		for fact: Resource in guest.facts:
			if fact != null and fact.unlock == fact.Unlock.SERVED_DRINK and not drink_ids.has(fact.target):
				errors.append("Fact '%s' on '%s' needs drink '%s', which isn't in content/drinks." % [fact.id, guest.id, fact.target])
	return errors
