// Test flow GĐ 3: register → login → create_char (giới hạn 3 NV, trùng tên chéo tài khoản)
// wait() chỉ quét message MỚI từ lúc gọi (tránh khớp message cũ đã tiêu thụ).
const url = process.env.TEST_URL || 'ws://127.0.0.1:9000';
const SUFFIX = Math.random().toString(36).slice(2, 6);
const USER1 = 'tester_' + SUFFIX;
const USER2 = 'tester2_' + SUFFIX;
let fails = 0;
const pass = (ok, what) => { console.log((ok ? 'PASS ✓' : 'FAIL ✗'), what); if (!ok) fails++; };

function open() {
  return new Promise((res, rej) => {
    const ws = new WebSocket(url);
    const seen = [];
    const scanners = [];
    ws.onmessage = async (e) => {
      const raw = typeof e.data === 'string' ? e.data : await e.data.text();
      const msg = JSON.parse(raw);
      if (msg.t === 'ping') return;
      seen.push(msg);
      for (let i = scanners.length - 1; i >= 0; i--) {
        if (scanners[i]()) scanners.splice(i, 1);
      }
    };
    ws.onopen = () => res({
      ws,
      send: (o) => ws.send(JSON.stringify(o)),
      wait: (pred, what, ms = 4000) => new Promise((resolve, reject) => {
        const base = seen.length;
        let timer;
        const scan = () => {
          for (let i = base; i < seen.length; i++) {
            if (pred(seen[i])) {
              clearTimeout(timer);
              resolve(seen[i]);
              return true;
            }
          }
          return false;
        };
        if (scan()) return;
        timer = setTimeout(() => reject(new Error('timeout chờ: ' + what)), ms);
        scanners.push(scan);
      }),
    });
    ws.onerror = () => rej(new Error('WS error'));
  });
}

const main = async () => {
  const p1 = await open();
  await p1.wait((m) => m.t === 'welcome', 'welcome');
  pass(true, 'p1 welcome');

  p1.send({ t: 'register', user: USER1, pass: 'matkhau1' });
  const reg = await p1.wait((m) => m.t === 'reg_ok' || m.t === 'reg_err', 'reg');
  pass(reg.t === 'reg_ok', 'p1 đăng ký OK');
  const lo = await p1.wait((m) => m.t === 'login_ok', 'login_ok');
  pass(lo.user === USER1 && lo.chars.length === 0, 'p1 tự đăng nhập sau đăng ký');

  const facs = ['shaolin', 'emei', 'wudang'];
  for (let i = 0; i < 3; i++) {
    p1.send({ t: 'create_char', name: `Hiệp${i}${SUFFIX}`, fac: facs[i] });
    const r = await p1.wait((m) => m.t === 'char_created' || m.t === 'char_err', 'create ' + i);
    pass(r.t === 'char_created' && r.chars.length === i + 1, `tạo nhân vật ${i + 1}/3`);
  }
  p1.send({ t: 'create_char', name: 'Vuot' + SUFFIX, fac: 'tangmen' });
  const limit = await p1.wait((m) => m.t === 'char_created' || m.t === 'char_err', 'limit');
  pass(limit.t === 'char_err' && String(limit.msg).includes('Tối đa'), 'chặn quá 3 nhân vật');

  const p2 = await open();
  await p2.wait((m) => m.t === 'welcome', 'welcome p2');
  p2.send({ t: 'register', user: USER2, pass: 'matkhau2' });
  await p2.wait((m) => m.t === 'login_ok', 'login p2');
  p2.send({ t: 'create_char', name: `Hiệp0${SUFFIX}`, fac: 'emei' });
  const dup = await p2.wait((m) => m.t === 'char_created' || m.t === 'char_err', 'dup');
  pass(dup.t === 'char_err' && String(dup.msg).includes('đã có người'), 'tên NV trùng chéo tài khoản bị chặn');

  p2.send({ t: 'create_char', name: 'Đơn' + SUFFIX, fac: 'wudu' });
  const solo = await p2.wait((m) => m.t === 'char_created' || m.t === 'char_err', 'solo');
  pass(solo.t === 'char_created', 'p2 tạo NV riêng OK');

  const p3 = await open();
  await p3.wait((m) => m.t === 'welcome', 'welcome p3');
  p3.send({ t: 'login', user: USER1, pass: 'sai_roi' });
  const bad = await p3.wait((m) => m.t === 'login_ok' || m.t === 'login_err', 'bad pass');
  pass(bad.t === 'login_err' && String(bad.msg).includes('Sai mật khẩu'), 'sai mật khẩu bị chặn');

  p3.send({ t: 'login', user: USER1, pass: 'matkhau1' });
  const re = await p3.wait((m) => m.t === 'login_ok' || m.t === 'login_err', 'relogin');
  pass(re.t === 'login_ok' && re.chars.length === 3, 'đăng nhập lại đủ 3 NV');

  p1.ws.close(); p2.ws.close(); p3.ws.close();
  console.log(fails === 0 ? 'ALL TESTS PASSED ✓' : `${fails} TEST(S) FAILED ✗`);
  process.exit(fails === 0 ? 0 : 1);
};
main().catch((e) => { console.log('ERROR:', e.message); process.exit(1); });
