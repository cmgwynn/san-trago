extends RefCounted

## Tracks what the player has learned about each regular.
## Gameplay reports events (visits, serves, small-talk topics); facts unlock when
## their conditions are met. Pure logic: no nodes, no UI, deterministic.

const Fact = preload("res://scripts/content/guest_fact.gd")
const SAVE_VERSION: int = 1

var profiles: Dictionary = {}
var progress: Dictionary = {}


func _init(guest_profiles: Array = []) -> void:
	for profile: Resource in guest_profiles:
		profiles[profile.id] = profile
		progress[profile.id] = _blank()


func _blank() -> Dictionary:
	return {"visits": 0, "perfect": 0, "drinks": {}, "topics": {}, "known": [], "unread": []}


func has_guest(guest_id: String) -> bool:
	return profiles.has(guest_id)


func record_visit(guest_id: String) -> Array[String]:
	if not has_guest(guest_id):
		return []
	progress[guest_id].visits += 1
	return _evaluate(guest_id)


func record_serve(guest_id: String, drink_id: String, perfect: bool) -> Array[String]:
	if not has_guest(guest_id):
		return []
	var state: Dictionary = progress[guest_id]
	state.drinks[drink_id] = int(state.drinks.get(drink_id, 0)) + 1
	if perfect:
		state.perfect += 1
	return _evaluate(guest_id)


func record_topic(guest_id: String, topic_id: String) -> Array[String]:
	if not has_guest(guest_id):
		return []
	progress[guest_id].topics[topic_id] = true
	return _evaluate(guest_id)


## Unlocks every satisfied fact in authored order. Repeats so a chained fact can
## unlock in the same event as the fact it requires.
func _evaluate(guest_id: String) -> Array[String]:
	var unlocked: Array[String] = []
	var state: Dictionary = progress[guest_id]
	var changed := true
	while changed:
		changed = false
		for fact: Resource in profiles[guest_id].facts:
			if state.known.has(fact.id) or not _met(fact, state):
				continue
			state.known.append(fact.id)
			state.unread.append(fact.id)
			unlocked.append(fact.id)
			changed = true
	return unlocked


func _met(fact: Resource, state: Dictionary) -> bool:
	if not fact.requires.is_empty() and not state.known.has(fact.requires):
		return false
	return _current(fact, state) >= fact.count


func _current(fact: Resource, state: Dictionary) -> int:
	match fact.unlock:
		Fact.Unlock.VISITS:
			return state.visits
		Fact.Unlock.PERFECT_SERVES:
			return state.perfect
		Fact.Unlock.SERVED_DRINK:
			return int(state.drinks.get(fact.target, 0))
		Fact.Unlock.TOPIC:
			return 1 if state.topics.has(fact.target) else 0
	return 0


func is_known(guest_id: String, fact_id: String) -> bool:
	return has_guest(guest_id) and progress[guest_id].known.has(fact_id)


func known_count(guest_id: String) -> int:
	return progress[guest_id].known.size() if has_guest(guest_id) else 0


func unread_count(guest_id: String = "") -> int:
	if not guest_id.is_empty():
		return progress[guest_id].unread.size() if has_guest(guest_id) else 0
	var total := 0
	for id: String in progress:
		total += progress[id].unread.size()
	return total


func mark_read(guest_id: String) -> void:
	if has_guest(guest_id):
		progress[guest_id].unread.clear()


## One entry per fact, in authored order, ready for a page in the book.
func page(guest_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not has_guest(guest_id):
		return entries
	var state: Dictionary = progress[guest_id]
	for fact: Resource in profiles[guest_id].facts:
		var known: bool = state.known.has(fact.id)
		entries.append({
			"id": fact.id,
			"known": known,
			"new": state.unread.has(fact.id),
			"text": fact.text if known else "???",
			"hint": "" if known else hint_for(guest_id, fact),
		})
	return entries


func hint_for(guest_id: String, fact: Resource) -> String:
	if not fact.hint.is_empty():
		return fact.hint
	var state: Dictionary = progress[guest_id]
	if not fact.requires.is_empty() and not state.known.has(fact.requires):
		return "Learn more about them first"
	var left: int = max(fact.count - _current(fact, state), 0)
	var times := "once more" if left == 1 else "%d more times" % left
	match fact.unlock:
		Fact.Unlock.VISITS:
			return "Visits %s" % times
		Fact.Unlock.PERFECT_SERVES:
			return "Serve perfectly %s" % times
		Fact.Unlock.SERVED_DRINK:
			return "Serve their %s %s" % [fact.target.replace("_", " "), times]
	return "Keep chatting"


func to_dict() -> Dictionary:
	return {"version": SAVE_VERSION, "guests": progress.duplicate(true)}


## Restores saved progress. Unknown guests or facts (removed content) are dropped,
## and newly authored facts that are already satisfied unlock on load.
func load_dict(data: Dictionary) -> PackedStringArray:
	var warnings := PackedStringArray()
	if int(data.get("version", 0)) != SAVE_VERSION:
		warnings.append("Unsupported guest book save version.")
		return warnings
	var guests: Dictionary = data.get("guests", {})
	for guest_id: String in guests:
		if not has_guest(guest_id):
			warnings.append("Dropped progress for unknown guest '%s'." % guest_id)
			continue
		var saved: Dictionary = guests[guest_id]
		var state := _blank()
		state.visits = max(int(saved.get("visits", 0)), 0)
		state.perfect = max(int(saved.get("perfect", 0)), 0)
		var drinks: Dictionary = saved.get("drinks", {})
		for drink_id: String in drinks:
			state.drinks[drink_id] = max(int(drinks[drink_id]), 0)
		var topics: Dictionary = saved.get("topics", {})
		for topic_id: String in topics:
			state.topics[topic_id] = true
		for key: String in ["known", "unread"]:
			for fact_id: String in saved.get(key, []):
				if profiles[guest_id].fact(fact_id) == null:
					if key == "known":
						warnings.append("Dropped unknown fact '%s' for '%s'." % [fact_id, guest_id])
				elif not state[key].has(fact_id) and (key == "known" or state.known.has(fact_id)):
					state[key].append(fact_id)
		progress[guest_id] = state
		_evaluate(guest_id)
	return warnings
