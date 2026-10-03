extends Node
## Dedicated server (khung GĐ 3-4): WebSocket authoritative.
## - 1 vùng bản đồ = 1 room; server tick và phán quyết mọi kết quả combat.
## - Cấu hình: biến môi trường VTS_PORT (mặc định 9000).
## - Chạy: godot --headless --path . -- --server   (hoặc qua deploy/Dockerfile)

const PORT_DEFAULT := 9000

var peers: Dictionary = {}      # peer_id -> thông tin người chơi (tạm)
var _tick_accum := 0.0
var _ping_timer := 0.0

func _ready() -> void:
	var port := PORT_DEFAULT
	if OS.get_environment("VTS_PORT") != "":
		port = int(OS.get_environment("VTS_PORT"))
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		push_error("[SERVER] Không mở được cổng %d (mã lỗi %d)" % [port, err])
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[SERVER] Võ Lâm Trùng Sinh - server đang nghe ở cổng %d" % port)
	print("[SERVER] DB: %d zone, %d loai quai da nap" % [
		(DB.jw.get("zones", []) as Array).size(),
		(DB.jw.get("mon", {}) as Dictionary).size(),
	])

func _on_peer_connected(id: int) -> void:
	peers[id] = {"name": "Vo si_%d" % id, "zone": 2}
	print("[SERVER] Peer ket noi: %d (tong %d)" % [id, peers.size()])

func _on_peer_disconnected(id: int) -> void:
	peers.erase(id)
	print("[SERVER] Peer ngat: %d (tong %d)" % [id, peers.size()])

func _process(delta: float) -> void:
	# TODO (GĐ 4): tick mo phong 10-15Hz - di chuyen, combat, PK, sat khi.
	_ping_timer += delta
	if _ping_timer >= 1.0:
		_ping_timer = 0.0
		if multiplayer.multiplayer_peer != null \
				and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.multiplayer_peer.put_packet(
				("ping %d peers %d" % [Time.get_ticks_msec() / 1000, peers.size()]).to_utf8_buffer())
