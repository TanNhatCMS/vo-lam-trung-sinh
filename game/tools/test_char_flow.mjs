// Test flow tạo nhân vật qua WebSocket: welcome → char_ok / char_err (2 peer để test trùng tên)
const url = process.env.TEST_URL || 'ws://127.0.0.1:9000';
let fails = 0;
const pass = (ok, what) => { console.log((ok ? 'PASS ✓' : 'FAIL ✗'), what); if (!ok) fails++; };

function open() {
  return new Promise((res, rej) => {
    const ws = new WebSocket(url);
    const q = [];
    ws.onmessage = async (e) => {
      const raw = typeof e.data === 'string' ? e.data : await e.data.text();
      const msg = JSON.parse(raw);
      if (q.length) q.shift()(msg);
    };
    ws.onopen = () => res({
      ws,
      send: (o) => ws.send(JSON.stringify(o)),
      wait: (ms = 3000) => new Promise((r, rej2) => q.push(r) || setTimeout(() => rej2(new Error('timeout')), ms)),
    });
    ws.onerror = () => rej(new Error('WS error'));
  });
}

const main = async () => {
  const p1 = await open();
  const w1 = await p1.wait();
  pass(w1.t === 'welcome', 'p1 nhận welcome');

  p1.send({ t: 'create_char', name: 'Kiếm Khách', fac: 'shaolin' });
  const ok1 = await p1.wait();
  pass(ok1.t === 'char_ok' && ok1.fac_name === 'Thiếu Lâm phái', 'p1 tạo NV hợp lệ (Thiếu Lâm)');

  const p2 = await open();
  await p2.wait(); // welcome
  p2.send({ t: 'create_char', name: 'Kiếm Khách', fac: 'emei' });
  const dup = await p2.wait();
  pass(dup.t === 'char_err' && String(dup.msg).includes('đã có người'), 'p2 trùng tên bị chặn');

  p1.send({ t: 'create_char', name: 'Ai Đó', fac: 'khongtonnai' });
  const badfac = await p1.wait();
  pass(badfac.t === 'char_err' && String(badfac.msg).includes('Phái không tồn tại'), 'phái lạ bị chặn');

  p1.send({ t: 'create_char', name: 'A', fac: 'shaolin' });
  const short = await p1.wait();
  pass(short.t === 'char_err' && String(short.msg).includes('Tên phải từ'), 'tên quá ngắn bị chặn');

  p1.ws.close(); p2.ws.close();
  console.log(fails === 0 ? 'ALL TESTS PASSED ✓' : `${fails} TEST(S) FAILED ✗`);
  process.exit(fails === 0 ? 0 : 1);
};
main().catch((e) => { console.log('ERROR:', e.message); process.exit(1); });
