class_name EventLog
extends RefCounted

var entries: Array[Dictionary] = []

func clear() -> void:
	entries.clear()

func record(event_type: String, message: String, data: Dictionary = {}) -> void:
	entries.append({
		"type": event_type,
		"message": message,
		"data": data.duplicate(true)
	})

func messages() -> Array[String]:
	var output: Array[String] = []
	for entry in entries:
		output.append(str(entry.get("message", "")))
	return output
