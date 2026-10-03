# Võ Lâm Trùng Sinh

Game idle võ hiệp chơi trực tiếp trên trình duyệt — do AI phát triển. Hai trụ cột gameplay: **Trùng Sinh** (tái sinh nhiều kiếp, tích Ký ức tiền thế) và **Giang Hồ Ký** (biên niên giang hồ, ân oán NPC truyền kiếp).

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

## Lộ trình

- [x] Giai đoạn 0 — Nền móng: engine hoàn chỉnh, hệ lưu 3 slot `vlts_*`, repo riêng
- [ ] Giai đoạn 1 — Giang Hồ Ký (`js/chronicle.js`): biên niên sự kiện + quan hệ NPC
- [ ] Giai đoạn 2 — Trùng Sinh (`js/reincarnate.js`): Tọa Hóa, Ký ức tiền thế, prestige loop
- [ ] Giai đoạn 3 — Nội dung mới: kịch bản theo kiếp, đại sự giang hồ, Vụn Vỡ, tuyến Viên Mãn
