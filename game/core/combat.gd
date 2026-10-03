class_name Combat
## Công thức combat dùng CHUNG client + server (nguyên tắc server-authoritative
## trong DESIGN.md): client gọi để dự đoán/hiển thị mượt, server gọi để phán quyết.
##
## TODO (GĐ 4 - PK/PvP): thay các hệ số tạm bằng công thức thật theo JX
## (attr 305 trường trong DB.jx["attr"] đã có sẵn dữ liệu gốc để tham chiếu).

const K_DEF := 0.5      # hệ số giảm của phòng thủ (tạm)

static func damage(atk: int, defense: int, mult: float = 1.0) -> int:
	return int(maxf(1.0, (atk - defense * K_DEF) * mult))

static func exp_to_next(level: int) -> int:
	# Bảng exp gốc nằm ở DB.jx["exp"] (200 cấp); hàm tiện dùng khi chưa nạp DB.
	var exp_table: Array = DB.jx.get("exp", [])
	if level >= 0 and level < exp_table.size():
		return int(exp_table[level])
	return -1
