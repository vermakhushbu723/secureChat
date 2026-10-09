// Push notifications for the web app / PWA (Firebase Cloud Messaging).
// Shows the notification while the tab is closed or in the background; a click opens the chat
// (the server sends the link with every message).
importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA8rqgvo4MSaPD-QHI5BvdMn-UbQEaHIjk',
  authDomain: 'proly-9337e.firebaseapp.com',
  projectId: 'proly-9337e',
  storageBucket: 'proly-9337e.firebasestorage.app',
  messagingSenderId: '42726587985',
  appId: '1:42726587985:web:194f2383ebf72f5d220270',
});

firebase.messaging();

// Open (or focus) the app on the chat of the notification.
self.addEventListener('notificationclick', (event) => {
  const link = event.notification?.data?.FCM_MSG?.data?.link || event.notification?.data?.link;
  if (!link) return;
  event.notification.close();
  const url = new URL(link, self.location.origin).href;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if (c.url.startsWith(self.location.origin) && 'focus' in c) {
          c.navigate(url);
          return c.focus();
        }
      }
      return clients.openWindow(url);
    }),
  );
});
