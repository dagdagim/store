// Minimal Firebase Messaging service worker placeholder.
// Add firebase messaging initialization here if you enable FCM on web.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
