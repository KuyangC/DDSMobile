import { db } from '../config/firebaseConfig';
import { ref, set, get, push } from 'firebase/database';

/**
 * Simple service untuk logging events ke Firebase
 */

// Path untuk logs di Firebase
const LOGS_PATH = 'fire_alarm_logs';

/**
 * Log an event to Firebase
 */
export const logEvent = async (eventType, details, slaveData = null, address = null) => {
  if (!db) {
    console.warn('⚠️ Firebase not available - log skipped');
    return null;
  }

  try {
    const logEntry = {
      timestamp: Date.now(),
      date: new Date().toISOString(),
      type: eventType,
      details: details,
      slaveData: slaveData,
      address: address
    };

    const logsRef = ref(db, LOGS_PATH);
    const newLogRef = push(logsRef);
    await set(newLogRef, logEntry);

    console.log(`✅ Event logged: ${eventType}`, logEntry);
    return logEntry;

  } catch (error) {
    console.error('❌ Failed to log event:', error);
    throw error;
  }
};

/**
 * Get logs from Firebase
 */
export const getLogs = async (limit = 100) => {
  if (!db) {
    throw new Error('Firebase not available');
  }

  try {
    const logsRef = ref(db, LOGS_PATH);
    const snapshot = await get(logsRef);
    const logs = snapshot.val() || {};

    // Convert to array and sort by timestamp (newest first)
    return Object.keys(logs).map(key => ({
      id: key,
      ...logs[key]
    })).sort((a, b) => b.timestamp - a.timestamp).slice(0, limit);

  } catch (error) {
    console.error('❌ Failed to get logs:', error);
    throw error;
  }
};

export default {
  logEvent,
  getLogs
};