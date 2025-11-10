import React, { useState } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  ScrollView, 
  TouchableOpacity, 
  RefreshControl,
  Alert
} from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import useESP32Connection from '../hooks/useESP32Connection';

const ESP32ConnectionTester = () => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const {
    isConnected,
    loading,
    error,
    stats,
    fireAlarmData,
    systemInfo,
    testConnection,
    getFireAlarmData,
    sendCommand,
    getSystemInfo,
    refresh
  } = useESP32Connection();

  const [testingCommand, setTestingCommand] = useState(false);

  if (!fontsLoaded) {
    return null;
  }

  const handleTestCommand = async (command) => {
    setTestingCommand(true);
    try {
      const result = await sendCommand(command);
      if (result.success) {
        Alert.alert('Success', `${command} command sent successfully`);
      } else {
        Alert.alert('Error', `Failed to send ${command}: ${result.error}`);
      }
    } catch (err) {
      Alert.alert('Error', `Command error: ${err.message}`);
    } finally {
      setTestingCommand(false);
    }
  };

  const getStatusColor = (connected) => {
    return connected ? '#11B653' : '#FF3B30';
  };

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp).toLocaleString();
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>ESP32 Connection</Text>
        <View style={styles.statusRow}>
          <View style={[styles.statusIndicator, { backgroundColor: getStatusColor(isConnected) }]} />
          <Text style={[styles.statusText, { color: getStatusColor(isConnected) }]}>
            {isConnected ? 'Connected' : 'Disconnected'}
          </Text>
        </View>
      </View>

      {/* Connection Info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Connection Details</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>IP Address:</Text>
          <Text style={styles.infoValue}>192.168.43.246</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Status:</Text>
          <Text style={[styles.infoValue, { color: getStatusColor(isConnected) }]}>
            {isConnected ? 'Online' : 'Offline'}
          </Text>
        </View>
        {stats && (
          <>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Total Requests:</Text>
              <Text style={styles.infoValue}>{stats.totalRequests}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Success Rate:</Text>
              <Text style={styles.infoValue}>{stats.successRate}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Avg Response:</Text>
              <Text style={styles.infoValue}>{stats.avgResponseTime}</Text>
            </View>
          </>
        )}
      </View>

      {/* System Info */}
      {systemInfo && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>System Information</Text>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Firmware:</Text>
            <Text style={styles.infoValue}>{systemInfo.firmware || 'N/A'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>MAC Address:</Text>
            <Text style={styles.infoValue}>{systemInfo.mac || 'N/A'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>WiFi Signal:</Text>
            <Text style={styles.infoValue}>{systemInfo.wifiSignal || 'N/A'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Uptime:</Text>
            <Text style={styles.infoValue}>{systemInfo.uptime || 'N/A'}</Text>
          </View>
        </View>
      )}

      {/* Fire Alarm Data */}
      {fireAlarmData && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Fire Alarm Status</Text>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Master Status:</Text>
            <Text style={styles.infoValue}>{fireAlarmData.masterStatus || 'N/A'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Total Slaves:</Text>
            <Text style={styles.infoValue}>{fireAlarmData.slaves?.length || 0}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Active Alarms:</Text>
            <Text style={styles.infoValue}>
              {fireAlarmData.slaves?.filter(s => s.status === 'ALARM').length || 0}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Active Troubles:</Text>
            <Text style={styles.infoValue}>
              {fireAlarmData.slaves?.filter(s => s.status === 'TROUBLE').length || 0}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Last Update:</Text>
            <Text style={styles.infoValue}>
              {formatTimestamp(fireAlarmData.timestamp)}
            </Text>
          </View>
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
            onPress={testConnection}
            disabled={loading}
          >
            <Text style={styles.buttonText}>Test Connection</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.dataButton]} 
            onPress={getFireAlarmData}
            disabled={!isConnected || loading}
          >
            <Text style={styles.buttonText}>Get Data</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.infoButton]} 
            onPress={getSystemInfo}
            disabled={!isConnected || loading}
          >
            <Text style={styles.buttonText}>System Info</Text>
          </TouchableOpacity>
        </View>

        {/* Command Testing */}
        <Text style={styles.sectionTitle}>Command Testing</Text>
        <View style={styles.buttonGrid}>
          <TouchableOpacity 
            style={[styles.button, styles.commandButton]} 
            onPress={() => handleTestCommand('SYSTEM_RESET')}
            disabled={!isConnected || loading || testingCommand}
          >
            <Text style={styles.buttonText}>System Reset</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.commandButton]} 
            onPress={() => handleTestCommand('ACKNOWLEDGE')}
            disabled={!isConnected || loading || testingCommand}
          >
            <Text style={styles.buttonText}>Acknowledge</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.commandButton]} 
            onPress={() => handleTestCommand('DRILL')}
            disabled={!isConnected || loading || testingCommand}
          >
            <Text style={styles.buttonText}>Drill Mode</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.button, styles.commandButton]} 
            onPress={() => handleTestCommand('SILENCED')}
            disabled={!isConnected || loading || testingCommand}
          >
            <Text style={styles.buttonText}>Silence Bell</Text>
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
  sectionTitle: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
    marginBottom: 15,
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
    flex: 1,
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
  dataButton: {
    backgroundColor: '#11B653',
  },
  infoButton: {
    backgroundColor: '#FF9500',
  },
  commandButton: {
    backgroundColor: '#FF3B30',
    minWidth: '48%',
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

export default ESP32ConnectionTester;