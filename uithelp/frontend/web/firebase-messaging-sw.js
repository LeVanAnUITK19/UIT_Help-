importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Thay các giá trị này bằng config từ Firebase Console
// Project Settings → General → Your apps → Web app → SDK setup
firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  authDomain: "uitconnect-f20a8.firebaseapp.com",
  projectId: "uitconnect-f20a8",
  storageBucket: "uitconnect-f20a8.appspot.com",
  messagingSenderId: "856939611735",
  appId: "1:856939611735:web:c3cd88d2439be5cf7b0512",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, { body });
});
