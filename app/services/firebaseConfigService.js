/**
 * Firebase Configuration Service
 * Manages Firebase credentials and connection settings
 * Using Expo SecureStore for Expo Go compatibility
 */

let SecureStore = null;

// Only try to load SecureStore in native environment
const isNative = typeof window === 'undefined' || 
                !window.location || 
                (typeof navigator !== 'undefined' && navigator.product === 'ReactNative');

if (isNative) {
  try {
    SecureStore = require('expo-secure-store').default;
  } catch (error) {
    console.warn('⚠️ expo-secure-store not available, using fallback storage');
  }
} else {
  console.log('🌐 Web environment detected, using localStorage');
}

const FIREBASE_CONFIG_KEY = 'firebase_config';

// Web localStorage storage
class WebStorage {
  constructor() {
    this.prefix = 'ddsmobile_';
  }

  async getItemAsync(key) {
    if (typeof window === 'undefined' || !window.localStorage) {
      return null;
    }
    return window.localStorage.getItem(this.prefix + key) || null;
  }

  async setItemAsync(key, value) {
    if (typeof window === 'undefined' || !window.localStorage) {
      console.warn('localStorage not available');
      return;
    }
    window.localStorage.setItem(this.prefix + key, value);
  }

  async deleteItemAsync(key) {
    if (typeof window === 'undefined' || !window.localStorage) {
      return;
    }
    window.localStorage.removeItem(this.prefix + key);
  }
}

// Fallback storage for when no storage is available
class MemoryStorage {
  constructor() {
    this.storage = {};
  }

  async getItemAsync(key) {
    return this.storage[key] || null;
  }

  async setItemAsync(key, value) {
    this.storage[key] = value;
  }

  async deleteItemAsync(key) {
    delete this.storage[key];
  }
}

const webStorage = new WebStorage();
const memoryStorage = new MemoryStorage();

const DEFAULT_CONFIG = {
  apiKey: '',
  authDomain: '',
  databaseURL: '',
  projectId: '',
  storageBucket: '',
  messagingSenderId: '',
  appId: '',
  measurementId: ''
};

class FirebaseConfigService {
  constructor() {
    this.config = DEFAULT_CONFIG;
    this.listeners = [];
  }

  /**
   * Load configuration from appropriate storage
   */
  async loadConfig() {
    try {
      let storedConfig = null;
      
      // Always use webStorage for web environment (Expo Go)
      if (typeof window !== 'undefined' && window.localStorage) {
        console.log('🌐 Using localStorage for web environment');
        const stored = window.localStorage.getItem('ddsmobile_' + FIREBASE_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      } else if (SecureStore) {
        console.log('📱 Using SecureStore for mobile');
        const stored = await SecureStore.getItemAsync(FIREBASE_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      } else {
        console.log('💾 Using memory storage fallback');
        const stored = await memoryStorage.getItemAsync(FIREBASE_CONFIG_KEY);
        if (stored) {
          storedConfig = JSON.parse(stored);
        }
      }
      
      if (storedConfig) {
        this.config = { ...DEFAULT_CONFIG, ...storedConfig };
        console.log('✅ Firebase config loaded:', this.config);
      } else {
        console.log('⚠️ No Firebase config found, using defaults');
        await this.saveConfig();
      }
      return this.config;
    } catch (error) {
      console.error('❌ Failed to load Firebase config:', error);
      this.config = DEFAULT_CONFIG;
      try {
        await this.saveConfig();
      } catch (saveError) {
        console.warn('⚠️ Could not save fallback config:', saveError);
      }
      return this.config;
    }
  }

  /**
   * Save configuration to appropriate storage
   */
  async saveConfig(newConfig = null) {
    try {
      if (newConfig) {
        this.config = { ...this.config, ...newConfig };
      }
      
      const configString = JSON.stringify(this.config);
      
      // Always use localStorage for web environment (Expo Go)
      if (typeof window !== 'undefined' && window.localStorage) {
        console.log('🌐 Saving to localStorage');
        window.localStorage.setItem('ddsmobile_' + FIREBASE_CONFIG_KEY, configString);
      } else if (SecureStore) {
        console.log('📱 Saving to SecureStore');
        await SecureStore.setItemAsync(FIREBASE_CONFIG_KEY, configString);
      } else {
        console.log('💾 Saving to memory');
        await memoryStorage.setItemAsync(FIREBASE_CONFIG_KEY, configString);
      }
      
      console.log('✅ Firebase config saved:', this.config);
      
      // Notify all listeners
      this.listeners.forEach(listener => listener(this.config));
      
      return true;
    } catch (error) {
      console.error('❌ Failed to save Firebase config:', error);
      return false;
    }
  }

  /**
   * Get current configuration
   */
  getConfig() {
    return this.config;
  }

  /**
   * Update specific configuration values
   */
  async updateConfig(updates) {
    return await this.saveConfig(updates);
  }

  /**
   * Validate Firebase configuration
   */
  validateConfig(config) {
    const requiredFields = [
      'apiKey',
      'authDomain', 
      'databaseURL',
      'projectId',
      'storageBucket',
      'messagingSenderId',
      'appId'
    ];

    for (const field of requiredFields) {
      if (!config[field] || config[field].trim() === '') {
        return {
          valid: false,
          error: `Field '${field}' is required`
        };
      }
    }

    // Validate database URL format
    if (!config.databaseURL.startsWith('https://') || !config.databaseURL.includes('firebaseio.com')) {
      return {
        valid: false,
        error: 'Invalid Firebase database URL format'
      };
    }

    // Validate authDomain format
    if (!config.authDomain.includes('.firebaseapp.com')) {
      return {
        valid: false,
        error: 'Invalid Firebase auth domain format'
      };
    }

    return { valid: true };
  }

  /**
   * Test Firebase connection
   */
  async testConnection() {
    try {
      const validation = this.validateConfig(this.config);
      if (!validation.valid) {
        return {
          success: false,
          error: validation.error
        };
      }

      // Initialize Firebase with current config
      const firebase = require('firebase/app');
      const database = require('firebase/database');

      // Initialize if not already initialized
      if (!firebase.apps.length) {
        firebase.initializeApp(this.config);
      }

      // Test database connection
      const db = database.getDatabase();
      const testRef = database.ref(db, 'connection_test');
      
      await database.set(testRef, {
        timestamp: new Date().toISOString(),
        test: true
      });

      await database.remove(testRef);

      return {
        success: true,
        message: 'Firebase connection successful'
      };
    } catch (error) {
      console.error('Firebase connection test failed:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get Firebase configuration object for app initialization
   */
  getFirebaseConfig() {
    return { ...this.config };
  }

  /**
   * Reset to default configuration
   */
  async resetToDefaults() {
    this.config = { ...DEFAULT_CONFIG };
    return await this.saveConfig();
  }

  /**
   * Subscribe to configuration changes
   */
  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  /**
   * Check if configuration is complete
   */
  isConfigured() {
    const validation = this.validateConfig(this.config);
    return validation.valid;
  }

  /**
   * Get configuration status
   */
  getConfigStatus() {
    const validation = this.validateConfig(this.config);
    
    if (validation.valid) {
      return {
        status: 'configured',
        message: 'Firebase is properly configured',
        color: '#11B653'
      };
    } else {
      return {
        status: 'not_configured',
        message: validation.error,
        color: '#FF3B30'
      };
    }
  }
}

// Create singleton instance
const firebaseConfigService = new FirebaseConfigService();

export default firebaseConfigService;