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

## 4. Kế hoạch kỹ thuật

Engine canvas hoàn chỉnh sẵn có: render (`js/render.js`), chiến đấu (`js/combat.js`), loot/shop/stash, save 3 slot (`js/save.js`), sinh tồn (`js/survival.js`).

- **Giai đoạn 0 — Nền móng (xong):** định hình thương hiệu, hệ lưu riêng `vlts_*`, repo riêng.
- **Giai đoạn 1 — Giang Hồ Ký:** module `js/chronicle.js` — event bus ghi sự kiện, UI tab ký, dữ liệu quan hệ NPC trong save v2.
- **Giai đoạn 2 — Trùng Sinh:** module `js/reincarnate.js` — logic Tọa Hóa, tính Ký ức, shop Ký ức, reset có kiểm soát (giữ stash chung + ký).
- **Giai đoạn 3 — Nội dung mới:** kịch bản theo kiếp, đại sự giang hồ, Vụn Vỡ, tuyến Viên Mãn.

## 5. Nguyên tắc

- Không phá save: mọi schema mới đều version + migrate từ phiên bản trước.
- Giữ tinh thần idle: mọi hệ thống mới phải có phần hưởng lợi khi AFK, không ép online liên tục.
