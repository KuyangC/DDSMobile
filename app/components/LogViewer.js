import React, { useState } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  ScrollView, 
  TouchableOpacity, 
  RefreshControl,
  Alert,
  Modal
} from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import useLogData from '../hooks/useLogData';

const LogViewer = () => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const { logs, loading, error, fetchLogs, logEvent } = useLogData();
  const [activeTab, setActiveTab] = useState('all');
  const [selectedLog, setSelectedLog] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);

  if (!fontsLoaded) {
    return null;
  }

  const handleClearLogs = () => {
    Alert.alert(
      'Clear Logs',
      'Are you sure you want to clear all logs?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear',
          style: 'destructive',
          onPress: () => {
            // Implement clear logs functionality
            Alert.alert('Info', 'Clear logs feature coming soon');
          }
        }
      ]
    );
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const getStatusColor = (type) => {
    switch (type) {
      case 'ALARM': return '#FF3B30';
      case 'TROUBLE': return '#FF9500';
      case 'NORMAL': return '#11B653';
      case 'COMMAND': return '#007AFF';
      default: return '#8E8E93';
    }
  };

  const getStatusIcon = (type) => {
    switch (type) {
      case 'ALARM': return '🚨';
      case 'TROUBLE': return '⚠️';
      case 'NORMAL': return '✅';
      case 'COMMAND': return '⚙️';
      default: return '📋';
    }
  };

  const getFilteredLogs = () => {
    if (activeTab === 'all') return logs;
    return logs.filter(log => log.type === activeTab);
  };

  const showLogDetail = (log) => {
    setSelectedLog(log);
    setShowDetailModal(true);
  };

  const renderZones = (zones) => {
    if (!zones || zones.length === 0) return 'No zones';
    return zones.map(zone => `Zone ${zone}`).join(', ');
  };

  const filteredLogs = getFilteredLogs();

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>System Logs</Text>
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{logs.length}</Text>
            <Text style={styles.statLabel}>Total</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: '#FF3B30' }]}>
              {logs.filter(log => log.type === 'ALARM').length}
            </Text>
            <Text style={styles.statLabel}>Alarms</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: '#FF9500' }]}>
              {logs.filter(log => log.type === 'TROUBLE').length}
            </Text>
            <Text style={styles.statLabel}>Troubles</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={[styles.statValue, { color: '#11B653' }]}>
              {logs.filter(log => log.type === 'NORMAL').length}
            </Text>
            <Text style={styles.statLabel}>Normal</Text>
          </View>
        </View>
      </View>

      {/* Tab Navigation */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'all' && styles.activeTab]}
          onPress={() => setActiveTab('all')}
        >
          <Text style={[styles.tabText, activeTab === 'all' && styles.activeTabText]}>
            All ({logs.length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'ALARM' && styles.activeTab]}
          onPress={() => setActiveTab('ALARM')}
        >
          <Text style={[styles.tabText, activeTab === 'ALARM' && styles.activeTabText]}>
            🚨 Alarms ({logs.filter(log => log.type === 'ALARM').length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'TROUBLE' && styles.activeTab]}
          onPress={() => setActiveTab('TROUBLE')}
        >
          <Text style={[styles.tabText, activeTab === 'TROUBLE' && styles.activeTabText]}>
            ⚠️ Troubles ({logs.filter(log => log.type === 'TROUBLE').length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'COMMAND' && styles.activeTab]}
          onPress={() => setActiveTab('COMMAND')}
        >
          <Text style={[styles.tabText, activeTab === 'COMMAND' && styles.activeTabText]}>
            ⚙️ Commands ({logs.filter(log => log.type === 'COMMAND').length})
          </Text>
        </TouchableOpacity>
      </View>

      {/* Action Buttons */}
      <View style={styles.actionBar}>
        <TouchableOpacity style={styles.actionButton} onPress={() => fetchLogs()}>
          <Text style={styles.actionButtonText}>Refresh</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionButton} onPress={handleClearLogs}>
          <Text style={styles.actionButtonText}>Clear All</Text>
        </TouchableOpacity>
      </View>

      {/* Content */}
      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={fetchLogs} />
        }
      >
        {error && (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>Error: {error}</Text>
          </View>
        )}

        {filteredLogs.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>No logs found</Text>
          </View>
        ) : (
          filteredLogs.map((log) => (
            <TouchableOpacity 
              key={log.id} 
              style={styles.logItem}
              onPress={() => showLogDetail(log)}
            >
              <View style={styles.logHeader}>
                <View style={styles.logTypeRow}>
                  <Text style={styles.logIcon}>{getStatusIcon(log.type)}</Text>
                  <Text style={[styles.logType, { color: getStatusColor(log.type) }]}>
                    {log.type}
                  </Text>
                </View>
                <Text style={styles.timestamp}>
                  {formatTimestamp(log.timestamp)}
                </Text>
              </View>
              <Text style={styles.logDetails}>{log.details}</Text>
              {log.address && (
                <Text style={styles.logAddress}>Slave: {log.address}</Text>
              )}
            </TouchableOpacity>
          ))
        )}
      </ScrollView>

      {/* Detail Modal */}
      <Modal
        visible={showDetailModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowDetailModal(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            {selectedLog && (
              <View>
                <View style={styles.modalHeader}>
                  <Text style={[styles.modalType, { color: getStatusColor(selectedLog.type) }]}>
                    {getStatusIcon(selectedLog.type)} {selectedLog.type}
                  </Text>
                  <TouchableOpacity 
                    style={styles.closeButton} 
                    onPress={() => setShowDetailModal(false)}
                  >
                    <Text style={styles.closeButtonText}>✕</Text>
                  </TouchableOpacity>
                </View>

                <Text style={styles.modalTitle}>{selectedLog.details}</Text>
                <Text style={styles.modalTimestamp}>
                  {formatTimestamp(selectedLog.timestamp)}
                </Text>

                {selectedLog.address && (
                  <View style={styles.modalSection}>
                    <Text style={styles.modalSectionTitle}>Slave Address:</Text>
                    <Text style={styles.modalValue}>{selectedLog.address}</Text>
                  </View>
                )}

                {selectedLog.slaveData && (
                  <View style={styles.modalSection}>
                    <Text style={styles.modalSectionTitle}>Slave Status:</Text>
                    <Text style={styles.modalValue}>
                      Online: {selectedLog.slaveData.online ? 'Yes' : 'No'}
                    </Text>
                    <Text style={styles.modalValue}>
                      Status: {selectedLog.slaveData.status || 'N/A'}
                    </Text>
                    {selectedLog.slaveData.alarm_zones && selectedLog.slaveData.alarm_zones.length > 0 && (
                      <Text style={styles.modalValue}>
                        Alarm Zones: {renderZones(selectedLog.slaveData.alarm_zones)}
                      </Text>
                    )}
                    {selectedLog.slaveData.trouble_zones && selectedLog.slaveData.trouble_zones.length > 0 && (
                      <Text style={styles.modalValue}>
                        Trouble Zones: {renderZones(selectedLog.slaveData.trouble_zones)}
                      </Text>
                    )}
                    {selectedLog.slaveData.bell_active && (
                      <Text style={[styles.modalValue, { color: '#FF3B30' }]}>
                        🔔 Bell Active
                      </Text>
                    )}
                  </View>
                )}

                <TouchableOpacity 
                  style={styles.modalCloseButton}
                  onPress={() => setShowDetailModal(false)}
                >
                  <Text style={styles.modalCloseButtonText}>Close</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>
      </Modal>
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
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statValue: {
    fontSize: 20,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
  },
  statLabel: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginTop: 2,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#f8f8f8',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  activeTab: {
    borderBottomColor: '#007AFF',
    backgroundColor: '#fff',
  },
  tabText: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    textAlign: 'center',
  },
  activeTabText: {
    color: '#007AFF',
    fontFamily: 'Poppins_600SemiBold',
  },
  actionBar: {
    flexDirection: 'row',
    padding: 15,
    backgroundColor: '#f8f8f8',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  actionButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 6,
    marginHorizontal: 5,
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    textAlign: 'center',
  },
  content: {
    flex: 1,
  },
  logItem: {
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
    backgroundColor: '#fff',
  },
  logHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  logTypeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  logIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  logType: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
  },
  timestamp: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
  },
  logDetails: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#333',
    marginBottom: 4,
  },
  logAddress: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    fontStyle: 'italic',
  },
  errorContainer: {
    padding: 20,
    backgroundColor: '#FFE5E5',
    margin: 15,
    borderRadius: 8,
  },
  errorText: {
    color: '#FF3B30',
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    textAlign: 'center',
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 50,
  },
  emptyText: {
    fontSize: 16,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    textAlign: 'center',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 10,
    margin: 20,
    maxHeight: '80%',
    width: '90%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  modalType: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
    flex: 1,
  },
  closeButton: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    fontSize: 16,
    color: '#666',
  },
  modalTitle: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#333',
    marginBottom: 10,
  },
  modalTimestamp: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginBottom: 15,
  },
  modalSection: {
    marginBottom: 15,
  },
  modalSectionTitle: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#333',
    marginBottom: 5,
  },
  modalValue: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginBottom: 5,
  },
  modalCloseButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalCloseButtonText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
});

export default LogViewer;