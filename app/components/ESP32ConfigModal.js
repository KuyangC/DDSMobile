import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  Modal,
  ScrollView,
  Alert
} from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import * as Haptics from 'expo-haptics';
import esp32ConfigService from '../services/esp32ConfigService';

const ESP32ConfigModal = ({ visible, onClose, onConfigUpdated }) => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const [config, setConfig] = useState({
    ipAddress: '',
    port: 80,
    timeout: 5000
  });
  const [loading, setLoading] = useState(false);
  const [editingIp, setEditingIp] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  // Load current config when modal opens
  useEffect(() => {
    if (visible) {
      loadConfig();
    }
  }, [visible]);

  const loadConfig = async () => {
    try {
      const currentConfig = await esp32ConfigService.loadConfig();
      setConfig(currentConfig);
      setEditingIp(currentConfig.ipAddress);
    } catch (_error) {
      console.error('Failed to load config:', _error);
    }
  };

  const handleIpChange = (text) => {
    setEditingIp(text);
    setConfig(prev => ({ ...prev, ipAddress: text }));
    
    // Generate suggestions when user types
    if (text.length >= 7 && text.includes('.')) {
      const parts = text.split('.');
      if (parts.length === 3) {
        const base = parts.slice(0, 3).join('.');
        const ipSuggestions = esp32ConfigService.generateIpSuggestions(base, 5);
        setSuggestions(ipSuggestions);
        setShowSuggestions(true);
      } else if (parts.length === 4) {
        setShowSuggestions(false);
      }
    } else {
      setShowSuggestions(false);
    }
  };

  const handleSuggestionSelect = (ip) => {
    // Haptic feedback on selection
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setEditingIp(ip);
    setConfig(prev => ({ ...prev, ipAddress: ip }));
    setShowSuggestions(false);
  };

  const handleNetworkSelect = (base) => {
    // Haptic feedback on network selection
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const suggestions = esp32ConfigService.generateIpSuggestions(base, 10);
    setSuggestions(suggestions);
    setEditingIp(base + '.');
    setShowSuggestions(true);
  };

  const validateAndSave = async () => {
    if (!config.ipAddress) {
      Alert.alert('Error', 'IP address is required');
      return;
    }

    if (!esp32ConfigService.validateIpAddress(config.ipAddress)) {
      Alert.alert('Error', 'Invalid IP address format');
      return;
    }

    setLoading(true);
    try {
      // Haptic feedback for save action
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      const success = await esp32ConfigService.updateIpAddress(config.ipAddress);
      if (success) {
        // Auto-trigger config update and close modal
        console.log('💾 ESP32 config saved successfully:', config.ipAddress);
        onConfigUpdated?.(config);
        onClose();
      } else {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        Alert.alert('Error', 'Failed to save configuration');
      }
    } catch (_error) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      Alert.alert('Error', _error.message);
    } finally {
      setLoading(false);
    }
  };

  const resetToDefaults = async () => {
    Alert.alert(
      'Reset Configuration',
      'Are you sure you want to reset to default settings?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset',
          style: 'destructive',
          onPress: async () => {
            setLoading(true);
            try {
              await esp32ConfigService.resetToDefaults();
              await loadConfig();
              Alert.alert('Success', 'Configuration reset to defaults');
            } catch (error) {
              Alert.alert('Error', 'Failed to reset configuration');
            } finally {
              setLoading(false);
            }
          }
        }
      ]
    );
  };

  if (!fontsLoaded) {
    return null;
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>ESP32 Configuration</Text>
          <TouchableOpacity 
            style={[styles.saveButton, loading && styles.saveButtonDisabled]} 
            onPress={validateAndSave}
            disabled={loading}
          >
            <Text style={styles.saveButtonText}>
              {loading ? 'Saving...' : 'Save'}
            </Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* IP Address Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>IP Address Settings</Text>
            
            <View style={styles.inputContainer}>
              <Text style={styles.label}>ESP32 IP Address</Text>
              <TextInput
                style={[styles.input, styles.ipInput]}
                value={editingIp}
                onChangeText={handleIpChange}
                placeholder="192.168.1.100"
                keyboardType="numeric"
                autoCapitalize="none"
                autoCorrect={false}
              />
              
              {/* IP Suggestions */}
              {showSuggestions && suggestions.length > 0 && (
                <View style={styles.suggestionsContainer}>
                  {suggestions.map((ip, index) => (
                    <TouchableOpacity
                      key={index}
                      style={styles.suggestionItem}
                      onPress={() => handleSuggestionSelect(ip)}
                    >
                      <Text style={styles.suggestionText}>{ip}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              )}
            </View>

            {/* Common Networks */}
            <View style={styles.networksContainer}>
              <Text style={styles.networksTitle}>Common Networks:</Text>
              {esp32ConfigService.getCommonNetworkRanges().map((network, index) => (
                <TouchableOpacity
                  key={index}
                  style={styles.networkItem}
                  onPress={() => handleNetworkSelect(network.base)}
                >
                  <Text style={styles.networkText}>{network.label}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Advanced Settings */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Advanced Settings</Text>
            
            <View style={styles.inputContainer}>
              <Text style={styles.label}>Port</Text>
              <TextInput
                style={styles.input}
                value={config.port.toString()}
                onChangeText={(text) => setConfig(prev => ({ 
                  ...prev, 
                  port: parseInt(text) || 80 
                }))}
                keyboardType="numeric"
                placeholder="80"
              />
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>Timeout (ms)</Text>
              <TextInput
                style={styles.input}
                value={config.timeout.toString()}
                onChangeText={(text) => setConfig(prev => ({ 
                  ...prev, 
                  timeout: parseInt(text) || 5000 
                }))}
                keyboardType="numeric"
                placeholder="5000"
              />
            </View>
          </View>

          {/* Current Configuration */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Current Configuration</Text>
            <View style={styles.configInfo}>
              <Text style={styles.configText}>
                Base URL: {esp32ConfigService.getBaseUrl()}
              </Text>
              <Text style={styles.configText}>
                Full URL: {esp32ConfigService.getBaseUrl()}/status
              </Text>
            </View>
          </View>

          {/* Reset Button */}
          <View style={styles.section}>
            <TouchableOpacity 
              style={styles.resetButton} 
              onPress={resetToDefaults}
              disabled={loading}
            >
              <Text style={styles.resetButtonText}>Reset to Defaults</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  cancelButton: {
    padding: 8,
  },
  cancelButtonText: {
    fontSize: 16,
    fontFamily: 'Poppins_500Medium',
    color: '#007AFF',
  },
  title: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
  },
  saveButton: {
    padding: 8,
  },
  saveButtonDisabled: {
    opacity: 0.5,
  },
  saveButtonText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#007AFF',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  section: {
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
    marginBottom: 15,
  },
  inputContainer: {
    marginBottom: 15,
  },
  label: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 16,
    fontFamily: 'Poppins_500Medium',
    backgroundColor: '#f9f9f9',
  },
  ipInput: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
  },
  suggestionsContainer: {
    marginTop: 5,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    backgroundColor: '#fff',
    maxHeight: 150,
  },
  suggestionItem: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  suggestionText: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#007AFF',
  },
  networksContainer: {
    marginTop: 20,
  },
  networksTitle: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#666',
    marginBottom: 10,
  },
  networkItem: {
    padding: 12,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    marginBottom: 8,
    backgroundColor: '#f9f9f9',
  },
  networkText: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#333',
  },
  configInfo: {
    backgroundColor: '#f8f8f8',
    padding: 15,
    borderRadius: 8,
  },
  configText: {
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#666',
    marginBottom: 5,
  },
  resetButton: {
    backgroundColor: '#FF3B30',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  resetButtonText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
});

export default ESP32ConfigModal;