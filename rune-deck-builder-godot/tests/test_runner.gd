extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var results := [DeckTests.run(), SequenceTests.run(), MatchTests.run(), ComputerTests.run(), RoundTests.run(), ResolutionTests.run(), ManaTests.run()]
	results.append(await BattleScreenTests.run(self))
	var all_passed := true
	for result in results:
		print("[%s] %s — %s" % ["PASS" if result["passed"] else "FAIL", result["name"], result["details"]])
		all_passed = all_passed and result["passed"]
	print("Rune Roguelike smoke tests: %s" % ("PASS" if all_passed else "FAIL"))
	quit(0 if all_passed else 1)
