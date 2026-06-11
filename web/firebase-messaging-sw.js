importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyB20HCwSyTortda4dIovxuU-jcZK5qRSbM",
  appId: "1:255124081047:web:99a39fd71088cb97d35cd2",
  messagingSenderId: "255124081047",
  projectId: "kanngrow-ai-qwok",
  authDomain: "kanngrow-ai-qwok.firebaseapp.com",
  storageBucket: "kanngrow-ai-qwok.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
  const notificationTitle = payload.notification?.title || "Kangrow AI Notification";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/favicon.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
