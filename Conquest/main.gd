extends Node2D

var MENU_SCENE = "res://menu.tscn"
var PLAYER_ID = 12
var PLAYER_TURN_ID = 13
var PLAYER_TURN_SPLIT_ID = 14
var ENEMY_ID = 9
var ENEMY_TURN_ID = 10
var ENEMY_TURN_SPLIT_ID = 11
var SEA_LEVEL_LAYER = 2

@onready var server_get_turns = $GetTurns
@onready var server_get_players_unstripped = $GetPlayersUnstripped
@onready var server_get_players = $GetPlayers
@onready var server_set_turn = $SetTurn
@onready var main_map = $Map
@onready var main_camera = $Camera
@onready var main_loading = $Camera/Loading
@onready var main_leaderboard = $Camera/Leaderboard
@onready var main_square_info = $Camera/SquareInfo

var players
var details
var turns
var click_start


func _ready():
	server_get_players_unstripped.request("%s/get_players_unstripped?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
	await server_get_players_unstripped.request_completed
	
	server_get_players.request("%s/get_players?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
	await server_get_players.request_completed
	
	server_get_turns.request("%s/get_turns?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
	await server_get_turns.request_completed
	
	move_to_position()
	visible = true
	

func move_to_position():
	var first_position = players[Globals.unique_id]["territory"].keys()[0]
	main_camera.position = main_map.map_to_local(first_position)
	main_camera.normalize_position()


func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		click_start = main_map.local_to_map(get_local_mouse_position())
	elif event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT and not main_square_info.visible:
		var mouse_position = get_local_mouse_position()
		var click_end = main_map.local_to_map(mouse_position)
		var player_owner
		
		for id in players:
			if click_end in players[id]["territory"]:
				player_owner = players[id]
				break
		
		main_square_info.change_square(click_end, player_owner, click_start, players[Globals.unique_id])
		main_square_info.visible = true
	elif event is InputEventKey and event.is_released() and event.keycode == KEY_ESCAPE:
		main_square_info.visible = false
	elif event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
		main_square_info.visible = false
	elif event is InputEventKey and event.is_released() and event.keycode == KEY_B:
		move_to_position()
	elif event is InputEventKey and event.is_released() and event.keycode == KEY_M:
		main_leaderboard.visible = not main_leaderboard.visible


func draw_players():
	for id in players:
		var tile_id = PLAYER_ID if id == Globals.unique_id else ENEMY_ID
		for cell_position in players[id]["territory"]:
			main_map.set_cell(SEA_LEVEL_LAYER, cell_position, tile_id, Vector2i(0, 0))


func draw_details():
	var array = details.values()
	array.sort_custom(func(a, b): return a["gold"] > b["gold"])
	
	var leaderboard = []

	for index in min(len(array), 10):
		var player_name = array[index]["name"]
		var player_gold = array[index]["gold"]
		leaderboard.append("%d. %s — %dG"%[index + 1, player_name, player_gold])
		
	main_leaderboard.change_list(leaderboard)


func draw_turns():
	for target_cell_position in turns:
		var turn_info = turns[target_cell_position]
		var tile_id
		
		if turn_info["id"] == Globals.unique_id and turn_info["split"]:
			tile_id = PLAYER_TURN_SPLIT_ID
		elif turn_info["id"] == Globals.unique_id and not turn_info["split"]:
			tile_id = PLAYER_TURN_ID
		elif turn_info["id"] != Globals.unique_id and turn_info["split"]:
			tile_id = ENEMY_TURN_SPLIT_ID
		elif turn_info["id"] != Globals.unique_id and not turn_info["split"]:
			tile_id = ENEMY_TURN_ID
		
		main_map.set_cell(SEA_LEVEL_LAYER, target_cell_position, tile_id, Vector2i(0, 0))

func switch_to_menu():
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_get_players_unstripped_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if data == "null":
		switch_to_menu()
	else:
		var json = JSON.new()
		
		var error = json.parse(data)
		if error == OK:
			main_loading.visible = false
			
			for id in json.data:
				var decoded_territory = {}
				for position in json.data[id]["territory"]:
					var numbers = position.split(",")
					decoded_territory[Vector2i(int(numbers[0]), int(numbers[1]))] = json.data[id]["territory"][position]
				json.data[id]["territory"] = decoded_territory
			
			players = json.data
			draw_players()
		else:
			main_loading.visible = true


func _on_get_turns_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if data == "null":
		switch_to_menu()
	else:
		var json = JSON.new()
		
		var error = json.parse(data)
		if error == OK:
			main_loading.visible = false

			var decoded_turns = {}
			for position in json.data:
				var position_numbers = position.split(",")
				var old_position_numbers = json.data[position]["position"].split(",")
				decoded_turns[Vector2i(int(position_numbers[0]), int(position_numbers[1]))] = {
					"position": Vector2i(int(old_position_numbers[0]), int(old_position_numbers[1])),
					"split": boolean(json.data[position]["split"]),
					"id": json.data[position]["id"]}
			
			if turns != null and not is_subset(turns, decoded_turns):
				server_get_players_unstripped.request("%s/get_players_unstripped?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
				await server_get_players_unstripped.request_completed
				
				server_get_players.request("%s/get_players?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
				await server_get_players.request_completed
				
				main_square_info.turn = false
			
			turns = decoded_turns
			draw_turns()
		else:
			main_loading.visible = true


func is_subset(subset, superset):
	for key in subset:
		if key not in superset or subset[key] != superset[key]:
			return false
	return true
	

func boolean(value):
	if value == "true":
		true
	elif value == "false":
		false


func _on_get_players_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if data == "null":
		switch_to_menu()
	else:
		var json = JSON.new()
		
		var error = json.parse(data)
		if error == OK:
			main_loading.visible = false
			details = json.data
			draw_details()
		else:
			main_loading.visible = true


func _on_set_turn_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if data == "ok":
		main_loading.visible = false
	elif data == "invalid":
		main_loading.visible = false
		main_square_info.turn = false
	elif data == "null":
		switch_to_menu()
	else:
		main_loading.visible = true


func _on_attack_pressed():
	main_square_info.visible = false
	main_square_info.turn = true
	server_set_turn.request("%s/set_turn?nonce=%s&unique_id=%s&x=%d&y=%d&adjacent_x=%d&adjacent_y=%d&split=%s"%[
		Globals.URL,
		Globals.nonce,
		Globals.unique_id,
		main_square_info.destination.x,
		main_square_info.destination.y,
		main_square_info.source.x,
		main_square_info.source.y,
		main_square_info.split_source])
	await server_set_turn.request_completed


func _on_turns_timer_timeout():
	server_get_turns.request("%s/get_turns?nonce=%s&unique_id=%s"%[Globals.URL, Globals.nonce, Globals.unique_id])
	await server_get_turns.request_completed
