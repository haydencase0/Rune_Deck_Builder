class_name DefeatResolver
extends RefCounted

static func determine_result(resources: Array[Dictionary]) -> Dictionary:
	var player_one_defeated := int(resources[0]["health"]) <= 0
	var player_two_defeated := int(resources[1]["health"]) <= 0
	if player_one_defeated and player_two_defeated:
		var player_one_loss := int(resources[0].get("life_lost", 0))
		var player_two_loss := int(resources[1].get("life_lost", 0))
		if player_one_loss == player_two_loss:
			return {"winner": -1, "result": "tie", "reason": "Both players lost the same amount of life."}
		return {"winner": 0 if player_one_loss < player_two_loss else 1, "result": "win", "reason": "Simultaneous defeat resolved by total life lost."}
	if player_one_defeated:
		return {"winner": 1, "result": "win", "reason": "Player 1 reached zero health."}
	if player_two_defeated:
		return {"winner": 0, "result": "win", "reason": "Player 2 reached zero health."}
	return {"winner": -1, "result": "continue", "reason": "Both players survived the sequence."}
