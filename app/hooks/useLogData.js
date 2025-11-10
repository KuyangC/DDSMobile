import { useState, useEffect } from 'react';
import logService from '../services/logService';

/**
 * Simple hook untuk mengelola log data
 */
const useLogData = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const logsData = await logService.getLogs(100);
      setLogs(logsData);
      setError(null);
    } catch (err) {
      console.error('Failed to fetch logs:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const logEvent = async (eventType, details) => {
    try {
      const newLog = await logService.logEvent(eventType, details);
      // Refresh logs after adding new event
      fetchLogs();
      return newLog;
    } catch (err) {
      console.error('Failed to log event:', err);
      throw err;
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  return {
    logs,
    loading,
    error,
    logEvent,
    fetchLogs
  };
};

export default useLogData;