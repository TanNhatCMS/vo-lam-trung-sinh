// Sinh export_shells/web_shell.html cho preset Web — nhúng ảnh chân dung dạng base64
// để shell không phụ thuộc file ngoài (export không copy file tùy ý ra thư mục web).
// Chạy lại sau khi đổi ảnh:  node game/tools/build_shell.mjs
import fs from 'fs';
import path from 'path';
import url from 'url';

const GAME = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..');
const OUT = path.join(GAME, 'export_shells', 'web_shell.html');
const portrait = fs.readFileSync(path.join(GAME, 'assets', 'demo', 'shaolin.png')).toString('base64');

const html = `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<title>Võ Lâm Trùng Sinh</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; overflow: hidden; background: #0b100e; }
  body {
    font-family: "Segoe UI", "Noto Serif", serif;
    display: flex; align-items: center; justify-content: center;
    background: radial-gradient(ellipse at 50% 30%, #17241f 0%, #0b100e 65%);
    color: #e6dfc8;
  }
  canvas#canvas { position: fixed; inset: 0; width: 100%; height: 100%; visibility: hidden; }
  canvas#canvas.ready { visibility: visible; }
  #loader { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 24px; text-align: center; transition: opacity .5s; }
  #loader.done { opacity: 0; pointer-events: none; }
  .portrait {
    width: 120px; height: 155px; object-fit: contain;
    filter: drop-shadow(0 6px 18px rgba(0,0,0,.8));
    animation: float 3s ease-in-out infinite;
  }
  @keyframes float { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }
  h1 {
    font-size: 40px; letter-spacing: 2px; font-weight: 700;
    color: #f5d97e;
    text-shadow: 0 0 18px rgba(245,217,126,.35), 0 2px 0 #3a2c10, 0 4px 10px rgba(0,0,0,.9);
  }
  .quote { font-size: 14px; font-style: italic; color: #9aa08e; max-width: 420px; min-height: 20px; }
  .barbox { width: min(420px, 78vw); height: 14px; border-radius: 8px; background: #101815; border: 1px solid rgba(245,217,126,.35); overflow: hidden; box-shadow: inset 0 1px 4px rgba(0,0,0,.8); }
  #bar { height: 100%; width: 0%; border-radius: 8px; background: linear-gradient(90deg, #8a6d1f, #f5d97e, #8a6d1f); background-size: 200% 100%; animation: shine 1.6s linear infinite; transition: width .15s; }
  @keyframes shine { to { background-position: -200% 0; } }
  #pct { font-size: 13px; color: #c8bfa2; letter-spacing: 1px; }
  #status-text { font-size: 14px; color: #b9b29a; min-height: 18px; }
  #err { display: none; font-size: 14px; color: #ff7a68; max-width: 480px; white-space: pre-wrap; }
  .hint { font-size: 12px; color: #5d665b; margin-top: 6px; }
</style>
$GODOT_HEAD_INCLUDE
</head>
<body>
<canvas id="canvas"></canvas>
<div id="loader">
  <img class="portrait" alt="" src="data:image/png;base64,__PORTRAIT_B64__">
  <h1>VÕ LÂM TRÙNG SINH</h1>
  <div class="quote" id="quote">Giang hồ là một cuốn ký đang viết dở…</div>
  <div class="barbox"><div id="bar"></div></div>
  <div id="pct">0%</div>
  <div id="status-text">Đang chuẩn bị thế giới…</div>
  <div id="err"></div>
  <div class="hint">Mẹo: luyện công vẫn tính khi bạn offline tối đa 8 giờ</div>
</div>
<script type="text/javascript" src="$GODOT_URL"></script>
<script type="text/javascript">
const GODOT_CONFIG = $GODOT_CONFIG;
const GODOT_THREADS_ENABLED = $GODOT_THREADS_ENABLED;
const engine = new Engine(GODOT_CONFIG);

const bar = document.getElementById('bar');
const pct = document.getElementById('pct');
const statusText = document.getElementById('status-text');
const errBox = document.getElementById('err');
const quotes = [
  'Giang hồ là một cuốn ký đang viết dở…',
  'Kiếm không hỏi phải trái, chỉ hỏi tâm có chính.',
  'Nhất thân nhất ảnh, độc bộ giang hồ.',
  'Trùng sinh không phải để sống lại — mà để sống đúng hơn.',
  'Có võ công mới đủ sức bảo vệ điều mình thương.',
];
let qi = 0;
setInterval(() => { qi = (qi + 1) % quotes.length; document.getElementById('quote').textContent = quotes[qi]; }, 4000);

const setStatus = (s) => { statusText.textContent = s; };

engine.startGame({
  onProgress(current, total) {
    const p = total > 0 ? Math.round((current / total) * 100) : 0;
    bar.style.width = p + '%';
    pct.textContent = p + '%';
    setStatus(p < 35 ? 'Đang tải thế giới giang hồ…' : p < 85 ? 'Đang tải võ công tuyệt học…' : 'Sắp vào game…');
  },
}).then(() => {
  setStatus('Vào game!');
  const canvas = document.getElementById('canvas');
  const loader = document.getElementById('loader');
  canvas.classList.add('ready');
  loader.classList.add('done');
  setTimeout(() => loader.remove(), 600);
}).catch((err) => {
  errBox.style.display = 'block';
  errBox.textContent = 'Không tải được game: ' + err;
  setStatus('');
});
</script>
</body>
</html>
`;

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, html.replace('__PORTRAIT_B64__', portrait));
console.log('Đã sinh', OUT, Math.round(fs.statSync(OUT).size / 1024) + ' KB');
