import { useState, useEffect, useCallback } from 'react';
import esp32Analyzer from '../services/esp32Analyzer';

/**
 * Hook untuk mengelola koneksi ESP32 di React Native
 */
const useESP32Connection = (monitoringInterval = 30000) => {
  const [isConnected, setIsConnected] = useState(false);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [fireAlarmData, setFireAlarmData] = useState(null);
  const [systemInfo, setSystemInfo] = useState(null);

  // Test connection
  const testConnection = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await esp32Analyzer.testConnection();
      setIsConnected(result.success);
      
      if (result.success) {
        const currentStats = esp32Analyzer.getStats();
        setStats(currentStats);
      } else {
        setError(result.error);
      }
      
      return result;
    } catch (err) {
      console.error('ESP32 Connection test error:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  }, []);

  // Get fire alarm data
  const getFireAlarmData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await esp32Analyzer.getFireAlarmData();
      
      if (result.success) {
        setFireAlarmData(result.data);
      } else {
        setError(result.error);
      }
      
      return result;
    } catch (err) {
      console.error('Get fire alarm data error:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  }, []);

  // Send command
  const sendCommand = useCallback(async (command, parameters = {}) => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await esp32Analyzer.sendCommand(command, parameters);
      
      if (result.success) {
        // Refresh stats after command
        setTimeout(() => {
          const currentStats = esp32Analyzer.getStats();
          setStats(currentStats);
        }, 500);
      } else {
        setError(result.error);
      }
      
      return result;
    } catch (err) {
      console.error('Send command error:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  }, []);

  // Get system info
  const getSystemInfo = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await esp32Analyzer.getSystemInfo();
      
      if (result.success) {
        setSystemInfo(result.data);
      } else {
        setError(result.error);
      }
      
      return result;
    } catch (err) {
      console.error('Get system info error:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  }, []);

  // Start monitoring
  const startMonitoring = useCallback(() => {
    esp32Analyzer.startMonitoring(monitoringInterval);
  }, [monitoringInterval]);

  // Stop monitoring
  const stopMonitoring = useCallback(() => {
    esp32Analyzer.stopMonitoring();
  }, []);

  // Refresh all data
  const refresh = useCallback(async () => {
    await testConnection();
    if (isConnected) {
      await getFireAlarmData();
      await getSystemInfo();
    }
  }, [isConnected, testConnection, getFireAlarmData, getSystemInfo]);

  // Initial connection test
  useEffect(() => {
    testConnection();
  }, []);

  // Auto-refresh stats every 5 seconds
  useEffect(() => {
    if (isConnected) {
      const interval = setInterval(() => {
        const currentStats = esp32Analyzer.getStats();
        setStats(currentStats);
      }, 5000);

      return () => clearInterval(interval);
    }
  }, [isConnected]);

  return {
    // Connection state
    isConnected,
    loading,
    error,
    stats,
    
    // Data
    fireAlarmData,
    systemInfo,
    
    // Methods
    testConnection,
    getFireAlarmData,
    sendCommand,
    getSystemInfo,
    startMonitoring,
    stopMonitoring,
    refresh
  };
};

export default useESP32Connection;