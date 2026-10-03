extends Control
## Client khung (GĐ 3): ket noi WebSocket toi server, hien trang thai.
## - Dia chi server: bien moi truong VTS_SERVER (mac dinh ws://127.0.0.1:9000)
## - Client chay ca tren Web (WASM), Windows, Linux, Android — cung mot scene.

const SERVER_URL_DEFAULT := "ws://127.0.0.1:9000"

var _status: Label

func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	var title := Label.new()
	title.text = "Võ Lâm Trùng Sinh"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)

	_status = Label.new()
	_status.text = "Chưa kết nối server"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 20)
	box.add_child(_status)

	var btn := Button.new()
	btn.text = "Kết nối máy chủ"
	btn.pressed.connect(_connect_to_server)
	box.add_child(btn)

	multiplayer.connected_to_server.connect(func(): _status.text = "Đã kết nối server ✓")
	multiplayer.connection_failed.connect(func(): _status.text = "Kết nối thất bại ✗")
	multiplayer.server_disconnected.connect(func(): _status.text = "Mất kết nối server ✗")

func _connect_to_server() -> void:
	var url := OS.get_environment("VTS_SERVER")
	if url == "":
		url = SERVER_URL_DEFAULT
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_client(url)
	if err != OK:
		_status.text = "Lỗi tạo kết nối (mã %d)" % err
		return
	multiplayer.multiplayer_peer = peer
	_status.text = "Đang kết nối " + url + " ..."

func _process(_delta: float) -> void:
	var peer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	while peer.get_available_packet_count() > 0:
		var packet := peer.get_packet()
		_status.text = "Server: " + packet.get_string_from_utf8()
