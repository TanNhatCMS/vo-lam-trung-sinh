extends Control
## Client khung (GĐ 3): ket noi WebSocket toi server, hien trang thai.
## - Dia chi server: bien moi truong VTS_SERVER (mac dinh ws://127.0.0.1:9000)
## - Client chay ca tren Web (WASM), Windows, Linux, Android — cung mot scene.

const SERVER_URL_DEFAULT := "ws://127.0.0.1:9000"

var _status: Label

func _ready() -> void:
	# Nen canh thanh tran
	var bg := TextureRect.new()
	bg.texture = load("res://assets/demo/town.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	# Chan dung nhan vat
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/demo/shaolin.png")
	portrait.custom_minimum_size = Vector2(132, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(portrait)

	var title := Label.new()
	title.text = "Võ Lâm Trùng Sinh"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.96, 0.85, 0.5))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.04))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Giang hồ là một cuốn ký đang viết dở…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	sub.add_theme_constant_override("outline_size", 6)
	box.add_child(sub)

	_status = Label.new()
	_status.text = "Chưa kết nối server"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 20)
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_status.add_theme_constant_override("outline_size", 6)
	box.add_child(_status)

	var btn := Button.new()
	btn.text = "  Kết nối máy chủ  "
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)
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
