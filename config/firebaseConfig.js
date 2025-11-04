import { initializeApp } from 'firebase/app';
    import { getDatabase } from 'firebase/database';

    const firebaseConfig = {
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_AUTH_DOMAIN",
      projectId: "testing1do-default-rtdb", // Misalnya: testing1do
      storageBucket: "YOUR_STORAGE_BUCKET",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      appId: "YOUR_APP_ID",
      databaseURL: "https://console.firebase.google.com/u/4/project/testing1do/database/testing1do-default-rtdb/data/~2F", 
    };

    // Inisialisasi Firebase
    const app = initializeApp(firebaseConfig);
    const database = getDatabase(app);

    export { database };