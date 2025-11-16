import { useState, useEffect } from 'react';
import firebaseConfigService from '../services/firebaseConfigService';

const useFirebaseConnection = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [configStatus, setConfigStatus] = useState(null);
  const [stats, setStats] = useState({
    connectionTests: 0,
    successfulTests: 0,
    lastTestTime: null,
    averageResponseTime: 0
  });

  // Load initial configuration and status
  useEffect(() => {
    loadConfiguration();
    subscribeToConfigChanges();
  }, []);

  const loadConfiguration = async () => {
    try {
      setLoading(true);
      await firebaseConfigService.loadConfig();
      updateStatus();
    } catch (error) {
      console.error('Failed to load Firebase configuration:', error);
      setError('Failed to load configuration');
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = () => {
    const status = firebaseConfigService.getConfigStatus();
    setConfigStatus(status);
    setIsConnected(status.status === 'configured');
  };

  const subscribeToConfigChanges = () => {
    const unsubscribe = firebaseConfigService.subscribe(() => {
      updateStatus();
    });
    return unsubscribe;
  };

  const testConnection = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const startTime = Date.now();
      const result = await firebaseConfigService.testConnection();
      const responseTime = Date.now() - startTime;

      // Update stats
      const newStats = {
        connectionTests: stats.connectionTests + 1,
        successfulTests: stats.successfulTests + (result.success ? 1 : 0),
        lastTestTime: new Date().toISOString(),
        averageResponseTime: Math.round(
          (stats.averageResponseTime * stats.connectionTests + responseTime) / (stats.connectionTests + 1)
        )
      };
      setStats(newStats);

      if (result.success) {
        setIsConnected(true);
        setError(null);
      } else {
        setIsConnected(false);
        setError(result.error);
      }

      return {
        ...result,
        responseTime,
        stats: newStats
      };
    } catch (error) {
      const errorMessage = error.message || 'Connection test failed';
      setError(errorMessage);
      setIsConnected(false);
      
      return {
        success: false,
        error: errorMessage,
        responseTime: 0
      };
    } finally {
      setLoading(false);
    }
  };

  const saveConfiguration = async (config) => {
    try {
      setLoading(true);
      setError(null);

      // Validate configuration before saving
      const validation = firebaseConfigService.validateConfig(config);
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      const success = await firebaseConfigService.saveConfig(config);
      
      if (success) {
        updateStatus();
        // Test the new configuration
        await testConnection();
      } else {
        throw new Error('Failed to save configuration');
      }

      return { success: true };
    } catch (error) {
      const errorMessage = error.message || 'Failed to save configuration';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const resetConfiguration = async () => {
    try {
      setLoading(true);
      setError(null);

      const success = await firebaseConfigService.resetToDefaults();
      
      if (success) {
        updateStatus();
        setIsConnected(false);
        setError(null);
      }

      return { success };
    } catch (error) {
      const errorMessage = error.message || 'Failed to reset configuration';
      setError(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const getCurrentConfig = () => {
    return firebaseConfigService.getConfig();
  };

  const isConfigured = () => {
    return firebaseConfigService.isConfigured();
  };

  const getFirebaseConfig = () => {
    return firebaseConfigService.getFirebaseConfig();
  };

  const refresh = async () => {
    await loadConfiguration();
    if (isConfigured()) {
      return await testConnection();
    }
    return { success: false, error: 'Firebase not configured' };
  };

  return {
    // State
    isConnected,
    loading,
    error,
    configStatus,
    stats,

    // Methods
    testConnection,
    saveConfiguration,
    resetConfiguration,
    getCurrentConfig,
    isConfigured,
    getFirebaseConfig,
    refresh,
    loadConfiguration
  };
};

export default useFirebaseConnection;