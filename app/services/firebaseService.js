import { database } from '../config/firebaseConfig';
import { ref, set, get, onValue, off } from 'firebase/database';

export const firebaseService = {
  // Check if Firebase is available
  isAvailable: () => {
    return !!database;
  },

  // Write data to Firebase
  writeData: async (path, data) => {
    if (!database) {
      console.warn('⚠️ Firebase not available - write operation skipped');
      return null;
    }

    try {
      const dbRef = ref(database, path);
      await set(dbRef, {
        ...data,
        _createdAt: new Date().toISOString()
      });
      console.log('✅ Data written to:', path);
      return true;
    } catch (error) {
      console.error('❌ Write operation failed:', error);
      throw error;
    }
  },

  // Read data once
  readData: async (path) => {
    if (!database) {
      console.warn('⚠️ Firebase not available - read operation skipped');
      return null;
    }

    try {
      const dbRef = ref(database, path);
      const snapshot = await get(dbRef);
      return snapshot.val();
    } catch (error) {
      console.error('❌ Read operation failed:', error);
      throw error;
    }
  },

  // Real-time listener
  listenToData: (path, callback) => {
    if (!database) {
      console.warn('⚠️ Firebase not available - listener not set');
      return () => {};
    }

    try {
      const dbRef = ref(database, path);
      const unsubscribe = onValue(dbRef, (snapshot) => {
        callback(snapshot.val());
      });

      return () => off(dbRef);
    } catch (error) {
      console.error('❌ Listener setup failed:', error);
      return () => {};
    }
  }
};