import { useState, useEffect } from 'react';
import useFirebaseRealtime from './useFirebaseRealtime';
import { processDataPooling } from '../utils/fireAlarmParser'; // Reverted to the original, correct parser

const useSlaveData = () => {
  const { data: rawDataObject, loading, error } = useFirebaseRealtime('all_slave_data');
  
  // This state will hold the parsed data: { masterStatus: {}, slaves: {} }
  const [processedData, setProcessedData] = useState({ masterStatus: {}, slaves: {} });

  useEffect(() => {
    // The data from Firebase is an object, e.g., { raw_data: "...", timestamp: "..." }
    // We need to specifically access the `raw_data` property.
    if (rawDataObject && typeof rawDataObject.raw_data === 'string') {
      const dataString = rawDataObject.raw_data;
      const newData = processDataPooling(dataString);
      setProcessedData(newData);
    } else {
      // If the data is not in the expected format, we reset to a default state.
      // The processDataPooling function initializes all slaves to OFFLINE when passed null.
      const defaultData = processDataPooling(null);
      setProcessedData(defaultData);
    }
  }, [rawDataObject]); // Effect runs when the object from Firebase changes

  // The UI component expects an object with a `slaves` property.
  // We pass the whole processed data object.
  return { slaveData: processedData, loading, error };
};

export default useSlaveData;