# Võ Lâm Trùng Sinh — Godot project

Khung game chính (client + dedicated server dùng chung một project Godot).

## Cấu trúc

```
game/
  project.godot          # cấu hình engine (GL Compatibility — nhẹ cho Web/Android)
  core/                  # dùng chung client + server
    app.gd               # chọn chế độ chạy (client / dedicated server)
    db.gd                # autoload DB: nạp game/data/*.json
    combat.gd            # công thức combat dùng chung (server-authoritative)
  client/                # client (Web/Windows/Linux/Android)
  server/                # dedicated server (WebSocket, chạy headless/Docker)
  data/                  # JSON dữ liệu game (sinh bởi tools/convert_data.mjs)
  tools/convert_data.mjs # convert data.js/world.js/rdata.js -> game/data/*.json
```

## Chạy

**Client** (mở `game/` bằng Godot 4.7+ rồi F5, hoặc):
```bash
godot --path game
```

**Server** (headless):
```bash
godot --headless --path game -- --server
# đổi cổng: VTS_PORT=9001 godot --headless --path game -- --server
```

**Client kết nối server khác:**
```bash
VTS_SERVER=ws://<ip-vps>:9000 godot --path game
```

## Docker (trên VPS)

```bash
docker compose -f deploy/docker-compose.yml up -d --build
docker logs -f vts-server          # xem "[SERVER] ... đang nghe ở cổng 9000"
```

Mở cổng `9000/tcp` trên firewall; đứng trước server thì nên đặt sau nginx/Caddy với TLS
(WebSocket wss://) khi đưa vào sử dụng thật.

## Dữ liệu game

Sửa dữ liệu gốc (`data.js`, `world.js`, `rdata.js` ở gốc repo) rồi chạy lại:
```bash
node game/tools/convert_data.mjs
```

## Export

Cài Godot export templates rồi thêm preset trong Project → Export:
Web, Windows, Linux, Android (client) — Dedicated server chạy trực tiếp qua Docker nên
chưa cần export riêng; sau này muốn image mỏng thì thêm preset "Linux Server" và đổi
Dockerfile sang chạy file pck đã export.
