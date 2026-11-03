extends Resource

## Something a guest brings up in small talk. Chatting about it reports the topic ID
## to the guest book, which unlocks any TOPIC fact that targets this ID.

@export var id: String = ""
## What the guest says when they bring the topic up.
@export_multiline var line: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.strip_edges().is_empty():
		errors.append("Topic ID is required.")
	if line.strip_edges().is_empty():
		errors.append("Topic '%s' needs a line." % id)
	return errors
