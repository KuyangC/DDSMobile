import React, { useState, useEffect } from 'react';
import { 
  StyleSheet, 
  Text, 
  View, 
  TouchableOpacity, 
  Alert,
  TextInput,
  ScrollView
} from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import firebaseConfigService from '../services/firebaseConfigService';
import NotificationToast from './NotificationToast';

const FirebaseConfigModal = ({ 
  visible, 
  onClose, 
  onConfigUpdated, 
  initialConfig = null 
}) => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const [config, setConfig] = useState({
    apiKey: '',
    authDomain: '',
    databaseURL: '',
    projectId: '',
    storageBucket: '',
    messagingSenderId: '',
    appId: '',
    measurementId: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [testing, setTesting] = useState(false);
  const [errors, setErrors] = useState({});

  // Load current config when modal opens
  useEffect(() => {
    if (visible) {
      loadConfig();
    }
  }, [visible]);

  const loadConfig = async () => {
    try {
      const currentConfig = await firebaseConfigService.loadConfig();
      setConfig(currentConfig);
    } catch (error) {
      console.error('Failed to load Firebase config:', error);
    }
  };

  const showNotification = (type, title, message) => {
    // This would be handled by parent component or a notification system
    console.log(`${type}: ${title} - ${message}`);
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!config.apiKey.trim()) {
      newErrors.apiKey = 'API Key is required';
    }
    
    if (!config.authDomain.trim()) {
      newErrors.authDomain = 'Auth Domain is required';
    } else if (!config.authDomain.includes('.firebaseapp.com')) {
      newErrors.authDomain = 'Invalid Firebase Auth Domain';
    }
    
    if (!config.databaseURL.trim()) {
      newErrors.databaseURL = 'Database URL is required';
    } else if (!config.databaseURL.startsWith('https://') || !config.databaseURL.includes('firebaseio.com')) {
      newErrors.databaseURL = 'Invalid Firebase Database URL';
    }
    
    if (!config.projectId.trim()) {
      newErrors.projectId = 'Project ID is required';
    }
    
    if (!config.storageBucket.trim()) {
      newErrors.storageBucket = 'Storage Bucket is required';
    }
    
    if (!config.messagingSenderId.trim()) {
      newErrors.messagingSenderId = 'Sender ID is required';
    }
    
    if (!config.appId.trim()) {
      newErrors.appId = 'App ID is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) {
      Alert.alert('Validation Error', 'Please fix the errors before saving');
      return;
    }

    setLoading(true);
    try {
      const success = await firebaseConfigService.saveConfig(config);
      
      if (success) {
        console.log('✅ Firebase config saved successfully');
        onConfigUpdated && onConfigUpdated(config);
        onClose && onClose();
        
        Alert.alert(
          'Success',
          'Firebase configuration saved successfully!',
          [{ text: 'OK' }]
        );
      } else {
        throw new Error('Failed to save configuration');
      }
    } catch (error) {
      console.error('❌ Failed to save Firebase config:', error);
      Alert.alert(
        'Error',
        'Failed to save Firebase configuration. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setLoading(false);
    }
  };

  const handleTestConnection = async () => {
    if (!validateForm()) {
      Alert.alert('Validation Error', 'Please fix the errors before testing');
      return;
    }

    setTesting(true);
    try {
      const result = await firebaseConfigService.testConnection();
      
      if (result.success) {
        Alert.alert(
          'Connection Successful',
          result.message,
          [{ text: 'OK' }]
        );
      } else {
        Alert.alert(
          'Connection Failed',
          result.error,
          [{ text: 'OK' }]
        );
      }
    } catch (error) {
      console.error('❌ Firebase connection test failed:', error);
      Alert.alert(
        'Error',
        'Failed to test Firebase connection: ' + error.message,
        [{ text: 'OK' }]
      );
    } finally {
      setTesting(false);
    }
  };

  const handleReset = () => {
    Alert.alert(
      'Reset Configuration',
      'Are you sure you want to reset to default configuration?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset',
          style: 'destructive',
          onPress: async () => {
            try {
              await firebaseConfigService.resetToDefaults();
              await loadConfig();
              Alert.alert('Success', 'Configuration reset to defaults');
            } catch (error) {
              Alert.alert('Error', 'Failed to reset configuration');
            }
          }
        }
      ]
    );
  };

  const updateConfigField = (field, value) => {
    setConfig(prev => ({ ...prev, [field]: value }));
    // Clear error for this field when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  if (!fontsLoaded || !visible) {
    return null;
  }

  return (
    <View style={styles.modalOverlay}>
      <View style={styles.modalContainer}>
        {/* Header */}
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Firebase Configuration</Text>
          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <Text style={styles.closeButtonText}>×</Text>
          </TouchableOpacity>
        </View>

        {/* Content */}
        <ScrollView style={styles.modalContent} showsVerticalScrollIndicator={false}>
          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>API Key *</Text>
            <TextInput
              style={[styles.formInput, errors.apiKey && styles.formInputError]}
              value={config.apiKey}
              onChangeText={(value) => updateConfigField('apiKey', value)}
              placeholder="Enter Firebase API Key"
              placeholderTextColor="#999"
              multiline
            />
            {errors.apiKey && <Text style={styles.errorText}>{errors.apiKey}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Auth Domain *</Text>
            <TextInput
              style={[styles.formInput, errors.authDomain && styles.formInputError]}
              value={config.authDomain}
              onChangeText={(value) => updateConfigField('authDomain', value)}
              placeholder="your-project.firebaseapp.com"
              placeholderTextColor="#999"
              autoCapitalize="none"
            />
            {errors.authDomain && <Text style={styles.errorText}>{errors.authDomain}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Database URL *</Text>
            <TextInput
              style={[styles.formInput, errors.databaseURL && styles.formInputError]}
              value={config.databaseURL}
              onChangeText={(value) => updateConfigField('databaseURL', value)}
              placeholder="https://your-project.firebaseio.com"
              placeholderTextColor="#999"
              autoCapitalize="none"
            />
            {errors.databaseURL && <Text style={styles.errorText}>{errors.databaseURL}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Project ID *</Text>
            <TextInput
              style={[styles.formInput, errors.projectId && styles.formInputError]}
              value={config.projectId}
              onChangeText={(value) => updateConfigField('projectId', value)}
              placeholder="your-project-id"
              placeholderTextColor="#999"
              autoCapitalize="none"
            />
            {errors.projectId && <Text style={styles.errorText}>{errors.projectId}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Storage Bucket *</Text>
            <TextInput
              style={[styles.formInput, errors.storageBucket && styles.formInputError]}
              value={config.storageBucket}
              onChangeText={(value) => updateConfigField('storageBucket', value)}
              placeholder="your-project.appspot.com"
              placeholderTextColor="#999"
              autoCapitalize="none"
            />
            {errors.storageBucket && <Text style={styles.errorText}>{errors.storageBucket}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Messaging Sender ID *</Text>
            <TextInput
              style={[styles.formInput, errors.messagingSenderId && styles.formInputError]}
              value={config.messagingSenderId}
              onChangeText={(value) => updateConfigField('messagingSenderId', value)}
              placeholder="123456789012"
              placeholderTextColor="#999"
              keyboardType="numeric"
            />
            {errors.messagingSenderId && <Text style={styles.errorText}>{errors.messagingSenderId}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>App ID *</Text>
            <TextInput
              style={[styles.formInput, errors.appId && styles.formInputError]}
              value={config.appId}
              onChangeText={(value) => updateConfigField('appId', value)}
              placeholder="1:123456789012:android:abc123def456"
              placeholderTextColor="#999"
              multiline
            />
            {errors.appId && <Text style={styles.errorText}>{errors.appId}</Text>}
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.formLabel}>Measurement ID (Optional)</Text>
            <TextInput
              style={styles.formInput}
              value={config.measurementId}
              onChangeText={(value) => updateConfigField('measurementId', value)}
              placeholder="G-XXXXXXXXXX"
              placeholderTextColor="#999"
            />
          </View>
        </ScrollView>

        {/* Actions */}
        <View style={styles.modalActions}>
          <TouchableOpacity 
            style={[styles.actionButton, styles.resetButton]} 
            onPress={handleReset}
          >
            <Text style={styles.actionButtonText}>Reset</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.actionButton, styles.testButton]} 
            onPress={handleTestConnection}
            disabled={testing}
          >
            <Text style={styles.actionButtonText}>
              {testing ? 'Testing...' : 'Test'}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.actionButton, styles.saveButton]} 
            onPress={handleSave}
            disabled={loading}
          >
            <Text style={styles.actionButtonText}>
              {loading ? 'Saving...' : 'Save'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  modalContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    width: '100%',
    maxWidth: 500,
    maxHeight: '90%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  modalTitle: {
    fontSize: 20,
    fontFamily: 'Poppins_600SemiBold',
    color: '#000',
    flex: 1,
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    fontSize: 18,
    fontFamily: 'Poppins_600SemiBold',
    color: '#666',
  },
  modalContent: {
    padding: 20,
    maxHeight: 400,
  },
  formGroup: {
    marginBottom: 20,
  },
  formLabel: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#333',
    marginBottom: 8,
  },
  formInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    fontFamily: 'Poppins_500Medium',
    color: '#333',
    backgroundColor: '#fafafa',
    minHeight: 44,
  },
  formInputError: {
    borderColor: '#FF3B30',
    backgroundColor: '#FFF5F5',
  },
  errorText: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#FF3B30',
    marginTop: 4,
  },
  modalActions: {
    flexDirection: 'row',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    gap: 10,
  },
  actionButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  resetButton: {
    backgroundColor: '#8E8E93',
  },
  testButton: {
    backgroundColor: '#007AFF',
  },
  saveButton: {
    backgroundColor: '#11B653',
  },
  actionButtonText: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
  },
});

export default FirebaseConfigModal;