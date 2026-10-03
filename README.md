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

- Client web (TS + Canvas/PixiJS), server **authoritative** trên Cloudflare: **Durable Objects** mô phỏng từng vùng bản đồ qua WebSocket, **Worker + D1** cho tài khoản/cloud save/bảng xếp hạng.
- Công thức combat dùng chung client + server qua `packages/game-core` (TypeScript).
- Đóng gói desktop bằng Tauri v2, Android bằng Capacitor.

## Lộ trình

- [x] Giai đoạn 0 — Nền móng: engine hoàn chỉnh, hệ lưu 3 slot `vlts_*`, repo riêng
- [ ] Giai đoạn 1 — Giang Hồ Ký (`js/chronicle.js`): biên niên sự kiện + quan hệ NPC
- [ ] Giai đoạn 2 — Trùng Sinh (`js/reincarnate.js`): Tọa Hóa, Ký ức tiền thế, prestige loop
- [ ] Giai đoạn 3 — Online nền tảng: TS + monorepo, tài khoản + cloud save, thấy người chơi trong ải
- [ ] Giai đoạn 4 — PK/PvP: combat server-authoritative, sát khí — rớt đồ, Đấu Võ Đài xếp hạng
- [ ] Giai đoạn 5 — Bang hội, đại sự giang hồ toàn server, thương trường
