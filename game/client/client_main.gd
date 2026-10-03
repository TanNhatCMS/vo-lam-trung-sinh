extends Control
## Client Võ Lâm Trùng Sinh (GĐ 0.5):
##   Boot (tự kết nối server đã lưu/mặc định) → Chọn máy chủ (từ data/servers.json)
##   → Tạo nhân vật (tên + 10 phái) → Lobby.
## Packet JSON UTF-8 hai chiều với server, chi tiết trong server/server_main.gd.

const SERVER_URL_FALLBACK := "ws://127.0.0.1:9000"
const PROFILE_PATH := "user://profile.json"
const NAME_MIN := 2
const NAME_MAX := 12

const COL_GOLD := Color(0.96, 0.85, 0.5)
const COL_TEXT := Color(0.9, 0.88, 0.8)

enum Screen { BOOT, SERVERS, CREATE, LOBBY }

var servers_cfg: Dictionary = {}
var profile: Dictionary = {}                 # {"server_id": "...", "char": {...}}
var current_server: Dictionary = {}          # server đang cố kết nối / đã kết nối
var connected_server_id := ""                # id server đã kết nối thành công
var chosen_fac := ""
var _screen := Screen.BOOT
var _screens: Dictionary = {}

# refs điều khiển runtime
var _boot_status: Label
var _boot_retry: Button
var _srv_continue: Button
var _srv_list_box: VBoxContainer
var _name_input: LineEdit
var _create_err: Label
var _fac_group: ButtonGroup
var _lobby_card: VBoxContainer
var _net_line: Label

var ws: WebSocketPeer = null    # kết nối tới server (WebSocket thô, JSON UTF-8)
var _ws_was_open := false

func _ready() -> void:
	_load_json_cfg()
	_load_profile()
	_build_background()
	_build_screens()
	_build_net_line()
	_show(Screen.BOOT)
	_auto_connect()

# ===================== cấu hình & profile =====================

func _load_json_cfg() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/servers.json"))
	if parsed is Dictionary and parsed.has("servers"):
		servers_cfg = parsed
	else:
		push_warning("servers.json lỗi — dùng cấu hình dự phòng")
		servers_cfg = {"default": "local", "servers": [
			{"id": "local", "name": "Máy cục bộ", "url": SERVER_URL_FALLBACK, "enabled": true}]}

func _enabled_servers() -> Array:
	var out: Array = []
	for s in servers_cfg.get("servers", []):
		if s.get("enabled", true):
			out.append(s)
	return out

func _server_by_id(id: String) -> Dictionary:
	for s in servers_cfg.get("servers", []):
		if s.get("id", "") == id:
			return s
	return {}

func _load_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
		if parsed is Dictionary:
			profile = parsed

func _save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profile))

# ===================== kết nối =====================

func _auto_connect() -> void:
	var last := _server_by_id(profile.get("server_id", ""))
	if last.is_empty():
		last = _server_by_id(servers_cfg.get("default", ""))
	if last.is_empty() or not last.get("enabled", true):
		var list := _enabled_servers()
		last = list[0] if list.size() > 0 else {"id": "local", "name": "Local", "url": SERVER_URL_FALLBACK}
	_connect_to(last, Screen.BOOT)

func _connect_to(srv: Dictionary, back_to: Screen = Screen.SERVERS) -> void:
	current_server = srv
	_net_line.text = "Đang kết nối %s ..." % srv.get("name", srv.get("url", "?"))
	_show(back_to)
	ws = WebSocketPeer.new()
	var err := ws.connect_to_url(srv.get("url", SERVER_URL_FALLBACK))
	if err != OK:
		ws = null
		_on_connect_failed()
		return
	_ws_was_open = false
	_boot_status.text = "Đang kết nối %s ..." % srv.get("name", "")

func _on_connected() -> void:
	connected_server_id = current_server.get("id", "")
	profile["server_id"] = connected_server_id
	_save_profile()
	_net_line.text = "● Đã kết nối: %s" % current_server.get("name", "")
	if _screen == Screen.BOOT:
		_show(Screen.SERVERS)      # sau khi kết nối xong → màn chọn server
	_refresh_server_list()

func _on_connect_failed() -> void:
	_net_line.text = "✗ Kết nối thất bại"
	connected_server_id = ""
	if _screen == Screen.BOOT:
		_boot_status.text = "Không kết nối được %s" % current_server.get("name", "?")
		_boot_retry.visible = true
	_refresh_server_list()

func _on_disconnected() -> void:
	_net_line.text = "✗ Mất kết nối server"
	connected_server_id = ""
	_refresh_server_list()

# ===================== vòng đời WebSocket =====================

func _process(_delta: float) -> void:
	if ws == null:
		return
	ws.poll()
	var st := ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN and not _ws_was_open:
		_ws_was_open = true
		_on_connected()
	elif st == WebSocketPeer.STATE_CLOSED:
		var was_open := _ws_was_open
		_ws_was_open = false
		ws = null
		if was_open:
			_on_disconnected()
		else:
			_on_connect_failed()
		return
	if _ws_was_open:
		while ws.get_available_packet_count() > 0:
			var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if msg is Dictionary:
				_handle(msg)

func _send(obj: Dictionary) -> void:
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(obj))

func _handle(msg: Dictionary) -> void:
	match msg.get("t", ""):
		"ping":
			_net_line.text = "● %s — %d người online" % [current_server.get("name", ""), msg.get("peers", 0)]
		"char_ok":
			profile["char"] = {"name": msg.get("name", ""), "fac": msg.get("fac", ""), "fac_name": msg.get("fac_name", "")}
			_save_profile()
			_rebuild_lobby()
			_show(Screen.LOBBY)
		"char_err":
			if _screen == Screen.CREATE and _create_err != null:
				_create_err.text = str(msg.get("msg", "Lỗi không rõ"))

# ===================== điều hướng màn hình =====================

func _show(s: Screen) -> void:
	_screen = s
	for k in _screens:
		_screens[k].visible = (k == s)

func _go_continue() -> void:
	if connected_server_id == "":
		return
	if profile.get("char", {}).has("name"):
		_rebuild_lobby()
		_show(Screen.LOBBY)
	else:
		_show(Screen.CREATE)

# ===================== dựng UI =====================

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/demo/town.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.07, 0.88)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(1)
	sb.border_color = Color(COL_GOLD, 0.35)
	sb.content_margin_left = 28.0
	sb.content_margin_right = 28.0
	sb.content_margin_top = 22.0
	sb.content_margin_bottom = 22.0
	p.add_theme_stylebox_override("panel", sb)
	return p

func _label(text: String, size: int, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	return l

func _gold_title(text: String, size: int = 30) -> Label:
	var l := _label(text, size, COL_GOLD)
	l.add_theme_constant_override("outline_size", 8)
	return l

func _build_screens() -> void:
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	_screens[Screen.BOOT] = _build_boot()
	_screens[Screen.SERVERS] = _build_servers()
	_screens[Screen.CREATE] = _build_create()
	_screens[Screen.LOBBY] = _build_lobby()
	for k in _screens:
		center.add_child(_screens[k])

func _build_boot() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/demo/shaolin.png")
	portrait.custom_minimum_size = Vector2(132, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(portrait)
	v.add_child(_gold_title("Võ Lâm Trùng Sinh", 48))
	_boot_status = _label("Đang vào giang hồ...", 20)
	v.add_child(_boot_status)
	_boot_retry = Button.new()
	_boot_retry.text = "  Thử lại  "
	_boot_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boot_retry.pressed.connect(_auto_connect)
	_boot_retry.visible = false
	v.add_child(_boot_retry)
	var other := Button.new()
	other.text = "  Chọn máy chủ khác  "
	other.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	other.pressed.connect(func():
		_refresh_server_list()
		_show(Screen.SERVERS))
	v.add_child(other)
	return v

func _build_servers() -> Control:
	var p := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_gold_title("Chọn máy chủ"))
	_srv_list_box = VBoxContainer.new()
	_srv_list_box.add_theme_constant_override("separation", 8)
	v.add_child(_srv_list_box)
	_srv_continue = Button.new()
	_srv_continue.text = "  Tiếp tục  ▸  "
	_srv_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_srv_continue.add_theme_font_size_override("font_size", 22)
	_srv_continue.disabled = true
	_srv_continue.pressed.connect(_go_continue)
	v.add_child(_srv_continue)
	return p

func _refresh_server_list() -> void:
	if _srv_list_box == null:
		return
	for c in _srv_list_box.get_children():
		c.queue_free()
	for srv in _enabled_servers():
		var b := Button.new()
		var mark := "✓ " if srv.get("id", "") == connected_server_id else ""
		b.text = "%s%s   (%s)" % [mark, srv.get("name", "?"), srv.get("url", "")]
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_server_button.bind(srv))
		_srv_list_box.add_child(b)
	_srv_continue.disabled = connected_server_id == ""

func _on_server_button(srv: Dictionary) -> void:
	if srv.get("id", "") == connected_server_id:
		return
	_connect_to(srv, Screen.SERVERS)
	_refresh_server_list()

func _build_create() -> Control:
	var p := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_gold_title("Tạo nhân vật"))
	v.add_child(_label("Chọn phái (dữ liệu gốc: 10 môn phái)", 16, Color(0.75, 0.72, 0.62)))

	_fac_group = ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for f in DB.jx.get("factions", []):
		var key := str(f.get("key", ""))
		if not (DB.jw.get("hero", {}) as Dictionary).has(key):
			continue   # chỉ hiện 10 môn phái có nhân vật/portrait trong game
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = _fac_group
		b.icon = load("res://assets/portraits/%s.png" % key)
		b.add_theme_constant_override("icon_max_width", 56)
		var nice: String = str(f.get("n", key)).replace(" phái", "").replace(" Bang", "")
		b.text = nice
		b.add_theme_font_size_override("font_size", 14)
		b.custom_minimum_size = Vector2(104, 0)
		b.tooltip_text = "%s\nCamp: %s\nSố kỹ năng: %d" % [f.get("n", key), f.get("camp", "?"), (f.get("skills", []) as Array).size()]
		b.set_meta("fac", key)
		grid.add_child(b)
	v.add_child(grid)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Tên nhân vật (%d–%d ký tự)" % [NAME_MIN, NAME_MAX]
	_name_input.max_length = NAME_MAX
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_name_input)

	_create_err = _label(" ", 16, Color(1, 0.5, 0.4))
	v.add_child(_create_err)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var back := Button.new()
	back.text = "◂ Đổi máy chủ"
	back.pressed.connect(func():
		_refresh_server_list()
		_show(Screen.SERVERS))
	row.add_child(back)
	var go := Button.new()
	go.text = "  Tạo nhân vật  "
	go.add_theme_font_size_override("font_size", 22)
	go.pressed.connect(_submit_create)
	row.add_child(go)
	return p

func _submit_create() -> void:
	_create_err.text = " "
	var sel = _fac_group.get_pressed_button()
	if sel == null:
		_create_err.text = "Hãy chọn một môn phái"
		return
	var char_name := _name_input.text.strip_edges()
	if char_name.length() < NAME_MIN:
		_create_err.text = "Tên phải từ %d ký tự trở lên" % NAME_MIN
		return
	_send({"t": "create_char", "name": char_name, "fac": sel.get_meta("fac")})

func _build_lobby() -> Control:
	var p := _panel()
	_lobby_card = VBoxContainer.new()
	_lobby_card.add_theme_constant_override("separation", 12)
	p.add_child(_lobby_card)
	return p

func _rebuild_lobby() -> void:
	if _lobby_card == null:
		return
	for c in _lobby_card.get_children():
		c.queue_free()
	var ch: Dictionary = profile.get("char", {})
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/portraits/%s.png" % ch.get("fac", "shaolin"))
	portrait.custom_minimum_size = Vector2(132, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lobby_card.add_child(portrait)
	_lobby_card.add_child(_gold_title(str(ch.get("name", "Võ sĩ")), 36))
	_lobby_card.add_child(_label("%s  •  %s" % [ch.get("fac_name", ""), current_server.get("name", "")], 18))
	var enter := Button.new()
	enter.text = "  Vào giang hồ  (GĐ 1 — sắp có)  "
	enter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enter.pressed.connect(func(): _net_line.text = "Thế giới đang được xây... GĐ 1 sẽ mở!")
	_lobby_card.add_child(enter)
	var change := Button.new()
	change.text = "Đổi máy chủ"
	change.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	change.pressed.connect(func():
		_refresh_server_list()
		_show(Screen.SERVERS))
	_lobby_card.add_child(change)

func _build_net_line() -> void:
	_net_line = _label("", 16)
	_net_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_net_line.offset_top = -34.0
	_net_line.offset_bottom = -10.0
	add_child(_net_line)
