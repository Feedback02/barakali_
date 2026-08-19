// Firebase Cloud Messaging service worker (web background/closed delivery).
//
// This file is committed but holds NO project config: the (public) Firebase web
// config is passed at registration time via the query string — see
// FcmService._serviceWorkerPath() — and read here from self.location.search, so
// the config stays in the gitignored .env like the rest of the app's keys.
importScripts(
  'https://www.gstatic.com/firebasejs/12.14.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/12.14.0/firebase-messaging-compat.js',
);

const params = new URL(self.location).searchParams;

firebase.initializeApp({
  apiKey: params.get('apiKey'),
  appId: params.get('appId'),
  messagingSenderId: params.get('messagingSenderId'),
  projectId: params.get('projectId'),
});

// Messages carrying a `notification` payload are shown automatically by the
// browser when the page is in the background, so we must NOT show them again
// here or the user gets two notifications. onBackgroundMessage only handles
// data-only messages (no `notification` block) — the path we'd use if we add
// silent/data pushes later.
const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  if (payload && payload.notification) return; // SDK already displayed it
  const d = (payload && payload.data) || {};
  self.registration.showNotification(d.title || 'Barakali', {
    body: d.body || '',
  });
});
