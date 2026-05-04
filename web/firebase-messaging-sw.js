// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCg9LhLvbUKcWxO6rNabImM3vIQLwh0R6A",
  authDomain: "mad-project2-5a7b8.firebaseapp.com",
  projectId: "mad-project2-5a7b8",
  messagingSenderId: "37925678934",
  appId: "1:37925678934:web:bfc5fa8ddbcd2b8deeb0f7",
});

const messaging = firebase.messaging();
