# VÕ LÂM TRÙNG SINH — Thiết kế game

> Game idle võ hiệp do AI phát triển, với hai trụ cột: **Trùng Sinh** (vòng đời tái sinh) và **Giang Hồ Ký** (biên niên giang hồ).

## 1. Tầm nhìn một câu

Bạn là một võ lâm nhân trùng sinh trong kỳ hạn — mỗi kiếp chết đi, ký ức về giang hồ lại trở về với bạn trong kiếp mới: giang hồ vẫn đó, nhưng bạn biết trước tất cả, và lần này sẽ đi đường khác. *Giang hồ là một cuốn ký đang viết dở, còn bạn là người viết lại nó.*

## 2. Hai trụ cột

### 2.1. Trùng Sinh (lõi gameplay — prestige loop)

Vòng lặp mới của game idle: luyện công AFK → đạt đỉnh kiếp này → **Tọa Hóa** (chủ động kết thúc kiếp) → trùng sinh mạnh hơn.

- **Điều kiện Tọa Hóa:** đạt level mốc kiếp (mỗi kiếp tăng dần: 60 → 90 → 120...) hoặc chết trong sinh tử đấu.
- **Ký ức tiền thế** (điểm prestige): tích từ level đạt được, boss đã sát, danh vọng giang hồ, kho đồ đóng góp. Đổi Ký ức lấy:
  - **Ngộ tính** — cộng chỉ số khởi đầu vĩnh viễn (càng đào sâu càng đắt).
  - **Võ học tiền thế** — mở khóa kỹ năng đặc biệt dùng ngay từ cấp 1 (chỉ 1 slot/kiếp, chọn khéo là chiến thuật).
  - **Duyên tiền thế** — bắt đầu kiếp mới với 1 NPC cũ vẫn nhớ bạn (buff quan hệ ngay lập tức).
- **Mỗi kiếp là một "Thế"**: Thế thứ 1, 2, 3... — thế giới giữ nguyên bản đồ/quái, nhưng **kịch bản môn phái và NPC thay đổi theo số kiếp** (NPC từng bị bạn giết sẽ ân hận hoặc thù hằn trong kiếp sau — xem 2.2).
- **Cân bằng:** tài sản/đồ rơi reset theo kiếp, chỉ Ký ức + Giang Hồ Ký bền vững → người chơi luôn có đích hướng tới nhưng không phá vỡ economy.

### 2.2. Giang Hồ Ký (biên niên giang hồ — hệ thống kể chuyện)

Nâng cấp tab **"Giang hồ"** thành cuốn ký thật sự, ghi lại mọi dấu mốc của nhân vật và thế giới:

- **Trang ký cá nhân:** dòng thời gian có mốc thời gian chơi (ngày tháng trong-game): nhập môn, phái gia nhập, boss đầu tiên, lần đầu trùng sinh, ân oán tạo lập...
- **Ân oán NPC:** mỗi NPC có hệ số thiện cảm/thù hận thay đổi theo hành vi (giết phường trộm cướp của môn phái họ → thiện cảm; sát NPC cùng môn phái → thù hận truyền nhiều kiếp). NPC ân nhân sẽ tặng đồ/bỏ qua va chạm; NPC thù sẽ dẫn đám thủ hạ tập kích.
- **Đại sự giang hồ:** sự kiện thế giới xoay vòng (Đại hội võ lâm, Kiếm Các mãn môn bị đồ sát, Bảo vật xuất thế...) — tham gia hay bỏ qua đều **ghi vào Ký** và đổi trạng thái thế giới (môn phái nào chiếm ải nào).
- **Kỷ yếu:** xuất toàn bộ Giang Hồ Ký ra file chia sẻ được — một "build story" độc đáo của mỗi người chơi.

## 3. Hệ thống gameplay

| Hệ thống | Thiết kế |
|---|---|
| Tiến trình | Kiếp hữu hạn, prestige qua Trùng Sinh thay vì level vô hạn đơn điệu |
| Kể chuyện | Giang Hồ Ký + quan hệ NPC ăn sâu qua nhiều kiếp |
| Môn phái | Nhiệm vụ phái, danh vọng, đổi phái cần "tẩy tủy" |
| Sinh tồn | "Vụn Vỡ" — chốn trùng sinh giả (endless, điểm đổi Ký ức) |
| Cuối game | Tọa Hóa tầng tầng lớp lớp + tuyến "Viên Mãn" sau N kiếp |

## 4. Online & PK/PvP

Game phát triển theo hướng **online** (Web/Desktop/Android cùng một server) nhưng vẫn giữ tinh thần idle: luyện công AFK tính offline như cũ, còn **PvP là phần thời gian thực**.

### 4.1. Nguyên tắc kiến trúc — server authoritative

- **Client chỉ gửi ý định (intent)**: dùng kỹ năng, di chuyển, uống thuốc, chọn mục tiêu... **Server tính mọi kết quả**: damage, loot, chết sống, điểm sát khí. Client không bao giờ tự báo "tao đã giết mày".
- **Chia sẻ công thức**: combat/chỉ số viết một lần trong `packages/game-core` (TypeScript) — client dùng để dự đoán/hiển thị mượt, server dùng để phán quyết. Không bao giờ hai bộ công thức lệch nhau.
- **Vùng = 1 phòng**: mỗi ải/khu bản đồ là một **Durable Object** (Cloudflare) giữ trạng thái thời gian thực của những người chơi trong vùng, tick mô phỏng 10–15 lần/giây, phát (broadcast) delta trạng thái qua WebSocket. Vùng trống thì ngủ (hibernation) — không tốn tài nguyên.
- **Dịch vụ toàn cục** (Worker + D1 + KV): tài khoản, cloud save, bảng xếp hạng, Matchmaking Đấu Võ Đài.
- **Offline progress** vẫn do client/server tính lại theo timestamp khi đăng nhập — không cần server chạy mô phỏng 24/7 cho phần AFK.

### 4.2. Thiết kế PK (phong cách võ hiệp cổ điển)

- **Chế độ PK per nhân vật**: *Hòa Bình* (không đánh được người) / *Sát Phạt*. Chỉ bật được Sát Phạt ngoài thành trấn — thành trấn là **vùng an toàn** vĩnh viễn.
- **Sát khí**: giết người có danh trắng tích điểm sát khí, tên đổi màu dần (trắng → vàng → đỏ). **Hồng danh** bị NPC tuầntra truy sát, và khi chết có xác suất **rớt đồ đang mang** — cái giá của giết chóc.
- **Nợ máu (bounty)**: nạn nhân có thể treo thưởng; người đanh đỏ danh bị truy nã toàn máy chủ, ai trảm đầu nhận thưởng — ghi thẳng vào **Giang Hồ Ký**.
- **Đấu Võ Đài**: PvP có tổ chức, 1v1 theo Season, không mất đồ, xếp hạng bảng vàng toàn server (D1). Trảm đầu được ghi danh, thua không mang nợ sát khí.
- **Quy tắc vàng — PvP không phá Trùng Sinh**: chết do PvP **không** kích hoạt trùng sinh/không mất kiếp (chỉ mất đồ/buff tạm thời); trùng sinh chỉ đến từ Tọa Hóa chủ động hoặc sinh tử trong cốt truyện PvE. PvP là ân oán giang hồ, không phải công cụ phá save của người khác.

### 4.3. Mở rộng tự nhiên về sau

Bang hội (chiến bang trường), đại sự giang hồ đồng bộ toàn server (Đại hội võ lâm theo lịch), thương trường người chơi.

## 5. Kế hoạch kỹ thuật

Monorepo (pnpm workspaces):

```
packages/game-core   # công thức combat/chỉ số/loot — dùng chung client + server (TS)
packages/data        # dữ liệu game: item, quái, kỹ năng, bản đồ (JSON)
apps/web             # client web (Vite + TS, Canvas2D/PixiJS)
apps/desktop         # Tauri v2 (Windows/Linux)
apps/android         # Capacitor
services/api         # Worker + Hono + D1: tài khoản, cloud save, bảng xếp hạng
services/realtime    # Durable Objects: ZoneRoom (1 vùng = 1 phòng, tick + WebSocket)
```

Engine canvas hiện có: render (`js/render.js`), chiến đấu (`js/combat.js`), loot/shop/stash, save 3 slot (`js/save.js`), sinh tồn (`js/survival.js`) — migrate dần sang TS trong `game-core`, không viết lại một phát.

Lộ trình:

- **GĐ 0 — Nền móng (xong):** thương hiệu, hệ lưu 3 slot `vlts_*`, repo riêng.
- **GĐ 1 — Giang Hồ Ký:** `js/chronicle.js` — event bus ghi sự kiện, UI tab ký, quan hệ NPC.
- **GĐ 2 — Trùng Sinh:** `js/reincarnate.js` — Tọa Hóa, Ký ức tiền thế, prestige loop.
- **GĐ 3 — Online nền tảng:** TS + monorepo + StorageAdapter; tài khoản + cloud save + bảng xếp hạng (`services/api`, D1); thấy người chơi khác trong ải (`ZoneRoom` DO, chưa combat).
- **GĐ 4 — PK/PvP:** combat server-authoritative, chế độ PK + sát khí + rớt đồ, Đấu Võ Đài xếp hạng theo mùa.
- **GĐ 5 — Sâu rộng:** bang hội, đại sự giang hồ toàn server, thương trường.

Chi phí: free tier của Cloudflare đủ cho giai đoạn đầu; khi đông người chơi cần Workers Paid (~$5/tháng) cho Durable Objects không giới hạn + log.

## 6. Nguyên tắc

- **Server phán quyết mọi kết quả combat** — client chỉ gửi ý định và hiển thị.
- Không phá save: mọi schema mới đều version + migrate từ phiên bản trước; chết PvP không đụng vào tiến trình Trùng Sinh.
- Giữ tinh thần idle: phần luyện công hưởng lợi khi AFK như cũ; PvP là lựa chọn chủ động của người chơi.
