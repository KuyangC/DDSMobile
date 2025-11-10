import { useState, useEffect } from 'react';
import { db } from '../config/firebaseConfig';
import { ref, onValue } from 'firebase/database';

/**
 * Hook untuk mengelola state silence mode aplikasi (local only)
 * Tidak mempengaruhi master status di backend/fire alarm panel
 */
const useAppSilence = () => {
  const [isSilenced, setIsSilenced] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!db) {
      setLoading(false);
      return;
    }

    // Listen to app state changes
    const appStateRef = ref(db, 'app_state/silence');
    
    const unsubscribe = onValue(appStateRef, (snapshot) => {
      const data = snapshot.val();
      setIsSilenced(data?.silenced || false);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { isSilenced, loading, setIsSilenced };
};

export default useAppSilence;