extends Node
## Autoload DB: cơ sở dữ liệu game tĩnh nạp từ game/data/*.json
## (convert từ data.js / world.js / rdata.js bằng game/tools/convert_data.mjs)
##
## Client dùng để hiển thị; server dùng để phán quyết — luôn nạp từ cùng một nguồn.

var jx: Dictionary = {}   # kỹ năng, npc, item, affix, maps, shop...
var jw: Dictionary = {}   # zone, quái (mon), hero, animation, thành trấn
var rcp: Dictionary = {}  # công thức chế tạo, mảnh ghép

func _ready() -> void:
	jx = _load("res://data/jx.json")
	jw = _load("res://data/jw.json")
	rcp = _load("res://data/rcp.json")
	print("[DB] skills=%d npcs=%d maps=%d | zones=%d mon=%d | recipes=%d" % [
		(jx.get("skills", {}) as Dictionary).size(),
		(jx.get("npcs", []) as Array).size(),
		(jx.get("maps", []) as Array).size(),
		(jw.get("zones", []) as Array).size(),
		(jw.get("mon", {}) as Dictionary).size(),
		(rcp.get("recipes", {}) as Dictionary).size(),
	])

func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[DB] Thiếu file dữ liệu: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_warning("[DB] File dữ liệu sai định dạng: " + path)
	return {}
