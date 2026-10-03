extends Node
## Dedicated server (khung GĐ 3): WebSocket thô — JSON UTF-8 hai chiều.
## Tài khoản + nhân vật lưu file JSON (SHA-256 + salt). Server authoritative.
##
## Packet:
##   c->s  {"t":"register","user":..,"pass":..}   s->c  {"t":"reg_ok"} | {"t":"reg_err","msg"}   (đăng ký = tự đăng nhập)
##   c->s  {"t":"login","user":..,"pass":..}      s->c  {"t":"login_ok","user":..,"chars":[..]} | {"t":"login_err","msg"}
##   c->s  {"t":"logout"}                          s->c  {"t":"logged_out"}
##   c->s  {"t":"create_char","name":..,"fac":..}  s->c  {"t":"char_created","chars":[..]} | {"t":"char_err","msg"}
##   s->c  {"t":"welcome","peers":N} | {"t":"ping","peers":N,"up":giây}
## chars = [{"name":..,"fac":..,"fac_name":..,"lvl":1}]

const PORT_DEFAULT := 9000
const MAX_CHARS := 3            # số nhân vật tối đa mỗi tài khoản
const USER_RE := "^[A-Za-z0-9_]{3,16}$"
const PASS_MIN := 4
const NAME_MIN := 2
const NAME_MAX := 12
const BAD_CHARS := "<>&\"'\\"

var tcp := TCPServer.new()
var clients: Dictionary = {}    # id -> {"ws": WebSocketPeer, "user": String, "greeted": bool}
var accounts: Dictionary = {}   # user -> {"salt": .., "hash": .., "chars": [..]}
var _next_id := 1
var _ping_timer := 0.0
var _uptime := 0.0
var _user_re: RegEx
var _io_thread: Thread = null   # ghi tài khoản ra đĩa bằng thread nền (volume chậm)
var _io_mutex := Mutex.new()
var _io_data: Dictionary = {}
var _io_has := false

func _ready() -> void:
	_user_re = RegEx.new()
	_user_re.compile(USER_RE)
	_load_accounts()
	var port := PORT_DEFAULT
	if OS.get_environment("VTS_PORT") != "":
		port = int(OS.get_environment("VTS_PORT"))
	var err := tcp.listen(port)
	if err != OK:
		push_error("[SERVER] Không mở được cổng %d (mã lỗi %d)" % [port, err])
		get_tree().quit(1)
		return
	print("[SERVER] Võ Lâm Trùng Sinh - server đang nghe ở cổng %d" % port)
	print("[SERVER] DB: %d phai, %d loai quai | %d tai khoan" % [
		(DB.jx.get("factions", []) as Array).size(),
		(DB.jw.get("mon", {}) as Dictionary).size(),
		accounts.size()])

func _process(delta: float) -> void:
	_uptime += delta
	while tcp.is_connection_available():
		var id := _next_id
		_next_id += 1
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp.take_connection())
		clients[id] = {"ws": ws, "user": "", "greeted": false}
		print("[SERVER] Peer ket noi: %d (tong %d)" % [id, clients.size()])
	var closed: Array[int] = []
	for id in clients:
		var ws: WebSocketPeer = clients[id]["ws"]
		ws.poll()
		match ws.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				# Chào sau khi handshake hoàn tất (gửi trước khi OPEN sẽ mất im lặng)
				if not clients[id]["greeted"]:
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
		var who: String = clients[id].get("user", "?")
		clients.erase(id)
		print("[SERVER] Peer ngat: %s (tong %d)" % [who, clients.size()])
	_ping_timer += delta
	if _ping_timer >= 1.0:
		_ping_timer = 0.0
		for id in clients:
			_send(id, {"t": "ping", "peers": clients.size(), "up": int(_uptime)})
	# Nhắc nhẹ: nếu có snapshot chờ ghi mà worker đã ngủ, đánh thức
	if _io_has and (_io_thread == null or not _io_thread.is_alive()):
		_kick_writer()

func _exit_tree() -> void:
	# Ghi nốt dữ liệu trước khi thoát (đồng bộ)
	_io_mutex.lock()
	_io_data = accounts.duplicate(true)
	_io_has = true
	_io_mutex.unlock()
	if _io_thread != null and _io_thread.is_alive():
		_io_thread.wait_to_finish()
	_io_mutex.lock()
	if _io_has:
		_io_has = false
		_write_sync(accounts)
	_io_mutex.unlock()

# ===================== điều phối packet =====================

func _handle(id: int, msg: Dictionary) -> void:
	match msg.get("t", ""):
		"register": _handle_register(id, msg)
		"login": _handle_login(id, msg)
		"logout":
			clients[id]["user"] = ""
			_send(id, {"t": "logged_out"})
		"create_char": _handle_create_char(id, msg)
		_:
			_send(id, {"t": "char_err", "msg": "Lệnh không hỗ trợ: %s" % msg.get("t", "?")})

func _handle_register(id: int, msg: Dictionary) -> void:
	var user := str(msg.get("user", "")).strip_edges()
	var passw := str(msg.get("pass", ""))
	var why := _check_user_pass(user, passw)
	if why != "":
		_send(id, {"t": "reg_err", "msg": why})
		return
	if accounts.has(user):
		_send(id, {"t": "reg_err", "msg": "Tài khoản «%s» đã tồn tại" % user})
		return
	var crypto := Crypto.new()
	var salt := crypto.generate_random_bytes(16).hex_encode()
	accounts[user] = {"salt": salt, "hash": _sha256_hex(salt + passw), "chars": []}
	_mark_dirty()
	print("[SERVER] Dang ky tai khoan: %s" % user)
	clients[id]["user"] = user   # đăng ký xong tự đăng nhập
	_send(id, {"t": "reg_ok"})
	_send(id, {"t": "login_ok", "user": user, "chars": []})

func _handle_login(id: int, msg: Dictionary) -> void:
	var user := str(msg.get("user", "")).strip_edges()
	var passw := str(msg.get("pass", ""))
	if not accounts.has(user):
		_send(id, {"t": "login_err", "msg": "Tài khoản không tồn tại — hãy đăng ký"})
		return
	var acc: Dictionary = accounts[user]
	if _sha256_hex(str(acc["salt"]) + passw) != str(acc["hash"]):
		_send(id, {"t": "login_err", "msg": "Sai mật khẩu"})
		return
	clients[id]["user"] = user
	print("[SERVER] Dang nhap: %s" % user)
	_send(id, {"t": "login_ok", "user": user, "chars": acc["chars"]})

func _handle_create_char(id: int, msg: Dictionary) -> void:
	var user := str(clients[id].get("user", ""))
	if user == "" or not accounts.has(user):
		_send(id, {"t": "char_err", "msg": "Chưa đăng nhập"})
		return
	var char_name := str(msg.get("name", "")).strip_edges()
	var fac := str(msg.get("fac", ""))
	if char_name.length() < NAME_MIN or char_name.length() > NAME_MAX:
		_send(id, {"t": "char_err", "msg": "Tên phải từ %d–%d ký tự" % [NAME_MIN, NAME_MAX]})
		return
	for i in char_name.length():
		if BAD_CHARS.contains(char_name[i]):
			_send(id, {"t": "char_err", "msg": "Tên chứa ký tự không hợp lệ"})
			return
	var fac_name := _fac_name(fac)
	if fac_name == "":
		_send(id, {"t": "char_err", "msg": "Phái không tồn tại"})
		return
	# Tên nhân vật duy nhất toàn server (qua mọi tài khoản)
	for other_user in accounts:
		for ch in accounts[other_user]["chars"]:
			if str(ch.get("name", "")) == char_name:
				_send(id, {"t": "char_err", "msg": "Tên «%s» đã có người dùng" % char_name})
				return
	var acc: Dictionary = accounts[user]
	if (acc["chars"] as Array).size() >= MAX_CHARS:
		_send(id, {"t": "char_err", "msg": "Tối đa %d nhân vật mỗi tài khoản" % MAX_CHARS})
		return
	acc["chars"].append({"name": char_name, "fac": fac, "fac_name": fac_name, "lvl": 1})
	_mark_dirty()
	print("[SERVER] %s tao nhan vat: %s (%s)" % [user, char_name, fac])
	_send(id, {"t": "char_created", "chars": acc["chars"]})

# ===================== tài khoản =====================

func _check_user_pass(user: String, passw: String) -> String:
	if _user_re.search(user) == null:
		return "Tài khoản: 3–16 ký tự, chỉ chữ/số/gạch dưới"
	if passw.length() < PASS_MIN:
		return "Mật khẩu tối thiểu %d ký tự" % PASS_MIN
	return ""

func _sha256_hex(s: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(s.to_utf8_buffer())
	return ctx.finish().hex_encode()

func _accounts_path() -> String:
	var dir := OS.get_environment("VTS_DATA")
	if dir == "":
		return "user://vts_accounts.json"
	DirAccess.make_dir_recursive_absolute(dir)
	return dir.path_join("accounts.json")

func _load_accounts() -> void:
	var path := _accounts_path()
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		accounts = parsed
		print("[SERVER] Nap %d tai khoan tu %s" % [accounts.size(), path])

func _mark_dirty() -> void:
	_io_mutex.lock()
	_io_data = accounts.duplicate(true)
	_io_has = true
	_io_mutex.unlock()
	_kick_writer()

func _kick_writer() -> void:
	if _io_thread != null and _io_thread.is_alive():
		return
	if _io_thread != null:
		_io_thread.wait_to_finish()
	_io_thread = Thread.new()
	_io_thread.start(_write_worker)

func _write_worker() -> void:
	while true:
		_io_mutex.lock()
		var data: Dictionary = _io_data
		var has := _io_has
		_io_has = false
		_io_data = {}
		_io_mutex.unlock()
		if not has:
			break
		_write_sync(data)

func _write_sync(data: Dictionary) -> void:
	var f := FileAccess.open(_accounts_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(accounts, "  "))

func _fac_name(key: String) -> String:
	for f in DB.jx.get("factions", []):
		if f.get("key", "") == key:
			return f.get("n", "")
	return ""

func _send(id: int, obj: Dictionary) -> void:
	var c: Dictionary = clients.get(id, {})
	if c.has("ws"):
		(c["ws"] as WebSocketPeer).send_text(JSON.stringify(obj))
