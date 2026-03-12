extends Node

const CLIENT_BOOT_SCENE := "res://scenes/boot/client_boot.tscn"
const SERVER_BOOT_SCENE := "res://scenes/boot/server_boot.tscn"

func _ready() -> void:
	var target_scene := SERVER_BOOT_SCENE if GameConfig.is_server_mode() else CLIENT_BOOT_SCENE
	get_tree().call_deferred("change_scene_to_file", target_scene)
