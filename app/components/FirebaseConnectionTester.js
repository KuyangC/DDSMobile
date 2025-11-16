import React, { useState } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  TouchableOpacity, 
  Alert
} from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import useFirebaseConnection from '../hooks/useFirebaseConnection';
import FirebaseConfigModal from './FirebaseConfigModal';
import NotificationToast from './NotificationToast';
import firebaseConfigService from '../services/firebaseConfigService';

const FirebaseConnectionTester = () => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const {
    isConnected,
    loading,
    error,
    configStatus,
    stats,
    testConnection,
    saveConfiguration,
    resetConfiguration,
    getCurrentConfig,
    isConfigured,
    getFirebaseConfig,
    refresh
  } = useFirebaseConnection();

  const [showConfigModal, setShowConfigModal] = useState(false);
  const [currentConfig, setCurrentConfig] = useState(null);
  const [notification, setNotification] = useState({
    visible: false,
    type: 'success',
    title: '',
    message: ''
  });

  // Load current config on mount
  React.useEffect(() => {
    const loadConfig = async () => {
      try {
        const config = await firebaseConfigService.loadConfig();
        setCurrentConfig(config);
        console.log('📱 Current Firebase config loaded:', config);
      } catch (error) {
        console.error('Failed to load config:', error);
      }
    };
    loadConfig();
  }, []);

  const showNotification = (type, title, message) => {
    setNotification({
      visible: true,
      type,
      title,
      message
    });
  };

  if (!fontsLoaded) {
    return null;
  }

  const getStatusColor = (connected) => {
    return connected ? '#11B653' : '#FF3B30';
  };

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp).toLocaleString();
  };

  const handleTestConnection = async () => {
    const result = await testConnection();
    if (result.success) {
      showNotification(
        'success',
        'Connection Successful',
        'Firebase connection is working properly'
      );
    } else {
      showNotification(
        'error',
        'Connection Failed',
        result.error
      );
    }
  };

  const handleResetConfig = () => {
    Alert.alert(
      'Reset Configuration',
      'Are you sure you want to reset Firebase configuration to defaults?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset',
          style: 'destructive',
          onPress: async () => {
            const result = await resetConfiguration();
            if (result.success) {
              setCurrentConfig(firebaseConfigService.getConfig());
              showNotification(
                'success',
                'Configuration Reset',
                'Firebase configuration has been reset to defaults'
              );
            } else {
              showNotification(
                'error',
                'Reset Failed',
                result.error
              );
            }
          }
        }
      ]
    );
  };

  const getSuccessRate = () => {
    if (stats.connectionTests === 0) return '0%';
    return Math.round((stats.successfulTests / stats.connectionTests) * 100) + '%';
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Firebase Connection</Text>
        <View style={styles.statusRow}>
          <View style={[styles.statusIndicator, { backgroundColor: getStatusColor(isConnected) }]} />
          <Text style={[styles.statusText, { color: getStatusColor(isConnected) }]}>
            {isConnected ? 'Connected' : 'Disconnected'}
          </Text>
        </View>
      </View>

      {/* Configuration Status */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Configuration Status</Text>
          <TouchableOpacity 
            style={styles.editButton} 
            onPress={() => setShowConfigModal(true)}
          >
            <Text style={styles.editButtonText}>Edit</Text>
          </TouchableOpacity>
        </View>
        
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Status:</Text>
          <Text style={[styles.infoValue, { color: configStatus?.color || getStatusColor(isConnected) }]}>
            {configStatus?.message || (isConnected ? 'Configured' : 'Not Configured')}
          </Text>
        </View>
        
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Project ID:</Text>
          <Text style={styles.infoValue}>
            {currentConfig?.projectId || 'Not Set'}
          </Text>
        </View>
        
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Database URL:</Text>
          <Text style={[styles.infoValue, { fontSize: 12 }]} numberOfLines={1}>
            {currentConfig?.databaseURL || 'Not Set'}
          </Text>
        </View>
      </View>

      {/* Connection Statistics */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Connection Statistics</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Connection Tests:</Text>
          <Text style={styles.infoValue}>{stats.connectionTests}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Successful Tests:</Text>
          <Text style={styles.infoValue}>{stats.successfulTests}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Success Rate:</Text>
          <Text style={styles.infoValue}>{getSuccessRate()}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Avg Response:</Text>
          <Text style={styles.infoValue}>{stats.averageResponseTime}ms</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Last Test:</Text>
          <Text style={styles.infoValue}>{formatTimestamp(stats.lastTestTime)}</Text>
        </View>
      </View>

      {/* Firebase Info */}
      {currentConfig && isConfigured() && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Firebase Information</Text>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Auth Domain:</Text>
            <Text style={[styles.infoValue, { fontSize: 12 }]} numberOfLines={1}>
              {currentConfig.authDomain}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Storage Bucket:</Text>
            <Text style={[styles.infoValue, { fontSize: 12 }]} numberOfLines={1}>
              {currentConfig.storageBucket}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>App ID:</Text>
            <Text style={[styles.infoValue, { fontSize: 10 }]} numberOfLines={1}>
              {currentConfig.appId}
            </Text>
          </View>
          {currentConfig.measurementId && (
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Measurement ID:</Text>
              <Text style={styles.infoValue}>{currentConfig.measurementId}</Text>
            </View>
          )}
        </View>
      )}

      {/* Action Buttons */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Actions</Text>
        <View style={styles.buttonGrid}>
          <TouchableOpacity 
            style={[styles.button, styles.refreshButton]} 
            onPress={refresh}
            disabled={loading}
          >
            <Text style={styles.buttonText}>Refresh</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.testButton]} 
            onPress={handleTestConnection}
            disabled={loading}
          >
            <Text style={styles.buttonText}>Test Connection</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.configButton]} 
            onPress={() => setShowConfigModal(true)}
          >
            <Text style={styles.buttonText}>Configure</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.resetButton]} 
            onPress={handleResetConfig}
            disabled={loading}
          >
            <Text style={styles.buttonText}>Reset Config</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Error Display */}
      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorTitle}>Connection Error</Text>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {/* Loading Indicator */}
      {loading && (
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Processing...</Text>
        </View>
      )}

      {/* Configuration Modal */}
      <FirebaseConfigModal
        visible={showConfigModal}
        onClose={() => setShowConfigModal(false)}
        onConfigUpdated={async (newConfig) => {
          console.log('🔄 Firebase config updated:', newConfig);
          setCurrentConfig(newConfig);
          
          // Close modal first
          setShowConfigModal(false);
          
          // Show success notification
          showNotification(
            'success',
            'Configuration Saved',
            'Firebase configuration updated successfully'
          );
          
          // Test connection after config change
          setTimeout(async () => {
            const testResult = await testConnection();
            if (testResult.success) {
              showNotification(
                'success',
                'Connection Success',
                'Firebase connected successfully!'
              );
            } else {
              showNotification(
                'error',
                'Connection Failed',
                'Could not connect to Firebase. Please check configuration.'
              );
            }
          }, 1000);
        }}
      />

      {/* Notification Toast */}
      <NotificationToast
        visible={notification.visible}
        type={notification.type}
        title={notification.title}
        message={notification.message}
        onHide={() => {
          setNotification(prev => ({ ...prev, visible: false }));
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    padding: 20,
    backgroundColor: '#f8f8f8',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 24,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
    marginBottom: 15,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 8,
  },
  statusText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
  },
  section: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
  },
  editButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  editButtonText: {
    fontSize: 12,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  infoLabel: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    flex: 1,
  },
  infoValue: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#333',
    flex: 1.5,
    textAlign: 'right',
  },
  buttonGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 15,
    paddingVertical: 12,
    borderRadius: 8,
    marginBottom: 10,
    minWidth: '48%',
  },
  refreshButton: {
    backgroundColor: '#5856D6',
  },
  testButton: {
    backgroundColor: '#007AFF',
  },
  configButton: {
    backgroundColor: '#11B653',
  },
  resetButton: {
    backgroundColor: '#FF9500',
  },
  buttonText: {
    color: '#fff',
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    textAlign: 'center',
  },
  errorContainer: {
    margin: 20,
    padding: 15,
    backgroundColor: '#FFE5E5',
    borderRadius: 8,
  },
  errorTitle: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#FF3B30',
    marginBottom: 5,
  },
  errorText: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
  },
  loadingContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
});

export default FirebaseConnectionTester;