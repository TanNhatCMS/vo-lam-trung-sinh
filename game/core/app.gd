extends Node
## Autoload App: chọn chế độ chạy lúc khởi động.
## - Client thường: mở project bằng editor / chạy export build -> client_main.tscn
## - Dedicated server: chạy headless (Docker) hoặc cờ user-arg "--server" -> server_main.tscn

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var is_server := "--server" in args or DisplayServer.get_name() == "headless"
	if is_server:
		get_tree().change_scene_to_file.call_deferred("res://server/server_main.tscn")
