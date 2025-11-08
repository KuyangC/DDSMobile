import { useEffect, useState } from 'react';
import { ref, onValue } from 'firebase/database';
import { db } from '../config/firebaseConfig';

const useFirebaseRealtime = (path) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!path) {
      setLoading(false);
      return;
    }

    const dataRef = ref(db, path);
    const unsubscribe = onValue(dataRef, (snapshot) => {
      try {
        const snapshotData = snapshot.val();
        setData(snapshotData);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    }, (err) => {
      setError(err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [path]);

  return { data, loading, error };
};

export default useFirebaseRealtime;
