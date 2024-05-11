extends Control

var PATH = "user://auth.json"
var SCENE = "/root/Menu"

@onready var server_connect = $Connect
@onready var server_exists = $Exists
@onready var menu_play = $Background/Container/Play
@onready var menu_name = $Background/Container/Name
@onready var menu_warning = $Warning
@onready var auth = FileAccess.open(PATH, FileAccess.READ_WRITE)
var main = preload("res://main.tscn")

var unique_id
var nonce


func _ready():
	if not auth:
		auth = FileAccess.open(PATH, FileAccess.WRITE_READ)
		menu_play.disabled = false
	elif auth.get_length() == 0:
		menu_play.disabled = false
	else:
		var json = JSON.parse_string(auth.get_as_text())
		unique_id = json["unique_id"]
		nonce = json["nonce"]
		server_exists.request("%s/exists?nonce=%s&unique_id=%s"%[Globals.URL, nonce, unique_id])


func _on_play_pressed():
	var player_name = menu_name.text
	menu_name.clear()
	_on_name_text_submitted(player_name)


func _on_name_text_submitted(player_name):
	menu_play.disabled = true
	server_connect.request("%s/connect?name=%s"%[Globals.URL, player_name.replace(" ", "-")])


func _on_connect_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	var json = JSON.new()
	var error = json.parse(data)
	
	if error == OK:
		auth.store_string(JSON.stringify(json.data))
		var main_node = main.instantiate()
		Globals.unique_id = json.data["unique_id"]
		Globals.nonce = json.data["nonce"]
		get_tree().change_scene_to_packed(main)
	else:
		menu_warning.popup_message("Could not connect!")


func _on_exists_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	if data == "true":
		var main_node = main.instantiate()
		Globals.unique_id = unique_id
		Globals.nonce = nonce
		get_tree().change_scene_to_packed(main)
	elif data == "false":
		menu_play.disabled = false
	else:
		menu_warning.popup_message("Unable to check server!")
