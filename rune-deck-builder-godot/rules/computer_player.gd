class_name ComputerPlayer
extends RefCounted

## Chooses a repeatable move without changing the hand or board.
func choose_placement(hand: HandManager, board: Array) -> Dictionary:
	var hand_index := -1
	for index in range(hand.slots.size()):
		if not hand.slots[index].is_empty():
			hand_index = index
			break
	if hand_index == -1:
		return {}
	for slot_index in range(board.size()):
		if board[slot_index].is_empty():
			return {"hand_index": hand_index, "slot_index": slot_index}
	return {}
