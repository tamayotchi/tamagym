/* tamagym runtime cache. Account and gym data under /api are never cached. */
const CACHE = 'tamagym-runtime-v1'

self.addEventListener('install', () => self.skipWaiting())
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))
  ).then(() => self.clients.claim()))
})

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url)
  if (event.request.method !== 'GET' || url.origin !== location.origin) return
  if (url.pathname.startsWith('/api/')) return

  const media = url.pathname.startsWith('/img/') || url.pathname.startsWith('/gif/')
  if (media) {
    event.respondWith(caches.open(CACHE).then(cache => cache.match(event.request).then(hit =>
      hit || fetch(event.request).then(response => {
        if (response.ok) cache.put(event.request, response.clone())
        return response
      })
    )))
    return
  }

  event.respondWith(fetch(event.request).then(response => {
    if (response.ok) caches.open(CACHE).then(cache => cache.put(event.request, response.clone()))
    return response
  }).catch(() => caches.match(event.request).then(hit => hit || caches.match('/'))))
})
