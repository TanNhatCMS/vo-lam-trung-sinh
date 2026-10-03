// Mang truoc, cache du phong: luon lay ban moi khi co mang, choi offline khi mat mang
const C = 'vlts-v1';
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== C).map(k => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  // bo qua request khac origin (vd chrome-extension cua tien ich trinh duyet)
  let url;
  try { url = new URL(e.request.url); } catch (_) { return; }
  if (url.origin !== self.location.origin) return;
  e.respondWith(fetch(e.request).then(r => {
    // chi cache 200 day du; bo qua 206 (audio streaming) va response khong ho tro cache
    if (r.status === 200) {
      const cp = r.clone();
      caches.open(C).then(c => c.put(e.request, cp)).catch(() => {});
    }
    return r;
  }).catch(() => caches.match(e.request)));
});
