// Chuyển dữ liệu game từ các file JS gốc (data.js, world.js, rdata.js) sang JSON cho Godot.
// Chạy lại mỗi khi dữ liệu gốc đổi:  node game/tools/convert_data.mjs
import fs from 'fs';
import path from 'path';
import url from 'url';

const ROOT = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..', '..');
const OUT = path.join(ROOT, 'game', 'data');
fs.mkdirSync(OUT, { recursive: true });

// Mỗi file gốc có dạng window.TEN={...}; (rdata.js có comment đầu file nên tìm '=' đầu tiên vẫn đúng)
function extract(file) {
  const t = fs.readFileSync(path.join(ROOT, file), 'utf8');
  const eq = t.indexOf('=');
  return JSON.parse(t.slice(eq + 1).replace(/;\s*$/, ''));
}

const jobs = [
  ['data.js', 'jx.json'],   // kỹ năng, npc, item, affix, bản đồ nội tại, shop...
  ['world.js', 'jw.json'],  // zone, quái, hero, animation, thành trấn
  ['rdata.js', 'rcp.json'], // công thức chế tạo, mảnh ghép
];

for (const [src, dst] of jobs) {
  const obj = extract(src);
  const target = path.join(OUT, dst);
  fs.writeFileSync(target, JSON.stringify(obj));
  const kb = Math.round(fs.statSync(target).size / 1024);
  console.log(`${src} -> game/data/${dst} (${kb} KB, ${Object.keys(obj).length} nhóm)`);
}
