extends Node
## Dedicated server (khung GĐ 3-4): WebSocket thô (WebSocketPeer) — JSON UTF-8 hai chiều,
## không dùng envelope của SceneMultiplayer để mọi client (Godot/web/test) đều nói chuyện được.
## - 1 vùng bản đồ = 1 room; server tick và phán quyết mọi kết quả combat.
## - Cấu hình: VTS_PORT (mặc định 9000).
## - Chạy: godot --headless --path . -- --server   (hoặc qua deploy/Dockerfile)
##
## Packet client -> server: {"t":"create_char","name":"...","fac":"shaolin"}
## Packet server -> client: {"t":"welcome","peers":N} | {"t":"ping","peers":N,"up":giây}
##   {"t":"char_ok","name":...,"fac":...,"fac_name":...} | {"t":"char_err","msg":...}

const PORT_DEFAULT := 9000
const NAME_MIN := 2
const NAME_MAX := 12
const BAD_CHARS := "<>&\"'\\"   # ký tự không cho phép trong tên

var tcp := TCPServer.new()
var clients: Dictionary = {}    # id -> {"ws": WebSocketPeer, "name": String, "fac": String}
var _next_id := 1
var _ping_timer := 0.0
var _uptime := 0.0

func _ready() -> void:
	var port := PORT_DEFAULT
	if OS.get_environment("VTS_PORT") != "":
		port = int(OS.get_environment("VTS_PORT"))
	var err := tcp.listen(port)
	if err != OK:
		push_error("[SERVER] Không mở được cổng %d (mã lỗi %d)" % [port, err])
		get_tree().quit(1)
		return
	print("[SERVER] Võ Lâm Trùng Sinh - server đang nghe ở cổng %d" % port)
	print("[SERVER] DB: %d phai, %d loai quai da nap" % [
		(DB.jx.get("factions", []) as Array).size(),
		(DB.jw.get("mon", {}) as Dictionary).size(),
	])

func _process(delta: float) -> void:
	_uptime += delta
	# Chấp nhận kết nối mới
	while tcp.is_connection_available():
		var id := _next_id
		_next_id += 1
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp.take_connection())
		clients[id] = {"ws": ws, "name": "", "fac": "", "greeted": false}
		print("[SERVER] Peer ket noi: %d (tong %d)" % [id, clients.size()])
	# Poll từng client
	var closed: Array[int] = []
	for id in clients:
		var ws: WebSocketPeer = clients[id]["ws"]
		ws.poll()
		match ws.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				# Chào sau khi handshake hoàn tất (gửi trước khi OPEN sẽ mất im lặng)
				if not clients[id].get("greeted", false):
					clients[id]["greeted"] = true
					_send(id, {"t": "welcome", "peers": clients.size()})
				while ws.get_available_packet_count() > 0:
					var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
					if msg is Dictionary:
						_handle(id, msg)
					else:
						_send(id, {"t": "char_err", "msg": "Packet không hợp lệ"})
			WebSocketPeer.STATE_CLOSED:
				closed.append(id)
	for id in closed:
		var info: Dictionary = clients[id]
		if info.get("name", "") != "":
			print("[SERVER] %s (%s) roi game" % [info["name"], info.get("fac", "?")])
		clients.erase(id)
		print("[SERVER] Peer ngat: %d (tong %d)" % [id, clients.size()])
	# Ping định kỳ
	# TODO (GĐ 4): tick mô phỏng 10-15Hz — di chuyển, combat, PK, sát khí.
	_ping_timer += delta
	if _ping_timer >= 1.0:
		_ping_timer = 0.0
		for id in clients:
			_send(id, {"t": "ping", "peers": clients.size(), "up": int(_uptime)})

func _handle(id: int, msg: Dictionary) -> void:
	match msg.get("t", ""):
		"create_char":
			_handle_create_char(id, msg)
		_:
			_send(id, {"t": "char_err", "msg": "Lệnh không hỗ trợ: %s" % msg.get("t", "?")})

func _handle_create_char(id: int, msg: Dictionary) -> void:
	var char_name := str(msg.get("name", "")).strip_edges()
	var fac := str(msg.get("fac", ""))
	# Kiểm tra tên
	if char_name.length() < NAME_MIN or char_name.length() > NAME_MAX:
		_send(id, {"t": "char_err", "msg": "Tên phải từ %d–%d ký tự" % [NAME_MIN, NAME_MAX]})
		return
	for i in char_name.length():
		if BAD_CHARS.contains(char_name[i]):
			_send(id, {"t": "char_err", "msg": "Tên chứa ký tự không hợp lệ"})
			return
	for other in clients:
		if other != id and clients[other].get("name", "") == char_name:
			_send(id, {"t": "char_err", "msg": "Tên «%s» đã có người dùng" % char_name})
			return
	# Kiểm tra phái theo dữ liệu game
	var fac_name := _fac_name(fac)
	if fac_name == "":
		_send(id, {"t": "char_err", "msg": "Phái không tồn tại"})
		return
	clients[id]["name"] = char_name
	clients[id]["fac"] = fac
	print("[SERVER] Tao nhan vat: %s (%s)" % [char_name, fac])
	_send(id, {"t": "char_ok", "name": char_name, "fac": fac, "fac_name": fac_name})

func _fac_name(key: String) -> String:
	for f in DB.jx.get("factions", []):
		if f.get("key", "") == key:
			return f.get("n", "")
	return ""

func _send(id: int, obj: Dictionary) -> void:
	var c: Dictionary = clients.get(id, {})
	if c.has("ws"):
		(c["ws"] as WebSocketPeer).send_text(JSON.stringify(obj))
