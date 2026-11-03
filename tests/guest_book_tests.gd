extends SceneTree

const Book = preload("res://scripts/systems/guest_book.gd")
const Profile = preload("res://scripts/content/guest_profile.gd")
const Fact = preload("res://scripts/content/guest_fact.gd")
const Topic = preload("res://scripts/content/guest_topic.gd")
const Catalog = preload("res://scripts/content/content_catalog.gd")

var checks: int = 0
var failures: int = 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	call_deferred("_run")


func make_fact(id: String, unlock: int, count: int = 1, target: String = "", requires: String = "", hint: String = "") -> Resource:
	var fact := Fact.new()
	fact.id = id
	fact.text = "Fact " + id
	fact.unlock = unlock
	fact.count = count
	fact.target = target
	fact.requires = requires
	fact.hint = hint
	return fact


func make_guest(id: String, facts: Array[Resource]) -> Resource:
	var guest := Profile.new()
	guest.id = id
	guest.display_name = id.capitalize()
	guest.facts = facts
	for fact: Resource in facts:
		if fact.unlock == Fact.Unlock.TOPIC and guest.topic(fact.target) == null:
			var topic := Topic.new()
			topic.id = fact.target
			topic.line = "About %s." % fact.target
			guest.topics.append(topic)
	return guest


func _run() -> void:
	_content()
	_unlocking()
	_saving()
	_validation()
	print("Guest book checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _content() -> void:
	var loaded: Array[Resource] = Catalog.load_dir(Catalog.GUESTS_DIR)
	var drinks: Array[Resource] = Catalog.load_dir(Catalog.DRINKS_DIR)
	expect(loaded.size() >= 3, "the catalog finds every guest file")
	var errors := Catalog.validation_errors(drinks, loaded)
	expect(errors.is_empty(), "all guest and drink content validates: %s" % [errors])
	for guest: Resource in loaded:
		expect(not guest.topics.is_empty(), "%s has something to talk about" % guest.id)
	var book := Book.new(loaded)
	expect(book.unread_count() == 0, "a fresh book has nothing to read")
	var first: Array[String] = book.record_visit("maya")
	expect(first.is_empty(), "one visit unlocks nothing for Maya")
	expect(book.record_serve("maya", "rum_cola", true) == ["usual"], "serving her usual unlocks it")
	expect(book.record_visit("maya") == ["tower"], "second visit unlocks the tower fact")
	expect(book.record_serve("maya", "rum_cola", true) == ["quarters"], "second perfect serve unlocks quarters")
	var entries: Array[Dictionary] = book.page("maya")
	expect(entries.size() == 5 and entries[0].known and entries[0].new, "page lists facts in authored order with new flags")
	expect(entries[3].text == "???" and entries[3].hint == "Ask about the pier", "locked topic facts show the authored hint")
	expect(entries[4].hint == "Learn more about them first", "chained facts hint at their prerequisite")


func _unlocking() -> void:
	var guest := make_guest("ana", [
		make_fact("visits", Fact.Unlock.VISITS, 3),
		make_fact("drink", Fact.Unlock.SERVED_DRINK, 2, "draft_beer"),
		make_fact("topic", Fact.Unlock.TOPIC, 1, "boats", "", "Ask about boats"),
		make_fact("chain_b", Fact.Unlock.VISITS, 1, "", "chain_a"),
		make_fact("chain_a", Fact.Unlock.TOPIC, 1, "boats", "", "Ask about boats"),
		make_fact("perfect", Fact.Unlock.PERFECT_SERVES, 2),
	])
	var book := Book.new([guest])
	expect(book.record_visit("nobody").is_empty(), "unknown guests are ignored")
	expect(book.record_serve("nobody", "draft_beer", true).is_empty(), "unknown guest serves are ignored")
	expect(book.record_visit("ana").is_empty(), "below threshold unlocks nothing")
	expect(book.page("ana")[0].hint == "Visits 2 more times", "generated hint counts down")
	book.record_visit("ana")
	expect(book.page("ana")[0].hint == "Visits once more", "generated hint uses singular")
	expect(book.record_visit("ana") == ["visits"], "threshold unlocks exactly once")
	expect(book.record_visit("ana").is_empty(), "known facts never unlock twice")
	expect(book.record_serve("ana", "rum_cola", false).is_empty(), "wrong drink does not count")
	expect(book.record_serve("ana", "draft_beer", false).is_empty(), "one of two drinks is not enough")
	expect(book.record_serve("ana", "draft_beer", false) == ["drink"], "second matching drink unlocks")
	expect(book.page("ana")[5].hint == "Serve perfectly 2 more times", "imperfect serves do not count as perfect")
	var chained: Array[String] = book.record_topic("ana", "boats")
	expect(chained == ["topic", "chain_a", "chain_b"], "a chain unlocks in the same event, prerequisite first: %s" % [chained])
	expect(book.unread_count("ana") == 5 and book.unread_count() == 5, "every unlock is unread")
	book.mark_read("ana")
	expect(book.unread_count() == 0 and book.known_count("ana") == 5, "reading clears new flags but keeps facts")
	expect(book.record_topic("ana", "boats").is_empty(), "repeating a topic unlocks nothing new")


func _saving() -> void:
	var facts: Array[Resource] = [make_fact("a", Fact.Unlock.VISITS, 1), make_fact("b", Fact.Unlock.VISITS, 2)]
	var book := Book.new([make_guest("ana", facts)])
	book.record_visit("ana")
	var saved: Dictionary = book.to_dict()
	var restored := Book.new([make_guest("ana", facts)])
	expect(restored.load_dict(saved).is_empty(), "round trip has no warnings")
	expect(restored.is_known("ana", "a") and restored.unread_count("ana") == 1, "known and unread facts survive a save")
	expect(restored.record_visit("ana") == ["b"], "counters survive a save")
	saved.guests.ana.known.append("removed")
	saved.guests["ghost"] = {"visits": 3}
	var warnings: PackedStringArray = Book.new([make_guest("ana", facts)]).load_dict(saved)
	expect(warnings.size() == 2, "removed content is dropped with warnings: %s" % [warnings])
	var grown: Array[Resource] = [make_fact("a", Fact.Unlock.VISITS, 1), make_fact("b", Fact.Unlock.VISITS, 2), make_fact("c", Fact.Unlock.VISITS, 1)]
	var updated := Book.new([make_guest("ana", grown)])
	updated.load_dict(book.to_dict())
	expect(updated.is_known("ana", "c"), "newly authored facts that are already earned unlock on load")
	expect(not Book.new([]).load_dict({"version": 99}).is_empty(), "unknown save versions are rejected")
	var mutated: Dictionary = book.to_dict()
	mutated.guests.ana.visits = 50
	expect(book.progress.ana.visits == 1, "save data is a copy, not live state")


func _validation() -> void:
	expect(not Profile.new().validation_errors().is_empty(), "empty guest is invalid")
	var bad := make_guest("bad", [
		make_fact("dup", Fact.Unlock.VISITS),
		make_fact("dup", Fact.Unlock.VISITS),
		make_fact("no_target", Fact.Unlock.SERVED_DRINK),
		make_fact("no_hint", Fact.Unlock.TOPIC, 1, "x"),
		make_fact("zero", Fact.Unlock.VISITS, 0),
		make_fact("orphan", Fact.Unlock.VISITS, 1, "", "missing"),
	])
	var errors: PackedStringArray = bad.validation_errors()
	for needle: String in ["duplicate", "target", "authored hint", "at least 1", "unknown fact"]:
		var found := false
		for error: String in errors:
			found = found or error.contains(needle)
		expect(found, "validation reports '%s'" % needle)
	var loop := make_guest("loop", [make_fact("x", Fact.Unlock.VISITS, 1, "", "y"), make_fact("y", Fact.Unlock.VISITS, 1, "", "x")])
	var cycle_found := false
	for error: String in loop.validation_errors():
		cycle_found = cycle_found or error.contains("cycle")
	expect(cycle_found, "requirement cycles are rejected")
	var silent := make_guest("silent", [make_fact("secret", Fact.Unlock.TOPIC, 1, "boats", "", "Ask about boats")])
	silent.topics.clear()
	var blank := Topic.new()
	silent.topics.append(blank)
	silent.topics.append(blank)
	for needle: String in ["never brings up", "Topic ID is required", "needs a line", "duplicate topic"]:
		var found := false
		for error: String in silent.validation_errors():
			found = found or error.contains(needle)
		expect(found, "topic validation reports '%s'" % needle)
