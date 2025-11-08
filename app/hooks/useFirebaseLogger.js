import { useEffect } from 'react';
import { db as database } from '../config/firebaseConfig'; // Corrected import: db is exported, but we alias it to database for consistency in this file.
import { ref, set, onValue, off } from 'firebase/database';

export const useFirebaseLogger = () => {
  useEffect(() => {
    console.log('\n🔄 Checking Firebase connection...');

    // Check if Firebase is available
    if (!database) {
      console.log('💡 Firebase not available - running in offline mode');
      return;
    }

    let unsubscribeTest = null;

    const testConnection = async () => {
      try {
        const testRef = ref(database, 'connectionTests/' + Date.now());
        
        const testData = {
          status: 'connected',
          timestamp: new Date().toISOString(),
          environment: process.env.EXPO_PUBLIC_APP_ENV || 'development',
          platform: 'Mobile App'
        };

        // Test write operation
        await set(testRef, testData);
        console.log('✅ Firebase write: SUCCESS');

        // Test read operation
        unsubscribeTest = onValue(testRef, (snapshot) => {
          const data = snapshot.val();
          console.log('✅ Firebase read: SUCCESS', {
            timestamp: data.timestamp,
            environment: data.environment
          });
        }, { onlyOnce: true });

      } catch (error) {
        console.error('❌ Firebase connection test failed:', error.message);
      }
    };

    // Real-time connection status monitor
    const connectedRef = ref(database, '.info/connected');
    const connectionListener = onValue(connectedRef, (snapshot) => {
      const connected = snapshot.val();
      const timestamp = new Date().toLocaleTimeString();
      
      if (connected === true) {
        console.log(`🟢 [${timestamp}] Firebase: CONNECTED`);
      } else {
        console.log(`🔴 [${timestamp}] Firebase: DISCONNECTED`);
      }
    });

    // Run connection test
    testConnection();

    // Cleanup function
    return () => {
      if (unsubscribeTest) {
        unsubscribeTest();
      }
      off(connectedRef);
      console.log('🧹 Firebase listeners cleaned up');
    };
  }, []);
};