class_name RuneDefinitions
extends RefCounted

const SLOT_COUNT := 7
const RULES := {
	"starting_health": 100, "starting_mana": 0, "starting_sanity": 50,
	"hand_size": 10, "rerolls": 4, "bonus_rerolls": 3,
	"mana_limit": 100, "sanity_limit": 100
}

const RUNE_POOL := [
	"secondstrike", "vitalshot", "evenstrike", "ultimatum", "roar", "poison", "blind", "bloodlet", "bandage", "dodge", "blindstrike",
	"drink", "cancel", "copy", "swap", "scry", "ward", "anchor", "burn", "siphon", "boast", "inspiration",
	"negate", "echo", "flatter", "traumatize", "lie", "investigate", "dictate", "reiterate", "outwit", "mend", "counsel",
	"bite", "ponder", "study", "mirror"
]

static func _r(key: String, name: String, symbol: String, family: String, health: int, mana: int, sanity: int, text: String) -> Dictionary:
	return {"key": key, "id": key, "name": name, "symbol": symbol, "mark": symbol, "family": family,
		"cost": {"health": health, "mana": mana, "sanity": sanity}, "text": text}

static func catalog() -> Dictionary:
	var c := {}
	var rows := [
		["secondstrike","Second Strike","Ⅱ","body",2,0,0,"Deal 2 physical damage; contiguous pairs deal 8 each."], ["vitalshot","Vital Shot","⟐","body",6,0,0,"Deal 12 physical damage."], ["evenstrike","Even Strike","∷","body",2,0,0,"Slots 2, 4, and 6 deal rising damage."], ["ultimatum","Ultimatum","⚑","body",6,0,0,"Deal 10 damage alone, otherwise 2."], ["roar","Roar","ᚨ","body",4,0,0,"Reduce opposing mana by 5 and sanity by 7."], ["poison","Poison","ᛝ","body",4,0,0,"Reduce opposing mana by 10."], ["blind","Blind","ᚧ","body",4,0,0,"Reduce opposing sanity by 14."], ["bloodlet","Bloodlet","ᛒ","body",12,0,0,"Inflict a persistent bleed, or heal 6 if already bleeding."], ["bandage","Bandage","᛭","body",0,0,0,"Restore 4 health."], ["dodge","Dodge","ᚴ","body",0,0,0,"Avoid physical damage from this mirrored slot."], ["blindstrike","Blind Strike","ᛪ","body",8,0,0,"Become a random keeper replica."],
		["drink","Drink","ᚢ","soul",0,0,0,"Gain 10 mana on placement and trigger."], ["cancel","Cancel","⊘","soul",0,5,0,"Disable the mirrored opposing rune."], ["copy","Copy","⧉","soul",0,5,0,"Become a replica of the previous rune."], ["swap","Swap","⇄","soul",0,10,0,"Exchange mirrored runes once."], ["scry","Scry","◬","soul",0,10,0,"Pay on placement to reveal/reorder a draft."], ["ward","Ward","⬡","soul",0,15,0,"Prevent the next physical damage."], ["anchor","Anchor","ᛏ","soul",0,15,0,"Restore 5 sanity."], ["burn","Burn","ᛲ","soul",0,20,0,"Deal magic damage after opposing successes."], ["siphon","Siphon","ᛠ","soul",0,20,0,"Deal 4 direct health loss and reduce sanity by 7."], ["boast","Boast","ᛦ","soul",0,0,0,"Gain 10 mana."], ["inspiration","Inspiration","ᛤ","soul",0,0,0,"Restore 7 sanity."],
		["negate","Negate","±","mind",0,0,3,"Reverse mirrored numeric effects."], ["echo","Echo","≪","mind",0,0,3,"Repeat the last successful active effect."], ["flatter","Flatter","❖","mind",0,0,3,"Choose an opposing replica."], ["traumatize","Traumatize","⋇","mind",0,0,5,"Steal sanity equal to last opposing damage."], ["lie","Lie","ᛟ","mind",0,0,5,"Disguise the next placement."], ["investigate","Investigate","⌕","mind",0,0,5,"Add one rune to next draw and restore 10 sanity."], ["dictate","Dictate","ᚹ","mind",0,0,7,"Restrict the opponent's next family."], ["reiterate","Reiterate","⋮","mind",0,0,13,"Retrigger slots 1, 3, and 7."], ["outwit","Outwit","ᛯ","mind",0,0,7,"Deal 4 psychic damage and reduce mana by 5."], ["mend","Mend","᛫","mind",0,0,0,"Restore 4 health."], ["counsel","Counsel","ᚥ","mind",0,0,0,"Gain 5 mana."],
		["bite","Bite","ᛋ","generic",0,0,0,"Deal 1 damage, then gain 1 health."], ["ponder","Ponder","◇","generic",0,0,0,"Gain 3 mana."], ["study","Study","ᛈ","generic",0,0,0,"Restore 5 sanity."], ["mirror","Mirror","◈","generic",4,5,3,"Trigger the opposing effect at triple strength."]
	]
	for row in rows:
		c[row[0]] = _r(row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7])
	return c

static func build_test_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	var c := catalog()
	for copy_index in range(2):
		for key in RUNE_POOL:
			var rune: Dictionary = c[key].duplicate(true)
			rune["instance_id"] = "%s_%02d" % [key, copy_index]
			deck.append(rune)
	return deck

static func display_name(rune: Dictionary) -> String:
	return "%s %s" % [str(rune.get("symbol", "?")), str(rune.get("name", "Unknown rune"))]

static func can_pay(player: Dictionary, rune: Dictionary) -> bool:
	var cost: Dictionary = rune.get("cost", {})
	return int(player.get("health", 0)) >= int(cost.get("health", 0)) and int(player.get("mana", 0)) >= int(cost.get("mana", 0)) and int(player.get("sanity", 0)) >= int(cost.get("sanity", 0))
