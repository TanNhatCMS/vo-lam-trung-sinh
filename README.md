# Võ Lâm Trùng Sinh

Game idle võ hiệp **online** chơi trên trình duyệt, Windows/Linux/Android — do AI phát triển. Ba trụ cột gameplay: **Trùng Sinh** (tái sinh nhiều kiếp, tích Ký ức tiền thế), **Giang Hồ Ký** (biên niên giang hồ, ân oán NPC truyền kiếp) và **PK/PvP** thời gian thực với luật sát khí — nợ máu kiểu võ hiệp cổ điển.

> 📐 **Thiết kế đầy đủ:** xem [DESIGN.md](DESIGN.md)

## Chạy local

```bash
python -m http.server 8000
# hoặc npx serve .
```

## Deploy Cloudflare Workers

```bash
npx wrangler login
npx wrangler deploy
```

## Kiến trúc (tóm tắt)

- **Core game: Godot 4** — một project cho cả client (export Web/Windows/Linux/Android) và dedicated server (headless).
- Server **authoritative** chạy trong **Docker trên VPS**: mỗi vùng bản đồ là một room, tick 10–15Hz, WebSocket; đứng sau nginx/Caddy + TLS khi lên production.
- Công thức combat dùng chung client + server qua `game/core/` (GDScript) — server là nơi phán quyết.
- Tài khoản / cloud save / bảng xếp hạng: Cloudflare Workers + D1 (`services/api`, làm ở GĐ 3).

## Lộ trình

- [x] Giai đoạn 0 — Nền móng: thương hiệu, hệ lưu 3 slot `vlts_*`, repo riêng
- [x] Giai đoạn 0.5 — Core Godot: scaffold project, nạp data JSON, khung WebSocket client/server, Docker
- [ ] Giai đoạn 1 — Giang Hồ Ký (module chronicle): biên niên sự kiện + quan hệ NPC
- [ ] Giai đoạn 2 — Trùng Sinh (module reincarnate): Tọa Hóa, Ký ức tiền thế, prestige loop
- [ ] Giai đoạn 3 — Online nền tảng: tài khoản + cloud save, thấy người chơi trong ải
- [ ] Giai đoạn 4 — PK/PvP: combat server-authoritative, sát khí — rớt đồ, Đấu Võ Đài xếp hạng
- [ ] Giai đoạn 5 — Bang hội, đại sự giang hồ toàn server, thương trường
