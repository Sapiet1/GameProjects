extends Control

@onready var title = $Background/Container/Title
@onready var details = $Background/Container/Details
@onready var split = $Background/Container/Split
@onready var attack = $Background/Container/Attack

var destination
var source
var split_source = false
var turn = false


func change_square(square, player_owner, original, player):
	title.text = str(square)
	
	if player_owner != null:
		details.text = "Owned by %s\n%d G and %d P"%[player_owner["name"], player_owner["territory"][square]["gold"], player_owner["territory"][square]["people"]]
	else:
		details.text = "No Owner"
		
	attack.text = "%s →"%[str(original)]
	var adjacent_x = abs(square.x - original.x) == 1 and square.y == original.y
	var adjacent_y = abs(square.y - original.y) == 1 and square.x == original.x
	var adjacent = adjacent_x or adjacent_y
	attack.disabled = original not in player["territory"] or not adjacent or turn
	
	if not attack.disabled:
		destination = square
		source = original


func _on_split_toggled(toggled_on):
	split_source = toggled_on
