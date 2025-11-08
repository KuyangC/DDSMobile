import { db } from '../config/firebaseConfig';
import { ref, set, get } from 'firebase/database';

export const testFirebaseConnection = async () => {
  try {
    const testRef = ref(db, 'connectionTest');
    await set(testRef, {
      status: 'connected',
      timestamp: new Date().toISOString()
    });
    
    const snapshot = await get(testRef);
    console.log('✅ Firebase connection test:', snapshot.val());
    return { success: true, data: snapshot.val() };
  } catch (error) {
    console.error('❌ Firebase connection failed:', error);
    return { success: false, error: error.message };
  }
};